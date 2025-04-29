import 'dart:convert';
import 'dart:async';
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

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize environment configuration
      await EnvConfig.initialize();

      // Get API key from environment
      _apiKey = EnvConfig.get('OPENROUTER_API_KEY');

      // Check the source of the API key
      final hasUserKey = await EnvConfig.hasUserApiKey();

      if (_apiKey == null || _apiKey!.isEmpty) {
        print(
          'Warning: No OpenRouter API key found. The application will not function properly.',
        );
        print('Please set OPENROUTER_API_KEY in your .env file.');
      } else if (hasUserKey) {
        print(
          'Character Chat Service: Using user-specified API key ${_apiKey!.substring(0, min(4, _apiKey!.length))}...',
        );
      } else {
        print(
          'Character Chat Service: Using .env file API key ${_apiKey!.substring(0, min(4, _apiKey!.length))}...',
        );
      }

      _isInitialized = true;
    } catch (e) {
      print('Error initializing character chat service: $e');
      _isInitialized = true; // Mark as initialized to prevent repeated attempts
    }
  }

  // Method to refresh API key from the latest source
  static Future<void> refreshApiKey() async {
    try {
      print('Character Chat Service: Refreshing API key...');

      // Get the latest key directly
      _apiKey = EnvConfig.get('OPENROUTER_API_KEY');

      // Check the source of the API key
      final hasUserKey = await EnvConfig.hasUserApiKey();

      if (_apiKey == null || _apiKey!.isEmpty) {
        print('Warning: No API key found after refresh');
      } else if (hasUserKey) {
        print(
          'Character Chat Service: Now using user-specified API key ${_apiKey!.substring(0, min(4, _apiKey!.length))}...',
        );
      } else {
        print(
          'Character Chat Service: Now using .env file API key ${_apiKey!.substring(0, min(4, _apiKey!.length))}...',
        );
      }
    } catch (e) {
      print('Error refreshing API key: $e');
    }
  }

  static Future<String?> sendMessageToCharacter({
    required String characterId,
    required String message,
    required String systemPrompt,
    required List<Map<String, dynamic>> chatHistory,
  }) async {
    // Ensure service is initialized
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

    // Prepare request body
    final body = jsonEncode({
      'model': 'google/gemini-2.0-flash-001',
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        ...chatHistory,
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
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
              'HTTP-Referer': 'https://afterlife.app',
              'X-Title': 'Afterlife AI',
            },
            body: body,
          )
          .timeout(_requestTimeout);

      if (response.statusCode != 200) {
        print('API error: ${response.body}');
        throw Exception('Failed to get response: ${response.body}');
      }

      // Parse response
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] as String;
    } on TimeoutException catch (e) {
      print('Request timed out after ${_requestTimeout.inSeconds} seconds: $e');
      return 'I apologize, but my response is taking longer than expected. Please try again in a moment.';
    } catch (e) {
      print('Error in chat service: $e');
      return 'I apologize, but I encountered an issue connecting to my servers. Please try again in a moment.';
    }
  }

  // Method for logging diagnostic info
  static void logDiagnostics() {
    print('=== Character Chat Service Diagnostics ===');
    print('Is initialized: $_isInitialized');
    print(
      'API key status: ${_apiKey == null ? "NULL" : (_apiKey!.isEmpty ? "EMPTY" : "SET (${_apiKey!.substring(0, min(4, _apiKey!.length))}...)")}',
    );
    print('=============================');
  }

  // Helper function to avoid importing dart:math
  static int min(int a, int b) => a < b ? a : b;
}
