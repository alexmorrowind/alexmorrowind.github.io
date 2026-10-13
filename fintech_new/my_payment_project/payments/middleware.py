import json
import time
import uuid

from django.utils.deprecation import MiddlewareMixin

from .models import RequestLog


SENSITIVE_KEYS = (
    'password', 'secret', 'token', 'authorization', 'client_hash',
    'client_secret', 'sdk_code', 'access', 'refresh', 'jwt', 'code',
    'pinfl', 'passport', 'base64', 'photo', 'image',
)
MAX_BODY_BYTES = 16 * 1024
MAX_VALUE_LENGTH = 500


def _is_sensitive_key(key):
    key = str(key or '').lower().replace('-', '_')
    return any(part in key for part in SENSITIVE_KEYS)


def _redact(value, key=''):
    if _is_sensitive_key(key):
        return '[REDACTED]'
    if isinstance(value, dict):
        return {str(k): _redact(v, str(k)) for k, v in list(value.items())[:100]}
    if isinstance(value, (list, tuple)):
        return [_redact(item, key) for item in list(value)[:100]]
    if isinstance(value, str):
        return value[:MAX_VALUE_LENGTH]
    if value is None or isinstance(value, (bool, int, float)):
        return value
    return str(value)[:MAX_VALUE_LENGTH]


def _client_ip(request):
    forwarded = request.META.get('HTTP_X_FORWARDED_FOR', '')
    if forwarded:
        return forwarded.split(',')[0].strip() or None
    return request.META.get('REMOTE_ADDR') or None


class RequestLogMiddleware(MiddlewareMixin):
    """Persist a redacted HTTP request audit row for the admin."""

    def process_request(self, request):
        request._b1_request_started_at = time.monotonic()
        request._b1_request_id = uuid.uuid4().hex[:20]

    def process_response(self, request, response):
        self._write_log(request, response=response)
        request_id = getattr(request, '_b1_request_id', '')
        if request_id:
            response['X-Request-ID'] = request_id
        return response

    def process_exception(self, request, exception):
        self._write_log(request, error=exception)
        return None

    def _write_log(self, request, response=None, error=None):
        path = request.path or '/'
        if path.startswith('/static/') or path == '/favicon.ico':
            return

        started = getattr(request, '_b1_request_started_at', time.monotonic())
        duration_ms = max(0, int((time.monotonic() - started) * 1000))
        status_code = getattr(response, 'status_code', None)
        user = getattr(request, 'user', None)
        if not getattr(user, 'is_authenticated', False):
            user = None

        query_params = _redact(dict(request.GET.lists()))
        body = {}
        content_type = request.META.get('CONTENT_TYPE', '')
        try:
            raw_body = request.body[:MAX_BODY_BYTES]
            body_size = len(request.body)
        except Exception:
            raw_body = b''
            body_size = 0
        if raw_body and 'application/json' in content_type:
            try:
                body = _redact(json.loads(raw_body.decode('utf-8')))
            except (UnicodeDecodeError, ValueError):
                body = {'_body': '[invalid json]'}
        elif raw_body and 'application/x-www-form-urlencoded' in content_type:
            body = _redact(dict(request.POST.lists()))
        elif raw_body:
            body = {'_body': f'[{body_size} bytes omitted]'}

        try:
            RequestLog.objects.create(
                request_id=getattr(request, '_b1_request_id', ''),
                method=request.method[:12],
                path=path[:500],
                status_code=status_code,
                duration_ms=duration_ms,
                ip_address=_client_ip(request),
                user=user,
                username=(user.get_username() if user else ''),
                user_agent=request.META.get('HTTP_USER_AGENT', '')[:500],
                query_params=query_params,
                request_body=body,
                response_summary=(
                    f'{getattr(response, "reason_phrase", "")}'[:300]
                    if response is not None else ''
                ),
                error=str(error)[:2000] if error else '',
            )
        except Exception:
            # Observability must never become a production outage.
            return
