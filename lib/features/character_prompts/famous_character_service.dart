// lib/features/character_prompts/famous_character_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../providers/language_provider.dart';
import 'famous_character_prompts.dart';
import '../../core/services/hybrid_chat_service.dart';
import '../models/character_model.dart';

/// Service for interacting with famous characters using the same architecture as regular character chat
class FamousCharacterService {
  static LanguageProvider? _languageProvider;

  /// Chat histories for each character
  static final Map<String, List<Map<String, dynamic>>> _chatHistories = {};

  /// Virtual character models for famous characters
  static final Map<String, CharacterModel> _virtualCharacters = {};

  /// Set the language provider for language support
  static void setLanguageProvider(LanguageProvider languageProvider) {
    _languageProvider = languageProvider;
  }

  /// Initialize a chat with a famous character
  static Future<void> initializeChat(String characterName) async {
    if (!_chatHistories.containsKey(characterName)) {
      _chatHistories[characterName] = [];
    }

    // Create virtual character model if not exists
    if (!_virtualCharacters.containsKey(characterName)) {
      _createVirtualCharacter(characterName);
    }
  }

  /// Create a virtual CharacterModel for a famous character
  static void _createVirtualCharacter(String characterName) {
    final systemPrompt = FamousCharacterPrompts.getPrompt(characterName);
    String selectedModel = FamousCharacterPrompts.getSelectedModel(
      characterName,
    );
    // Back-compat: ensure legacy Llama local id migrates to Gemma 3n local id
    if (selectedModel == 'local/llama-3.2-1b-instruct' || selectedModel == 'local/llama-3.2' || selectedModel == 'local/gemma-3n-e2b-it') {
      selectedModel = 'local/gemma-3-1b-it';
    }

    if (systemPrompt == null) return;

    // Add language instruction if language provider is available
    String finalSystemPrompt = systemPrompt;
    if (_languageProvider != null &&
        _languageProvider!.currentLanguageCode != 'en') {
      final languageName = _languageProvider!.currentLanguageName;
      final languageInstruction =
          '\n\nIMPORTANT: Please always respond in $languageName unless the user explicitly asks you to change languages. Your responses should be natural and fluent in $languageName.';
      finalSystemPrompt = '$systemPrompt$languageInstruction';
    }

    final virtualCharacter = CharacterModel(
      id: 'famous_$characterName',
      name: characterName,
      systemPrompt: finalSystemPrompt,
      createdAt: DateTime.now(),
      chatHistory: _chatHistories[characterName] ?? [],
      model: selectedModel,
      imageUrl: FamousCharacterPrompts.getImageUrl(characterName),
    );

    _virtualCharacters[characterName] = virtualCharacter;
  }

  /// Add a user message to chat history immediately
  static void addUserMessage({
    required String characterName,
    required String message,
  }) {
    // Ensure character is initialized
    if (!_chatHistories.containsKey(characterName)) {
      _chatHistories[characterName] = [];
    }

    // Add user message immediately
    _chatHistories[characterName]!.add({
      'content': message,
      'isUser': true,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Update virtual character's chat history
    final virtualCharacter = _virtualCharacters[characterName];
    if (virtualCharacter != null) {
      _virtualCharacters[characterName] = CharacterModel(
        id: virtualCharacter.id,
        name: virtualCharacter.name,
        systemPrompt: virtualCharacter.systemPrompt,
        localPrompt: virtualCharacter.localPrompt,
        createdAt: virtualCharacter.createdAt,
        chatHistory: _chatHistories[characterName]!,
        model: virtualCharacter.model,
        imageUrl: virtualCharacter.imageUrl,
        userImagePath: virtualCharacter.userImagePath,
        iconImagePath: virtualCharacter.iconImagePath,
        icon: virtualCharacter.icon,
        accentColor: virtualCharacter.accentColor,
        additionalInfo: virtualCharacter.additionalInfo,
      );
    }
  }

  /// Add an AI response message to chat history
  static void addAIMessage({
    required String characterName,
    required String message,
  }) {
    // Ensure character is initialized
    if (!_chatHistories.containsKey(characterName)) {
      _chatHistories[characterName] = [];
    }

    // Add AI message
    _chatHistories[characterName]!.add({
      'content': message,
      'isUser': false,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Update virtual character's chat history
    final virtualCharacter = _virtualCharacters[characterName];
    if (virtualCharacter != null) {
      _virtualCharacters[characterName] = CharacterModel(
        id: virtualCharacter.id,
        name: virtualCharacter.name,
        systemPrompt: virtualCharacter.systemPrompt,
        localPrompt: virtualCharacter.localPrompt,
        createdAt: virtualCharacter.createdAt,
        chatHistory: _chatHistories[characterName]!,
        model: virtualCharacter.model,
        imageUrl: virtualCharacter.imageUrl,
        userImagePath: virtualCharacter.userImagePath,
        iconImagePath: virtualCharacter.iconImagePath,
        icon: virtualCharacter.icon,
        accentColor: virtualCharacter.accentColor,
        additionalInfo: virtualCharacter.additionalInfo,
      );
    }
  }

  /// Send a message to a famous character and get a response
  static Future<String?> sendMessage({
    required String characterName,
    required String message,
  }) async {
    // Ensure character is initialized
    await initializeChat(characterName);

    final virtualCharacter = _virtualCharacters[characterName];
    if (virtualCharacter == null) {
      return "Error: Character profile not found.";
    }

    // Get current chat history (should already include the user message)
    final chatHistory = _chatHistories[characterName] ?? [];

    try {
      // Use HybridChatService like regular character chat
      final response = await HybridChatService.sendMessageToCharacter(
        characterId: virtualCharacter.id,
        message: message,
        systemPrompt: virtualCharacter.systemPrompt,
        chatHistory: chatHistory,
        model: virtualCharacter.model,
        localPrompt: virtualCharacter.localPrompt,
      );

      if (response != null) {
        // Add only the AI response to chat history (user message already added)
        _chatHistories[characterName]!.add({
          'content': response,
          'isUser': false,
          'timestamp': DateTime.now().toIso8601String(),
        });

        // Update virtual character's chat history
        _virtualCharacters[characterName] = CharacterModel(
          id: virtualCharacter.id,
          name: virtualCharacter.name,
          systemPrompt: virtualCharacter.systemPrompt,
          localPrompt: virtualCharacter.localPrompt,
          createdAt: virtualCharacter.createdAt,
          chatHistory: _chatHistories[characterName]!,
          model: virtualCharacter.model,
          imageUrl: virtualCharacter.imageUrl,
          userImagePath: virtualCharacter.userImagePath,
          iconImagePath: virtualCharacter.iconImagePath,
          icon: virtualCharacter.icon,
          accentColor: virtualCharacter.accentColor,
          additionalInfo: virtualCharacter.additionalInfo,
        );
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error in FamousCharacterService.sendMessage: $e');
      }
      return 'I apologize, but I encountered an issue. Please try again.';
    }
  }

  /// Update the model for a famous character
  static void updateCharacterModel(String characterName, String newModel) {
    final virtualCharacter = _virtualCharacters[characterName];
    if (virtualCharacter != null) {
      // Recreate the virtual character with the new model
      final updatedCharacter = CharacterModel(
        id: virtualCharacter.id,
        name: virtualCharacter.name,
        systemPrompt: virtualCharacter.systemPrompt,
        localPrompt: virtualCharacter.localPrompt,
        createdAt: virtualCharacter.createdAt,
        chatHistory: virtualCharacter.chatHistory,
        model: newModel, // Update to new model
        imageUrl: virtualCharacter.imageUrl,
        userImagePath: virtualCharacter.userImagePath,
        iconImagePath: virtualCharacter.iconImagePath,
        icon: virtualCharacter.icon,
        accentColor: virtualCharacter.accentColor,
        additionalInfo: virtualCharacter.additionalInfo,
      );

      _virtualCharacters[characterName] = updatedCharacter;

      // Update the selected model in prompts
      FamousCharacterPrompts.setSelectedModel(characterName, newModel);
    }
  }

  /// Get the chat history for a character
  static List<Map<String, dynamic>> getChatHistory(String characterName) {
    return _chatHistories[characterName] ?? [];
  }

  /// Clear the chat history for a character
  static void clearChatHistory(String characterName) {
    _chatHistories[characterName] = [];

    // Update virtual character's chat history
    final virtualCharacter = _virtualCharacters[characterName];
    if (virtualCharacter != null) {
      _virtualCharacters[characterName] = CharacterModel(
        id: virtualCharacter.id,
        name: virtualCharacter.name,
        systemPrompt: virtualCharacter.systemPrompt,
        localPrompt: virtualCharacter.localPrompt,
        createdAt: virtualCharacter.createdAt,
        chatHistory: [], // Clear chat history
        model: virtualCharacter.model,
        imageUrl: virtualCharacter.imageUrl,
        userImagePath: virtualCharacter.userImagePath,
        iconImagePath: virtualCharacter.iconImagePath,
        icon: virtualCharacter.icon,
        accentColor: virtualCharacter.accentColor,
        additionalInfo: virtualCharacter.additionalInfo,
      );
    }
  }

  /// Convert chat history to standard format for display
  static List<Map<String, dynamic>> getFormattedChatHistory(
    String characterName,
  ) {
    return _chatHistories[characterName] ?? [];
  }

  /// Get the virtual character model (for debugging or advanced usage)
  static CharacterModel? getVirtualCharacter(String characterName) {
    return _virtualCharacters[characterName];
  }

  /// Method for logging diagnostic info
  static void logDiagnostics() {
    if (kDebugMode) {
      print('=== Famous Character Service Diagnostics ===');
      print('Loaded characters: ${_virtualCharacters.keys.toList()}');
      print('Chat histories: ${_chatHistories.keys.toList()}');
      print(
        'Language provider: ${_languageProvider?.currentLanguageCode ?? 'not set'}',
      );
      print('=============================');
    }
  }
}
