import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:myid/enums.dart';
import 'package:myid/myid.dart';
import 'package:myid/myid_config.dart';
import 'package:provider/provider.dart';

import 'app_data_service.dart';
import 'controllers.dart';
import 'integrations.dart';
import 'models.dart';

void main() {
  runApp(const BPayApp());
}

class BPayApp extends StatelessWidget {
  const BPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => B1ApiClient()),
        Provider(create: (_) => const AppDataService()),
        Provider<PaymentGateway>(
          create: (context) =>
              B1PaymePaymentGateway(context.read<B1ApiClient>()),
        ),
        Provider<UserRepository>(
          create: (context) =>
              B1DjangoUserRepository(context.read<B1ApiClient>()),
        ),
        ChangeNotifierProvider(
          create: (context) => AuthController(
            userRepository: context.read<UserRepository>(),
            api: context.read<B1ApiClient>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => PaymentController(
            gateway: context.read<PaymentGateway>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              StartupController(api: context.read<B1ApiClient>()),
        ),
        ChangeNotifierProvider(create: (_) => SettingsController()),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'BPay',
            debugShowCheckedModeBanner: false,
            themeMode: settings.themeMode,
            theme: _theme(Brightness.light),
            darkTheme: _theme(Brightness.dark),
            initialRoute: '/splash',
            routes: {
              '/splash': (_) => const SplashScreen(),
              '/login': (_) => const LoginScreen(),
              '/home': (_) => const MainShell(initialIndex: 0),
              '/banks': (_) => const MainShell(initialIndex: 1),
              '/cards': (_) => const MainShell(initialIndex: 2),
              '/loans': (_) => const MainShell(initialIndex: 3),
              '/investors': (_) => const MainShell(initialIndex: 4),
              '/analytics': (_) => const MainShell(initialIndex: 5),
              '/startups': (_) => const MainShell(initialIndex: 6),
              '/profile': (_) => const MainShell(initialIndex: 7),
              '/admin': (_) => const MainShell(initialIndex: 8),
              '/services': (_) => const MainShell(initialIndex: 9),
              '/settings': (_) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }

  ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2563EB),
      brightness: brightness,
      primary: const Color(0xFF2563EB),
      secondary: const Color(0xFF06B6D4),
      tertiary: const Color(0xFF10B981),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          dark ? const Color(0xFF020408) : const Color(0xFFF8FAFC),
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: dark ? const Color(0xFF060C14) : Colors.white,
        foregroundColor:
            dark ? const Color(0xFFF0F6FF) : const Color(0xFF0F172A),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: dark ? const Color(0x99111827) : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: dark ? const Color(0x33508CFF) : const Color(0x140F172A),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF08111F) : const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: BorderSide(
              color: dark ? const Color(0x55508CFF) : const Color(0x332563EB)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: dark ? const Color(0xFF060C14) : Colors.white,
        indicatorColor: const Color(0x332563EB),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: dark ? const Color(0xFF060C14) : Colors.white,
        indicatorColor: const Color(0x332563EB),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(
            color: dark ? const Color(0x33508CFF) : const Color(0x1A2563EB)),
      ),
      dividerTheme: DividerThemeData(
        color: dark ? const Color(0x22508CFF) : const Color(0x140F172A),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(1500.ms, () {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LogoMark(size: 104).animate().scale(curve: Curves.elasticOut),
              const SizedBox(height: 20),
              const Text(
                'BPay',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Moliyaviy platforma',
                style: TextStyle(color: Colors.white.withValues(alpha: .76)),
              ),
            ],
          ).animate().fadeIn(duration: 600.ms).slideY(begin: .08, end: 0),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phone = TextEditingController(text: '+998901234567');
  final password = TextEditingController(text: 'demo123');
  final companyName = TextEditingController(text: 'B1 Ventures LLC');
  final industry = TextEditingController(text: 'FinTech');
  final businessType = TextEditingController(text: 'Startup');
  final startupDescription =
      TextEditingController(text: 'Payment infrastructure for SMEs');
  final contactInfo = TextEditingController(text: 'founder@b1.uz');
  String? scannedWebSessionId;
  String? loginStatus;
  bool myIdBusy = false;
  bool register = false;
  bool obscure = true;
  AccountType accountType = AccountType.physical;

  String? _extractQrSessionId(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri != null) {
      final querySession =
          uri.queryParameters['session_id'] ?? uri.queryParameters['sessionId'];
      if (querySession != null && querySession.isNotEmpty) return querySession;
      if (uri.scheme == 'bpay' && uri.host == 'auth') {
        final pathSegments = uri.pathSegments;
        if (pathSegments.isNotEmpty) {
          final fromPath = pathSegments.last;
          if (fromPath.isNotEmpty) return fromPath;
        }
      }
    }
    return trimmed.length >= 12 ? trimmed : null;
  }

  bool _isMyIdSuccessCode(String value) {
    final code = value.trim().toLowerCase();
    // MyID's embedded SDK documentation defines result_code=1 as the only
    // successful identification result.  Treat every other code as a failed
    // verification; accepting an unknown code would let a cancelled or failed
    // SDK flow reach the backend as a verified session.
    return code == '1';
  }

  bool get _allowMyIdDemo =>
      kDebugMode &&
      const String.fromEnvironment(
            'B1_MYID_ALLOW_DEMO',
            defaultValue: 'false',
          ).toLowerCase() ==
          'true';

  String _myIdResultMessage(String resultCode) {
    switch (resultCode.trim()) {
      case '2':
        return 'MyID: паспортные данные введены неправильно.';
      case '3':
        return 'MyID: не удалось подтвердить жизненность. Попробуйте ещё раз.';
      case '4':
        return 'MyID: документ или лицо не удалось распознать.';
      case '5':
        return 'MyID временно недоступен. Попробуйте позже.';
      case '9':
      case '10':
      case '11':
        return 'MyID: проверка не завершена. Повторите попытку позже.';
      case '14':
      case '17':
      case '18':
      case '19':
      case '20':
      case '21':
      case '22':
      case '23':
      case '24':
      case '25':
      case '26':
      case '27':
      case '28':
      case '29':
      case '30':
      case '31':
        return 'MyID не смог обработать фотографию. Выполните инструкции и повторите.';
      case '34':
        return 'MyID: срок действия документа истёк.';
      default:
        return resultCode.isEmpty
            ? 'MyID не вернул результат проверки.'
            : 'MyID: проверка не пройдена (код $resultCode).';
    }
  }

  String _myIdErrorMessage(Object error) {
    if (error is PlatformException) {
      switch (error.code.trim()) {
        case '101':
          return 'Проверка MyID отменена. Можно повторить попытку.';
        case '102':
          return 'Нет доступа к камере. Разрешите доступ к камере и повторите.';
        case '103':
          return 'MyID временно недоступен. Проверьте интернет и повторите.';
        case '122':
          return 'Проверка MyID временно заблокирована. Попробуйте позже.';
      }
      return error.message?.trim().isNotEmpty == true
          ? error.message!
          : 'Не удалось запустить MyID.';
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  Future<void> _scanWebQr() async {
    final sessionId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (_) => const _QrScannerSheet(),
    );
    if (!mounted || sessionId == null || sessionId.isEmpty) return;
    setState(() {
      scannedWebSessionId = sessionId;
      loginStatus = 'QR session linked';
    });
  }

  Future<void> _startMyIdLogin() async {
    final auth = context.read<AuthController>();
    final messenger = ScaffoldMessenger.of(context);
    final phoneValue = phone.text.trim();
    if (phoneValue.isEmpty) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Phone number is required')));
      return;
    }

    setState(() {
      myIdBusy = true;
      loginStatus = 'MyID session starting...';
    });

    try {
      final session = await auth.startMyIdLogin(
        phone: phoneValue,
        email: phoneValue.contains('@')
            ? phoneValue
            : '${phoneValue.replaceAll(RegExp(r'\D'), '')}@bpay.local',
        accountType: accountType,
      );

      if (session.isExpired ||
          session.expiresAt
              .isBefore(DateTime.now().add(const Duration(seconds: 5)))) {
        throw StateError('Сессия MyID истекла. Повторите попытку.');
      }

      if (session.demo || !session.readyForSdk) {
        // Demo is opt-in even in debug builds.  A missing production
        // configuration must never silently turn a real login into a verified
        // local/demo user.
        if (_allowMyIdDemo && session.demo) {
          auth.demoLogin(type: accountType);
          if (mounted) {
            setState(() => loginStatus = 'Demo MyID verification completed.');
            Navigator.pushReplacementNamed(context, '/home');
          }
          return;
        }
        throw StateError(
          'MyID is not configured on the server. Contact support to finish verification setup.',
        );
      }

      final result = await MyIdClient.start(
        config: MyIdConfig(
          sessionId: session.sessionId,
          clientHash: session.clientHash,
          clientHashId: session.clientHashId,
          environment: MyIdEnvironment.PRODUCTION,
          entryType: MyIdEntryType.IDENTIFICATION,
        ),
        iosAppearance: const MyIdIOSAppearance(),
      );

      final resultCode = result.code?.toString() ?? '';
      final verified = _isMyIdSuccessCode(resultCode);
      if (!verified) {
        throw StateError(_myIdResultMessage(resultCode));
      }

      final completion = await auth.completeMyIdLogin(
        sessionId: session.sessionId,
        phone: session.phone.isNotEmpty ? session.phone : phoneValue,
        resultCode: resultCode,
        verified: verified,
        qrSessionId: scannedWebSessionId,
        email: session.email.isNotEmpty ? session.email : null,
        myIdPayload: {
          'code': resultCode,
        },
      );

      if (!mounted) return;
      setState(() {
        loginStatus = completion.qrSessionId.isNotEmpty
            ? 'MyID verified. Website QR confirmed.'
            : 'MyID verified.';
      });
      Navigator.pushReplacementNamed(context, '/home');
    } on StateError catch (error) {
      final message = error.message;
      messenger.showSnackBar(SnackBar(content: Text(message)));
      if (mounted) {
        setState(() => loginStatus = message);
      }
    } catch (error) {
      final message = _myIdErrorMessage(error);
      messenger.showSnackBar(SnackBar(content: Text(message)));
      if (mounted) {
        setState(() => loginStatus = message);
      }
    } finally {
      if (mounted) {
        setState(() => myIdBusy = false);
      }
    }
  }

  @override
  void dispose() {
    phone.dispose();
    password.dispose();
    companyName.dispose();
    industry.dispose();
    businessType.dispose();
    startupDescription.dispose();
    contactInfo.dispose();
    super.dispose();
  }

  Future<void> _submit({bool demo = false, AccountType? demoType}) async {
    final auth = context.read<AuthController>();
    final messenger = ScaffoldMessenger.of(context);
    if (demo) {
      auth.demoLogin(type: demoType ?? AccountType.physical);
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }
    try {
      if (register) {
        await auth.register(
          phone: phone.text.trim(),
          password: password.text,
          accountType: accountType,
          business: accountType == AccountType.legal
              ? BusinessQuestionnaire(
                  companyName: companyName.text.trim(),
                  industry: industry.text.trim(),
                  businessType: businessType.text.trim(),
                  startupDescription: startupDescription.text.trim(),
                  contactInfo: contactInfo.text.trim(),
                )
              : null,
        );
      } else {
        await auth.login(phone.text.trim(), password.text);
      }
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } on StateError catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = Copy(context.watch<SettingsController>().isUz);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const _LogoMark(size: 54),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              copy.appName,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            Text(copy.tagline),
                          ],
                        ),
                        const Spacer(),
                        const _LanguageToggle(),
                      ],
                    ),
                    const SizedBox(height: 44),
                    Text(
                      register
                          ? (copy.isUz ? 'Hisob yaratish' : 'Create account')
                          : copy.loginTitle,
                      style: Theme.of(context)
                          .textTheme
                          .displaySmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text(copy.loginSubtitle),
                    const SizedBox(height: 28),
                    SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(
                          value: false,
                          label: Text(copy.isUz ? 'Kirish' : 'Login'),
                          icon: const Icon(Icons.login),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text(copy.isUz ? 'Royxat' : 'Register'),
                          icon: const Icon(Icons.person_add_alt),
                        ),
                      ],
                      selected: {register},
                      onSelectionChanged: (value) {
                        setState(() => register = value.first);
                      },
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: copy.isUz ? 'Telefon raqam' : 'Phone number',
                        prefixIcon: const Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: password,
                      obscureText: obscure,
                      decoration: InputDecoration(
                        labelText: copy.isUz ? 'Parol' : 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => obscure = !obscure),
                          icon: Icon(obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              copy.isUz
                                  ? 'MyID va QR kirish'
                                  : 'MyID and QR access',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              copy.isUz
                                  ? 'App uchun MyID yetadi. Web kirish uchun QR ni oldin yoki MyID paytida skanerlang.'
                                  : 'MyID is enough for the app. For website login, scan the QR before or during MyID.',
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: myIdBusy ? null : _startMyIdLogin,
                              icon: myIdBusy
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.verified_user_outlined),
                              label: Text(copy.isUz
                                  ? 'MyID bilan davom etish'
                                  : 'Continue with MyID'),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: myIdBusy ? null : _scanWebQr,
                              icon: const Icon(Icons.qr_code_scanner),
                              label: Text(copy.isUz
                                  ? 'Web QR ni skanerlash'
                                  : 'Scan web QR'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (loginStatus != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: .15)),
                        ),
                        child: Text(loginStatus!),
                      ),
                    ],
                    if (register) ...[
                      const SizedBox(height: 14),
                      SegmentedButton<AccountType>(
                        segments: [
                          ButtonSegment(
                            value: AccountType.physical,
                            label: Text(copy.isUz ? 'Fiz litso' : 'Physical'),
                            icon: const Icon(Icons.person_outline),
                          ),
                          ButtonSegment(
                            value: AccountType.legal,
                            label: Text(copy.isUz ? 'Yur litso' : 'Legal'),
                            icon: const Icon(Icons.business_outlined),
                          ),
                        ],
                        selected: {accountType},
                        onSelectionChanged: (value) {
                          setState(() => accountType = value.first);
                        },
                      ),
                      if (accountType == AccountType.legal) ...[
                        const SizedBox(height: 14),
                        TextField(
                            controller: companyName,
                            decoration: const InputDecoration(
                                labelText: 'Company name')),
                        const SizedBox(height: 10),
                        TextField(
                            controller: industry,
                            decoration:
                                const InputDecoration(labelText: 'Industry')),
                        const SizedBox(height: 10),
                        TextField(
                            controller: businessType,
                            decoration: const InputDecoration(
                                labelText: 'Business type')),
                        const SizedBox(height: 10),
                        TextField(
                            controller: startupDescription,
                            decoration: const InputDecoration(
                                labelText: 'Startup description')),
                        const SizedBox(height: 10),
                        TextField(
                            controller: contactInfo,
                            decoration: const InputDecoration(
                                labelText: 'Contact information')),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        copy.isUz
                            ? 'Davom etishda MyID sahifasiga yonaltiriladi. Web login bo‘lsa, QR ni oldin yoki MyID paytida skanerlang.'
                            : 'Continuing redirects to MyID. For web login, scan the QR before or during MyID.',
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed:
                          (context.watch<AuthController>().busy || myIdBusy)
                              ? null
                              : _submit,
                      icon: Icon(register ? Icons.person_add : Icons.login),
                      label: Text(register
                          ? (copy.isUz ? 'Hisob yaratish' : 'Create account')
                          : (copy.isUz ? 'Kirish' : 'Login')),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _submit(demo: true),
                      icon: const Icon(Icons.play_circle_outline),
                      label: Text(copy.isUz
                          ? 'Demo rejimida korish'
                          : 'Open demo mode'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () =>
                          _submit(demo: true, demoType: AccountType.legal),
                      icon: const Icon(Icons.business_center_outlined),
                      label: Text(
                          copy.isUz ? 'Yur litso demo' : 'Legal entity demo'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.initialIndex});

  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    final copy = Copy(context.watch<SettingsController>().isUz);
    final pages = [
      DashboardPage(copy: copy),
      BanksPage(copy: copy),
      CardsPage(copy: copy),
      LoansPage(copy: copy),
      InvestorsPage(copy: copy),
      AnalyticsPage(copy: copy),
      StartupsPage(copy: copy),
      ProfilePage(copy: copy),
      AdminPage(copy: copy),
      ServicesPage(copy: copy),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text([
          'BPay',
          copy.banks,
          copy.cards,
          copy.loans,
          copy.investors,
          copy.analytics,
          copy.startups,
          copy.profile,
          copy.admin,
          copy.services,
        ][index]),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => showNotificationsSheet(context),
            icon: const Icon(Icons.notifications_outlined),
          ),
          IconButton(
            tooltip: copy.settings,
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: const [0, 1, 2, 3, 6, 7].contains(index)
            ? const [0, 1, 2, 3, 6, 7].indexOf(index)
            : 0,
        onDestinationSelected: (value) {
          setState(() => index = const [0, 1, 2, 3, 6, 7][value]);
        },
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              label: copy.dashboard),
          NavigationDestination(
              icon: const Icon(Icons.account_balance_outlined),
              label: copy.banks),
          NavigationDestination(
              icon: const Icon(Icons.credit_card), label: copy.cards),
          NavigationDestination(
              icon: const Icon(Icons.payments_outlined), label: copy.loans),
          NavigationDestination(
              icon: const Icon(Icons.rocket_launch_outlined),
              label: copy.startups),
          NavigationDestination(
              icon: const Icon(Icons.person_outline), label: copy.profile),
        ],
      ),
      drawer: NavigationDrawer(
        selectedIndex: index,
        onDestinationSelected: (value) {
          Navigator.pop(context);
          setState(() => index = value);
        },
        children: [
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('BPay Super App',
                style: TextStyle(fontWeight: FontWeight.w900)),
          ),
          NavigationDrawerDestination(
              icon: const Icon(Icons.dashboard_outlined),
              label: Text(copy.dashboard)),
          NavigationDrawerDestination(
              icon: const Icon(Icons.account_balance_outlined),
              label: Text(copy.banks)),
          NavigationDrawerDestination(
              icon: const Icon(Icons.credit_card), label: Text(copy.cards)),
          NavigationDrawerDestination(
              icon: const Icon(Icons.payments_outlined),
              label: Text(copy.loans)),
          NavigationDrawerDestination(
              icon: const Icon(Icons.trending_up), label: Text(copy.investors)),
          NavigationDrawerDestination(
              icon: const Icon(Icons.query_stats), label: Text(copy.analytics)),
          NavigationDrawerDestination(
              icon: const Icon(Icons.rocket_launch_outlined),
              label: Text(copy.startups)),
          NavigationDrawerDestination(
              icon: const Icon(Icons.person_outline),
              label: Text(copy.profile)),
          NavigationDrawerDestination(
              icon: const Icon(Icons.admin_panel_settings_outlined),
              label: Text(copy.admin)),
          NavigationDrawerDestination(
              icon: const Icon(Icons.health_and_safety_outlined),
              label: Text(copy.services)),
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.copy});

  final Copy copy;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _CatalogHero(copy: copy),
        const SizedBox(height: 14),
        _CatalogCategories(copy: copy),
        const SizedBox(height: 16),
        _HeroBalance(userName: auth.userName, copy: copy),
        const SizedBox(height: 16),
        _QuickActions(copy: copy),
        const SizedBox(height: 16),
        _SectionTitle(copy.isUz ? 'Portfolio osishi' : 'Portfolio growth'),
        const SizedBox(height: 10),
        const _LineChartCard(values: [180, 195, 188, 210, 225, 240, 252, 284]),
        const SizedBox(height: 16),
        _SectionTitle(copy.isUz ? 'Songgi amaliyotlar' : 'Recent transactions'),
        const SizedBox(height: 8),
        _TransactionTile(
            icon: Icons.shopping_bag,
            title: 'Market payment',
            amount: '-124,000 UZS'),
        _TransactionTile(
            icon: Icons.restaurant, title: 'Dinner', amount: '-85,000 UZS'),
        _TransactionTile(
            icon: Icons.savings,
            title: 'Salary deposit',
            amount: '+9,200,000 UZS',
            positive: true),
      ],
    );
  }
}

class BanksPage extends StatefulWidget {
  const BanksPage({super.key, required this.copy});

  final Copy copy;

  @override
  State<BanksPage> createState() => _BanksPageState();
}

class _BanksPageState extends State<BanksPage> {
  OfferType? filter;
  String query = '';

  @override
  Widget build(BuildContext context) {
    final service = context.read<AppDataService>();
    final items = query.isEmpty
        ? service.filterBanks(filter)
        : service.searchBanks(query);
    return _OfferList(
      title: widget.copy.isUz ? 'Banklarni solishtirish' : 'Compare banks',
      searchLabel: widget.copy.search,
      onSearch: (value) => setState(() => query = value),
      chips: OfferType.values
          .map((type) => FilterChip(
                label: Text(type.name),
                selected: filter == type,
                onSelected: (_) =>
                    setState(() => filter = filter == type ? null : type),
              ))
          .toList(),
      children: [
        const _BarChartCard(),
        ...items.map(
          (bank) => _InfoCard(
            leading: _Avatar(text: bank.logo, color: bank.color),
            title: bank.name,
            subtitle: '${bank.apy}% APY - ${bank.rating} rating',
            trailing: '${NumberFormat.compact().format(bank.minDeposit)} UZS',
            tags: bank.features,
            action: widget.copy.apply,
            onTap: () => showBankSheet(context, bank, widget.copy),
          ),
        ),
      ],
    );
  }
}

class CardsPage extends StatefulWidget {
  const CardsPage({super.key, required this.copy});

  final Copy copy;

  @override
  State<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends State<CardsPage> {
  final cardNumber = TextEditingController(text: '9860123412345678');
  final expiry = TextEditingController(text: '03/29');
  final otp = TextEditingController(text: '111111');

  @override
  void dispose() {
    cardNumber.dispose();
    expiry.dispose();
    otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cards = context.watch<PaymentController>();
    final auth = context.watch<AuthController>();
    return _OfferList(
      title: widget.copy.isUz ? 'Bank kartalari' : 'Bank cards',
      searchLabel: widget.copy.search,
      onSearch: (_) {},
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(widget.copy.isUz ? 'Karta qoshish' : 'Add card'),
                const SizedBox(height: 10),
                TextField(
                  controller: cardNumber,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Card number'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: expiry,
                  keyboardType: TextInputType.datetime,
                  decoration: const InputDecoration(labelText: 'Expiry MM/YY'),
                ),
                const SizedBox(height: 10),
                if (cards.hasPendingOtp)
                  TextField(
                    controller: otp,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'SMS OTP (staging: 111111)'),
                  ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: cards.busy
                      ? null
                      : () async {
                          try {
                            if (cards.hasPendingOtp) {
                              await cards.verifyOtp(otp.text.trim());
                            } else {
                              await cards.startCardAdd(
                                cardNumber: cardNumber.text.trim(),
                                expiry: expiry.text.trim(),
                                phone: auth.profile?.phone ?? '+998901234567',
                              );
                            }
                          } on Object catch (error) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$error')),
                              );
                            }
                          }
                        },
                  icon: Icon(cards.hasPendingOtp
                      ? Icons.verified_user
                      : Icons.sms_outlined),
                  label:
                      Text(cards.hasPendingOtp ? 'Verify OTP' : 'Send SMS OTP'),
                ),
              ],
            ),
          ),
        ),
        ...cards.cards.map(
          (card) => Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.credit_card)),
              title: Text(card.cardName),
              subtitle: Text('${card.bankName} - ${card.maskedNumber}'),
              trailing: Text(card.expiryDate),
            ),
          ),
        ),
        ...AppDataService.cards.map(
          (card) => _InfoCard(
            leading: _IconBubble(icon: card.icon, color: card.color),
            title: card.name,
            subtitle: '${card.bank} - ${card.cashback}% cashback',
            trailing: card.limit,
            tags: card.benefits,
            action: widget.copy.order,
            onTap: () => showActionSheet(
              context,
              title: card.name,
              body: card.benefits.join('\n'),
              action: widget.copy.order,
            ),
          ),
        ),
      ],
    );
  }
}

class LoansPage extends StatefulWidget {
  const LoansPage({super.key, required this.copy});

  final Copy copy;

  @override
  State<LoansPage> createState() => _LoansPageState();
}

class _LoansPageState extends State<LoansPage> {
  LoanType? filter;

  @override
  Widget build(BuildContext context) {
    final service = context.read<AppDataService>();
    final loans = service.filterLoans(filter);
    return _OfferList(
      title: widget.copy.isUz ? 'Kreditlar markazi' : 'Loan center',
      searchLabel: widget.copy.search,
      onSearch: (_) {},
      chips: [
        ActionChip(
          avatar: const Icon(Icons.calculate_outlined),
          label: Text(widget.copy.isUz ? 'Kalkulyator' : 'Calculator'),
          onPressed: () => showLoanCalculator(context, widget.copy),
        ),
        ...LoanType.values.map(
          (type) => FilterChip(
            label: Text(type.name),
            selected: filter == type,
            onSelected: (_) =>
                setState(() => filter = filter == type ? null : type),
          ),
        ),
      ],
      children: [
        const _LineChartCard(values: [26, 25, 24, 23, 22, 21, 20]),
        ...loans.map(
          (loan) => _InfoCard(
            leading:
                _IconBubble(icon: loan.icon, color: const Color(0xFF10B981)),
            title: loan.name,
            subtitle: '${loan.bank} - ${loan.rate}% - ${loan.term}',
            trailing:
                '~${NumberFormat.compact().format(loan.monthlyPayment)} UZS',
            tags: loan.requirements,
            action: widget.copy.apply,
            onTap: () => showActionSheet(
              context,
              title: loan.name,
              body: loan.requirements.join('\n'),
              action: widget.copy.apply,
            ),
          ),
        ),
      ],
    );
  }
}

class InvestorsPage extends StatefulWidget {
  const InvestorsPage({super.key, required this.copy});

  final Copy copy;

  @override
  State<InvestorsPage> createState() => _InvestorsPageState();
}

class _InvestorsPageState extends State<InvestorsPage> {
  InvestorDomain? filter;

  @override
  Widget build(BuildContext context) {
    final service = context.read<AppDataService>();
    final investors = service.filterInvestors(filter);
    return _OfferList(
      title: widget.copy.isUz ? 'Investorlar platformasi' : 'Investor platform',
      searchLabel: widget.copy.search,
      onSearch: (_) {},
      chips: InvestorDomain.values
          .map((domain) => FilterChip(
                label: Text(domain.name),
                selected: filter == domain,
                onSelected: (_) =>
                    setState(() => filter = filter == domain ? null : domain),
              ))
          .toList(),
      children: [
        ...investors.map(
          (investor) => _InfoCard(
            leading: _IconBubble(
                icon: investor.icon, color: const Color(0xFF7C3AED)),
            title: investor.name,
            subtitle: investor.description,
            trailing: '+${investor.roi}% ROI',
            tags: [
              '${investor.projects} projects',
              'from \$${investor.minInvestment}'
            ],
            action: widget.copy.invest,
            onTap: () => showActionSheet(
              context,
              title: investor.name,
              body: investor.description,
              action: widget.copy.invest,
            ),
          ),
        ),
      ],
    );
  }
}

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key, required this.copy});

  final Copy copy;

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  String filter = 'all';

  @override
  Widget build(BuildContext context) {
    final isUz = widget.copy.isUz;
    final items = [
      _ServiceOffer(
          'microloan',
          isUz ? 'Tezkor mikroqarz' : 'Быстрый микрозайм',
          'Mikrokreditbank',
          isUz ? '24% dan' : 'от 24%',
          isUz
              ? 'Kichik summa va qisqa muddat.'
              : 'Small amount and short term.',
          Icons.speed_outlined,
          const Color(0xFFF59E0B)),
      _ServiceOffer(
          'microloan',
          isUz ? 'Onlayn mikroqarz' : 'Онлайн-микрозайм',
          'Anorbank',
          isUz ? '1–30 mln UZS' : '1–30m UZS',
          isUz ? 'Masofadan ariza topshirish.' : 'Apply remotely.',
          Icons.phone_android_outlined,
          const Color(0xFF06B6D4)),
      _ServiceOffer(
          'insurance',
          isUz ? 'Avto sug‘urta' : 'Автострахование',
          isUz ? 'Hamkor sug‘urta' : 'Partner insurer',
          isUz ? 'Online ariza' : 'Online application',
          isUz
              ? 'Avtomobil risklarini solishtiring.'
              : 'Compare vehicle protection options.',
          Icons.directions_car_outlined,
          const Color(0xFF2563EB)),
      _ServiceOffer(
          'insurance',
          isUz ? 'Sayohat sug‘urtasi' : 'Страхование путешествий',
          isUz ? 'Hamkor sug‘urta' : 'Partner insurer',
          '24/7',
          isUz
              ? 'Safar oldidan himoya rejasini tanlang.'
              : 'Choose protection before a trip.',
          Icons.flight_takeoff_outlined,
          const Color(0xFF7C3AED)),
      _ServiceOffer(
          'insurance',
          isUz ? 'Sog‘liq sug‘urtasi' : 'Страхование здоровья',
          isUz ? 'Hamkor sug‘urta' : 'Partner insurer',
          isUz ? 'Individual' : 'For you',
          isUz
              ? 'Shaxsiy va oila uchun reja.'
              : 'Plans for you and your family.',
          Icons.health_and_safety_outlined,
          const Color(0xFF10B981)),
    ].where((item) => filter == 'all' || item.kind == filter).toList();

    return _OfferList(
      title: widget.copy.services,
      searchLabel: widget.copy.search,
      onSearch: (_) {},
      chips: [
        FilterChip(
            label: Text(isUz ? 'Barchasi' : 'All'),
            selected: filter == 'all',
            onSelected: (_) => setState(() => filter = 'all')),
        FilterChip(
            label: Text(isUz ? 'Mikroqarzlar' : 'Microloans'),
            selected: filter == 'microloan',
            onSelected: (_) => setState(
                () => filter = filter == 'microloan' ? 'all' : 'microloan')),
        FilterChip(
            label: Text(isUz ? 'Sug‘urta' : 'Insurance'),
            selected: filter == 'insurance',
            onSelected: (_) => setState(
                () => filter = filter == 'insurance' ? 'all' : 'insurance')),
      ],
      children: [
        Card(
          color: Theme.of(context)
              .colorScheme
              .primaryContainer
              .withValues(alpha: .52),
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(widget.copy.p2pInDevelopment,
                style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(widget.copy.p2pDescription),
            onTap: () => showP2PStatusSheet(context, widget.copy),
          ),
        ),
        ...items.map((item) => _InfoCard(
              leading: _IconBubble(icon: item.icon, color: item.color),
              title: item.name,
              subtitle: '${item.provider} · ${item.metric}',
              trailing: item.kind == 'insurance'
                  ? (isUz ? 'Himoya' : 'Protection')
                  : (isUz ? 'Kredit' : 'Loan'),
              tags: [
                item.kind == 'insurance'
                    ? (isUz ? 'Sug‘urta' : 'Insurance')
                    : (isUz ? 'Mikroqarz' : 'Microloan'),
                isUz ? 'Taqqoslash' : 'Compare'
              ],
              action: isUz ? 'Shartlar' : 'Details',
              onTap: () => showActionSheet(context,
                  title: item.name,
                  body: item.description,
                  action: isUz ? 'Tushunarli' : 'Got it'),
            )),
      ],
    );
  }
}

class _ServiceOffer {
  const _ServiceOffer(this.kind, this.name, this.provider, this.metric,
      this.description, this.icon, this.color);

  final String kind;
  final String name;
  final String provider;
  final String metric;
  final String description;
  final IconData icon;
  final Color color;
}

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key, required this.copy});

  final Copy copy;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _MetricGrid(copy: copy),
        const SizedBox(height: 16),
        _SectionTitle(copy.isUz ? 'Daromad va xarajat' : 'Income and spending'),
        const SizedBox(height: 10),
        const _LineChartCard(values: [78, 79, 81, 83, 82, 86, 89, 92]),
        const SizedBox(height: 16),
        _SectionTitle(copy.isUz ? 'Aktivlar taqsimoti' : 'Asset allocation'),
        const SizedBox(height: 10),
        const _PieChartCard(),
      ],
    );
  }
}

class StartupsPage extends StatefulWidget {
  const StartupsPage({super.key, required this.copy});

  final Copy copy;

  @override
  State<StartupsPage> createState() => _StartupsPageState();
}

class _StartupsPageState extends State<StartupsPage> {
  final query = TextEditingController();
  final name = TextEditingController(text: 'New BPay Startup');
  final category = TextEditingController(text: 'FinTech');
  final description =
      TextEditingController(text: 'Describe the startup value proposition');
  final goal = TextEditingController(text: '500000000');
  final model = TextEditingController(text: 'Subscription and transaction fee');
  final finance =
      TextEditingController(text: 'Revenue, margin, runway, burn rate');
  bool requestedServerLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (requestedServerLoad) return;
    requestedServerLoad = true;
    Future.microtask(() => context.read<StartupController>().loadFromServer());
  }

  @override
  void dispose() {
    query.dispose();
    name.dispose();
    category.dispose();
    description.dispose();
    goal.dispose();
    model.dispose();
    finance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final startups = context.watch<StartupController>();
    final profile = auth.profile;
    final filtered = startups.startups
        .where((startup) =>
            startup.name.toLowerCase().contains(query.text.toLowerCase()) ||
            startup.category.toLowerCase().contains(query.text.toLowerCase()))
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: query,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: widget.copy.isUz ? 'Startap qidirish' : 'Search startups',
            prefixIcon: const Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 12),
        if (profile?.canCreateStartups ?? false)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(
                      widget.copy.isUz ? 'Startap yaratish' : 'Create startup'),
                  const SizedBox(height: 10),
                  TextField(
                      controller: name,
                      decoration:
                          const InputDecoration(labelText: 'Startup name')),
                  const SizedBox(height: 8),
                  TextField(
                      controller: category,
                      decoration: const InputDecoration(labelText: 'Category')),
                  const SizedBox(height: 8),
                  TextField(
                      controller: description,
                      decoration:
                          const InputDecoration(labelText: 'Description')),
                  const SizedBox(height: 8),
                  TextField(
                      controller: goal,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Investment goal')),
                  const SizedBox(height: 8),
                  TextField(
                      controller: model,
                      decoration:
                          const InputDecoration(labelText: 'Business model')),
                  const SizedBox(height: 8),
                  TextField(
                      controller: finance,
                      decoration: const InputDecoration(
                          labelText: 'Financial information')),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: startups.busy
                        ? null
                        : () async {
                            await startups.createStartup(
                              ownerUserId: profile!.id,
                              name: name.text.trim(),
                              category: category.text.trim(),
                              description: description.text.trim(),
                              goal: int.tryParse(goal.text) ?? 0,
                              businessModel: model.text.trim(),
                              financialInfo: finance.text.trim(),
                            );
                          },
                    icon: const Icon(Icons.rocket_launch_outlined),
                    label: Text(widget.copy.isUz
                        ? 'Tasdiqlashga yuborish'
                        : 'Submit for approval'),
                  ),
                ],
              ),
            ),
          ),
        ...filtered.map(
          (startup) => _InfoCard(
            leading: _Avatar(
                text: startup.name.substring(0, 2).toUpperCase(),
                color: const Color(0xFF2563EB)),
            title: startup.name,
            subtitle: startup.description,
            trailing:
                '${NumberFormat.compact().format(startup.raisedAmount)} / ${NumberFormat.compact().format(startup.investmentGoal)}',
            tags: [
              startup.category,
              startup.status.name,
              '${startup.investorsCount} investors'
            ],
            action:
                profile?.canInvest ?? true ? widget.copy.invest : 'Analytics',
            onTap: () async {
              if (profile?.canInvest ?? true) {
                await startups.invest(
                  userId: profile?.id ?? 'user_demo',
                  startupId: startup.id,
                  amount: 1000000,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          '${widget.copy.invest}: ${widget.copy.success}')),
                );
              } else {
                showActionSheet(
                  context,
                  title: startup.name,
                  body: '${startup.businessModel}\n${startup.financialInfo}',
                  action: 'Open analytics',
                );
              }
            },
          ),
        ),
      ],
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.copy});

  final Copy copy;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final profile = auth.profile;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(radius: 28, child: Icon(Icons.person)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile?.fullName ?? 'Guest',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 18)),
                          Text(profile?.phone ?? '+998 -- --- -- --'),
                        ],
                      ),
                    ),
                    Chip(
                      avatar: const Icon(Icons.verified, size: 16),
                      label: Text(profile?.isMyIdVerified ?? false
                          ? 'MyID verified'
                          : 'Not verified'),
                    ),
                  ],
                ),
                const Divider(height: 28),
                _ProfileRow(label: 'User ID', value: profile?.id ?? '-'),
                _ProfileRow(
                    label: 'Account type',
                    value: profile?.accountType.name ?? '-'),
                _ProfileRow(
                    label: 'Verification status',
                    value: profile?.verificationStatus ?? '-'),
                _ProfileRow(
                    label: 'MyID status',
                    value: profile?.myIdStatus.name ?? '-'),
                if (profile?.business != null) ...[
                  const Divider(height: 28),
                  _ProfileRow(
                      label: 'Company', value: profile!.business!.companyName),
                  _ProfileRow(
                      label: 'Industry', value: profile.business!.industry),
                  _ProfileRow(
                      label: 'Contact', value: profile.business!.contactInfo),
                ],
              ],
            ),
          ),
        ),
        ListTile(
            leading: const Icon(Icons.language),
            title: Text(copy.settings),
            onTap: () => Navigator.pushNamed(context, '/settings')),
        ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Security settings'),
            onTap: () {}),
        ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications settings'),
            onTap: () {}),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Logout'),
          onTap: () {
            auth.logout();
            Navigator.pushReplacementNamed(context, '/login');
          },
        ),
      ],
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant))),
          Expanded(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class AdminPage extends StatelessWidget {
  const AdminPage({super.key, required this.copy});

  final Copy copy;

  @override
  Widget build(BuildContext context) {
    final stats = AppDataService.adminStats;
    final startupController = context.watch<StartupController>();
    final pending = startupController.startups
        .where((startup) => startup.status == StartupStatus.pendingApproval)
        .length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _MetricGrid(copy: copy),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              _AdminTile(
                  label: 'Manage users',
                  value: '${stats.users}',
                  icon: Icons.people_outline),
              _AdminTile(
                  label: 'Manage startups',
                  value: '${startupController.startups.length}',
                  icon: Icons.rocket_launch_outlined),
              _AdminTile(
                  label: 'Manage investments',
                  value: '${startupController.investments.length}',
                  icon: Icons.savings_outlined),
              _AdminTile(
                  label: 'Manage banks',
                  value: '${AppDataService.banks.length}',
                  icon: Icons.account_balance_outlined),
              _AdminTile(
                  label: 'Pending approvals',
                  value: '$pending',
                  icon: Icons.approval_outlined),
              _AdminTile(
                  label: 'Analytics events',
                  value: '${stats.investments}',
                  icon: Icons.query_stats),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminTile extends StatelessWidget {
  const _AdminTile(
      {required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing:
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final copy = Copy(settings.isUz);
    return Scaffold(
      appBar: AppBar(title: Text(copy.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _LogoMark(size: 72),
          const SizedBox(height: 16),
          _SectionTitle(copy.isUz ? 'Til' : 'Language'),
          const SizedBox(height: 8),
          const _LanguageToggle(expanded: true),
          const SizedBox(height: 18),
          _SectionTitle(copy.isUz ? 'Mavzu' : 'Theme'),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode)),
              ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode)),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (value) => settings.setThemeMode(value.first),
          ),
          const SizedBox(height: 18),
          SwitchListTile(
            value: settings.settings.notificationsEnabled,
            onChanged: settings.toggleNotifications,
            title: Text(copy.isUz ? 'Bildirishnomalar' : 'Notifications'),
            secondary: const Icon(Icons.notifications_active_outlined),
          ),
          SwitchListTile(
            value: settings.settings.biometricEnabled,
            onChanged: settings.toggleBiometric,
            title: Text(copy.isUz ? 'Biometrik kirish' : 'Biometric login'),
            secondary: const Icon(Icons.fingerprint),
          ),
        ],
      ),
    );
  }
}

class _OfferList extends StatelessWidget {
  const _OfferList({
    required this.title,
    required this.searchLabel,
    required this.onSearch,
    required this.children,
    this.chips = const [],
  });

  final String title;
  final String searchLabel;
  final ValueChanged<String> onSearch;
  final List<Widget> chips;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        TextField(
          onChanged: onSearch,
          decoration: InputDecoration(
            hintText: searchLabel,
            prefixIcon: const Icon(Icons.search),
          ),
        ),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: chips),
        ],
        const SizedBox(height: 14),
        ...children.map((child) =>
            Padding(padding: const EdgeInsets.only(bottom: 12), child: child)),
      ],
    );
  }
}

class _CatalogHero extends StatelessWidget {
  const _CatalogHero({required this.copy});

  final Copy copy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF0891B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              copy.isUz
                  ? 'MOLIYAVIY TAKLIFLAR KATALOGI'
                  : 'FINANCIAL OFFERS CATALOG',
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1)),
          const SizedBox(height: 10),
          Text(copy.catalogTitle,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  height: 1.08,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Text(copy.catalogSubtitle,
              style: const TextStyle(color: Colors.white70, height: 1.45)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/loans'),
                  icon: const Icon(Icons.compare_arrows),
                  label: Text(copy.isUz ? 'Solishtirish' : 'Compare'),
                  style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1D4ED8)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showP2PStatusSheet(context, copy),
                  icon: const Icon(Icons.schedule),
                  label: Text(copy.isUz ? 'P2P holati' : 'P2P status'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: Colors.amberAccent, size: 19),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(copy.p2pDescription,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12, height: 1.4))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogCategories extends StatelessWidget {
  const _CatalogCategories({required this.copy});

  final Copy copy;

  @override
  Widget build(BuildContext context) {
    final categories = [
      (
        copy.banks,
        copy.isUz
            ? 'Banklar va rasmiy mahsulotlar'
            : 'Banks and official products',
        Icons.account_balance_outlined,
        const Color(0xFF2563EB),
        '/banks'
      ),
      (
        copy.loans,
        copy.isUz ? 'Shaxsiy, avto, ipoteka' : 'Personal, auto, mortgage',
        Icons.payments_outlined,
        const Color(0xFF059669),
        '/loans'
      ),
      (
        copy.services,
        copy.isUz ? 'Kichik qarzlar va sug‘urta' : 'Small loans and insurance',
        Icons.health_and_safety_outlined,
        const Color(0xFFF59E0B),
        '/services'
      ),
      (
        copy.cards,
        copy.isUz ? 'Cashback va limitlar' : 'Cashback and limits',
        Icons.credit_card_outlined,
        const Color(0xFF7C3AED),
        '/cards'
      ),
      (
        copy.investors,
        copy.isUz ? 'Startaplar va loyihalar' : 'Startups and projects',
        Icons.trending_up,
        const Color(0xFFE11D48),
        '/investors'
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(copy.isUz ? 'Mashhur yo‘nalishlar' : 'Popular categories',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.sizeOf(context).width > 540 ? 3 : 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio:
                MediaQuery.sizeOf(context).width > 540 ? 1.45 : 1.18,
          ),
          itemBuilder: (context, index) {
            final item = categories[index];
            return Card(
              child: InkWell(
                onTap: () => Navigator.pushNamed(context, item.$5),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(13),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                            backgroundColor: item.$4.withValues(alpha: .13),
                            foregroundColor: item.$4,
                            child: Icon(item.$3)),
                        const Spacer(),
                        Text(item.$1,
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(item.$2,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontSize: 11,
                                height: 1.3)),
                      ]),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _HeroBalance extends StatelessWidget {
  const _HeroBalance({required this.userName, required this.copy});

  final String userName;
  final Copy copy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF06B6D4), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(copy.isUz ? 'Xush kelibsiz, $userName' : 'Welcome, $userName',
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          const Text(
            '284,521,000 UZS',
            style: TextStyle(
                color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 18),
          Row(
            children: const [
              _HeroStat(label: 'Growth', value: '+12.4%'),
              SizedBox(width: 18),
              _HeroStat(label: 'Score', value: '821'),
              SizedBox(width: 18),
              _HeroStat(label: 'Cards', value: '4'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.copy});

  final Copy copy;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionButton(
            icon: Icons.schedule,
            label: copy.isUz ? 'P2P' : 'P2P',
            onTap: () => showP2PStatusSheet(context, copy)),
        _ActionButton(
            icon: Icons.add_card,
            label: copy.order,
            onTap: () => Navigator.pushNamed(context, '/cards')),
        _ActionButton(
            icon: Icons.calculate,
            label: 'Calc',
            onTap: () => showLoanCalculator(context, copy)),
        _ActionButton(
            icon: Icons.query_stats,
            label: copy.analytics,
            onTap: () => Navigator.pushNamed(context, '/analytics')),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              CircleAvatar(child: Icon(icon)),
              const SizedBox(height: 6),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.tags,
    required this.action,
    required this.onTap,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final String trailing;
  final List<String> tags;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  leading,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 16)),
                        Text(subtitle,
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(trailing,
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags
                    .take(3)
                    .map((tag) => Chip(
                        label: Text(tag), visualDensity: VisualDensity.compact))
                    .toList(),
              ),
              const SizedBox(height: 8),
              Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(onPressed: onTap, child: Text(action))),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.copy});

  final Copy copy;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      (
        'Net worth',
        '284.5M',
        Icons.account_balance_wallet,
        const Color(0xFF2563EB)
      ),
      ('Income', '9.2M', Icons.trending_up, const Color(0xFF10B981)),
      ('Spending', '3.1M', Icons.trending_down, const Color(0xFFE11D48)),
      ('Savings', '66%', Icons.savings, const Color(0xFF7C3AED)),
    ];
    return GridView.count(
      crossAxisCount: MediaQuery.sizeOf(context).width > 520 ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.45,
      children: metrics
          .map((m) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(m.$3, color: m.$4),
                      Text(m.$1, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(m.$2,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _LineChartCard extends StatelessWidget {
  const _LineChartCard({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 18, 18, 10),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: const FlTitlesData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (var i = 0; i < values.length; i++)
                      FlSpot(i.toDouble(), values[i]),
                  ],
                  color: Theme.of(context).colorScheme.primary,
                  barWidth: 4,
                  isCurved: true,
                  belowBarData: BarAreaData(
                    show: true,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: .14),
                  ),
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BarChartCard extends StatelessWidget {
  const _BarChartCard();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: BarChart(
            BarChartData(
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: const FlTitlesData(show: false),
              barGroups: AppDataService.banks
                  .map((bank) => BarChartGroupData(
                        x: bank.id,
                        barRods: [
                          BarChartRodData(
                            toY: bank.apy,
                            color: bank.color,
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _PieChartCard extends StatelessWidget {
  const _PieChartCard();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 44,
              sections: [
                PieChartSectionData(
                    value: 42, color: Color(0xFF2563EB), title: 'Stocks'),
                PieChartSectionData(
                    value: 18, color: Color(0xFF7C3AED), title: 'Intl'),
                PieChartSectionData(
                    value: 15, color: Color(0xFF10B981), title: 'Bonds'),
                PieChartSectionData(
                    value: 12, color: Color(0xFFF59E0B), title: 'Estate'),
                PieChartSectionData(
                    value: 13, color: Color(0xFFE11D48), title: 'Cash'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile(
      {required this.icon,
      required this.title,
      required this.amount,
      this.positive = false});

  final IconData icon;
  final String title;
  final String amount;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title),
        subtitle: const Text('Today'),
        trailing: Text(
          amount,
          style: TextStyle(
            color: positive ? const Color(0xFF10B981) : null,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({this.expanded = false});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'uz', label: Text('UZ')),
        ButtonSegment(value: 'ru', label: Text('RU')),
      ],
      selected: {settings.language},
      onSelectionChanged: (value) => settings.setLanguage(value.first),
      style: expanded
          ? null
          : const ButtonStyle(visualDensity: VisualDensity.compact),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * .14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SvgPicture.asset(
        'fintech app/logo.svg',
        fit: BoxFit.contain,
        placeholderBuilder: (_) => const Center(child: Text('B1')),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.w900));
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
        backgroundColor: color,
        child: Text(text, style: const TextStyle(color: Colors.white)));
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
        backgroundColor: color.withValues(alpha: .14),
        child: Icon(icon, color: color));
  }
}

void showActionSheet(BuildContext context,
    {required String title, required String body, required String action}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title),
          const SizedBox(height: 12),
          Text(body),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('$action: successful')));
            },
            icon: const Icon(Icons.check),
            label: Text(action),
          ),
        ],
      ),
    ),
  );
}

void showP2PStatusSheet(BuildContext context, Copy copy) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.schedule, color: Color(0xFFF59E0B)),
            const SizedBox(width: 8),
            Expanded(child: _SectionTitle(copy.p2pInDevelopment)),
          ]),
          const SizedBox(height: 12),
          Text(copy.isUz
              ? "OCTO Money Transfer integratsiyasi va Markaziy bank talablari bo'yicha ruxsatlar tayyorlanmoqda. Hozircha ilova takliflarni solishtirish va hamkor xizmatlariga yo'naltirish uchun ishlaydi."
              : 'We are preparing the OCTO Money Transfer integration and required approvals. For now, the app compares offers and directs users to partner services.'),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.check),
            label: Text(copy.isUz ? 'Tushunarli' : 'Got it'),
          ),
        ],
      ),
    ),
  );
}

void showBankSheet(BuildContext context, BankOffer bank, Copy copy) {
  showActionSheet(
    context,
    title: bank.name,
    body:
        '${bank.apy}% APY\n${bank.features.join('\n')}\nRating: ${bank.rating}',
    action: copy.apply,
  );
}

void showTransferSheet(BuildContext context, Copy copy) {
  final amount = TextEditingController();
  final target = TextEditingController();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SectionTitle(copy.transfer),
          const SizedBox(height: 14),
          TextField(
              controller: target,
              decoration: const InputDecoration(labelText: 'Card or phone')),
          const SizedBox(height: 12),
          TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount')),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${copy.transfer}: ${copy.success}')));
            },
            icon: const Icon(Icons.send),
            label: Text(copy.transfer),
          ),
        ],
      ),
    ),
  ).whenComplete(() {
    amount.dispose();
    target.dispose();
  });
}

void showLoanCalculator(BuildContext context, Copy copy) {
  final principal = TextEditingController(text: '50000000');
  final rate = TextEditingController(text: '20');
  final months = TextEditingController(text: '24');
  double? result;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SectionTitle(copy.isUz ? 'Kredit kalkulyator' : 'Loan calculator'),
            const SizedBox(height: 14),
            TextField(
                controller: principal,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Principal')),
            const SizedBox(height: 12),
            TextField(
                controller: rate,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Annual rate')),
            const SizedBox(height: 12),
            TextField(
                controller: months,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Months')),
            const SizedBox(height: 16),
            if (result != null)
              Text(
                  '${NumberFormat.decimalPattern().format(result!.round())} UZS / month',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                setModalState(() {
                  result = AppDataService.calculateMonthlyPayment(
                    principal: double.tryParse(principal.text) ?? 0,
                    annualRate: double.tryParse(rate.text) ?? 0,
                    months: int.tryParse(months.text) ?? 1,
                  );
                });
              },
              icon: const Icon(Icons.calculate),
              label: const Text('Calculate'),
            ),
          ],
        ),
      ),
    ),
  ).whenComplete(() {
    principal.dispose();
    rate.dispose();
    months.dispose();
  });
}

void showNotificationsSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionTitle('Notifications'),
        const SizedBox(height: 8),
        ...AppDataService.notifications.map(
          (item) => Card(
            child: ListTile(
              leading: _IconBubble(icon: item.icon, color: item.color),
              title: Text(item.title),
              subtitle: Text(item.body),
              trailing: Text(item.time),
            ),
          ),
        ),
      ],
    ),
  );
}

String? _extractSessionIdFromQrValue(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  final uri = Uri.tryParse(trimmed);
  if (uri != null) {
    final querySession =
        uri.queryParameters['session_id'] ?? uri.queryParameters['sessionId'];
    if (querySession != null && querySession.isNotEmpty) return querySession;
    if (uri.scheme == 'bpay' && uri.host == 'auth') {
      if (uri.pathSegments.isNotEmpty) {
        final lastSegment = uri.pathSegments.last;
        if (lastSegment.isNotEmpty) return lastSegment;
      }
    }
  }
  if (trimmed.startsWith('session_id=')) {
    final parts = trimmed.split('=');
    if (parts.length > 1 && parts.last.isNotEmpty) return parts.last;
  }
  return trimmed.length >= 12 ? trimmed : null;
}

class _QrScannerSheet extends StatefulWidget {
  const _QrScannerSheet();

  @override
  State<_QrScannerSheet> createState() => _QrScannerSheetState();
}

class _QrScannerSheetState extends State<_QrScannerSheet> {
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue ?? barcode.displayValue ?? '';
      final sessionId = _extractSessionIdFromQrValue(rawValue);
      if (sessionId != null) {
        _handled = true;
        Navigator.of(context).pop(sessionId);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * .86;
    return SafeArea(
      child: SizedBox(
        height: height,
        child: Container(
          color: Colors.black,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Scan web QR',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0x332563EB)),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        MobileScanner(onDetect: _onDetect),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            color: Colors.black.withValues(alpha: .45),
                            child: const Text(
                              'Point the camera at the QR shown on the website',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
