import 'package:flutter/foundation.dart';
import '../../core/services/unified_chat_service.dart';
import '../../core/utils/env_config.dart';

class ChatService {
  static bool _isInitialized = false;
  static String? _apiKey;
  static bool _isUsingDefaultKey = false;

  // Initialize the service - delegates to UnifiedChatService
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await UnifiedChatService.initialize();
      _isInitialized = true;

      // Sync state from UnifiedChatService for diagnostics
      _apiKey = EnvConfig.get('OPENROUTER_API_KEY');
      _isUsingDefaultKey = !(await EnvConfig.hasUserApiKey());

      if (kDebugMode) {
        print('Provider Chat Service: Delegating to UnifiedChatService');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing providers chat service: $e');
      }
      _isInitialized = true;
    }
  }

  // Method to refresh API key from the latest source
  static Future<void> refreshApiKey() async {
    try {
      if (kDebugMode) {
        print('Provider Chat Service: Refreshing API key...');
      }

      await UnifiedChatService.refreshApiKey();

      // Sync state for diagnostics
      _apiKey = EnvConfig.get('OPENROUTER_API_KEY');
      _isUsingDefaultKey = !(await EnvConfig.hasUserApiKey());

      if (kDebugMode) {
        print(
          'API key refreshed successfully - Using ${_isUsingDefaultKey ? 'default' : 'user\'s'} key',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error refreshing API key: $e');
      }
    }
  }

  // Send a message to the chat API using OpenRouter - delegates to UnifiedChatService
  static Future<String?> sendMessage({
    required String message,
    required List<Map<String, String>> history,
    String? systemPrompt,
    String? model,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Delegate to UnifiedChatService
    return await UnifiedChatService.sendGeneralMessage(
      message: message,
      history: history,
      systemPrompt: systemPrompt,
      model: model,
    );
  }

  // Send a message to a specific character - delegates to UnifiedChatService
  static Future<String?> sendMessageToCharacter({
    required String characterId,
    required String message,
    required String systemPrompt,
    required List<Map<String, String>> chatHistory,
    String? model,
  }) async {
    try {
      // Convert List<Map<String, String>> to List<Map<String, dynamic>> for compatibility
      final dynamicHistory =
          chatHistory.map((msg) => Map<String, dynamic>.from(msg)).toList();

      // Delegate to UnifiedChatService
      return await UnifiedChatService.sendMessageToCharacter(
        characterId: characterId,
        message: message,
        systemPrompt: systemPrompt,
        chatHistory: dynamicHistory,
        model: model,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error sending message to character: $e');
      }
      return 'Failed to communicate with the character';
    }
  }

  // Method for logging diagnostic info - maintains original behavior
  static void logDiagnostics() {
    if (kDebugMode) {
      print('=== Provider Chat Service Diagnostics ===');
      print('Is initialized: $_isInitialized');
      print('Is using default key: $_isUsingDefaultKey');
      print(
        'API key status: ${_apiKey == null ? "NULL" : (_apiKey!.isEmpty ? "EMPTY" : "SET (${_apiKey!.substring(0, min(4, _apiKey!.length))}...)")}',
      );
      print('Delegating to: UnifiedChatService');
      print('=============================');

      // Also log unified service diagnostics
      UnifiedChatService.logDiagnostics();
    }
  }

  static int min(int a, int b) => a < b ? a : b;
}
