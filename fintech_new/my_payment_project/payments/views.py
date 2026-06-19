import base64
import os
import time
import uuid
from decimal import Decimal
from urllib.parse import quote_plus
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework import status
from django.utils import timezone
from .integrations import (
    generate_sms_code,
    get_myid_status,
    mask_phone,
    myid_is_configured,
    payme_subscribe_rpc,
    send_registration_sms,
    start_myid_authentication,
    get_config,
)
from .models import APIConfiguration, Bank, Investment, KYCVerification, LegalEntityProfile, Order, PaymeTransaction, Startup

from .serializers import (
    InvestmentSerializer,
    LegalEntityProfileSerializer,
    OrderSerializer,
    RegisterSerializer,
    StartupSerializer,
)

PAYME_ERRORS = {
    "AUTH_ERROR": {
        "code": -32504,
        "message": {"ru": "Ошибка авторизации", "uz": "Avtorizatsiya xatosi", "en": "Authorization error"},
    },
    "ORDER_NOT_FOUND": {
        "code": -31050,
        "message": {"ru": "Заказ не найден", "uz": "Buyurtma topilmadi", "en": "Order not found"},
        "data": "Bpay",
    },
    "INVALID_AMOUNT": {
        "code": -31001,
        "message": {"ru": "Неверная сумма заказа", "uz": "Buyurtma summasi noto'g'ri", "en": "Invalid order amount"},
        "data": "amount",
    },
    "CANT_CANCEL": {
        "code": -31007,
        "message": {"ru": "Невозможно выполнить операцию", "uz": "Operatsiyani bajarib bo'lmaydi", "en": "Operation cannot be performed"},
    },
    "TRANSACTION_NOT_FOUND": {
        "code": -31003,
        "message": {"ru": "Транзакция не найдена", "uz": "Tranzaksiya topilmadi", "en": "Transaction not found"},
    },
}

PLACEHOLDER_PREFIXES = ('your_', 'paste_', 'change-me', 'сюда_', 'example')
SECRET_CONFIG_KEYS = {
    'PAYME_MERCHANT_KEY',
    'PAYME_SUBSCRIBE_KEY',
    'MYID_PASSWORD',
    'SMS_PROVIDER_TOKEN',
    'DJANGO_SECRET_KEY',
}
PAYME_CHECKOUT_REQUIRED_KEYS = [
    'PAYME_MERCHANT_ID',
    'PAYME_MERCHANT_KEY',
    'PAYME_CHECKOUT_URL',
    'PAYME_CALLBACK_URL',
    'PAYME_ACCOUNT_KEY',
]


def config_value_is_set(value):
    if value is None:
        return False
    normalized = str(value).strip()
    if not normalized:
        return False
    return not normalized.lower().startswith(PLACEHOLDER_PREFIXES)


def mask_config_value(key, value):
    if not config_value_is_set(value):
        return ''
    value = str(value)
    if key in SECRET_CONFIG_KEYS:
        return '****' if len(value) <= 8 else f"{value[:4]}...{value[-4:]}"
    return value


def config_source(key):
    db_config = APIConfiguration.objects.filter(key=key, is_active=True).first()
    if db_config and config_value_is_set(db_config.value):
        return 'django_admin', db_config.value
    env_value = os.environ.get(key)
    if config_value_is_set(env_value):
        return 'env', env_value
    return 'missing', ''


def config_group_status(keys):
    items = {}
    configured = True
    for key in keys:
        source, value = config_source(key)
        is_set = config_value_is_set(value)
        configured = configured and is_set
        items[key] = {
            'configured': is_set,
            'source': source,
            'value': mask_config_value(key, value),
        }
    return {'configured': configured, 'items': items}


def get_payme_merchant_key():
    return get_config('PAYME_MERCHANT_KEY', 'test_merchant_secret_key')


def get_payme_merchant_id():
    return get_config('PAYME_MERCHANT_ID', 'test_merchant_id')


def get_payme_account_key():
    return get_config('PAYME_ACCOUNT_KEY', 'Bpay')


def missing_payme_checkout_config():
    return [key for key in PAYME_CHECKOUT_REQUIRED_KEYS if not config_value_is_set(get_config(key))]


def payme_config_error_response():
    return Response({
        "detail": "Payme is not configured on the backend. Add the missing keys in Render Environment or Django Admin.",
        "missing": missing_payme_checkout_config(),
    }, status=status.HTTP_503_SERVICE_UNAVAILABLE)


def build_payme_checkout_url(order):
    missing = missing_payme_checkout_config()
    if missing:
        raise ValueError(f"Payme checkout is not configured: {', '.join(missing)}")
    merchant_id = get_payme_merchant_id()
    account_key = get_payme_account_key()
    amount_tiyin = int(Decimal(order.amount) * 100)
    callback = get_config('PAYME_CALLBACK_URL', 'http://127.0.0.1:8765/index.html')
    base_url = get_config('PAYME_CHECKOUT_URL', 'https://test.paycom.uz')
    payload = f"m={merchant_id};ac.{account_key}={order.id};a={amount_tiyin};c={callback};ct=15"
    encoded = base64.b64encode(payload.encode('utf-8')).decode('utf-8')
    return f"{base_url}/{quote_plus(encoded)}"


class PaymeWebhookView(APIView):
    permission_classes = [AllowAny]

    def _rpc_result(self, result, request_id):
        return Response({"jsonrpc": "2.0", "result": result, "id": request_id})

    def post(self, request, *args, **kwargs):
        request_id = request.data.get('id')
        # 1. Проверка авторизации
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Basic '):
            return self._rpc_error("AUTH_ERROR", request_id)

        try:
            encoded_credentials = auth_header.split(' ')[1]
            decoded_credentials = base64.b64decode(encoded_credentials).decode('utf-8')
            username, password = decoded_credentials.split(':', 1)
        except Exception:
            return self._rpc_error("AUTH_ERROR", request_id)

        MERCHANT_KEY = get_payme_merchant_key()
        if password != MERCHANT_KEY:
            return self._rpc_error("AUTH_ERROR", request_id)

        # 2. Разбор JSON-RPC
        method = request.data.get('method')
        params = request.data.get('params', {})

        if method == "CheckPerformTransaction":
            return self._check_perform_transaction(params, request_id)
        elif method == "CreateTransaction":
            return self._create_transaction(params, request_id)
        elif method == "PerformTransaction":
            return self._perform_transaction(params, request_id)
        elif method == "CancelTransaction":
            return self._cancel_transaction(params, request_id)
        elif method == "CheckTransaction":
            return self._check_transaction(params, request_id)
        elif method == "GetStatement":
            return self._get_statement(params, request_id)
        
        return Response({"jsonrpc": "2.0", "error": {
            "code": -32601,
            "message": {"ru": "Метод не найден", "uz": "Metod topilmadi", "en": "Method not found"},
        }, "id": request_id})

    def _extract_order_id(self, params):
        account = params.get('account') or {}
        if not isinstance(account, dict):
            return None
        account_key = get_payme_account_key()
        for key in [account_key, 'order_id', 'OrderId', 'order', 'id', 'Bpay', 'bpay']:
            value = account.get(key)
            if value not in [None, '']:
                return value
        for value in account.values():
            if isinstance(value, (str, int)) and str(value).strip():
                return value
        return None

    def _normalize_order_id(self, value):
        if value in [None, '']:
            return None
        value = str(value).strip()
        return int(value) if value.isdigit() else None

    def _get_order_from_params(self, params):
        order_id = self._normalize_order_id(self._extract_order_id(params))
        if order_id is None:
            return None
        return Order.objects.filter(id=order_id).first()

    def _merchant_transaction_id(self, tx):
        return str(tx.id)

    def _amount_tiyin(self, amount):
        try:
            return int(amount)
        except (TypeError, ValueError):
            return None

    def _create_transaction_result(self, tx):
        return {
            "create_time": tx.create_time,
            "transaction": self._merchant_transaction_id(tx),
            "state": tx.state,
        }

    def _perform_transaction_result(self, tx):
        return {
            "transaction": self._merchant_transaction_id(tx),
            "perform_time": tx.perform_time,
            "state": tx.state,
        }

    def _cancel_transaction_result(self, tx):
        return {
            "transaction": self._merchant_transaction_id(tx),
            "cancel_time": tx.cancel_time,
            "state": tx.state,
        }

    def _check_transaction_result(self, tx):
        result = {
            "create_time": tx.create_time,
            "perform_time": tx.perform_time,
            "cancel_time": tx.cancel_time,
            "transaction": self._merchant_transaction_id(tx),
            "state": tx.state,
        }
        if tx.reason is not None:
            result["reason"] = tx.reason
        return result

    def _check_perform_transaction(self, params, request_id):
        amount = params.get('amount')
        order = self._get_order_from_params(params)

        if not order:
            return self._rpc_error("ORDER_NOT_FOUND", request_id)

        if int(order.amount * 100) != self._amount_tiyin(amount):
            return self._rpc_error("INVALID_AMOUNT", request_id)

        if order.status != 'pending':
            return self._rpc_error("CANT_CANCEL", request_id)

        return self._rpc_result({"allow": True}, request_id)

    def _create_transaction(self, params, request_id):
        payme_id = params.get('id')
        amount = params.get('amount')
        create_time = params.get('time')
        order = self._get_order_from_params(params)

        if not order:
            return self._rpc_error("ORDER_NOT_FOUND", request_id)

        if int(order.amount * 100) != self._amount_tiyin(amount):
            return self._rpc_error("INVALID_AMOUNT", request_id)

        try:
            tx = PaymeTransaction.objects.get(payme_id=payme_id)
            if tx.state == 1:
                return self._rpc_result(self._create_transaction_result(tx), request_id)
            return self._rpc_error("CANT_CANCEL", request_id)
        except PaymeTransaction.DoesNotExist:
            pass

        tx = PaymeTransaction.objects.create(payme_id=payme_id, order=order, amount=amount, state=1, create_time=create_time)
        return self._rpc_result(self._create_transaction_result(tx), request_id)

    def _perform_transaction(self, params, request_id):
        payme_id = params.get('id')

        try:
            tx = PaymeTransaction.objects.get(payme_id=payme_id)
        except PaymeTransaction.DoesNotExist:
            return self._rpc_error("TRANSACTION_NOT_FOUND", request_id)

        if tx.state == 1:
            current_time_ms = int(time.time() * 1000)
            tx.state = 2
            tx.perform_time = current_time_ms
            tx.save()

            order = tx.order
            order.status = 'paid'
            order.save()
            Investment.objects.filter(order=order).update(status='paid')
            for investment in Investment.objects.filter(order=order, startup__isnull=False):
                startup = investment.startup
                startup.amount_raised = startup.amount_raised + investment.amount
                startup.save(update_fields=['amount_raised', 'updated_at'])

            # If this is a registration or card connection order, connect the profile and card
            if order.purpose in ['card_order', 'application'] and order.user:
                profile, _ = UserProfile.objects.get_or_create(user=order.user)
                profile.myid_status = 'verified'
                profile.save(update_fields=['myid_status'])

                # Create a realistic test card
                import random
                card_num = f"86000691{random.randint(10000000, 99999999)}"
                Card.objects.create(
                    user=order.user,
                    number=f"{card_num[:4]} {card_num[4:8]} {card_num[8:12]} {card_num[12:]}",
                    expiry="03/29",
                    balance=Decimal('500000.00'),
                    name="Payme Humo",
                    provider="payme",
                    payme_verified=True,
                )

        return self._rpc_result(self._perform_transaction_result(tx), request_id)


    def _cancel_transaction(self, params, request_id):
        payme_id = params.get('id')
        reason = params.get('reason')

        try:
            tx = PaymeTransaction.objects.get(payme_id=payme_id)
        except PaymeTransaction.DoesNotExist:
            return self._rpc_error("TRANSACTION_NOT_FOUND", request_id)

        if tx.state in [-1, -2]:
            return self._rpc_result(self._cancel_transaction_result(tx), request_id)

        current_time_ms = int(time.time() * 1000)
        tx.cancel_time = current_time_ms
        tx.reason = reason
        tx.state = -2 if tx.state == 2 else -1
        tx.save()

        order = tx.order
        order.status = 'canceled'
        order.save(update_fields=['status'])
        Investment.objects.filter(order=order).update(status='canceled')

        return self._rpc_result(self._cancel_transaction_result(tx), request_id)

    def _check_transaction(self, params, request_id):
        payme_id = params.get('id')

        try:
            tx = PaymeTransaction.objects.get(payme_id=payme_id)
        except PaymeTransaction.DoesNotExist:
            return self._rpc_error("TRANSACTION_NOT_FOUND", request_id)

        return self._rpc_result(self._check_transaction_result(tx), request_id)

    def _get_statement(self, params, request_id):
        from_time = params.get('from', 0)
        to_time = params.get('to', int(time.time() * 1000))
        transactions = PaymeTransaction.objects.filter(create_time__gte=from_time, create_time__lte=to_time)
        return self._rpc_result({"transactions": [
            {
                "id": tx.payme_id,
                "time": tx.create_time,
                "amount": tx.amount,
                "account": {get_payme_account_key(): str(tx.order_id)},
                "create_time": tx.create_time,
                "perform_time": tx.perform_time,
                "cancel_time": tx.cancel_time,
                "transaction": self._merchant_transaction_id(tx),
                "state": tx.state,
                "reason": tx.reason,
            }
            for tx in transactions
        ]}, request_id)

    def _rpc_error(self, error_type, request_id):
        error_data = PAYME_ERRORS.get(error_type, {"code": -32603, "message": "Внутренняя ошибка"})
        if error_type == "ORDER_NOT_FOUND":
            error_data = {**error_data, "data": get_payme_account_key()}
        return Response({"jsonrpc": "2.0", "error": error_data, "id": request_id})


from .models import UserProfile, Card
from .serializers import CardSerializer


class IntegrationStatusView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        payme_env_keys = sorted(key for key in os.environ if key.startswith('PAYME_'))
        return Response({
            'registration_provider': 'payme',
            'runtime': {
                'host': request.get_host(),
                'render': bool(os.environ.get('RENDER')),
                'render_external_hostname': os.environ.get('RENDER_EXTERNAL_HOSTNAME', ''),
                'render_service_name': os.environ.get('RENDER_SERVICE_NAME', ''),
                'render_git_commit': os.environ.get('RENDER_GIT_COMMIT', ''),
                'payme_env_keys_present': payme_env_keys,
            },
            'payme_merchant': config_group_status([
                'PAYME_MERCHANT_ID',
                'PAYME_MERCHANT_KEY',
                'PAYME_CHECKOUT_URL',
                'PAYME_CALLBACK_URL',
                'PAYME_ACCOUNT_KEY',
            ]),
            'payme_subscribe': config_group_status([
                'PAYME_SUBSCRIBE_ID',
                'PAYME_SUBSCRIBE_KEY',
                'PAYME_SUBSCRIBE_BASE_URL',
            ]),
            'sms': config_group_status([
                'SMS_DEMO_MODE',
                'SMS_DEMO_CODE',
                'SMS_PROVIDER_URL',
                'SMS_PROVIDER_TOKEN',
            ]),
            'myid': {
                **config_group_status([
                    'MYID_BASE_URL',
                    'MYID_CLIENT_ID',
                    'MYID_USERNAME',
                    'MYID_PASSWORD',
                    'MYID_HOSTED_URL',
                ]),
                'used_for_registration': False,
            },
            'notes': [
                'Secrets are masked and never returned fully.',
                'Django Admin values override .env values when active.',
                'Registration currently redirects to Payme checkout, not MyID/camera.',
            ],
        })


class PaymeDepositRatesView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        rates = [
            {
                'name': bank.name,
                'apy': float(bank.apy or 0),
                'min_amount': float(bank.min_deposit or 0),
            }
            for bank in Bank.objects.all().order_by('-apy')[:12]
        ]
        return Response({
            'source': 'backend_local',
            'rates': rates,
        })


class RegisterView(APIView):
    def post(self, request):
        myid_session_id = request.data.get('myid_session_id')
        payme_connect = request.data.get('payme_connect', False) or (request.data.get('phone') and not myid_session_id)
        
        allow_without_myid = get_config('ALLOW_REGISTER_WITHOUT_MYID', 'true').lower() in ['1', 'true', 'yes']
        allow_without_phone_sms = get_config('ALLOW_REGISTER_WITHOUT_PHONE_SMS', 'true').lower() in ['1', 'true', 'yes']
        
        kyc = None
        if myid_session_id:
            kyc = KYCVerification.objects.filter(session_id=myid_session_id).first()
            if kyc:
                allow_without_myid = False
                allow_without_phone_sms = False
                
        if not allow_without_myid and (not kyc or kyc.status not in ['verified', 'demo_verified']):
            return Response({
                "myid": "MyID verification is required before registration"
            }, status=status.HTTP_400_BAD_REQUEST)
        if not allow_without_phone_sms and kyc and not kyc.phone_verified:
            return Response({
                "phone_sms": "Phone SMS verification is required before registration"
            }, status=status.HTTP_400_BAD_REQUEST)
        if payme_connect and missing_payme_checkout_config():
            return payme_config_error_response()

        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save(
                first_name=(kyc.first_name if kyc and kyc.first_name else request.data.get('first_name', '')),
                last_name=(kyc.last_name if kyc and kyc.last_name else request.data.get('last_name', ''))
            )
            profile, _ = UserProfile.objects.get_or_create(
                user=user,
                defaults={'phone': request.data.get('phone', '')}
            )
            profile.phone = (kyc.phone if kyc and kyc.phone else request.data.get('phone', profile.phone))
            if kyc:
                profile.passport = kyc.passport
                profile.birth_date = kyc.birth_date
                profile.myid_status = kyc.status
                profile.myid_job_id = kyc.job_id
                profile.myid_session_id = kyc.session_id
                profile.myid_payload = kyc.payload
            profile.save()

            from rest_framework_simplejwt.tokens import RefreshToken
            refresh = RefreshToken.for_user(user)
            tokens = {
                "access": str(refresh.access_token),
                "refresh": str(refresh),
            }

            response_data = {
                "message": "User registered successfully",
                "tokens": tokens,
                "myid_status": profile.myid_status,
            }

            if payme_connect:
                # Create a card_order order to link the profile and card
                order = Order.objects.create(
                    user=user,
                    amount=Decimal('1000.00'),
                    purpose='card_order',
                    description='Регистрация и привязка профиля через Payme',
                )
                order.checkout_url = build_payme_checkout_url(order)
                order.save(update_fields=['checkout_url'])
                response_data['payme_checkout_url'] = order.checkout_url

            return Response(response_data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)



class RegistrationMyIDStartView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email', '').strip().lower()
        passport = request.data.get('passport', '').strip().upper()
        birth_date = request.data.get('birth_date', '')
        phone = request.data.get('phone', '').strip()
        agreed_value = request.data.get('agreed_on_terms')
        agreed = agreed_value is True or str(agreed_value).lower() in ['1', 'true', 'yes', 'on']

        if not email or not phone or not agreed:
            return Response({
                "detail": "email, phone and agreed_on_terms are required"
            }, status=status.HTTP_400_BAD_REQUEST)

        session_id = f"reg-myid-{uuid.uuid4()}"
        external_id = str(uuid.uuid4())
        photo_from_camera = request.data.get('photo_from_camera') or {}
        payload = {
            "first_name": request.data.get('first_name', ''),
            "last_name": request.data.get('last_name', ''),
            "phone": phone,
            "pass_data": passport,
            "birth_date": birth_date,
            "photo_from_camera": photo_from_camera,
            "agreed_on_terms": agreed,
            "external_id": external_id,
            "is_resident": request.data.get('is_resident', True),
        }
        has_inline_myid_data = bool(passport and birth_date and (photo_from_camera.get('front') or request.data.get('front')))

        try:
            if has_inline_myid_data:
                myid = start_myid_authentication(payload)
            elif myid_is_configured() and get_config('MYID_HOSTED_URL'):
                hosted_url = get_config('MYID_HOSTED_URL')
                myid = {
                    'demo': False,
                    'status': 'pending',
                    'job_id': '',
                    'external_id': external_id,
                    'redirect_url': hosted_url,
                    'payload': {
                        'source': 'hosted_redirect',
                        'redirect_url': hosted_url,
                    },
                }
            elif myid_is_configured():
                return Response({
                    "detail": "This MyID mode needs a hosted/redirect URL or inline passport, birth date and face photo data."
                }, status=status.HTTP_400_BAD_REQUEST)
            else:
                myid = {
                    'demo': True,
                    'status': 'demo_verified',
                    'job_id': f"myid-demo-{int(time.time())}",
                    'external_id': external_id,
                    'payload': {
                        'first_name': payload["first_name"],
                        'last_name': payload["last_name"],
                        'phone': phone,
                        'source': 'demo_redirect',
                    },
                }
            kyc = KYCVerification.objects.create(
                session_id=session_id,
                email=email,
                phone=phone,
                first_name=payload["first_name"],
                last_name=payload["last_name"],
                passport=passport,
                birth_date=birth_date or None,
                status=myid.get('status', 'pending'),
                job_id=myid.get('job_id', ''),
                external_id=myid.get('external_id', external_id),
                payload=myid.get('payload', {}),
                verified_at=timezone.now() if myid.get('status') in ['verified', 'demo_verified'] else None,
            )
        except Exception as exc:
            kyc = KYCVerification.objects.create(
                session_id=session_id,
                email=email,
                phone=phone,
                first_name=payload["first_name"],
                last_name=payload["last_name"],
                passport=passport,
                birth_date=birth_date or None,
                status='failed',
                external_id=external_id,
                error=str(exc),
            )
            return Response({
                "session_id": kyc.session_id,
                "status": kyc.status,
                "error": kyc.error,
            }, status=status.HTTP_502_BAD_GATEWAY)

        return Response({
            "session_id": kyc.session_id,
            "status": kyc.status,
            "job_id": kyc.job_id,
            "external_id": kyc.external_id,
            "redirect_url": myid.get('redirect_url', ''),
            "demo": kyc.status == 'demo_verified',
        }, status=status.HTTP_201_CREATED)


class RegistrationMyIDStatusView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        session_id = request.data.get('session_id')
        kyc = KYCVerification.objects.filter(session_id=session_id).first()
        if not kyc:
            return Response({"detail": "KYC session not found"}, status=status.HTTP_404_NOT_FOUND)

        if kyc.status in ['verified', 'demo_verified', 'failed']:
            return Response({
                "session_id": kyc.session_id,
                "status": kyc.status,
                "payload": kyc.payload,
                "error": kyc.error,
            })

        try:
            result = get_myid_status(kyc.job_id)
            kyc.status = result.get('status', 'verified')
            kyc.payload = {**(kyc.payload or {}), "status_response": result.get('payload', {})}
            kyc.verified_at = timezone.now()
            kyc.save(update_fields=['status', 'payload', 'verified_at'])
        except Exception as exc:
            kyc.error = str(exc)
            kyc.save(update_fields=['error'])

        return Response({
            "session_id": kyc.session_id,
            "status": kyc.status,
            "payload": kyc.payload,
            "error": kyc.error,
        })


class RegistrationPhoneCodeView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        session_id = request.data.get('session_id')
        kyc = KYCVerification.objects.filter(session_id=session_id).first()
        if not kyc:
            return Response({"detail": "KYC session not found"}, status=status.HTTP_404_NOT_FOUND)
        if kyc.status not in ['verified', 'demo_verified']:
            return Response({"detail": "MyID verification must be completed first"}, status=status.HTTP_400_BAD_REQUEST)
        if not kyc.phone:
            return Response({"detail": "Phone is missing for this session"}, status=status.HTTP_400_BAD_REQUEST)

        code = generate_sms_code()
        sms = send_registration_sms(kyc.phone, code)
        kyc.sms_code = code
        kyc.sms_sent_at = timezone.now()
        kyc.payload = {
            **(kyc.payload or {}),
            "phone_sms": {
                "sent": bool(sms.get('sent')),
                "demo": bool(sms.get('demo')),
                "phone": sms.get('phone') or mask_phone(kyc.phone),
            }
        }
        kyc.save(update_fields=['sms_code', 'sms_sent_at', 'payload'])

        return Response({
            "session_id": kyc.session_id,
            "sent": bool(sms.get('sent')),
            "phone": sms.get('phone') or mask_phone(kyc.phone),
            "wait": sms.get('wait', 60000),
            "demo": bool(sms.get('demo')),
        })


class RegistrationPhoneVerifyView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        session_id = request.data.get('session_id')
        code = str(request.data.get('code', '')).strip()
        kyc = KYCVerification.objects.filter(session_id=session_id).first()
        if not kyc:
            return Response({"detail": "KYC session not found"}, status=status.HTTP_404_NOT_FOUND)
        if not code:
            return Response({"detail": "SMS code is required"}, status=status.HTTP_400_BAD_REQUEST)
        if not kyc.sms_code or code != kyc.sms_code:
            return Response({"detail": "Invalid SMS code"}, status=status.HTTP_400_BAD_REQUEST)

        kyc.phone_verified = True
        kyc.sms_verified_at = timezone.now()
        kyc.payload = {**(kyc.payload or {}), "phone_verified": True}
        kyc.save(update_fields=['phone_verified', 'sms_verified_at', 'payload'])
        return Response({
            "session_id": kyc.session_id,
            "phone_verified": True,
            "phone": mask_phone(kyc.phone),
        })

class ProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        profile, created = UserProfile.objects.get_or_create(user=user)
        return Response({
            "id": user.id,
            "email": user.email,
            "first_name": user.first_name if user.first_name else "",
            "last_name": user.last_name if user.last_name else "",
            "phone": profile.phone if profile.phone else "",
            "passport": profile.passport if profile.passport else "",
            "birth_date": profile.birth_date.isoformat() if profile.birth_date else "",
            "myid_status": profile.myid_status,
            "credits": float(profile.credits),
            "investments": float(profile.investments),
            "savings": float(profile.savings),
            "date_joined": user.date_joined.strftime('%Y-%m-%d')
        })

    def put(self, request):
        user = request.user
        data = request.data
        user.first_name = data.get('first_name', user.first_name)
        user.last_name = data.get('last_name', user.last_name)
        if 'email' in data:
            user.email = data.get('email')
            user.username = data.get('email')
        user.save()

        profile, created = UserProfile.objects.get_or_create(user=user)
        profile.phone = data.get('phone', profile.phone)
        if 'credits' in data:
            profile.credits = data.get('credits')
        if 'investments' in data:
            profile.investments = data.get('investments')
        if 'savings' in data:
            profile.savings = data.get('savings')
        profile.save()

        return Response({
            "message": "Profile updated successfully",
            "first_name": user.first_name,
            "last_name": user.last_name,
            "email": user.email,
            "phone": profile.phone,
            "credits": float(profile.credits),
            "investments": float(profile.investments),
            "savings": float(profile.savings),
        })

class CardListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        cards = Card.objects.filter(user=request.user)
        serializer = CardSerializer(cards, many=True)
        return Response(serializer.data)

    def post(self, request):
        serializer = CardSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(user=request.user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class CardDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request, pk):
        try:
            card = Card.objects.get(pk=pk, user=request.user)
            card.delete()
            return Response(status=status.HTTP_204_NO_CONTENT)
        except Card.DoesNotExist:
            return Response({"error": "Card not found"}, status=status.HTTP_404_NOT_FOUND)


class PaymeSubscribeCardCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        number = ''.join(ch for ch in str(request.data.get('number', '')) if ch.isdigit())
        expire = ''.join(ch for ch in str(request.data.get('expire', '')) if ch.isdigit())
        if len(number) < 16 or len(expire) != 4:
            return Response({"detail": "Card number and expire MMYY are required"}, status=status.HTTP_400_BAD_REQUEST)

        response = payme_subscribe_rpc('cards.create', {
            'card': {'number': number, 'expire': expire},
            'save': bool(request.data.get('save', True)),
            'customer': request.user.email,
        })
        return Response(response)


class PaymeSubscribeCardCodeView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        token = request.data.get('token')
        if not token:
            return Response({"detail": "token is required"}, status=status.HTTP_400_BAD_REQUEST)
        response = payme_subscribe_rpc('cards.get_verify_code', {'token': token})
        profile, _ = UserProfile.objects.get_or_create(user=request.user)
        registered_phone = mask_phone(profile.phone or '')
        result = response.setdefault('result', {})
        result['registered_phone'] = registered_phone
        if response.get('result', {}).get('phone') in [None, '', '99890*****00'] and registered_phone:
            result['phone'] = registered_phone
        return Response(response)


class PaymeSubscribeCardVerifyView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        token = request.data.get('token')
        code = request.data.get('code')
        if not token or not code:
            return Response({"detail": "token and code are required"}, status=status.HTTP_400_BAD_REQUEST)

        response = payme_subscribe_rpc('cards.verify', {
            'token': token,
            'code': code,
            'number': request.data.get('number', ''),
            'expire': request.data.get('expire', ''),
        })
        card_payload = response.get('result', {}).get('card', {})
        if not card_payload or not card_payload.get('verify'):
            return Response(response, status=status.HTTP_400_BAD_REQUEST)

        card, _ = Card.objects.update_or_create(
            user=request.user,
            payme_token=card_payload.get('token', token),
            defaults={
                'number': card_payload.get('number', '860000******0000'),
                'expiry': card_payload.get('expire', request.data.get('expire', '')),
                'balance': 0,
                'name': request.data.get('name') or 'Payme',
                'provider': 'payme',
                'payme_recurrent': bool(card_payload.get('recurrent', True)),
                'payme_verified': bool(card_payload.get('verify', True)),
                'payme_payload': card_payload,
            }
        )
        return Response({
            "payme": response,
            "card": CardSerializer(card).data,
        }, status=status.HTTP_201_CREATED)


class PaymeSubscribeReceiptView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        method = request.data.get('method', 'receipts.create')
        params = request.data.get('params', {})
        if method not in ['receipts.create', 'receipts.pay', 'receipts.check', 'receipts.get', 'receipts.cancel']:
            return Response({"detail": "Unsupported receipt method"}, status=status.HTTP_400_BAD_REQUEST)
        response = payme_subscribe_rpc(method, params, backend=True)
        return Response(response)


class PaymeCreateOrderView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        if missing_payme_checkout_config():
            return payme_config_error_response()

        amount = request.data.get('amount')
        purpose = request.data.get('purpose', 'application')
        target_id = request.data.get('target_id', '')
        description = request.data.get('description', '')

        try:
            amount_decimal = Decimal(str(amount))
        except Exception:
            return Response({"amount": "Invalid amount"}, status=status.HTTP_400_BAD_REQUEST)

        if amount_decimal <= 0:
            return Response({"amount": "Amount must be positive"}, status=status.HTTP_400_BAD_REQUEST)

        allowed_purposes = {choice[0] for choice in Order.PURPOSE_CHOICES}
        if purpose not in allowed_purposes:
            purpose = 'application'

        order = Order.objects.create(
            user=request.user,
            amount=amount_decimal,
            purpose=purpose,
            target_id=str(target_id) if target_id is not None else '',
            description=description[:255] if description else '',
        )
        order.checkout_url = build_payme_checkout_url(order)
        order.save(update_fields=['checkout_url'])

        if purpose == 'investment':
            startup = None
            if target_id and str(target_id).isdigit():
                startup = Startup.objects.filter(id=target_id).first()
            investment_amount = amount_decimal
            if request.data.get('display_amount') not in [None, '']:
                try:
                    investment_amount = Decimal(str(request.data.get('display_amount')))
                except Exception:
                    investment_amount = amount_decimal
            Investment.objects.create(
                investor=request.user,
                startup=startup,
                order=order,
                amount=investment_amount,
                comment=request.data.get('comment', ''),
            )

        return Response(OrderSerializer(order).data, status=status.HTTP_201_CREATED)


class LegalEntityProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        profile = LegalEntityProfile.objects.filter(user=request.user).first()
        if not profile:
            return Response({"detail": "Legal entity profile not created"}, status=status.HTTP_404_NOT_FOUND)
        return Response(LegalEntityProfileSerializer(profile).data)

    def post(self, request):
        profile = LegalEntityProfile.objects.filter(user=request.user).first()
        serializer = LegalEntityProfileSerializer(profile, data=request.data, partial=bool(profile))
        if serializer.is_valid():
            legal_profile = serializer.save(user=request.user)
            return Response(LegalEntityProfileSerializer(legal_profile).data, status=status.HTTP_200_OK if profile else status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def put(self, request):
        return self.post(request)


class LegalEntitySubmitView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        profile = LegalEntityProfile.objects.filter(user=request.user).first()
        if not profile:
            return Response({"detail": "Legal entity profile not created"}, status=status.HTTP_404_NOT_FOUND)

        missing = []
        for field in ['company_name', 'tin', 'registration_number', 'director_name', 'director_passport']:
            if not getattr(profile, field):
                missing.append(field)
        if not profile.accepted_terms or not profile.accepted_investment_risk:
            missing.append('agreements')
        if profile.myid_status not in ['verified', 'demo_verified']:
            missing.append('myid')
        if not profile.company_docs:
            missing.append('company_docs')

        if missing:
            return Response({"detail": "Profile is incomplete", "missing": missing}, status=status.HTTP_400_BAD_REQUEST)

        profile.status = 'pending_review'
        profile.submitted_at = timezone.now()
        profile.save(update_fields=['status', 'submitted_at', 'updated_at'])
        return Response(LegalEntityProfileSerializer(profile).data)


class MyIDStartView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        profile, _ = LegalEntityProfile.objects.get_or_create(
            user=request.user,
            defaults={'company_name': request.data.get('company_name', request.user.email or 'Company')}
        )
        session_id = f"myid-demo-{request.user.id}-{int(time.time())}"
        profile.director_passport = request.data.get('passport', profile.director_passport)
        profile.director_birth_date = request.data.get('birth_date') or profile.director_birth_date
        profile.myid_status = 'pending'
        profile.myid_session_id = session_id
        profile.myid_payload = {
            "mode": "demo" if not get_config('MYID_CLIENT_ID') else "api_ready",
            "passport": profile.director_passport,
            "birth_date": str(profile.director_birth_date) if profile.director_birth_date else request.data.get('birth_date', ''),
        }
        profile.save()

        return Response({
            "session_id": session_id,
            "status": profile.myid_status,
            "verification_url": get_config('MYID_VERIFICATION_URL', ''),
            "demo": not bool(get_config('MYID_CLIENT_ID')),
            "message": "MYID credentials are not configured; demo verification can be completed from frontend." if not get_config('MYID_CLIENT_ID') else "MYID session prepared.",
        })


class MyIDCompleteView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        profile = LegalEntityProfile.objects.filter(user=request.user).first()
        if not profile:
            return Response({"detail": "Legal entity profile not created"}, status=status.HTTP_404_NOT_FOUND)

        profile.myid_status = 'demo_verified' if not get_config('MYID_CLIENT_ID') else 'verified'
        profile.verified_at = timezone.now()
        profile.myid_payload = {
            **(profile.myid_payload or {}),
            "face_photo_received": bool(request.data.get('face_photo')),
            "verified_at": profile.verified_at.isoformat(),
        }
        profile.save(update_fields=['myid_status', 'verified_at', 'myid_payload', 'updated_at'])
        return Response(LegalEntityProfileSerializer(profile).data)


class StartupListCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        mine = request.query_params.get('mine') == '1'
        queryset = Startup.objects.select_related('legal_entity', 'owner').all()
        if mine:
            queryset = queryset.filter(owner=request.user)
        else:
            queryset = queryset.filter(status='active')
        return Response(StartupSerializer(queryset.order_by('-created_at'), many=True).data)

    def post(self, request):
        legal_profile = LegalEntityProfile.objects.filter(user=request.user).first()
        if not legal_profile:
            return Response({"detail": "Create legal entity profile first"}, status=status.HTTP_400_BAD_REQUEST)
        if legal_profile.status not in ['verified', 'pending_review']:
            return Response({"detail": "Legal entity must pass verification before publishing startups"}, status=status.HTTP_400_BAD_REQUEST)

        serializer = StartupSerializer(data=request.data)
        if serializer.is_valid():
            startup = serializer.save(
                owner=request.user,
                legal_entity=legal_profile,
                contact_email=request.data.get('contact_email') or request.user.email,
            )
            return Response(StartupSerializer(startup).data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class StartupDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        startup = Startup.objects.filter(pk=pk).first()
        if not startup:
            return Response({"detail": "Startup not found"}, status=status.HTTP_404_NOT_FOUND)
        return Response(StartupSerializer(startup).data)


class InvestmentListCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        investments = Investment.objects.filter(investor=request.user).select_related('startup', 'order')
        return Response(InvestmentSerializer(investments.order_by('-created_at'), many=True).data)

    def post(self, request):
        if missing_payme_checkout_config():
            return payme_config_error_response()

        startup = Startup.objects.filter(pk=request.data.get('startup')).first()
        if not startup:
            return Response({"startup": "Startup not found"}, status=status.HTTP_404_NOT_FOUND)
        amount = Decimal(str(request.data.get('amount', startup.min_investment)))
        order = Order.objects.create(
            user=request.user,
            amount=amount,
            purpose='investment',
            target_id=str(startup.id),
            description=f"Investment in {startup.name}",
        )
        order.checkout_url = build_payme_checkout_url(order)
        order.save(update_fields=['checkout_url'])
        investment = Investment.objects.create(
            investor=request.user,
            startup=startup,
            order=order,
            amount=amount,
            comment=request.data.get('comment', ''),
        )
        return Response(InvestmentSerializer(investment).data, status=status.HTTP_201_CREATED)


class ApplicationCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        if request.data.get('amount') and missing_payme_checkout_config():
            return payme_config_error_response()

        order = None
        amount = request.data.get('amount')
        if amount:
            order = Order.objects.create(
                user=request.user,
                amount=Decimal(str(amount)),
                purpose='application',
                target_id=str(request.data.get('target_id', '')),
                description=request.data.get('app_type', 'application')[:255],
            )
            order.checkout_url = build_payme_checkout_url(order)
            order.save(update_fields=['checkout_url'])
        return Response({
            "message": "Application accepted",
            "order": OrderSerializer(order).data if order else None,
        }, status=status.HTTP_201_CREATED)


class UserOrdersView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        orders = Order.objects.filter(user=request.user).order_by('-created_at')
        return Response(OrderSerializer(orders, many=True).data)



import openpyxl
from django.http import HttpResponse

def download_financial_report(request):
    user = request.user
    profile = user.profile
    
    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = "Financial Report"
    
    # Заголовки
    ws.append(['Kategoriya', 'Summa (UZS)'])
    ws.append(['Jamg\'armalar', profile.savings])
    ws.append(['Investitsiyalar', profile.investments])
    ws.append(['Kreditlar', profile.credits])
    
    response = HttpResponse(content_type='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
    response['Content-Disposition'] = 'attachment; filename=report.xlsx'
    wb.save(response)
    return response
