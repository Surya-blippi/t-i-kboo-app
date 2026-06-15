import 'package:flutter_test/flutter_test.dart';

import 'package:tikboo/services/chat_parser.dart';
import 'package:tikboo/services/stats_engine.dart';

void main() {
  test('parses iOS-format export and computes stats', () {
    const raw = '''
[12/01/2024, 9:42:13 PM] Alex: hey hey 😂
[12/01/2024, 9:43:01 PM] Sam: omg hii
[12/01/2024, 9:43:30 PM] Alex: wanna get food later?
[13/01/2024, 8:00:00 AM] Sam: yes!! 😂😂
''';
    final msgs = ChatParser.parse(raw);
    expect(msgs.length, 4);
    expect(msgs.first.sender, 'Alex');

    final stats = StatsEngine.compute(msgs);
    expect(stats.isGroup, false);
    expect(stats.totalMessages, 4);
    expect(stats.people.length, 2);
    expect(stats.topEmojiOverall, '😂');
  });

  test('filters WhatsApp system notices (encryption, contact cards)', () {
    // ‎ is the invisible LRM mark WhatsApp prepends to system notices.
    const lrm = '‎';
    const raw = '''
[31/07/2025, 7:48:00 PM] Classic Furniture Sofa: ${lrm}Messages and calls are end-to-end encrypted. Only people in this chat can read, listen to, or share them.
[31/07/2025, 7:48:01 PM] Classic Furniture Sofa: ${lrm}Classic Furniture Sofa is a contact.
[31/07/2025, 7:49:00 PM] Alex: yo is the sofa still available?
[31/07/2025, 7:50:00 PM] Classic Furniture Sofa: Yes! It is.
''';
    final msgs = ChatParser.parse(raw);
    final stats = StatsEngine.compute(msgs);
    // System notices excluded → first real message is Alex's question.
    expect(stats.firstSender, 'Alex');
    expect(stats.firstText.contains('sofa'), true);
    expect(stats.totalMessages, 2);
  });

  test('identifies the other person from the export filename', () {
    final people = ['Abhay', 'Matt'];
    expect(ChatParser.resolveOtherPerson(people, 'WhatsApp Chat with Matt.txt'),
        'Matt');
    expect(ChatParser.resolveOtherPerson(people, 'WhatsApp Chat - Matt.zip'),
        'Matt');
    expect(
        ChatParser.resolveOtherPerson(
            people, 'tikboo_1718_WhatsApp Chat - Matt.zip'),
        'Matt');
    // Generic share-sheet name → falls back (no crash).
    expect(ChatParser.contactNameFromFileName('_chat.txt'), isNull);
  });

  test('parses Android-format export', () {
    const raw = '''
12/01/2024, 21:42 - Alex: hey
12/01/2024, 21:43 - Sam: yo whats up?
''';
    final msgs = ChatParser.parse(raw);
    expect(msgs.length, 2);
    expect(msgs[1].sender, 'Sam');
    expect(msgs[1].text.contains('?'), true);
  });
}
