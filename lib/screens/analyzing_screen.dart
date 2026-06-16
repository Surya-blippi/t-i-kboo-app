import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/ai_analysis.dart';
import '../models/chat_context.dart';
import '../models/chat_stats.dart';
import '../services/ai_service.dart';
import '../services/history_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/blob_background.dart';
import '../widgets/chunky_button.dart';
import 'results_screen.dart';

class AnalyzingScreen extends StatefulWidget {
  final ChatStats stats;
  final ChatContext context;
  const AnalyzingScreen(
      {super.key, required this.stats, required this.context});

  @override
  State<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends State<AnalyzingScreen> {
  String? _error;

  Timer? _stepTimer;
  int _activeStep = 0;
  bool _aiDone = false;
  AiAnalysis? _result;

  static const _steps = [
    (Icons.description_rounded, 'Reading the chat'),
    (Icons.shield_rounded, 'Anonymising the messages'),
    (Icons.flag_rounded, 'Detecting red flags'),
    (Icons.insights_rounded, 'Reading message patterns'),
    (Icons.auto_awesome_rounded, 'Cooking the verdict'),
  ];

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    super.dispose();
  }

  void _startChecklist() {
    _activeStep = 0;
    _aiDone = false;
    _stepTimer?.cancel();
    _stepTimer = Timer.periodic(const Duration(milliseconds: 900), (t) {
      if (!mounted) return;
      setState(() {
        // Hold on the final step until the AI actually returns.
        final cap = _aiDone ? _steps.length : _steps.length - 1;
        if (_activeStep < cap) _activeStep++;
      });
      if (_activeStep >= _steps.length && _aiDone) {
        t.cancel();
        _goToResults();
      }
    });
  }

  Future<void> _run() async {
    setState(() => _error = null);
    _startChecklist();
    try {
      final analysis =
          await AiService().analyze(widget.stats, context: widget.context);
      _result = analysis;
      _aiDone = true;
      // Persist to local history so it can be revisited later.
      HistoryService.instance.save(widget.stats, analysis, widget.context);
      // If the checklist already finished waiting, jump now.
      if (_activeStep >= _steps.length - 1) {
        setState(() => _activeStep = _steps.length);
      }
    } catch (e) {
      _stepTimer?.cancel();
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  void _goToResults() {
    if (!mounted || _result == null) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResultsScreen(
            stats: widget.stats,
            analysis: _result!,
            otherName: widget.context.otherName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlobBackground(
        colors: const [AppColors.violet, AppColors.lime, AppColors.cyan],
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _error != null
                ? Center(child: _errorView())
                : _checklistView(),
          ),
        ),
      ),
    );
  }

  Widget _checklistView() {
    final total = _steps.length;
    final done = _activeStep.clamp(0, total);
    final progress = (done / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 84,
            height: 84,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                  colors: [AppColors.violet, AppColors.cyan]),
            ),
            child: Text(
              widget.context.subject == Subject.group
                  ? '👥'
                  : (widget.stats.mostActiveSenderName.isNotEmpty
                      ? widget.stats.mostActiveSenderName
                          .characters.first
                          .toUpperCase()
                      : '✨'),
              style: AppTheme.display(34, color: AppColors.textHi),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Analyzing your\nconversation…',
            textAlign: TextAlign.center,
            style: AppTheme.display(28, height: 1.1)),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Analyzing…',
                style: AppTheme.body(14, color: AppColors.textMid)),
            Text('${(progress * 100).round()}%',
                style: AppTheme.display(16, color: AppColors.lime)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: AppColors.inkCard,
            valueColor: const AlwaysStoppedAnimation(AppColors.lime),
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: total,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _stepTile(i, done),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.lime.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_user_rounded,
                  color: AppColors.lime, size: 18),
              const SizedBox(width: 8),
              Text('Analyzed securely · never stored or sold',
                  style: AppTheme.body(13,
                      color: AppColors.textMid, weight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepTile(int i, int done) {
    final isDone = i < done;
    final isActive = i == done;
    const accent = AppColors.lime;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDone
            ? accent.withOpacity(0.10)
            : isActive
                ? AppColors.inkCard
                : AppColors.inkSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive ? accent : (isDone ? accent.withOpacity(0.4) : AppColors.stroke),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDone ? accent.withOpacity(0.18) : AppColors.ink,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_steps[i].$1,
                size: 20,
                color: isDone || isActive ? accent : AppColors.textLow),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text('${_steps[i].$2}…',
                style: AppTheme.display(15,
                    color: isDone || isActive
                        ? AppColors.textHi
                        : AppColors.textLow,
                    weight: FontWeight.w600)),
          ),
          if (isDone)
            const Icon(Icons.check_circle_rounded,
                    color: AppColors.lime, size: 24)
                .animate()
                .scale(duration: 250.ms, curve: Curves.easeOutBack)
          else if (isActive)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: AppColors.lime),
            )
          else
            Icon(Icons.circle_outlined,
                color: AppColors.textLow.withOpacity(0.5), size: 22),
        ],
      ),
    );
  }

  Widget _errorView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('😵‍💫', style: AppTheme.display(56)),
        const SizedBox(height: 16),
        Text('HIT A SNAG', style: AppTheme.display(28)),
        const SizedBox(height: 10),
        Text(_error ?? 'Something went wrong.',
            style: AppTheme.body(15, color: AppColors.textMid, height: 1.5)),
        const SizedBox(height: 24),
        ChunkyButton(
            label: 'TRY AGAIN', icon: Icons.refresh_rounded, onTap: _run),
      ],
    );
  }
}
