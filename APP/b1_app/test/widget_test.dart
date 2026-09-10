import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:b1_fintech_app/app_data_service.dart';
import 'package:b1_fintech_app/controllers.dart';
import 'package:b1_fintech_app/integrations.dart';
import 'package:b1_fintech_app/main.dart';
import 'package:b1_fintech_app/models.dart';

void main() {
  testWidgets('splash route exists and opens login', (tester) async {
    await tester.pumpWidget(const BPayApp());

    expect(find.text('BPay'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    expect(find.text('Xush kelibsiz'), findsOneWidget);
  });

  testWidgets('login validation rejects invalid credentials', (tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BPayApp());
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'bad-phone');
    await tester.enterText(find.byType(TextField).at(1), '123');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Kirish'));
    await tester.tap(find.widgetWithText(FilledButton, 'Kirish'));
    await tester.pump();

    expect(find.textContaining('+998'), findsOneWidget);
  });

  testWidgets('demo login reaches home dashboard', (tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BPayApp());
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Demo rejimida korish'));
    await tester.tap(find.text('Demo rejimida korish'));
    await tester.pumpAndSettle();

    expect(find.text('MOLIYAVIY TAKLIFLAR KATALOGI'), findsOneWidget);
    expect(find.textContaining('P2P'), findsWidgets);
    expect(find.byIcon(Icons.dashboard_outlined), findsOneWidget);
  });

  testWidgets('language and theme settings update visible UI', (tester) async {
    await tester.pumpWidget(const BPayApp());
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    await tester.tap(find.text('RU'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  });

  test('search and filters return expected offers', () {
    const service = AppDataService();

    expect(service.searchBanks('digital').map((bank) => bank.name),
        contains('TBC Uzbekistan'));
    expect(service.searchCards('travel'), isNotEmpty);
    expect(service.searchLoans('auto').single.type, LoanType.auto);
    expect(service.filterInvestors(InvestorDomain.tech).single.name,
        'Silk Road Ventures');
    expect(AppDataService.banks.map((bank) => bank.name),
        contains('National Bank of Uzbekistan (NBU)'));
    expect(AppDataService.banks.map((bank) => bank.name),
        contains('Kredit Standart Bank'));
  });

  test('loan calculator returns a monthly payment', () {
    final payment = AppDataService.calculateMonthlyPayment(
      principal: 50000000,
      annualRate: 20,
      months: 24,
    );

    expect(payment, greaterThan(2500000));
    expect(payment, lessThan(2600000));
  });

  test('auth validation and settings controller work', () {
    final auth = AuthController(
      userRepository: InMemoryUserRepository(),
      api: B1ApiClient(),
    );
    expect(auth.validateLogin('bad', '123456'), isNotNull);
    expect(auth.validateLogin('+998901234567', 'demo123'), isNull);

    final settings = SettingsController();
    settings.setLanguage('ru');
    settings.setThemeMode(ThemeMode.light);

    expect(settings.language, 'ru');
    expect(settings.themeMode, ThemeMode.light);
  });

  test('registration completes through mock MyID', () async {
    final auth = AuthController(
      userRepository: InMemoryUserRepository(),
      api: B1ApiClient(),
    );

    await auth.register(
      phone: '+998901234567',
      password: 'demo123',
      accountType: AccountType.physical,
    );

    expect(auth.authenticated, isTrue);
    expect(auth.profile?.isMyIdVerified, isTrue);
    expect(auth.profile?.identity?.firstName, 'Anvar');
  });

  test('card OTP flow verifies ownership in staging mode', () async {
    final cards = PaymentController(gateway: const MockPaymentGateway());

    await cards.startCardAdd(
      cardNumber: '9860123412345678',
      expiry: '12/28',
      phone: '+998901234567',
    );
    expect(cards.hasPendingOtp, isTrue);

    await cards.verifyOtp('111111');
    expect(cards.cards.single.maskedNumber, '**** **** **** 5678');
    expect(cards.cards.single.ownerVerified, isTrue);
  });

  test('legal entity can create startup and physical user can invest', () {
    final startups = StartupController();

    startups.createStartup(
      ownerUserId: 'legal_1',
      name: 'Legal Startup',
      category: 'FinTech',
      description: 'A legal entity startup listing',
      goal: 100000000,
      businessModel: 'SaaS',
      financialInfo: 'MRR 10M UZS',
    );
    startups.invest(
        userId: 'physical_1',
        startupId: startups.startups.last.id,
        amount: 1000000);

    expect(startups.startups.last.status, StartupStatus.pendingApproval);
    expect(startups.investments.last.amount, 1000000);
  });
}
