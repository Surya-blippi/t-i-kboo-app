import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// tikboo Pro gate, backed by RevenueCat.
///
/// SETUP TO GO LIVE:
///   1. Create a RevenueCat project, add your App Store app, paste the
///      iOS public SDK key into [_revenueCatApiKey] below.
///   2. In RevenueCat create an entitlement called `pro` and an Offering
///      (default) with an Annual + Weekly package, attached to App Store
///      Connect products (with a 3-day intro trial on the weekly).
///   3. That's it — this class will pick up real localized prices and
///      handle purchase / restore automatically.
///
/// Until a real key is set, it runs in LOCAL fallback mode: the paywall works
/// and "purchasing" just flips a local flag, so you can test the whole flow
/// on-device before billing is configured.
class PurchaseService {
  PurchaseService._();
  static final instance = PurchaseService._();

  static const String _revenueCatApiKey = 'REVENUECAT_PUBLIC_SDK_KEY';
  static const String _entitlement = 'pro';
  static const _kProLocal = 'tikboo_pro_unlocked';

  /// Short reassurance shown under unlock CTAs.
  static const String trialHint = '3-day free trial · cancel anytime';

  bool _rcReady = false;
  Offering? _offering;

  bool get usingRealBilling => _rcReady;

  Future<void> init() async {
    if (_revenueCatApiKey == 'REVENUECAT_PUBLIC_SDK_KEY') {
      // No key yet → local fallback mode.
      return;
    }
    try {
      await Purchases.setLogLevel(LogLevel.warn);
      await Purchases.configure(PurchasesConfiguration(_revenueCatApiKey));
      _offering = (await Purchases.getOfferings()).current;
      _rcReady = true;
    } catch (e) {
      debugPrint('RevenueCat init failed, using local fallback: $e');
      _rcReady = false;
    }
  }

  Future<bool> isPro() async {
    if (_rcReady) {
      try {
        final info = await Purchases.getCustomerInfo();
        return info.entitlements.active.containsKey(_entitlement);
      } catch (_) {/* fall through to cache */}
    }
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kProLocal) ?? false;
  }

  /// Display plans for the paywall. Uses live store prices when RevenueCat is
  /// configured; otherwise the designed INR fallback copy.
  List<ProPlan> plans({required bool exclusiveOffer}) {
    if (_rcReady && _offering != null) {
      final pkgs = _offering!.availablePackages;
      return [
        for (final pkg in pkgs)
          ProPlan(
            id: pkg.identifier,
            title: _titleFor(pkg.packageType),
            priceLabel: pkg.storeProduct.priceString,
            perWeek: '',
            badge: pkg.packageType == PackageType.annual ? 'BEST VALUE' : null,
            trial: pkg.packageType == PackageType.weekly ? '3-day free trial' : null,
            package: pkg,
          ),
      ];
    }
    // Fallback (pre-billing) — matches the pricing table.
    return [
      ProPlan(
        id: 'yearly',
        title: 'Yearly',
        priceLabel: exclusiveOffer ? '₹499 / year' : '₹999 / year',
        perWeek: exclusiveOffer ? '≈ ₹9.6/wk' : '≈ ₹19/wk',
        badge: exclusiveOffer ? '80% OFF' : 'BEST VALUE',
      ),
      const ProPlan(
        id: 'weekly',
        title: 'Weekly',
        priceLabel: '₹199 / week',
        perWeek: '3-day free trial',
        trial: '3-day free trial',
      ),
    ];
  }

  String _titleFor(PackageType t) => switch (t) {
        PackageType.annual => 'Yearly',
        PackageType.weekly => 'Weekly',
        PackageType.monthly => 'Monthly',
        _ => 'Pro',
      };

  /// Returns true on success.
  Future<bool> purchase(ProPlan plan) async {
    if (_rcReady && plan.package != null) {
      try {
        // ignore: deprecated_member_use
        final result = await Purchases.purchasePackage(plan.package!);
        return result.customerInfo.entitlements.active
            .containsKey(_entitlement);
      } on PurchasesErrorCode {
        return false;
      } catch (_) {
        return false;
      }
    }
    // Local fallback.
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kProLocal, true);
    return true;
  }

  Future<bool> restore() async {
    if (_rcReady) {
      try {
        final info = await Purchases.restorePurchases();
        return info.entitlements.active.containsKey(_entitlement);
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
