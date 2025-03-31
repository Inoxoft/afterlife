// lib/features/character_interview/chat_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatService {
  final String _openRouterUrl = 'https://openrouter.ai/api/v1/chat/completions';
  final List<Map<String, dynamic>> _messageHistory = [];
  late String _apiKey;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Get API key from .env file
      _apiKey = dotenv.env['OPENROUTER_API_KEY'] ?? '';

      // Fallback to default key if not found in .env (only for development)
      if (_apiKey.isEmpty) {
        _apiKey =
            "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";
        print(
          'Warning: Using default API key. Set OPENROUTER_API_KEY in .env file for production.',
        );
      }

      _isInitialized = true;
    } catch (e) {
      print('Error initializing chat service: $e');
      // Use default key as last resort
      _apiKey =
          "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";
    }
  }

  Future<String> sendMessage(String userMessage, {String? systemPrompt}) async {
    // Ensure service is initialized
    if (!_isInitialized) {
      await initialize();
    }

    // Add user message to history
    _messageHistory.add({'role': 'user', 'content': userMessage});

    // Prepare request body
    final body = jsonEncode({
      'model':
          'google/gemini-2.0-flash-001', // Or any model available on OpenRouter
      'messages': [
        if (systemPrompt != null && systemPrompt.isNotEmpty)
          {'role': 'system', 'content': systemPrompt},
        ..._messageHistory,
      ],
      'temperature': 0.7,
      'max_tokens': 1000,
    });

    try {
      // Send request
      final response = await http.post(
        Uri.parse(_openRouterUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'HTTP-Referer':
              'https://afterlife.app', // Replace with your app's URL
          'X-Title': 'Afterlife AI', // Your app name
        },
        body: body,
      );

      if (response.statusCode != 200) {
        print('API error: ${response.body}');
        throw Exception('Failed to get response: ${response.body}');
      }

      // Parse response
      final data = jsonDecode(response.body);
      final assistantMessage =
          data['choices'][0]['message']['content'] as String;

      // Add assistant response to history
      _messageHistory.add({'role': 'assistant', 'content': assistantMessage});

      return assistantMessage;
    } catch (e) {
      // Add better error handling
      print('Error in chat service: $e');
      // Add error message to history for continuity
      final errorMessage =
          'I apologize, but I encountered an issue connecting to my servers. Please try again in a moment.';
      _messageHistory.add({'role': 'assistant', 'content': errorMessage});
      return errorMessage;
    }
  }

  void clearHistory() {
    _messageHistory.clear();
  }
}
