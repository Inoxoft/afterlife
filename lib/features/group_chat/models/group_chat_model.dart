import 'dart:math';
import 'package:flutter/foundation.dart';
import 'group_chat_message.dart';

class GroupChatModel {
  static const String _groupIdPrefix = 'group_';
  static const int _minCharacters = 2;
  static const int _maxCharacters = 6;

  final String id;
  final String name;
  final List<String> characterIds; // Mix of user and famous character IDs
  final List<GroupChatMessage> messages;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final String? description; // Optional group description
  final Map<String, dynamic>? settings; // Group-specific settings
  final Map<String, dynamic>? metadata; // Additional group metadata

  GroupChatModel({
    String? id,
    required this.name,
    required this.characterIds,
    List<GroupChatMessage>? messages,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    this.description,
    this.settings,
    this.metadata,
  }) : id = id ?? _generateId(),
       messages = messages ?? [],
       createdAt = createdAt ?? DateTime.now(),
       lastMessageAt = lastMessageAt ?? DateTime.now() {
    
    print('🔧 [GroupChatModel] Constructor called with:');
    print('🔧 [GroupChatModel] - name: "$name"');
    print('🔧 [GroupChatModel] - characterIds: $characterIds (count: ${characterIds.length})');
    print('🔧 [GroupChatModel] - description: "$description"');
    print('🔧 [GroupChatModel] - Generated ID: ${this.id}');
    
    // Validation with detailed logging
    if (name.isEmpty) {
      print('❌ [GroupChatModel] Validation failed: Group name is empty');
      throw ArgumentError('Group name cannot be empty');
    }
    
    if (characterIds.length < _minCharacters) {
      print('❌ [GroupChatModel] Validation failed: Too few characters (${characterIds.length} < $_minCharacters)');
      throw ArgumentError('Group must have at least $_minCharacters characters');
    }
    
    if (characterIds.length > _maxCharacters) {
      print('❌ [GroupChatModel] Validation failed: Too many characters (${characterIds.length} > $_maxCharacters)');
      throw ArgumentError('Group cannot have more than $_maxCharacters characters');
    }
    
    if (characterIds.toSet().length != characterIds.length) {
      print('❌ [GroupChatModel] Validation failed: Duplicate character IDs found');
      print('❌ [GroupChatModel] - Original: $characterIds');
      print('❌ [GroupChatModel] - Unique: ${characterIds.toSet().toList()}');
      throw ArgumentError('Character IDs must be unique');
    }
    
    print('✅ [GroupChatModel] Validation passed successfully');
    print('✅ [GroupChatModel] GroupChatModel created with ID: ${this.id}');
  }

  // Generate unique group ID
  static String _generateId() {
    return '${_groupIdPrefix}${DateTime.now().millisecondsSinceEpoch}';
  }

  // Get character count
  int get characterCount => characterIds.length;

  // Get message count
  int get messageCount => messages.length;

  // Get last message
  GroupChatMessage? get lastMessage => messages.isNotEmpty ? messages.last : null;

  // Get last user message
  GroupChatMessage? get lastUserMessage => 
      messages.where((m) => m.isUser).isNotEmpty ? 
      messages.where((m) => m.isUser).last : null;

  // Get last character message
  GroupChatMessage? get lastCharacterMessage => 
      messages.where((m) => !m.isUser).isNotEmpty ? 
      messages.where((m) => !m.isUser).last : null;

  // Check if group has any messages
  bool get hasMessages => messages.isNotEmpty;

  // Check if group is active (has recent activity)
  bool get isActive {
    final now = DateTime.now();
    final difference = now.difference(lastMessageAt);
    return difference.inHours < 24; // Active if last message within 24 hours
  }

  // Get unique character IDs who have sent messages
  Set<String> get activeCharacterIds {
    return messages
        .where((m) => !m.isUser)
        .map((m) => m.characterId)
        .toSet();
  }

  // Get character IDs who haven't sent messages yet
  Set<String> get inactiveCharacterIds {
    final activeIds = activeCharacterIds;
    return characterIds.where((id) => !activeIds.contains(id)).toSet();
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'characterIds': characterIds,
      'messages': messages.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastMessageAt': lastMessageAt.toIso8601String(),
      'description': description,
      'settings': settings,
      'metadata': metadata,
    };
  }

  // JSON deserialization
  factory GroupChatModel.fromJson(Map<String, dynamic> json) {
    try {
      // Validate required fields
      if (json['id'] == null || 
          json['name'] == null || 
          json['characterIds'] == null) {
        throw FormatException('Missing required fields in group chat data');
      }

      // Parse timestamps safely
      DateTime createdAt;
      try {
        createdAt = DateTime.parse(json['createdAt'] as String);
      } catch (e) {
        createdAt = DateTime.now();
      }

      DateTime lastMessageAt;
      try {
        lastMessageAt = DateTime.parse(json['lastMessageAt'] as String);
      } catch (e) {
        lastMessageAt = createdAt;
      }

      // Parse character IDs safely
      List<String> characterIds;
      try {
        characterIds = List<String>.from(json['characterIds']);
      } catch (e) {
        throw FormatException('Invalid character IDs format');
      }

      // Parse messages safely
      List<GroupChatMessage> messages = [];
      try {
        if (json['messages'] != null) {
          final messagesList = json['messages'] as List;
          messages = messagesList
              .map((m) => GroupChatMessage.fromJson(m as Map<String, dynamic>))
              .toList();
        }
      } catch (e) {
        if (kDebugMode) {
          print('Warning: Could not parse messages for group ${json['id']}: $e');
        }
        // Continue with empty messages list
      }

      return GroupChatModel(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Unnamed Group',
        characterIds: characterIds,
        messages: messages,
        createdAt: createdAt,
        lastMessageAt: lastMessageAt,
        description: json['description']?.toString(),
        settings: json['settings'] as Map<String, dynamic>?,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
    } catch (e) {
      throw FormatException('Invalid group chat data: $e');
    }
  }

  // Add a message to the group
  GroupChatModel addMessage(GroupChatMessage message) {
    if (message.content.isEmpty) {
      throw ArgumentError('Message content cannot be empty');
    }

    final newMessages = List<GroupChatMessage>.from(messages)..add(message);
    
    return GroupChatModel(
      id: id,
      name: name,
      characterIds: characterIds,
      messages: newMessages,
      createdAt: createdAt,
      lastMessageAt: message.timestamp,
      description: description,
      settings: settings,
      metadata: metadata,
    );
  }

  // Add multiple messages to the group
  GroupChatModel addMessages(List<GroupChatMessage> newMessages) {
    if (newMessages.isEmpty) return this;

    final allMessages = List<GroupChatMessage>.from(messages)..addAll(newMessages);
    final latestTimestamp = newMessages.map((m) => m.timestamp).reduce(
      (a, b) => a.isAfter(b) ? a : b,
    );

    return GroupChatModel(
      id: id,
      name: name,
      characterIds: characterIds,
      messages: allMessages,
      createdAt: createdAt,
      lastMessageAt: latestTimestamp,
      description: description,
      settings: settings,
      metadata: metadata,
    );
  }

  // Remove a message by ID
  GroupChatModel removeMessage(String messageId) {
    final newMessages = messages.where((m) => m.id != messageId).toList();
    
    return GroupChatModel(
      id: id,
      name: name,
      characterIds: characterIds,
      messages: newMessages,
      createdAt: createdAt,
      lastMessageAt: newMessages.isNotEmpty ? 
          newMessages.last.timestamp : createdAt,
      description: description,
      settings: settings,
      metadata: metadata,
    );
  }

  // Update message status
  GroupChatModel updateMessageStatus(String messageId, newStatus) {
    final newMessages = messages.map((m) {
      return m.id == messageId ? m.copyWith(status: newStatus) : m;
    }).toList();

    return GroupChatModel(
      id: id,
      name: name,
      characterIds: characterIds,
      messages: newMessages,
      createdAt: createdAt,
      lastMessageAt: lastMessageAt,
      description: description,
      settings: settings,
      metadata: metadata,
    );
  }

  // Add a character to the group
  GroupChatModel addCharacter(String characterId) {
    if (characterIds.contains(characterId)) {
      throw ArgumentError('Character already in group');
    }
    if (characterIds.length >= _maxCharacters) {
      throw ArgumentError('Group cannot have more than $_maxCharacters characters');
    }

    final newCharacterIds = List<String>.from(characterIds)..add(characterId);

    return GroupChatModel(
      id: id,
      name: name,
      characterIds: newCharacterIds,
      messages: messages,
      createdAt: createdAt,
      lastMessageAt: lastMessageAt,
      description: description,
      settings: settings,
      metadata: metadata,
    );
  }

  // Remove a character from the group
  GroupChatModel removeCharacter(String characterId) {
    if (!characterIds.contains(characterId)) {
      throw ArgumentError('Character not in group');
    }
    if (characterIds.length <= _minCharacters) {
      throw ArgumentError('Group must have at least $_minCharacters characters');
    }

    final newCharacterIds = characterIds.where((id) => id != characterId).toList();

    return GroupChatModel(
      id: id,
      name: name,
      characterIds: newCharacterIds,
      messages: messages,
      createdAt: createdAt,
      lastMessageAt: lastMessageAt,
      description: description,
      settings: settings,
      metadata: metadata,
    );
  }

  // Update group name
  GroupChatModel updateName(String newName) {
    if (newName.isEmpty) {
      throw ArgumentError('Group name cannot be empty');
    }

    return GroupChatModel(
      id: id,
      name: newName,
      characterIds: characterIds,
      messages: messages,
      createdAt: createdAt,
      lastMessageAt: lastMessageAt,
      description: description,
      settings: settings,
      metadata: metadata,
    );
  }

  // Update group description
  GroupChatModel updateDescription(String? newDescription) {
    return GroupChatModel(
      id: id,
      name: name,
      characterIds: characterIds,
      messages: messages,
      createdAt: createdAt,
      lastMessageAt: lastMessageAt,
      description: newDescription,
      settings: settings,
      metadata: metadata,
    );
  }

  // Clear all messages
  GroupChatModel clearMessages() {
    return GroupChatModel(
      id: id,
      name: name,
      characterIds: characterIds,
      messages: [],
      createdAt: createdAt,
      lastMessageAt: createdAt,
      description: description,
      settings: settings,
      metadata: metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupChatModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'GroupChatModel{id: $id, name: $name, characterCount: $characterCount, messageCount: $messageCount}';
  }

  // Copy with method for updating group properties
  GroupChatModel copyWith({
    String? id,
    String? name,
    List<String>? characterIds,
    List<GroupChatMessage>? messages,
    DateTime? createdAt,
    DateTime? lastMessageAt,
  }) {
    return GroupChatModel(
      id: id ?? this.id,
      name: name ?? this.name,
      characterIds: characterIds ?? this.characterIds,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    );
  }
}