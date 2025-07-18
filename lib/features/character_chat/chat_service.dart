import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/utils/env_config.dart';

class ChatService {
  static final String _openRouterUrl =
      'https://openrouter.ai/api/v1/chat/completions';
  static const Duration _requestTimeout = Duration(
    seconds: 120,
  ); // 2 minutes timeout
  static String? _apiKey;
  static bool _isInitialized = false;
  static bool _isUsingDefaultKey = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize environment configuration
      await EnvConfig.initialize();

      // Get API key from environment
      _apiKey = EnvConfig.get('OPENROUTER_API_KEY');

      // Check if we're using a default key or a user key
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

  // Method to refresh API key from the latest source
  static Future<void> refreshApiKey() async {
    try {
      // Get the latest key directly
      _apiKey = EnvConfig.get('OPENROUTER_API_KEY');

      // Check if we're using a default key or a user key
      _isUsingDefaultKey = !(await EnvConfig.hasUserApiKey());

      if (_apiKey == null || _apiKey!.isEmpty) {
      } else {
        if (kDebugMode) {
          print(
            'API key refreshed successfully - Using ${_isUsingDefaultKey ? 'default' : 'user\'s'} key',
          );
        }
      }
    } catch (e) {}
  }

  static Future<String?> sendMessageToCharacter({
    required String characterId,
    required String message,
    required String systemPrompt,
    required List<Map<String, dynamic>> chatHistory,
    String? model,
  }) async {
    // Ensure service is initialized
    if (!_isInitialized) {
      await initialize();
    }

    // Always refresh the API key before sending a message
    await refreshApiKey();

    // Validate API key exists
    if (_apiKey == null || _apiKey!.isEmpty) {
      return 'Error: Unable to connect to AI service. Please check your API key configuration.';
    }

    // Prepare request body
    final body = jsonEncode({
      'model': model ?? 'anthropic/claude-3.5-sonnet',
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
      'temperature': 0.7,
      'max_tokens': 25000,
    });

    try {
      // Send request
      final response = await http
          .post(
            Uri.parse(_openRouterUrl),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer $_apiKey',
              // 'HTTP-Referer': 'https://afterlife.app',
              'X-Title': 'Afterlife AI',
              'Accept': 'application/json; charset=utf-8',
            },
            body: body,
          )
          .timeout(_requestTimeout);

      if (response.statusCode != 200) {
        if (kDebugMode) {
          print(
            'API Error in character_chat: ${response.statusCode}: ${response.body}',
          );
        }
        return 'I apologize, but I encountered a server error. Please try again.';
      }

      // Parse response with explicit UTF-8 decoding
      final responseBody = utf8.decode(response.bodyBytes);
      final data = jsonDecode(responseBody);

      // Add null checks to prevent "The method '[]' was called on null" error
      if (data == null ||
          data['choices'] == null ||
          data['choices'].isEmpty ||
          data['choices'][0] == null ||
          data['choices'][0]['message'] == null) {
        if (kDebugMode) {
          print('Error in character_chat: Invalid response format: $data');
        }
        return 'I apologize, I received an invalid response format. Please try again.';
      }

      return data['choices'][0]['message']['content'] as String;
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        print('TimeoutException in character_chat: $e');
      }
      return 'I apologize, but my response is taking longer than expected. Please try again in a moment.';
    } on http.ClientException catch (e) {
      if (kDebugMode) {
        print('ClientException in character_chat: $e');
      }
      return 'It seems there is a network issue. Please check your internet connection.';
    } catch (e, s) {
      if (kDebugMode) {
        print('Generic Exception in character_chat: $e');
        print(s);
      }
      return 'I apologize, but I encountered an issue connecting to my servers. Please try again in a moment.';
    }
  }

  // Method for logging diagnostic info
  static void logDiagnostics() {
    if (kDebugMode) {
      print(
        'API key status: ${_apiKey == null ? "NULL" : (_apiKey!.isEmpty ? "EMPTY" : "SET (${_apiKey!.substring(0, min(4, _apiKey!.length))}...)")}',
      );
    }
  }

  static int min(int a, int b) => a < b ? a : b;
}
