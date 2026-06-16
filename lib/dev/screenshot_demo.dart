import '../models/ai_analysis.dart';
import '../models/chat_stats.dart';
import '../services/chat_parser.dart';
import '../services/stats_engine.dart';

/// Sample data used ONLY when built with --dart-define=SCREENSHOT=true,
/// so we can capture polished App Store screenshots without a real chat,
/// network, or purchase. Not referenced in normal builds.
class ScreenshotDemo {
  static const bool enabled = bool.fromEnvironment('SCREENSHOT');
  static const otherName = 'Sam';

  static const _sampleChat = '''
[12/03/2025, 9:42:13 PM] Sam: heyy stranger 👀
[12/03/2025, 9:43:01 PM] Alex: omg hiii
[12/03/2025, 9:43:30 PM] Sam: i was literally just thinking about you 🙈
[12/03/2025, 9:45:10 PM] Alex: stoppp you always say that 😂
[12/03/2025, 9:46:00 PM] Sam: because it's true 🙄
[13/03/2025, 8:01:00 AM] Sam: good morning ☀️
[13/03/2025, 10:22:00 AM] Alex: morning! sorry was asleep
[13/03/2025, 7:30:00 PM] Alex: wanna get food this weekend?
[13/03/2025, 7:55:00 PM] Sam: maybe haha depends
[14/03/2025, 11:10:00 PM] Sam: i'll call you tomorrow ok 🥺
[15/03/2025, 9:00:00 PM] Sam: so about that food 👀
[15/03/2025, 9:02:00 PM] Alex: HAHA i knew you'd come back
[15/03/2025, 9:05:00 PM] Sam: shut up 😂 pick a place
[15/03/2025, 9:06:00 PM] Alex: that ramen spot? 🍜
[15/03/2025, 9:07:00 PM] Sam: omg yes it's a date 💞
''';

  static ChatStats stats() => StatsEngine.compute(ChatParser.parse(_sampleChat));

  static const analysis = AiAnalysis(
    vibeTitle: 'Sneaky Flirt Alert',
    vibeEmoji: '😏',
    summary:
        'Sam runs hot — quick replies, soft launches, and emojis doing heavy lifting. This is a crush in slow motion.',
    roast:
        'You two have texted "we should hang" 6 times and actually hung out zero. The situationship is mathing but the calendar is not. 💀',
    energyMatch:
        'Sam brings 60% of the energy and most of the 🙈 — you play it cool but the read receipts say otherwise.',
    whoTextsFirst:
        'Sam breaks the ice 8 times to your 4. Certified double-texter (affectionate).',
    attachmentStyle:
        'Sam reads anxious-preoccupied — fast replies, misses you out loud. You lean secure-with-a-side-of-avoidant.',
    firstTextRead:
        'Sam opened with "heyy stranger 👀" — the boldest move in the textbook. Respect.',
    greenFlags: [
      FlagItem(flag: 'Initiates and means it', quote: 'i was literally just thinking about you 🙈', sender: 'Sam'),
      FlagItem(flag: 'Plans real-life dates', quote: 'so about that food 👀', sender: 'Sam'),
      FlagItem(flag: 'Soft and sweet', quote: "i'll call you tomorrow ok 🥺", sender: 'Sam'),
    ],
    redFlags: [
      FlagItem(flag: 'Commitment-shy on plans', quote: 'maybe haha depends', sender: 'Sam'),
      FlagItem(flag: 'Deflects with a joke', quote: 'shut up 😂 pick a place', sender: 'Sam'),
    ],
    superlatives: [
      AiSuperlative(emoji: '🗣️', title: 'First-Move Royalty', person: 'Sam', reason: 'Started 8 of the convos'),
      AiSuperlative(emoji: '⏱️', title: 'Speed Texter', person: 'Sam', reason: 'Avg reply under 3 min'),
      AiSuperlative(emoji: '🧊', title: 'Mr Cool', person: 'Alex', reason: 'Plays it suspiciously chill'),
    ],
    vibeScore: 84,
  );
}
