import '../../core/services/base_chat_service.dart';

/// Character Chat Service - delegates to BaseChatService
/// This eliminates code duplication while maintaining the same API
class ChatService {
  static const String _serviceName = 'CharacterChatService';

  /// Initialize the service
  static Future<void> initialize() async {
    await BaseChatService.initialize(serviceName: _serviceName);
  }

  /// Refresh API key from the latest source
  static Future<void> refreshApiKey() async {
    await BaseChatService.refreshApiKey(serviceName: _serviceName);
  }

  /// Send a message to a specific character
  static Future<String?> sendMessageToCharacter({
    required String characterId,
    required String message,
    required String systemPrompt,
    required List<Map<String, dynamic>> chatHistory,
    String? model,
  }) async {
    return await BaseChatService.sendMessageToCharacter(
      characterId: characterId,
      message: message,
      systemPrompt: systemPrompt,
      chatHistory: chatHistory,
      model: model,
    );
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
