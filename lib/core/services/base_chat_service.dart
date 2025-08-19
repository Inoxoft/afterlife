import 'unified_chat_service.dart';
import '../utils/env_config.dart';
import '../utils/app_logger.dart';

/// Base ChatService that consolidates all chat functionality
/// Eliminates the need for duplicate ChatService classes across features
class BaseChatService {
  static String? _apiKey;
  static bool _isInitialized = false;
  static bool _isUsingDefaultKey = false;

  /// Initialize the chat service
  static Future<void> initialize({String? serviceName}) async {
    if (_isInitialized) return;

    try {
      await UnifiedChatService.initialize();
      _isInitialized = true;

      // Sync state from UnifiedChatService for diagnostics
      _apiKey = EnvConfig.get('OPENROUTER_API_KEY');
      _isUsingDefaultKey = !(await EnvConfig.hasUserApiKey());

      AppLogger.serviceInitialized(serviceName ?? 'BaseChatService');
    } catch (e) {
      AppLogger.serviceError(
        serviceName ?? 'BaseChatService',
        'initialization failed',
        e,
      );
      _isInitialized = true; // Mark as initialized to prevent repeated attempts
    }
  }

  /// Refresh API key from the latest source
  static Future<void> refreshApiKey({String? serviceName}) async {
    try {
      await UnifiedChatService.refreshApiKey();

      // Sync state for diagnostics
      _apiKey = EnvConfig.get('OPENROUTER_API_KEY');
      _isUsingDefaultKey = !(await EnvConfig.hasUserApiKey());

      AppLogger.debug(
        'API key refreshed successfully - Using ${_isUsingDefaultKey ? 'default' : 'user\'s'} key',
        tag: serviceName ?? 'BaseChatService',
      );
    } catch (e) {
      AppLogger.error(
        'Error refreshing API key',
        tag: serviceName ?? 'BaseChatService',
        error: e,
      );
    }
  }

  /// Send a general message
  static Future<String?> sendGeneralMessage({
    required String message,
    required List<Map<String, String>> history,
    String? systemPrompt,
    String? model,
  }) async {
    await _ensureInitialized();

    return await UnifiedChatService.sendGeneralMessage(
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
    required List<Map<String, dynamic>> chatHistory,
    String? model,
  }) async {
    await _ensureInitialized();

    return await UnifiedChatService.sendMessageToCharacter(
      characterId: characterId,
      message: message,
      systemPrompt: systemPrompt,
      chatHistory: chatHistory,
      model: model,
    );
  }

  /// Send a message for character interview
  static Future<String?> sendInterviewMessage({
    required List<Map<String, dynamic>> messages,
    String? systemPrompt,
    String? model,
    double? temperature,
    int? maxTokens,
  }) async {
    await _ensureInitialized();

    return await UnifiedChatService.sendInterviewMessage(
      messages: messages,
      systemPrompt: systemPrompt,
      model: model,
      temperature: temperature,
      maxTokens: maxTokens,
    );
  }

  /// Ensure service is initialized before operations
  static Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Log diagnostic information
  static void logDiagnostics({String? serviceName}) {
    final name = serviceName ?? 'BaseChatService';
    AppLogger.debug('=== $name Diagnostics ===', tag: name);
    AppLogger.debug('Is initialized: $_isInitialized', tag: name);
    AppLogger.debug('Is using default key: $_isUsingDefaultKey', tag: name);
    
    final keyStatus = _apiKey == null 
        ? "NULL" 
        : (_apiKey!.isEmpty 
            ? "EMPTY" 
            : "SET (${_apiKey!.substring(0, _min(4, _apiKey!.length))}...)");
    
    AppLogger.debug('API key status: $keyStatus', tag: name);
    AppLogger.debug('Delegating to: UnifiedChatService', tag: name);
    AppLogger.debug('=============================', tag: name);

    // Also log unified service diagnostics
    UnifiedChatService.logDiagnostics();
  }

  /// Get initialization status
  static bool get isInitialized => _isInitialized;

  /// Get API key status
  static bool get hasApiKey => _apiKey != null && _apiKey!.isNotEmpty;

  /// Get whether using default key
  static bool get isUsingDefaultKey => _isUsingDefaultKey;

  /// Helper method for min calculation
  static int _min(int a, int b) => a < b ? a : b;
} 