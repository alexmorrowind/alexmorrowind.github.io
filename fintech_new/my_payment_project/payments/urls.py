from django.urls import path
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from .views import (
    ApplicationCreateView,
    CardDetailView,
    CardListView,
    IntegrationStatusView,
    InvestmentListCreateView,
    LegalEntityProfileView,
    LegalEntitySubmitView,
    MyIDCompleteView,
    MyIDStartView,
    PaymeCreateOrderView,
    PaymeDepositRatesView,
    PaymeSubscribeCardCodeView,
    PaymeSubscribeCardCreateView,
    PaymeSubscribeCardVerifyView,
    PaymeSubscribeReceiptView,
    PaymeWebhookView,
    ProfileView,
    RegistrationPhoneCodeView,
    RegistrationPhoneVerifyView,
    RegistrationMyIDStartView,
    RegistrationMyIDStatusView,
    RegisterView,
    StartupDetailView,
    StartupListCreateView,
    UserOrdersView,
)


urlpatterns = [
    path('api/integrations/status/', IntegrationStatusView.as_view(), name='integration_status'),

    # Payme Webhook
    path('api/payme/', PaymeWebhookView.as_view(), name='payme_webhook'),
    path('api/payme/create-order/', PaymeCreateOrderView.as_view(), name='payme_create_order'),
    path('api/payme/deposit-rates/', PaymeDepositRatesView.as_view(), name='payme_deposit_rates'),
    path('api/payme/subscribe/cards/create/', PaymeSubscribeCardCreateView.as_view(), name='payme_subscribe_card_create'),
    path('api/payme/subscribe/cards/code/', PaymeSubscribeCardCodeView.as_view(), name='payme_subscribe_card_code'),
    path('api/payme/subscribe/cards/verify/', PaymeSubscribeCardVerifyView.as_view(), name='payme_subscribe_card_verify'),
    path('api/payme/subscribe/receipts/', PaymeSubscribeReceiptView.as_view(), name='payme_subscribe_receipts'),

    # Регистрация и Авторизация (BPay)
    path('api/auth/myid/start/', RegistrationMyIDStartView.as_view(), name='auth_myid_start'),
    path('api/auth/myid/status/', RegistrationMyIDStatusView.as_view(), name='auth_myid_status'),
    path('api/auth/phone-code/', RegistrationPhoneCodeView.as_view(), name='auth_phone_code'),
    path('api/auth/phone-verify/', RegistrationPhoneVerifyView.as_view(), name='auth_phone_verify'),
    path('api/auth/register/', RegisterView.as_view(), name='auth_register'),
    path('api/auth/login/', TokenObtainPairView.as_view(), name='auth_login'), # Выдаст access и refresh токены
    path('api/auth/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),

    # Личный кабинет
    path('api/user/profile/', ProfileView.as_view(), name='user_profile'),
    path('api/user/cards/', CardListView.as_view(), name='user_cards'),
    path('api/user/cards/<int:pk>/', CardDetailView.as_view(), name='user_card_detail'),
    path('api/user/orders/', UserOrdersView.as_view(), name='user_orders'),

    # Юридическое лицо + MyID
    path('api/legal-entity/profile/', LegalEntityProfileView.as_view(), name='legal_entity_profile'),
    path('api/legal-entity/submit/', LegalEntitySubmitView.as_view(), name='legal_entity_submit'),
    path('api/kyc/myid/start/', MyIDStartView.as_view(), name='myid_start'),
    path('api/kyc/myid/complete/', MyIDCompleteView.as_view(), name='myid_complete'),

    # Стартапы и инвестиции
    path('api/startups/', StartupListCreateView.as_view(), name='startup_list_create'),
    path('api/startups/<int:pk>/', StartupDetailView.as_view(), name='startup_detail'),
    path('api/investments/', InvestmentListCreateView.as_view(), name='investment_list_create'),
    path('api/applications/', ApplicationCreateView.as_view(), name='application_create'),
]
