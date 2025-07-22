import 'package:flutter/foundation.dart';
import '../../core/services/unified_chat_service.dart';
import '../../core/utils/env_config.dart';

class ChatService {
  static String? _apiKey;
  static bool _isInitialized = false;
  static bool _isUsingDefaultKey = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await UnifiedChatService.initialize();
      _isInitialized = true;

      // Sync state from UnifiedChatService for diagnostics
      _apiKey = EnvConfig.get('OPENROUTER_API_KEY');
      _isUsingDefaultKey = !(await EnvConfig.hasUserApiKey());

      if (kDebugMode) {
        print('Character Chat Service: Delegating to UnifiedChatService');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing character chat service: $e');
      }
      _isInitialized = true;
    }
  }

  // Method to refresh API key from the latest source
  static Future<void> refreshApiKey() async {
    try {
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
        print('Error refreshing API key in character chat: $e');
      }
    }
  }

  static Future<String?> sendMessageToCharacter({
    required String characterId,
    required String message,
    required String systemPrompt,
    required List<Map<String, dynamic>> chatHistory,
    String? model,
  }) async {
    // Ensure service is initialized
    if (!_isInitialized) {
      await initialize();
    }

    // Delegate to UnifiedChatService
    return await UnifiedChatService.sendMessageToCharacter(
      characterId: characterId,
      message: message,
      systemPrompt: systemPrompt,
      chatHistory: chatHistory,
      model: model,
    );
  }

  // Method for logging diagnostic info - maintains original behavior
  static void logDiagnostics() {
    if (kDebugMode) {
      print('=== Character Chat Service Diagnostics ===');
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
