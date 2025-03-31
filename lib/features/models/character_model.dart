import 'package:flutter/material.dart';

class CharacterModel {
  final String id;
  final String name;
  final String systemPrompt;
  final String? imageUrl;
  final DateTime createdAt;
  final Color accentColor;
  final List<Map<String, dynamic>> chatHistory;

  CharacterModel({
    required this.id,
    required this.name,
    required this.systemPrompt,
    this.imageUrl,
    required this.createdAt,
    this.accentColor = const Color(0xFF4ECDC4),
    List<Map<String, dynamic>>? chatHistory,
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

    return CharacterModel(
      id: id,
      name: name,
      systemPrompt: cardContent,
      imageUrl: imageUrl,
      createdAt: createdAt,
    );
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
    );
  }

  // Add a message to chat history
  CharacterModel addMessage({required String text, required bool isUser}) {
    final updatedHistory = List<Map<String, dynamic>>.from(chatHistory);
    updatedHistory.add({
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
      chatHistory: updatedHistory,
    );
  }
}
