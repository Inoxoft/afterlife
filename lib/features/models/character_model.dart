import 'package:flutter/material.dart';

class CharacterModel {
  final String id;
  final String name;
  final String systemPrompt;
  final String? imageUrl;
  final DateTime createdAt;
  final Color accentColor;
  final List<Map<String, dynamic>> chatHistory;
  final String? additionalInfo;

  CharacterModel({
    required this.id,
    required this.name,
    required this.systemPrompt,
    this.imageUrl,
    required this.createdAt,
    this.accentColor = const Color(0xFF4ECDC4),
    List<Map<String, dynamic>>? chatHistory,
    this.additionalInfo,
  }) : chatHistory = chatHistory ?? [];

  // Create a character from the interview data
  factory CharacterModel.fromInterviewData({
    required String name,
    required String cardContent,
    String? imageUrl,
  }) {
    // Generate a unique ID based on timestamp
    final id = 'char_${DateTime.now().millisecondsSinceEpoch}';
    final createdAt = DateTime.now();

    // Ensure the system prompt is cleaned from any markdown markers
    final cleanSystemPrompt = _cleanSystemPrompt(cardContent, name);

    return CharacterModel(
      id: id,
      name: name,
      systemPrompt: cleanSystemPrompt,
      imageUrl: imageUrl,
      createdAt: createdAt,
    );
  }

  // Helper method to clean system prompts
  static String _cleanSystemPrompt(String prompt, String characterName) {
    // Remove any ## markers if they somehow got included
    String cleanedPrompt = prompt;

    // Check if the prompt still contains markdown markers
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

    // Ensure the prompt starts with a clear instruction about who the AI is impersonating
    if (!cleanedPrompt.contains("You are")) {
      cleanedPrompt =
          "You are $characterName, a character with the following traits and background:\n\n$cleanedPrompt";
    }

    // Add clear instructions to stay in character if not already present
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
      'accentColor': accentColor.value,
      'chatHistory': chatHistory,
      'additionalInfo': additionalInfo,
    };
  }

  // Create from JSON data
  factory CharacterModel.fromJson(Map<String, dynamic> json) {
    return CharacterModel(
      id: json['id'],
      name: json['name'],
      systemPrompt: json['systemPrompt'],
      imageUrl: json['imageUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      accentColor: Color(json['accentColor']),
      chatHistory: List<Map<String, dynamic>>.from(json['chatHistory'] ?? []),
      additionalInfo: json['additionalInfo'],
    );
  }

  // Add a message to chat history
  CharacterModel addMessage({required String text, required bool isUser}) {
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
    );
  }
}
