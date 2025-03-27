// lib/features/character_interview/chat_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';


class ChatService {
  final String _openRouterUrl = 'https://openrouter.ai/api/v1/chat/completions';
  final List<Map<String, dynamic>> _messageHistory = [];
  
  // Hard-coded API key - REPLACE WITH YOUR ACTUAL KEY
  // For production, use secure storage or environment variables
  static const String _defaultApiKey = "";
  
  Future<void> initialize() async {
    // This method is kept for potential future initialization logic
    // Default implementation uses the hard-coded key
  }
  
  Future<String> sendMessage(String userMessage, {String? systemPrompt}) async {
    // Add user message to history
    _messageHistory.add({
      'role': 'user',
      'content': userMessage,
    });
    
    // Prepare request body
    final body = jsonEncode({
      'model': 'google/gemini-2.0-flash-001', // Or any model available on OpenRouter
      'messages': [
        if (systemPrompt != null && systemPrompt.isNotEmpty)
          {
            'role': 'system',
            'content': systemPrompt,
          },
        ..._messageHistory,
      ],
      'temperature': 0.7,
      'max_tokens': 1000,
    });
    
    // Send request
    final response = await http.post(
      Uri.parse(_openRouterUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_defaultApiKey',
        'HTTP-Referer': 'https://afterlife.app', // Replace with your app's URL
        'X-Title': 'Afterlife AI', // Your app name
      },
      body: body,
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to get response: ${response.body}');
    }
    
    // Parse response
    final data = jsonDecode(response.body);
    final assistantMessage = data['choices'][0]['message']['content'] as String;
    
    // Add assistant response to history
    _messageHistory.add({
      'role': 'assistant',
      'content': assistantMessage,
    });
    
    return assistantMessage;
  }
  
  void clearHistory() {
    _messageHistory.clear();
  }
}
