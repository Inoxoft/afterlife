// lib/features/character_prompts/famous_character_service.dart

import '../character_chat/chat_service.dart';
import '../providers/language_provider.dart';
import '../models/leading_question_detector.dart';
import 'famous_character_prompts.dart';

/// Service for interacting with famous characters
class FamousCharacterService {
  static final Map<String, List<Map<String, dynamic>>> _chatHistories = {};
  static LanguageProvider? _languageProvider;

  /// Set the language provider for language support
  static void setLanguageProvider(LanguageProvider languageProvider) {
    _languageProvider = languageProvider;
  }

  /// Initialize a chat with a famous character
  static Future<void> initializeChat(String characterName) async {
    if (!_chatHistories.containsKey(characterName)) {
      _chatHistories[characterName] = [];
      await ChatService.initialize();
      // Initialize the leading question detector
      await LeadingQuestionDetector.initialize();
    }
  }

  /// Check if a message contains leading questions
  /// Returns null if no leading question detected, otherwise returns detection result
  static Future<Map<String, dynamic>?> checkForLeadingQuestion(String message) async {
    print('🔍 Checking for leading question: "$message"');
    try {
      final result = await LeadingQuestionDetector.detectLeadingQuestion(message);
      print('🎯 Detection result: $result');
      if (result['isLeading'] == true) {
        print('⚠️ Leading question detected with confidence: ${result['confidence']}');
        return result;
      }
      print('✅ No leading question detected (confidence: ${result['confidence']})');
      return null;
    } catch (e) {
      // If detection fails, allow the message to proceed
      print('❌ Leading question detection failed: $e');
      return null;
    }
  }

  /// Send a message to a famous character and get a response
  static Future<String?> sendMessage({
    required String characterName,
    required String message,
    bool bypassLeadingQuestionCheck = false,
  }) async {
    try {
      // Initialize chat if not already done
      if (!_chatHistories.containsKey(characterName)) {
        await initializeChat(characterName);
      }

      // Check for leading questions unless bypassed
      if (!bypassLeadingQuestionCheck) {
        final leadingQuestionResult = await checkForLeadingQuestion(message);
        if (leadingQuestionResult != null) {
          // Return a special response indicating leading question detected
          // The UI will handle showing the warning
          return null;
        }
      }

      // Get system prompt for the character
      String? systemPrompt = FamousCharacterPrompts.getPrompt(characterName);
      if (systemPrompt == null) {
        return "Error: Character profile not found.";
      }

      // Add language instructions if not English
      if (_languageProvider != null && _languageProvider!.currentLanguageCode != 'en') {
        final languageName = _languageProvider!.currentLanguageName;
        final languageInstruction = '\n\n### LANGUAGE INSTRUCTIONS:\nPlease respond in $languageName language. The user has selected $languageName as their preferred language. Stay in character while responding in $languageName.\n';
        systemPrompt = systemPrompt + languageInstruction;
      }

      // Get the selected model for this character
      final selectedModel = FamousCharacterPrompts.getSelectedModel(
        characterName,
      );

      // Add user message to chat history
      _chatHistories[characterName]!.add({'role': 'user', 'content': message});

      // Prepare the chat history for the API - limit to last 10 messages for performance
      final List<Map<String, dynamic>> recentMessages = [];
      final history = _chatHistories[characterName]!;

      if (history.length > 10) {
        recentMessages.addAll(history.sublist(history.length - 10));
      } else {
        recentMessages.addAll(history);
      }

      // Send the message to the character
      final response = await ChatService.sendMessageToCharacter(
        characterId: characterName,
        message: message,
        systemPrompt: systemPrompt,
        chatHistory: recentMessages,
        model: selectedModel,
      );

      // Add AI response to chat history
      if (response != null) {
        _chatHistories[characterName]!.add({
          'role': 'assistant',
          'content': response,
        });
      }

      return response;
    } catch (e) {
      return "I'm sorry, but I'm having trouble connecting at the moment. Please try again later.";
    }
  }

  /// Get the chat history for a character
  static List<Map<String, dynamic>> getChatHistory(String characterName) {
    return _chatHistories[characterName] ?? [];
  }

  /// Clear the chat history for a character
  static void clearChatHistory(String characterName) {
    _chatHistories[characterName] = [];
  }

  /// Convert chat history to standard format for display
  static List<Map<String, dynamic>> getFormattedChatHistory(
    String characterName,
  ) {
    final history = _chatHistories[characterName] ?? [];
    return history.map((message) {
      return {
        'content': message['content'],
        'isUser': message['role'] == 'user',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }).toList();
  }
}
