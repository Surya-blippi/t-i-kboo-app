import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

void showHowToSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.inkSoft,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const _HowToSheet(),
  );
}

class _HowToSheet extends StatelessWidget {
  const _HowToSheet();

  @override
  Widget build(BuildContext context) {
    final steps = [
      'Open the WhatsApp chat you want to read.',
      'Tap the contact / group name at the top.',
      'Scroll down → "Export Chat".',
      'Choose "Without Media" (faster, cleaner).',
      'Save the .txt or .zip, then import it here.',
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.stroke,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('EXPORT IN 5 SECS', style: AppTheme.display(26)),
          const SizedBox(height: 4),
          Text('Same steps on iPhone + Android.',
              style: AppTheme.body(14, color: AppColors.textMid)),
          const SizedBox(height: 22),
          for (int i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.deck[i % AppColors.deck.length],
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text('${i + 1}',
                        style: AppTheme.display(13,
                            color: AppColors.ink, weight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(steps[i],
                          style: AppTheme.body(15, color: AppColors.textHi)),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.stroke),
            ),
            child: Text(
              '🔒 Your chat is sent to the AI only to generate your report — it’s never saved to our servers, stored, or sold.',
              style: AppTheme.body(13, color: AppColors.textMid, height: 1.45),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
