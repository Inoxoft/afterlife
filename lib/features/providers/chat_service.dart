import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatService {
  static const String _openRouterUrl =
      'https://openrouter.ai/api/v1/chat/completions';
  static const String _openAiUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _defaultModel = 'google/gemini-2.0-flash-001';

  // Get API key from environment variables or use fallback
  static String? get _openRouterApiKey {
    try {
      return dotenv.env['OPENROUTER_API_KEY'] ??
          "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";
    } catch (e) {
      debugPrint('Error loading OpenRouter API key from .env: $e');
      return "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";
    }
  }

  // Send a message to the chat API using OpenRouter
  static Future<String> sendMessage({
    required String message,
    required List<Map<String, String>> history,
    String? systemPrompt,
  }) async {
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
        'max_tokens': 1000,
      };

      // Send the request
      final response = await http.post(
        Uri.parse(_openRouterUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_openRouterApiKey}',
          'HTTP-Referer': 'https://afterlife.app',
          'X-Title': 'Afterlife AI',
        },
        body: jsonEncode(body),
      );

      // Check if the request was successful
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final content = jsonResponse['choices'][0]['message']['content'];
        return content;
      } else {
        debugPrint('API Error: ${response.statusCode}: ${response.body}');
        throw Exception('Failed to get response: ${response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      throw Exception('Failed to communicate with the AI service: $e');
    }
  }

  // Send a message to a specific character
  static Future<String> sendMessageToCharacter({
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
      throw Exception('Failed to communicate with the character: $e');
    }
  }
}
