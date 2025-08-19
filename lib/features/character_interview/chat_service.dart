// lib/features/character_interview/chat_service.dart
import '../../core/services/base_chat_service.dart';

/// Character Interview Service - delegates to BaseChatService
/// This eliminates code duplication while maintaining the same API
class ChatService {
  static const String _serviceName = 'CharacterInterviewService';

  /// Initialize the service
  static Future<void> initialize() async {
    await BaseChatService.initialize(serviceName: _serviceName);
  }

  /// Refresh API key from the latest source
  static Future<void> refreshApiKey() async {
    await BaseChatService.refreshApiKey(serviceName: _serviceName);
  }

  /// Send a message for character interview
  static Future<String?> sendMessage({
    required List<Map<String, dynamic>> messages,
    String? systemPrompt,
    String? model,
    double? temperature,
    int? maxTokens,
  }) async {
    return await BaseChatService.sendInterviewMessage(
      messages: messages,
      systemPrompt: systemPrompt,
      model: model,
      temperature: temperature,
      maxTokens: maxTokens,
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
