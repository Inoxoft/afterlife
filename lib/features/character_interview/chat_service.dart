import 'dart:convert';
import 'dart:math';
// lib/features/character_interview/chat_service.dart
import 'dart:async';
import 'package:http/http.dart' as http;
import '../../core/utils/env_config.dart';
import 'package:flutter/foundation.dart';

class ChatService {
  static const String _openRouterUrl =
      'https://openrouter.ai/api/v1/chat/completions';
  static const Duration _requestTimeout = Duration(seconds: 120);
  static const String _defaultModel = 'google/gemini-2.5-flash';
  static const double _defaultTemperature = 0.7;
  static const int _defaultMaxTokens = 25000;

  static String? _apiKey;
  static bool _isInitialized = false;
  static bool _isUsingDefaultKey = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize and load environment config
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
      _isInitialized =
          true; // Still mark as initialized to prevent repeated attempts
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
        if (kDebugMode) {
          print('Warning: API key refresh failed - No key found');
        }
      } else {
        if (kDebugMode) {
          print(
            'API key refreshed successfully - Using ${_isUsingDefaultKey ? 'default' : 'user\'s'} key',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error refreshing API key: $e');
      }
    }
  }

  static Future<String?> sendMessage({
    required List<Map<String, dynamic>> messages,
    String? systemPrompt,
    String? model,
    double? temperature,
    int? maxTokens,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Always refresh the API key before sending a message
    await refreshApiKey();

    // Validate API key exists
    if (_apiKey == null || _apiKey!.isEmpty) {
      return 'Error: Unable to connect to AI service. Please check your API key configuration.';
    }

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

    final body = jsonEncode({
      'model': model ?? _defaultModel,
      'messages': messagesList,
      'temperature': temperature ?? _defaultTemperature,
      'max_tokens': maxTokens ?? _defaultMaxTokens,
    });

    try {
      // Log headers and API key for debugging
      logDiagnostics();

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
        final errorMessage =
            'API error (${response.statusCode}): ${response.body}';
        if (kDebugMode) {
          print('Error in character_interview: $errorMessage');
        }
        return 'I apologize, I encountered a server error. Please try again.';
      }

      // Explicitly decode response body as UTF-8
      final responseBody = utf8.decode(response.bodyBytes);
      final data = jsonDecode(responseBody);

      // Add null checks to prevent "The method '[]' was called on null" error
      if (data == null ||
          data['choices'] == null ||
          data['choices'].isEmpty ||
          data['choices'][0] == null ||
          data['choices'][0]['message'] == null) {
        if (kDebugMode) {
          print('Error in character_interview: Invalid response format: $data');
        }
        return 'I apologize, I received an invalid response format. Please try again.';
      }

      return data['choices'][0]['message']['content'] as String;
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        print('TimeoutException in character_interview: $e');
      }
      return 'I apologize, but my response is taking longer than expected. Please try again in a moment.';
    } on http.ClientException catch (e) {
      if (kDebugMode) {
        print('ClientException in character_interview: $e');
      }
      return 'It seems there is a network issue. Please check your internet connection.';
    } on FormatException catch (e) {
      if (kDebugMode) {
        print('FormatException in character_interview: $e');
      }
      return 'I received an invalid response from the server. Please try again.';
    } catch (e, s) {
      if (kDebugMode) {
        print('Unexpected error in character_interview: $e');
        print(s);
      }
      return 'I apologize, but I encountered an issue connecting to my servers. Please try again in a moment.';
    }
  }

  // Method for logging diagnostic info
  static void logDiagnostics() {
    if (kDebugMode) {
      print(
        'API key status: ${_apiKey == null ? "NULL" : (_apiKey!.isEmpty ? "EMPTY" : "SET (${_apiKey!.substring(0, min(8, _apiKey!.length))}...)")}',
      );
    }
  }
}

int min(int a, int b) => a < b ? a : b;
