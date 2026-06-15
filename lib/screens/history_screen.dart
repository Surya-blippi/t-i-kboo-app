import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat_context.dart';
import '../services/history_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/blob_background.dart';
import 'results_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ReportEntry>? _entries;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final e = await HistoryService.instance.list();
    if (mounted) setState(() => _entries = e);
  }

  Future<void> _open(ReportEntry e) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ResultsScreen(
          stats: e.stats,
          analysis: e.ai,
          otherName: e.subject == Subject.group ? '' : e.title),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries;
    return Scaffold(
      body: BlobBackground(
        colors: const [AppColors.cyan, AppColors.pink, AppColors.violet],
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.textHi),
                    ),
                    const SizedBox(width: 4),
                    Text('HISTORY', style: AppTheme.display(24)),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: entries == null
                      ? const Center(
                          child:
                              CircularProgressIndicator(color: AppColors.lime))
                      : entries.isEmpty
                          ? _empty()
                          : ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              itemCount: entries.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (_, i) => _tile(entries[i]),
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🗂️', style: AppTheme.display(56)),
          const SizedBox(height: 14),
          Text('No reports yet',
              style: AppTheme.display(22), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Analyze a chat and it’ll show up here\nto revisit anytime.',
              style: AppTheme.body(15, color: AppColors.textMid, height: 1.5),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _tile(ReportEntry e) {
    final accent =
        AppColors.deck[e.title.hashCode.abs() % AppColors.deck.length];
    return Dismissible(
      key: ValueKey(e.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.pink.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_rounded, color: AppColors.pink),
      ),
      onDismissed: (_) async {
        await HistoryService.instance.delete(e.id);
        setState(() => _entries!.removeWhere((x) => x.id == e.id));
      },
      child: GestureDetector(
        onTap: () => _open(e),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.inkCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.stroke),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(e.vibeEmoji, style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.display(17)),
                    const SizedBox(height: 3),
                    Text(
                      '${e.relationship} · ${e.vibeTitle.isNotEmpty ? e.vibeTitle : 'tap to view'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.body(13, color: AppColors.textMid),
                    ),
                    const SizedBox(height: 2),
                    Text(DateFormat('MMM d, yyyy').format(e.savedAt),
                        style: AppTheme.body(12, color: AppColors.textLow)),
                  ],
                ),
              ),
              if (e.vibeScore > 0)
                Text('${e.vibeScore}',
                    style: AppTheme.display(20, color: accent)),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textLow),
            ],
          ),
        ),
      ),
    );
  }
}
