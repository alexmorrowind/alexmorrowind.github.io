import os
from django.contrib import admin
from .models import APIConfiguration, UserProfile, Card, Order, PaymeTransaction, Startup, Investment, KYCVerification

PLACEHOLDER_PREFIXES = ('your_', 'paste_', 'change-me', 'сюда_', 'example')


def value_is_set(value):
    if value is None:
        return False
    normalized = str(value).strip()
    if not normalized:
        return False
    return not normalized.lower().startswith(PLACEHOLDER_PREFIXES)


@admin.register(APIConfiguration)
class APIConfigurationAdmin(admin.ModelAdmin):
    list_display = ('key', 'get_status', 'value_masked', 'is_active', 'description')
    list_editable = ('is_active',)
    search_fields = ('key', 'description')

    def value_masked(self, obj):
        val = obj.value
        if not value_is_set(val):
            # Fallback check from environment variables
            env_val = os.environ.get(obj.key)
            if value_is_set(env_val):
                if len(env_val) > 8:
                    return f"[Env] {env_val[:4]}...{env_val[-4:]}"
                return "[Env] ****"
            return "—"
        if len(val) > 8:
            return f"{val[:4]}...{val[-4:]}"
        return "****"
    value_masked.short_description = "Value"

    def get_status(self, obj):
        has_val = value_is_set(obj.value) or value_is_set(os.environ.get(obj.key))
        if has_val and obj.is_active:
            return "✅ Connected"
        return "❌ Not Configured / Disabled"
    get_status.short_description = "Status"


@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'phone', 'passport', 'myid_status', 'credits', 'investments', 'savings')
    search_fields = ('user__username', 'phone', 'passport')
    list_filter = ('myid_status',)


@admin.register(Card)
class CardAdmin(admin.ModelAdmin):
    list_display = ('user', 'number', 'expiry', 'balance', 'name', 'provider', 'payme_verified')
    search_fields = ('user__username', 'number', 'name')
    list_filter = ('provider', 'payme_verified')


@admin.register(KYCVerification)
class KYCVerificationAdmin(admin.ModelAdmin):
    list_display = ('email', 'phone', 'passport', 'status', 'phone_verified', 'created_at')
    search_fields = ('email', 'phone', 'passport')
    list_filter = ('status', 'phone_verified')


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'amount', 'status', 'purpose', 'created_at')
    search_fields = ('user__username', 'description')
    list_filter = ('status', 'purpose')


@admin.register(PaymeTransaction)
class PaymeTransactionAdmin(admin.ModelAdmin):
    list_display = ('payme_id', 'order', 'amount', 'state', 'perform_time')
    search_fields = ('payme_id', 'order__id')
    list_filter = ('state',)


@admin.register(Startup)
class StartupAdmin(admin.ModelAdmin):
    list_display = ('name', 'owner', 'stage', 'funding_goal', 'amount_raised', 'status')
    search_fields = ('name', 'description')
    list_filter = ('stage', 'status')


@admin.register(Investment)
class InvestmentAdmin(admin.ModelAdmin):
    list_display = ('investor', 'startup', 'amount', 'status', 'created_at')
    search_fields = ('investor__username', 'startup__name')
    list_filter = ('status',)
