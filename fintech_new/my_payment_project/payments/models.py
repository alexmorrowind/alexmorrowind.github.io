from django.db import models
from django.contrib.auth.models import User

class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    phone = models.CharField(max_length=20, blank=True, null=True)
    passport = models.CharField(max_length=20, blank=True, null=True)
    birth_date = models.DateField(blank=True, null=True)
    myid_status = models.CharField(max_length=32, default='not_started')
    myid_job_id = models.CharField(max_length=120, blank=True, null=True)
    myid_session_id = models.CharField(max_length=120, blank=True, null=True)
    myid_payload = models.JSONField(default=dict, blank=True)
    credits = models.DecimalField(max_digits=15, decimal_places=2, default=0.0)
    investments = models.DecimalField(max_digits=15, decimal_places=2, default=0.0)
    savings = models.DecimalField(max_digits=15, decimal_places=2, default=0.0)

    def __str__(self):
        return f"Profile of {self.user.username}"


class Card(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='cards')
    number = models.CharField(max_length=20)
    expiry = models.CharField(max_length=5)
    balance = models.DecimalField(max_digits=15, decimal_places=2, default=0.0)
    name = models.CharField(max_length=50, blank=True, null=True)
    provider = models.CharField(max_length=30, blank=True, default='manual')
    payme_token = models.TextField(blank=True, null=True)
    payme_recurrent = models.BooleanField(default=False)
    payme_verified = models.BooleanField(default=False)
    payme_payload = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.name or 'Card'} — {self.number} ({self.balance} UZS)"


class KYCVerification(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('verified', 'Verified'),
        ('demo_verified', 'Demo verified'),
        ('failed', 'Failed'),
    ]
    session_id = models.CharField(max_length=120, unique=True)
    email = models.EmailField()
    phone = models.CharField(max_length=30, blank=True)
    first_name = models.CharField(max_length=120, blank=True)
    last_name = models.CharField(max_length=120, blank=True)
    passport = models.CharField(max_length=20, blank=True)
    birth_date = models.DateField(blank=True, null=True)
    status = models.CharField(max_length=32, choices=STATUS_CHOICES, default='pending')
    job_id = models.CharField(max_length=120, blank=True)
    external_id = models.CharField(max_length=120, blank=True)
    payload = models.JSONField(default=dict, blank=True)
    error = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    verified_at = models.DateTimeField(blank=True, null=True)

    def __str__(self):
        return f"{self.email} ({self.status})"


class Order(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Ожидает оплаты'),
        ('paid', 'Оплачен'),
        ('canceled', 'Отменен'),
    ]
    PURPOSE_CHOICES = [
        ('card_order', 'Заказ карты'),
        ('investment', 'Инвестиция'),
        ('transfer', 'Перевод средств'),
        ('loan_application', 'Заявка на кредит'),
        ('application', 'Заявка'),
        ('report', 'Финансовый отчет'),
    ]
    user = models.ForeignKey(User, on_delete=models.SET_NULL, related_name='orders', null=True, blank=True)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    purpose = models.CharField(max_length=32, choices=PURPOSE_CHOICES, default='application')
    target_id = models.CharField(max_length=80, blank=True, null=True)
    description = models.CharField(max_length=255, blank=True, null=True)
    checkout_url = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Заказ #{self.id} — {self.amount} сум ({self.purpose})"


class PaymeTransaction(models.Model):
    payme_id = models.CharField(max_length=255, unique=True)
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='transactions')
    amount = models.BigIntegerField()
    state = models.IntegerField()
    create_time = models.BigIntegerField()
    perform_time = models.BigIntegerField(default=0)
    cancel_time = models.BigIntegerField(default=0)
    reason = models.IntegerField(null=True, blank=True)

    def __str__(self):
        return f"Транзакция Payme {self.payme_id} (Cтатус: {self.state})"



from django.db import models
from django.contrib.auth.models import User

# Модель Банка
class Bank(models.Model):
    name = models.CharField(max_length=100)
    abbr = models.CharField(max_length=10) # Например: NBU, KB
    logo_url = models.CharField(max_length=255) # Ссылка на лого
    apy = models.FloatField(default=0.0) # Процентная ставка
    min_deposit = models.DecimalField(max_digits=15, decimal_places=2)
    rating = models.FloatField(default=5.0)
    is_recommended = models.BooleanField(default=False)

    def __str__(self):
        return self.name

# Модель заявки (Кредит или Карта)
class Application(models.Model):
    TYPE_CHOICES = [('loan', 'Кредит'), ('card', 'Карта'), ('bank', 'Банк'), ('investment', 'Инвестиция')]
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    target_name = models.CharField(max_length=100) # Название банка или карты
    app_type = models.CharField(max_length=10, choices=TYPE_CHOICES)
    status = models.CharField(max_length=20, default='pending')
    created_at = models.DateTimeField(auto_now_add=True)

# Модель Инвестиций пользователя
class UserInvestment(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    project_name = models.CharField(max_length=100)
    amount = models.DecimalField(max_digits=15, decimal_places=2)
    current_value = models.DecimalField(max_digits=15, decimal_places=2) # Для графиков роста
    roi = models.FloatField()
    created_at = models.DateTimeField(auto_now_add=True)


class LegalEntityProfile(models.Model):
    STATUS_CHOICES = [
        ('draft', 'Черновик'),
        ('pending_review', 'На проверке'),
        ('verified', 'Подтверждено'),
        ('rejected', 'Отклонено'),
    ]
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='legal_profile')
    company_name = models.CharField(max_length=160)
    legal_form = models.CharField(max_length=80, blank=True, default='MCHJ')
    tin = models.CharField(max_length=20, blank=True)  # INN/STIR
    registration_number = models.CharField(max_length=40, blank=True)
    bank_account = models.CharField(max_length=32, blank=True)
    director_name = models.CharField(max_length=120, blank=True)
    director_passport = models.CharField(max_length=20, blank=True)
    director_birth_date = models.DateField(blank=True, null=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='draft')
    accepted_terms = models.BooleanField(default=False)
    accepted_investment_risk = models.BooleanField(default=False)
    company_docs = models.JSONField(default=list, blank=True)
    myid_status = models.CharField(max_length=32, default='not_started')
    myid_session_id = models.CharField(max_length=120, blank=True)
    myid_payload = models.JSONField(default=dict, blank=True)
    submitted_at = models.DateTimeField(blank=True, null=True)
    verified_at = models.DateTimeField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.company_name} ({self.status})"


class Startup(models.Model):
    STAGE_CHOICES = [
        ('idea', 'Идея'),
        ('mvp', 'MVP'),
        ('growth', 'Рост'),
        ('scale', 'Масштабирование'),
    ]
    STATUS_CHOICES = [
        ('draft', 'Черновик'),
        ('active', 'Активен'),
        ('closed', 'Закрыт'),
    ]
    owner = models.ForeignKey(User, on_delete=models.CASCADE, related_name='owned_startups')
    legal_entity = models.ForeignKey(LegalEntityProfile, on_delete=models.CASCADE, related_name='startups')
    name = models.CharField(max_length=140)
    domain = models.CharField(max_length=40, default='startup')
    stage = models.CharField(max_length=20, choices=STAGE_CHOICES, default='mvp')
    funding_goal = models.DecimalField(max_digits=15, decimal_places=2)
    min_investment = models.DecimalField(max_digits=12, decimal_places=2, default=1000)
    amount_raised = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    roi = models.FloatField(default=20)
    description = models.TextField()
    contact_email = models.EmailField(blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name


class Investment(models.Model):
    STATUS_CHOICES = [
        ('pending_payment', 'Ожидает оплаты'),
        ('paid', 'Оплачено'),
        ('canceled', 'Отменено'),
    ]
    investor = models.ForeignKey(User, on_delete=models.CASCADE, related_name='startup_investments')
    startup = models.ForeignKey(Startup, on_delete=models.SET_NULL, related_name='investments', null=True, blank=True)
    order = models.ForeignKey(Order, on_delete=models.SET_NULL, related_name='investments', null=True, blank=True)
    amount = models.DecimalField(max_digits=15, decimal_places=2)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending_payment')
    comment = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.investor_id} -> {self.startup_id}: {self.amount}"
