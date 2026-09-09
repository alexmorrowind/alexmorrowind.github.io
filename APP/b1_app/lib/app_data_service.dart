import 'dart:math';

import 'package:flutter/material.dart';

import 'models.dart';

class AppDataService {
  const AppDataService();

  static const banks = [
    BankOffer(
      id: 1,
      name: 'National Bank of Uzbekistan (NBU)',
      type: OfferType.digital,
      apy: 18.5,
      minDeposit: 100000,
      fees: 0,
      rating: 4.9,
      features: ['Instant account', 'Free transfers', 'Cashback'],
      color: Color(0xFF2563EB),
      logo: 'BP',
    ),
    BankOffer(
      id: 2,
      name: 'Kapitalbank',
      type: OfferType.traditional,
      apy: 16.2,
      minDeposit: 500000,
      fees: 12000,
      rating: 4.7,
      features: ['Branches', 'Visa cards', 'Mobile app'],
      color: Color(0xFF059669),
      logo: 'KB',
    ),
    BankOffer(
      id: 3,
      name: 'Ipak Yuli Bank',
      type: OfferType.traditional,
      apy: 15.8,
      minDeposit: 300000,
      fees: 9000,
      rating: 4.6,
      features: ['Deposits', 'SME loans', 'Support'],
      color: Color(0xFFF59E0B),
      logo: 'IY',
    ),
    BankOffer(
      id: 4,
      name: 'TBC Uzbekistan',
      type: OfferType.digital,
      apy: 17.1,
      minDeposit: 0,
      fees: 0,
      rating: 4.8,
      features: ['Digital onboarding', 'No fees', 'Fast cards'],
      color: Color(0xFF06B6D4),
      logo: 'TB',
    ),
    BankOffer(
      id: 5,
      name: 'Asaka Bank',
      type: OfferType.international,
      apy: 14.4,
      minDeposit: 2000000,
      fees: 25000,
      rating: 4.5,
      features: ['FX support', 'Global access', 'Premium service'],
      color: Color(0xFFE11D48),
      logo: 'HS',
    ),
    BankOffer(id: 6, name: 'Ipoteka Bank', type: OfferType.traditional, apy: 15.3, minDeposit: 200000, fees: 8000, rating: 4.5, features: ['Mortgage', 'Deposits', 'Cards'], color: Color(0xFF0EA5E9), logo: 'IP'),
    BankOffer(id: 7, name: 'Qishloq Qurilish Bank', type: OfferType.traditional, apy: 14.9, minDeposit: 100000, fees: 7000, rating: 4.3, features: ['Rural finance', 'Loans', 'Savings'], color: Color(0xFF65A30D), logo: 'QQ'),
    BankOffer(id: 8, name: 'Agrobank', type: OfferType.traditional, apy: 15.7, minDeposit: 100000, fees: 6000, rating: 4.4, features: ['Agriculture', 'SME', 'Cards'], color: Color(0xFF16A34A), logo: 'AG'),
    BankOffer(id: 9, name: 'Xalq Banki', type: OfferType.traditional, apy: 15.1, minDeposit: 100000, fees: 6000, rating: 4.4, features: ['Retail', 'Pensions', 'Transfers'], color: Color(0xFF0284C7), logo: 'XB'),
    BankOffer(id: 10, name: 'Sanoat Qurilish Bank', type: OfferType.traditional, apy: 15.4, minDeposit: 250000, fees: 9000, rating: 4.4, features: ['Corporate', 'Construction', 'Loans'], color: Color(0xFF334155), logo: 'SQ'),
    BankOffer(id: 11, name: 'Hamkorbank', type: OfferType.traditional, apy: 16.1, minDeposit: 150000, fees: 7000, rating: 4.6, features: ['SME', 'Retail', 'Cards'], color: Color(0xFFEA580C), logo: 'HB'),
    BankOffer(id: 12, name: 'Orient Finans Bank', type: OfferType.traditional, apy: 15.6, minDeposit: 200000, fees: 9000, rating: 4.4, features: ['Deposits', 'Cards', 'FX'], color: Color(0xFF7C2D12), logo: 'OF'),
    BankOffer(id: 13, name: 'Davr Bank', type: OfferType.traditional, apy: 16.3, minDeposit: 150000, fees: 6000, rating: 4.5, features: ['Deposits', 'Retail', 'Mobile'], color: Color(0xFFBE123C), logo: 'DB'),
    BankOffer(id: 14, name: 'Anorbank', type: OfferType.digital, apy: 17.3, minDeposit: 0, fees: 0, rating: 4.8, features: ['Digital bank', 'No fees', 'Fast onboarding'], color: Color(0xFFDC2626), logo: 'AN'),
    BankOffer(id: 15, name: 'InfinBank', type: OfferType.traditional, apy: 15.9, minDeposit: 100000, fees: 8000, rating: 4.5, features: ['Cards', 'Transfers', 'SME'], color: Color(0xFF4F46E5), logo: 'IN'),
    BankOffer(id: 16, name: 'AloqaBank', type: OfferType.traditional, apy: 15.2, minDeposit: 100000, fees: 7000, rating: 4.4, features: ['Telecom', 'Cards', 'Payments'], color: Color(0xFF2563EB), logo: 'AL'),
    BankOffer(id: 17, name: 'Savdogarbank', type: OfferType.traditional, apy: 14.8, minDeposit: 100000, fees: 6000, rating: 4.2, features: ['Retail', 'Deposits', 'Transfers'], color: Color(0xFFCA8A04), logo: 'SB'),
    BankOffer(id: 18, name: 'Ziraat Bank Uzbekistan', type: OfferType.international, apy: 14.6, minDeposit: 300000, fees: 10000, rating: 4.4, features: ['International', 'FX', 'Corporate'], color: Color(0xFFDC2626), logo: 'ZI'),
    BankOffer(id: 19, name: 'Tenge Bank', type: OfferType.international, apy: 15.5, minDeposit: 200000, fees: 8000, rating: 4.5, features: ['International', 'Cards', 'Deposits'], color: Color(0xFF0284C7), logo: 'TE'),
    BankOffer(id: 20, name: 'Universalbank', type: OfferType.traditional, apy: 15.0, minDeposit: 100000, fees: 7000, rating: 4.3, features: ['Retail', 'Loans', 'Cards'], color: Color(0xFF0891B2), logo: 'UB'),
    BankOffer(id: 21, name: 'Mikrokreditbank', type: OfferType.traditional, apy: 15.6, minDeposit: 100000, fees: 6000, rating: 4.4, features: ['Microfinance', 'SME', 'Agriculture'], color: Color(0xFF059669), logo: 'MK'),
    BankOffer(id: 22, name: 'Trastbank', type: OfferType.traditional, apy: 15.7, minDeposit: 150000, fees: 7000, rating: 4.4, features: ['Deposits', 'Cards', 'FX'], color: Color(0xFF1D4ED8), logo: 'TR'),
    BankOffer(id: 23, name: 'Hi-Tech Bank', type: OfferType.digital, apy: 16.7, minDeposit: 0, fees: 0, rating: 4.6, features: ['Digital services', 'Cards', 'Transfers'], color: Color(0xFF9333EA), logo: 'HT'),
    BankOffer(id: 24, name: 'Muamalat Bank', type: OfferType.traditional, apy: 14.7, minDeposit: 100000, fees: 6000, rating: 4.3, features: ['Ethical finance', 'Cards', 'Deposits'], color: Color(0xFF047857), logo: 'MU'),
    BankOffer(id: 25, name: 'Asia Alliance Bank', type: OfferType.traditional, apy: 15.4, minDeposit: 150000, fees: 8000, rating: 4.4, features: ['Corporate', 'Retail', 'FX'], color: Color(0xFF7C3AED), logo: 'AA'),
    BankOffer(id: 26, name: 'Ravnaq Bank', type: OfferType.traditional, apy: 14.9, minDeposit: 100000, fees: 6000, rating: 4.2, features: ['Retail', 'Loans', 'Transfers'], color: Color(0xFF0F766E), logo: 'RB'),
    BankOffer(id: 27, name: 'Madad Invest Bank', type: OfferType.traditional, apy: 15.1, minDeposit: 100000, fees: 6000, rating: 4.2, features: ['Investments', 'Deposits', 'Cards'], color: Color(0xFFB45309), logo: 'MI'),
    BankOffer(id: 28, name: 'Kredit Standart Bank', type: OfferType.traditional, apy: 15.0, minDeposit: 100000, fees: 6000, rating: 4.2, features: ['Credit', 'Cards', 'Deposits'], color: Color(0xFFE11D48), logo: 'KS'),
  ];

  static const cards = [
    CardOffer(
      id: 1,
      name: 'Platinum Rewards',
      bank: 'BPay Digital',
      annualFee: 0,
      cashback: 5,
      limit: 'Up to 120M UZS',
      benefits: ['5% cashback', 'Airport lounge', 'Free FX transfers'],
      color: Color(0xFF2563EB),
      icon: Icons.workspace_premium,
    ),
    CardOffer(
      id: 2,
      name: 'Gold Everyday',
      bank: 'Kapitalbank',
      annualFee: 180000,
      cashback: 3,
      limit: 'Up to 60M UZS',
      benefits: ['Grocery cashback', 'Installments', 'Family cards'],
      color: Color(0xFFF59E0B),
      icon: Icons.credit_card,
    ),
    CardOffer(
      id: 3,
      name: 'Travel Infinite',
      bank: 'HSBC Premier',
      annualFee: 480000,
      cashback: 4,
      limit: 'Custom limit',
      benefits: ['Travel insurance', 'Concierge', 'FX discounts'],
      color: Color(0xFF7C3AED),
      icon: Icons.flight_takeoff,
    ),
  ];

  static const loans = [
    LoanOffer(
      id: 1,
      name: 'Personal Flex Loan',
      type: LoanType.personal,
      bank: 'BPay Digital',
      rate: 20,
      minAmount: 5000000,
      maxAmount: 150000000,
      term: '6-48 months',
      monthlyPayment: 3900000,
      requirements: ['Passport', 'Income proof', 'Bank statement'],
      icon: Icons.person,
    ),
    LoanOffer(
      id: 2,
      name: 'Auto Loan',
      type: LoanType.auto,
      bank: 'Kapitalbank',
      rate: 16,
      minAmount: 30000000,
      maxAmount: 450000000,
      term: '12-72 months',
      monthlyPayment: 7200000,
      requirements: ['Passport', 'Vehicle invoice', 'Down payment'],
      icon: Icons.directions_car,
    ),
    LoanOffer(
      id: 3,
      name: 'Mortgage Plus',
      type: LoanType.mortgage,
      bank: 'Ipak Yuli Bank',
      rate: 13,
      minAmount: 100000000,
      maxAmount: 1200000000,
      term: '5-20 years',
      monthlyPayment: 9400000,
      requirements: ['Passport', 'Property docs', 'Income proof'],
      icon: Icons.home_work,
    ),
    LoanOffer(
      id: 4,
      name: 'Business Growth',
      type: LoanType.business,
      bank: 'TBC Uzbekistan',
      rate: 18,
      minAmount: 50000000,
      maxAmount: 800000000,
      term: '12-60 months',
      monthlyPayment: 11800000,
      requirements: ['Registration', 'Cashflow report', 'Tax statement'],
      icon: Icons.business_center,
    ),
  ];

  static const investors = [
    InvestorOffer(
      id: 1,
      name: 'Silk Road Ventures',
      domain: InvestorDomain.tech,
      minInvestment: 1000,
      maxInvestment: 50000,
      roi: 18.4,
      projects: 24,
      description: 'Fintech, SaaS, and marketplace seed investments.',
      icon: Icons.memory,
    ),
    InvestorOffer(
      id: 2,
      name: 'Tashkent Property Fund',
      domain: InvestorDomain.realEstate,
      minInvestment: 5000,
      maxInvestment: 250000,
      roi: 14.2,
      projects: 11,
      description: 'Commercial and residential real-estate opportunities.',
      icon: Icons.apartment,
    ),
    InvestorOffer(
      id: 3,
      name: 'Agro Future Capital',
      domain: InvestorDomain.agriculture,
      minInvestment: 2500,
      maxInvestment: 90000,
      roi: 16.8,
      projects: 18,
      description: 'Modern agriculture, logistics, and processing projects.',
      icon: Icons.agriculture,
    ),
  ];

  static const notifications = [
    NotificationItem(
      id: 1,
      title: 'Transfer completed',
      body: 'Your payment to card ending 4829 was processed.',
      time: '2 min',
      unread: true,
      color: Color(0xFF10B981),
      icon: Icons.check_circle,
    ),
    NotificationItem(
      id: 2,
      title: 'New card offer',
      body: 'Platinum Rewards is available with first-year free service.',
      time: '1 h',
      unread: true,
      color: Color(0xFF2563EB),
      icon: Icons.credit_card,
    ),
    NotificationItem(
      id: 3,
      title: 'Loan rate update',
      body: 'Auto loan rates dropped by 1.2% this week.',
      time: 'Today',
      unread: false,
      color: Color(0xFFF59E0B),
      icon: Icons.trending_down,
    ),
  ];

  static const startups = [
    StartupListing(
      id: 'st_001',
      ownerUserId: 'user_legal_demo',
      name: 'AgroSense AI',
      category: 'AgriTech',
      logoUrl: '',
      description: 'IoT monitoring and AI yield forecasting for farms.',
      investmentGoal: 800000000,
      raisedAmount: 320000000,
      businessModel: 'Hardware subscription plus analytics SaaS.',
      financialInfo: 'MRR 42M UZS, gross margin 54%, 18-month runway.',
      status: StartupStatus.approved,
      investorsCount: 38,
    ),
    StartupListing(
      id: 'st_002',
      ownerUserId: 'user_legal_demo',
      name: 'PayRoute',
      category: 'FinTech',
      logoUrl: '',
      description: 'Merchant routing for cards, wallets, and QR payments.',
      investmentGoal: 1200000000,
      raisedAmount: 510000000,
      businessModel: 'Transaction fee and premium analytics.',
      financialInfo: 'GMV 9.4B UZS, take rate 0.8%, MoM growth 21%.',
      status: StartupStatus.pendingApproval,
      investorsCount: 64,
    ),
  ];

  static final investments = [
    InvestmentRecord(
      id: 'inv_001',
      userId: 'user_demo',
      startupId: 'st_001',
      amount: 5000000,
      status: InvestmentStatus.active,
      createdAt: DateTime(2026, 6, 1),
    ),
  ];

  static const adminStats = AdminStats(
    users: 1248,
    startups: 42,
    investments: 316,
    banks: 28,
    pendingApprovals: 7,
  );

  List<BankOffer> searchBanks(String query) {
    final q = query.toLowerCase();
    return banks
        .where((bank) =>
            bank.name.toLowerCase().contains(q) ||
            bank.features.any((feature) => feature.toLowerCase().contains(q)))
        .toList();
  }

  List<CardOffer> searchCards(String query) {
    final q = query.toLowerCase();
    return cards
        .where((card) =>
            card.name.toLowerCase().contains(q) ||
            card.bank.toLowerCase().contains(q) ||
            card.benefits.any((benefit) => benefit.toLowerCase().contains(q)))
        .toList();
  }

  List<LoanOffer> searchLoans(String query) {
    final q = query.toLowerCase();
    return loans
        .where((loan) =>
            loan.name.toLowerCase().contains(q) ||
            loan.bank.toLowerCase().contains(q) ||
            loan.term.toLowerCase().contains(q))
        .toList();
  }

  List<InvestorOffer> searchInvestors(String query) {
    final q = query.toLowerCase();
    return investors
        .where((investor) =>
            investor.name.toLowerCase().contains(q) ||
            investor.description.toLowerCase().contains(q) ||
            investor.domain.name.toLowerCase().contains(q))
        .toList();
  }

  List<BankOffer> filterBanks(OfferType? type) =>
      type == null ? banks : banks.where((bank) => bank.type == type).toList();

  List<LoanOffer> filterLoans(LoanType? type) =>
      type == null ? loans : loans.where((loan) => loan.type == type).toList();

  List<InvestorOffer> filterInvestors(InvestorDomain? domain) => domain == null
      ? investors
      : investors.where((investor) => investor.domain == domain).toList();

  List<StartupListing> searchStartups(String query, {String? category}) {
    final q = query.toLowerCase();
    return startups
        .where((startup) =>
            (category == null || startup.category == category) &&
            (startup.name.toLowerCase().contains(q) ||
                startup.description.toLowerCase().contains(q) ||
                startup.category.toLowerCase().contains(q)))
        .toList();
  }

  static double calculateMonthlyPayment({
    required double principal,
    required double annualRate,
    required int months,
  }) {
    if (months <= 0) return 0;
    final monthlyRate = annualRate / 100 / 12;
    if (monthlyRate == 0) return principal / months;
    final factor = pow(1 + monthlyRate, months);
    return principal * monthlyRate * factor / (factor - 1);
  }
}
