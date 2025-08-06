enum MessageStatus {
  sending,
  sent,
  error,
  typing,
  characterTyping,
  multipleTyping,
  characterResponding,
  queuedForResponse,
  delivered,
  pending,
}

extension MessageStatusExtension on MessageStatus {
  String get displayText {
    switch (this) {
      case MessageStatus.sending:
        return 'Sending...';
      case MessageStatus.sent:
        return 'Sent';
      case MessageStatus.error:
        return 'Error';
      case MessageStatus.typing:
        return 'Typing...';
      case MessageStatus.characterTyping:
        return 'Character typing...';
      case MessageStatus.multipleTyping:
        return 'Characters typing...';
      case MessageStatus.characterResponding:
        return 'Responding...';
      case MessageStatus.queuedForResponse:
        return 'Queued...';
      case MessageStatus.delivered:
        return 'Delivered';
      case MessageStatus.pending:
        return 'Pending';
    }
  }
}