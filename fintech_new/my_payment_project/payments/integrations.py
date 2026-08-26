import base64
import json
import os
import time
import uuid
from urllib import parse, request

PLACEHOLDER_PREFIXES = ('your_', 'paste_', 'change-me', 'сюда_', 'example')
CONFIG_ALIASES = {
    'PAYME_SUBSCRIBE_ID': 'PAYME_MERCHANT_ID',
    'PAYME_SUBSCRIBE_KEY': 'PAYME_MERCHANT_KEY',
}
PAYME_PRODUCTION_CHECKOUT_URL = 'https://checkout.paycom.uz'
PAYME_PRODUCTION_SUBSCRIBE_URL = 'https://checkout.paycom.uz/api'
CONFIG_DEFAULTS = {
    'PAYME_CHECKOUT_URL': PAYME_PRODUCTION_CHECKOUT_URL,
    'PAYME_SUBSCRIBE_BASE_URL': PAYME_PRODUCTION_SUBSCRIBE_URL,
    'PAYME_ACCOUNT_KEY': 'Bpay',
    'OCTO_API_BASE_URL': 'https://secure.octo.uz',
    'OCTO_P2P_ENABLED': 'false',
}


def config_value_is_set(value):
    if value is None:
        return False
    normalized = str(value).strip()
    if not normalized:
        return False
    return not normalized.lower().startswith(PLACEHOLDER_PREFIXES)


def raw_env_bool(name, default=False):
    value = os.environ.get(name)
    if value is None:
        return default
    return str(value).lower() in ['1', 'true', 'yes', 'on']


def payme_test_mode_enabled():
    return raw_env_bool('PAYME_TEST_MODE', default=False)


def effective_config_value(key, value):
    if not config_value_is_set(value) or payme_test_mode_enabled():
        return value

    if key == 'PAYME_CHECKOUT_URL':
        parsed = parse.urlsplit(str(value) if '://' in str(value) else f'https://{value}')
        if 'test.paycom.uz' in parsed.netloc.lower():
            return PAYME_PRODUCTION_CHECKOUT_URL

    if key == 'PAYME_SUBSCRIBE_BASE_URL':
        parsed = parse.urlsplit(str(value) if '://' in str(value) else f'https://{value}')
        if 'test.paycom.uz' in parsed.netloc.lower():
            return PAYME_PRODUCTION_SUBSCRIBE_URL

    return value


def get_config(key, default=None):
    env_value = os.environ.get(key)
    if config_value_is_set(env_value):
        return effective_config_value(key, env_value)

    alias = CONFIG_ALIASES.get(key)
    if alias:
        alias_env_value = os.environ.get(alias)
        if config_value_is_set(alias_env_value):
            return alias_env_value

    try:
        from payments.models import APIConfiguration
        config = APIConfiguration.objects.filter(key=key, is_active=True).first()
        if config and config_value_is_set(config.value):
            return effective_config_value(key, config.value)
        if alias:
            alias_config = APIConfiguration.objects.filter(key=alias, is_active=True).first()
            if alias_config and config_value_is_set(alias_config.value):
                return alias_config.value
    except Exception:
        pass
    if default is None:
        default = CONFIG_DEFAULTS.get(key)
    return default


def env_bool(name, default=False):
    value = get_config(name)
    if value is None:
        return default
    if isinstance(value, bool):
        return value
    return str(value).lower() in ['1', 'true', 'yes', 'on']


def normalize_phone(phone):
    return ''.join(ch for ch in str(phone or '') if ch.isdigit())


def mask_phone(phone):
    digits = normalize_phone(phone)
    if len(digits) < 7:
        return phone or ''
    return f"{digits[:5]}***{digits[-2:]}"


def _post_json(url, payload, headers=None, timeout=20):
    data = json.dumps(payload).encode('utf-8')
    req = request.Request(
        url,
        data=data,
        method='POST',
        headers={'Content-Type': 'application/json', **(headers or {})},
    )
    with request.urlopen(req, timeout=timeout) as response:
        return json.loads(response.read().decode('utf-8') or '{}')


def _post_form(url, payload, headers=None, timeout=20):
    data = parse.urlencode(payload).encode('utf-8')
    req = request.Request(
        url,
        data=data,
        method='POST',
        headers={'Content-Type': 'application/x-www-form-urlencoded', **(headers or {})},
    )
    with request.urlopen(req, timeout=timeout) as response:
        return json.loads(response.read().decode('utf-8') or '{}')


def myid_is_configured():
    return all([
        get_config('MYID_BASE_URL'),
        get_config('MYID_CLIENT_ID'),
        get_config('MYID_USERNAME'),
        get_config('MYID_PASSWORD'),
    ])


def get_myid_access_token():
    base_url = get_config('MYID_BASE_URL').rstrip('/')
    payload = {
        'grant_type': 'password',
        'username': get_config('MYID_USERNAME'),
        'password': get_config('MYID_PASSWORD'),
        'client_id': get_config('MYID_CLIENT_ID'),
    }
    response = _post_form(f'{base_url}/api/v1/oauth2/access-token', payload, timeout=5)
    return response['access_token'], response


def start_myid_authentication(payload):
    if not myid_is_configured():
        return {
            'demo': True,
            'status': 'demo_verified',
            'job_id': f"myid-demo-{int(time.time())}",
            'external_id': payload.get('external_id') or str(uuid.uuid4()),
            'payload': {
                'first_name': payload.get('first_name', ''),
                'last_name': payload.get('last_name', ''),
                'phone': payload.get('phone', ''),
                'passport': payload.get('pass_data', ''),
                'birth_date': payload.get('birth_date', ''),
                'source': 'demo',
            },
        }

    access_token, token_payload = get_myid_access_token()
    base_url = get_config('MYID_BASE_URL').rstrip('/')
    external_id = payload.get('external_id') or str(uuid.uuid4())
    request_payload = {
        'pass_data': payload.get('pass_data', '').upper(),
        'pinfl': payload.get('pinfl', ''),
        'birth_date': payload.get('birth_date'),
        'photo_from_camera': {
            'front': payload.get('photo_from_camera', {}).get('front') or payload.get('front'),
        },
        'agreed_on_terms': bool(payload.get('agreed_on_terms')),
        'client_id': get_config('MYID_CLIENT_ID'),
        'device': payload.get('device') or {'platform': 'web', 'app': 'B1'},
        'threshold': payload.get('threshold', 0.5),
        'external_id': external_id,
        'is_resident': payload.get('is_resident', True),
    }
    response = _post_json(
        f'{base_url}/api/v1/authentication/simple-inplace-authentication-request-task',
        request_payload,
        headers={'Authorization': f'Bearer {access_token}'},
        timeout=5,
    )
    return {
        'demo': False,
        'status': 'pending',
        'job_id': response.get('job_id') or response.get('jobId') or response.get('id', ''),
        'external_id': external_id,
        'payload': {'token': token_payload, 'task': response},
    }


def get_myid_status(job_id):
    if not myid_is_configured():
        return {'status': 'demo_verified', 'payload': {'source': 'demo'}}

    access_token, _ = get_myid_access_token()
    base_url = get_config('MYID_BASE_URL').rstrip('/')
    query = parse.urlencode({'job_id': job_id})
    response = _post_json(
        f'{base_url}/api/v1/authentication/simple-inplace-authentication-request-status?{query}',
        {},
        headers={'Authorization': f'Bearer {access_token}'},
        timeout=30,
    )
    return {'status': 'verified', 'payload': response}


def generate_sms_code():
    if env_bool('SMS_DEMO_MODE', default=True):
        return get_config('SMS_DEMO_CODE', '666666')
    return str(int(time.time() * 1000))[-6:]


def send_registration_sms(phone, code):
    sms_url = get_config('SMS_PROVIDER_URL')
    sms_token = get_config('SMS_PROVIDER_TOKEN')
    if not sms_url or not sms_token:
        return {
            'demo': True,
            'sent': True,
            'phone': mask_phone(phone),
            'wait': 60000,
        }

    response = _post_json(
        sms_url,
        {'phone': normalize_phone(phone), 'message': f'B1 verification code: {code}'},
        headers={'Authorization': f'Bearer {sms_token}'},
        timeout=10,
    )
    return {
        'demo': False,
        'sent': True,
        'phone': mask_phone(phone),
        'payload': response,
        'wait': 60000,
    }


def payme_subscribe_is_configured(require_password=False):
    has_id = bool(get_config('PAYME_SUBSCRIBE_ID'))
    has_password = bool(get_config('PAYME_SUBSCRIBE_KEY'))
    return has_id and (has_password if require_password else True)


def normalize_payme_subscribe_base_url(base_url):
    raw_url = str(base_url or '').strip().rstrip('/')
    if not raw_url:
        return raw_url

    parsed = parse.urlsplit(raw_url if '://' in raw_url else f'https://{raw_url}')
    hostname = parsed.netloc.lower()
    path = parsed.path.rstrip('/')

    if hostname == 'test.paycom.uz':
        hostname = 'checkout.test.paycom.uz'
    elif hostname == 'paycom.uz':
        hostname = 'checkout.paycom.uz'

    if not path:
        path = '/api'

    return parse.urlunsplit((parsed.scheme or 'https', hostname, path, '', ''))


def payme_subscribe_rpc(method, params, backend=False):
    if not payme_subscribe_is_configured(require_password=backend):
        return _payme_subscribe_demo(method, params)

    base_url = normalize_payme_subscribe_base_url(
        get_config('PAYME_SUBSCRIBE_BASE_URL', 'https://checkout.paycom.uz/api')
    )
    cashier_id = get_config('PAYME_SUBSCRIBE_ID')
    auth = cashier_id
    if backend:
        auth = f"{cashier_id}:{get_config('PAYME_SUBSCRIBE_KEY')}"

    payload = {
        'id': int(time.time() * 1000),
        'method': method,
        'params': params,
    }
    return _post_json(base_url, payload, headers={'X-Auth': auth}, timeout=20)


def _mask_card(number):
    digits = ''.join(ch for ch in str(number) if ch.isdigit())
    if len(digits) < 10:
        return '****'
    return f"{digits[:6]}******{digits[-4:]}"


def octo_p2p_status():
    enabled = env_bool('OCTO_P2P_ENABLED', default=False)
    has_secret = bool(get_config('OCTO_SECRET_KEY'))
    has_endpoint = bool(get_config('OCTO_P2P_ENDPOINT'))
    has_merchant = bool(get_config('OCTO_SHOP_ID') or get_config('OCTO_MERCHANT_ID'))
    return {
        'enabled': enabled,
        'configured': enabled and has_secret and has_endpoint and has_merchant,
        'missing': [
            key for key, present in [
                ('OCTO_P2P_ENABLED', enabled),
                ('OCTO_SECRET_KEY', has_secret),
                ('OCTO_P2P_ENDPOINT', has_endpoint),
                ('OCTO_SHOP_ID', has_merchant),
            ] if not present
        ],
        'product': 'OCTO Money Transfer',
    }


def create_octo_p2p_transfer_payload(transfer, recipient, source_card=None):
    merchant_id = get_config('OCTO_SHOP_ID') or get_config('OCTO_MERCHANT_ID')
    payload = {
        'shop_transaction_id': str(transfer.shop_transaction_id),
        'amount': str(transfer.amount),
        'currency': transfer.currency,
        'recipient': ''.join(ch for ch in str(recipient or '') if ch.isdigit()),
        'merchant_id': merchant_id,
        'description': transfer.note or 'B1 P2P transfer',
    }
    if source_card:
        payload['source_card_id'] = source_card.id
    return payload


def submit_octo_p2p_transfer(transfer, recipient, source_card=None):
    status_payload = octo_p2p_status()
    if not status_payload['configured']:
        return {
            'sent': False,
            'status': 'provider_not_connected',
            'provider_status': 'not_configured',
            'payload': status_payload,
            'message': (
                'OCTO Money Transfer needs a separate P2P contract/API endpoint. '
                'The transfer request was saved but not sent to Octo.'
            ),
        }

    endpoint = get_config('OCTO_P2P_ENDPOINT')
    secret_key = get_config('OCTO_SECRET_KEY')
    payload = create_octo_p2p_transfer_payload(transfer, recipient, source_card)
    response = _post_json(
        endpoint,
        payload,
        headers={'Authorization': f'Bearer {secret_key}'},
        timeout=20,
    )
    return {
        'sent': True,
        'status': 'pending',
        'provider_status': str(response.get('status') or response.get('state') or 'sent'),
        'provider_reference': str(response.get('id') or response.get('transaction_id') or response.get('uuid') or ''),
        'payload': response,
        'message': 'Transfer request sent to Octo.',
    }


def _payme_subscribe_demo(method, params):
    if method == 'cards.create':
        card = params.get('card', {})
        return {
            'jsonrpc': '2.0',
            'result': {
                'card': {
                    'number': _mask_card(card.get('number', '8600000000000000')),
                    'expire': card.get('expire', '0399'),
                    'token': 'demo-card-token-' + base64.urlsafe_b64encode(str(time.time()).encode()).decode().rstrip('='),
                    'recurrent': bool(params.get('save', True)),
                    'verify': False,
                }
            }
        }
    if method == 'cards.get_verify_code':
        return {'jsonrpc': '2.0', 'result': {'sent': True, 'phone': '99890*****00', 'wait': 60000}}
    if method == 'cards.verify':
        token = params.get('token', '')
        return {
            'jsonrpc': '2.0',
            'result': {
                'card': {
                    'number': params.get('number', '860000******0000'),
                    'expire': params.get('expire', '03/99'),
                    'token': token,
                    'recurrent': True,
                    'verify': True,
                }
            }
        }
    if method == 'cards.check':
        return {'jsonrpc': '2.0', 'result': {'card': {'token': params.get('token'), 'verify': True}}}
    if method == 'cards.remove':
        return {'jsonrpc': '2.0', 'result': {'success': True}}
    if method == 'receipts.create':
        return {
            'jsonrpc': '2.0',
            'result': {
                'receipt': {
                    '_id': 'demo-receipt-' + str(int(time.time())),
                    'state': 0,
                    'amount': params.get('amount'),
                    'account': params.get('account'),
                }
            }
        }
    if method == 'receipts.pay':
        return {
            'jsonrpc': '2.0',
            'result': {'receipt': {'_id': params.get('id'), 'state': 4, 'pay_time': int(time.time() * 1000)}}
        }
    return {'jsonrpc': '2.0', 'result': {'demo': True, 'method': method, 'params': params}}
