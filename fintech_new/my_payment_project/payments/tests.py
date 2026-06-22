from django.test import TestCase

from .views import normalize_payme_checkout_url


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
