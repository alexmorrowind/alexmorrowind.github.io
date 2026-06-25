import base64
import os
import time
from urllib.parse import unquote, urlparse

from django.test import TestCase, override_settings
from django.contrib.auth.models import User
from rest_framework.test import APIClient

from .integrations import normalize_payme_subscribe_base_url
from .models import APIConfiguration, Order, PaymeTransaction
from .views import (
    PAYME_SANDBOX_ALIAS_TARGET_ID,
    PaymeWebhookView,
    build_payme_checkout_url,
    get_payme_merchant_keys,
    normalize_payme_checkout_url,
)


class PaymeCheckoutUrlTests(TestCase):
    def test_payme_sandbox_base_url_is_normalized_to_checkout_host(self):
        url = normalize_payme_checkout_url('https://test.paycom.uz')

        self.assertEqual(url, 'https://checkout.test.paycom.uz')

    def test_payme_production_base_url_is_normalized_to_checkout_host(self):
        url = normalize_payme_checkout_url('https://paycom.uz')

        self.assertEqual(url, 'https://checkout.paycom.uz')

    def test_checkout_api_suffix_is_removed_for_checkout_redirects(self):
        url = normalize_payme_checkout_url('https://checkout.test.paycom.uz/api')

        self.assertEqual(url, 'https://checkout.test.paycom.uz')

    @override_settings()
    def test_checkout_payload_uses_single_configured_account_key(self):
        order = Order.objects.create(amount='1000.00', purpose='card_order')

        url = build_payme_checkout_url(order)
        encoded_payload = unquote(urlparse(url).path.lstrip('/'))
        payload = base64.b64decode(encoded_payload).decode('utf-8')

        self.assertIn(f"ac.Bpay={order.id}", payload)
        self.assertNotIn("ac.order_id=", payload)
        self.assertEqual(payload.count(';ac.'), 1)


class PaymeSubscribeUrlTests(TestCase):
    def test_subscribe_sandbox_base_url_is_normalized_to_checkout_api(self):
        url = normalize_payme_subscribe_base_url('https://test.paycom.uz/api')

        self.assertEqual(url, 'https://checkout.test.paycom.uz/api')

    def test_subscribe_base_url_adds_api_path_when_missing(self):
        url = normalize_payme_subscribe_base_url('checkout.test.paycom.uz')

        self.assertEqual(url, 'https://checkout.test.paycom.uz/api')


class PaymeWebhookValidationTests(TestCase):
    def setUp(self):
        self.view = PaymeWebhookView()

    def test_check_perform_transaction_rejects_invalid_amount_format(self):
        response = self.view._check_perform_transaction({
            'amount': 'not-a-number',
            'account': {'Bpay': 'missing'},
        }, 1)

        self.assertEqual(response.data['error']['code'], -31001)

    def test_create_transaction_rejects_invalid_amount_format(self):
        response = self.view._create_transaction({
            'id': 'payme-test-id',
            'amount': 'not-a-number',
            'account': {'Bpay': 'missing'},
            'time': 1,
        }, 2)

        self.assertEqual(response.data['error']['code'], -31001)

    def test_check_perform_transaction_rejects_wrong_order_amount(self):
        order = Order.objects.create(amount='1000.00', purpose='card_order')
        response = self.view._check_perform_transaction({
            'amount': 100001,
            'account': {'Bpay': str(order.id)},
        }, 3)

        self.assertEqual(response.data['error']['code'], -31001)

    def test_check_perform_transaction_accepts_payme_sandbox_alias(self):
        Order.objects.create(amount='1000.00', purpose='card_order')

        response = self.view._check_perform_transaction({
            'amount': 100000,
            'account': {'Bpay': 'Bpay'},
        }, 4)

        self.assertEqual(response.data['result']['allow'], True)

    def test_check_perform_transaction_rejects_wrong_amount_for_sandbox_alias(self):
        Order.objects.create(amount='1000.00', purpose='card_order')

        response = self.view._check_perform_transaction({
            'amount': 50000,
            'account': {'Bpay': 'Bpay'},
        }, 5)

        self.assertEqual(response.data['error']['code'], -31001)

    def test_create_transaction_uses_payme_sandbox_alias(self):
        Order.objects.create(amount='1000.00', purpose='card_order')

        response = self.view._create_transaction({
            'id': 'payme-test-id',
            'amount': 100000,
            'account': {'Bpay': 'Bpay'},
            'time': 123456,
        }, 6)

        self.assertEqual(response.data['result']['state'], 1)

    def test_sandbox_alias_reuses_isolated_order_across_multiple_runs(self):
        create_time = int(time.time() * 1000)
        first_check = self.view._check_perform_transaction({
            'amount': 100000,
            'account': {'Bpay': 'Bpay'},
        }, 6)
        self.assertEqual(first_check.data['result']['allow'], True)
        self.assertEqual(
            Order.objects.filter(target_id=PAYME_SANDBOX_ALIAS_TARGET_ID, status='pending').count(),
            1,
        )

        first_create = self.view._create_transaction({
            'id': 'payme-sandbox-repeat-1',
            'amount': 100000,
            'account': {'Bpay': 'Bpay'},
            'time': create_time,
        }, 61)
        self.assertEqual(first_create.data['result']['state'], 1)

        first_perform = self.view._perform_transaction({'id': 'payme-sandbox-repeat-1'}, 62)
        self.assertEqual(first_perform.data['result']['state'], 2)
        self.assertEqual(
            Order.objects.filter(target_id=PAYME_SANDBOX_ALIAS_TARGET_ID, status='pending').count(),
            0,
        )

        second_check = self.view._check_perform_transaction({
            'amount': 100000,
            'account': {'Bpay': 'Bpay'},
        }, 63)
        self.assertEqual(second_check.data['result']['allow'], True)
        self.assertEqual(
            Order.objects.filter(target_id=PAYME_SANDBOX_ALIAS_TARGET_ID, status='pending').count(),
            1,
        )

    def test_sandbox_alias_does_not_consume_real_pending_orders(self):
        real_order = Order.objects.create(amount='1000.00', purpose='card_order')

        response = self.view._check_perform_transaction({
            'amount': 100000,
            'account': {'Bpay': 'Bpay'},
        }, 64)

        real_order.refresh_from_db()

        self.assertEqual(response.data['result']['allow'], True)
        self.assertEqual(real_order.status, 'pending')
        self.assertFalse(
            Order.objects.filter(target_id=PAYME_SANDBOX_ALIAS_TARGET_ID, id=real_order.id).exists()
        )

    def test_change_password_updates_admin_configuration(self):
        response = self.view._change_password({'password': 'new-payme-secret'}, 7)

        self.assertEqual(response.data['result']['success'], True)
        self.assertEqual(
            APIConfiguration.objects.get(key='PAYME_MERCHANT_KEY').value,
            'new-payme-secret',
        )

    def test_merchant_keys_include_admin_and_env_values(self):
        APIConfiguration.objects.update_or_create(
            key='PAYME_MERCHANT_KEY',
            defaults={'value': 'admin-secret', 'is_active': True},
        )

        original = os.environ.get('PAYME_MERCHANT_KEY')
        os.environ['PAYME_MERCHANT_KEY'] = 'env-secret'
        try:
            self.assertIn('admin-secret', get_payme_merchant_keys())
            self.assertIn('env-secret', get_payme_merchant_keys())
        finally:
            if original is None:
                os.environ.pop('PAYME_MERCHANT_KEY', None)
            else:
                os.environ['PAYME_MERCHANT_KEY'] = original

    def test_check_transaction_always_includes_reason_field(self):
        order = Order.objects.create(amount='1000.00', purpose='card_order')
        tx = PaymeTransaction.objects.create(
            payme_id='tx-1',
            order=order,
            amount=100000,
            state=1,
            create_time=int(time.time() * 1000),
        )

        result = self.view._check_transaction_result(tx)

        self.assertIn('reason', result)
        self.assertIsNone(result['reason'])

    def test_create_transaction_rejects_existing_transaction_for_different_order(self):
        order_a = Order.objects.create(amount='1000.00', purpose='card_order')
        order_b = Order.objects.create(amount='1000.00', purpose='card_order')
        PaymeTransaction.objects.create(
            payme_id='payme-test-id',
            order=order_a,
            amount=100000,
            state=1,
            create_time=123456,
        )

        response = self.view._create_transaction({
            'id': 'payme-test-id',
            'amount': 100000,
            'account': {'Bpay': str(order_b.id)},
            'time': 123456,
        }, 8)

        self.assertEqual(response.data['error']['code'], -31008)

    def test_perform_transaction_times_out_old_transaction(self):
        order = Order.objects.create(amount='1000.00', purpose='card_order')
        tx = PaymeTransaction.objects.create(
            payme_id='payme-timeout-id',
            order=order,
            amount=100000,
            state=1,
            create_time=int(time.time() * 1000) - (13 * 60 * 60 * 1000),
        )

        response = self.view._perform_transaction({'id': tx.payme_id}, 9)

        tx.refresh_from_db()
        order.refresh_from_db()

        self.assertEqual(response.data['error']['code'], -31008)
        self.assertEqual(tx.state, -1)
        self.assertEqual(tx.reason, 4)
        self.assertEqual(order.status, 'canceled')


class PaymeMerchantEndpointTests(TestCase):
    def setUp(self):
        APIConfiguration.objects.update_or_create(
            key='PAYME_MERCHANT_KEY',
            defaults={'value': 'test_merchant_secret_key', 'is_active': True},
        )
        self.client = APIClient()
        self.user = User.objects.create_user(
            username='payme-tester',
            email='payme-tester@example.com',
            password='Testpass123',
        )
        self.client.force_authenticate(user=self.user)
        self.auth = self._auth_header('test_merchant_secret_key')

    def _auth_header(self, password):
        encoded = base64.b64encode(f"Paycom:{password}".encode()).decode()
        return f"Basic {encoded}"

    def _rpc(self, method, params=None, request_id=1, auth=None):
        return self.client.post(
            '/api/payme/',
            {
                'jsonrpc': '2.0',
                'id': request_id,
                'method': method,
                'params': params or {},
            },
            format='json',
            HTTP_AUTHORIZATION=auth or self.auth,
        )

    def test_payme_endpoint_completes_main_transaction_lifecycle(self):
        order = Order.objects.create(amount='1000.00', purpose='card_order')
        account = {'Bpay': str(order.id)}
        payme_id = 'payme-endpoint-test-id'
        create_time = int(time.time() * 1000)

        check = self._rpc('CheckPerformTransaction', {'amount': 100000, 'account': account}, 1)
        self.assertEqual(check.status_code, 200)
        self.assertEqual(check.data['result']['allow'], True)

        create = self._rpc('CreateTransaction', {
            'id': payme_id,
            'amount': 100000,
            'account': account,
            'time': create_time,
        }, 2)
        self.assertEqual(create.status_code, 200)
        self.assertEqual(create.data['result']['state'], 1)
        self.assertEqual(create.data['result']['create_time'], create_time)

        before_perform = self._rpc('CheckTransaction', {'id': payme_id}, 3)
        self.assertEqual(before_perform.status_code, 200)
        self.assertEqual(before_perform.data['result']['state'], 1)
        self.assertIn('reason', before_perform.data['result'])
        self.assertIsNone(before_perform.data['result']['reason'])

        perform = self._rpc('PerformTransaction', {'id': payme_id}, 4)
        self.assertEqual(perform.status_code, 200)
        self.assertEqual(perform.data['result']['state'], 2)

        statement = self._rpc('GetStatement', {'from': create_time - 1, 'to': int(time.time() * 1000) + 1000}, 5)
        self.assertEqual(statement.status_code, 200)
        self.assertEqual(statement.data['result']['transactions'][0]['id'], payme_id)

    def test_payme_endpoint_returns_http_200_for_payme_errors(self):
        auth_error = self.client.post(
            '/api/payme/',
            {'jsonrpc': '2.0', 'id': 10, 'method': 'CheckPerformTransaction', 'params': {}},
            format='json',
        )
        self.assertEqual(auth_error.status_code, 200)
        self.assertEqual(auth_error.data['error']['code'], -32504)

        missing_order = self._rpc('CheckPerformTransaction', {
            'amount': 100000,
            'account': {'Bpay': '999999'},
        }, 11)
        self.assertEqual(missing_order.status_code, 200)
        self.assertEqual(missing_order.data['error']['code'], -31050)
        self.assertEqual(missing_order.data['error']['data'], 'Bpay')

    def test_payme_order_amount_is_limited_on_backend(self):
        low = self.client.post('/api/payme/create-order/', {
            'amount': 999,
            'purpose': 'card_order',
        }, format='json')
        self.assertEqual(low.status_code, 400)
        self.assertIn('min_amount', low.data)

        high = self.client.post('/api/payme/create-order/', {
            'amount': 10000001,
            'purpose': 'card_order',
        }, format='json')
        self.assertEqual(high.status_code, 400)
        self.assertIn('max_amount', high.data)

        ok = self.client.post('/api/payme/create-order/', {
            'amount': 1000,
            'purpose': 'card_order',
        }, format='json')
        self.assertEqual(ok.status_code, 201)
