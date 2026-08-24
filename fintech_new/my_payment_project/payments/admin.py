import os
import secrets
from django.contrib import admin
from django.contrib import messages
from django.contrib.auth.admin import UserAdmin as DjangoUserAdmin
from django.contrib.auth.models import User
from django.utils.html import format_html, format_html_join
from .models import APIConfiguration, Bank, UserProfile, Card, NewsArticle, Order, PaymeTransaction, Startup, Investment, KYCVerification

PLACEHOLDER_PREFIXES = ('your_', 'paste_', 'change-me', 'сюда_', 'example')
TEMP_PASSWORD_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789'


def generate_temporary_password(length=14):
    return ''.join(secrets.choice(TEMP_PASSWORD_ALPHABET) for _ in range(length))


def reset_users_to_temporary_passwords(users):
    reset_rows = []
    for user in users:
        password = generate_temporary_password()
        user.set_password(password)
        user.save(update_fields=['password'])
        reset_rows.append((user.get_username(), password))
    return reset_rows


class B1UserAdmin(DjangoUserAdmin):
    actions = ['reset_passwords_to_temporary']

    @admin.action(description='Reset selected users to temporary passwords')
    def reset_passwords_to_temporary(self, request, queryset):
        reset_rows = reset_users_to_temporary_passwords(queryset.order_by('username'))
        if not reset_rows:
            self.message_user(request, 'No users selected.', messages.WARNING)
            return

        self.message_user(
            request,
            format_html(
                'Temporary passwords were generated. They are shown only once:<br>{}',
                format_html_join(
                    '',
                    '<div><strong>{}</strong>: <code>{}</code></div>',
                    reset_rows,
                ),
            ),
            messages.WARNING,
        )


if admin.site.is_registered(User):
    admin.site.unregister(User)
admin.site.register(User, B1UserAdmin)


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


@admin.register(Bank)
class BankAdmin(admin.ModelAdmin):
    list_display = ('name', 'abbr', 'ownership_type', 'license_number', 'is_catalog', 'data_status', 'updated_at')
    search_fields = ('name', 'name_uz', 'abbr', 'legal_name', 'license_number', 'address')
    list_filter = ('ownership_type', 'is_catalog', 'data_status', 'is_recommended')
    list_editable = ('is_catalog', 'data_status')
    readonly_fields = ('updated_at',)
    fieldsets = (
        ('Каталог', {
            'fields': (
                'name', 'name_uz', 'abbr', 'slug', 'logo_url',
                'is_catalog', 'is_recommended', 'data_status',
            ),
        }),
        ('Описание', {
            'fields': ('legal_name', 'description', 'description_uz', 'ownership_type'),
        }),
        ('Лицензия и реквизиты', {
            'fields': (
                'license_number', 'license_date', 'stir', 'swift_code',
                'bank_code', 'address',
            ),
        }),
        ('Сайт и контакты', {
            'fields': (
                'website_url', 'support_phone', 'support_email',
                'mobile_app_url', 'android_url', 'ios_url',
            ),
        }),
        ('Продукты, сервисы и источники', {
            'fields': ('products', 'services', 'source_urls', 'data_as_of'),
        }),
        ('Карта', {
            'fields': ('latitude', 'longitude'),
            'description': 'Координаты главного офиса. Их можно скорректировать вручную.',
        }),
        ('Тарифные данные', {
            'fields': ('apy', 'min_deposit', 'rating', 'apy_source_url', 'fees_verified'),
        }),
        ('Служебное', {'fields': ('updated_at',)}),
    )


@admin.register(NewsArticle)
class NewsArticleAdmin(admin.ModelAdmin):
    list_display = ('title', 'category', 'source_name', 'published_at', 'is_published', 'is_featured')
    list_filter = ('category', 'is_published', 'is_featured')
    search_fields = ('title', 'title_uz', 'excerpt', 'source_name', 'source_url')
    prepopulated_fields = {'slug': ('title',)}
    list_editable = ('is_published', 'is_featured')
    readonly_fields = ('created_at', 'updated_at')
    fieldsets = (
        ('Основное', {
            'fields': (
                'title', 'title_uz', 'slug', 'category',
                'excerpt', 'excerpt_uz', 'content', 'content_uz',
            ),
        }),
        ('Источник и публикация', {
            'fields': (
                'image_url', 'source_name', 'source_url', 'external_id',
                'published_at', 'is_published', 'is_featured',
            ),
        }),
        ('Служебное', {'fields': ('created_at', 'updated_at')}),
    )


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
