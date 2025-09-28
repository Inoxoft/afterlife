import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:afterlife/core/services/local_llm_service.dart';
import 'preferences_service.dart';
import '../utils/app_logger.dart';
import '../../features/character_interview/chat_service.dart' as interview_chat;
import '../../features/character_chat/chat_service.dart' as character_chat;
import '../../features/providers/chat_service.dart' as provider_chat;

enum LLMProvider {
  local,
  openRouter,
  auto, // Automatically choose based on availability
}

class ServiceAvailability {
  final bool localLLM;
  final bool interviewChat;
  final bool characterChat;
  final bool providerChat;
  final List<String> errors;

  const ServiceAvailability({
    required this.localLLM,
    required this.interviewChat,
    required this.characterChat,
    required this.providerChat,
    this.errors = const [],
  });

  bool get hasAnyWorkingService =>
      localLLM || interviewChat || characterChat || providerChat;
  // Allow local-only usage when cloud providers are unavailable
  bool get canSendMessages => localLLM || interviewChat || characterChat || providerChat;
}

class HybridChatService {
  static HybridChatService? _instance;
  static HybridChatService get instance => _instance ??= HybridChatService._();
  HybridChatService._();

  static LLMProvider _preferredProvider = LLMProvider.auto;
  static bool _isInitialized = false;
  static ServiceAvailability _serviceAvailability = const ServiceAvailability(
    localLLM: false,
    interviewChat: false,
    characterChat: false,
    providerChat: false,
  );

  // Style guide to steer local models toward concise, in-character answers
  static const String _localStyleGuide =
      """
STYLE:
- Stay strictly in character; use first-person voice and era-appropriate style.
- Be concise: 2–4 sentences unless the user asks for depth.
- No generic encyclopedia summaries; answer directly to the user prompt.
- Warm, conversational tone; ask a clarifying follow-up when helpful.
- Do not include role labels (Human/Assistant) or restate the question.
- If uncertain, say so briefly and suggest what is needed to proceed.
- Target ≈120 words per reply by default.
""";

  /// Get current service availability
  static ServiceAvailability get serviceAvailability => _serviceAvailability;

  /// Initialize the hybrid chat service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    final errors = <String>[];

    // Track which services successfully initialize
    bool localLLMReady = false;
    bool interviewChatReady = false;
    bool characterChatReady = false;
    bool providerChatReady = false;

    // Initialize LocalLLMService
    try {
      await LocalLLMService.initialize();
      localLLMReady = true;
      AppLogger.serviceInitialized('LocalLLMService');
    } catch (e) {
      AppLogger.serviceError('LocalLLMService', 'initialization failed', e);
      errors.add('Local LLM service failed: ${e.toString()}');
    }

    // Initialize chat services through BaseChatService (eliminates duplication)
    try {
      await interview_chat.ChatService.initialize();
      interviewChatReady = true;
      AppLogger.serviceInitialized('Interview ChatService');
    } catch (e) {
      AppLogger.serviceError('Interview ChatService', 'initialization failed', e);
      errors.add('Interview chat service failed: ${e.toString()}');
    }

    try {
      await character_chat.ChatService.initialize();
      characterChatReady = true;
      AppLogger.serviceInitialized('Character ChatService');
    } catch (e) {
      AppLogger.serviceError('Character ChatService', 'initialization failed', e);
      errors.add('Character chat service failed: ${e.toString()}');
    }

    try {
      await provider_chat.ChatService.initialize();
      providerChatReady = true;
      AppLogger.serviceInitialized('Provider ChatService');
    } catch (e) {
      AppLogger.serviceError('Provider ChatService', 'initialization failed', e);
      errors.add('Provider chat service failed: ${e.toString()}');
    }

    // Update service availability
    _serviceAvailability = ServiceAvailability(
      localLLM: localLLMReady,
      interviewChat: interviewChatReady,
      characterChat: characterChatReady,
      providerChat: providerChatReady,
      errors: errors,
    );

    // Set initialization status based on whether we have any working services
    _isInitialized = _serviceAvailability.hasAnyWorkingService;

    // Log initialization summary
    AppLogger.debug('HybridChatService initialization complete:', tag: 'HybridChatService');
    AppLogger.debug('  Local LLM: ${localLLMReady ? '✓' : '✗'}', tag: 'HybridChatService');
    AppLogger.debug('  Interview Chat: ${interviewChatReady ? '✓' : '✗'}', tag: 'HybridChatService');
    AppLogger.debug('  Character Chat: ${characterChatReady ? '✓' : '✗'}', tag: 'HybridChatService');
    AppLogger.debug('  Provider Chat: ${providerChatReady ? '✓' : '✗'}', tag: 'HybridChatService');
    AppLogger.debug('  Can send messages: ${_serviceAvailability.canSendMessages}', tag: 'HybridChatService');
    if (errors.isNotEmpty) {
      AppLogger.warning('  Errors: ${errors.join(', ')}', tag: 'HybridChatService');
    }

    // Throw error only if NO services are available
    if (!_serviceAvailability.hasAnyWorkingService) {
      throw Exception(
        'No chat services available. Errors: ${errors.join(', ')}',
      );
    }
  }

  /// Check if service is ready for use
  static bool get isReady =>
      _isInitialized && _serviceAvailability.canSendMessages;

  /// Send a message using the optimal provider
  static Future<String?> sendMessage({
    required List<Map<String, dynamic>> messages,
    String? systemPrompt,
    String? model,
    double? temperature,
    int? maxTokens,
    LLMProvider? preferredProvider,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Check if we can send messages
    if (!_serviceAvailability.canSendMessages) {
      throw Exception(
        'No chat services available. Please check your configuration.',
      );
    }

    // Use the explicitly provided provider when set; otherwise auto-determine
    final provider = preferredProvider ?? _preferredProvider;

    LLMProvider actualProvider;
    if (preferredProvider != null) {
      // Respect explicit provider. If local is requested but not available, attempt to enable once.
      if (preferredProvider == LLMProvider.local) {
        var localStatus = LocalLLMService.getStatus();
        var isLocalAvailable = localStatus['isAvailable'] as bool;
        if (!isLocalAvailable && localStatus['modelStatus'] == 'downloaded') {
          try {
            await LocalLLMService.enableLocalLLM();
          } catch (_) {}
        }
      }
      actualProvider = preferredProvider;
    } else {
      // Auto mode: determine best provider
      actualProvider = await _determineProvider(provider);
    }

    if (kDebugMode) {
      print('Requested provider: $provider, Using provider: $actualProvider');
      if (model != null) {
        print('Model: $model');
      }
    }

    switch (actualProvider) {
      case LLMProvider.local:
        return await _sendMessageLocal(
          messages: messages,
          systemPrompt: systemPrompt,
          temperature: temperature,
          maxTokens: maxTokens,
        );

      case LLMProvider.openRouter:
        return await _sendMessageOpenRouter(
          messages: messages,
          systemPrompt: systemPrompt,
          model: model,
          temperature: temperature,
          maxTokens: maxTokens,
        );

      case LLMProvider.auto:
        // This shouldn't happen after _determineProvider, but fallback to OpenRouter
        return await _sendMessageOpenRouter(
          messages: messages,
          systemPrompt: systemPrompt,
          model: model,
          temperature: temperature,
          maxTokens: maxTokens,
        );
    }
  }

  /// Send message to character using hybrid approach
  static Future<String?> sendMessageToCharacter({
    required String characterId,
    required String message,
    required String systemPrompt,
    required List<Map<String, dynamic>> chatHistory,
    String? model,
    LLMProvider? preferredProvider,
    String? localPrompt,
  }) async {
    // Check if the model is a local model - be more specific about local model patterns
    bool isLocalModel =
        model != null &&
        (model.startsWith('local/') ||
            model == 'local' ||
            model.contains('hammer') ||
            model.contains('gemma') ||
            model.contains('llama'));

    if (kDebugMode) {
      print('HybridChatService: Model selection debug');
      print('  - Model: $model');
      print('  - Is local model: $isLocalModel');
      print('  - Preferred provider: $preferredProvider');
    }

    // Determine the provider based on the model
    LLMProvider actualProvider;
    if (isLocalModel) {
      actualProvider = LLMProvider.local;
    } else if (preferredProvider != null) {
      actualProvider = preferredProvider;
    } else {
      // For API models, always use OpenRouter
      actualProvider = LLMProvider.openRouter;
    }

    if (kDebugMode) {
      print('  - Actual provider: $actualProvider');
    }

    // Select the appropriate prompt based on provider
    String promptToUse;
    if (actualProvider == LLMProvider.local) {
      final base = localPrompt ?? systemPrompt ?? '';
      promptToUse = base.isEmpty ? _localStyleGuide : '$base\n\n$_localStyleGuide';
    } else {
      promptToUse = systemPrompt ?? '';
    }

    // Append language instruction for local models based on saved app language
    if (actualProvider == LLMProvider.local) {
      try {
        final prefs = await PreferencesService.getPrefs();
        final code = (prefs.getString('user_language') ?? 'en').toLowerCase();
        if (code != 'en') {
          final languageName = _languageNameFromCode(code);
          final endonym = _languageEndonym(code);
          final instruction =
              "\n\nLANGUAGE POLICY: Reply only in $languageName ($endonym). Do not include any translations, explanations, or duplicate text in other languages. Do not add English in parentheses. Switch languages only if the user explicitly requests it, otherwise keep strictly to $languageName.";
          promptToUse = '$promptToUse$instruction';
        }
      } catch (_) {}
    }

    // Convert the message format for hybrid service
    // Ensure each message has a valid 'role' field for OpenRouter API
    final messages =
        chatHistory.map((msg) {
          // Make a copy of the message to avoid modifying the original
          final Map<String, dynamic> formattedMsg = Map.from(msg);

          // Ensure the message has a role field
          if (!formattedMsg.containsKey('role')) {
            // If it has an 'isUser' field, use that to determine role
            if (formattedMsg.containsKey('isUser')) {
              formattedMsg['role'] =
                  formattedMsg['isUser'] == true ? 'user' : 'assistant';
            } else {
              // Default to 'user' if we can't determine
              formattedMsg['role'] = 'user';
            }
          }

          return formattedMsg;
        }).toList();

    // Add the new user message with proper role
    messages.add({'role': 'user', 'content': message});

    return await sendMessage(
      messages: messages,
      systemPrompt: promptToUse,
      model:
          isLocalModel
              ? null
              : model, // Don't pass local model ID to cloud service
      preferredProvider: actualProvider,
    );
  }

  static String _languageNameFromCode(String code) {
    switch (code) {
      case 'es':
        return 'Spanish';
      case 'fr':
        return 'French';
      case 'de':
        return 'German';
      case 'it':
        return 'Italian';
      case 'ja':
        return 'Japanese';
      case 'ko':
        return 'Korean';
      case 'uk':
        return 'Ukrainian';
      case 'ru':
        return 'Russian';
      default:
        return 'English';
    }
  }

  static String _languageEndonym(String code) {
    switch (code) {
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      case 'de':
        return 'Deutsch';
      case 'it':
        return 'Italiano';
      case 'ja':
        return '日本語';
      case 'ko':
        return '한국어';
      case 'uk':
        return 'Українська';
      case 'ru':
        return 'Русский';
      default:
        return 'English';
    }
  }

  /// Determine which provider to actually use
  static Future<LLMProvider> _determineProvider(LLMProvider requested) async {
    var localStatus = LocalLLMService.getStatus();
    var isLocalAvailable = localStatus['isAvailable'] as bool;

    // If requested local but not available, try to enable/initialize on the fly
    if (requested == LLMProvider.local && !isLocalAvailable) {
      // Attempt to initialize if model is downloaded
      final modelStatus = localStatus['modelStatus'];
      if (modelStatus == 'downloaded') {
        try {
          await LocalLLMService.enableLocalLLM();
          localStatus = LocalLLMService.getStatus();
          isLocalAvailable = localStatus['isAvailable'] as bool;
        } catch (_) {}
      }
    }

    switch (requested) {
      case LLMProvider.local:
        // Check if local LLM is available
        if (isLocalAvailable) {
          return LLMProvider.local;
        } else {
          // Fallback to OpenRouter if local is not available
          if (kDebugMode) {
            print('Local LLM not available, falling back to OpenRouter');
          }
          return LLMProvider.openRouter;
        }

      case LLMProvider.openRouter:
        return LLMProvider.openRouter;

      case LLMProvider.auto:
        // Prefer local if available, otherwise use OpenRouter
        if (isLocalAvailable) {
          return LLMProvider.local;
        } else {
          return LLMProvider.openRouter;
        }
    }
  }

  /// Send message using local LLM
  static Future<String?> _sendMessageLocal({
    required List<Map<String, dynamic>> messages,
    String? systemPrompt,
    double? temperature,
    int? maxTokens,
  }) async {
    try {
      // Ensure local LLM is ready; attempt on-the-fly enable if possible
      var localStatus = LocalLLMService.getStatus();
      if (localStatus['isAvailable'] != true) {
        if (localStatus['modelStatus'] == 'downloaded') {
          try {
            await LocalLLMService.enableLocalLLM();
            localStatus = LocalLLMService.getStatus();
          } catch (_) {}

          // Wait briefly for the model to finish initializing (first-call race)
          if (localStatus['isAvailable'] != true) {
            for (int i = 0; i < 20; i++) {
              await Future.delayed(const Duration(milliseconds: 150));
              localStatus = LocalLLMService.getStatus();
              if (localStatus['isAvailable'] == true) {
                break;
              }
            }
          }
        }
        if (localStatus['isAvailable'] != true) {
          return "The local AI model (Gemma 3n) isn't ready yet. Please try again in a moment, or switch this character to a cloud model in the profile or settings to continue now.";
        }
      }

      // Build a comprehensive prompt with conversation context for local models
      final StringBuffer promptBuffer = StringBuffer();

      // Add system prompt if provided
      if (systemPrompt != null && systemPrompt.isNotEmpty) {
        promptBuffer.writeln(systemPrompt);
        promptBuffer.writeln();
      }

      // Add conversation history in a format local models can understand
      if (messages.isNotEmpty) {
        promptBuffer.writeln("Conversation:");

        for (final message in messages) {
          final role = message['role'] ?? 'user';
          final content = message['content'] ?? '';

          if (role == 'user') {
            promptBuffer.writeln("Human: $content");
          } else if (role == 'assistant') {
            promptBuffer.writeln("Assistant: $content");
          }
        }

        // Add the prompt for the assistant to respond
        promptBuffer.writeln();
        promptBuffer.write("Assistant:");
      } else if (messages.isNotEmpty) {
        // Fallback: just use the last message
        final userMessage = messages.last['content'] ?? '';
        promptBuffer.writeln("Human: $userMessage");
        promptBuffer.writeln();
        promptBuffer.write("Assistant:");
      }

      final fullPrompt = promptBuffer.toString();

      if (kDebugMode) {
        print('Local LLM prompt length: ${fullPrompt.length}');
        print(
          'Local LLM prompt preview: ${fullPrompt.substring(0, min(200, fullPrompt.length))}...',
        );
      }

      final response = await LocalLLMService.sendMessage(
        '', // Empty message since we're using the full prompt
        systemPrompt: fullPrompt,
      );

      // Clean up the response - remove any leading "Assistant:" if present
      String cleanedResponse = LocalLLMService.cleanLocalResponse(response);

      return cleanedResponse;
    } catch (e) {
      if (kDebugMode) {
        print('Local LLM error: $e');
      }
      // Inform the user instead of silently switching providers
      return "I'm having trouble with the local AI model right now. Please try again shortly, or switch this character to a cloud model (uses internet) to continue without delay.";
    }
  }

  /// Send message using OpenRouter API
  static Future<String?> _sendMessageOpenRouter({
    required List<Map<String, dynamic>> messages,
    String? systemPrompt,
    String? model,
    double? temperature,
    int? maxTokens,
  }) async {
    try {
      return await interview_chat.ChatService.sendMessage(
        messages: messages,
        systemPrompt: systemPrompt,
        model: model,
        temperature: temperature,
        maxTokens: maxTokens,
      );
    } catch (e) {
      if (kDebugMode) {
        print('OpenRouter API error: $e');
      }
      return 'I apologize, but I\'m having trouble connecting to my AI services. Please try again later.';
    }
  }

  /// Set preferred provider
  static void setPreferredProvider(LLMProvider provider) {
    // Provider selection is fixed to Auto (smart selection)
    _preferredProvider = LLMProvider.auto;
    if (kDebugMode) {
      print('Preferred provider set to: LLMProvider.auto');
    }
  }

  /// Get current preferred provider
  static LLMProvider get preferredProvider => _preferredProvider;

  /// Get provider status information
  static Map<String, dynamic> getProviderStatus() {
    final localStatus = LocalLLMService.getStatus();
    return {
      'local': {
        'available': localStatus['isAvailable'],
        'enabled': localStatus['isEnabled'],
        'initialized': localStatus['isInitialized'],
        'name': 'Local AI',
        'description': 'Privacy-focused offline AI model',
      },
      'cloud': {
        'available':
            true, // Assuming cloud is always available if API key is set
        'enabled': true,
        'name': 'Cloud AI (OpenRouter)',
        'description': 'Advanced cloud-based AI models',
      },
    };
  }

  /// Check if local LLM is available
  static bool get isLocalLLMAvailable {
    final localStatus = LocalLLMService.getStatus();
    return localStatus['isAvailable'] as bool;
  }

  /// Check if OpenRouter is available
  static bool get isOpenRouterAvailable =>
      true; // Always available if API key is set

  /// Get recommended provider based on current status
  static Future<LLMProvider> getRecommendedProvider() async {
    final localStatus = LocalLLMService.getStatus();
    final isLocalAvailable = localStatus['isAvailable'] as bool;

    if (isLocalAvailable) {
      return LLMProvider.local;
    } else {
      return LLMProvider.openRouter;
    }
  }

  /// Get provider display name
  static String getProviderDisplayName(LLMProvider provider) {
    switch (provider) {
      case LLMProvider.local:
        return 'Local AI';
      case LLMProvider.openRouter:
        return 'Cloud AI (OpenRouter)';
      case LLMProvider.auto:
        return 'Auto (Smart Selection)';
    }
  }

  /// Get provider description
  static String getProviderDescription(LLMProvider provider) {
    switch (provider) {
      case LLMProvider.local:
        return 'Uses your device\'s local AI model for privacy and offline usage';
      case LLMProvider.openRouter:
        return 'Uses cloud-based AI models for advanced capabilities';
      case LLMProvider.auto:
        return 'Automatically selects the best available AI provider';
    }
  }

  /// Refresh all services
  static Future<void> refreshServices() async {
    try {
      await LocalLLMService.initialize();
      await interview_chat.ChatService.refreshApiKey();
      await character_chat.ChatService.refreshApiKey();
      await provider_chat.ChatService.refreshApiKey();

      if (kDebugMode) {
        print('All services refreshed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error refreshing services: $e');
      }
    }
  }
}
