// lib/features/character_interview/chat_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/utils/env_config.dart';

class ChatService {
  static const String _openRouterUrl =
      'https://openrouter.ai/api/v1/chat/completions';
  static const Duration _requestTimeout = Duration(seconds: 120);
  static const String _defaultModel = 'google/gemini-2.0-flash-001';
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
          'WARNING: No OpenRouter API key found. The application will not function properly.',
        );
        print('Please set OPENROUTER_API_KEY in your .env file or in Settings.');
      } else {
        print('API key loaded successfully - Using ${_isUsingDefaultKey ? 'default' : 'user\'s'} key');
      }

      _isInitialized = true;
    } catch (e) {
      print('Error initializing chat service: $e');
      _isInitialized =
          true; // Still mark as initialized to prevent repeated attempts
    }
  }

  // Method to refresh API key from the latest source
  static Future<void> refreshApiKey() async {
    try {
      print('Interview Chat Service: Refreshing API key...');

      // Get the latest key directly
      _apiKey = EnvConfig.get('OPENROUTER_API_KEY');

      // Check if we're using a default key or a user key
      _isUsingDefaultKey = !(await EnvConfig.hasUserApiKey());

      if (_apiKey == null || _apiKey!.isEmpty) {
        print('Warning: No API key found after refresh');
      } else {
        print('API key refreshed successfully - Using ${_isUsingDefaultKey ? 'default' : 'user\'s'} key');
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
      print('Error: API key is missing. Cannot send message.');
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
      print('Interview Chat Service: Sending request with API key: ${_apiKey!.substring(0, min(4, _apiKey!.length))}...');
      print('Is using default key: $_isUsingDefaultKey');
      
      final response = await http
          .post(
            Uri.parse(_openRouterUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
              'HTTP-Referer': 'https://afterlife.app',
              'X-Title': 'Afterlife AI',
            },
            body: body,
          )
          .timeout(_requestTimeout);

      if (response.statusCode != 200) {
        final errorMessage =
            'API error (${response.statusCode}): ${response.body}';
        print(errorMessage);
        throw ChatServiceException(errorMessage);
      }

      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] as String;
    } on http.ClientException catch (e) {
      print('Network error in chat service: $e');
      throw ChatServiceException('Network error: ${e.message}');
    } on FormatException catch (e) {
      print('Invalid response format: $e');
      throw ChatServiceException('Invalid response format');
    } catch (e) {
      print('Unexpected error in chat service: $e');
      throw ChatServiceException('Unexpected error occurred: $e');
    }
  }

  // Method for logging diagnostic info
  static void logDiagnostics() {
    print('=== ChatService Diagnostics ===');
    print('Is initialized: $_isInitialized');
    print('Is using default key: $_isUsingDefaultKey');
    print(
      'API key status: ${_apiKey == null ? "NULL" : (_apiKey!.isEmpty ? "EMPTY" : "SET (${_apiKey!.substring(0, min(8, _apiKey!.length))}...)")}',
    );
    print('=============================');
  }
}

class ChatServiceException implements Exception {
  final String message;
  ChatServiceException(this.message);

  @override
  String toString() => 'ChatServiceException: $message';
}

// Helper function to avoid importing dart:math
int min(int a, int b) => a < b ? a : b;
