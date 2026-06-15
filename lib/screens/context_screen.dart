import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/chat_context.dart';
import '../models/chat_stats.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/blob_background.dart';
import '../widgets/chunky_button.dart';
import 'analyzing_screen.dart';

/// Two-step context capture: who are they → what's the vibe.
/// For group chats the gender step is skipped automatically.
class ContextScreen extends StatefulWidget {
  final ChatStats stats;
  final String otherName;
  const ContextScreen(
      {super.key, required this.stats, this.otherName = ''});

  @override
  State<ContextScreen> createState() => _ContextScreenState();
}

class _ContextScreenState extends State<ContextScreen> {
  late int _step; // 0 = gender, 1 = relationship
  Subject? _subject;
  String? _relationship;

  @override
  void initState() {
    super.initState();
    // Skip gender for group chats.
    if (widget.stats.isGroup) {
      _subject = Subject.group;
      _step = 1;
    } else {
      _step = 0;
    }
  }

  String get _otherName {
    if (widget.stats.isGroup) return 'the group';
    if (widget.otherName.isNotEmpty) return widget.otherName;
    final p = widget.stats.people;
    return p.isNotEmpty ? p.first.name : 'them';
  }

  void _back() {
    if (_step == 1 && !widget.stats.isGroup) {
      setState(() => _step = 0);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _continue() {
    HapticFeedback.mediumImpact();
    if (_step == 0) {
      setState(() => _step = 1);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AnalyzingScreen(
            stats: widget.stats,
            context: ChatContext(
              subject: _subject ?? Subject.group,
              relationship: _relationship ?? 'Friend',
              otherName: _otherName,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _step == 0 ? _subject != null : _relationship != null;
    return Scaffold(
      body: BlobBackground(
        colors: _step == 0
            ? const [AppColors.pink, AppColors.violet, AppColors.cyan]
            : const [AppColors.violet, AppColors.lime, AppColors.pink],
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: _back,
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: AppColors.textHi),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    child: _step == 0 ? _genderStep() : _relationshipStep(),
                  ),
                ),
                ChunkyButton(
                  label: _step == 0 ? 'CONTINUE' : 'ANALYZE THE CHAT',
                  icon: _step == 0 ? Icons.arrow_forward_rounded : Icons.bolt_rounded,
                  color: canContinue ? AppColors.lime : AppColors.inkCard,
                  onTap: canContinue ? _continue : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _genderStep() {
    return Column(
      key: const ValueKey('gender'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('WHO IS', style: AppTheme.display(20, color: AppColors.textMid)),
        Text('$_otherName?',
                style: AppTheme.display(38, color: AppColors.pink, height: 1.05))
            .animate()
            .fadeIn(duration: 350.ms),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: _genderCard('👩', 'A girl', Subject.girl, AppColors.pink),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _genderCard('🧑', 'A guy', Subject.guy, AppColors.cyan),
            ),
          ],
        ),
      ],
    );
  }

  Widget _genderCard(String emoji, String label, Subject value, Color accent) {
    final selected = _subject == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _subject = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(0.14) : AppColors.inkCard,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: selected ? accent : AppColors.stroke,
              width: selected ? 2.5 : 1),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(label,
                style: AppTheme.display(18,
                    color: selected ? accent : AppColors.textHi)),
          ],
        ),
      ),
    );
  }

  Widget _relationshipStep() {
    final options = [
      ('😳', 'Crush'),
      ('🌀', 'Situationship'),
      ('💞', 'Together'),
      ('🪦', 'Ex'),
      ('👯', 'Friend'),
      ('🫂', 'Family'),
      if (widget.stats.isGroup) ('👥', 'Group chat'),
    ];
    return Column(
      key: const ValueKey('rel'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("WHAT'S THE VIBE",
            style: AppTheme.display(20, color: AppColors.textMid)),
        Text('with $_otherName?',
            style: AppTheme.display(30, color: AppColors.violet, height: 1.1)),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            itemCount: options.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final o = options[i];
              return _relTile(o.$1, o.$2,
                  AppColors.deck[i % AppColors.deck.length]);
            },
          ),
        ),
      ],
    );
  }

  Widget _relTile(String emoji, String label, Color accent) {
    final selected = _relationship == label;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _relationship = label);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(0.14) : AppColors.inkCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: selected ? accent : AppColors.stroke,
              width: selected ? 2.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: AppTheme.display(17,
                      color: selected ? accent : AppColors.textHi)),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? accent : AppColors.textLow,
            ),
          ],
        ),
      ),
    );
  }
}
