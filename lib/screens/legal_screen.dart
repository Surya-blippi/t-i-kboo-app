import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/blob_background.dart';

/// Renders in-app legal text (Privacy Policy / Terms) in tikboo's style.
/// Lightweight markup: "## " heading, "- " bullet, blank line spacing.
class LegalScreen extends StatelessWidget {
  final String title;
  final String body;
  const LegalScreen({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlobBackground(
        colors: const [AppColors.cyan, AppColors.violet, AppColors.lime],
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 24, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.textHi),
                    ),
                    const SizedBox(width: 4),
                    Expanded(child: Text(title, style: AppTheme.display(24))),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  physics: const BouncingScrollPhysics(),
                  children: _render(body),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _render(String text) {
    final widgets = <Widget>[];
    for (final raw in text.trim().split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 12));
      } else if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 6),
          child: Text(line.substring(3),
              style: AppTheme.display(16, color: AppColors.lime)),
        ));
      } else if (line.startsWith('- ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('•',
                  style: AppTheme.body(15, color: AppColors.textMid)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(line.substring(2),
                    style: AppTheme.body(15,
                        color: AppColors.textHi, height: 1.5)),
              ),
            ],
          ),
        ));
      } else {
        widgets.add(Text(line,
            style: AppTheme.body(15, color: AppColors.textHi, height: 1.55)));
      }
    }
    return widgets;
  }
}
