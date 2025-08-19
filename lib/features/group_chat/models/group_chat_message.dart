import '../../chat/models/message_status.dart';

class GroupChatMessage {
  static const String _defaultCharacterId = 'user';
  static const String _defaultCharacterName = 'You';

  final String id;
  final String content;
  final String characterId; // ID of the character who sent this (or 'user')
  final String characterName; // Display name of the character
  final String? characterAvatarUrl; // Character's avatar/image URL
  final String? characterAvatarText; // Fallback avatar text (initials)
  final bool isUser;
  final DateTime timestamp;
  final MessageStatus status;
  final String? model; // AI model used for this response (if not user)
  final Map<String, dynamic>? metadata; // Additional message metadata

  GroupChatMessage({
    String? id,
    required this.content,
    String? characterId,
    String? characterName,
    this.characterAvatarUrl,
    String? characterAvatarText,
    required this.isUser,
    DateTime? timestamp,
    MessageStatus? status,
    this.model,
    this.metadata,
  }) : id = id ?? _generateId(),
       characterId = characterId ?? (isUser ? _defaultCharacterId : ''),
       characterName = characterName ?? (isUser ? _defaultCharacterName : 'Unknown'),
       characterAvatarText = characterAvatarText ?? _generateAvatarText(characterName ?? (isUser ? _defaultCharacterName : 'Unknown')),
       timestamp = timestamp ?? DateTime.now(),
       status = status ?? MessageStatus.sent,
       assert(content.isNotEmpty, 'Message content cannot be empty'),
       assert(isUser || characterId != null, 'Non-user messages must have a characterId');

  // Generate unique message ID
  static String _generateId() {
    return 'msg_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  // Generate avatar text from character name (first letter or initials)
  static String _generateAvatarText(String name) {
    if (name.isEmpty) return '?';
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    } else {
      return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'.toUpperCase();
    }
  }

  // Factory constructor for user messages
  factory GroupChatMessage.user({
    required String content,
    DateTime? timestamp,
    MessageStatus? status,
    Map<String, dynamic>? metadata,
  }) {
    return GroupChatMessage(
      content: content,
      isUser: true,
      timestamp: timestamp,
      status: status,
      metadata: metadata,
    );
  }

  // Factory constructor for character messages
  factory GroupChatMessage.character({
    required String content,
    required String characterId,
    required String characterName,
    String? characterAvatarUrl,
    String? characterAvatarText,
    DateTime? timestamp,
    MessageStatus? status,
    String? model,
    Map<String, dynamic>? metadata,
  }) {
    return GroupChatMessage(
      content: content,
      characterId: characterId,
      characterName: characterName,
      characterAvatarUrl: characterAvatarUrl,
      characterAvatarText: characterAvatarText,
      isUser: false,
      timestamp: timestamp,
      status: status,
      model: model,
      metadata: metadata,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'characterId': characterId,
      'characterName': characterName,
      'characterAvatarUrl': characterAvatarUrl,
      'characterAvatarText': characterAvatarText,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'model': model,
      'metadata': metadata,
    };
  }

  // JSON deserialization
  factory GroupChatMessage.fromJson(Map<String, dynamic> json) {
    try {
      // Validate required fields
      if (json['content'] == null || json['isUser'] == null) {
        throw FormatException('Missing required fields in message data');
      }

      // Parse timestamp safely
      DateTime timestamp;
      try {
        timestamp = DateTime.parse(json['timestamp'] as String);
      } catch (e) {
        timestamp = DateTime.now();
      }

      // Parse status safely
      MessageStatus status;
      try {
        status = MessageStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => MessageStatus.sent,
        );
      } catch (e) {
        status = MessageStatus.sent;
      }

      return GroupChatMessage(
        id: json['id'] as String?,
        content: json['content'] as String,
        characterId: json['characterId'] as String?,
        characterName: json['characterName'] as String?,
        characterAvatarUrl: json['characterAvatarUrl'] as String?,
        characterAvatarText: json['characterAvatarText'] as String?,
        isUser: json['isUser'] as bool,
        timestamp: timestamp,
        status: status,
        model: json['model'] as String?,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
    } catch (e) {
      throw FormatException('Invalid message data: $e');
    }
  }

  // Create a copy with updated fields
  GroupChatMessage copyWith({
    String? id,
    String? content,
    String? characterId,
    String? characterName,
    String? characterAvatarUrl,
    String? characterAvatarText,
    bool? isUser,
    DateTime? timestamp,
    MessageStatus? status,
    String? model,
    Map<String, dynamic>? metadata,
  }) {
    return GroupChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      characterId: characterId ?? this.characterId,
      characterName: characterName ?? this.characterName,
      characterAvatarUrl: characterAvatarUrl ?? this.characterAvatarUrl,
      characterAvatarText: characterAvatarText ?? this.characterAvatarText,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      model: model ?? this.model,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupChatMessage &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'GroupChatMessage{id: $id, content: ${content.length > 50 ? content.substring(0, 50) + '...' : content}, characterName: $characterName, isUser: $isUser, status: $status}';
  }
}