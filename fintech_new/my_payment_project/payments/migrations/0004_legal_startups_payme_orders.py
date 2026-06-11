# Generated for B1 legal entity onboarding, startup investments, and Payme checkout.

import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('payments', '0003_bank_application_userinvestment'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.AddField(
            model_name='order',
            name='checkout_url',
            field=models.TextField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='order',
            name='description',
            field=models.CharField(blank=True, max_length=255, null=True),
        ),
        migrations.AddField(
            model_name='order',
            name='purpose',
            field=models.CharField(choices=[('card_order', 'Заказ карты'), ('investment', 'Инвестиция'), ('transfer', 'Перевод средств'), ('loan_application', 'Заявка на кредит'), ('application', 'Заявка'), ('report', 'Финансовый отчет')], default='application', max_length=32),
        ),
        migrations.AddField(
            model_name='order',
            name='target_id',
            field=models.CharField(blank=True, max_length=80, null=True),
        ),
        migrations.AddField(
            model_name='order',
            name='user',
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='orders', to=settings.AUTH_USER_MODEL),
        ),
        migrations.AlterField(
            model_name='application',
            name='app_type',
            field=models.CharField(choices=[('loan', 'Кредит'), ('card', 'Карта'), ('bank', 'Банк'), ('investment', 'Инвестиция')], max_length=10),
        ),
        migrations.CreateModel(
            name='LegalEntityProfile',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('company_name', models.CharField(max_length=160)),
                ('legal_form', models.CharField(blank=True, default='MCHJ', max_length=80)),
                ('tin', models.CharField(blank=True, max_length=20)),
                ('registration_number', models.CharField(blank=True, max_length=40)),
                ('bank_account', models.CharField(blank=True, max_length=32)),
                ('director_name', models.CharField(blank=True, max_length=120)),
                ('director_passport', models.CharField(blank=True, max_length=20)),
                ('director_birth_date', models.DateField(blank=True, null=True)),
                ('status', models.CharField(choices=[('draft', 'Черновик'), ('pending_review', 'На проверке'), ('verified', 'Подтверждено'), ('rejected', 'Отклонено')], default='draft', max_length=20)),
                ('accepted_terms', models.BooleanField(default=False)),
                ('accepted_investment_risk', models.BooleanField(default=False)),
                ('company_docs', models.JSONField(blank=True, default=list)),
                ('myid_status', models.CharField(default='not_started', max_length=32)),
                ('myid_session_id', models.CharField(blank=True, max_length=120)),
                ('myid_payload', models.JSONField(blank=True, default=dict)),
                ('submitted_at', models.DateTimeField(blank=True, null=True)),
                ('verified_at', models.DateTimeField(blank=True, null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('user', models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name='legal_profile', to=settings.AUTH_USER_MODEL)),
            ],
        ),
        migrations.CreateModel(
            name='Startup',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=140)),
                ('domain', models.CharField(default='startup', max_length=40)),
                ('stage', models.CharField(choices=[('idea', 'Идея'), ('mvp', 'MVP'), ('growth', 'Рост'), ('scale', 'Масштабирование')], default='mvp', max_length=20)),
                ('funding_goal', models.DecimalField(decimal_places=2, max_digits=15)),
                ('min_investment', models.DecimalField(decimal_places=2, default=1000, max_digits=12)),
                ('amount_raised', models.DecimalField(decimal_places=2, default=0, max_digits=15)),
                ('roi', models.FloatField(default=20)),
                ('description', models.TextField()),
                ('contact_email', models.EmailField(blank=True, max_length=254)),
                ('status', models.CharField(choices=[('draft', 'Черновик'), ('active', 'Активен'), ('closed', 'Закрыт')], default='active', max_length=20)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('legal_entity', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='startups', to='payments.legalentityprofile')),
                ('owner', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='owned_startups', to=settings.AUTH_USER_MODEL)),
            ],
        ),
        migrations.CreateModel(
            name='Investment',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('amount', models.DecimalField(decimal_places=2, max_digits=15)),
                ('status', models.CharField(choices=[('pending_payment', 'Ожидает оплаты'), ('paid', 'Оплачено'), ('canceled', 'Отменено')], default='pending_payment', max_length=20)),
                ('comment', models.TextField(blank=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('investor', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='startup_investments', to=settings.AUTH_USER_MODEL)),
                ('order', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='investments', to='payments.order')),
                ('startup', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='investments', to='payments.startup')),
            ],
        ),
    ]
