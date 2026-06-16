import 'package:flutter/foundation.dart';

class PaymentLabels {
  final String currency;
  final String currencyCode;
  final WalletLabels wallet;
  final UnlockLabels unlock;
  final SettingsLabels settings;
  final PricingLabels pricing;
  final FilterLabels filters;

  PaymentLabels({
    this.currency = '₹',
    this.currencyCode = 'INR',
    WalletLabels? wallet,
    UnlockLabels? unlock,
    SettingsLabels? settings,
    PricingLabels? pricing,
    FilterLabels? filters,
  })  : wallet = wallet ?? WalletLabels(),
        unlock = unlock ?? UnlockLabels(),
        settings = settings ?? SettingsLabels(),
        pricing = pricing ?? PricingLabels(),
        filters = filters ?? FilterLabels();

  factory PaymentLabels.fromJson(Map<String, dynamic> json) {
    return PaymentLabels(
      currency: json['currency'] as String? ?? '₹',
      currencyCode: json['currency_code'] as String? ?? 'INR',
      wallet: json['wallet'] != null
          ? WalletLabels.fromJson(json['wallet'])
          : WalletLabels(),
      unlock: json['unlock'] != null
          ? UnlockLabels.fromJson(json['unlock'])
          : UnlockLabels(),
      settings: json['settings'] != null
          ? SettingsLabels.fromJson(json['settings'])
          : SettingsLabels(),
      pricing: json['pricing'] != null
          ? PricingLabels.fromJson(json['pricing'])
          : PricingLabels(),
      filters: json['filters'] != null
          ? FilterLabels.fromJson(json['filters'])
          : FilterLabels(),
    );
  }
}

class WalletLabels {
  final String title;
  final String balanceLabel;
  final String quickRecharge;
  final String transactionHistory;
  final String transfer;
  final String noTransactions;
  final String recharge;
  final String rechargeNow;
  final String rechargeRequired;
  final String later;

  const WalletLabels({
    this.title = 'Wallet & Transactions',
    this.balanceLabel = 'Available Balance',
    this.quickRecharge = 'Quick Recharge',
    this.transactionHistory = 'Transaction History',
    this.transfer = 'Transfer',
    this.noTransactions = 'No transactions in this category',
    this.recharge = 'Recharge',
    this.rechargeNow = 'Recharge Now',
    this.rechargeRequired = 'Recharge Required',
    this.later = 'Later',
  });

  factory WalletLabels.fromJson(Map<String, dynamic> json) {
    return WalletLabels(
      title: json['title'] as String? ?? 'Wallet & Transactions',
      balanceLabel: json['balance_label'] as String? ?? 'Available Balance',
      quickRecharge: json['quick_recharge'] as String? ?? 'Quick Recharge',
      transactionHistory: json['transaction_history'] as String? ?? 'Transaction History',
      transfer: json['transfer'] as String? ?? 'Transfer',
      noTransactions: json['no_transactions'] as String? ?? 'No transactions in this category',
      recharge: json['recharge'] as String? ?? 'Recharge',
      rechargeNow: json['recharge_now'] as String? ?? 'Recharge Now',
      rechargeRequired: json['recharge_required'] as String? ?? 'Recharge Required',
      later: json['later'] as String? ?? 'Later',
    );
  }
}

class UnlockLabels {
  final String title;
  final String payNow;
  final String unlockWithWallet;
  final String unlockFree;
  final String confirmUnlock;
  final String insufficientBalance;
  final String walletLabel;
  final String askPermission;
  final String unlocked;
  final String permissionGranted;
  final String permissionDeclined;
  final String permissionRequested;
  final String sendingRequest;
  final String viewContact;
  final String contactInfo;
  final String freeUnlockOffer;
  final String unlockFreeDesc;
  final String verificationRequired;
  final String dailyLimitReached;
  final String confirmUnlockDesc;

  const UnlockLabels({
    this.title = 'Unlock Contact',
    this.payNow = 'Pay Now',
    this.unlockWithWallet = 'Wallet',
    this.unlockFree = 'Unlock Free',
    this.confirmUnlock = 'Confirm & Unlock',
    this.insufficientBalance = 'Insufficient Balance',
    this.walletLabel = 'Wallet',
    this.askPermission = 'Ask Permission',
    this.unlocked = 'Unlocked',
    this.permissionGranted = 'Permission Granted — You can now unlock via Wallet',
    this.permissionDeclined = 'Permission Declined',
    this.permissionRequested = 'Permission Requested — Awaiting Reply',
    this.sendingRequest = 'Sending Request...',
    this.viewContact = 'View Contact Details',
    this.contactInfo = 'Contact Information',
    this.freeUnlockOffer = 'Free Unlock Offer',
    this.unlockFreeDesc = 'Unlock contacts for free during this promotional period.',
    this.verificationRequired = 'Verification Required',
    this.dailyLimitReached = 'Daily Limit Reached',
    this.confirmUnlockDesc = 'Are you sure you want to unlock this contact?',
  });

  factory UnlockLabels.fromJson(Map<String, dynamic> json) {
    return UnlockLabels(
      title: json['title'] as String? ?? 'Unlock Contact',
      payNow: json['pay_now'] as String? ?? 'Pay Now',
      unlockWithWallet: json['unlock_with_wallet'] as String? ?? 'Wallet',
      unlockFree: json['unlock_free'] as String? ?? 'Unlock Free',
      confirmUnlock: json['confirm_unlock'] as String? ?? 'Confirm & Unlock',
      insufficientBalance: json['insufficient_balance'] as String? ?? 'Insufficient Balance',
      walletLabel: json['wallet_label'] as String? ?? 'Wallet',
      askPermission: json['ask_permission'] as String? ?? 'Ask Permission',
      unlocked: json['unlocked'] as String? ?? 'Unlocked',
      permissionGranted: json['permission_granted'] as String? ?? 'Permission Granted — You can now unlock via Wallet',
      permissionDeclined: json['permission_declined'] as String? ?? 'Permission Declined',
      permissionRequested: json['permission_requested'] as String? ?? 'Permission Requested — Awaiting Reply',
      sendingRequest: json['sending_request'] as String? ?? 'Sending Request...',
      viewContact: json['view_contact'] as String? ?? 'View Contact Details',
      contactInfo: json['contact_info'] as String? ?? 'Contact Information',
      freeUnlockOffer: json['free_unlock_offer'] as String? ?? 'Free Unlock Offer',
      unlockFreeDesc: json['unlock_free_desc'] as String? ?? 'Unlock contacts for free during this promotional period.',
      verificationRequired: json['verification_required'] as String? ?? 'Verification Required',
      dailyLimitReached: json['daily_limit_reached'] as String? ?? 'Daily Limit Reached',
      confirmUnlockDesc: json['confirm_unlock_desc'] as String? ?? 'Are you sure you want to unlock this contact?',
    );
  }
}

class SettingsLabels {
  final String walletTitle;
  final String walletSubtitle;

  const SettingsLabels({
    this.walletTitle = 'Wallet & Transactions',
    this.walletSubtitle = 'Recharge and view history',
  });

  factory SettingsLabels.fromJson(Map<String, dynamic> json) {
    return SettingsLabels(
      walletTitle: json['wallet_title'] as String? ?? 'Wallet & Transactions',
      walletSubtitle: json['wallet_subtitle'] as String? ?? 'Recharge and view history',
    );
  }
}

class PricingLabels {
  final List<Map<String, dynamic>> tiers;
  final int dailyLimit;
  final bool walletIsActive;
  final bool walletInMaintenanceIos;
  final bool walletInMaintenanceAndroid;

  const PricingLabels({
    this.tiers = const [],
    this.dailyLimit = 20,
    this.walletIsActive = true,
    this.walletInMaintenanceIos = false,
    this.walletInMaintenanceAndroid = false,
  });

  bool get isInMaintenance {
    if (!walletIsActive) return true;
    if (kIsWeb) return walletInMaintenanceAndroid || walletInMaintenanceIos;
    if (defaultTargetPlatform == TargetPlatform.iOS && walletInMaintenanceIos) return true;
    if (defaultTargetPlatform == TargetPlatform.android && walletInMaintenanceAndroid) return true;
    
    // Fallback for desktop testing
    if (defaultTargetPlatform == TargetPlatform.windows || 
        defaultTargetPlatform == TargetPlatform.macOS || 
        defaultTargetPlatform == TargetPlatform.linux) {
      return walletInMaintenanceAndroid || walletInMaintenanceIos;
    }
    return false;
  }

  factory PricingLabels.fromJson(Map<String, dynamic> json) {
    return PricingLabels(
      tiers: (json['tiers'] as List<dynamic>?)
              ?.map((t) => t as Map<String, dynamic>)
              .toList() ?? [],
      dailyLimit: int.tryParse(json['daily_limit']?.toString() ?? '') ?? 20,
      walletIsActive: json['wallet_is_active'] as bool? ?? true,
      walletInMaintenanceIos: json['wallet_in_maintenance_ios'] as bool? ?? false,
      walletInMaintenanceAndroid: json['wallet_in_maintenance_android'] as bool? ?? false,
    );
  }
}

class FilterLabels {
  final String all;
  final String recharges;
  final String unlocks;
  final String usageFees;
  final String transfers;

  const FilterLabels({
    this.all = 'All',
    this.recharges = 'Recharges',
    this.unlocks = 'Unlocks',
    this.usageFees = 'Usage Fees',
    this.transfers = 'Transfers',
  });

  factory FilterLabels.fromJson(Map<String, dynamic> json) {
    return FilterLabels(
      all: json['all'] as String? ?? 'All',
      recharges: json['recharges'] as String? ?? 'Recharges',
      unlocks: json['unlocks'] as String? ?? 'Unlocks',
      usageFees: json['usage_fees'] as String? ?? 'Usage Fees',
      transfers: json['transfers'] as String? ?? 'Transfers',
    );
  }
}
