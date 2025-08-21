import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/env_config.dart';
import '../utils/app_logger.dart';
import 'base_service.dart';

enum ChatContext { general, character, interview }

class UnifiedChatService {
  static const String _openRouterUrl =
      'https://openrouter.ai/api/v1/chat/completions';
  static const Duration _requestTimeout = Duration(seconds: 120);

  // Default models per context (updated to newest OpenRouter models)
  static const String _defaultGeneralModel = 'anthropic/claude-sonnet-4';
  static const String _defaultCharacterModel = 'anthropic/claude-sonnet-4';
  static const String _defaultInterviewModel = 'google/gemini-2.5-pro';

  static const double _defaultTemperature = 0.7;
  static const int _defaultMaxTokens = 25000;

  static bool _isInitialized = false;
  static String? _apiKey;
  static bool _isUsingDefaultKey = false;

  // Initialize the service
  static Future<void> initialize() async {
    await StaticServiceInitializer.initializeService(
      serviceName: 'UnifiedChatService',
      isInitialized: () => _isInitialized,
      markInitialized: () => _isInitialized = true,
      dependencies: [
        () => EnvConfig.initialize(),
      ],
      initializeLogic: () async {
        // Get API key from environment
        _apiKey = EnvConfig.get('OPENROUTER_API_KEY');

        // Check if we're using a default key or a user key
        _isUsingDefaultKey = !(await EnvConfig.hasUserApiKey());

        if (_apiKey == null || _apiKey!.isEmpty) {
          if (kDebugMode) {
            AppLogger.warning(
              'No OpenRouter API key found - application will not function properly',
              tag: 'UnifiedChatService'
            );
            AppLogger.info(
              'Please set OPENROUTER_API_KEY in your .env file or in Settings',
              tag: 'UnifiedChatService'
            );
          }
        } else {
          if (kDebugMode) {
            AppLogger.debug(
              'Using ${_isUsingDefaultKey ? 'default' : 'user\'s'} API key',
              tag: 'UnifiedChatService'
            );
          }
        }
      },
    );
  }

  // Method to refresh API key from the latest source
  static Future<void> refreshApiKey() async {
    try {
      if (kDebugMode) {
        AppLogger.debug('Refreshing API key', tag: 'UnifiedChatService');
      }

      // Get the latest key directly
      _apiKey = EnvConfig.get('OPENROUTER_API_KEY');

      // Check if we're using a default key or a user key
      _isUsingDefaultKey = !(await EnvConfig.hasUserApiKey());

      if (_apiKey == null || _apiKey!.isEmpty) {
        if (kDebugMode) {
          AppLogger.warning('No API key found after refresh', tag: 'UnifiedChatService');
        }
      } else {
        if (kDebugMode) {
          AppLogger.debug(
            'API key refreshed successfully - Using ${_isUsingDefaultKey ? 'default' : 'user\'s'} key',
            tag: 'UnifiedChatService'
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.error('Error refreshing API key', tag: 'UnifiedChatService', error: e);
      }
    }
  }

  // Unified send message method that routes based on context
  static Future<String?> sendMessage({
    required ChatContext context,
    String? message,
    List<Map<String, dynamic>>? history,
    List<Map<String, dynamic>>? messages,
    String? systemPrompt,
    String? model,
    String? characterId,
    double? temperature,
    int? maxTokens,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Always refresh the API key before sending a message
    await refreshApiKey();

    // Validate API key
    if (_apiKey == null || _apiKey!.isEmpty) {
      if (kDebugMode) {
        AppLogger.error('API key is missing - cannot send message', tag: 'UnifiedChatService');
      }
      return 'Error: No API key configured. Please add your OpenRouter API key in Settings to use AI features.';
    }

    // Additional validation for API key format
    if (!_isValidApiKeyFormat(_apiKey!)) {
      if (kDebugMode) {
        AppLogger.error('API key format appears invalid', tag: 'UnifiedChatService');
      }
      return 'Error: API key format appears invalid. Please check your OpenRouter API key in Settings.';
    }

    try {
      // Route to appropriate handler based on context
      switch (context) {
        case ChatContext.general:
          return await _sendGeneralMessage(
            message: message!,
            history: history ?? [],
            systemPrompt: systemPrompt,
            model: model,
          );
        case ChatContext.character:
          return await _sendCharacterMessage(
            characterId: characterId!,
            message: message!,
            systemPrompt: systemPrompt!,
            chatHistory: history ?? [],
            model: model,
          );
        case ChatContext.interview:
          return await _sendInterviewMessage(
            messages: messages!,
            systemPrompt: systemPrompt,
            model: model,
            temperature: temperature,
            maxTokens: maxTokens,
          );
      }
    } catch (e, s) {
      if (kDebugMode) {
        print('Error in unified chat service: $e');
        print(s);
      }
      return 'I apologize, but I encountered an issue connecting to my servers. Please try again in a moment.';
    }
  }

  // Internal method for general chat flow
  static Future<String?> _sendGeneralMessage({
    required String message,
    required List<Map<String, dynamic>> history,
    String? systemPrompt,
    String? model,
  }) async {
    try {
      // Prepare the request payload
      final List<Map<String, dynamic>> messages = [];

      // Add system prompt if provided
      if (systemPrompt != null && systemPrompt.isNotEmpty) {
        messages.add({'role': 'system', 'content': systemPrompt});
      }

      // Add chat history with proper role fields
      for (final msg in history) {
        // Make a copy of the message to avoid modifying the original
        final Map<String, dynamic> formattedMsg = Map.from(msg);

        // Ensure the message has a role field
        if (!formattedMsg.containsKey('role')) {
          // If it has an 'isUser' field, use that to determine role
          if (formattedMsg.containsKey('isUser')) {
            formattedMsg['role'] =
                formattedMsg['isUser'] == true ? 'user' : 'assistant';
          } else {
            // Default to 'user' if we can't determine
            formattedMsg['role'] = 'user';
          }
        }

        messages.add({
          'role': formattedMsg['role'],
          'content': formattedMsg['content'],
        });
      }

      // Add the new user message
      messages.add({'role': 'user', 'content': message});

      // Create the request body
      final body = {
        'model': model ?? _defaultGeneralModel,
        'messages': messages,
        'temperature': _defaultTemperature,
        'max_tokens': _defaultMaxTokens,
      };

      return await _makeApiRequest(body, 'providers');
    } catch (e, s) {
      if (kDebugMode) {
        print('Error in general message flow: $e');
        print(s);
      }
      return 'I apologize, but I encountered an issue connecting to my servers. Please try again in a moment.';
    }
  }

  // Internal method for character chat flow
  static Future<String?> _sendCharacterMessage({
    required String characterId,
    required String message,
    required String systemPrompt,
    required List<Map<String, dynamic>> chatHistory,
    String? model,
  }) async {
    try {
      // Prepare request body
      final body = {
        'model': model ?? _defaultCharacterModel,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          ...chatHistory.map((msg) {
            // Ensure each message has a proper role field
            if (msg.containsKey('role')) {
              return {'role': msg['role'], 'content': msg['content']};
            } else if (msg.containsKey('isUser')) {
              return {
                'role': msg['isUser'] == true ? 'user' : 'assistant',
                'content': msg['content'],
              };
            } else {
              return {
                'role': 'user', // Default to user
                'content': msg['content'],
              };
            }
          }),
          {'role': 'user', 'content': message},
        ],
        'temperature': _defaultTemperature,
        'max_tokens': _defaultMaxTokens,
      };

      return await _makeApiRequest(body, 'character_chat');
    } catch (e, s) {
      if (kDebugMode) {
        print('Error in character message flow: $e');
        print(s);
      }
      return 'I apologize, but I encountered an issue connecting to my servers. Please try again in a moment.';
    }
  }

  // Internal method for interview chat flow
  static Future<String?> _sendInterviewMessage({
    required List<Map<String, dynamic>> messages,
    String? systemPrompt,
    String? model,
    double? temperature,
    int? maxTokens,
  }) async {
    try {
      final messagesList = <Map<String, dynamic>>[];

      if (systemPrompt?.isNotEmpty ?? false) {
        messagesList.add({'role': 'system', 'content': systemPrompt});
      }

      // Ensure each message has a valid 'role' field
      for (final msg in messages) {
        // Make a copy of the message to avoid modifying the original
        final Map<String, dynamic> formattedMsg = Map.from(msg);

        // Ensure the message has a role field
        if (!formattedMsg.containsKey('role')) {
          // If it has an 'isUser' field, use that to determine role
          if (formattedMsg.containsKey('isUser')) {
            formattedMsg['role'] =
                formattedMsg['isUser'] == true ? 'user' : 'assistant';
          } else {
            // Default to 'user' if we can't determine
            formattedMsg['role'] = 'user';
          }
        }

        messagesList.add(formattedMsg);
      }

      final body = {
        'model': model ?? _defaultInterviewModel,
        'messages': messagesList,
        'temperature': temperature ?? _defaultTemperature,
        'max_tokens': maxTokens ?? _defaultMaxTokens,
      };

      return await _makeApiRequest(body, 'character_interview');
    } catch (e, s) {
      if (kDebugMode) {
        print('Error in interview message flow: $e');
        print(s);
      }
      return 'I apologize, but I encountered an issue connecting to my servers. Please try again in a moment.';
    }
  }

  // Shared API request method
  static Future<String?> _makeApiRequest(
    Map<String, dynamic> body,
    String debugPrefix,
  ) async {
    try {
      // Send the request
      final response = await http
          .post(
            Uri.parse(_openRouterUrl),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer $_apiKey',
              'X-Title': 'Afterlife AI',
              'Accept': 'application/json; charset=utf-8',
            },
            body: jsonEncode(body),
          )
          .timeout(_requestTimeout);

      // Check if the request was successful
      if (response.statusCode == 200) {
        // Explicitly decode response body as UTF-8
        final responseBody = utf8.decode(response.bodyBytes);
        final jsonResponse = jsonDecode(responseBody);

        // Add null checks to prevent "The method '[]' was called on null" error
        if (jsonResponse == null ||
            jsonResponse['choices'] == null ||
            jsonResponse['choices'].isEmpty ||
            jsonResponse['choices'][0] == null ||
            jsonResponse['choices'][0]['message'] == null) {
          if (kDebugMode) {
            print(
              'Error in $debugPrefix: Invalid response format: $jsonResponse',
            );
          }
          return 'I apologize, I received an invalid response format. Please try again.';
        }

        final content = jsonResponse['choices'][0]['message']['content'];
        return content;
      } else {
        if (kDebugMode) {
          print(
            'API Error in $debugPrefix: ${response.statusCode}: ${response.body}',
          );
        }

        // Handle specific API errors with better user feedback
        switch (response.statusCode) {
          case 401:
            return 'Error: Invalid API key. Please check your OpenRouter API key in Settings.';
          case 403:
            return 'Error: API key does not have permission for this request. Please check your OpenRouter account.';
          case 429:
            return 'Error: Rate limit exceeded. Please try again in a few moments.';
          case 500:
          case 502:
          case 503:
            return 'Error: AI service is temporarily unavailable. Please try again later.';
          default:
            return 'Error: AI service returned an error (${response.statusCode}). Please try again.';
        }
      }
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        print('TimeoutException in $debugPrefix: $e');
      }
      return 'I apologize, but my response is taking longer than expected. Please try again in a moment.';
    } on http.ClientException catch (e) {
      if (kDebugMode) {
        print('ClientException in $debugPrefix: $e');
      }
      return 'It seems there is a network issue. Please check your internet connection.';
    } on FormatException catch (e) {
      if (kDebugMode) {
        print('FormatException in $debugPrefix: $e');
      }
      return 'I received an invalid response from the server. Please try again.';
    } catch (e, s) {
      if (kDebugMode) {
        print('Generic Exception in $debugPrefix: $e');
        print(s);
      }
      return 'I apologize, but I encountered an issue connecting to my servers. Please try again in a moment.';
    }
  }

  // Validate API key format (basic check for OpenRouter keys)
  static bool _isValidApiKeyFormat(String apiKey) {
    // OpenRouter API keys typically start with 'sk-or-' and are base64-like
    if (apiKey.length < 10) return false;
    if (!apiKey.startsWith('sk-or-') && !apiKey.startsWith('sk-')) return false;
    // Basic pattern check for common API key formats
    final pattern = RegExp(r'^sk-[A-Za-z0-9_-]+$');
    return pattern.hasMatch(apiKey);
  }

  // ========== BACKWARD COMPATIBILITY METHODS ==========

  // General chat compatibility (from providers/chat_service.dart)
  static Future<String?> sendGeneralMessage({
    required String message,
    required List<Map<String, String>> history,
    String? systemPrompt,
    String? model,
  }) async {
    // Convert List<Map<String, String>> to List<Map<String, dynamic>>
    final dynamicHistory =
        history.map((msg) => Map<String, dynamic>.from(msg)).toList();

    return await sendMessage(
      context: ChatContext.general,
      message: message,
      history: dynamicHistory,
      systemPrompt: systemPrompt,
      model: model,
    );
  }

  // Character chat compatibility (from character_chat/chat_service.dart)
  static Future<String?> sendMessageToCharacter({
    required String characterId,
    required String message,
    required String systemPrompt,
    required List<Map<String, dynamic>> chatHistory,
    String? model,
  }) async {
    return await sendMessage(
      context: ChatContext.character,
      characterId: characterId,
      message: message,
      systemPrompt: systemPrompt,
      history: chatHistory,
      model: model,
    );
  }

  // Interview compatibility (from character_interview/chat_service.dart)
  static Future<String?> sendInterviewMessage({
    required List<Map<String, dynamic>> messages,
    String? systemPrompt,
    String? model,
    double? temperature,
    int? maxTokens,
  }) async {
    return await sendMessage(
      context: ChatContext.interview,
      messages: messages,
      systemPrompt: systemPrompt,
      model: model,
      temperature: temperature,
      maxTokens: maxTokens,
    );
  }

  // Method for logging diagnostic info
  static void logDiagnostics() {
    if (kDebugMode) {
      AppLogger.debug('=== Unified Chat Service Diagnostics ===', tag: 'UnifiedChatService');
      AppLogger.debug('Is initialized: $_isInitialized', tag: 'UnifiedChatService');
      AppLogger.debug('Is using default key: $_isUsingDefaultKey', tag: 'UnifiedChatService');
      final keyStatus = _apiKey == null ? "NULL" : (_apiKey!.isEmpty ? "EMPTY" : "SET (${_apiKey!.substring(0, min(4, _apiKey!.length))}...)");
      AppLogger.debug('API key status: $keyStatus', tag: 'UnifiedChatService');
      AppLogger.debug('=============================', tag: 'UnifiedChatService');
    }
  }

  static int min(int a, int b) => a < b ? a : b;
}
