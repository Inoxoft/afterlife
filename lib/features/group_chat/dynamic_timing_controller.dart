import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/character_model.dart';
import 'models/group_chat_message.dart';
import 'personality_dynamics_analyzer.dart';
import 'conversation_memory_system.dart';

/// Controls natural, personality-based response timing for realistic conversations
class DynamicTimingController {
  // Base response timing ranges by personality type (in milliseconds)
  static const Map<String, Map<String, int>> personalityTimingProfiles = {
    'intellectual': {
      'baseMin': 1200,
      'baseMax': 3500,
      'thinkingTime': 800,
      'agitationMultiplier': 70, // Gets faster when agitated
    },
    'emotional': {
      'baseMin': 200,
      'baseMax': 1200,
      'thinkingTime': 200,
      'agitationMultiplier': 150, // Gets much faster when emotional
    },
    'dominant': {
      'baseMin': 400,
      'baseMax': 1500,
      'thinkingTime': 300,
      'agitationMultiplier': 80, // Quick to assert authority
    },
    'philosophical': {
      'baseMin': 1500,
      'baseMax': 4000,
      'thinkingTime': 1000,
      'agitationMultiplier': 60, // Still contemplative when agitated
    },
    'rebellious': {
      'baseMin': 150,
      'baseMax': 800,
      'thinkingTime': 100,
      'agitationMultiplier': 200, // Very impulsive
    },
    'diplomatic': {
      'baseMin': 800,
      'baseMax': 2200,
      'thinkingTime': 500,
      'agitationMultiplier': 90, // Measured even under pressure
    },
    'creative': {
      'baseMin': 600,
      'baseMax': 2000,
      'thinkingTime': 400,
      'agitationMultiplier': 110, // Variable based on inspiration
    },
    'practical': {
      'baseMin': 500,
      'baseMax': 1300,
      'thinkingTime': 250,
      'agitationMultiplier': 85, // Consistent timing
    },
  };

  // Conversation context multipliers
  static const Map<String, double> conversationContextMultipliers = {
    'debate_emerged': 0.7, // Faster in debates
    'agreement_cascade': 1.1, // Slightly slower in agreement
    'topic_development': 1.0, // Normal pace
    'high_tension': 0.6, // Much faster in conflict
    'intellectual_debate': 1.2, // Thoughtful pace
    'harmonious': 1.1, // Relaxed pace
  };

  /// Calculate response timing for a character
  static Map<String, dynamic> calculateResponseTiming({
    required CharacterModel character,
    required int responseOrder,
    required List<GroupChatMessage> conversationHistory,
    required ConversationMemory? conversationMemory,
    String? targetCharacterId, // If responding to specific character
  }) {
    // Extract character personality traits
    final traits = PersonalityDynamicsAnalyzer.extractPersonalityTraits(character);
    
    // Get base timing profile
    final timingProfile = _getTimingProfile(traits);
    
    // Calculate base delay
    int baseDelay = _calculateBaseDelay(timingProfile);
    
    // Apply personality-based adjustments
    baseDelay = _applyPersonalityAdjustments(baseDelay, traits, character);
    
    // Apply emotional state adjustments
    if (conversationMemory != null) {
      baseDelay = _applyEmotionalAdjustments(baseDelay, character.id, conversationMemory, timingProfile);
    }
    
    // Apply conversation context adjustments
    baseDelay = _applyConversationContextAdjustments(baseDelay, conversationHistory, conversationMemory);
    
    // Apply relationship-based adjustments
    if (targetCharacterId != null) {
      baseDelay = _applyRelationshipAdjustments(baseDelay, character, targetCharacterId, conversationHistory);
    }
    
    // Apply response order delay to prevent simultaneity
    final orderDelay = _calculateOrderDelay(responseOrder, baseDelay);
    
    // Calculate natural variations
    final variation = _addNaturalVariation(baseDelay);
    
    final totalDelay = baseDelay + orderDelay + variation;
    
    // Calculate urgency and thinking indicators
    final urgency = _calculateUrgency(totalDelay, timingProfile, conversationMemory);
    final thinkingTime = _calculateThinkingTime(timingProfile, conversationMemory);
    
    if (kDebugMode) {
      print('=== Timing Calculation: ${character.name} ===');
      print('Base delay: ${baseDelay}ms');
      print('Order delay: ${orderDelay}ms');
      print('Variation: ${variation}ms');
      print('Total delay: ${totalDelay}ms');
      print('Urgency: ${urgency.toStringAsFixed(2)}');
      print('=============================================');
    }
    
    return {
      'totalDelay': totalDelay,
      'baseDelay': baseDelay,
      'orderDelay': orderDelay,
      'variation': variation,
      'urgency': urgency,
      'thinkingTime': thinkingTime,
      'personalityProfile': timingProfile,
      'traits': traits,
    };
  }

  /// Get timing profile based on character traits
  static Map<String, int> _getTimingProfile(List<String> traits) {
    // Find the most dominant personality trait for timing
    for (final trait in traits) {
      if (personalityTimingProfiles.containsKey(trait)) {
        return personalityTimingProfiles[trait]!;
      }
    }
    
    // Default profile if no specific trait found
    return personalityTimingProfiles['practical']!;
  }

  /// Calculate base delay from timing profile
  static int _calculateBaseDelay(Map<String, int> profile) {
    final min = profile['baseMin']!;
    final max = profile['baseMax']!;
    return min + math.Random().nextInt(max - min);
  }

  /// Apply personality-specific adjustments
  static int _applyPersonalityAdjustments(
    int baseDelay,
    List<String> traits,
    CharacterModel character,
  ) {
    double multiplier = 1.0;
    
    // Multiple trait effects
    if (traits.contains('intellectual') && traits.contains('emotional')) {
      multiplier *= 1.1; // Thoughtful but reactive
    }
    
    if (traits.contains('dominant') && traits.contains('intellectual')) {
      multiplier *= 0.9; // Quick to assert expertise
    }
    
    if (traits.contains('rebellious') && traits.contains('philosophical')) {
      multiplier *= 1.2; // Thoughtful rebellion
    }
    
    // Character-specific adjustments based on famous character patterns
    final characterName = character.name.toLowerCase();
    if (characterName.contains('einstein')) {
      multiplier *= 1.3; // Known for deep thinking
    } else if (characterName.contains('napoleon')) {
      multiplier *= 0.8; // Quick decision maker
    } else if (characterName.contains('cleopatra')) {
      multiplier *= 0.9; // Politically astute, measured responses
    } else if (characterName.contains('caesar')) {
      multiplier *= 0.7; // Decisive leader
    }
    
    return (baseDelay * multiplier).round();
  }

  /// Apply emotional state adjustments from conversation memory
  static int _applyEmotionalAdjustments(
    int baseDelay,
    String characterId,
    ConversationMemory memory,
    Map<String, int> timingProfile,
  ) {
    final characterState = memory.characterStates[characterId];
    if (characterState == null) return baseDelay;
    
    double multiplier = 1.0;
    final agitationMultiplier = timingProfile['agitationMultiplier']! / 100.0;
    
    // Adjust based on mood
    switch (characterState.mood) {
      case 'agitated':
        multiplier *= (1.0 - (characterState.intensity * agitationMultiplier));
        break;
      case 'challenging':
        multiplier *= 0.8; // Quick to challenge
        break;
      case 'supportive':
        multiplier *= 1.1; // More measured in support
        break;
      case 'engaged':
        multiplier *= 0.9; // Eager to participate
        break;
      case 'thoughtful':
        multiplier *= 1.2; // Extra contemplation time
        break;
    }
    
    // High emotional intensity generally speeds up responses
    multiplier *= (1.0 - (characterState.intensity * 0.3));
    
    return (baseDelay * math.max(multiplier, 0.2)).round(); // Minimum 20% of original delay
  }

  /// Apply conversation context adjustments
  static int _applyConversationContextAdjustments(
    int baseDelay,
    List<GroupChatMessage> history,
    ConversationMemory? memory,
  ) {
    double multiplier = 1.0;
    
    if (memory != null) {
      // Apply conversation flow adjustments
      for (final flowPattern in memory.conversationFlow) {
        if (conversationContextMultipliers.containsKey(flowPattern)) {
          multiplier *= conversationContextMultipliers[flowPattern]!;
        }
      }
      
      // Apply tension adjustments
      if (memory.overallTension > 0.7) {
        multiplier *= 0.6; // High tension = fast responses
      } else if (memory.overallTension > 0.4) {
        multiplier *= 0.8; // Medium tension = slightly faster
      }
      
      // Apply dominant mood adjustments
      switch (memory.dominantMood) {
        case 'intellectual':
          multiplier *= 1.2; // Thoughtful pace
          break;
        case 'conflicted':
          multiplier *= 0.7; // Quick to respond in conflict
          break;
        case 'harmonious':
          multiplier *= 1.1; // Relaxed pace
          break;
      }
    }
    
    // Analyze recent message frequency
    final recentMessages = history.where((m) => !m.isUser).take(5).toList();
    if (recentMessages.length >= 3) {
      final timeDifferences = <int>[];
      for (int i = 1; i < recentMessages.length; i++) {
        final diff = recentMessages[i-1].timestamp.difference(recentMessages[i].timestamp).inMilliseconds.abs();
        timeDifferences.add(diff);
      }
      
      if (timeDifferences.isNotEmpty) {
        final averageGap = timeDifferences.reduce((a, b) => a + b) / timeDifferences.length;
        if (averageGap < 2000) {
          multiplier *= 0.8; // Fast conversation pace
        } else if (averageGap > 5000) {
          multiplier *= 1.1; // Slow conversation pace
        }
      }
    }
    
    return (baseDelay * multiplier).round();
  }

  /// Apply relationship-based timing adjustments
  static int _applyRelationshipAdjustments(
    int baseDelay,
    CharacterModel character,
    String targetCharacterId,
    List<GroupChatMessage> history,
  ) {
    // This would require access to character models, simplified for now
    double multiplier = 1.0;
    
    // Find recent message from target character
    final targetMessage = history
        .where((m) => !m.isUser && m.characterId == targetCharacterId)
        .firstOrNull;
    
    if (targetMessage != null) {
      final content = targetMessage.content.toLowerCase();
      
      // Quick response to direct challenges
      if (content.contains(RegExp(r'\b(wrong|disagree|ridiculous|challenge)\b'))) {
        multiplier *= 0.6; // Quick defensive response
      }
      
      // Thoughtful response to complex ideas
      if (content.contains(RegExp(r'\b(theory|analysis|consider|philosophy)\b'))) {
        multiplier *= 1.3; // More time to process complexity
      }
      
      // Quick agreement
      if (content.contains(RegExp(r'\b(agree|exactly|brilliant|yes)\b'))) {
        multiplier *= 0.8; // Quick to support
      }
    }
    
    return (baseDelay * multiplier).round();
  }

  /// Calculate order-based delay to prevent simultaneous responses
  static int _calculateOrderDelay(int responseOrder, int baseDelay) {
    if (responseOrder == 0) return 0;
    
    // Use a combination of fixed and proportional delays
    final fixedDelay = responseOrder * (300 + math.Random().nextInt(400)); // 300-700ms per order
    final proportionalDelay = (baseDelay * 0.1 * responseOrder).round(); // 10% per order
    
    return fixedDelay + proportionalDelay;
  }

  /// Add natural variation to prevent robotic timing
  static int _addNaturalVariation(int baseDelay) {
    final variationPercent = 0.15; // 15% variation
    final maxVariation = (baseDelay * variationPercent).round();
    return math.Random().nextInt(maxVariation * 2) - maxVariation; // -15% to +15%
  }

  /// Calculate urgency score (0.0 to 1.0)
  static double _calculateUrgency(
    int totalDelay,
    Map<String, int> profile,
    ConversationMemory? memory,
  ) {
    double urgency = 0.5; // Base urgency
    
    // Shorter delays indicate higher urgency
    final maxDelay = profile['baseMax']!;
    urgency += (maxDelay - totalDelay) / maxDelay * 0.3;
    
    // High tension increases urgency
    if (memory != null && memory.overallTension > 0.5) {
      urgency += memory.overallTension * 0.3;
    }
    
    return math.max(0.0, math.min(1.0, urgency));
  }

  /// Calculate thinking time before response
  static int _calculateThinkingTime(
    Map<String, int> profile,
    ConversationMemory? memory,
  ) {
    int thinkingTime = profile['thinkingTime']!;
    
    // Adjust based on conversation complexity
    if (memory != null) {
      final topicCount = memory.activeTopics.length;
      if (topicCount > 3) {
        thinkingTime = (thinkingTime * 1.2).round(); // More topics = more thinking
      }
      
      // High tension reduces thinking time
      if (memory.overallTension > 0.6) {
        thinkingTime = (thinkingTime * 0.7).round();
      }
    }
    
    return thinkingTime;
  }

  /// Create staggered response schedule for multiple characters
  static List<Map<String, dynamic>> createResponseSchedule(
    List<Map<String, dynamic>> characterResponses,
  ) {
    final schedule = <Map<String, dynamic>>[];
    
    // Sort by calculated delay
    final sortedResponses = List<Map<String, dynamic>>.from(characterResponses);
    sortedResponses.sort((a, b) => (a['totalDelay'] as int).compareTo(b['totalDelay'] as int));
    
    int accumulatedDelay = 0;
    
    for (int i = 0; i < sortedResponses.length; i++) {
      final response = sortedResponses[i];
      final timing = response['timing'] as Map<String, dynamic>;
      
      // Add thinking time if it's the first response or there's a significant gap
      final shouldShowThinking = i == 0 || 
          (timing['totalDelay'] as int) - accumulatedDelay > 2000;
      
      schedule.add({
        'characterId': response['characterId'],
        'character': response['character'],
        'delay': accumulatedDelay + (timing['totalDelay'] as int),
        'showThinking': shouldShowThinking,
        'thinkingDuration': shouldShowThinking ? timing['thinkingTime'] : 0,
        'urgency': timing['urgency'],
        'order': i,
        'timing': timing,
      });
      
      accumulatedDelay += (timing['totalDelay'] as int);
    }
    
    return schedule;
  }

  /// Get diagnostic information for timing analysis
  static Map<String, dynamic> getTimingDiagnostics(
    String characterId,
    CharacterModel character,
    Map<String, dynamic> timing,
  ) {
    return {
      'characterId': characterId,
      'characterName': character.name,
      'personalityTraits': timing['traits'],
      'timingProfile': timing['personalityProfile'],
      'calculatedDelay': timing['totalDelay'],
      'urgency': timing['urgency'],
      'breakdown': {
        'base': timing['baseDelay'],
        'order': timing['orderDelay'],
        'variation': timing['variation'],
      },
    };
  }
}
