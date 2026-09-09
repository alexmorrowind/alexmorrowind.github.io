import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class B1ApiClient {
  B1ApiClient({http.Client? httpClient, String? baseUrl})
      : _http = httpClient ?? http.Client(),
        baseUrl = _normalizeBaseUrl(
          baseUrl ??
              const String.fromEnvironment(
                'B1_API_BASE_URL',
                defaultValue: 'https://api.b1pay.uz/api',
              ),
        );

  final http.Client _http;
  final String baseUrl;
  String? _accessToken;
  String? _refreshToken;

  bool get isAuthenticated => _accessToken != null;

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.endsWith('/')) return trimmed.substring(0, trimmed.length - 1);
    return trimmed;
  }

  Uri _uri(String path) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalized');
  }

  Future<dynamic> getJson(String path, {bool auth = true}) {
    return _request('GET', path, auth: auth);
  }

  Future<List<NewsArticle>> fetchNews({String language = 'ru', int limit = 6}) async {
    final data = await getJson(
      '/news/?lang=${Uri.encodeQueryComponent(language)}&limit=$limit',
      auth: false,
    ) as List<dynamic>;
    return data.map((item) {
      final row = Map<String, dynamic>.from(item as Map);
      return NewsArticle(
        id: int.tryParse('${row['id']}') ?? 0,
        title: '${row['display_title'] ?? row['title'] ?? ''}',
        excerpt: '${row['display_excerpt'] ?? row['excerpt'] ?? ''}',
        category: '${row['category_label'] ?? row['category'] ?? ''}',
        sourceName: '${row['source_name'] ?? ''}',
        sourceUrl: '${row['source_url'] ?? ''}',
        publishedAt: DateTime.tryParse('${row['published_at'] ?? ''}'),
        imageUrl: '${row['image_url'] ?? ''}',
      );
    }).toList();
  }

  Future<dynamic> postJson(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) {
    return _request('POST', path, body: body, auth: auth);
  }

  Future<WebLoginSession> startWebLoginSession() async {
    final data = await postJson('/auth/qr/start/', {}, auth: false) as Map<String, dynamic>;
    return WebLoginSession.fromJson(data);
  }

  Future<WebLoginSession> fetchWebLoginSession(String sessionId) async {
    final data = await postJson(
      '/auth/qr/status/',
      {'session_id': sessionId},
      auth: false,
    ) as Map<String, dynamic>;
    return WebLoginSession.fromJson(data);
  }

  Future<MyIdStartSession> startMobileMyIdSession({
    required String phone,
    String? email,
    AccountType accountType = AccountType.physical,
  }) async {
    final data = await postJson(
      '/auth/myid/mobile/start/',
      {
        'phone': phone,
        'email': email ?? '',
        'account_type': accountType.name,
      },
      auth: false,
    ) as Map<String, dynamic>;
    return MyIdStartSession.fromJson(data);
  }

  Future<MyIdCompletion> completeMobileMyIdSession({
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
    final data = await postJson(
      '/auth/myid/mobile/complete/',
      {
        'session_id': sessionId,
        'phone': phone,
        'email': email ?? '',
        'first_name': firstName ?? '',
        'last_name': lastName ?? '',
        'passport': passport ?? '',
        'birth_date': birthDate ?? '',
        'qr_session_id': qrSessionId ?? '',
        'result_code': resultCode,
        'verified': verified,
        'myid_payload': myIdPayload ?? {},
      },
      auth: false,
    ) as Map<String, dynamic>;
    final profileData = Map<String, dynamic>.from(data['profile'] as Map? ?? {});
    if (profileData.isEmpty) {
      profileData.addAll({
        'phone': phone,
        'first_name': firstName ?? '',
        'last_name': lastName ?? '',
        // Do not manufacture a verified profile on a malformed/partial
        // backend response. AuthController validates the status and token
        // before making the app session authenticated.
        'myid_status': data['status']?.toString() ?? 'failed',
      });
    }
    final profile = _profileFromJson(
      profileData,
      preferredPhone: phone,
      preferredType: AccountType.physical,
    );
    return MyIdCompletion(
      sessionId: data['session_id']?.toString() ?? sessionId,
      status: data['status']?.toString() ?? 'verified',
      tokens: Map<String, dynamic>.from(data['tokens'] as Map? ?? {}),
      profile: profile,
      qrSessionId: data['qr_session_id']?.toString() ?? (qrSessionId ?? ''),
      raw: data,
      error: data['error']?.toString(),
    );
  }

  Future<dynamic> putJson(String path, Map<String, dynamic> body) {
    return _request('PUT', path, body: body);
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
    bool retry = true,
  }) async {
    final request = http.Request(method, _uri(path));
    request.headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    if (auth && _accessToken != null) {
      request.headers['Authorization'] = 'Bearer $_accessToken';
    }

    final streamed = await _http.send(request).timeout(const Duration(seconds: 20));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 401 && retry && _refreshToken != null) {
      await _refreshAccessToken();
      return _request(method, path, body: body, auth: auth, retry: false);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(_extractError(response));
    }
    if (response.body.trim().isEmpty) return <String, dynamic>{};
    return jsonDecode(response.body);
  }

  Future<void> _refreshAccessToken() async {
    final refresh = _refreshToken;
    if (refresh == null) throw StateError('Session expired');

    final response = await _http
        .post(
          _uri('/auth/token/refresh/'),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'refresh': refresh}),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _accessToken = null;
      _refreshToken = null;
      throw StateError('Session expired');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _accessToken = data['access']?.toString();
  }

  void _applyTokens(Map<String, dynamic> data) {
    _accessToken = data['access']?.toString();
    _refreshToken = data['refresh']?.toString();
  }

  Future<UserProfile> login({
    required String phone,
    required String password,
  }) async {
    final data = await postJson(
      '/auth/login/',
      {'username': _loginIdentifier(phone), 'password': password},
      auth: false,
    ) as Map<String, dynamic>;
    _applyTokens(data);
    return fetchProfile(preferredPhone: phone);
  }

  Future<UserProfile> register({
    required String phone,
    required String password,
    required AccountType accountType,
    BusinessQuestionnaire? business,
  }) async {
    try {
      final data = await postJson(
        '/auth/register/',
        {
          'email': _loginIdentifier(phone),
          'password': password,
          'phone': phone,
          'first_name': business?.companyName ?? '',
          'last_name': '',
          'payme_connect': false,
        },
        auth: false,
      ) as Map<String, dynamic>;
      _applyTokens(Map<String, dynamic>.from(data['tokens'] as Map));
    } on StateError catch (error) {
      final message = error.message.toLowerCase();
      if (message.contains('уже') ||
          message.contains('already') ||
          message.contains('account')) {
        return login(phone: phone, password: password);
      }
      rethrow;
    }

    if (accountType == AccountType.legal && business != null) {
      await upsertLegalProfile(business);
    }
    return fetchProfile(
      preferredPhone: phone,
      preferredType: accountType,
      preferredBusiness: business,
    );
  }

  Future<UserProfile> fetchProfile({
    String? preferredPhone,
    AccountType preferredType = AccountType.physical,
    BusinessQuestionnaire? preferredBusiness,
  }) async {
    final profile = await getJson('/user/profile/') as Map<String, dynamic>;
    final legalProfile = await _tryGetLegalProfile();
    return _profileFromJson(
      profile,
      preferredPhone: preferredPhone,
      preferredType: legalProfile == null ? preferredType : AccountType.legal,
      preferredBusiness: _businessFromLegalProfile(legalProfile) ?? preferredBusiness,
    );
  }

  Future<void> saveProfile(UserProfile profile) async {
    if (!isAuthenticated) return;
    await putJson('/user/profile/', {
      'phone': profile.phone,
      'first_name': profile.identity?.firstName ?? '',
      'last_name': profile.identity?.lastName ?? '',
    });
  }

  Future<void> upsertLegalProfile(BusinessQuestionnaire business) async {
    await postJson('/legal-entity/profile/', {
      'company_name': business.companyName,
      'legal_form': business.businessType,
      'contact_email': business.contactInfo,
      'accepted_terms': true,
      'accepted_investment_risk': true,
      'company_docs': [
        {'name': 'mobile-registration', 'status': 'pending_upload'}
      ],
    });
  }

  Future<List<StartupListing>> fetchStartups() async {
    final data = await getJson('/startups/') as List<dynamic>;
    return data
        .map((item) => _startupFromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<StartupListing> createStartup({
    required String name,
    required String category,
    required String description,
    required int goal,
    required String businessModel,
    required String financialInfo,
  }) async {
    final data = await postJson('/startups/', {
      'name': name,
      'domain': category,
      'stage': 'mvp',
      'funding_goal': goal,
      'min_investment': 1000000,
      'roi': 18,
      'description': '$description\n\n$businessModel\n$financialInfo',
    }) as Map<String, dynamic>;
    return _startupFromJson(data);
  }

  Future<void> createInvestment({
    required String startupId,
    required int amount,
  }) async {
    final numericId = int.tryParse(startupId);
    if (numericId == null) {
      throw StateError('This startup is local demo data');
    }
    await postJson('/investments/', {'startup': numericId, 'amount': amount});
  }

  Future<Map<String, dynamic>?> _tryGetLegalProfile() async {
    try {
      return await getJson('/legal-entity/profile/') as Map<String, dynamic>;
    } on StateError {
      return null;
    }
  }

  String _extractError(http.Response response) {
    try {
      final parsed = jsonDecode(response.body);
      if (parsed is Map<String, dynamic>) {
        final detail = parsed['detail'];
        if (detail != null) return detail.toString();
        final nonField = parsed['non_field_errors'];
        if (nonField is List && nonField.isNotEmpty) return nonField.first.toString();
        if (parsed.isNotEmpty) {
          final first = parsed.values.first;
          if (first is List && first.isNotEmpty) return first.first.toString();
          return first.toString();
        }
      }
    } catch (_) {
      // Fall through to HTTP status below.
    }
    return 'Server error ${response.statusCode}';
  }

  String _loginIdentifier(String phoneOrEmail) {
    if (phoneOrEmail.contains('@')) return phoneOrEmail.trim().toLowerCase();
    final digits = phoneOrEmail.replaceAll(RegExp(r'\D'), '');
    return '$digits@phone.b1.local';
  }

  UserProfile _profileFromJson(
    Map<String, dynamic> data, {
    String? preferredPhone,
    AccountType preferredType = AccountType.physical,
    BusinessQuestionnaire? preferredBusiness,
  }) {
    final firstName = data['first_name']?.toString() ?? '';
    final lastName = data['last_name']?.toString() ?? '';
    final phone = (data['phone']?.toString().isNotEmpty ?? false)
        ? data['phone'].toString()
        : (preferredPhone ?? '');
    final birthDate = DateTime.tryParse(data['birth_date']?.toString() ?? '') ??
        DateTime(1994, 4, 12);
    final myIdStatus = _myIdStatus(data['myid_status']);

    return UserProfile(
      id: data['id']?.toString() ?? phone,
      phone: phone,
      accountType: preferredType,
      myIdStatus: myIdStatus,
      verificationStatus: myIdStatus == MyIdStatus.verified ? 'verified' : 'server_saved',
      identity: IdentityData(
        firstName: firstName.isNotEmpty ? firstName : 'BPay',
        lastName: lastName.isNotEmpty ? lastName : 'User',
        middleName: '',
        birthDate: birthDate,
        gender: '',
        verifiedPhone: phone,
        pinfl: data['passport']?.toString() ?? '',
      ),
      business: preferredBusiness,
    );
  }

  BusinessQuestionnaire? _businessFromLegalProfile(Map<String, dynamic>? data) {
    if (data == null) return null;
    return BusinessQuestionnaire(
      companyName: data['company_name']?.toString() ?? 'Company',
      industry: data['legal_form']?.toString() ?? 'FinTech',
      businessType: data['legal_form']?.toString() ?? 'MCHJ',
      startupDescription: data['status']?.toString() ?? '',
      contactInfo: data['contact_email']?.toString() ?? '',
    );
  }

  StartupListing _startupFromJson(Map<String, dynamic> data) {
    final goal = _intValue(data['funding_goal']);
    final raised = _intValue(data['amount_raised']);
    return StartupListing(
      id: data['id']?.toString() ?? 'server-${DateTime.now().millisecondsSinceEpoch}',
      ownerUserId: data['owner_email']?.toString() ?? '',
      name: data['name']?.toString() ?? 'Startup',
      category: data['domain']?.toString() ?? 'startup',
      logoUrl: '',
      description: data['description']?.toString() ?? '',
      investmentGoal: goal,
      raisedAmount: raised,
      businessModel: data['company_name']?.toString() ?? '',
      financialInfo: '${raised.toString()} / ${goal.toString()} UZS',
      status: _startupStatus(data['status']),
      investorsCount: 0,
    );
  }

  int _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return double.tryParse(value?.toString() ?? '')?.round() ?? 0;
  }

  MyIdStatus _myIdStatus(dynamic value) {
    switch (value?.toString()) {
      case 'verified':
      case 'demo_verified':
        return MyIdStatus.verified;
      case 'pending':
        return MyIdStatus.pending;
      case 'failed':
        return MyIdStatus.failed;
      default:
        return MyIdStatus.notStarted;
    }
  }

  StartupStatus _startupStatus(dynamic value) {
    switch (value?.toString()) {
      case 'active':
        return StartupStatus.approved;
      case 'draft':
        return StartupStatus.draft;
      case 'closed':
      case 'rejected':
        return StartupStatus.rejected;
      default:
        return StartupStatus.pendingApproval;
    }
  }
}

abstract class MyIdVerificationGateway {
  Future<Uri> createVerificationSession({
    required String phone,
    required AccountType accountType,
  });

  Future<IdentityData> completeVerification({
    required Uri callbackUri,
    required String phone,
  });
}

abstract class PaymentGateway {
  Future<String> sendCardOtp({
    required String cardNumber,
    required String expiry,
    required String phone,
  });

  Future<ConnectedCard> verifyCardOtp({
    required String sessionId,
    required String otp,
    required String cardNumber,
  });
}

abstract class UserRepository {
  Future<UserProfile> register({
    required String phone,
    required String password,
    required AccountType accountType,
    BusinessQuestionnaire? business,
  });

  Future<UserProfile> login({
    required String phone,
    required String password,
  });

  Future<void> saveUserProfile(UserProfile profile);
  Future<UserProfile?> findByPhone(String phone);
}

class B1DjangoUserRepository implements UserRepository {
  B1DjangoUserRepository(this.api);

  final B1ApiClient api;

  @override
  Future<UserProfile> register({
    required String phone,
    required String password,
    required AccountType accountType,
    BusinessQuestionnaire? business,
  }) {
    return api.register(
      phone: phone,
      password: password,
      accountType: accountType,
      business: business,
    );
  }

  @override
  Future<UserProfile> login({
    required String phone,
    required String password,
  }) {
    return api.login(phone: phone, password: password);
  }

  @override
  Future<UserProfile?> findByPhone(String phone) async {
    if (!api.isAuthenticated) return null;
    return api.fetchProfile(preferredPhone: phone);
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) {
    return api.saveProfile(profile);
  }
}

class B1PaymePaymentGateway implements PaymentGateway {
  B1PaymePaymentGateway(this.api);

  final B1ApiClient api;

  @override
  Future<String> sendCardOtp({
    required String cardNumber,
    required String expiry,
    required String phone,
  }) async {
    final number = cardNumber.replaceAll(RegExp(r'\D'), '');
    final expire = expiry.replaceAll(RegExp(r'\D'), '');
    if (number.length < 16 || expire.length != 4) {
      throw StateError('Enter card number and expiry in MM/YY format');
    }
    final create = await api.postJson('/payme/subscribe/cards/create/', {
      'number': number,
      'expire': expire,
      'phone': phone,
    }) as Map<String, dynamic>;
    final result = Map<String, dynamic>.from(create['result'] as Map? ?? {});
    final card = Map<String, dynamic>.from(result['card'] as Map? ?? {});
    final token = card['token']?.toString();
    if (token == null || token.isEmpty) {
      throw StateError('Payme did not return a card token');
    }
    await api.postJson('/payme/subscribe/cards/code/', {'token': token});
    return base64Url.encode(
      utf8.encode(jsonEncode({'token': token, 'number': number, 'expire': expire})),
    );
  }

  @override
  Future<ConnectedCard> verifyCardOtp({
    required String sessionId,
    required String otp,
    required String cardNumber,
  }) async {
    final raw = utf8.decode(base64Url.decode(base64Url.normalize(sessionId)));
    final session = jsonDecode(raw) as Map<String, dynamic>;
    final response = await api.postJson('/payme/subscribe/cards/verify/', {
      'token': session['token'],
      'code': otp,
      'number': session['number'],
      'expire': session['expire'],
      'name': 'Payme',
    }) as Map<String, dynamic>;
    final card = Map<String, dynamic>.from(response['card'] as Map? ?? {});
    final number = card['number']?.toString() ?? _mask(cardNumber);
    final expire = card['expiry']?.toString() ?? session['expire']?.toString() ?? '';
    return ConnectedCard(
      id: card['id']?.toString() ?? session['token'].toString(),
      cardName: card['name']?.toString() ?? 'Payme',
      maskedNumber: number,
      bankName: 'Payme',
      expiryDate: _formatExpire(expire),
      ownerVerified: card['payme_verified'] == true,
    );
  }

  String _formatExpire(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 4) return '${digits.substring(0, 2)}/${digits.substring(2)}';
    return value;
  }

  String _mask(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return '****';
    return '**** **** **** ${digits.substring(digits.length - 4)}';
  }
}

class MockMyIdVerificationGateway implements MyIdVerificationGateway {
  const MockMyIdVerificationGateway();

  @override
  Future<Uri> createVerificationSession({
    required String phone,
    required AccountType accountType,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return Uri.parse(
      'https://staging.myid.uz/mock/verify?phone=$phone&type=${accountType.name}',
    );
  }

  @override
  Future<IdentityData> completeVerification({
    required Uri callbackUri,
    required String phone,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 550));
    return IdentityData(
      firstName: 'Anvar',
      lastName: 'Karimov',
      middleName: 'Akmalovich',
      birthDate: DateTime(1994, 4, 12),
      gender: 'male',
      verifiedPhone: phone,
      pinfl: '',
    );
  }
}

class MockPaymentGateway implements PaymentGateway {
  const MockPaymentGateway();

  @override
  Future<String> sendCardOtp({
    required String cardNumber,
    required String expiry,
    required String phone,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return 'mock-payme-session-${cardNumber.substring(cardNumber.length - 4)}';
  }

  @override
  Future<ConnectedCard> verifyCardOtp({
    required String sessionId,
    required String otp,
    required String cardNumber,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (otp != '111111') {
      throw StateError('Invalid OTP. Use 111111 in staging mode.');
    }
    final last4 = cardNumber.substring(cardNumber.length - 4);
    return ConnectedCard(
      id: sessionId,
      cardName: 'BPay Verified Card',
      maskedNumber: '**** **** **** $last4',
      bankName: _detectBank(cardNumber),
      expiryDate: '12/28',
      ownerVerified: true,
    );
  }

  String _detectBank(String cardNumber) {
    if (cardNumber.startsWith('9860')) return 'Kapitalbank';
    if (cardNumber.startsWith('8600')) return 'Uzcard Partner Bank';
    if (cardNumber.startsWith('5614')) return 'Humo Partner Bank';
    return 'Partner Bank';
  }
}

class InMemoryUserRepository implements UserRepository {
  final Map<String, UserProfile> _users = {};

  @override
  Future<UserProfile> register({
    required String phone,
    required String password,
    required AccountType accountType,
    BusinessQuestionnaire? business,
  }) async {
    final profile = UserProfile(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      phone: phone,
      accountType: accountType,
      myIdStatus: MyIdStatus.verified,
      verificationStatus: 'verified',
      identity: IdentityData(
        firstName: accountType == AccountType.legal ? 'Madina' : 'Anvar',
        lastName: accountType == AccountType.legal ? 'Saidova' : 'Karimov',
        middleName: accountType == AccountType.legal ? 'Rustamovna' : 'Akmalovich',
        birthDate: DateTime(1994, 4, 12),
        gender: accountType == AccountType.legal ? 'female' : 'male',
        verifiedPhone: phone,
        pinfl: '',
      ),
      business: business,
    );
    await saveUserProfile(profile);
    return profile;
  }

  @override
  Future<UserProfile> login({
    required String phone,
    required String password,
  }) async {
    return _users[phone] ??
        UserProfile(
          id: 'user_demo',
          phone: phone,
          accountType: AccountType.physical,
          myIdStatus: MyIdStatus.verified,
          verificationStatus: 'verified',
          identity: IdentityData(
            firstName: 'Anvar',
            lastName: 'Karimov',
            middleName: 'Akmalovich',
            birthDate: DateTime(1994, 4, 12),
            gender: 'male',
            verifiedPhone: phone,
            pinfl: '',
          ),
        );
  }

  @override
  Future<UserProfile?> findByPhone(String phone) async => _users[phone];

  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    _users[profile.phone] = profile;
  }
}

class WebLoginSession {
  const WebLoginSession({
    required this.sessionId,
    required this.status,
    required this.expiresAt,
    required this.qrPayload,
    required this.qrImage,
    this.tokens,
    this.profile,
    this.lastError,
  });

  factory WebLoginSession.fromJson(Map<String, dynamic> json) {
    return WebLoginSession(
      sessionId: json['session_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? '') ?? DateTime.now(),
      qrPayload: json['qr_payload']?.toString() ?? '',
      qrImage: json['qr_image']?.toString() ?? '',
      tokens: json['tokens'] is Map ? Map<String, dynamic>.from(json['tokens'] as Map) : null,
      profile: json['profile'] is Map ? Map<String, dynamic>.from(json['profile'] as Map) : null,
      lastError: json['last_error']?.toString(),
    );
  }

  final String sessionId;
  final String status;
  final DateTime expiresAt;
  final String qrPayload;
  final String qrImage;
  final Map<String, dynamic>? tokens;
  final Map<String, dynamic>? profile;
  final String? lastError;

  bool get isVerified => status == 'verified' && tokens != null;
}

class MyIdStartSession {
  const MyIdStartSession({
    required this.sessionId,
    required this.phone,
    required this.email,
    required this.accountType,
    required this.clientId,
    required this.clientHash,
    required this.clientHashId,
    required this.environment,
    required this.entryType,
    required this.status,
    required this.expiresAt,
    required this.demo,
  });

  factory MyIdStartSession.fromJson(Map<String, dynamic> json) {
    return MyIdStartSession(
      sessionId: json['session_id']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      accountType: json['account_type']?.toString() ?? 'physical',
      clientId: json['client_id']?.toString() ?? '',
      clientHash: json['client_hash']?.toString() ?? '',
      clientHashId: json['client_hash_id']?.toString() ?? '',
      environment: json['environment']?.toString() ?? 'demo',
      entryType: json['entry_type']?.toString() ?? 'IDENTIFICATION',
      status: json['status']?.toString() ?? 'pending',
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? '') ?? DateTime.now(),
      demo: json['demo'] == true,
    );
  }

  final String sessionId;
  final String phone;
  final String email;
  final String accountType;
  final String clientId;
  final String clientHash;
  final String clientHashId;
  final String environment;
  final String entryType;
  final String status;
  final DateTime expiresAt;
  final bool demo;

  bool get readyForSdk => sessionId.isNotEmpty && clientHash.isNotEmpty && clientHashId.isNotEmpty;

  bool get isExpired => !expiresAt.isAfter(DateTime.now());
}

class MyIdCompletion {
  const MyIdCompletion({
    required this.sessionId,
    required this.status,
    required this.tokens,
    required this.profile,
    required this.qrSessionId,
    required this.raw,
    this.error,
  });

  final String sessionId;
  final String status;
  final Map<String, dynamic> tokens;
  final UserProfile profile;
  final String qrSessionId;
  final Map<String, dynamic> raw;
  final String? error;

  bool get isVerified {
    final accessToken = tokens['access']?.toString().trim() ?? '';
    return status.trim().toLowerCase() == 'verified' && accessToken.isNotEmpty;
  }
}
