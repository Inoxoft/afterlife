import 'dart:async';
import 'dart:math';
import 'dart:io' show Platform;
import 'package:afterlife/core/services/local_llm_service.dart';
import 'package:afterlife/core/services/native_ios_ai.dart';
import 'package:flutter/services.dart';
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

  // Minimal style guide for tiny local models (keep it very short)
  static const String _localStyleGuide =
      """
Guidelines:
- Keep replies short (1–3 sentences).
- Speak naturally; no role labels.
""";

  // Clean up occasional wrappers emitted by on-device model
  static String _cleanIOSResponse(String raw) {
    String text = raw;
    // Remove simple highlight wrappers sometimes added by FM
    text = text.replaceAll('<highlight>', '').replaceAll('</highlight>', '');
    return text.trim();
  }

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

    // Initialize local provider: use Native iOS FM on iOS, Gemma-based service on Android
    if (Platform.isIOS) {
      try {
        final fmAvailable = await NativeIOSAI.isFMAvailable();
        localLLMReady = fmAvailable;
        AppLogger.debug('iOS Foundation Models available: ' + fmAvailable.toString(), tag: 'HybridChatService');
      } catch (e) {
        AppLogger.serviceError('NativeIOSAI', 'availability check failed', e);
        errors.add('Native iOS FM check failed: ' + e.toString());
      }
    } else {
      try {
        await LocalLLMService.initialize();
        localLLMReady = true;
        AppLogger.serviceInitialized('LocalLLMService');
      } catch (e) {
        AppLogger.serviceError('LocalLLMService', 'initialization failed', e);
        errors.add('Local LLM service failed: ' + e.toString());
      }
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

    // iOS: Force on-device Apple Foundation Models for all chats
    if (Platform.isIOS) {
      // Always adapt prompt for local execution: prefer concise style
      String? adjustedSystemPrompt = systemPrompt;
      if ((adjustedSystemPrompt ?? '').isNotEmpty) {
        adjustedSystemPrompt = adjustedSystemPrompt! + "\n\n" + _localStyleGuide;
      } else {
        adjustedSystemPrompt = _localStyleGuide;
      }
      return await _sendMessageLocal(
        messages: messages,
        systemPrompt: adjustedSystemPrompt,
        temperature: temperature,
        maxTokens: maxTokens,
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

    AppLogger.debug('Requested provider: $provider, Using provider: $actualProvider', tag: 'HybridChatService');
    if (model != null) {
      AppLogger.debug('Model: $model', tag: 'HybridChatService');
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
            model.contains('gemma-3n') ||
            model.contains('gemma3n') ||
            model.contains('gemma') ||
            model.contains('llama') ||
            model.contains('hammer'));

    AppLogger.debug('HybridChatService: Model selection', tag: 'HybridChatService');
    AppLogger.debug('  - Model: $model', tag: 'HybridChatService');
    AppLogger.debug('  - Is local model: $isLocalModel', tag: 'HybridChatService');
    AppLogger.debug('  - Preferred provider: $preferredProvider', tag: 'HybridChatService');

    // Determine the provider based on the model
    LLMProvider actualProvider;
    if (Platform.isIOS) {
      // On iOS, always use local (Apple FM)
      actualProvider = LLMProvider.local;
    } else if (isLocalModel) {
      actualProvider = LLMProvider.local;
    } else if (preferredProvider != null) {
      actualProvider = preferredProvider;
    } else {
      // For API models, always use OpenRouter
      actualProvider = LLMProvider.openRouter;
    }

    AppLogger.debug('  - Actual provider: $actualProvider', tag: 'HybridChatService');

    // Select the appropriate prompt based on provider
    String promptToUse;
    if (Platform.isIOS) {
      // Always prefer localPrompt for iOS FM
      final base = (localPrompt ?? systemPrompt);
      promptToUse = base.isEmpty ? _localStyleGuide : (base + '\n\n' + _localStyleGuide);
    } else if (actualProvider == LLMProvider.local) {
      final base = localPrompt ?? systemPrompt;
      promptToUse = base.isEmpty ? _localStyleGuide : '$base\n\n$_localStyleGuide';
    } else {
      promptToUse = systemPrompt;
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
          AppLogger.debug('Local model unavailable; falling back to cloud provider', tag: 'HybridChatService');
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
      // iOS path: use Apple Foundation Models via native bridge
      if (Platform.isIOS) {
        final StringBuffer promptBuffer = StringBuffer();

        // Include system prompt (already adapted by caller with local style guide when available)
        if (systemPrompt != null && systemPrompt.isNotEmpty) {
          promptBuffer.writeln(systemPrompt);
          promptBuffer.writeln();
        }

        // Add a short rolling window of conversation for context
        const int maxTurns = 8; // total messages (user+assistant)
        final int start = messages.length > maxTurns ? messages.length - maxTurns : 0;
        if (messages.isNotEmpty) {
          for (int i = start; i < messages.length; i++) {
            final m = messages[i];
            final role = (m['role'] ?? 'user') == 'assistant' ? 'Assistant' : 'User';
            String content = (m['content'] ?? '').toString();
            if (content.length > 800) {
              content = content.substring(0, 800);
            }
            if (content.trim().isEmpty) continue;
            promptBuffer.writeln(role + ': ' + content);
          }
          promptBuffer.writeln();
        }

        // Interview gating: enforce 3 questions before card generation
        // Heuristic detection: presence of interview instructions and card markers in system prompt
        final bool looksLikeInterview = (systemPrompt ?? '')
                .toLowerCase()
                .contains('interview') &&
            (systemPrompt ?? '').contains('## CHARACTER CARD SUMMARY ##');

        if (looksLikeInterview) {
          int userTurns = 0;
          for (final m in messages) {
            if ((m['role'] ?? 'user') == 'user') userTurns++;
          }
          // Provide explicit control instructions based on turn count
          if (userTurns <= 1) {
            promptBuffer.writeln(
                'Do not produce the character card yet. Ask the next short, natural question about personality traits and temperament. Keep it one sentence.');
          } else if (userTurns == 2) {
            promptBuffer.writeln(
                'Do not produce the character card yet. Ask one final short, natural question about a vivid memorable moment or defining anecdote. Exactly one sentence.');
          } else {
            promptBuffer.writeln(
                'You now have enough information. Produce the character card using ONLY the required markers. Do not add any extra headings, labels, or tags.');
          }
          promptBuffer.writeln();
        }

        // Do not add an explicit Assistant cue; let the model continue naturally

        final fullPrompt = promptBuffer.toString();

        final fmAvailable = await NativeIOSAI.isFMAvailable();
        if (!fmAvailable) {
          return "On-device Apple Intelligence is unavailable on this device (see Settings).";
        }

        try {
          final response = await NativeIOSAI.generateText(fullPrompt);
          return _cleanIOSResponse(response);
        } on PlatformException catch (e) {
          // Surface a clear, user-friendly message for on-device moderation blocks
          final msg = (e.message ?? '').toLowerCase();
          if ((e.code == 'GEN_FAIL') && msg.contains('unsafe')) {
            return "I couldn't respond because the last message was flagged as potentially unsafe on this device. Please rephrase or try a different topic.";
          }
          return "I ran into a problem generating a response on-device. Please try again or rephrase.";
        }
      }

      // Ensure local LLM is ready; attempt on-the-fly enable if possible
      var localStatus = LocalLLMService.getStatus();
      if (localStatus['isAvailable'] != true) {
        if (localStatus['modelStatus'] == 'downloaded') {
          try {
            await LocalLLMService.enableLocalLLM();
            localStatus = LocalLLMService.getStatus();
          } catch (_) {}

          // Wait longer for first-load initialization
          if (localStatus['isAvailable'] != true) {
            for (int i = 0; i < 60; i++) { // up to ~15s
              await Future.delayed(const Duration(milliseconds: 250));
              localStatus = LocalLLMService.getStatus();
              if (localStatus['isAvailable'] == true) {
                break;
              }
            }
          }

          // As a final nudge, try explicit model init once
          if (localStatus['isAvailable'] != true &&
              localStatus['modelStatus'] == 'downloaded') {
            try {
              await LocalLLMService.initializeModel();
              // brief wait
              for (int i = 0; i < 10; i++) {
                await Future.delayed(const Duration(milliseconds: 200));
                localStatus = LocalLLMService.getStatus();
                if (localStatus['isAvailable'] == true) break;
              }
            } catch (_) {}
          }
        }
        if (localStatus['isAvailable'] != true) {
          return "The local AI model is still starting up. Please send your message again in a few seconds (first load can take longer).";
        }
      }

      // Minimal prompt: system instructions (if any) + latest user message only
      final StringBuffer promptBuffer = StringBuffer();
      if (systemPrompt != null && systemPrompt.isNotEmpty) {
        promptBuffer.writeln(systemPrompt);
        promptBuffer.writeln();
      }
      String latestUser = '';
      for (var i = messages.length - 1; i >= 0; i--) {
        final m = messages[i];
        if ((m['role'] ?? 'user') == 'user') {
          latestUser = (m['content'] ?? '').toString();
          break;
        }
      }
      // Fallback to last message content if no explicit user message found
      if (latestUser.isEmpty && messages.isNotEmpty) {
        latestUser = (messages.last['content'] ?? '').toString();
      }
      promptBuffer.writeln("User: $latestUser");
      promptBuffer.writeln();
      promptBuffer.write("Assistant:");

      final fullPrompt = promptBuffer.toString();

      AppLogger.debug('Local prompt length: ${fullPrompt.length}', tag: 'HybridChatService');
      AppLogger.debug('Local prompt preview: ${fullPrompt.substring(0, min(200, fullPrompt.length))}...', tag: 'HybridChatService');

      final response = await LocalLLMService.sendMessage(
        '', // Empty message since we're using the full prompt
        systemPrompt: fullPrompt,
      );

      // Clean up the response - remove any leading "Assistant:" if present
      String cleanedResponse = LocalLLMService.cleanLocalResponse(response);

      return cleanedResponse;
    } catch (e) {
      AppLogger.error('Local model error', tag: 'HybridChatService', error: e);
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
      AppLogger.error('Cloud provider API error', tag: 'HybridChatService', error: e);
      return 'I apologize, but I\'m having trouble connecting to my AI services. Please try again later.';
    }
  }

  /// Set preferred provider
  static void setPreferredProvider(LLMProvider provider) {
    // Provider selection is fixed to Auto (smart selection)
    _preferredProvider = LLMProvider.auto;
    AppLogger.debug('Preferred provider set to Auto', tag: 'HybridChatService');
  }

  /// Get current preferred provider
  static LLMProvider get preferredProvider => _preferredProvider;

  /// Get provider status information
  static Map<String, dynamic> getProviderStatus() {
    final localStatus = LocalLLMService.getStatus();
    // iOS: Present only Apple Intelligence to the UI
    if (Platform.isIOS) {
      return {
        'local': {
          'available': true,
          'enabled': true,
          'initialized': true,
          'name': 'Apple Intelligence',
          'description': 'On‑device AI (private, fast, offline)',
        },
      };
    }
    // Android: keep both entries
    return {
      'local': {
        'available': localStatus['isAvailable'],
        'enabled': localStatus['isEnabled'],
        'initialized': localStatus['isInitialized'],
        'name': 'Local AI',
        'description': 'Privacy-focused offline AI model',
      },
      'cloud': {
        'available': true,
        'enabled': true,
        'name': 'Cloud AI',
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
    if (Platform.isIOS) {
      return 'Apple Intelligence';
    }
    switch (provider) {
      case LLMProvider.local:
        return 'Local AI';
      case LLMProvider.openRouter:
        return 'Cloud AI';
      case LLMProvider.auto:
        return 'Auto (Smart Selection)';
    }
  }

  /// Get provider description
  static String getProviderDescription(LLMProvider provider) {
    if (Platform.isIOS) {
      return 'On‑device Apple Foundation Models (private, offline)';
    }
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

      AppLogger.debug('All services refreshed successfully', tag: 'HybridChatService');
    } catch (e) {
      AppLogger.error('Error refreshing services', tag: 'HybridChatService', error: e);
    }
  }
}
