import 'package:flutter_test/flutter_test.dart';
import 'package:afterlife/core/services/local_llm_service.dart';
import 'package:afterlife/core/services/hybrid_chat_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LocalLLMService Tests', () {
    setUpAll(() async {
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({
        'local_llm_enabled': true,
        'huggingface_token': 'test_token',
        'google_agreement_accepted': true,
      });
    });

    test('should initialize correctly', () async {
      await LocalLLMService.initialize();
      // Just test that initialization doesn't throw
      expect(true, true);
    });

    test('should return correct status', () async {
      await LocalLLMService.initialize();
      final status = LocalLLMService.getStatus();
      expect(status, isA<Map<String, dynamic>>());
      expect(status.containsKey('isAvailable'), true);
      expect(status.containsKey('isEnabled'), true);
    });

    test('should handle settings changes', () async {
      await LocalLLMService.initialize();
      
      final newSettings = {
        'enabled': true,
        'maxTokens': 2048,
        'temperature': 0.7,
      };
      
      await LocalLLMService.updateSettings(newSettings);
      final settings = LocalLLMService.getSettings();
      expect(settings, isA<Map<String, dynamic>>());
      expect(settings.containsKey('enabled'), true);
    });
  });

  group('HybridChatService Tests', () {
    test('should initialize correctly', () async {
      await HybridChatService.initialize();
      // Just test that initialization doesn't throw
      expect(true, true);
    });

    test('should handle provider status checks', () async {
      await HybridChatService.initialize();
      final status = HybridChatService.getProviderStatus();
      expect(status, isA<Map<String, dynamic>>());
    });

    test('should handle preferred provider changes', () async {
      await HybridChatService.initialize();
      
      // Provider selection is fixed to Auto regardless of input
      HybridChatService.setPreferredProvider(LLMProvider.local);
      expect(HybridChatService.preferredProvider, LLMProvider.auto);
      
      HybridChatService.setPreferredProvider(LLMProvider.openRouter);
      expect(HybridChatService.preferredProvider, LLMProvider.auto);
      
      HybridChatService.setPreferredProvider(LLMProvider.auto);
      expect(HybridChatService.preferredProvider, LLMProvider.auto);
    });

    test('should get provider display names', () async {
      await HybridChatService.initialize();
      
      expect(HybridChatService.getProviderDisplayName(LLMProvider.local), isA<String>());
      expect(HybridChatService.getProviderDisplayName(LLMProvider.openRouter), isA<String>());
      expect(HybridChatService.getProviderDisplayName(LLMProvider.auto), isA<String>());
    });

    test('should get provider descriptions', () async {
      await HybridChatService.initialize();
      
      expect(HybridChatService.getProviderDescription(LLMProvider.local), isA<String>());
      expect(HybridChatService.getProviderDescription(LLMProvider.openRouter), isA<String>());
      expect(HybridChatService.getProviderDescription(LLMProvider.auto), isA<String>());
    });
  });
} 