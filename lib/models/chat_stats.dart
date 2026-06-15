/// Deterministic, on-device stats. No AI, no network — fast + private.
class PersonStats {
  final String name;
  int messages;
  int words;
  int emojis;
  int media;
  int questions;
  int laughs; // haha / lol / 😂 / 💀
  int conversationsStarted; // first msg after a long gap
  final Map<String, int> topEmojis;
  final List<String> topWords;
  Duration? avgReply; // median-ish reply latency to the other person

  PersonStats({
    required this.name,
    this.messages = 0,
    this.words = 0,
    this.emojis = 0,
    this.media = 0,
    this.questions = 0,
    this.laughs = 0,
    this.conversationsStarted = 0,
    Map<String, int>? topEmojis,
    List<String>? topWords,
    this.avgReply,
  })  : topEmojis = topEmojis ?? {},
        topWords = topWords ?? [];

  double get avgWordsPerMsg => messages == 0 ? 0 : words / messages;

  Map<String, dynamic> toJson() => {
        'name': name,
        'messages': messages,
        'words': words,
        'emojis': emojis,
        'media': media,
        'questions': questions,
        'laughs': laughs,
        'conversationsStarted': conversationsStarted,
        'topEmojis': topEmojis,
        'topWords': topWords,
        'avgReplySeconds': avgReply?.inSeconds,
      };

  factory PersonStats.fromJson(Map<String, dynamic> j) => PersonStats(
        name: j['name'] as String,
        messages: j['messages'] as int? ?? 0,
        words: j['words'] as int? ?? 0,
        emojis: j['emojis'] as int? ?? 0,
        media: j['media'] as int? ?? 0,
        questions: j['questions'] as int? ?? 0,
        laughs: j['laughs'] as int? ?? 0,
        conversationsStarted: j['conversationsStarted'] as int? ?? 0,
        topEmojis: (j['topEmojis'] as Map?)?.map(
                (k, v) => MapEntry(k as String, v as int)) ??
            {},
        topWords:
            (j['topWords'] as List?)?.map((e) => e.toString()).toList() ?? [],
        avgReply: j['avgReplySeconds'] == null
            ? null
            : Duration(seconds: j['avgReplySeconds'] as int),
      );
}

class ChatStats {
  final bool isGroup;
  final List<PersonStats> people;
  final int totalMessages;
  final DateTime firstDate;
  final DateTime lastDate;
  final int activeDays;
  final int longestStreakDays;
  final Map<int, int> messagesByHour; // 0-23
  final Map<int, int> messagesByWeekday; // 1=Mon..7=Sun
  final String mostActiveSenderName;
  final String topEmojiOverall;
  final int totalEmojis;
  final int totalMedia;
  final String busiestDayLabel;
  final int busiestDayCount;
  final String firstSender;
  final String firstText;
  final DateTime firstDateTime;
  final String longestSender;
  final String longestText;
  final int longestWords;

  /// Sampled "Sender: text" lines sent to the AI so it can quote real
  /// messages. Held only for the live analysis call — NOT serialized to
  /// local history (see toJson).
  final List<String> sampleLines;

  const ChatStats({
    required this.isGroup,
    required this.people,
    required this.totalMessages,
    required this.firstDate,
    required this.lastDate,
    required this.activeDays,
    required this.longestStreakDays,
    required this.messagesByHour,
    required this.messagesByWeekday,
    required this.mostActiveSenderName,
    required this.topEmojiOverall,
    required this.totalEmojis,
    required this.totalMedia,
    required this.busiestDayLabel,
    required this.busiestDayCount,
    required this.firstSender,
    required this.firstText,
    required this.firstDateTime,
    required this.longestSender,
    required this.longestText,
    required this.longestWords,
    this.sampleLines = const [],
  });

  int get spanDays => lastDate.difference(firstDate).inDays + 1;

  int get peakHour {
    if (messagesByHour.isEmpty) return 0;
    return messagesByHour.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  Map<String, dynamic> toJson() => {
        'isGroup': isGroup,
        'people': people.map((p) => p.toJson()).toList(),
        'totalMessages': totalMessages,
        'firstDate': firstDate.toIso8601String(),
        'lastDate': lastDate.toIso8601String(),
        'activeDays': activeDays,
        'longestStreakDays': longestStreakDays,
        'messagesByHour':
            messagesByHour.map((k, v) => MapEntry(k.toString(), v)),
        'messagesByWeekday':
            messagesByWeekday.map((k, v) => MapEntry(k.toString(), v)),
        'mostActiveSenderName': mostActiveSenderName,
        'topEmojiOverall': topEmojiOverall,
        'totalEmojis': totalEmojis,
        'totalMedia': totalMedia,
        'busiestDayLabel': busiestDayLabel,
        'busiestDayCount': busiestDayCount,
        'firstSender': firstSender,
        'firstText': firstText,
        'firstDateTime': firstDateTime.toIso8601String(),
        'longestSender': longestSender,
        'longestText': longestText,
        'longestWords': longestWords,
      };

  factory ChatStats.fromJson(Map<String, dynamic> j) {
    Map<int, int> intMap(dynamic m) => (m as Map).map(
        (k, v) => MapEntry(int.parse(k.toString()), v as int));
    return ChatStats(
      isGroup: j['isGroup'] as bool,
      people: (j['people'] as List)
          .map((e) => PersonStats.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalMessages: j['totalMessages'] as int,
      firstDate: DateTime.parse(j['firstDate'] as String),
      lastDate: DateTime.parse(j['lastDate'] as String),
      activeDays: j['activeDays'] as int,
      longestStreakDays: j['longestStreakDays'] as int,
      messagesByHour: intMap(j['messagesByHour']),
      messagesByWeekday: intMap(j['messagesByWeekday']),
      mostActiveSenderName: j['mostActiveSenderName'] as String,
      topEmojiOverall: j['topEmojiOverall'] as String,
      totalEmojis: j['totalEmojis'] as int,
      totalMedia: j['totalMedia'] as int,
      busiestDayLabel: j['busiestDayLabel'] as String,
      busiestDayCount: j['busiestDayCount'] as int,
      firstSender: j['firstSender'] as String,
      firstText: j['firstText'] as String,
      firstDateTime: DateTime.parse(j['firstDateTime'] as String),
      longestSender: j['longestSender'] as String,
      longestText: j['longestText'] as String,
      longestWords: j['longestWords'] as int,
    );
  }

  /// Compact, privacy-conscious digest handed to the AI (no raw transcript,
  /// aside from the two short signature lines that make the read feel personal).
  Map<String, dynamic> toDigest(
      {String? subject, String? relationship, String? otherName}) {
    String? you;
    if (otherName != null && otherName.isNotEmpty && !isGroup) {
      for (final p in people) {
        if (p.name != otherName) {
          you = p.name;
          break;
        }
      }
    }
    return {
      if (subject != null) 'they_are': subject,
      if (relationship != null) 'relationship': relationship,
      if (otherName != null && otherName.isNotEmpty)
        'person_being_analyzed': otherName,
      if (you != null) 'you_the_app_user': you,
      if (sampleLines.isNotEmpty) 'message_samples': sampleLines,
      'is_group': isGroup,
      'total_messages': totalMessages,
      'span_days': spanDays,
      'active_days': activeDays,
      'longest_streak_days': longestStreakDays,
      'peak_hour': peakHour,
      'busiest_day': busiestDayLabel,
      'top_emoji': topEmojiOverall,
      'total_media': totalMedia,
      'first_message': {
        'sender': firstSender,
        'text': firstText.length > 120 ? firstText.substring(0, 120) : firstText,
      },
      'longest_message': {
        'sender': longestSender,
        'words': longestWords,
      },
      'people': people
          .map((p) => {
                'name': p.name,
                'messages': p.messages,
                'words': p.words,
                'avg_words_per_msg':
                    double.parse(p.avgWordsPerMsg.toStringAsFixed(1)),
                'emojis': p.emojis,
                'questions': p.questions,
                'laughs': p.laughs,
                'conversations_started': p.conversationsStarted,
                'avg_reply_minutes': p.avgReply?.inMinutes,
                'top_emojis': p.topEmojis.entries
                    .take(5)
                    .map((e) => '${e.key}:${e.value}')
                    .toList(),
                'top_words': p.topWords.take(8).toList(),
              })
          .toList(),
    };
  }
}
