import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ai_analysis.dart';
import '../models/chat_context.dart';
import '../models/chat_stats.dart';

/// Generates the AI report via tikboo's own backend (Vercel), which runs
/// Google Gemini server-side. This keeps the AI key off the device entirely.
class AiService {
  // tikboo web backend (Gemini-powered). Same endpoint the web app uses.
  static const String _endpoint = 'https://tikbooapp.vercel.app/api/analyze';

  Future<AiAnalysis> analyze(ChatStats stats, {ChatContext? context}) async {
    final digest = stats.toDigest(
      subject: context?.subjectLabel,
      relationship: context?.relationship,
      otherName: context?.otherName,
    );
    String? you;
    if (context != null && context.otherName.isNotEmpty && !stats.isGroup) {
      for (final p in stats.people) {
        if (p.name != context.otherName) {
          you = p.name;
          break;
        }
      }
    }

    Object? lastError;
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        final res = await http
            .post(
              Uri.parse(_endpoint),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'digest': digest, 'you': you}),
            )
            .timeout(const Duration(seconds: 60));

        if (res.statusCode == 200) {
          final body =
              jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
          final analysis = body['analysis'];
          if (analysis is Map<String, dynamic>) {
            return AiAnalysis.fromApi(analysis);
          }
          lastError = 'Unexpected response.';
        } else if (res.statusCode == 429 || res.statusCode == 503) {
          lastError = 'The AI is busy — try again in a moment.';
          await Future.delayed(Duration(milliseconds: 1000 * attempt));
          continue;
        } else {
          lastError = 'Analysis failed (${res.statusCode}).';
        }
      } catch (e) {
        lastError = 'Network hiccup — check your connection and retry.';
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
    throw AiException(lastError?.toString() ?? 'Could not get a read. Try again.');
  }
}

class AiException implements Exception {
  final String message;
  const AiException(this.message);
  @override
  String toString() => message;
}
