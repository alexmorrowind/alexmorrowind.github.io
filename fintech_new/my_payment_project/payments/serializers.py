from django.contrib.auth.models import User
from rest_framework import serializers
from .models import Bank, Card, Investment, KYCVerification, LegalEntityProfile, NewsArticle, Order, Startup, UserProfile

class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=6)
    email = serializers.EmailField(required=True)
    first_name = serializers.CharField(required=False, allow_blank=True)
    last_name = serializers.CharField(required=False, allow_blank=True)

    class Meta:
        model = User
        fields = ('id', 'email', 'password', 'first_name', 'last_name')

    def validate_email(self, value):
        email_lower = value.lower()
        if User.objects.filter(username=email_lower).exists() or User.objects.filter(email=email_lower).exists():
            raise serializers.ValidationError("Уже есть аккаунт с такой почтой.")
        return email_lower

    def create(self, validated_data):
        user = User.objects.create_user(
            username=validated_data['email'],
            email=validated_data['email'],
            password=validated_data['password'],
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', '')
        )
        return user

class CardSerializer(serializers.ModelSerializer):
    class Meta:
        model = Card
        fields = (
            'id', 'number', 'expiry', 'balance', 'name', 'provider',
            'payme_recurrent', 'payme_verified', 'created_at'
        )
        read_only_fields = ('id', 'created_at')


class BankSerializer(serializers.ModelSerializer):
    minDeposit = serializers.DecimalField(source='min_deposit', max_digits=15, decimal_places=2, read_only=True)
    logo = serializers.CharField(source='abbr', read_only=True)
    fees = serializers.SerializerMethodField()
    type = serializers.SerializerMethodField()
    features = serializers.SerializerMethodField()
    color = serializers.SerializerMethodField()
    isRecommended = serializers.BooleanField(source='is_recommended', read_only=True)
    profileComplete = serializers.SerializerMethodField()
    officialSources = serializers.ListField(source='source_urls', read_only=True)
    dataAsOf = serializers.DateField(source='data_as_of', read_only=True)
    licenseDate = serializers.DateField(source='license_date', read_only=True)
    isCatalog = serializers.BooleanField(source='is_catalog', read_only=True)

    class Meta:
        model = Bank
        fields = (
            'id', 'name', 'abbr', 'logo', 'logo_url', 'apy', 'min_deposit',
            'minDeposit', 'fees', 'rating', 'type', 'features', 'color',
            'is_recommended', 'isRecommended', 'is_catalog', 'isCatalog',
            'slug', 'legal_name', 'name_uz', 'description', 'description_uz',
            'ownership_type', 'license_number', 'license_date', 'licenseDate',
            'website_url', 'support_phone', 'support_email', 'address', 'stir',
            'swift_code', 'bank_code', 'mobile_app_url', 'android_url', 'ios_url',
            'products', 'services', 'source_urls', 'officialSources',
            'data_as_of', 'dataAsOf', 'data_status', 'apy_source_url',
            'fees_verified', 'latitude', 'longitude', 'profileComplete', 'updated_at',
        )

    def get_fees(self, obj):
        return 0 if obj.fees_verified else None

    def get_type(self, obj):
        if obj.ownership_type == 'foreign':
            return 'international'
        if obj.name.lower().startswith(('tbc', 'anor')):
            return 'digital'
        return 'traditional'

    def get_features(self, obj):
        values = []
        for item in (obj.products or []) + (obj.services or []):
            if isinstance(item, dict):
                label = item.get('name') or item.get('name_uz') or item.get('title')
            else:
                label = item
            if label and label not in values:
                values.append(label)
        return values[:5] or ['Профиль банка']

    def get_color(self, obj):
        colors = ['#2563eb', '#059669', '#f59e0b', '#06b6d4', '#7c3aed']
        return colors[(obj.id - 1) % len(colors)] if obj.id else colors[0]

    def get_profileComplete(self, obj):
        required = (
            obj.legal_name,
            obj.address,
            obj.website_url,
            obj.license_number,
            obj.description,
            obj.products,
            obj.services,
            obj.source_urls,
        )
        return sum(bool(value) for value in required) >= 7


class NewsArticleSerializer(serializers.ModelSerializer):
    category_label = serializers.CharField(source='get_category_display', read_only=True)
    display_title = serializers.SerializerMethodField()
    display_excerpt = serializers.SerializerMethodField()
    display_content = serializers.SerializerMethodField()

    class Meta:
        model = NewsArticle
        fields = (
            'id', 'title', 'title_uz', 'slug', 'excerpt', 'excerpt_uz',
            'content', 'content_uz', 'display_title', 'display_excerpt',
            'display_content', 'category', 'category_label', 'image_url',
            'source_name', 'source_url', 'published_at', 'is_featured',
        )

    def _language(self):
        request = self.context.get('request')
        return (request.query_params.get('lang') if request else '') or 'ru'

    def get_display_title(self, obj):
        return obj.title_uz if self._language() == 'uz' and obj.title_uz else obj.title

    def get_display_excerpt(self, obj):
        if self._language() == 'uz' and obj.excerpt_uz:
            return obj.excerpt_uz
        return obj.excerpt

    def get_display_content(self, obj):
        if self._language() == 'uz' and obj.content_uz:
            return obj.content_uz
        return obj.content


class OrderSerializer(serializers.ModelSerializer):
    class Meta:
        model = Order
        fields = (
            'id', 'amount', 'status', 'purpose', 'target_id',
            'description', 'checkout_url', 'created_at'
        )
        read_only_fields = ('id', 'status', 'checkout_url', 'created_at')


class LegalEntityProfileSerializer(serializers.ModelSerializer):
    startup_count = serializers.SerializerMethodField()
    total_raised = serializers.SerializerMethodField()

    class Meta:
        model = LegalEntityProfile
        fields = (
            'id', 'company_name', 'legal_form', 'tin', 'registration_number',
            'bank_account', 'director_name', 'director_passport',
            'director_birth_date', 'status', 'accepted_terms',
            'accepted_investment_risk', 'company_docs', 'myid_status',
            'myid_session_id', 'myid_payload', 'submitted_at', 'verified_at',
            'startup_count', 'total_raised', 'created_at', 'updated_at',
        )
        read_only_fields = (
            'id', 'status', 'myid_status', 'myid_session_id', 'myid_payload',
            'submitted_at', 'verified_at', 'startup_count', 'total_raised',
            'created_at', 'updated_at',
        )

    def get_startup_count(self, obj):
        return obj.startups.count()

    def get_total_raised(self, obj):
        return float(sum(startup.amount_raised for startup in obj.startups.all()))


class StartupSerializer(serializers.ModelSerializer):
    company_name = serializers.CharField(source='legal_entity.company_name', read_only=True)
    owner_email = serializers.EmailField(source='owner.email', read_only=True)

    class Meta:
        model = Startup
        fields = (
            'id', 'name', 'domain', 'stage', 'funding_goal',
            'min_investment', 'amount_raised', 'roi', 'description',
            'contact_email', 'status', 'company_name', 'owner_email',
            'created_at', 'updated_at',
        )
        read_only_fields = (
            'id', 'amount_raised', 'status', 'company_name', 'owner_email',
            'created_at', 'updated_at',
        )


class StartupPublicSerializer(serializers.ModelSerializer):
    company_name = serializers.CharField(source='legal_entity.company_name', read_only=True)

    class Meta:
        model = Startup
        fields = (
            'id', 'name', 'domain', 'stage', 'funding_goal',
            'min_investment', 'amount_raised', 'roi', 'description',
            'status', 'company_name', 'created_at', 'updated_at',
        )
        read_only_fields = fields


class InvestmentSerializer(serializers.ModelSerializer):
    startup_name = serializers.CharField(source='startup.name', read_only=True)
    checkout_url = serializers.CharField(source='order.checkout_url', read_only=True)

    class Meta:
        model = Investment
        fields = (
            'id', 'startup', 'startup_name', 'order', 'amount',
            'status', 'comment', 'checkout_url', 'created_at',
        )
        read_only_fields = ('id', 'order', 'status', 'startup_name', 'checkout_url', 'created_at')
