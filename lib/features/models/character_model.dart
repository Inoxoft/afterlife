import 'package:flutter/material.dart';

class CharacterModel {
  static const String _defaultAccentColor = '0xFF4ECDC4';
  static const String _characterIdPrefix = 'char_';
  static const String _defaultModel = 'local/llama-3.2-1b-instruct';

  final String id;
  final String name;
  final String systemPrompt; // Full detailed prompt for API models
  final String localPrompt; // Short optimized prompt for local models
  final String? imageUrl; // Asset image URL (for famous characters)
  final String? userImagePath; // User-uploaded image path
  final String? iconImagePath; // User-uploaded icon image path
  final IconData? icon; // Character icon
  final DateTime createdAt;
  final Color accentColor;
  final List<Map<String, dynamic>> chatHistory;
  final String? additionalInfo;
  final String model;

  CharacterModel({
    required this.id,
    required this.name,
    required this.systemPrompt,
    String? localPrompt,
    this.imageUrl,
    this.userImagePath,
    this.iconImagePath,
    this.icon,
    required this.createdAt,
    Color? accentColor,
    List<Map<String, dynamic>>? chatHistory,
    this.additionalInfo,
    String? model,
  }) : accentColor = accentColor ?? Color(int.parse(_defaultAccentColor)),
       chatHistory = chatHistory ?? [],
       model = model ?? _defaultModel,
       localPrompt = localPrompt ?? generateLocalPrompt(systemPrompt, name),
       assert(id.isNotEmpty, 'Character ID cannot be empty'),
       assert(name.isNotEmpty, 'Character name cannot be empty'),
       assert(systemPrompt.isNotEmpty, 'System prompt cannot be empty');

  // Create a character from the interview data
  factory CharacterModel.fromInterviewData({
    required String name,
    required String cardContent,
    String? imageUrl,
    String? userImagePath,
    String? iconImagePath,
    IconData? icon,
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
      userImagePath: userImagePath,
      iconImagePath: iconImagePath,
      icon: icon,
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

    // Optimize for DeepSeek: Make the prompt more direct and conversational
    if (!cleanedPrompt.contains("You are")) {
      cleanedPrompt =
          "You are $characterName. You will speak and act as this character in all responses.\n\n$cleanedPrompt";
    }

    // Add DeepSeek-optimized character persistence instructions
    if (!cleanedPrompt.contains("stay in character") &&
        !cleanedPrompt.contains("never break character")) {
      cleanedPrompt +=
          "\n\nYou must stay completely in character. Never break character, never mention you are an AI, and never show reasoning or thinking processes. Respond naturally as $characterName would.";
    }

    return cleanedPrompt;
  }

  // Get the appropriate prompt based on model type
  String getPromptForModel() {
    return isLocalModel(model) ? localPrompt : systemPrompt;
  }

  // Check if a model is a local model
  static bool isLocalModel(String modelId) {
    return modelId.startsWith('local/') ||
        modelId == 'local' ||
        modelId.contains('hammer') ||
        modelId.contains('gemma') || modelId.contains('llama');
  }

  // Generate optimized local prompt from full prompt
  static String generateLocalPrompt(String fullPrompt, String characterName) {
    // Remove markdown markers if present
    String cleanedPrompt = fullPrompt;
    if (fullPrompt.contains('## CHARACTER CARD SUMMARY ##') &&
        fullPrompt.contains('## END OF CHARACTER CARD ##')) {
      final startMarker = '## CHARACTER CARD SUMMARY ##';
      final endMarker = '## END OF CHARACTER CARD ##';

      final startIndex = fullPrompt.indexOf(startMarker);
      final cleanStart = startIndex + startMarker.length;
      final endIndex = fullPrompt.indexOf(endMarker);

      if (startIndex >= 0 && endIndex > startIndex) {
        cleanedPrompt = fullPrompt.substring(cleanStart, endIndex).trim();
      }
    }

    // Remove any remaining markdown markers
    cleanedPrompt = cleanedPrompt.replaceAll(RegExp(r'##.*?##'), '').trim();

    // Remove excessive formatting and structure that local models struggle with
    cleanedPrompt = cleanedPrompt.replaceAll(
      RegExp(r'\*\*.*?\*\*'),
      '',
    ); // Remove bold
    cleanedPrompt = cleanedPrompt.replaceAll(
      RegExp(r'\*.*?\*'),
      '',
    ); // Remove italics
    cleanedPrompt = cleanedPrompt.replaceAll(
      RegExp(r'###?\s*'),
      '',
    ); // Remove headers
    cleanedPrompt = cleanedPrompt.replaceAll(
      RegExp(r'-\s+'),
      '',
    ); // Remove bullet points
    cleanedPrompt = cleanedPrompt.replaceAll(
      RegExp(r'\n\s*\n\s*\n'),
      '\n\n',
    ); // Reduce excessive newlines

    // Start building the local prompt with clear character identity
    String localPrompt = "You are $characterName. ";

    // Extract core personality and background information
    final lines = cleanedPrompt.split('\n');

    final importantInfo = <String>[];

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      // Look for personality, background, and behavioral information
      if (trimmedLine.length > 15 &&
          !trimmedLine.startsWith('You are') &&
          !trimmedLine.startsWith('Your name') &&
          !trimmedLine.contains('respond as') &&
          !trimmedLine.contains('character') &&
          importantInfo.length < 5) {
        importantInfo.add(trimmedLine);
      }
    }

    // Add the most important character information
    if (importantInfo.isNotEmpty) {
      localPrompt += "${importantInfo.take(3).join(' ')} ";
    }

    // Add concise behavioral instructions optimized for local models
    localPrompt +=
        "Respond naturally and conversationally as $characterName would. ";
    localPrompt += "Stay in character at all times. ";
    localPrompt +=
        "Keep responses focused and authentic to $characterName's personality and background. ";
    localPrompt += "Do not mention being an AI or break character.";

    return localPrompt;
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'systemPrompt': systemPrompt,
      'localPrompt': localPrompt,
      'imageUrl': imageUrl,
      'userImagePath': userImagePath,
      'iconImagePath': iconImagePath,
      // Icon serialization disabled for release builds to avoid tree-shaking issues
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

      Color accentColor;
      try {
        accentColor = Color(json['accentColor'] as int);
      } catch (e) {
        accentColor = Color(int.parse(_defaultAccentColor));
      }

      // For release builds, we'll skip icon restoration from JSON to avoid tree-shaking issues
      // Icons will need to be re-selected by users if they were customized
      IconData? icon;

      // Parse chat history safely
      List<Map<String, dynamic>> chatHistory = [];
      try {
        if (json['chatHistory'] != null) {
          chatHistory = List<Map<String, dynamic>>.from(json['chatHistory']);
        }
      } catch (e) {
        // Use empty list as fallback
      }

      // Get system prompt
      final systemPrompt = json['systemPrompt']?.toString() ?? '';
      final characterName = json['name']?.toString() ?? 'Unknown Character';

      // Handle local prompt - generate if not present (backwards compatibility)
      String localPrompt;
      if (json['localPrompt'] != null) {
        localPrompt = json['localPrompt']?.toString() ?? '';
      } else {
        // Generate local prompt for existing characters
        localPrompt = generateLocalPrompt(systemPrompt, characterName);
      }

      return CharacterModel(
        id: json['id']?.toString() ?? '',
        name: characterName,
        systemPrompt: systemPrompt,
        localPrompt: localPrompt,
        imageUrl: json['imageUrl']?.toString(),
        userImagePath: json['userImagePath']?.toString(),
        iconImagePath: json['iconImagePath']?.toString(),
        icon: icon,
        createdAt: createdAt,
        accentColor: accentColor,
        chatHistory: chatHistory,
        additionalInfo: json['additionalInfo']?.toString(),
        model: json['model']?.toString(),
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
      localPrompt: localPrompt,
      imageUrl: imageUrl,
      userImagePath: userImagePath,
      iconImagePath: iconImagePath,
      icon: icon,
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
          userImagePath == other.userImagePath &&
          iconImagePath == other.iconImagePath &&
          icon == other.icon &&
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
      userImagePath.hashCode ^
      iconImagePath.hashCode ^
      icon.hashCode ^
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
