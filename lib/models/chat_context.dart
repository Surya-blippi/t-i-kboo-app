/// User-supplied context about the chat, captured before analysis.
/// Feeds the AI so the read is tailored (a Crush read != an Ex read).
enum Subject { girl, guy, group }

class ChatContext {
  final Subject subject;
  final String relationship;
  final String otherName; // the person being analyzed (not the device owner)

  const ChatContext({
    required this.subject,
    required this.relationship,
    this.otherName = '',
  });

  String get subjectLabel => switch (subject) {
        Subject.girl => 'a girl',
        Subject.guy => 'a guy',
        Subject.group => 'a group',
      };
}
