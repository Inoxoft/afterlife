import 'dart:convert';
import 'dart:math';
// lib/features/character_interview/chat_service.dart
import 'dart:async';
import 'package:http/http.dart' as http;
import '../../core/utils/env_config.dart';

class ChatService {
  static const String _openRouterUrl =
      'https://openrouter.ai/api/v1/chat/completions';
  static const Duration _requestTimeout = Duration(seconds: 120);
  static const String _defaultModel = 'google/gemini-2.5-flash-preview-05-20';
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
        print(
          'Warning: No OpenRouter API key found. The application will not function properly.',
        );
        print(
          'Please set OPENROUTER_API_KEY in your .env file or in Settings.',
        );
      } else {
        print(
          'API key loaded successfully - Using ${_isUsingDefaultKey ? 'default' : 'user\'s'} key',
        );
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
        print(
          'Warning: API key refresh failed - No key found',
        );
      } else {
        print(
          'API key refreshed successfully - Using ${_isUsingDefaultKey ? 'default' : 'user\'s'} key',
        );
      }
    } catch (e) {
      print('Error refreshing API key: $e');
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
    messagesList.addAll(messages);

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
              'HTTP-Referer': 'https://afterlife.app',
              'X-Title': 'Afterlife AI',
              'Accept': 'application/json; charset=utf-8',
            },
            body: body,
          )
          .timeout(_requestTimeout);

      if (response.statusCode != 200) {
        final errorMessage =
            'API error (${response.statusCode}): ${response.body}';
        throw ChatServiceException(errorMessage);
      }

      // Explicitly decode response body as UTF-8
      final responseBody = utf8.decode(response.bodyBytes);
      final data = jsonDecode(responseBody);
      return data['choices'][0]['message']['content'] as String;
    } on http.ClientException catch (e) {
      throw ChatServiceException('Network error: ${e.message}');
    } on FormatException catch (e) {
      throw ChatServiceException('Invalid response format');
    } catch (e) {
      throw ChatServiceException('Unexpected error occurred: $e');
    }
  }

  // Method for logging diagnostic info
  static void logDiagnostics() {
    print(
      'API key status: ${_apiKey == null ? "NULL" : (_apiKey!.isEmpty ? "EMPTY" : "SET (${_apiKey!.substring(0, min(8, _apiKey!.length))}...)")}',
    );
  }
}

class ChatServiceException implements Exception {
  final String message;
  ChatServiceException(this.message);

  @override
  String toString() => 'ChatServiceException: $message';
}

int min(int a, int b) => a < b ? a : b;
