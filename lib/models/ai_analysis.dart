/// Structured AI output. We ask the model for strict JSON and map it here,
/// with graceful fallbacks if a field is missing.
class AiAnalysis {
  final String vibeTitle; // e.g. "Chronically Online Soulmates"
  final String vibeEmoji; // single emoji
  final String summary; // 1-2 line read on the dynamic
  final String roast; // playful, never mean
  final List<FlagItem> greenFlags;
  final List<FlagItem> redFlags;
  final String energyMatch; // who brings more energy
  final String whoTextsFirst;
  final String attachmentStyle; // texting attachment read
  final String firstTextRead; // witty read on the opening message
  final List<AiSuperlative> superlatives; // award-style call-outs
  final int vibeScore; // 0-100

  const AiAnalysis({
    required this.vibeTitle,
    required this.vibeEmoji,
    required this.summary,
    required this.roast,
    required this.greenFlags,
    required this.redFlags,
    required this.energyMatch,
    required this.whoTextsFirst,
    required this.attachmentStyle,
    required this.firstTextRead,
    required this.superlatives,
    required this.vibeScore,
  });

  Map<String, dynamic> toJson() => {
        'vibe_title': vibeTitle,
        'vibe_emoji': vibeEmoji,
        'summary': summary,
        'roast': roast,
        'energy_match': energyMatch,
        'who_texts_first': whoTextsFirst,
        'attachment_style': attachmentStyle,
        'first_text_read': firstTextRead,
        'green_flags': greenFlags.map((f) => f.toJson()).toList(),
        'red_flags': redFlags.map((f) => f.toJson()).toList(),
        'superlatives': superlatives.map((s) => s.toJson()).toList(),
        'vibe_score': vibeScore,
      };

  /// Parse the camelCase shape returned by the tikboo web backend (/api/analyze).
  factory AiAnalysis.fromApi(Map<String, dynamic> j) {
    List<FlagItem> flags(dynamic v) =>
        (v as List?)?.map((e) => FlagItem.fromAny(e)).toList() ?? const [];
    return AiAnalysis(
      vibeTitle: (j['vibeTitle'] ?? 'Certified Chat').toString(),
      vibeEmoji: (j['vibeEmoji'] ?? '✨').toString(),
      summary: (j['summary'] ?? '').toString(),
      roast: (j['roast'] ?? '').toString(),
      energyMatch: (j['energyMatch'] ?? '').toString(),
      whoTextsFirst: (j['whoTextsFirst'] ?? '').toString(),
      attachmentStyle: (j['attachmentStyle'] ?? '').toString(),
      firstTextRead: (j['firstTextRead'] ?? '').toString(),
      greenFlags: flags(j['greenFlags']),
      redFlags: flags(j['redFlags']),
      vibeScore: (j['vibeScore'] is num)
          ? (j['vibeScore'] as num).clamp(0, 100).toInt()
          : 72,
      superlatives: (j['superlatives'] as List?)
              ?.map((e) => AiSuperlative.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  factory AiAnalysis.fromJson(Map<String, dynamic> j) {
    List<FlagItem> flags(dynamic v) =>
        (v as List?)?.map((e) => FlagItem.fromAny(e)).toList() ?? const [];
    return AiAnalysis(
      vibeTitle: (j['vibe_title'] ?? 'Certified Chat').toString(),
      vibeEmoji: (j['vibe_emoji'] ?? '✨').toString(),
      summary: (j['summary'] ?? '').toString(),
      roast: (j['roast'] ?? '').toString(),
      greenFlags: flags(j['green_flags']),
      redFlags: flags(j['red_flags']),
      energyMatch: (j['energy_match'] ?? '').toString(),
      whoTextsFirst: (j['who_texts_first'] ?? '').toString(),
      attachmentStyle: (j['attachment_style'] ?? '').toString(),
      firstTextRead: (j['first_text_read'] ?? '').toString(),
      vibeScore: (j['vibe_score'] is num)
          ? (j['vibe_score'] as num).clamp(0, 100).toInt()
          : 72,
      superlatives: (j['superlatives'] as List?)
              ?.map((e) => AiSuperlative.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

/// A flag (green or red) with the actual message it's based on, so the read
/// feels personal and believable.
class FlagItem {
  final String flag; // the observation
  final String quote; // the real message backing it (may be empty)
  final String sender; // who said it (may be empty)

  const FlagItem({required this.flag, this.quote = '', this.sender = ''});

  /// Accepts either a plain string (legacy / history) or a {flag,quote,sender}.
  factory FlagItem.fromAny(dynamic v) {
    if (v is String) return FlagItem(flag: v);
    if (v is Map) {
      return FlagItem(
        flag: (v['flag'] ?? v['text'] ?? '').toString(),
        quote: (v['quote'] ?? '').toString(),
        sender: (v['sender'] ?? '').toString(),
      );
    }
    return FlagItem(flag: v.toString());
  }

  Map<String, dynamic> toJson() =>
      {'flag': flag, 'quote': quote, 'sender': sender};
}

class AiSuperlative {
  final String emoji;
  final String title; // award name
  final String person; // who won it
  final String reason;

  const AiSuperlative({
    required this.emoji,
    required this.title,
    required this.person,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
        'emoji': emoji,
        'title': title,
        'person': person,
        'reason': reason,
      };

  factory AiSuperlative.fromJson(Map<String, dynamic> j) => AiSuperlative(
        emoji: (j['emoji'] ?? '🏆').toString(),
        title: (j['title'] ?? '').toString(),
        person: (j['person'] ?? '').toString(),
        reason: (j['reason'] ?? '').toString(),
      );
}
