import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/ai_analysis.dart';
import '../models/chat_stats.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/chunky_button.dart';
import 'results_screen.dart';

/// The final "That's a wrap" slide: shows a 9:16 story-format summary card
/// (with a "Made with tikboo" watermark) and shares it as an image.
class ShareSlide extends StatefulWidget {
  final ChatStats stats;
  final AiAnalysis analysis;
  final String otherName;
  const ShareSlide({
    super.key,
    required this.stats,
    required this.analysis,
    this.otherName = '',
  });

  @override
  State<ShareSlide> createState() => _ShareSlideState();
}

class _ShareSlideState extends State<ShareSlide> {
  final _cardKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    HapticFeedback.mediumImpact();
    // Capture the anchor rect BEFORE any async gap.
    final box = context.findRenderObject() as RenderBox?;
    final origin = (box != null && box.hasSize)
        ? box.localToGlobal(Offset.zero) & box.size
        : const Rect.fromLTWH(0, 0, 100, 100);
    try {
      final boundary = _cardKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = await File(
              '${dir.path}/tikboo_wrapped_${DateTime.now().millisecondsSinceEpoch}.png')
          .writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: 'my chat, decoded 🍵 made with tikboo',
        sharePositionOrigin: origin,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.inkCard,
          behavior: SnackBarBehavior.floating,
          content: Text('Couldn’t make the card: $e',
              style: AppTheme.body(13, color: AppColors.textHi)),
        ));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WrappedScaffold(
      accent: AppColors.lime,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("THAT'S A WRAP",
              style: AppTheme.display(28), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text('share your verdict ✨',
              style: AppTheme.body(14, color: AppColors.textMid),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: RepaintBoundary(
                  key: _cardKey,
                  child: ShareableWrappedCard(
                    stats: widget.stats,
                    analysis: widget.analysis,
                    otherName: widget.otherName,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ChunkyButton(
            label: _sharing ? 'CREATING…' : 'SHARE TO STORY',
            icon: _sharing ? null : Icons.ios_share_rounded,
            loading: _sharing,
            onTap: _share,
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: Center(
              child: Text('analyze another chat',
                  style: AppTheme.body(14,
                      color: AppColors.textMid, weight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fixed 9:16 (360×640 logical → 1080×1920 @3x) story card. Screenshot-ready.
class ShareableWrappedCard extends StatelessWidget {
  final ChatStats stats;
  final AiAnalysis analysis;
  final String otherName;
  const ShareableWrappedCard({
    super.key,
    required this.stats,
    required this.analysis,
    this.otherName = '',
  });

  String get _namesLine {
    if (stats.isGroup) return '${stats.people.length} legends';
    if (otherName.isEmpty) {
      return stats.people.map((p) => p.name).take(2).join('  ×  ');
    }
    final you = stats.people
        .map((p) => p.name)
        .firstWhere((n) => n != otherName, orElse: () => 'You');
    return '$you  ×  $otherName';
  }

  @override
  Widget build(BuildContext context) {
    final hasAi = analysis.vibeScore > 0 || analysis.summary.isNotEmpty;
    return Container(
      width: 360,
      height: 640,
      decoration: const BoxDecoration(color: AppColors.ink),
      child: Stack(
        children: [
          // gradient mesh
          Positioned(
              top: -60,
              left: -40,
              child: _blob(AppColors.violet, 240)),
          Positioned(
              bottom: -40, right: -50, child: _blob(AppColors.pink, 260)),
          Positioned(
              bottom: 120, left: -60, child: _blob(AppColors.lime, 200)),
          Positioned.fill(
              child: Container(color: AppColors.ink.withOpacity(0.45))),
          Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.lime,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(Icons.chat_bubble_rounded,
                          color: AppColors.ink, size: 13),
                    ),
                    const SizedBox(width: 8),
                    Text('tikboo', style: AppTheme.display(16)),
                    const Spacer(),
                    Text('WRAPPED',
                        style: AppTheme.display(12, color: AppColors.textMid)),
                  ],
                ),
                const Spacer(),
                Text(analysis.vibeEmoji.isNotEmpty ? analysis.vibeEmoji : '🍵',
                    style: const TextStyle(fontSize: 64)),
                const SizedBox(height: 10),
                Text(
                  hasAi && analysis.vibeTitle.isNotEmpty
                      ? analysis.vibeTitle
                      : 'Certified Chat',
                  style: AppTheme.display(30, color: AppColors.lime, height: 1.05),
                ),
                const SizedBox(height: 10),
                Text(_namesLine,
                    style: AppTheme.display(15, color: AppColors.textHi)),
                const SizedBox(height: 16),
                if (analysis.summary.isNotEmpty)
                  Text(
                    analysis.summary,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style:
                        AppTheme.body(13, color: AppColors.textMid, height: 1.45),
                  ),
                const Spacer(),
                Row(
                  children: [
                    if (hasAi)
                      _stat('${analysis.vibeScore}', 'vibe', AppColors.lime),
                    _stat(_compact(stats.totalMessages), 'texts',
                        AppColors.cyan),
                    _stat(stats.topEmojiOverall, 'top', AppColors.pink),
                    _stat('${stats.longestStreakDays}d', 'streak',
                        AppColors.tangerine),
                  ],
                ),
                const SizedBox(height: 18),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.inkCard.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.stroke),
                    ),
                    child: Text('Made with tikboo 🍵',
                        style: AppTheme.display(12, color: AppColors.textHi)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, Color accent) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.display(22, color: accent)),
          Text(label, style: AppTheme.body(11, color: AppColors.textMid)),
        ],
      ),
    );
  }

  Widget _blob(Color c, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
              colors: [c.withOpacity(0.6), c.withOpacity(0.0)]),
        ),
      );

  static String _compact(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
