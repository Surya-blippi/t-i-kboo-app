import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models/ai_analysis.dart';
import '../models/chat_stats.dart';
import '../services/purchase_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/chunky_button.dart';
import 'results_screen.dart';
import 'share_slide.dart';

/// Builds the ordered list of full-screen wrapped cards.
/// AI cards are skipped gracefully when running in stats-only mode, and gated
/// behind the paywall when the user isn't Pro.
List<Widget> buildWrappedCards(
  ChatStats stats,
  AiAnalysis ai, {
  bool isPro = true,
  VoidCallback? onUnlock,
  String otherName = '',
}) {
  final hasAi = ai.roast.isNotEmpty || ai.vibeScore > 0 || ai.summary.isNotEmpty;
  final cards = <Widget>[];

  // --- FREE TEASERS (first 2 cards) ---
  cards.add(_IntroCard(stats: stats));
  cards.add(_FirstTextCard(stats: stats, ai: ai));

  // Paywall gate right after the teasers — the rest of the deck is Pro.
  if (hasAi && !isPro) {
    cards.add(_LockedCard(ai: ai, onUnlock: onUnlock));
    return cards;
  }

  // --- FULL REPORT (Pro, or stats-only mode with no AI to gate) ---
  // Total messages
  cards.add(_BigStatCard(
    accent: AppColors.lime,
    kicker: 'TOTAL DAMAGE',
    value: _compact(stats.totalMessages),
    label: 'messages sent',
    caption:
        'across ${stats.spanDays} days · ${stats.activeDays} of them actually active',
  ));

  // Who texts more
  cards.add(_TexterCard(stats: stats));

  // Peak hour
  cards.add(_BigStatCard(
    accent: AppColors.violet,
    kicker: 'PRIME TIME',
    value: _hourLabel(stats.peakHour),
    label: 'is when it pops off',
    caption: stats.peakHour >= 23 || stats.peakHour <= 4
        ? 'certified night owls 🦉 touch grass challenge: failed'
        : 'peak chaos hours, locked in',
  ));

  // 4 — Top emoji
  cards.add(_EmojiCard(stats: stats));

  // Longest message — the essayist
  if (stats.longestWords > 5) cards.add(_LongestMessageCard(stats: stats));

  // 5 — Longest streak
  cards.add(_BigStatCard(
    accent: AppColors.cyan,
    kicker: 'NO DAYS OFF',
    value: '${stats.longestStreakDays}',
    label: stats.longestStreakDays == 1 ? 'day streak' : 'day streak',
    caption: stats.longestStreakDays >= 7
        ? 'texting every single day. obsessed (affectionate) 🔥'
        : 'longest you went without ghosting each other',
  ));

  // AI cards — the emotional payload.
  if (hasAi) {
    cards.add(_VibeCard(ai: ai));
    if (ai.energyMatch.isNotEmpty || ai.whoTextsFirst.isNotEmpty) {
      cards.add(_ReadCard(ai: ai));
    }
    if (ai.attachmentStyle.isNotEmpty) cards.add(_AttachmentCard(ai: ai));
    if (ai.superlatives.isNotEmpty) cards.add(_SuperlativesCard(ai: ai));
    if (ai.greenFlags.isNotEmpty) {
      cards.add(_FlagsCard(
        accent: AppColors.lime,
        emoji: '🟢',
        title: 'GREEN FLAGS',
        flags: ai.greenFlags,
      ));
    }
    if (ai.redFlags.isNotEmpty) {
      cards.add(_FlagsCard(
        accent: AppColors.pink,
        emoji: '🚩',
        title: 'RED FLAGS',
        flags: ai.redFlags,
      ));
    }
    if (ai.roast.isNotEmpty) cards.add(_RoastCard(ai: ai));
  }

  // Final
  cards.add(ShareSlide(stats: stats, analysis: ai, otherName: otherName));
  return cards;
}

String _compact(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}

String _hourLabel(int h) {
  final ampm = h < 12 ? 'AM' : 'PM';
  final hr = h % 12 == 0 ? 12 : h % 12;
  return '$hr $ampm';
}

// ---------------------------------------------------------------------------

class _IntroCard extends StatelessWidget {
  final ChatStats stats;
  const _IntroCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final who = stats.isGroup
        ? '${stats.people.length} legends'
        : stats.people.map((p) => p.name).take(2).join(' & ');
    return WrappedScaffold(
      accent: AppColors.pink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('THE TEA ON', style: AppTheme.display(22, color: AppColors.textMid)),
          const SizedBox(height: 8),
          Text(who, style: AppTheme.display(40, color: AppColors.pink, height: 1.05))
              .animate()
              .fadeIn(duration: 500.ms)
              .slideX(begin: -0.15, end: 0),
          const SizedBox(height: 20),
          Text('is officially served. 🍵',
              style: AppTheme.body(18, color: AppColors.textHi)),
        ],
      ),
    );
  }
}

class _LockedCard extends StatelessWidget {
  final AiAnalysis ai;
  final VoidCallback? onUnlock;
  const _LockedCard({required this.ai, this.onUnlock});

  @override
  Widget build(BuildContext context) {
    final teasers = [
      ('🧠', 'Attachment style', AppColors.violet),
      ('💞', 'Vibe score: ${ai.vibeScore > 0 ? ai.vibeScore : 78}/100', AppColors.lime),
      ('🚩', 'Red flags', AppColors.pink),
      ('🔥', 'The roast', AppColors.tangerine),
    ];
    return WrappedScaffold(
      accent: AppColors.lime,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('THE VERDICT IS IN',
              style: AppTheme.display(18, color: AppColors.lime)),
          const SizedBox(height: 6),
          Text('Unlock your\nfull report 🔓',
              style: AppTheme.display(32, height: 1.1)),
          const SizedBox(height: 20),
          Expanded(
            child: Stack(
              children: [
                // Blurred teaser stack
                ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: teasers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final t = teasers[i];
                    return Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: t.$3.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: t.$3.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          Text(t.$1, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(t.$2,
                                style: AppTheme.display(16,
                                    color: AppColors.textHi)),
                          ),
                          const Icon(Icons.lock_rounded,
                              color: AppColors.textMid, size: 20),
                        ],
                      ),
                    );
                  },
                ),
                // Fade to imply "more below"
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 80,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.ink.withOpacity(0),
                            AppColors.ink,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ChunkyButton(
            label: 'UNLOCK FULL REPORT',
            icon: Icons.lock_open_rounded,
            onTap: onUnlock,
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(PurchaseService.trialHint,
                style: AppTheme.body(12, color: AppColors.textLow)),
          ),
        ],
      ),
    );
  }
}

class _FirstTextCard extends StatelessWidget {
  final ChatStats stats;
  final AiAnalysis ai;
  const _FirstTextCard({required this.stats, required this.ai});

  @override
  Widget build(BuildContext context) {
    final preview = stats.firstText.trim().isEmpty
        ? '(a media message)'
        : stats.firstText.trim();
    final clipped =
        preview.length > 140 ? '${preview.substring(0, 140)}…' : preview;
    return WrappedScaffold(
      accent: AppColors.cyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WHO BROKE THE ICE',
              style: AppTheme.display(18, color: AppColors.cyan)),
          const Spacer(),
          Text(stats.firstSender,
                  style: AppTheme.display(34, color: AppColors.textHi))
              .animate()
              .fadeIn(duration: 400.ms),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.inkCard,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: AppColors.stroke),
            ),
            child: Text('“$clipped”',
                style: AppTheme.body(17, color: AppColors.textHi, height: 1.4)),
          ),
          const SizedBox(height: 8),
          Text(DateFormat('MMM d, yyyy · h:mm a').format(stats.firstDateTime),
              style: AppTheme.body(13, color: AppColors.textLow)),
          const Spacer(),
          if (ai.firstTextRead.isNotEmpty)
            Text(ai.firstTextRead,
                style: AppTheme.body(16, color: AppColors.textMid, height: 1.5)),
        ],
      ),
    );
  }
}

class _LongestMessageCard extends StatelessWidget {
  final ChatStats stats;
  const _LongestMessageCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final preview = stats.longestText.trim();
    final clipped =
        preview.length > 220 ? '${preview.substring(0, 220)}…' : preview;
    return WrappedScaffold(
      accent: AppColors.tangerine,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('THE ESSAY 📝',
              style: AppTheme.display(18, color: AppColors.tangerine)),
          const SizedBox(height: 6),
          Text('${stats.longestSender} typed ${stats.longestWords} words in one go',
              style: AppTheme.display(26, height: 1.15)),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.inkCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.stroke),
                ),
                child: Text('“$clipped”',
                    style: AppTheme.body(16,
                        color: AppColors.textHi, height: 1.5)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('no notes. a whole TED talk. 🎤',
              style: AppTheme.body(15, color: AppColors.textMid)),
        ],
      ),
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  final AiAnalysis ai;
  const _AttachmentCard({required this.ai});

  @override
  Widget build(BuildContext context) {
    return WrappedScaffold(
      accent: AppColors.violet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ATTACHMENT STYLE 🧠',
              style: AppTheme.display(18, color: AppColors.violet)),
          const Spacer(),
          Text('the texting tells',
              style: AppTheme.display(30, color: AppColors.textHi, height: 1.1)),
          const SizedBox(height: 16),
          Text(ai.attachmentStyle,
                  style:
                      AppTheme.body(18, color: AppColors.textHi, height: 1.55))
              .animate()
              .fadeIn(duration: 500.ms),
          const Spacer(),
        ],
      ),
    );
  }
}

class _BigStatCard extends StatelessWidget {
  final Color accent;
  final String kicker;
  final String value;
  final String label;
  final String caption;
  const _BigStatCard({
    required this.accent,
    required this.kicker,
    required this.value,
    required this.label,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return WrappedScaffold(
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(kicker, style: AppTheme.display(18, color: accent)),
          const Spacer(),
          Text(value,
                  style: AppTheme.display(96, color: AppColors.textHi, height: 0.95))
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(begin: const Offset(0.7, 0.7), end: const Offset(1, 1)),
          const SizedBox(height: 8),
          Text(label, style: AppTheme.display(24, color: AppColors.textHi)),
          const Spacer(),
          Text(caption, style: AppTheme.body(16, color: AppColors.textMid, height: 1.5)),
        ],
      ),
    );
  }
}

class _TexterCard extends StatelessWidget {
  final ChatStats stats;
  const _TexterCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final top = stats.people.take(stats.isGroup ? 4 : 2).toList();
    final max = top.first.messages.toDouble();
    return WrappedScaffold(
      accent: AppColors.tangerine,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('YAP RANKINGS', style: AppTheme.display(18, color: AppColors.tangerine)),
          const SizedBox(height: 6),
          Text(stats.isGroup ? 'who runs the group' : 'who texts more',
              style: AppTheme.display(30, height: 1.1)),
          const Spacer(),
          for (int i = 0; i < top.length; i++) ...[
            _bar(top[i].name, top[i].messages, max,
                AppColors.deck[i % AppColors.deck.length], i),
            const SizedBox(height: 18),
          ],
          const Spacer(),
          Text(
            stats.isGroup
                ? '${top.first.name} simply could not be stopped 🗣️'
                : '${top.first.name} sent ${(top.first.messages / (top.last.messages == 0 ? 1 : top.last.messages)).toStringAsFixed(1)}x more. someone’s down bad 👀',
            style: AppTheme.body(16, color: AppColors.textMid, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _bar(String name, int count, double max, Color color, int i) {
    final pct = max == 0 ? 0.0 : count / max;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.display(18, color: AppColors.textHi)),
            ),
            Text(_compact(count),
                style: AppTheme.display(18, color: color)),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.inkCard,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            FractionallySizedBox(
              widthFactor: pct.clamp(0.04, 1.0),
              child: Container(
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ).animate().scaleX(
                  begin: 0,
                  end: 1,
                  alignment: Alignment.centerLeft,
                  duration: 600.ms,
                  delay: (120 * i).ms,
                  curve: Curves.easeOut,
                ),
          ],
        ),
      ],
    );
  }
}

class _EmojiCard extends StatelessWidget {
  final ChatStats stats;
  const _EmojiCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return WrappedScaffold(
      accent: AppColors.violet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SIGNATURE EMOJI', style: AppTheme.display(18, color: AppColors.violet)),
          const Spacer(),
          Center(
            child: Text(stats.topEmojiOverall, style: const TextStyle(fontSize: 120))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                    duration: 1200.ms,
                    begin: const Offset(0.92, 0.92),
                    end: const Offset(1.08, 1.08)),
          ),
          const Spacer(),
          Text('${_compact(stats.totalEmojis)} emojis total',
              style: AppTheme.display(26, color: AppColors.textHi)),
          const SizedBox(height: 10),
          Text('this one carried the entire conversation on its back.',
              style: AppTheme.body(16, color: AppColors.textMid, height: 1.5)),
        ],
      ),
    );
  }
}

class _VibeCard extends StatelessWidget {
  final AiAnalysis ai;
  const _VibeCard({required this.ai});

  @override
  Widget build(BuildContext context) {
    return WrappedScaffold(
      accent: AppColors.lime,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('THE VERDICT', style: AppTheme.display(18, color: AppColors.lime)),
          const Spacer(),
          Text(ai.vibeEmoji, style: const TextStyle(fontSize: 72)),
          const SizedBox(height: 12),
          Text(ai.vibeTitle,
                  style: AppTheme.display(38, color: AppColors.lime, height: 1.05))
              .animate()
              .fadeIn(duration: 500.ms),
          const SizedBox(height: 16),
          if (ai.summary.isNotEmpty)
            Text(ai.summary,
                style: AppTheme.body(17, color: AppColors.textHi, height: 1.5)),
          const Spacer(),
          if (ai.vibeScore > 0) _scoreBar(ai.vibeScore),
        ],
      ),
    );
  }

  Widget _scoreBar(int score) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('VIBE SCORE', style: AppTheme.display(15, color: AppColors.textMid)),
            Text('$score/100', style: AppTheme.display(20, color: AppColors.lime)),
          ],
        ),
        const SizedBox(height: 10),
        Stack(
          children: [
            Container(
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.inkCard,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            FractionallySizedBox(
              widthFactor: (score / 100).clamp(0.02, 1.0),
              child: Container(
                height: 16,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppColors.cyan, AppColors.lime]),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ).animate().scaleX(
                begin: 0,
                end: 1,
                alignment: Alignment.centerLeft,
                duration: 800.ms,
                curve: Curves.easeOut),
          ],
        ),
      ],
    );
  }
}

class _ReadCard extends StatelessWidget {
  final AiAnalysis ai;
  const _ReadCard({required this.ai});

  @override
  Widget build(BuildContext context) {
    return WrappedScaffold(
      accent: AppColors.cyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('THE DYNAMIC', style: AppTheme.display(18, color: AppColors.cyan)),
          const Spacer(),
          if (ai.energyMatch.isNotEmpty) ...[
            Text('⚡ energy', style: AppTheme.display(20, color: AppColors.textHi)),
            const SizedBox(height: 8),
            Text(ai.energyMatch,
                style: AppTheme.body(17, color: AppColors.textMid, height: 1.5)),
            const SizedBox(height: 28),
          ],
          if (ai.whoTextsFirst.isNotEmpty) ...[
            Text('💬 first move', style: AppTheme.display(20, color: AppColors.textHi)),
            const SizedBox(height: 8),
            Text(ai.whoTextsFirst,
                style: AppTheme.body(17, color: AppColors.textMid, height: 1.5)),
          ],
          const Spacer(),
        ],
      ),
    );
  }
}

class _SuperlativesCard extends StatelessWidget {
  final AiAnalysis ai;
  const _SuperlativesCard({required this.ai});

  @override
  Widget build(BuildContext context) {
    return WrappedScaffold(
      accent: AppColors.tangerine,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('THE AWARDS', style: AppTheme.display(18, color: AppColors.tangerine)),
          const SizedBox(height: 6),
          Text('hand them their trophies 🏆', style: AppTheme.display(26, height: 1.1)),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: ai.superlatives.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (_, i) {
                final s = ai.superlatives[i];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.inkCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.stroke),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.emoji, style: const TextStyle(fontSize: 30)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.title,
                                style: AppTheme.display(15,
                                    color: AppColors.tangerine,
                                    weight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(s.person,
                                style: AppTheme.body(14,
                                    color: AppColors.textHi,
                                    weight: FontWeight.w700)),
                            if (s.reason.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(s.reason,
                                  style: AppTheme.body(13,
                                      color: AppColors.textMid, height: 1.4)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: (90 * i).ms).slideY(begin: 0.2, end: 0);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FlagsCard extends StatelessWidget {
  final Color accent;
  final String emoji;
  final String title;
  final List<FlagItem> flags;
  const _FlagsCard({
    required this.accent,
    required this.emoji,
    required this.title,
    required this.flags,
  });

  @override
  Widget build(BuildContext context) {
    return WrappedScaffold(
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.display(28, color: accent)),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: flags.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (_, i) => _flagTile(flags[i], i),
            ),
          ),
        ],
      ),
    );
  }

  Widget _flagTile(FlagItem f, int i) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(f.flag,
                  style: AppTheme.display(16,
                      color: AppColors.textHi, weight: FontWeight.w700)),
            ),
          ],
        ),
        if (f.quote.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.only(left: 30),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.inkCard,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: accent.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (f.sender.trim().isNotEmpty)
                  Text(f.sender,
                      style: AppTheme.body(11,
                          color: accent, weight: FontWeight.w800)),
                Text('“${f.quote.trim()}”',
                    style: AppTheme.body(14,
                        color: AppColors.textHi, height: 1.4)),
              ],
            ),
          ),
        ],
      ],
    ).animate().fadeIn(delay: (100 * i).ms).slideX(begin: 0.12, end: 0);
  }
}

class _RoastCard extends StatelessWidget {
  final AiAnalysis ai;
  const _RoastCard({required this.ai});

  @override
  Widget build(BuildContext context) {
    return WrappedScaffold(
      accent: AppColors.pink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('THE ROAST 🔥', style: AppTheme.display(28, color: AppColors.pink)),
          const Spacer(),
          Text('"', style: AppTheme.display(60, color: AppColors.pink, height: 0.6)),
          Text(ai.roast,
                  style: AppTheme.display(22, color: AppColors.textHi, height: 1.3))
              .animate()
              .fadeIn(duration: 600.ms),
          const Spacer(),
          Text('— tikboo, with love',
              style: AppTheme.body(15, color: AppColors.textMid)),
        ],
      ),
    );
  }
}
