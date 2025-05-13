// lib/features/character_prompts/famous_character_service.dart

import 'dart:convert';
import '../character_chat/chat_service.dart';
import 'famous_character_prompts.dart';

/// Service for interacting with famous characters
class FamousCharacterService {
  static final Map<String, List<Map<String, dynamic>>> _chatHistories = {};

  /// Initialize a chat with a famous character
  static Future<void> initializeChat(String characterName) async {
    if (!_chatHistories.containsKey(characterName)) {
      _chatHistories[characterName] = [];
      await ChatService.initialize();
    }
  }

  /// Send a message to a famous character and get a response
  static Future<String?> sendMessage({
    required String characterName,
    required String message,
  }) async {
    try {
      // Initialize chat if not already done
      if (!_chatHistories.containsKey(characterName)) {
        await initializeChat(characterName);
      }

      // Get system prompt for the character
      final systemPrompt = FamousCharacterPrompts.getPrompt(characterName);
      if (systemPrompt == null) {
        return "Error: Character profile not found.";
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
      print('Error in FamousCharacterService.sendMessage: $e');
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
