// lib/features/character_interview/chat_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatService {
  static const String _openRouterUrl =
      'https://openrouter.ai/api/v1/chat/completions';
  static const Duration _requestTimeout = Duration(seconds: 30);
  static const String _defaultModel = 'google/gemini-2.0-flash-001';
  static const double _defaultTemperature = 0.7;
  static const int _defaultMaxTokens = 1000;

  static late String _apiKey;
  static bool _isInitialized = false;
  static bool _isUsingDefaultKey = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await dotenv.load();
      _apiKey = dotenv.env['OPENROUTER_API_KEY'] ?? '';

      if (_apiKey.isEmpty) {
        _apiKey = "";
        _isUsingDefaultKey = true;
        print(
          'Warning: Using default API key. Set OPENROUTER_API_KEY in .env file for production.',
        );
      }

      _isInitialized = true;
    } catch (e) {
      print('Error initializing chat service: $e');
      _apiKey = "";
      _isUsingDefaultKey = true;
      _isInitialized =
          true; // Still mark as initialized to prevent repeated attempts
    }
  }

  static Future<String> sendMessage({
    required List<Map<String, dynamic>> messages,
    String? systemPrompt,
    String? model,
    double? temperature,
    int? maxTokens,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isUsingDefaultKey) {
      print(
        'Warning: Using default API key - this is not recommended for production',
      );
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
      throw ChatServiceException('Unexpected error occurred');
    }
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
