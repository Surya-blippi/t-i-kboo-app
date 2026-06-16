import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../legal/legal_content.dart';
import '../services/purchase_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/blob_background.dart';
import '../widgets/chunky_button.dart';
import 'legal_screen.dart';

/// Pops with `true` when the user successfully unlocks Pro.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final _purchases = PurchaseService.instance;
  bool _busy = false;
  bool _loading = true;
  List<ProPlan> _plans = const [];
  String? _selectedId;

  static const _benefits = [
    ('🧠', 'The full AI read', 'Vibe, roast, attachment style & score'),
    ('🚩', 'Every red flag, decoded', 'Plus the green flags you missed'),
    ('🔒', 'Private & secure', 'Analyzed for your eyes — never stored or sold'),
    ('🔖', 'Unlimited chats', 'Analyze every DM and group, anytime'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final plans = await _purchases.plans();
    if (!mounted) return;
    setState(() {
      _plans = plans;
      _selectedId = plans.isNotEmpty ? plans.first.id : null;
      _loading = false;
    });
  }

  ProPlan get _selected =>
      _plans.firstWhere((p) => p.id == _selectedId, orElse: () => _plans.first);

  Future<void> _start() async {
    // With real billing, a plan must have a live store package.
    if (_purchases.usingRealBilling && !_purchases.storeReady) {
      _toast('Couldn’t reach the App Store. Sign into a Sandbox account and retry.');
      _load();
      return;
    }
    setState(() => _busy = true);
    HapticFeedback.mediumImpact();
    final ok = await _purchases.purchase(_selected);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      _toast('Purchase didn’t go through or was cancelled.');
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    final ok = await _purchases.restore();
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      _toast('Nothing to restore.');
    }
  }

  void _toast(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: AppColors.inkCard,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Text(m, style: AppTheme.body(14, color: AppColors.textHi)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlobBackground(
        colors: const [AppColors.lime, AppColors.violet, AppColors.pink],
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context, false),
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.textMid),
                    ),
                    TextButton(
                      onPressed: _busy ? null : _restore,
                      child: Text('Restore',
                          style: AppTheme.body(14,
                              color: AppColors.textMid,
                              weight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
                  children: [
                    Text('UNLOCK THE', style: AppTheme.display(22)),
                    Text('FULL TEA 🍵',
                        style: AppTheme.display(38, color: AppColors.lime)),
                    const SizedBox(height: 24),
                    ..._benefits.map(_benefitRow),
                    const SizedBox(height: 20),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.lime)),
                      )
                    else
                      ..._plans.map(_planCard),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified_user_rounded,
                            color: AppColors.textMid, size: 16),
                        const SizedBox(width: 6),
                        Text('Cancel anytime, no commitments',
                            style: AppTheme.body(13, color: AppColors.textMid)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ChunkyButton(
                      label: 'UNLOCK MY REPORT',
                      icon: Icons.bolt_rounded,
                      loading: _busy,
                      onTap: _start,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _plans.isEmpty ? '' : _selected.priceLabel,
                      style: AppTheme.body(12, color: AppColors.textLow),
                    ),
                    const SizedBox(height: 10),
                    _legalBlock(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openLegal(String title, String body) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => LegalScreen(title: title, body: body),
    ));
  }

  Widget _legalBlock() {
    return Column(
      children: [
        Text(
          'Your subscription auto-renews at the price shown unless cancelled at least 24h before the period ends. Payment is charged to your Apple ID. Manage or cancel anytime in App Store settings.',
          textAlign: TextAlign.center,
          style: AppTheme.body(10, color: AppColors.textLow, height: 1.4),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () =>
                  _openLegal('Terms of Service', LegalContent.termsOfService),
              style: _legalBtnStyle,
              child: Text('Terms of Use',
                  style: AppTheme.body(11,
                      color: AppColors.textMid, weight: FontWeight.w700)),
            ),
            Text('·', style: AppTheme.body(11, color: AppColors.textLow)),
            TextButton(
              onPressed: () =>
                  _openLegal('Privacy Policy', LegalContent.privacyPolicy),
              style: _legalBtnStyle,
              child: Text('Privacy Policy',
                  style: AppTheme.body(11,
                      color: AppColors.textMid, weight: FontWeight.w700)),
            ),
            Text('·', style: AppTheme.body(11, color: AppColors.textLow)),
            TextButton(
              onPressed: _busy ? null : _restore,
              style: _legalBtnStyle,
              child: Text('Restore',
                  style: AppTheme.body(11,
                      color: AppColors.textMid, weight: FontWeight.w700)),
            ),
          ],
        ),
      ],
    );
  }

  static final ButtonStyle _legalBtnStyle = TextButton.styleFrom(
    minimumSize: const Size(0, 0),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );

  Widget _benefitRow((String, String, String) b) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.inkCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.stroke),
            ),
            child: Text(b.$1, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.$2,
                    style: AppTheme.display(15,
                        color: AppColors.textHi, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(b.$3, style: AppTheme.body(13, color: AppColors.textMid)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _planCard(ProPlan plan) {
    final selected = plan.id == _selectedId;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedId = plan.id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? AppColors.lime.withOpacity(0.12) : AppColors.inkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.lime : AppColors.stroke,
              width: selected ? 2.5 : 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(plan.title, style: AppTheme.display(18)),
                      if (plan.badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.lime,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(plan.badge!,
                              style: AppTheme.display(10,
                                  color: AppColors.ink,
                                  weight: FontWeight.w800)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(plan.priceLabel,
                      style: AppTheme.body(14,
                          color: AppColors.textHi, weight: FontWeight.w700)),
                ],
              ),
            ),
            if (plan.perWeek.isNotEmpty)
              Text(plan.perWeek,
                  style: AppTheme.body(13, color: AppColors.textMid)),
            const SizedBox(width: 10),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.circle_outlined,
              color: selected ? AppColors.lime : AppColors.textLow,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}
