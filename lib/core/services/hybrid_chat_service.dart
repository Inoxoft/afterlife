import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:afterlife/core/services/local_llm_service.dart';
import '../../features/character_interview/chat_service.dart' as interview_chat;
import '../../features/character_chat/chat_service.dart' as character_chat;
import '../../features/providers/chat_service.dart' as provider_chat;

enum LLMProvider {
  local,
  openRouter,
  auto, // Automatically choose based on availability
}

class HybridChatService {
  static HybridChatService? _instance;
  static HybridChatService get instance => _instance ??= HybridChatService._();
  HybridChatService._();

  static LLMProvider _preferredProvider = LLMProvider.auto;
  static bool _isInitialized = false;
  
  /// Initialize the hybrid chat service
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize all services
      await LocalLLMService.initialize();
      await interview_chat.ChatService.initialize();
      await character_chat.ChatService.initialize();
      await provider_chat.ChatService.initialize();
      
      _isInitialized = true;
      
      if (kDebugMode) {
        print('HybridChatService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('HybridChatService initialization error: $e');
      }
    }
  }
  
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
    
    // Use the explicitly provided provider, otherwise use the global preference
    final provider = preferredProvider ?? _preferredProvider;
    
    // Determine which provider to use
    final actualProvider = await _determineProvider(provider);
    
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
  }) async {
    // Check if the model is a local model
    bool isLocalModel = model != null && model.startsWith('local/');
    
    // Determine the provider based on the model
    LLMProvider actualProvider;
    if (isLocalModel) {
      actualProvider = LLMProvider.local;
    } else if (preferredProvider != null) {
      actualProvider = preferredProvider;
    } else {
      actualProvider = _preferredProvider;
    }
    
    // Convert the message format for hybrid service
    final messages = [
      ...chatHistory,
      {'role': 'user', 'content': message},
    ];
    
    return await sendMessage(
      messages: messages,
      systemPrompt: systemPrompt,
      model: isLocalModel ? null : model, // Don't pass local model ID to cloud service
      preferredProvider: actualProvider,
    );
  }
  
  /// Determine which provider to actually use
  static Future<LLMProvider> _determineProvider(LLMProvider requested) async {
    final localStatus = LocalLLMService.getStatus();
    final isLocalAvailable = localStatus['isAvailable'] as bool;
    
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
      // Convert messages to a single user message for now
      // This is a simplified approach - in a real implementation you'd want to handle the full conversation
      final userMessage = messages.isNotEmpty ? messages.last['content'] ?? '' : '';
      
      final response = await LocalLLMService.sendMessage(
        userMessage,
        systemPrompt: systemPrompt,
      );
      
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Local LLM error, falling back to OpenRouter: $e');
      }
      // Fallback to OpenRouter on error
      return await _sendMessageOpenRouter(
        messages: messages,
        systemPrompt: systemPrompt,
        temperature: temperature,
        maxTokens: maxTokens,
      );
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
    _preferredProvider = provider;
    if (kDebugMode) {
      print('Preferred provider set to: $provider');
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
        'available': true, // Assuming cloud is always available if API key is set
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
  static bool get isOpenRouterAvailable => true; // Always available if API key is set
  
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