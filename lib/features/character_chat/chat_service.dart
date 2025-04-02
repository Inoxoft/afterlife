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

  static Future<String> sendMessageToCharacter({
    required String characterId,
    required String message,
    required String systemPrompt,
    required List<Map<String, dynamic>> chatHistory,
  }) async {
    // Ensure service is initialized
    if (!_isInitialized) {
      await initialize();
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
