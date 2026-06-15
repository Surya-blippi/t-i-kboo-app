import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ai_analysis.dart';
import '../models/chat_context.dart';
import '../models/chat_stats.dart';

/// Talks to OpenRouter's chat completions endpoint using a free model.
/// We send only an aggregate digest (no raw transcript) and ask for JSON.
class OpenRouterService {
  static const _endpoint =
      'https://openrouter.ai/api/v1/chat/completions';

  final String apiKey;
  final String model;

  OpenRouterService({required this.apiKey, required this.model});

  Future<AiAnalysis> analyze(ChatStats stats, {ChatContext? context}) async {
    final digest = const JsonEncoder.withIndent('  ').convert(
        stats.toDigest(
            subject: context?.subjectLabel,
            relationship: context?.relationship,
            otherName: context?.otherName));
    final names = stats.people.map((p) => p.name).join(', ');

    const system = '''
You are tikboo — a witty genz best friend who reads group chats and DMs for the vibe.
You get a JSON digest of chat statistics PLUS "message_samples" (a sample of real lines as "Sender: text"). Read between the numbers AND quote the receipts.
The digest may include "person_being_analyzed" (the person the app user wants read) and "you_the_app_user" (the app user themselves) — address the app user as "you" and focus the juicy read on the other person.
The digest may include "they_are" (the other person's gender) and "relationship" (e.g. Crush, Situationship, Ex). TAILOR the read to that relationship — a Crush read should hunt for interest signals and rizz; an Ex read should be about closure and patterns; a Friend read should be about loyalty and chaos.
Tone: playful, hype, lightly roasting but NEVER cruel, inclusive. Use genz slang naturally (lowkey, no cap, rizz, the math is mathing, ick, green/beige/red flag) but don't overdo it.
Refer to people by their actual names from the digest.
Return STRICT JSON only, no markdown, no commentary, matching this exact shape:
{
  "vibe_title": "short punchy 2-4 word title for this chat",
  "vibe_emoji": "one emoji",
  "summary": "1-2 sentences reading the dynamic, referencing the relationship type",
  "roast": "2-3 sentences of loving roast based on the stats",
  "energy_match": "1 sentence on who brings more energy and how balanced it is",
  "who_texts_first": "1 sentence on who starts convos / double texts more, with the numbers",
  "attachment_style": "1-2 sentences reading each person's texting attachment style (anxious/avoidant/secure-coded) from reply speed + who initiates",
  "first_text_read": "1 witty sentence reacting to who broke the ice and what the first message was",
  "green_flags": [{"flag":"short positive observation","quote":"a REAL message from message_samples that backs it, copied exactly","sender":"who said it"}],
  "red_flags": [{"flag":"short cheeky red flag (keep it light)","quote":"a REAL message from message_samples, copied exactly","sender":"who said it"}],
  "superlatives": [
    {"emoji":"🏆","title":"award name","person":"name","reason":"why, short"}
  ],
  "vibe_score": 0-100
}
CRITICAL: Both green_flags AND red_flags must be about "person_being_analyzed" ONLY — judge THEIR behavior, never the app user's. Every flag's "sender" MUST be person_being_analyzed, and every "quote" MUST be a message THEY sent. Never flag or quote "you_the_app_user".
Give 3 green flags and 2-3 red flags. For EACH flag, quote a real message verbatim from message_samples sent by person_being_analyzed (keep the quote short, under ~120 chars). If genuinely no fitting line from them exists, set quote to "".
Give 3-4 superlatives. Keep every string tight and screenshot-able.
''';

    final user = '''
Here is the chat digest. People: $names.
Analyze it and return the JSON.

$digest
''';

    final payload = jsonEncode({
      'model': model,
      'temperature': 0.9,
      'response_format': {'type': 'json_object'},
      'messages': [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': user},
      ],
    });

    // Free models occasionally rate-limit (429) or emit slightly malformed
    // JSON. Both are transient, so we retry a few times before giving up.
    const maxAttempts = 4;
    Object? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final res = await http
            .post(
              Uri.parse(_endpoint),
              headers: {
                'Authorization': 'Bearer $apiKey',
                'Content-Type': 'application/json',
                'HTTP-Referer': 'https://tikboo.app',
                'X-Title': 'tikboo',
              },
              body: payload,
            )
            .timeout(const Duration(seconds: 60));

        if (res.statusCode == 429) {
          lastError = const OpenRouterException(
              'Rate limited — free models are popular. Wait a sec and retry.');
          await Future.delayed(Duration(milliseconds: 1200 * attempt));
          continue;
        }
        if (res.statusCode != 200) {
          throw OpenRouterException(_friendlyError(res.statusCode, res.body));
        }

        final body =
            jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final content = body['choices']?[0]?['message']?['content'];
        if (content == null || content.toString().trim().isEmpty) {
          lastError = const OpenRouterException('The model sent back nothing.');
          continue; // re-sample
        }

        final parsed = _extractJson(content.toString());
        _dropFlagsFromUser(parsed, stats, context);
        return AiAnalysis.fromJson(parsed);
      } on OpenRouterException {
        rethrow; // hard errors (bad key, paid model) — don't retry
      } catch (e) {
        // network blip or malformed JSON — re-sample
        lastError = e;
        await Future.delayed(Duration(milliseconds: 400 * attempt));
      }
    }
    throw OpenRouterException(lastError is OpenRouterException
        ? lastError.message
        : 'Couldn’t get a clean read after a few tries. Tap retry or switch models in Settings.');
  }

  /// Safety net: flags must judge the OTHER person, so drop any flag the model
  /// attributed to the app user. Won't empty a list entirely (keeps at least
  /// what the model gave if everything would be removed).
  static void _dropFlagsFromUser(
      Map<String, dynamic> parsed, ChatStats stats, ChatContext? context) {
    if (context == null || context.otherName.isEmpty || stats.isGroup) return;
    String? you;
    for (final p in stats.people) {
      if (p.name != context.otherName) {
        you = p.name;
        break;
      }
    }
    if (you == null) return;
    final youLower = you.toLowerCase().trim();

    void filter(String key) {
      final list = parsed[key];
      if (list is! List) return;
      final kept = list.where((e) {
        if (e is! Map) return true;
        final sender = (e['sender'] ?? '').toString().toLowerCase().trim();
        return sender != youLower;
      }).toList();
      if (kept.isNotEmpty) parsed[key] = kept;
    }

    filter('red_flags');
    filter('green_flags');
  }

  /// Models sometimes wrap JSON in prose or ```fences``` — dig it out.
  static Map<String, dynamic> _extractJson(String raw) {
    var s = raw.trim();
    s = s.replaceAll(RegExp(r'^```(json)?', multiLine: true), '');
    s = s.replaceAll('```', '');
    final start = s.indexOf('{');
    final end = s.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      s = s.substring(start, end + 1);
    }
    // Strip trailing commas before } or ] — a frequent small-model quirk.
    s = s.replaceAll(RegExp(r',\s*([}\]])'), r'$1');
    return jsonDecode(s) as Map<String, dynamic>;
  }

  static String _friendlyError(int code, String body) {
    switch (code) {
      case 401:
        return 'That API key got rejected. Double-check it in Settings.';
      case 402:
        return 'This model needs credits. Pick a :free model in Settings.';
      case 429:
        return 'Rate limited — free models are popular. Wait a sec and retry.';
      default:
        return 'OpenRouter error ($code). Try another free model.';
    }
  }
}

class OpenRouterException implements Exception {
  final String message;
  const OpenRouterException(this.message);
  @override
  String toString() => message;
}
