import 'package:flutter/material.dart';

import 'app_data_service.dart';
import 'integrations.dart';
import 'models.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required UserRepository userRepository,
    required B1ApiClient api,
  })  : _userRepository = userRepository,
        _api = api;

  final UserRepository _userRepository;
  final B1ApiClient _api;

  bool _authenticated = false;
  bool _busy = false;
  Uri? _myIdRedirectUri;
  UserProfile? _profile;

  bool get authenticated => _authenticated;
  bool get busy => _busy;
  Uri? get myIdRedirectUri => _myIdRedirectUri;
  UserProfile? get profile => _profile;
  String get userName => _profile?.fullName ?? 'Anvar Karimov';

  void applySession(UserProfile profile) {
    _profile = profile;
    _authenticated = true;
    notifyListeners();
  }

  String? validatePhonePassword(String phone, String password) {
    final normalized = phone.replaceAll(RegExp(r'\s+'), '');
    if (!normalized.startsWith('+998') || normalized.length < 13) {
      return 'Enter Uzbekistan phone number in +998 format';
    }
    if (password.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? validateLogin(String emailOrPhone, String password) =>
      validatePhonePassword(emailOrPhone, password);

  Future<void> register({
    required String phone,
    required String password,
    required AccountType accountType,
    BusinessQuestionnaire? business,
  }) async {
    final error = validatePhonePassword(phone, password);
    if (error != null) throw StateError(error);
    if (accountType == AccountType.legal && business == null) {
      throw StateError('Legal entities must complete business questionnaire');
    }

    _busy = true;
    notifyListeners();
    try {
      _profile = await _userRepository.register(
        phone: phone,
        password: password,
        accountType: accountType,
        business: business,
      );
      _authenticated = true;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> login(String phone, String password) async {
    final error = validatePhonePassword(phone, password);
    if (error != null) throw StateError(error);
    _busy = true;
    notifyListeners();
    try {
      _profile = await _userRepository.login(
        phone: phone,
        password: password,
      );
      _authenticated = true;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<MyIdStartSession> startMyIdLogin({
    required String phone,
    String? email,
    AccountType accountType = AccountType.physical,
  }) {
    return _api.startMobileMyIdSession(
      phone: phone,
      email: email,
      accountType: accountType,
    );
  }

  Future<MyIdCompletion> completeMyIdLogin({
    required String sessionId,
    required String phone,
    required String resultCode,
    required bool verified,
    String? qrSessionId,
    String? email,
    String? firstName,
    String? lastName,
    String? passport,
    String? birthDate,
    Map<String, dynamic>? myIdPayload,
  }) async {
    _busy = true;
    notifyListeners();
    try {
      final completion = await _api.completeMobileMyIdSession(
        sessionId: sessionId,
        phone: phone,
        resultCode: resultCode,
        verified: verified,
        qrSessionId: qrSessionId,
        email: email,
        firstName: firstName,
        lastName: lastName,
        passport: passport,
        birthDate: birthDate,
        myIdPayload: myIdPayload,
      );
      if (!completion.isVerified) {
        throw StateError(
          completion.error?.trim().isNotEmpty == true
              ? completion.error!
              : 'MyID verification was not confirmed by the server',
        );
      }
      _profile = completion.profile;
      _authenticated = true;
      return completion;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void demoLogin({AccountType type = AccountType.physical}) {
    _profile = UserProfile(
      id: type == AccountType.legal ? 'user_legal_demo' : 'user_demo',
      phone: '+998901234567',
      accountType: type,
      myIdStatus: MyIdStatus.verified,
      verificationStatus: 'verified',
      identity: IdentityData(
        firstName: type == AccountType.legal ? 'Madina' : 'Anvar',
        lastName: type == AccountType.legal ? 'Saidova' : 'Karimov',
        middleName: type == AccountType.legal ? 'Rustamovna' : 'Akmalovich',
        birthDate: DateTime(1994, 4, 12),
        gender: type == AccountType.legal ? 'female' : 'male',
        verifiedPhone: '+998901234567',
        pinfl: '',
      ),
      business: type == AccountType.legal
          ? const BusinessQuestionnaire(
              companyName: 'B1 Ventures LLC',
              industry: 'FinTech',
              businessType: 'Startup',
              startupDescription: 'Payment infrastructure for SMEs.',
              contactInfo: 'founder@b1.uz',
            )
          : null,
    );
    _authenticated = true;
    notifyListeners();
  }

  void logout() {
    _authenticated = false;
    notifyListeners();
  }
}

class PaymentController extends ChangeNotifier {
  PaymentController({required PaymentGateway gateway}) : _gateway = gateway;

  final PaymentGateway _gateway;
  final List<ConnectedCard> _cards = [];
  String? _pendingSessionId;
  String? _pendingCardNumber;
  bool _busy = false;

  List<ConnectedCard> get cards => List.unmodifiable(_cards);
  bool get busy => _busy;
  bool get hasPendingOtp => _pendingSessionId != null;

  Future<void> startCardAdd({
    required String cardNumber,
    required String expiry,
    required String phone,
  }) async {
    _busy = true;
    notifyListeners();
    try {
      _pendingSessionId = await _gateway.sendCardOtp(
        cardNumber: cardNumber,
        expiry: expiry,
        phone: phone,
      );
      _pendingCardNumber = cardNumber;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> verifyOtp(String otp) async {
    if (_pendingSessionId == null || _pendingCardNumber == null) {
      throw StateError('No card verification session started');
    }
    _busy = true;
    notifyListeners();
    try {
      final card = await _gateway.verifyCardOtp(
        sessionId: _pendingSessionId!,
        otp: otp,
        cardNumber: _pendingCardNumber!,
      );
      _cards.add(card);
      _pendingSessionId = null;
      _pendingCardNumber = null;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}

class StartupController extends ChangeNotifier {
  StartupController({B1ApiClient? api}) : _api = api;

  final B1ApiClient? _api;
  final List<StartupListing> _startups = [...AppDataService.startups];
  final List<InvestmentRecord> _investments = [...AppDataService.investments];
  bool _busy = false;
  String? _lastError;

  List<StartupListing> get startups => List.unmodifiable(_startups);
  List<InvestmentRecord> get investments => List.unmodifiable(_investments);
  bool get busy => _busy;
  String? get lastError => _lastError;

  Future<void> loadFromServer() async {
    final api = _api;
    if (api == null || !api.isAuthenticated || _busy) return;
    _busy = true;
    notifyListeners();
    try {
      final serverStartups = await api.fetchStartups();
      if (serverStartups.isNotEmpty) {
        _startups
          ..clear()
          ..addAll(serverStartups);
      }
      _lastError = null;
    } on Object catch (error) {
      _lastError = '$error';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> createStartup({
    required String ownerUserId,
    required String name,
    required String category,
    required String description,
    required int goal,
    required String businessModel,
    required String financialInfo,
  }) async {
    _busy = true;
    notifyListeners();
    try {
      final api = _api;
      if (api != null && api.isAuthenticated) {
        final startup = await api.createStartup(
          name: name,
          category: category,
          description: description,
          goal: goal,
          businessModel: businessModel,
          financialInfo: financialInfo,
        );
        _startups.insert(0, startup);
        _lastError = null;
        return;
      }
    } on Object catch (error) {
      _lastError = '$error';
    } finally {
      _busy = false;
      notifyListeners();
    }

    _startups.insert(
      0,
      StartupListing(
        id: 'st_${DateTime.now().millisecondsSinceEpoch}',
        ownerUserId: ownerUserId,
        name: name,
        category: category,
        logoUrl: '',
        description: description,
        investmentGoal: goal,
        raisedAmount: 0,
        businessModel: businessModel,
        financialInfo: financialInfo,
        status: StartupStatus.pendingApproval,
        investorsCount: 0,
      ),
    );
    notifyListeners();
  }

  Future<void> invest({
    required String userId,
    required String startupId,
    required int amount,
  }) async {
    try {
      final api = _api;
      if (api != null && api.isAuthenticated) {
        await api.createInvestment(startupId: startupId, amount: amount);
        _lastError = null;
      }
    } on Object catch (error) {
      _lastError = '$error';
    }
    _investments.add(
      InvestmentRecord(
        id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        startupId: startupId,
        amount: amount,
        status: InvestmentStatus.active,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }
}

class SettingsController extends ChangeNotifier {
  AppSettings _settings = const AppSettings(
    language: 'uz',
    themeMode: ThemeMode.dark,
    notificationsEnabled: true,
    biometricEnabled: false,
    currency: 'UZS',
  );

  AppSettings get settings => _settings;
  ThemeMode get themeMode => _settings.themeMode;
  String get language => _settings.language;
  bool get isUz => _settings.language == 'uz';

  void setLanguage(String language) {
    _settings = _settings.copyWith(language: language);
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _settings = _settings.copyWith(themeMode: mode);
    notifyListeners();
  }

  void toggleNotifications(bool enabled) {
    _settings = _settings.copyWith(notificationsEnabled: enabled);
    notifyListeners();
  }

  void toggleBiometric(bool enabled) {
    _settings = _settings.copyWith(biometricEnabled: enabled);
    notifyListeners();
  }
}

class Copy {
  const Copy(this.isUz);

  final bool isUz;

  String get appName => 'BPay';
  String get tagline => isUz ? 'Moliyaviy platforma' : 'Financial platform';
  String get loginTitle => isUz ? 'Xush kelibsiz' : 'Welcome back';
  String get loginSubtitle => isUz
      ? 'Telefon raqam va parol bilan kiring'
      : 'Sign in with phone number and password';
  String get dashboard => isUz ? 'Takliflar' : 'Offers';
  String get banks => isUz ? 'Banklar' : 'Banks';
  String get cards => isUz ? 'Kartalar' : 'Cards';
  String get loans => isUz ? 'Kreditlar' : 'Loans';
  String get services =>
      isUz ? 'Mikroqarz va sug\'urta' : 'Microloans & insurance';
  String get startups => isUz ? 'Startaplar' : 'Startups';
  String get profile => isUz ? 'Profil' : 'Profile';
  String get admin => isUz ? 'Admin' : 'Admin';
  String get investors => isUz ? 'Investorlar' : 'Investors';
  String get analytics => isUz ? 'Tahlil' : 'Analytics';
  String get settings => isUz ? 'Sozlamalar' : 'Settings';
  String get search => isUz ? 'Qidirish' : 'Search';
  String get apply => isUz ? 'Ariza berish' : 'Apply';
  String get order => isUz ? 'Buyurtma' : 'Order';
  String get invest => isUz ? 'Investitsiya' : 'Invest';
  String get transfer => isUz ? 'Pul o\'tkazish' : 'Transfer';
  String get catalogTitle => isUz
      ? 'Sizga mos moliyaviy taklifni toping'
      : 'Find an offer for your goal';
  String get catalogSubtitle => isUz
      ? 'Banklar, kreditlar, kartalar, mikroqarzlar, sug\'urta va investitsiyalarni solishtiring.'
      : 'Compare banks, loans, cards, microloans, insurance and investments.';
  String get p2pInDevelopment => isUz
      ? 'P2P o\'tkazmalar — ishlab chiqilmoqda'
      : 'P2P transfers — in development';
  String get p2pDescription => isUz
      ? 'OCTO integratsiyasi va kerakli ruxsatlar tayyorlanmoqda.'
      : 'OCTO integration and required approvals are being prepared.';
  String get success => isUz ? 'Muvaffaqiyatli' : 'Successful';
}
