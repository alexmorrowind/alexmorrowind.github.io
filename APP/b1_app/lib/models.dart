import 'package:flutter/material.dart';

enum OfferType { digital, traditional, international }

enum LoanType { personal, auto, mortgage, business }

enum InvestorDomain { tech, realEstate, startup, agriculture }

enum AccountType { physical, legal }

enum MyIdStatus { notStarted, pending, verified, failed }

enum StartupStatus { draft, pendingApproval, approved, rejected }

enum InvestmentStatus { pending, active, exited }

class IdentityData {
  const IdentityData({
    required this.firstName,
    required this.lastName,
    required this.middleName,
    required this.birthDate,
    required this.gender,
    required this.verifiedPhone,
    required this.pinfl,
  });

  final String firstName;
  final String lastName;
  final String middleName;
  final DateTime birthDate;
  final String gender;
  final String verifiedPhone;
  final String pinfl;

  String get fullName => '$lastName $firstName $middleName';
}

class BusinessQuestionnaire {
  const BusinessQuestionnaire({
    required this.companyName,
    required this.industry,
    required this.businessType,
    required this.startupDescription,
    required this.contactInfo,
  });

  final String companyName;
  final String industry;
  final String businessType;
  final String startupDescription;
  final String contactInfo;
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.phone,
    required this.accountType,
    required this.myIdStatus,
    required this.verificationStatus,
    this.identity,
    this.business,
  });

  final String id;
  final String phone;
  final AccountType accountType;
  final MyIdStatus myIdStatus;
  final String verificationStatus;
  final IdentityData? identity;
  final BusinessQuestionnaire? business;

  String get fullName => identity?.fullName ?? phone;
  bool get isMyIdVerified => myIdStatus == MyIdStatus.verified;
  bool get canCreateStartups => accountType == AccountType.legal;
  bool get canInvest => accountType == AccountType.physical;
}

class ConnectedCard {
  const ConnectedCard({
    required this.id,
    required this.cardName,
    required this.maskedNumber,
    required this.bankName,
    required this.expiryDate,
    required this.ownerVerified,
  });

  final String id;
  final String cardName;
  final String maskedNumber;
  final String bankName;
  final String expiryDate;
  final bool ownerVerified;
}

class StartupListing {
  const StartupListing({
    required this.id,
    required this.ownerUserId,
    required this.name,
    required this.category,
    required this.logoUrl,
    required this.description,
    required this.investmentGoal,
    required this.raisedAmount,
    required this.businessModel,
    required this.financialInfo,
    required this.status,
    required this.investorsCount,
  });

  final String id;
  final String ownerUserId;
  final String name;
  final String category;
  final String logoUrl;
  final String description;
  final int investmentGoal;
  final int raisedAmount;
  final String businessModel;
  final String financialInfo;
  final StartupStatus status;
  final int investorsCount;
}

class InvestmentRecord {
  const InvestmentRecord({
    required this.id,
    required this.userId,
    required this.startupId,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String startupId;
  final int amount;
  final InvestmentStatus status;
  final DateTime createdAt;
}

class AdminStats {
  const AdminStats({
    required this.users,
    required this.startups,
    required this.investments,
    required this.banks,
    required this.pendingApprovals,
  });

  final int users;
  final int startups;
  final int investments;
  final int banks;
  final int pendingApprovals;
}

class BankOffer {
  const BankOffer({
    required this.id,
    required this.name,
    required this.type,
    required this.apy,
    required this.minDeposit,
    required this.fees,
    required this.rating,
    required this.features,
    required this.color,
    required this.logo,
  });

  final int id;
  final String name;
  final OfferType type;
  final double apy;
  final int minDeposit;
  final int fees;
  final double rating;
  final List<String> features;
  final Color color;
  final String logo;
}

class NewsArticle {
  const NewsArticle({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.category,
    required this.sourceName,
    required this.sourceUrl,
    required this.publishedAt,
    required this.imageUrl,
  });

  final int id;
  final String title;
  final String excerpt;
  final String category;
  final String sourceName;
  final String sourceUrl;
  final DateTime? publishedAt;
  final String imageUrl;
}

class CardOffer {
  const CardOffer({
    required this.id,
    required this.name,
    required this.bank,
    required this.annualFee,
    required this.cashback,
    required this.limit,
    required this.benefits,
    required this.color,
    required this.icon,
  });

  final int id;
  final String name;
  final String bank;
  final int annualFee;
  final double cashback;
  final String limit;
  final List<String> benefits;
  final Color color;
  final IconData icon;
}

class LoanOffer {
  const LoanOffer({
    required this.id,
    required this.name,
    required this.type,
    required this.bank,
    required this.rate,
    required this.minAmount,
    required this.maxAmount,
    required this.term,
    required this.monthlyPayment,
    required this.requirements,
    required this.icon,
  });

  final int id;
  final String name;
  final LoanType type;
  final String bank;
  final double rate;
  final int minAmount;
  final int maxAmount;
  final String term;
  final int monthlyPayment;
  final List<String> requirements;
  final IconData icon;
}

class InvestorOffer {
  const InvestorOffer({
    required this.id,
    required this.name,
    required this.domain,
    required this.minInvestment,
    required this.maxInvestment,
    required this.roi,
    required this.projects,
    required this.description,
    required this.icon,
  });

  final int id;
  final String name;
  final InvestorDomain domain;
  final int minInvestment;
  final int maxInvestment;
  final double roi;
  final int projects;
  final String description;
  final IconData icon;
}

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.unread,
    required this.color,
    required this.icon,
  });

  final int id;
  final String title;
  final String body;
  final String time;
  final bool unread;
  final Color color;
  final IconData icon;
}

class AppSettings {
  const AppSettings({
    required this.language,
    required this.themeMode,
    required this.notificationsEnabled,
    required this.biometricEnabled,
    required this.currency,
  });

  final String language;
  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final bool biometricEnabled;
  final String currency;

  AppSettings copyWith({
    String? language,
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    bool? biometricEnabled,
    String? currency,
  }) {
    return AppSettings(
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      currency: currency ?? this.currency,
    );
  }
}

class ChartDataset {
  const ChartDataset({
    required this.label,
    required this.values,
    required this.color,
  });

  final String label;
  final List<double> values;
  final Color color;
}
