import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../legal/legal_content.dart';
import '../services/purchase_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/blob_background.dart';
import 'legal_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _restoring = false;
  bool _demoSkip = false;

  @override
  void initState() {
    super.initState();
    PurchaseService.instance.demoSkipEnabled().then((v) {
      if (mounted) setState(() => _demoSkip = v);
    });
  }

  Future<void> _toggleDemoSkip(bool v) async {
    HapticFeedback.selectionClick();
    setState(() => _demoSkip = v);
    await PurchaseService.instance.setDemoSkip(v);
  }

  Future<void> _restore() async {
    setState(() => _restoring = true);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await PurchaseService.instance.restore();
    if (!mounted) return;
    setState(() => _restoring = false);
    messenger.showSnackBar(SnackBar(
      backgroundColor: AppColors.inkCard,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Text(ok ? 'Pro restored 🎉' : 'No purchases to restore.',
          style: AppTheme.body(14, color: AppColors.textHi)),
    ));
  }

  void _openLegal(String title, String body) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => LegalScreen(title: title, body: body),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlobBackground(
        colors: const [AppColors.cyan, AppColors.violet, AppColors.lime],
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: AppColors.textHi),
                  ),
                  const SizedBox(width: 4),
                  Text('SETTINGS', style: AppTheme.display(24)),
                ],
              ),
              const SizedBox(height: 24),
              Text('ACCOUNT', style: AppTheme.display(15, color: AppColors.lime)),
              const SizedBox(height: 10),
              _tile(
                'Restore Purchases',
                Icons.restore_rounded,
                _restoring ? null : _restore,
                trailing: _restoring
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.lime))
                    : null,
              ),
              const SizedBox(height: 28),
              Text('DEMO', style: AppTheme.display(15, color: AppColors.tangerine)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.inkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: _demoSkip ? AppColors.tangerine : AppColors.stroke),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_open_rounded,
                        color: AppColors.textMid, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Skip paywall',
                              style: AppTheme.display(15,
                                  color: AppColors.textHi,
                                  weight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text('Unlock reports free (for demo recordings)',
                              style: AppTheme.body(12, color: AppColors.textMid)),
                        ],
                      ),
                    ),
                    Switch(
                      value: _demoSkip,
                      activeColor: AppColors.ink,
                      activeTrackColor: AppColors.tangerine,
                      inactiveThumbColor: AppColors.textMid,
                      inactiveTrackColor: AppColors.inkSoft,
                      onChanged: _toggleDemoSkip,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text('LEGAL', style: AppTheme.display(15, color: AppColors.cyan)),
              const SizedBox(height: 10),
              _tile('Privacy Policy', Icons.shield_rounded,
                  () => _openLegal('Privacy Policy', LegalContent.privacyPolicy)),
              const SizedBox(height: 10),
              _tile('Terms of Service', Icons.description_rounded,
                  () => _openLegal('Terms of Service', LegalContent.termsOfService)),
              const SizedBox(height: 28),
              Center(
                child: Text('tikboo · made with 🍵',
                    style: AppTheme.body(12, color: AppColors.textLow)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(String label, IconData icon, VoidCallback? onTap,
      {Widget? trailing}) {
    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap();
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.inkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textMid, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: AppTheme.display(15,
                      color: AppColors.textHi, weight: FontWeight.w700)),
            ),
            trailing ??
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textLow),
          ],
        ),
      ),
    );
  }
}
