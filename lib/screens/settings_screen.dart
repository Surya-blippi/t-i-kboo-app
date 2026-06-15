import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../legal/legal_content.dart';
import '../services/purchase_service.dart';
import '../services/settings_service.dart';
import 'legal_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/blob_background.dart';
import '../widgets/chunky_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settings = SettingsService();
  final _controller = TextEditingController();
  String _model = SettingsService.defaultModel;
  bool _obscure = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final key = await _settings.getApiKey();
    final model = await _settings.getModel();
    if (!mounted) return;
    setState(() {
      _controller.text = key ?? '';
      _model = model;
      _loaded = true;
    });
  }

  Future<void> _save() async {
    await _settings.setApiKey(_controller.text);
    await _settings.setModel(_model);
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlobBackground(
        colors: const [AppColors.cyan, AppColors.violet, AppColors.lime],
        child: SafeArea(
          child: _loaded
              ? ListView(
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
                    Text('OPENROUTER KEY',
                        style: AppTheme.display(15, color: AppColors.lime)),
                    const SizedBox(height: 8),
                    Text(
                      'Free to make at openrouter.ai/keys. The free models cost \$0 — you just need a key to use them.',
                      style: AppTheme.body(14, color: AppColors.textMid),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _controller,
                      obscureText: _obscure,
                      style: AppTheme.body(15, color: AppColors.textHi),
                      decoration: InputDecoration(
                        hintText: 'sk-or-v1-…',
                        hintStyle: AppTheme.body(15, color: AppColors.textLow),
                        filled: true,
                        fillColor: AppColors.inkCard,
                        suffixIcon: IconButton(
                          icon: Icon(
                              _obscure
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                              color: AppColors.textMid),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text('MODEL',
                        style: AppTheme.display(15, color: AppColors.pink)),
                    const SizedBox(height: 8),
                    Text('All free. Pick your fighter.',
                        style: AppTheme.body(14, color: AppColors.textMid)),
                    const SizedBox(height: 12),
                    ...SettingsService.freeModels.map(_modelTile),
                    const SizedBox(height: 28),
                    Text('LEGAL',
                        style: AppTheme.display(15, color: AppColors.cyan)),
                    const SizedBox(height: 10),
                    _legalRow('Privacy Policy', () => _openLegal(
                        'Privacy Policy', LegalContent.privacyPolicy)),
                    const SizedBox(height: 10),
                    _legalRow('Terms of Service', () => _openLegal(
                        'Terms of Service', LegalContent.termsOfService)),
                    const SizedBox(height: 28),
                    ChunkyButton(label: 'SAVE', onTap: _save),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await PurchaseService.instance.resetForTesting();
                          messenger.showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Pro reset — paywall will show again')),
                          );
                        },
                        child: Text('Reset Pro (testing)',
                            style: AppTheme.body(13,
                                color: AppColors.textLow,
                                weight: FontWeight.w700)),
                      ),
                    ),
                  ],
                )
              : const Center(
                  child: CircularProgressIndicator(color: AppColors.lime)),
        ),
      ),
    );
  }

  void _openLegal(String title, String body) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => LegalScreen(title: title, body: body),
    ));
  }

  Widget _legalRow(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.inkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: AppTheme.display(15,
                      color: AppColors.textHi, weight: FontWeight.w700)),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textLow),
          ],
        ),
      ),
    );
  }

  Widget _modelTile(FreeModel m) {
    final selected = m.id == _model;
    return GestureDetector(
      onTap: () => setState(() => _model = m.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.lime.withOpacity(0.12) : AppColors.inkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selected ? AppColors.lime : AppColors.stroke,
              width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.label,
                      style: AppTheme.display(15,
                          color: AppColors.textHi, weight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(m.blurb,
                      style: AppTheme.body(13, color: AppColors.textMid)),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? AppColors.lime : AppColors.textLow,
            ),
          ],
        ),
      ),
    );
  }
}
