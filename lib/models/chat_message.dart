/// A single parsed line from a WhatsApp export.
class ChatMessage {
  final DateTime timestamp;
  final String sender;
  final String text;
  final bool isMedia; // <Media omitted> / <attached: ...>
  final bool isSystem; // join/leave/encryption notices etc.

  const ChatMessage({
    required this.timestamp,
    required this.sender,
    required this.text,
    this.isMedia = false,
    this.isSystem = false,
  });

  int get wordCount =>
      text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
}
