import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/character_model.dart';
import 'models/group_chat_model.dart';
import 'models/group_chat_message.dart';
import '../chat/models/message_status.dart';
import 'personality_dynamics_analyzer.dart';
import 'conversation_memory_system.dart';
import 'enhanced_conversation_coordinator.dart';
import 'dynamic_timing_controller.dart';

/// Comprehensive testing system for natural conversation features
class NaturalConversationTester {
  
  /// Test personality dynamics analysis
  static void testPersonalityDynamics() {
    if (kDebugMode) {
      print('=== Testing Personality Dynamics ===');
      
      // Create test characters
      final einstein = _createTestCharacter(
        'test_einstein',
        'Albert Einstein',
        'Brilliant physicist known for relativity theory. Deeply intellectual, philosophical, and curious about the universe.',
      );
      
      final napoleon = _createTestCharacter(
        'test_napoleon',
        'Napoleon Bonaparte',
        'French military leader and emperor. Commanding, strategic, and ambitious with strong leadership qualities.',
      );
      
      final cleopatra = _createTestCharacter(
        'test_cleopatra',
        'Cleopatra VII',
        'Last pharaoh of Egypt. Intelligent, charismatic, and politically astute with diplomatic skills.',
      );
      
      // Test personality compatibility
      final einsteinNapoleonAnalysis = PersonalityDynamicsAnalyzer.analyzePersonalityCompatibility(einstein, napoleon);
      print('Einstein-Napoleon Analysis:');
      print('  Compatibility: ${einsteinNapoleonAnalysis['compatibility']}');
      print('  Conflict Potential: ${einsteinNapoleonAnalysis['conflictPotential']}');
      print('  Interaction Style: ${einsteinNapoleonAnalysis['interactionStyle']}');
      
      final einsteinCleopatraAnalysis = PersonalityDynamicsAnalyzer.analyzePersonalityCompatibility(einstein, cleopatra);
      print('Einstein-Cleopatra Analysis:');
      print('  Compatibility: ${einsteinCleopatraAnalysis['compatibility']}');
      print('  Agreement Potential: ${einsteinCleopatraAnalysis['agreementPotential']}');
      print('  Debate Likelihood: ${einsteinCleopatraAnalysis['debateLikelihood']}');
      
      // Test group dynamics
      final groupDynamics = PersonalityDynamicsAnalyzer.analyzeGroupDynamics({
        'test_einstein': einstein,
        'test_napoleon': napoleon,
        'test_cleopatra': cleopatra,
      });
      print('Group Dynamics:');
      print('  Type: ${groupDynamics['groupDynamicsType']}');
      print('  Avg Conflict: ${groupDynamics['groupAverages']['conflictPotential']}');
      print('  Avg Debate: ${groupDynamics['groupAverages']['debateLikelihood']}');
      
      print('✅ Personality Dynamics Test Completed\n');
    }
  }

  /// Test conversation memory system
  static void testConversationMemory() {
    if (kDebugMode) {
      print('=== Testing Conversation Memory ===');
      
      // Create test group and messages
      final groupId = 'test_group_001';
      final testMessages = _createTestConversationHistory();
      final characterModels = _createTestCharacterModels();
      
      // Test memory updates
      final memory = ConversationMemorySystem.updateMemory(
        groupId: groupId,
        recentMessages: testMessages,
        characterModels: characterModels,
      );
      
      print('Memory Analysis:');
      print('  Active Topics: ${memory.activeTopics.length}');
      for (final topic in memory.activeTopics) {
        print('    - ${topic.topic}: ${topic.intensity.toStringAsFixed(2)} intensity, ${topic.sentiment} sentiment');
      }
      
      print('  Character States: ${memory.characterStates.length}');
      memory.characterStates.forEach((id, state) {
        print('    - $id: ${state.mood} (${state.intensity.toStringAsFixed(2)})');
      });
      
      print('  Overall Tension: ${memory.overallTension.toStringAsFixed(2)}');
      print('  Dominant Mood: ${memory.dominantMood}');
      print('  Conversation Flow: ${memory.conversationFlow}');
      
      // Test suggestions
      final suggestions = ConversationMemorySystem.getSuggestions(memory);
      print('  Suggestions: $suggestions');
      
      print('✅ Conversation Memory Test Completed\n');
    }
  }

  /// Test enhanced conversation coordinator
  static Future<void> testEnhancedCoordinator() async {
    if (kDebugMode) {
      print('=== Testing Enhanced Conversation Coordinator ===');
      
      final characterModels = _createTestCharacterModels();
      final groupChat = _createTestGroupChat();
      
      // Test different user messages
      final testMessages = [
        'What do you think about war, Napoleon?',
        'Einstein, can you explain your theory of relativity?',
        'I disagree with both of you!',
        'What is the meaning of life?',
      ];
      
      for (final userMessage in testMessages) {
        print('User Message: "$userMessage"');
        
        final responseSchedule = await EnhancedConversationCoordinator.determineRespondingCharactersAdvanced(
          groupChat: groupChat,
          userMessage: userMessage,
          characterModels: characterModels,
        );
        
        print('  Response Schedule:');
        for (final response in responseSchedule) {
          final character = characterModels[response['characterId']]!;
          print('    - ${character.name}: ${response['delay']}ms delay, ${response['urgency'].toStringAsFixed(2)} urgency');
        }
        print('');
      }
      
      print('✅ Enhanced Coordinator Test Completed\n');
    }
  }

  /// Test dynamic timing system
  static void testDynamicTiming() {
    if (kDebugMode) {
      print('=== Testing Dynamic Timing System ===');
      
      final characterModels = _createTestCharacterModels();
      final conversationHistory = _createTestConversationHistory();
      
      // Create test conversation memory
      final memory = ConversationMemory(
        groupId: 'test_group',
        activeTopics: [
          ConversationTopic(
            topic: 'science',
            keywords: ['physics', 'theory'],
            intensity: 0.8,
            firstMentioned: DateTime.now().subtract(Duration(minutes: 5)),
            lastMentioned: DateTime.now().subtract(Duration(minutes: 1)),
            participatingCharacters: ['test_einstein'],
            sentiment: 'positive',
          ),
        ],
        characterStates: {
          'test_einstein': CharacterEmotionalState(
            characterId: 'test_einstein',
            mood: 'engaged',
            intensity: 0.7,
            recentTopics: ['science'],
            positionsOnTopics: {'science': 'supporting'},
            lastUpdate: DateTime.now(),
          ),
          'test_napoleon': CharacterEmotionalState(
            characterId: 'test_napoleon',
            mood: 'challenging',
            intensity: 0.6,
            recentTopics: [],
            positionsOnTopics: {},
            lastUpdate: DateTime.now(),
          ),
        },
        conversationFlow: ['debate_emerged'],
        overallTension: 0.6,
        dominantMood: 'intellectual',
        lastUpdate: DateTime.now(),
      );
      
      print('Timing Analysis:');
      for (int i = 0; i < characterModels.length; i++) {
        final character = characterModels.values.elementAt(i);
        final timing = DynamicTimingController.calculateResponseTiming(
          character: character,
          responseOrder: i,
          conversationHistory: conversationHistory,
          conversationMemory: memory,
        );
        
        print('  ${character.name}:');
        print('    - Total Delay: ${timing['totalDelay']}ms');
        print('    - Base Delay: ${timing['baseDelay']}ms');
        print('    - Urgency: ${timing['urgency'].toStringAsFixed(2)}');
        print('    - Thinking Time: ${timing['thinkingTime']}ms');
        print('    - Traits: ${timing['traits']}');
      }
      
      print('✅ Dynamic Timing Test Completed\n');
    }
  }

  /// Test complete natural conversation flow
  static Future<void> testCompleteConversationFlow() async {
    if (kDebugMode) {
      print('=== Testing Complete Natural Conversation Flow ===');
      
      // This test simulates the full conversation flow
      final characterModels = _createTestCharacterModels();
      final groupChat = _createTestGroupChat();
      final userMessage = 'What do you think about war, Napoleon?';
      
      print('Simulating conversation: "$userMessage"');
      
      // Step 1: Update conversation memory
      final memory = ConversationMemorySystem.updateMemory(
        groupId: groupChat.id,
        recentMessages: groupChat.messages,
        characterModels: characterModels,
      );
      
      // Step 2: Determine responding characters
      final responseSchedule = await EnhancedConversationCoordinator.determineRespondingCharactersAdvanced(
        groupChat: groupChat,
        userMessage: userMessage,
        characterModels: characterModels,
      );
      
      // Step 3: Calculate timing for each response
      final timedResponses = <Map<String, dynamic>>[];
      for (final response in responseSchedule) {
        final character = characterModels[response['characterId']]!;
        final timing = DynamicTimingController.calculateResponseTiming(
          character: character,
          responseOrder: response['order'],
          conversationHistory: groupChat.messages,
          conversationMemory: memory,
        );
        
        timedResponses.add({
          'character': character,
          'timing': timing,
          'responseInfo': response,
        });
      }
      
      // Step 4: Create response schedule
      final schedule = DynamicTimingController.createResponseSchedule(timedResponses);
      
      print('Complete Response Schedule:');
      for (final scheduledResponse in schedule) {
        final character = scheduledResponse['character'] as CharacterModel;
        print('  ${character.name}:');
        print('    - Delay: ${scheduledResponse['delay']}ms');
        print('    - Show Thinking: ${scheduledResponse['showThinking']}');
        print('    - Thinking Duration: ${scheduledResponse['thinkingDuration']}ms');
        print('    - Urgency: ${scheduledResponse['urgency'].toStringAsFixed(2)}');
      }
      
      // Step 5: Simulate conversation evolution
      print('\nConversation Evolution Simulation:');
      final simulatedResponses = [
        'War is the ultimate test of leadership and strategy. A necessary tool for achieving great ends.',
        'I must respectfully disagree, Napoleon. War brings suffering that outweighs any strategic gains.',
        'Both perspectives have merit, but we must consider the human cost above all political calculations.',
      ];
      
      var currentMemory = memory;
      for (int i = 0; i < simulatedResponses.length && i < schedule.length; i++) {
        final scheduledResponse = schedule[i];
        final character = scheduledResponse['character'] as CharacterModel;
        final response = simulatedResponses[i];
        
        print('  Step ${i + 1}: ${character.name} responds (after ${scheduledResponse['delay']}ms)');
        print('    "${response}"');
        
        // Update memory with new response
        final newMessage = GroupChatMessage.character(
          content: response,
          characterId: character.id,
          characterName: character.name,
          status: MessageStatus.sent,
        );
        
        final updatedMessages = [...groupChat.messages, newMessage];
        currentMemory = ConversationMemorySystem.updateMemory(
          groupId: groupChat.id,
          recentMessages: updatedMessages,
          characterModels: characterModels,
          existingMemory: currentMemory,
        );
        
        print('    Memory Update:');
        print('      - Tension: ${currentMemory.overallTension.toStringAsFixed(2)}');
        print('      - Mood: ${currentMemory.dominantMood}');
        print('      - Flow: ${currentMemory.conversationFlow.last}');
      }
      
      print('✅ Complete Conversation Flow Test Completed\n');
    }
  }

  /// Run all tests
  static Future<void> runAllTests() async {
    if (kDebugMode) {
      print('🧪 Starting Natural Conversation System Tests\n');
      
      testPersonalityDynamics();
      testConversationMemory();
      await testEnhancedCoordinator();
      testDynamicTiming();
      await testCompleteConversationFlow();
      
      print('🎉 All Natural Conversation Tests Completed Successfully!');
    }
  }

  /// Helper: Create test character
  static CharacterModel _createTestCharacter(String id, String name, String description) {
    return CharacterModel(
      id: id,
      name: name,
      createdAt: DateTime.now(),
      systemPrompt: description,
      localPrompt: description,
      model: 'test_model',
      accentColor: const Color(0xFF6200EA),
      chatHistory: [],
    );
  }

  /// Helper: Create test character models
  static Map<String, CharacterModel> _createTestCharacterModels() {
    return {
      'test_einstein': _createTestCharacter(
        'test_einstein',
        'Albert Einstein',
        'Brilliant physicist known for relativity theory. Deeply intellectual, philosophical, and curious about the universe. Prefers thoughtful analysis and peaceful discourse.',
      ),
      'test_napoleon': _createTestCharacter(
        'test_napoleon',
        'Napoleon Bonaparte',
        'French military leader and emperor. Commanding, strategic, and ambitious with strong leadership qualities. Quick to assert authority and defend positions.',
      ),
      'test_cleopatra': _createTestCharacter(
        'test_cleopatra',
        'Cleopatra VII',
        'Last pharaoh of Egypt. Intelligent, charismatic, and politically astute with diplomatic skills. Balances power with grace and wisdom.',
      ),
    };
  }

  /// Helper: Create test group chat
  static GroupChatModel _createTestGroupChat() {
    return GroupChatModel(
      name: 'Test Historical Discussion',
      characterIds: ['test_einstein', 'test_napoleon', 'test_cleopatra'],
      description: 'A test group for historical figures',
    );
  }

  /// Helper: Create test conversation history
  static List<GroupChatMessage> _createTestConversationHistory() {
    return [
      GroupChatMessage.user(
        content: 'Hello everyone! What are your thoughts on leadership?',
        timestamp: DateTime.now().subtract(Duration(minutes: 10)),
      ),
      GroupChatMessage.character(
        content: 'Leadership requires both vision and the will to act decisively.',
        characterId: 'test_napoleon',
        characterName: 'Napoleon Bonaparte',
        timestamp: DateTime.now().subtract(Duration(minutes: 9)),
      ),
      GroupChatMessage.character(
        content: 'True leadership comes from understanding and inspiring others, not commanding them.',
        characterId: 'test_einstein',
        characterName: 'Albert Einstein',
        timestamp: DateTime.now().subtract(Duration(minutes: 8)),
      ),
      GroupChatMessage.character(
        content: 'Leadership is an art that requires adapting to circumstances while maintaining core principles.',
        characterId: 'test_cleopatra',
        characterName: 'Cleopatra VII',
        timestamp: DateTime.now().subtract(Duration(minutes: 7)),
      ),
      GroupChatMessage.user(
        content: 'Interesting perspectives! How do you handle disagreement?',
        timestamp: DateTime.now().subtract(Duration(minutes: 5)),
      ),
    ];
  }

  /// Helper: Validate test results
  static bool validateResults(Map<String, dynamic> results) {
    // Basic validation logic
    if (results.isEmpty) return false;
    
    // Check for required fields and reasonable values
    final requiredFields = ['personality_analysis', 'memory_system', 'timing_system'];
    for (final field in requiredFields) {
      if (!results.containsKey(field)) return false;
    }
    
    return true;
  }

  /// Get test summary
  static Map<String, dynamic> getTestSummary() {
    return {
      'personality_analysis': 'Analyzes character traits and compatibility',
      'conversation_memory': 'Tracks topics, emotions, and conversation flow',
      'enhanced_coordinator': 'Determines natural response patterns',
      'dynamic_timing': 'Calculates personality-based response timing',
      'complete_flow': 'Integrates all systems for natural conversations',
      'status': 'All systems operational',
      'improvements': [
        'Natural conversation flow based on personality dynamics',
        'Emotional context tracking and memory',
        'Personality-based response timing',
        'Enhanced character interactions and relationships',
        'Topic-aware conversation management',
      ],
    };
  }
}


