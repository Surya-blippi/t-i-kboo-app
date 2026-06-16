import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// tikboo Pro gate, backed by RevenueCat.
///
/// CURRENT KEY IS A TEST STORE KEY (test_...): purchases are SIMULATED (a
/// RevenueCat modal, no real StoreKit, no revenue). Great for testing the flow.
///
/// BEFORE APP STORE SUBMISSION you MUST swap to the production App Store key:
///   1. In RevenueCat, add your App Store app (upload the App Store Connect
///      In-App Purchase key + Issuer ID + shared secret).
///   2. Copy the Apple public SDK key (starts with `appl_`).
///   3. Replace [_revenueCatApiKey] below with that appl_ key, rebuild, upload.
/// Apps submitted with a test_ key are rejected by App Review.
///
/// If the key is left as the placeholder, the app runs in LOCAL fallback mode
/// (tapping unlock flips a local flag) so the UI still works without billing.
class PurchaseService {
  PurchaseService._();
  static final instance = PurchaseService._();

  static const String _revenueCatApiKey = 'appl_wnfRwVctWkwVWPeIkJQQaopGOJe';
  static const _kProLocal = 'tikboo_pro_unlocked';

  /// Short reassurance shown under unlock CTAs.
  static const String trialHint = 'Cancel anytime in the App Store';

  bool _rcReady = false;
  Offering? _offering;

  /// True only when no real key is set — the ONLY mode where a local unlock is
  /// allowed (for UI testing). With a real key, unlock requires a real purchase.
  bool get _placeholderKey => _revenueCatApiKey == 'REVENUECAT_PUBLIC_SDK_KEY';

  /// True when RevenueCat is configured AND an offering with packages loaded.
  bool get storeReady => _rcReady && _offering != null;
  bool get usingRealBilling => !_placeholderKey;

  Future<void> init() async {
    if (_placeholderKey) return; // local fallback mode
    // A Test Store key (test_...) in a RELEASE build makes RevenueCat show a
    // native alert and force-close the app. Only configure with a production
    // key (appl_/goog_) OR in a debug build (Test Store OK).
    final isProductionKey = _revenueCatApiKey.startsWith('appl_') ||
        _revenueCatApiKey.startsWith('goog_');
    if (!isProductionKey && !kDebugMode) {
      debugPrint('Skipping RevenueCat: non-production key in release.');
      return;
    }
    try {
      await Purchases.setLogLevel(LogLevel.warn);
      await Purchases.configure(PurchasesConfiguration(_revenueCatApiKey));
      _rcReady = true;
    } catch (e) {
      debugPrint('RevenueCat configure failed: $e');
      _rcReady = false;
      return;
    }
    await _loadOffering();
  }

  Future<void> _loadOffering() async {
    if (!_rcReady) return;
    try {
      final offerings =
          await Purchases.getOfferings().timeout(const Duration(seconds: 15));
      _offering = offerings.current ??
          (offerings.all.isNotEmpty ? offerings.all.values.first : null);
    } catch (e) {
      debugPrint('RevenueCat offerings load failed: $e');
    }
  }

  /// Single-entitlement app → any active entitlement means Pro.
  Future<bool> isPro() async {
    if (_rcReady) {
      try {
        final info = await Purchases.getCustomerInfo();
        return info.entitlements.active.isNotEmpty;
      } catch (_) {
        return false;
      }
    }
    // Local unlock is only honored in placeholder (no-billing) mode.
    if (_placeholderKey) {
      final p = await SharedPreferences.getInstance();
      return p.getBool(_kProLocal) ?? false;
    }
    return false;
  }

  /// Plans for the paywall. With a real key, loads live store packages (fetching
  /// the offering on demand if needed). Falls back to display-only copy.
  Future<List<ProPlan>> plans() async {
    if (_rcReady) {
      if (_offering == null) await _loadOffering();
      if (_offering != null) {
        final pkgs = [..._offering!.availablePackages]
          // Yearly first (highest-value option on top).
          ..sort((a, b) => (_isYearly(b) ? 1 : 0) - (_isYearly(a) ? 1 : 0));
        return [
          for (final pkg in pkgs)
            ProPlan(
              id: pkg.identifier,
              title: _title(pkg),
              priceLabel: pkg.storeProduct.priceString, // live localized price
              perWeek: '',
              badge: _isYearly(pkg) ? 'BEST VALUE' : null,
              package: pkg,
            ),
        ];
      }
    }
    // Fallback (display only; real unlock requires a real purchase).
    return const [
      ProPlan(
        id: 'yearly',
        title: 'Yearly',
        priceLabel: '₹999 / year',
        perWeek: '≈ ₹19/wk',
        badge: 'BEST VALUE',
      ),
      ProPlan(
        id: 'weekly',
        title: 'Weekly',
        priceLabel: '₹299 / week',
        perWeek: '',
      ),
    ];
  }

  // Map a package to a display title + "is this the yearly plan", robust to
  // either standard package types or custom identifiers like "yearly"/"weekly".
  bool _isYearly(Package p) {
    if (p.packageType == PackageType.annual) return true;
    final id = p.identifier.toLowerCase();
    return id.contains('year') || id.contains('annual');
  }

  String _title(Package p) {
    switch (p.packageType) {
      case PackageType.annual:
        return 'Yearly';
      case PackageType.weekly:
        return 'Weekly';
      case PackageType.monthly:
        return 'Monthly';
      default:
        final id = p.identifier.toLowerCase();
        if (id.contains('year') || id.contains('annual')) return 'Yearly';
        if (id.contains('week')) return 'Weekly';
        if (id.contains('month')) return 'Monthly';
        return p.storeProduct.title;
    }
  }

  /// Returns true on success (entitlement active).
  Future<bool> purchase(ProPlan plan) async {
    if (_rcReady && plan.package != null) {
      try {
        // ignore: deprecated_member_use
        final result = await Purchases.purchasePackage(plan.package!);
        return result.customerInfo.entitlements.active.isNotEmpty;
      } on PurchasesErrorCode {
        return false;
      } catch (_) {
        return false;
      }
    }
    // Local unlock ONLY in placeholder (no-billing) mode — never with a real key,
    // so real users can't unlock for free if the store didn't load.
    if (_placeholderKey) {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_kProLocal, true);
      return true;
    }
    return false;
  }

  Future<bool> restore() async {
    if (_rcReady) {
      try {
        final info = await Purchases.restorePurchases();
        return info.entitlements.active.isNotEmpty;
      } catch (_) {
        return false;
      }
    }
    return isPro();
  }

  Future<void> resetForTesting() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kProLocal);
  }
}

class ProPlan {
  final String id;
  final String title;
  final String priceLabel;
  final String perWeek;
  final String? badge;
  final String? trial;
  final Package? package;

  const ProPlan({
    required this.id,
    required this.title,
    required this.priceLabel,
    required this.perWeek,
    this.badge,
    this.trial,
    this.package,
  });
}
