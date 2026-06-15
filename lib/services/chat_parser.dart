import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import '../models/chat_message.dart';

/// Parses a WhatsApp chat export. Handles both major formats:
///   iOS:     [15/01/2023, 9:42:13 PM] John: Hey
///   Android: 15/01/2023, 21:42 - John: Hey
/// Also unwraps .zip exports and stitches multi-line messages back together.
class ChatParser {
  // iOS: [date, time] sender: message   (brackets, optional U+200E marks)
  static final RegExp _iosLine = RegExp(
    r'^‎?\[(\d{1,2}[\/.]\d{1,2}[\/.]\d{2,4}),?\s+'
    r'(\d{1,2}:\d{2}(?::\d{2})?)\s*([AaPp][Mm])?\]\s*([^:]+?):\s?(.*)$',
  );

  // Android: date, time - sender: message
  static final RegExp _androidLine = RegExp(
    r'^(\d{1,2}[\/.]\d{1,2}[\/.]\d{2,4}),?\s+'
    r'(\d{1,2}:\d{2}(?::\d{2})?)\s*([AaPp][Mm])?\s*-\s+([^:]+?):\s?(.*)$',
  );

  // Android system line (no sender, e.g. "... created group")
  static final RegExp _androidSystem = RegExp(
    r'^(\d{1,2}[\/.]\d{1,2}[\/.]\d{2,4}),?\s+'
    r'(\d{1,2}:\d{2}(?::\d{2})?)\s*([AaPp][Mm])?\s*-\s+(.*)$',
  );

  // Invisible formatting characters WhatsApp sprinkles in: LRM/RLM, embeddings,
  // isolates, zero-width space, BOM.
  static final RegExp _formatMarks =
      RegExp(r'[\u200b\u200e\u200f\u202a-\u202e\u2066-\u2069\ufeff]');

  static final RegExp _mediaMarker = RegExp(
    r'<Media omitted>|<attached:|image omitted|video omitted|'
    r'audio omitted|sticker omitted|GIF omitted|document omitted|\.vcf \(file attached\)',
    caseSensitive: false,
  );

  /// Decode raw bytes of an export. If it's a zip, find the .txt inside.
  static String extractText(Uint8List bytes, String fileName) {
    if (fileName.toLowerCase().endsWith('.zip')) {
      final archive = ZipDecoder().decodeBytes(bytes);
      for (final f in archive) {
        if (f.isFile && f.name.toLowerCase().endsWith('.txt')) {
          return utf8.decode(f.content as List<int>, allowMalformed: true);
        }
      }
      throw const FormatException('No .txt chat file found inside the zip.');
    }
    return utf8.decode(bytes, allowMalformed: true);
  }

  /// Pulls the contact name out of a WhatsApp export filename:
  ///   "WhatsApp Chat with Matt.txt"        -> "Matt"   (Android)
  ///   "WhatsApp Chat - Matt.zip"           -> "Matt"   (iOS)
  ///   "tikboo_1718_WhatsApp Chat - Matt.zip" -> "Matt" (after our iOS copy)
  /// Returns null for generic names like "_chat.txt" (share sheet strips it).
  static String? contactNameFromFileName(String fileName) {
    var n = fileName;
    final slash = n.lastIndexOf('/');
    if (slash != -1) n = n.substring(slash + 1);
    n = n.replaceAll(RegExp(r'\.(txt|zip)$', caseSensitive: false), '');
    n = n.replaceFirst(RegExp(r'^tikboo_\d+_'), '');
    final m = RegExp(r'whatsapp chat (?:with|-)\s*(.+)$', caseSensitive: false)
        .firstMatch(n);
    if (m == null) return null;
    var name = m.group(1)!.trim();
    name = name.replaceAll(RegExp(r'\s*\(\d+\)$'), '').trim();
    if (name.isEmpty || name.toLowerCase() == '_chat') return null;
    return name;
  }

  /// Best guess at "the other person" in a 1:1 chat. Prefers the participant
  /// named in the export filename; otherwise falls back to the busiest sender.
  static String resolveOtherPerson(
      List<String> participants, String? fileName) {
    if (participants.isEmpty) return 'them';
    if (participants.length == 1) return participants.first;
    final contact =
        fileName == null ? null : contactNameFromFileName(fileName);
    if (contact != null) {
      final c = contact.toLowerCase();
      for (final p in participants) {
        final pl = p.toLowerCase();
        if (pl == c || pl.contains(c) || c.contains(pl)) return p;
      }
    }
    return participants.first; // fallback guess
  }

  static List<ChatMessage> parse(String raw) {
    final lines = const LineSplitter().convert(raw);
    final messages = <ChatMessage>[];

    DateTime? curTime;
    String? curSender;
    final buffer = StringBuffer();
    bool curIsSystem = false;

    void flush() {
      if (curTime == null) return;
      // WhatsApp injects invisible bidi/zero-width marks (esp. before system
      // notices) — strip them so content checks and previews are clean.
      final text =
          buffer.toString().replaceAll(_formatMarks, '').trim();
      final isMedia = _mediaMarker.hasMatch(text);
      messages.add(ChatMessage(
        timestamp: curTime,
        sender: curSender ?? 'System',
        text: isMedia ? '' : text,
        isMedia: isMedia,
        isSystem: curIsSystem || curSender == null || _isSystemContent(text),
      ));
    }

    for (final line in lines) {
      final ios = _iosLine.firstMatch(line);
      final android = ios == null ? _androidLine.firstMatch(line) : null;
      final match = ios ?? android;

      if (match != null) {
        flush();
        buffer.clear();
        curTime = _buildDate(
          match.group(1)!,
          match.group(2)!,
          match.group(3),
        );
        curSender = match.group(4)!.trim();
        curIsSystem = false;
        buffer.write(match.group(5) ?? '');
      } else {
        // Possibly an Android system line (date - text, no colon sender)
        final sys = _androidSystem.firstMatch(line);
        if (sys != null && ios == null) {
          flush();
          buffer.clear();
          curTime = _buildDate(sys.group(1)!, sys.group(2)!, sys.group(3));
          curSender = null;
          curIsSystem = true;
          buffer.write(sys.group(4) ?? '');
        } else if (curTime != null) {
          // continuation of previous message
          buffer.write('\n');
          buffer.write(line);
        }
      }
    }
    flush();
    return messages;
  }

  /// WhatsApp injects notices (encryption banner, business-contact cards,
  /// deleted messages, missed calls, group events). In business/contact chats
  /// these get attributed to a sender, so we have to catch them by content.
  static bool _isSystemContent(String text) {
    if (text.isEmpty) return true;
    final t = text.trim().toLowerCase();

    const startsWith = [
      'messages and calls are end-to-end encrypted',
      'messages to this chat and calls are now secured',
      'this business uses a secure service from meta',
      'this business works with',
      'you blocked this business',
      'you unblocked this business',
      'waiting for this message',
      'you turned on disappearing messages',
      'you turned off disappearing messages',
      'disappearing messages were turned',
      'this message was deleted',
      'you deleted this message',
      'missed voice call',
      'missed video call',
      'missed group voice call',
      'missed group video call',
    ];
    for (final s in startsWith) {
      if (t.startsWith(s)) return true;
    }

    const contains = [
      'security code with',
      'changed their phone number',
      'changed to a new number',
      "you're now an admin",
      'tap to learn more',
    ];
    for (final c in contains) {
      if (t.contains(c)) return true;
    }

    // Business-contact card: "<Name> is a contact."
    if (t.endsWith('is a contact') || t.endsWith('is a contact.')) return true;

    return false;
  }

  static DateTime _buildDate(String date, String time, String? ampm) {
    final dParts = date.split(RegExp(r'[\/.]'));
    int a = int.parse(dParts[0]);
    int b = int.parse(dParts[1]);
    int year = int.parse(dParts[2]);
    if (year < 100) year += 2000;

    // Disambiguate D/M vs M/D: if first part > 12 it must be the day.
    int day, month;
    if (a > 12) {
      day = a;
      month = b;
    } else if (b > 12) {
      month = a;
      day = b;
    } else {
      // Ambiguous — default to day/month (most of the world + iOS locale).
      day = a;
      month = b;
    }

    final tParts = time.split(':');
    int hour = int.parse(tParts[0]);
    int minute = int.parse(tParts[1]);
    int second = tParts.length > 2 ? int.parse(tParts[2]) : 0;

    if (ampm != null) {
      final pm = ampm.toLowerCase() == 'pm';
      if (pm && hour < 12) hour += 12;
      if (!pm && hour == 12) hour = 0;
    }
    return DateTime(year, month, day, hour, minute, second);
  }
}
