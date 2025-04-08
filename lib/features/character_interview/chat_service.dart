// lib/features/character_interview/chat_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatService {
  static final String _openRouterUrl =
      'https://openrouter.ai/api/v1/chat/completions';
  static late String _apiKey;
  static bool _isInitialized = false;

  static Future<void> initialize() async {
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

  static Future<String> sendMessage({
    required List<Map<String, dynamic>> messages,
    String? systemPrompt,
  }) async {
    // Ensure service is initialized
    if (!_isInitialized) {
      await initialize();
    }

    // Prepare message list
    final List<Map<String, dynamic>> messagesList = [];

    // Add system message if provided
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      messagesList.add({'role': 'system', 'content': systemPrompt});
    }

    // Add conversation messages
    messagesList.addAll(messages);

    // Prepare request body
    final body = jsonEncode({
      'model': 'google/gemini-2.0-flash-001',
      'messages': messagesList,
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
          'HTTP-Referer': 'https://afterlife.app',
          'X-Title': 'Afterlife AI',
        },
        body: body,
      );

      if (response.statusCode != 200) {
        print('API error: ${response.body}');
        throw Exception('Failed to get response: ${response.body}');
      }

      // Parse response
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] as String;
    } catch (e) {
      print('Error in chat service: $e');
      return 'I apologize, but I encountered an issue connecting to my servers. Please try again in a moment.';
    }
  }
}

// Helper function to avoid importing dart:math
int min(int a, int b) => a < b ? a : b;
