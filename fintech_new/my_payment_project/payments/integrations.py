import base64
import json
import os
import time
import uuid
from urllib import parse, request

PLACEHOLDER_PREFIXES = ('your_', 'paste_', 'change-me', 'сюда_', 'example')


def config_value_is_set(value):
    if value is None:
        return False
    normalized = str(value).strip()
    if not normalized:
        return False
    return not normalized.lower().startswith(PLACEHOLDER_PREFIXES)


def get_config(key, default=None):
    try:
        from payments.models import APIConfiguration
        config = APIConfiguration.objects.filter(key=key, is_active=True).first()
        if config and config_value_is_set(config.value):
            return config.value
    except Exception:
        pass
    env_value = os.environ.get(key)
    return env_value if config_value_is_set(env_value) else default


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
        get_config('PAYME_SUBSCRIBE_BASE_URL', 'https://checkout.test.paycom.uz/api')
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
