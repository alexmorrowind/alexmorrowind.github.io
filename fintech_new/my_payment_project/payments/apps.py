from django.apps import AppConfig
from django.db.models.signals import post_migrate

def populate_api_configs(sender, **kwargs):
    try:
        from payments.models import APIConfiguration
    except ImportError:
        return
    import os

    default_descriptions = {
        'PAYME_MERCHANT_ID': 'Payme Merchant / Cashier ID used for checkout.',
        'PAYME_MERCHANT_KEY': 'Payme Merchant / Cashier Secret Key.',
        'PAYME_CHECKOUT_URL': 'Payme Checkout Base URL (e.g., https://checkout.test.paycom.uz).',
        'PAYME_CALLBACK_URL': 'Return URL after payment completes (e.g. index.html).',
        'PAYME_ACCOUNT_KEY': 'Payme account field name from cabinet (for this cashbox: Bpay).',
        'PAYME_SUBSCRIBE_ID': 'Payme Subscribe ID for card linking.',
        'PAYME_SUBSCRIBE_KEY': 'Payme Subscribe Key (secret password) for card linking.',
        'PAYME_SUBSCRIBE_BASE_URL': 'Payme Subscribe Base API URL.',
        'MYID_BASE_URL': 'MyID Base URL (e.g., https://docs.myid.uz).',
        'MYID_CLIENT_ID': 'MyID Client ID.',
        'MYID_USERNAME': 'MyID username.',
        'MYID_PASSWORD': 'MyID password.',
        'MYID_HOSTED_URL': 'MyID redirect URL.',
        'SMS_DEMO_MODE': 'Enable SMS demo mode (true/false).',
        'SMS_DEMO_CODE': 'SMS code for test mode (default 666666).',
        'SMS_PROVIDER_URL': 'Real SMS provider URL.',
        'SMS_PROVIDER_TOKEN': 'Real SMS provider token.',
    }

    for key, label in APIConfiguration.KEY_CHOICES:
        env_val = os.environ.get(key, '')
        APIConfiguration.objects.get_or_create(
            key=key,
            defaults={
                'value': env_val,
                'description': default_descriptions.get(key, ''),
                'is_active': True
            }
        )

class PaymentsConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'payments'

    def ready(self):
        post_migrate.connect(populate_api_configs, sender=self)
