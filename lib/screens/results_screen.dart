import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/ai_analysis.dart';
import '../models/chat_stats.dart';
import '../services/purchase_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'paywall_screen.dart';
import 'wrapped_cards.dart';

class ResultsScreen extends StatefulWidget {
  final ChatStats stats;
  final AiAnalysis analysis;
  final String otherName;
  const ResultsScreen(
      {super.key,
      required this.stats,
      required this.analysis,
      this.otherName = ''});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final _controller = PageController();
  int _index = 0;
  bool _pro = false; // gated until we confirm entitlement
  late List<Widget> _cards;

  @override
  void initState() {
    super.initState();
    _rebuild();
    _loadPro();
  }

  Future<void> _loadPro() async {
    final pro = await PurchaseService.instance.isPro();
    if (!mounted) return;
    setState(() {
      _pro = pro;
      _rebuild();
    });
  }

  void _rebuild() {
    _cards = buildWrappedCards(
      widget.stats,
      widget.analysis,
      isPro: _pro,
      onUnlock: _openPaywall,
      otherName: widget.otherName,
    );
  }

  Future<void> _openPaywall() async {
    final unlocked = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PaywallScreen()),
    );
    if (unlocked == true && mounted) {
      setState(() {
        _pro = true;
        _rebuild();
      });
      // Slide into the freshly-unlocked verdict.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_controller.hasClients) {
          _controller.nextPage(
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOut);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < _cards.length - 1) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 380), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(
        children: [
          GestureDetector(
            onTapUp: (d) {
              final w = MediaQuery.of(context).size.width;
              if (d.localPosition.dx > w * 0.35) {
                _next();
              } else if (_index > 0) {
                _controller.previousPage(
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOut);
              }
            },
            child: PageView(
              controller: _controller,
              onPageChanged: (i) {
                HapticFeedback.selectionClick();
                setState(() => _index = i);
              },
              children: _cards,
            ),
          ),
          // Segmented progress bar (stories style)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  for (int i = 0; i < _cards.length; i++)
                    Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i <= _index
                              ? AppColors.textHi
                              : AppColors.textHi.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Close
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 24, right: 8),
                child: IconButton(
                  onPressed: () => Navigator.of(context)
                      .popUntil((r) => r.isFirst),
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textHi),
                ),
              ),
            ),
          ),
          // Tap hint on first card
          if (_index == 0)
            Positioned(
              bottom: 36,
              left: 0,
              right: 0,
              child: Center(
                child: Text('tap to continue →',
                        style: AppTheme.body(13, color: AppColors.textMid))
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fadeIn(duration: 800.ms),
              ),
            ),
        ],
      ),
    );
  }
}

/// Reusable scaffold for one full-bleed wrapped card.
class WrappedScaffold extends StatelessWidget {
  final Color accent;
  final Widget child;
  const WrappedScaffold({super.key, required this.accent, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withOpacity(0.22),
            AppColors.ink,
            AppColors.ink,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 72, 28, 40),
          child: child,
        ),
      ),
    );
  }
}

