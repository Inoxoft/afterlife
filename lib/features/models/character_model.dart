import 'dart:math';
import 'package:flutter/material.dart';

class CharacterModel {
  static const String _defaultAccentColor = '0xFF4ECDC4';
  static const String _characterIdPrefix = 'char_';
  static const String _defaultModel = 'google/gemini-2.0-flash-001';

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
           modelId.contains('deepseek') || 
           modelId.contains('gemma');
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

    // Create a more comprehensive local prompt by extracting key sections
    final sections = <String>[];
    final lines = cleanedPrompt.split('\n');
    
    // Variables to track current section
    String currentSection = '';
    bool inImportantSection = false;
    int sectionCount = 0;
    
    // Key sections to look for (case insensitive)
    final keySectionPatterns = [
      RegExp(r'personality', caseSensitive: false),
      RegExp(r'background', caseSensitive: false),
      RegExp(r'history', caseSensitive: false),
      RegExp(r'traits', caseSensitive: false),
      RegExp(r'characteristics', caseSensitive: false),
      RegExp(r'behaviors', caseSensitive: false),
      RegExp(r'interests', caseSensitive: false),
      RegExp(r'speaking style', caseSensitive: false),
      RegExp(r'communication', caseSensitive: false),
      RegExp(r'voice', caseSensitive: false),
      RegExp(r'appearance', caseSensitive: false),
    ];

    // Extract important sections
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        if (inImportantSection && currentSection.isNotEmpty) {
          sections.add(currentSection);
          currentSection = '';
          inImportantSection = false;
        }
        continue;
      }
      
      // Check if this line starts a key section
      bool isKeySectionHeader = false;
      for (final pattern in keySectionPatterns) {
        if (pattern.hasMatch(line) && line.length < 100) {
          isKeySectionHeader = true;
          
          // Save previous section if exists
          if (inImportantSection && currentSection.isNotEmpty) {
            sections.add(currentSection);
            currentSection = '';
          }
          
          // Start new section
          inImportantSection = true;
          currentSection = line;
          break;
        }
      }
      
      // Add line to current section
      if (inImportantSection && !isKeySectionHeader) {
        currentSection += '\n$line';
      }
      
      // For non-section-header lines that appear important
      if (!inImportantSection && line.length > 20 && sectionCount < 5) {
        sections.add(line);
        sectionCount++;
      }
    }
    
    // Add final section if exists
    if (inImportantSection && currentSection.isNotEmpty) {
      sections.add(currentSection);
    }
    
    // Start with a strong identity statement
    String localPrompt = "You are $characterName. ";
    
    // Add core identity description - up to 3 key lines if not already covered
    final identityLines = <String>[];
    for (int i = 0; i < lines.length && identityLines.length < 3; i++) {
      final line = lines[i].trim();
      if (line.isNotEmpty && 
          line.length > 20 && 
          !line.startsWith('You are') && 
          !sections.any((s) => s.contains(line))) {
        identityLines.add(line);
      }
    }
    
    if (identityLines.isNotEmpty) {
      localPrompt += "${identityLines.join(' ')}\n\n";
    }
    
    // Add extracted sections
    if (sections.isNotEmpty) {
      localPrompt += "${sections.join('\n\n')}\n\n";
    }

    // Add mandatory roleplay instructions
    localPrompt += "You must stay completely in character as $characterName. Never break character, never mention you are an AI, and never show reasoning or thinking processes. Respond naturally as $characterName would, with appropriate emotions, knowledge, and personality traits. Your responses should accurately reflect $characterName's speaking style, vocabulary, and mannerisms.";

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
      'iconCodePoint': icon?.codePoint,
      'iconFontFamily': icon?.fontFamily,
      'iconFontPackage': icon?.fontPackage,
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

      // Parse the icon safely
      IconData? icon;
      try {
        if (json['iconCodePoint'] != null) {
          icon = IconData(
            json['iconCodePoint'] as int,
            fontFamily: json['iconFontFamily'] as String?,
            fontPackage: json['iconFontPackage'] as String?,
          );
        }
      } catch (e) {
        // Icon parsing failed, use null
        icon = null;
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

      // Get system prompt
      final systemPrompt = json['systemPrompt'] as String;
      final characterName = json['name'] as String;
      
      // Handle local prompt - generate if not present (backwards compatibility)
      String localPrompt;
      if (json['localPrompt'] != null) {
        localPrompt = json['localPrompt'] as String;
      } else {
        // Generate local prompt for existing characters
        localPrompt = generateLocalPrompt(systemPrompt, characterName);
      }

      return CharacterModel(
        id: json['id'] as String,
        name: characterName,
        systemPrompt: systemPrompt,
        localPrompt: localPrompt,
        imageUrl: json['imageUrl'] as String?,
        userImagePath: json['userImagePath'] as String?,
        iconImagePath: json['iconImagePath'] as String?,
        icon: icon,
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
