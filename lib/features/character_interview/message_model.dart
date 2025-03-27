// lib/features/character_interview/message_model.dart
class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? imageUrl;
  final bool isLoading;
  
  Message({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.imageUrl,
    this.isLoading = false,
  }) : timestamp = timestamp ?? DateTime.now();
}
