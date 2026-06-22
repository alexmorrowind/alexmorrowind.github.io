from django.test import TestCase

from .integrations import normalize_payme_subscribe_base_url
from .models import Order
from .views import PaymeWebhookView, normalize_payme_checkout_url


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
