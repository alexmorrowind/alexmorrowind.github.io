from django.contrib.auth.models import User
from rest_framework import serializers
from .models import Card, Investment, KYCVerification, LegalEntityProfile, Order, Startup, UserProfile

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
