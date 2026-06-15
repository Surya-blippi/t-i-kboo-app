import 'package:intl/intl.dart';
import '../models/chat_message.dart';
import '../models/chat_stats.dart';

/// Turns parsed messages into ChatStats. Pure Dart, runs on-device.
class StatsEngine {
  // Matches most emoji (covers the common ranges people actually use).
  static final RegExp _emoji = RegExp(
    r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{1F1E6}-\u{1F1FF}\u{2764}\u{FE0F}]',
    unicode: true,
  );
  static final RegExp _laugh =
      RegExp(r'(haha|hehe|lol|lmao|lmfao|rofl|💀|😂|🤣)', caseSensitive: false);

  static const _stop = {
    'the', 'a', 'an', 'and', 'or', 'but', 'is', 'are', 'was', 'were', 'i',
    'you', 'u', 'me', 'my', 'we', 'to', 'of', 'in', 'on', 'it', 'so', 'for',
    'that', 'this', 'with', 'at', 'be', 'have', 'do', 'just', 'not', 'no',
    'yes', 'ok', 'okay', 'yeah', 'ya', 'im', 'its', 'he', 'she', 'they',
    'will', 'can', 'if', 'as', 'too', 'get', 'got', 'up', 'out', 'now',
    'omg', 'like', 'know', 'what', 'how', 'when', 'why', 'all', 'about',
  };

  static ChatStats compute(List<ChatMessage> all) {
    final msgs = all.where((m) => !m.isSystem).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (msgs.isEmpty) {
      throw const FormatException(
          "Couldn't find any messages. Make sure it's a WhatsApp .txt/.zip export.");
    }

    final names = <String>{};
    for (final m in msgs) {
      names.add(m.sender);
    }
    final isGroup = names.length > 2;

    final stats = <String, PersonStats>{
      for (final n in names) n: PersonStats(name: n),
    };
    final emojiTallies = <String, Map<String, int>>{
      for (final n in names) n: {},
    };
    final wordTallies = <String, Map<String, int>>{
      for (final n in names) n: {},
    };
    final emojiOverall = <String, int>{};

    final byHour = <int, int>{for (var h = 0; h < 24; h++) h: 0};
    final byWeekday = <int, int>{for (var d = 1; d <= 7; d++) d: 0};
    final byDay = <String, int>{};
    final activeDates = <String>{};

    int totalEmojis = 0;
    int totalMedia = 0;

    // First real (text) message = who broke the ice.
    final firstText = msgs.firstWhere((m) => !m.isMedia && m.text.trim().isNotEmpty,
        orElse: () => msgs.first);
    // Longest message by word count.
    ChatMessage longest = msgs.first;

    // reply latency accumulation
    final replyTotals = <String, Duration>{for (final n in names) n: Duration.zero};
    final replyCounts = <String, int>{for (final n in names) n: 0};

    final dfDay = DateFormat('yyyy-MM-dd');
    const gap = Duration(hours: 6); // new "conversation" threshold

    ChatMessage? prev;
    for (final m in msgs) {
      final s = stats[m.sender]!;
      s.messages++;
      byHour[m.timestamp.hour] = byHour[m.timestamp.hour]! + 1;
      byWeekday[m.timestamp.weekday] = byWeekday[m.timestamp.weekday]! + 1;
      final dayKey = dfDay.format(m.timestamp);
      byDay[dayKey] = (byDay[dayKey] ?? 0) + 1;
      activeDates.add(dayKey);

      if (m.isMedia) {
        s.media++;
        totalMedia++;
        prev = m;
        continue;
      }

      s.words += m.wordCount;
      if (m.wordCount > longest.wordCount) longest = m;
      if (m.text.contains('?')) s.questions++;
      if (_laugh.hasMatch(m.text)) s.laughs++;

      for (final e in _emoji.allMatches(m.text)) {
        final g = e.group(0)!;
        emojiTallies[m.sender]![g] = (emojiTallies[m.sender]![g] ?? 0) + 1;
        emojiOverall[g] = (emojiOverall[g] ?? 0) + 1;
        s.emojis++;
        totalEmojis++;
      }

      for (final w in m.text.toLowerCase().split(RegExp(r'[^a-z0-9]+'))) {
        if (w.length < 3 || _stop.contains(w)) continue;
        wordTallies[m.sender]![w] = (wordTallies[m.sender]![w] ?? 0) + 1;
      }

      // conversation starter + reply latency
      if (prev == null || m.timestamp.difference(prev.timestamp) > gap) {
        s.conversationsStarted++;
      } else if (prev.sender != m.sender) {
        final d = m.timestamp.difference(prev.timestamp);
        if (d < const Duration(hours: 3)) {
          replyTotals[m.sender] = replyTotals[m.sender]! + d;
          replyCounts[m.sender] = replyCounts[m.sender]! + 1;
        }
      }
      prev = m;
    }

    // finalize per-person top lists + avg reply
    for (final n in names) {
      final s = stats[n]!;
      final em = emojiTallies[n]!.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      s.topEmojis.addEntries(em.take(5));
      final wd = wordTallies[n]!.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      s.topWords.addAll(wd.take(8).map((e) => e.key));
      if (replyCounts[n]! > 0) {
        s.avgReply = Duration(
            seconds: replyTotals[n]!.inSeconds ~/ replyCounts[n]!);
      }
    }

    final people = stats.values.toList()
      ..sort((a, b) => b.messages.compareTo(a.messages));

    // longest streak of consecutive active days
    final sortedDates = activeDates.toList()..sort();
    int streak = sortedDates.isEmpty ? 0 : 1;
    int best = streak;
    for (var i = 1; i < sortedDates.length; i++) {
      final prevD = DateTime.parse(sortedDates[i - 1]);
      final curD = DateTime.parse(sortedDates[i]);
      if (curD.difference(prevD).inDays == 1) {
        streak++;
        if (streak > best) best = streak;
      } else {
        streak = 1;
      }
    }

    // Build a representative sample of real lines for the AI to quote from.
    // Evenly spaced across the timeline, capped for token budget + privacy.
    final textMsgs = msgs
        .where((m) => !m.isMedia && m.text.trim().isNotEmpty)
        .toList();
    const maxSample = 220;
    final sampleLines = <String>[];
    if (textMsgs.isNotEmpty) {
      final step =
          textMsgs.length <= maxSample ? 1 : (textMsgs.length / maxSample).ceil();
      for (var i = 0; i < textMsgs.length; i += step) {
        final m = textMsgs[i];
        final t = m.text.trim().replaceAll('\n', ' ');
        final clipped = t.length > 200 ? '${t.substring(0, 200)}…' : t;
        sampleLines.add('${m.sender}: $clipped');
      }
    }

    final topEmojiOverall = emojiOverall.isEmpty
        ? '🤐'
        : (emojiOverall.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .first
            .key;

    String busiestLabel = '—';
    int busiestCount = 0;
    if (byDay.isNotEmpty) {
      final top = byDay.entries.reduce((a, b) => a.value >= b.value ? a : b);
      busiestLabel = DateFormat('MMM d, yyyy').format(DateTime.parse(top.key));
      busiestCount = top.value;
    }

    return ChatStats(
      isGroup: isGroup,
      people: people,
      totalMessages: msgs.length,
      firstDate: msgs.first.timestamp,
      lastDate: msgs.last.timestamp,
      activeDays: activeDates.length,
      longestStreakDays: best,
      messagesByHour: byHour,
      messagesByWeekday: byWeekday,
      mostActiveSenderName: people.first.name,
      topEmojiOverall: topEmojiOverall,
      totalEmojis: totalEmojis,
      totalMedia: totalMedia,
      busiestDayLabel: busiestLabel,
      busiestDayCount: busiestCount,
      firstSender: firstText.sender,
      firstText: firstText.text,
      firstDateTime: firstText.timestamp,
      longestSender: longest.sender,
      longestText: longest.text,
      longestWords: longest.wordCount,
      sampleLines: sampleLines,
    );
  }
}
