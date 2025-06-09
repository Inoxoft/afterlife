import 'dart:math';
import 'package:flutter/material.dart';

class CharacterModel {
  static const String _defaultAccentColor = '0xFF4ECDC4';
  static const String _characterIdPrefix = 'char_';
  static const String _defaultModel = 'google/gemini-2.0-flash-001';

  final String id;
  final String name;
  final String systemPrompt;
  final String? imageUrl;
  final DateTime createdAt;
  final Color accentColor;
  final List<Map<String, dynamic>> chatHistory;
  final String? additionalInfo;
  final String model;

  CharacterModel({
    required this.id,
    required this.name,
    required this.systemPrompt,
    this.imageUrl,
    required this.createdAt,
    Color? accentColor,
    List<Map<String, dynamic>>? chatHistory,
    this.additionalInfo,
    String? model,
  }) : accentColor = accentColor ?? Color(int.parse(_defaultAccentColor)),
       chatHistory = chatHistory ?? [],
       model = model ?? _defaultModel,
       assert(id.isNotEmpty, 'Character ID cannot be empty'),
       assert(name.isNotEmpty, 'Character name cannot be empty'),
       assert(systemPrompt.isNotEmpty, 'System prompt cannot be empty');

  // Create a character from the interview data
  factory CharacterModel.fromInterviewData({
    required String name,
    required String cardContent,
    String? imageUrl,
    String? model,
  }) {
    final id = '${_characterIdPrefix}${DateTime.now().millisecondsSinceEpoch}';
    final createdAt = DateTime.now();
    final cleanSystemPrompt = _cleanSystemPrompt(cardContent, name);

    return CharacterModel(
      id: id,
      name: name,
      systemPrompt: cleanSystemPrompt,
      imageUrl: imageUrl,
      createdAt: createdAt,
      model: model,
    );
  }

  // Helper method to clean system prompts
  static String _cleanSystemPrompt(String prompt, String characterName) {
    String cleanedPrompt = prompt;

    // Remove markdown markers if present
    if (prompt.contains('## CHARACTER CARD SUMMARY ##') &&
        prompt.contains('## END OF CHARACTER CARD ##')) {
      final startMarker = '## CHARACTER CARD SUMMARY ##';
      final endMarker = '## END OF CHARACTER CARD ##';

      final startIndex = prompt.indexOf(startMarker);
      final cleanStart = startIndex + startMarker.length;
      final endIndex = prompt.indexOf(endMarker);

      if (startIndex >= 0 && endIndex > startIndex) {
        cleanedPrompt = prompt.substring(cleanStart, endIndex).trim();
      }
    }

    // Remove any remaining markdown markers
    cleanedPrompt = cleanedPrompt.replaceAll(RegExp(r'##.*?##'), '').trim();

    // Ensure proper instruction format
    if (!cleanedPrompt.contains("You are")) {
      cleanedPrompt =
          "You are $characterName, a character with the following traits and background:\n\n$cleanedPrompt";
    }

    // Add character persistence instruction if not present
    if (!cleanedPrompt.contains("stay in character") &&
        !cleanedPrompt.contains("never break character")) {
      cleanedPrompt +=
          "\n\nStay in character at all times. Never break character or admit you are an AI.";
    }

    return cleanedPrompt;
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'systemPrompt': systemPrompt,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'accentColor': accentColor.toARGB32(),
      'chatHistory': chatHistory,
      'additionalInfo': additionalInfo,
      'model': model,
    };
  }

  // Create from JSON data
  factory CharacterModel.fromJson(Map<String, dynamic> json) {
    try {
      // Ensure required fields are present
      if (json['id'] == null ||
          json['name'] == null ||
          json['systemPrompt'] == null) {
        throw FormatException('Missing required fields in character data');
      }

      // Parse the createdAt date safely
      DateTime createdAt;
      try {
        createdAt = DateTime.parse(json['createdAt'] as String);
      } catch (e) {
        createdAt = DateTime.now();
      }

      // Parse the accent color safely
      Color accentColor;
      try {
        accentColor = Color(json['accentColor'] as int);
      } catch (e) {
        accentColor = Color(int.parse(_defaultAccentColor));
      }

      // Parse chat history safely
      List<Map<String, dynamic>> chatHistory = [];
      try {
        if (json['chatHistory'] != null) {
          chatHistory = List<Map<String, dynamic>>.from(json['chatHistory']);
        }
      } catch (e) {
        // Use empty list as fallback
      }

      return CharacterModel(
        id: json['id'] as String,
        name: json['name'] as String,
        systemPrompt: json['systemPrompt'] as String,
        imageUrl: json['imageUrl'] as String?,
        createdAt: createdAt,
        accentColor: accentColor,
        chatHistory: chatHistory,
        additionalInfo: json['additionalInfo'] as String?,
        model: json['model'] as String?,
      );
    } catch (e) {
      throw FormatException('Invalid character data: $e');
    }
  }

  // Add a message to chat history
  CharacterModel addMessage({required String text, required bool isUser}) {
    if (text.isEmpty) {
      throw ArgumentError('Message text cannot be empty');
    }

    final newChatHistory = List<Map<String, dynamic>>.from(chatHistory)..add({
      'content': text,
      'isUser': isUser,
      'timestamp': DateTime.now().toIso8601String(),
    });

    return CharacterModel(
      id: id,
      name: name,
      systemPrompt: systemPrompt,
      imageUrl: imageUrl,
      createdAt: createdAt,
      accentColor: accentColor,
      chatHistory: newChatHistory,
      additionalInfo: additionalInfo,
      model: model,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CharacterModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          systemPrompt == other.systemPrompt &&
          imageUrl == other.imageUrl &&
          createdAt == other.createdAt &&
          accentColor == other.accentColor &&
          chatHistory.length == other.chatHistory.length &&
          additionalInfo == other.additionalInfo &&
          model == other.model;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      systemPrompt.hashCode ^
      imageUrl.hashCode ^
      createdAt.hashCode ^
      accentColor.hashCode ^
      chatHistory.length.hashCode ^
      additionalInfo.hashCode ^
      model.hashCode;

  // Get a short description from the system prompt
  String getShortDescription() {
    final cleanPrompt = systemPrompt.replaceAll(RegExp(r'You are \w+,\s+'), '');
    final firstSentence = cleanPrompt.split('.').first;

    if (firstSentence.length > 100) {
      return '${firstSentence.substring(0, 97)}...';
    }

    return '$firstSentence.';
  }

  // Get formatted creation date
  String getFormattedDate() {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}
