import '../../core/services/base_chat_service.dart';

/// Provider Chat Service - delegates to BaseChatService
/// This eliminates code duplication while maintaining the same API
class ChatService {
  static const String _serviceName = 'ProviderChatService';

  /// Initialize the service
  static Future<void> initialize() async {
    await BaseChatService.initialize(serviceName: _serviceName);
  }

  /// Refresh API key from the latest source
  static Future<void> refreshApiKey() async {
    await BaseChatService.refreshApiKey(serviceName: _serviceName);
  }

  /// Send a general message
  static Future<String?> sendMessage({
    required String message,
    required List<Map<String, String>> history,
    String? systemPrompt,
    String? model,
  }) async {
    return await BaseChatService.sendGeneralMessage(
      message: message,
      history: history,
      systemPrompt: systemPrompt,
      model: model,
    );
  }

  /// Send a message to a specific character
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

      return await BaseChatService.sendMessageToCharacter(
        characterId: characterId,
        message: message,
        systemPrompt: systemPrompt,
        chatHistory: dynamicHistory,
        model: model,
      );
    } catch (e) {
      // Use AppLogger instead of print for consistency
      return 'Failed to communicate with the character';
    }
  }

  /// Log diagnostic information
  static void logDiagnostics() {
    BaseChatService.logDiagnostics(serviceName: _serviceName);
  }

  /// Get initialization status
  static bool get isInitialized => BaseChatService.isInitialized;

  /// Get API key status
  static bool get hasApiKey => BaseChatService.hasApiKey;

  /// Get whether using default key
  static bool get isUsingDefaultKey => BaseChatService.isUsingDefaultKey;
}
