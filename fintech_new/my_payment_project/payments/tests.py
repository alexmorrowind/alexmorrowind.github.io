import base64
from urllib.parse import unquote, urlparse

from django.test import TestCase, override_settings

from .integrations import normalize_payme_subscribe_base_url
from .models import APIConfiguration, Order
from .views import PaymeWebhookView, build_payme_checkout_url, normalize_payme_checkout_url


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

    def test_change_password_updates_admin_configuration(self):
        response = self.view._change_password({'password': 'new-payme-secret'}, 7)

        self.assertEqual(response.data['result']['success'], True)
        self.assertEqual(
            APIConfiguration.objects.get(key='PAYME_MERCHANT_KEY').value,
            'new-payme-secret',
        )
