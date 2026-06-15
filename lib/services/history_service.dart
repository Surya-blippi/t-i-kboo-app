import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_analysis.dart';
import '../models/chat_context.dart';
import '../models/chat_stats.dart';

/// Stores past analyses locally so users can revisit them. Everything stays
/// on-device (SharedPreferences) — nothing is uploaded.
class HistoryService {
  HistoryService._();
  static final instance = HistoryService._();

  static const _key = 'tikboo_history_v1';
  static const _max = 50;

  Future<List<ReportEntry>> list() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null) return [];
    final arr = jsonDecode(raw) as List;
    return arr
        .map((e) => ReportEntry.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  }

  Future<void> save(ChatStats stats, AiAnalysis ai, ChatContext ctx) async {
    final entry = ReportEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      savedAt: DateTime.now(),
      title: stats.isGroup
          ? 'Group chat'
          : (ctx.otherName.isNotEmpty
              ? ctx.otherName
              : stats.people.first.name),
      relationship: ctx.relationship,
      subject: ctx.subject,
      vibeTitle: ai.vibeTitle,
      vibeEmoji: ai.vibeEmoji,
      vibeScore: ai.vibeScore,
      stats: stats,
      ai: ai,
    );
    final current = await list();
    current.insert(0, entry);
    final trimmed = current.take(_max).toList();
    final p = await SharedPreferences.getInstance();
    await p.setString(
        _key, jsonEncode(trimmed.map((e) => e.toJson()).toList()));
  }

  Future<void> delete(String id) async {
    final current = await list();
    current.removeWhere((e) => e.id == id);
    final p = await SharedPreferences.getInstance();
    await p.setString(
        _key, jsonEncode(current.map((e) => e.toJson()).toList()));
  }

  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}

class ReportEntry {
  final String id;
  final DateTime savedAt;
  final String title;
  final String relationship;
  final Subject subject;
  final String vibeTitle;
  final String vibeEmoji;
  final int vibeScore;
  final ChatStats stats;
  final AiAnalysis ai;

  const ReportEntry({
    required this.id,
    required this.savedAt,
    required this.title,
    required this.relationship,
    required this.subject,
    required this.vibeTitle,
    required this.vibeEmoji,
    required this.vibeScore,
    required this.stats,
    required this.ai,
  });

  ChatContext get context =>
      ChatContext(subject: subject, relationship: relationship);

  Map<String, dynamic> toJson() => {
        'id': id,
        'savedAt': savedAt.toIso8601String(),
        'title': title,
        'relationship': relationship,
        'subject': subject.name,
        'vibeTitle': vibeTitle,
        'vibeEmoji': vibeEmoji,
        'vibeScore': vibeScore,
        'stats': stats.toJson(),
        'ai': ai.toJson(),
      };

  factory ReportEntry.fromJson(Map<String, dynamic> j) => ReportEntry(
        id: j['id'] as String,
        savedAt: DateTime.parse(j['savedAt'] as String),
        title: j['title'] as String,
        relationship: j['relationship'] as String,
        subject: Subject.values.firstWhere((s) => s.name == j['subject'],
            orElse: () => Subject.group),
        vibeTitle: j['vibeTitle'] as String? ?? '',
        vibeEmoji: j['vibeEmoji'] as String? ?? '✨',
        vibeScore: j['vibeScore'] as int? ?? 0,
        stats: ChatStats.fromJson(j['stats'] as Map<String, dynamic>),
        ai: AiAnalysis.fromJson(j['ai'] as Map<String, dynamic>),
      );
}
