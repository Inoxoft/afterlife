// lib/features/character_prompts/famous_character_service.dart

import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/utils/env_config.dart';
import '../providers/language_provider.dart';
import 'famous_character_prompts.dart';
import '../../core/services/hybrid_chat_service.dart';
import '../models/character_model.dart';

/// Service for interacting with famous characters
class FamousCharacterService {
  static final String _openRouterUrl =
      'https://openrouter.ai/api/v1/chat/completions';
  static const Duration _requestTimeout = Duration(seconds: 120);
  static String? _apiKey;
  static bool _isInitialized = false;
  static bool _isUsingDefaultKey = false;
  static LanguageProvider? _languageProvider;

  /// Chat histories for each character
  static final Map<String, List<Map<String, dynamic>>> _chatHistories = {};

  /// Set the language provider for language support
  static void setLanguageProvider(LanguageProvider languageProvider) {
    _languageProvider = languageProvider;
  }

  /// Initialize a chat with a famous character
  static Future<void> initializeChat(String characterName) async {
    if (!_chatHistories.containsKey(characterName)) {
      _chatHistories[characterName] = [];
    }
  }

  /// Send a message to a famous character and get a response
  static Future<String?> sendMessage({
    required String characterName,
    required String message,
  }) async {
    /// Ensure service is initialized
    if (!_isInitialized) {
      await initialize();
    }

    /// Always refresh the API key before sending a message
    await refreshApiKey();

    /// Get the character's system prompt
    final systemPrompt = FamousCharacterPrompts.getPrompt(characterName);
    final model = FamousCharacterPrompts.getSelectedModel(characterName);

    if (systemPrompt == null) {
      return "Error: Character profile not found.";
    }

    /// Get current chat history
    final chatHistory = _chatHistories[characterName] ?? [];

    /// Add language instruction if language provider is available
    String finalSystemPrompt = systemPrompt;
    if (_languageProvider != null &&
        _languageProvider!.currentLanguageCode != 'en') {
      final languageName = _languageProvider!.currentLanguageName;
      final languageInstruction =
          '\n\nIMPORTANT: Please always respond in $languageName unless the user explicitly asks you to change languages. Your responses should be natural and fluent in $languageName.';
      finalSystemPrompt = '$systemPrompt$languageInstruction';
    }

    /// Check if using a local model
    final bool isLocalModel = CharacterModel.isLocalModel(model);

    if (isLocalModel) {
      /// Use HybridChatService for local models
      try {
        // Convert chat history to the format expected by HybridChatService
        final formattedChatHistory =
            chatHistory.map((msg) {
              // Ensure each message has proper fields
              return {
                'role': msg['isUser'] == true ? 'user' : 'assistant',
                'content': msg['content'],
                'isUser': msg['isUser'],
              };
            }).toList();

        // Generate a local-optimized prompt if needed
        final localPrompt = CharacterModel.generateLocalPrompt(
          finalSystemPrompt,
          characterName,
        );

        // Use HybridChatService with local model
        final response = await HybridChatService.sendMessageToCharacter(
          characterId: 'famous_$characterName', // Create a virtual ID
          message: message,
          systemPrompt: finalSystemPrompt,
          chatHistory: formattedChatHistory,
          model: model,
          localPrompt: localPrompt,
        );

        if (response != null) {
          /// Add both user message and AI response to chat history
          _chatHistories[characterName]!.addAll([
            {
              'content': message,
              'isUser': true,
              'timestamp': DateTime.now().toIso8601String(),
            },
            {
              'content': response,
              'isUser': false,
              'timestamp': DateTime.now().toIso8601String(),
            },
          ]);
        }

        return response;
      } catch (e) {
        if (kDebugMode) {
          print('Error using local model for famous character: $e');
        }
        return 'I apologize, but I encountered an issue with the local AI model. Please try again or select a different model.';
      }
    } else {
      /// Use OpenRouter API for cloud models
      /// Validate API key exists for cloud models
      if (_apiKey == null || _apiKey!.isEmpty) {
        return 'Error: Unable to connect to AI service. Please check your API key configuration.';
      }

      /// Prepare messages for API
      final messages = <Map<String, dynamic>>[
        {'role': 'system', 'content': finalSystemPrompt},
      ];

      // Add chat history with proper role fields
      for (final msg in chatHistory) {
        // Ensure each message has a proper role field
        if (msg.containsKey('isUser')) {
          messages.add({
            'role': msg['isUser'] == true ? 'user' : 'assistant',
            'content': msg['content'],
          });
        } else if (msg.containsKey('role')) {
          // If it already has a role, use it directly
          messages.add({'role': msg['role'], 'content': msg['content']});
        } else {
          // Default fallback if we can't determine the role
          messages.add({
            'role': 'user', // Default to user
            'content': msg['content'],
          });
        }
      }

      // Add the new user message
      messages.add({'role': 'user', 'content': message});

      /// Prepare request body
      final body = jsonEncode({
        'model': model,
        'messages': messages,
        'temperature': 0.7,
        'max_tokens': 25000,
      });

      try {
        /// Send request
        final response = await http
            .post(
              Uri.parse(_openRouterUrl),
              headers: {
                'Content-Type': 'application/json; charset=utf-8',
                'Authorization': 'Bearer $_apiKey',
                'X-Title': 'Afterlife AI',
                'Accept': 'application/json; charset=utf-8',
              },
              body: body,
            )
            .timeout(_requestTimeout);

        if (response.statusCode != 200) {
          if (kDebugMode) {
            print(
              'API Error in famous_character_service: ${response.statusCode}: ${response.body}',
            );
          }
          return 'I apologize, but I encountered a server error. Please try again.';
        }

        /// Parse response with explicit UTF-8 decoding
        final responseBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(responseBody);

        /// Add null checks to prevent "The method '[]' was called on null" error
        if (data == null ||
            data['choices'] == null ||
            data['choices'].isEmpty ||
            data['choices'][0] == null ||
            data['choices'][0]['message'] == null) {
          if (kDebugMode) {
            print(
              'Error in famous_character_service: Invalid response format: $data',
            );
          }
          return 'I apologize, I received an invalid response format. Please try again.';
        }

        final aiResponse = data['choices'][0]['message']['content'] as String;

        /// Add both user message and AI response to chat history
        _chatHistories[characterName]!.addAll([
          {
            'content': message,
            'isUser': true,
            'timestamp': DateTime.now().toIso8601String(),
          },
          {
            'content': aiResponse,
            'isUser': false,
            'timestamp': DateTime.now().toIso8601String(),
          },
        ]);

        return aiResponse;
      } on TimeoutException catch (e) {
        if (kDebugMode) {
          print('TimeoutException in famous_character_service: $e');
        }
        return 'I apologize, but my response is taking longer than expected. Please try again in a moment.';
      } on http.ClientException catch (e) {
        if (kDebugMode) {
          print('ClientException in famous_character_service: $e');
        }
        return 'It seems there is a network issue. Please check your internet connection.';
      } catch (e, s) {
        if (kDebugMode) {
          print('Generic Exception in famous_character_service: $e');
          print(s);
        }
        return 'I apologize, but I encountered an issue connecting to my servers. Please try again in a moment.';
      }
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
    return _chatHistories[characterName] ?? [];
  }

  /// Initialize the service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      /// Initialize environment configuration
      await EnvConfig.initialize();

      /// Get API key from environment
      _apiKey = EnvConfig.get('OPENROUTER_API_KEY');

      /// Check if we're using a default key or a user key
      _isUsingDefaultKey = !(await EnvConfig.hasUserApiKey());

      if (_apiKey == null || _apiKey!.isEmpty) {
        if (kDebugMode) {
          print(
            'Warning: No OpenRouter API key found. The application will not function properly.',
          );
          print(
            'Please set OPENROUTER_API_KEY in your .env file or in Settings.',
          );
        }
      } else {
        if (kDebugMode) {
          print(
            'API key loaded successfully - Using ${_isUsingDefaultKey ? 'default' : 'user\'s'} key',
          );
        }
      }

      _isInitialized = true;
    } catch (e) {
      _isInitialized = true; // Mark as initialized to prevent repeated attempts
    }
  }

  /// Method to refresh API key from the latest source
  static Future<void> refreshApiKey() async {
    try {
      /// Get the latest key directly
      _apiKey = EnvConfig.get('OPENROUTER_API_KEY');

      /// Check if we're using a default key or a user key
      _isUsingDefaultKey = !(await EnvConfig.hasUserApiKey());

      if (_apiKey == null || _apiKey!.isEmpty) {
        /// Silent handling for missing key
      } else {
        if (kDebugMode) {
          print(
            'API key refreshed successfully - Using ${_isUsingDefaultKey ? 'default' : 'user\'s'} key',
          );
        }
      }
    } catch (e) {
      /// Silent error handling
    }
  }

  /// Method for logging diagnostic info
  static void logDiagnostics() {
    if (kDebugMode) {
      print(
        'API key status: ${_apiKey == null ? "NULL" : (_apiKey!.isEmpty ? "EMPTY" : "SET (${_apiKey!.substring(0, min(4, _apiKey!.length))}...)")}',
      );
    }
  }

  static int min(int a, int b) => a < b ? a : b;
}
