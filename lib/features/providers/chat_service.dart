import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/utils/env_config.dart';

class ChatService {
  static const String _openRouterUrl =
      'https://openrouter.ai/api/v1/chat/completions';
  static const String _openAiUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _defaultModel = 'google/gemini-2.0-flash-001';
  static const Duration _requestTimeout = Duration(
    seconds: 120,
  ); // 2 minutes timeout
  static bool _isInitialized = false;
  static String? _apiKey;

  // Initialize the service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize environment configuration
      await EnvConfig.initialize();

      // Get API key from environment
      _apiKey = EnvConfig.get('OPENROUTER_API_KEY');

      if (_apiKey == null || _apiKey!.isEmpty) {
        debugPrint(
          'Warning: No OpenRouter API key found. The application will not function properly.',
        );
        debugPrint('Please set OPENROUTER_API_KEY in your .env file.');
      } else {
        debugPrint('API key loaded successfully for provider chat service');
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing chat service: $e');
      _isInitialized = true; // Mark as initialized to prevent repeated attempts
    }
  }

  // Send a message to the chat API using OpenRouter
  static Future<String?> sendMessage({
    required String message,
    required List<Map<String, String>> history,
    String? systemPrompt,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Validate API key
    if (_apiKey == null || _apiKey!.isEmpty) {
      debugPrint('Error: API key is missing. Cannot send message.');
      return 'Error: Unable to connect to AI service. Please check your API key configuration.';
    }

    try {
      // Prepare the request payload
      final List<Map<String, String>> messages = [];

      // Add system prompt if provided
      if (systemPrompt != null && systemPrompt.isNotEmpty) {
        messages.add({'role': 'system', 'content': systemPrompt});
      }

      // Add chat history
      for (final msg in history) {
        messages.add(msg);
      }

      // Add the new user message
      messages.add({'role': 'user', 'content': message});

      // Create the request body
      final body = {
        'model': _defaultModel,
        'messages': messages,
        'temperature': 0.7,
        'max_tokens': 25000,
      };

      // Send the request
      final response = await http
          .post(
            Uri.parse(_openRouterUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
              'HTTP-Referer': 'https://afterlife.app',
              'X-Title': 'Afterlife AI',
            },
            body: jsonEncode(body),
          )
          .timeout(_requestTimeout);

      // Check if the request was successful
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final content = jsonResponse['choices'][0]['message']['content'];
        return content;
      } else {
        debugPrint('API Error: ${response.statusCode}: ${response.body}');
        throw Exception('Failed to get response: ${response.reasonPhrase}');
      }
    } on TimeoutException catch (e) {
      debugPrint(
        'Request timed out after ${_requestTimeout.inSeconds} seconds: $e',
      );
      return 'I apologize, but my response is taking longer than expected. Please try again in a moment.';
    } catch (e) {
      debugPrint('Error sending message: $e');
      return 'I apologize, but I encountered an issue connecting to my servers. Please try again in a moment.';
    }
  }

  // Send a message to a specific character
  static Future<String?> sendMessageToCharacter({
    required String characterId,
    required String message,
    required String systemPrompt,
    required List<Map<String, String>> chatHistory,
  }) async {
    try {
      // Send the message with the character's system prompt and chat history
      return await sendMessage(
        message: message,
        history: chatHistory,
        systemPrompt: systemPrompt,
      );
    } catch (e) {
      debugPrint('Error sending message to character: $e');
      return 'Failed to communicate with the character';
    }
  }

  // Method for logging diagnostic info
  static void logDiagnostics() {
    debugPrint('=== Provider Chat Service Diagnostics ===');
    debugPrint('Is initialized: $_isInitialized');
    debugPrint(
      'API key status: ${_apiKey == null ? "NULL" : (_apiKey!.isEmpty ? "EMPTY" : "SET (${_apiKey!.substring(0, min(4, _apiKey!.length))}...)")}',
    );
    debugPrint('=============================');
  }

  // Helper function to avoid importing dart:math
  static int min(int a, int b) => a < b ? a : b;
}
