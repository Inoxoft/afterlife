import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/character_model.dart';
import 'models/group_chat_model.dart';
import 'models/group_chat_message.dart';
import 'personality_dynamics_analyzer.dart';

/// Enhanced conversation coordinator that creates natural, organic conversations
class EnhancedConversationCoordinator {
  // ignore: unused_field
  static const int _maxSimultaneousResponses = 3; // Increased for more dynamic conversations
  static const double _baseResponseProbability = 0.4;
  // ignore: unused_field
  static const int _conversationMemoryWindow = 8; // More context
  
  // Response timing patterns based on personality
  static const Map<String, Map<String, int>> responseTimingPatterns = {
    'intellectual': {'min': 1200, 'max': 3000}, // Thoughtful, slower responses
    'emotional': {'min': 300, 'max': 1200}, // Quick, reactive responses
    'dominant': {'min': 500, 'max': 1500}, // Confident, measured responses
    'philosophical': {'min': 1500, 'max': 4000}, // Deep contemplation
    'rebellious': {'min': 200, 'max': 800}, // Impulsive, quick responses
    'diplomatic': {'min': 800, 'max': 2000}, // Careful, considered responses
  };

  /// Determine responding characters using advanced personality analysis
  static Future<List<Map<String, dynamic>>> determineRespondingCharactersAdvanced({
    required GroupChatModel groupChat,
    required String userMessage,
    required Map<String, CharacterModel> characterModels,
    String? lastRespondingCharacterId,
  }) async {
    if (groupChat.characterIds.isEmpty) return [];

    final responses = <Map<String, dynamic>>[];
    final conversationHistory = groupChat.messages;

    // Analyze group dynamics
    final groupDynamics = PersonalityDynamicsAnalyzer.analyzeGroupDynamics(characterModels);
    
    if (kDebugMode) {
      print('=== Enhanced Conversation Coordinator ===');
      print('Group Dynamics Type: ${groupDynamics['groupDynamicsType']}');
      print('Average Conflict Potential: ${groupDynamics['groupAverages']['conflictPotential']}');
      print('Average Debate Likelihood: ${groupDynamics['groupAverages']['debateLikelihood']}');
    }

    // Phase 1: Determine primary responders based on personality triggers
    final primaryResponders = await _determinePrimaryResponders(
      groupChat,
      userMessage,
      characterModels,
      groupDynamics,
      lastRespondingCharacterId,
    );

    // Phase 2: Determine secondary responders (reactions to primary responses)
    final secondaryResponders = await _determineSecondaryResponders(
      primaryResponders,
      characterModels,
      conversationHistory,
      groupDynamics,
    );

    // Phase 3: Calculate response timing and order
    // Combine responders and ensure uniqueness while preserving order
    final seen = <String>{};
    final allResponders = <String>[
      ...primaryResponders.where((id) => seen.add(id)),
      ...secondaryResponders.where((id) => seen.add(id)),
    ];
    
    for (int i = 0; i < allResponders.length; i++) {
      final responder = allResponders[i];
      final character = characterModels[responder];
      if (character == null) {
        // Skip if not in models
        continue;
      }
      
      // Calculate personality-based timing
      final timing = _calculateResponseTiming(
        character,
        i,
        conversationHistory,
        groupDynamics,
      );

      responses.add({
        'characterId': responder,
        'character': character,
        'delay': timing['delay'],
        'urgency': timing['urgency'],
        'responseType': i < primaryResponders.length ? 'primary' : 'secondary',
        'order': i,
      });
    }

    // Sort by delay to get natural conversation flow
    responses.sort((a, b) => (a['delay'] as int).compareTo(b['delay'] as int));

    if (kDebugMode) {
      print('Planned responses:');
      for (final response in responses) {
        print('  ${characterModels[response['characterId']]?.name}: ${response['delay']}ms (${response['responseType']})');
      }
      print('==========================================');
    }

    return responses;
  }

  /// Determine primary responders based on personality and context
  static Future<List<String>> _determinePrimaryResponders(
    GroupChatModel groupChat,
    String userMessage,
    Map<String, CharacterModel> characterModels,
    Map<String, dynamic> groupDynamics,
    String? lastRespondingCharacterId,
  ) async {
    final responseScores = <String, double>{};
    final conversationHistory = groupChat.messages;

    // Initialize base scores
    for (final characterId in characterModels.keys) {
      responseScores[characterId] = _baseResponseProbability;
    }

    // Factor 1: Direct addressing (enhanced detection)
    await _applyEnhancedDirectAddressing(responseScores, userMessage, characterModels);

    // Factor 2: Personality-based topic relevance
    await _applyPersonalityTopicRelevance(responseScores, userMessage, characterModels);

    // Factor 3: Character relationship dynamics
    _applyRelationshipDynamics(responseScores, characterModels, conversationHistory);

    // Factor 4: Conversation momentum analysis
    _applyConversationMomentum(responseScores, conversationHistory, characterModels);

    // Factor 5: Emotional trigger detection
    _applyEmotionalTriggers(responseScores, userMessage, characterModels, conversationHistory);

    // Factor 6: Recent activity balancing (improved)
    _applyAdvancedActivityBalancing(responseScores, conversationHistory, lastRespondingCharacterId);

    // Factor 7: Group dynamics influence
    _applyGroupDynamicsInfluence(responseScores, groupDynamics, characterModels);

    if (kDebugMode) {
      print('Primary response scores:');
      responseScores.forEach((id, score) {
        print('  ${characterModels[id]?.name}: ${score.toStringAsFixed(3)}');
      });
    }

    return _selectPrimaryCharacters(responseScores, characterModels);
  }

  /// Enhanced direct addressing detection
  static Future<void> _applyEnhancedDirectAddressing(
    Map<String, double> scores,
    String userMessage,
    Map<String, CharacterModel> characterModels,
  ) async {
    final messageLower = userMessage.toLowerCase();

    for (final entry in characterModels.entries) {
      final characterId = entry.key;
      final character = entry.value;
      
      final nameLower = character.name.toLowerCase();
      final firstNameLower = character.name.split(' ').first.toLowerCase();
      final lastNameLower = character.name.split(' ').length > 1 
          ? character.name.split(' ').last.toLowerCase() 
          : '';

      double addressingBonus = 0.0;

      // Direct name mentions
      if (messageLower.contains(nameLower)) {
        addressingBonus += 1.0; // Very strong signal
      } else if (messageLower.contains(firstNameLower)) {
        addressingBonus += 0.8;
      } else if (lastNameLower.isNotEmpty && messageLower.contains(lastNameLower)) {
        addressingBonus += 0.8;
      }

      // Question patterns directed at character
      final questionPatterns = [
        'what do you think, $firstNameLower',
        '$firstNameLower, what',
        'hey $firstNameLower',
        '$firstNameLower?',
        'right, $firstNameLower',
        'agree, $firstNameLower',
        'disagree, $firstNameLower',
        '$firstNameLower would say',
        'ask $firstNameLower',
      ];

      for (final pattern in questionPatterns) {
        if (messageLower.contains(pattern)) {
          addressingBonus += 0.9;
          break;
        }
      }

      // Addressing punctuation
      if (messageLower.contains('@$firstNameLower') ||
          messageLower.contains('$firstNameLower,') ||
          messageLower.contains('$firstNameLower:')) {
        addressingBonus += 0.7;
      }

      scores[characterId] = (scores[characterId] ?? 0.0) + addressingBonus;
    }
  }

  /// Apply personality-based topic relevance
  static Future<void> _applyPersonalityTopicRelevance(
    Map<String, double> scores,
    String userMessage,
    Map<String, CharacterModel> characterModels,
  ) async {
    final messageLower = userMessage.toLowerCase();

    // Extended topic analysis with personality matching
    final topicPersonalityMap = {
      // Scientific topics
      'science': ['intellectual', 'analytical'],
      'physics': ['intellectual'],
      'mathematics': ['intellectual'],
      'technology': ['intellectual', 'innovative'],
      
      // Philosophical topics
      'philosophy': ['philosophical', 'intellectual'],
      'meaning': ['philosophical'],
      'existence': ['philosophical'],
      'truth': ['philosophical', 'intellectual'],
      'morality': ['philosophical', 'diplomatic'],
      'ethics': ['philosophical', 'diplomatic'],
      
      // Political topics
      'politics': ['dominant', 'diplomatic', 'rebellious'],
      'power': ['dominant'],
      'leadership': ['dominant', 'diplomatic'],
      'revolution': ['rebellious'],
      'war': ['dominant', 'rebellious'],
      'empire': ['dominant'],
      
      // Emotional/artistic topics
      'art': ['creative', 'emotional'],
      'beauty': ['creative', 'emotional'],
      'love': ['emotional'],
      'passion': ['emotional'],
      'creativity': ['creative'],
      'music': ['creative', 'emotional'],
      
      // Social topics
      'society': ['diplomatic', 'philosophical'],
      'justice': ['philosophical', 'diplomatic'],
      'freedom': ['rebellious', 'philosophical'],
      'equality': ['diplomatic', 'rebellious'],
    };

    for (final entry in characterModels.entries) {
      final characterId = entry.key;
      final character = entry.value;
      final characterTraits = PersonalityDynamicsAnalyzer.extractPersonalityTraits(character);

      double topicRelevanceScore = 0.0;

      for (final topicEntry in topicPersonalityMap.entries) {
        final topic = topicEntry.key;
        final relevantTraits = topicEntry.value;

        if (messageLower.contains(topic)) {
          // Check if character has relevant personality traits
          final matchingTraits = characterTraits.where((trait) => 
              relevantTraits.contains(trait)).length;
          
          if (matchingTraits > 0) {
            topicRelevanceScore += 0.3 * matchingTraits;
          }
        }
      }

      scores[characterId] = (scores[characterId] ?? 0.0) + topicRelevanceScore;
    }
  }

  /// Apply relationship dynamics between characters
  static void _applyRelationshipDynamics(
    Map<String, double> scores,
    Map<String, CharacterModel> characterModels,
    List<GroupChatMessage> conversationHistory,
  ) {
    // Find who spoke in the last few messages
    final recentSpeakers = conversationHistory
        .where((m) => !m.isUser)
        .take(3)
        .map((m) => m.characterId)
        .toList();

    if (recentSpeakers.isEmpty) return;

    // Analyze relationships with recent speakers
    for (final characterId in scores.keys) {
      final character = characterModels[characterId];
      if (character == null) continue;

      double relationshipBonus = 0.0;

      for (final recentSpeakerId in recentSpeakers) {
        final recentSpeaker = characterModels[recentSpeakerId];
        if (recentSpeaker == null || recentSpeakerId == characterId) continue;

        final analysis = PersonalityDynamicsAnalyzer.analyzePersonalityCompatibility(
          character,
          recentSpeaker,
        );

        final conflictPotential = analysis['conflictPotential'] as double;
        final debateLikelihood = analysis['debateLikelihood'] as double;
        final agreementPotential = analysis['agreementPotential'] as double;

        // Characters are more likely to respond to conflict or strong agreement
        if (conflictPotential > 0.5) {
          relationshipBonus += 0.4; // Want to challenge or defend
        } else if (agreementPotential > 0.6) {
          relationshipBonus += 0.3; // Want to support or elaborate
        } else if (debateLikelihood > 0.5) {
          relationshipBonus += 0.3; // Intellectual engagement
        }
      }

      scores[characterId] = (scores[characterId] ?? 0.0) + relationshipBonus;
    }
  }

  /// Apply conversation momentum analysis
  static void _applyConversationMomentum(
    Map<String, double> scores,
    List<GroupChatMessage> conversationHistory,
    Map<String, CharacterModel> characterModels,
  ) {
    if (conversationHistory.length < 3) return;

    final recentMessages = conversationHistory.reversed.take(6).toList();
    
    // Analyze conversation intensity
    double conversationIntensity = 0.0;
    int messageCount = 0;

    for (final message in recentMessages) {
      if (!message.isUser) {
        messageCount++;
        
        // Check for emotional language that indicates intensity
        final content = message.content.toLowerCase();
        if (content.contains(RegExp(r'\b(strongly|absolutely|never|always|completely|utterly)\b'))) {
          conversationIntensity += 0.3;
        }
        if (content.contains('!')) {
          conversationIntensity += 0.2;
        }
        if (content.contains('?')) {
          conversationIntensity += 0.1;
        }
      }
    }

    final averageIntensity = messageCount > 0 ? conversationIntensity / messageCount : 0.0;

    // High intensity conversations encourage more participation
    if (averageIntensity > 0.4) {
      for (final characterId in scores.keys) {
        scores[characterId] = (scores[characterId] ?? 0.0) + 0.2;
      }
    }

    // Find characters who haven't participated in recent intense discussion
    final recentParticipants = recentMessages
        .where((m) => !m.isUser)
        .map((m) => m.characterId)
        .toSet();

    for (final characterId in scores.keys) {
      if (!recentParticipants.contains(characterId) && averageIntensity > 0.3) {
        scores[characterId] = (scores[characterId] ?? 0.0) + 0.25; // Encourage joining
      }
    }
  }

  /// Apply emotional trigger detection
  static void _applyEmotionalTriggers(
    Map<String, double> scores,
    String userMessage,
    Map<String, CharacterModel> characterModels,
    List<GroupChatMessage> conversationHistory,
  ) {
    final messageLower = userMessage.toLowerCase();

    // Emotional trigger words and their intensities
    final emotionalTriggers = {
      'high_intensity': ['outrageous', 'absurd', 'ridiculous', 'brilliant', 'genius', 'foolish', 'wrong'],
      'medium_intensity': ['interesting', 'concerning', 'surprising', 'impressive', 'disappointing'],
      'controversial': ['disagree', 'oppose', 'challenge', 'question', 'doubt', 'contradict'],
    };

    for (final entry in characterModels.entries) {
      final characterId = entry.key;
      final character = entry.value;
      final characterTraits = PersonalityDynamicsAnalyzer.extractPersonalityTraits(character);

      double emotionalResponse = 0.0;

      // Check for high-intensity triggers
      for (final trigger in emotionalTriggers['high_intensity']!) {
        if (messageLower.contains(trigger)) {
          if (characterTraits.contains('emotional')) {
            emotionalResponse += 0.5; // Emotional characters react strongly
          } else if (characterTraits.contains('intellectual')) {
            emotionalResponse += 0.3; // Intellectual characters analyze
          }
        }
      }

      // Check for controversial triggers
      for (final trigger in emotionalTriggers['controversial']!) {
        if (messageLower.contains(trigger)) {
          if (characterTraits.contains('dominant')) {
            emotionalResponse += 0.4; // Dominant characters defend positions
          } else if (characterTraits.contains('rebellious')) {
            emotionalResponse += 0.4; // Rebels love controversy
          } else if (characterTraits.contains('diplomatic')) {
            emotionalResponse += 0.2; // Diplomats mediate
          }
        }
      }

      scores[characterId] = (scores[characterId] ?? 0.0) + emotionalResponse;
    }
  }

  /// Apply advanced activity balancing
  static void _applyAdvancedActivityBalancing(
    Map<String, double> scores,
    List<GroupChatMessage> conversationHistory,
    String? lastRespondingCharacterId,
  ) {
    // Count recent activity (last 10 messages)
    final recentActivity = <String, int>{};
    final recentMessages = conversationHistory.reversed.take(10).toList();

    for (final message in recentMessages) {
      if (!message.isUser) {
        recentActivity[message.characterId] = (recentActivity[message.characterId] ?? 0) + 1;
      }
    }

    // Heavy penalty for immediate last responder
    if (lastRespondingCharacterId != null) {
      scores[lastRespondingCharacterId] = (scores[lastRespondingCharacterId] ?? 0.0) * 0.3;
    }

    // Progressive penalties for recent speakers
    final maxActivity = recentActivity.values.isNotEmpty 
        ? recentActivity.values.reduce(math.max) 
        : 0;

    if (maxActivity > 0) {
      for (final entry in recentActivity.entries) {
        final characterId = entry.key;
        final activityCount = entry.value;
        
        if (characterId != lastRespondingCharacterId) {
          final activityRatio = activityCount / maxActivity;
          final penalty = 1.0 - (activityRatio * 0.6); // Max 60% penalty
          scores[characterId] = (scores[characterId] ?? 0.0) * penalty;
        }
      }
    }

    // Boost for completely inactive characters
    for (final characterId in scores.keys) {
      if (!recentActivity.containsKey(characterId)) {
        scores[characterId] = (scores[characterId] ?? 0.0) + 0.3;
      }
    }
  }

  /// Apply group dynamics influence
  static void _applyGroupDynamicsInfluence(
    Map<String, double> scores,
    Map<String, dynamic> groupDynamics,
    Map<String, CharacterModel> characterModels,
  ) {
    final dynamicsType = groupDynamics['groupDynamicsType'] as String;

    for (final characterId in scores.keys) {
      final character = characterModels[characterId];
      if (character == null) continue;

      final traits = PersonalityDynamicsAnalyzer.extractPersonalityTraits(character);
      double dynamicsBonus = 0.0;

      switch (dynamicsType) {
        case 'high_tension':
          if (traits.contains('dominant') || traits.contains('rebellious')) {
            dynamicsBonus += 0.3; // Thrive in conflict
          } else if (traits.contains('diplomatic')) {
            dynamicsBonus += 0.4; // Needed for mediation
          }
          break;
        
        case 'intellectual_debate':
          if (traits.contains('intellectual') || traits.contains('philosophical')) {
            dynamicsBonus += 0.4; // Perfect environment
          }
          break;
        
        case 'harmonious':
          if (traits.contains('diplomatic') || traits.contains('creative')) {
            dynamicsBonus += 0.2; // Comfortable environment
          }
          break;
        
        case 'dynamic_discussion':
          // All personality types can contribute
          dynamicsBonus += 0.1;
          break;
      }

      scores[characterId] = (scores[characterId] ?? 0.0) + dynamicsBonus;
    }
  }

  /// Select primary responding characters
  static List<String> _selectPrimaryCharacters(
    Map<String, double> scores,
    Map<String, CharacterModel> characterModels,
  ) {
    final selectedCharacters = <String>[];
    
    // Sort by score
    final sortedEntries = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Very high scores (> 1.2) should definitely respond
    final highPriorityCharacters = sortedEntries
        .where((entry) => entry.value >= 1.2)
        .map((entry) => entry.key)
        .take(2) // Limit to prevent overwhelming
        .toList();

    selectedCharacters.addAll(highPriorityCharacters);

    // If no high priority, select based on probability
    if (selectedCharacters.isEmpty && sortedEntries.isNotEmpty) {
      final topScore = sortedEntries.first.value;
      if (topScore > 0.6 || math.Random().nextDouble() < topScore) {
        selectedCharacters.add(sortedEntries.first.key);
      }
    }

    // Consider second character if scores are close and high enough
    if (selectedCharacters.length == 1 && sortedEntries.length > 1) {
      final secondScore = sortedEntries[1].value;
      final firstScore = sortedEntries[0].value;
      
      if (secondScore > 0.5 && (firstScore - secondScore) < 0.4) {
        if (math.Random().nextDouble() < 0.6) {
          selectedCharacters.add(sortedEntries[1].key);
        }
      }
    }

    // Guard: ensure only valid characters (present in characterModels)
    final filtered = selectedCharacters
        .where((id) => characterModels.containsKey(id))
        .toList();

    // Fallback: ensure at least one responder
    if (filtered.isEmpty && characterModels.isNotEmpty) {
      filtered.add(characterModels.keys.first);
    }

    return filtered;
  }

  /// Determine secondary responders (reactions to primary responses)
  static Future<List<String>> _determineSecondaryResponders(
    List<String> primaryResponders,
    Map<String, CharacterModel> characterModels,
    List<GroupChatMessage> conversationHistory,
    Map<String, dynamic> groupDynamics,
  ) async {
    if (primaryResponders.isEmpty) return [];

    final secondaryResponders = <String>[];
    final availableCharacters = characterModels.keys
        .where((id) => !primaryResponders.contains(id))
        .toList();

    final dynamicsType = groupDynamics['groupDynamicsType'] as String;

    for (final primaryId in primaryResponders) {
      final primaryCharacter = characterModels[primaryId];
      if (primaryCharacter == null) continue;

      // Find characters likely to react to this primary responder
      for (final candidateId in availableCharacters) {
        if (secondaryResponders.contains(candidateId)) continue;

        final candidateCharacter = characterModels[candidateId];
        if (candidateCharacter == null) continue;

        final analysis = PersonalityDynamicsAnalyzer.analyzePersonalityCompatibility(
          primaryCharacter,
          candidateCharacter,
        );

        double reactionProbability = 0.0;

        // High conflict personalities often trigger responses
        if (analysis['conflictPotential'] > 0.6) {
          reactionProbability += 0.5;
        }

        // Intellectual debates encourage participation
        if (analysis['debateLikelihood'] > 0.6) {
          reactionProbability += 0.4;
        }

        // Strong agreement also triggers support
        if (analysis['agreementPotential'] > 0.7) {
          reactionProbability += 0.3;
        }

        // High tension groups have more secondary responses
        if (dynamicsType == 'high_tension') {
          reactionProbability += 0.2;
        }

        // Random factor for natural conversation flow
        if (math.Random().nextDouble() < reactionProbability && secondaryResponders.length < 2) {
          secondaryResponders.add(candidateId);
        }
      }
    }

    return secondaryResponders;
  }

  /// Calculate response timing based on personality
  static Map<String, dynamic> _calculateResponseTiming(
    CharacterModel character,
    int responseOrder,
    List<GroupChatMessage> conversationHistory,
    Map<String, dynamic> groupDynamics,
  ) {
    final traits = PersonalityDynamicsAnalyzer.extractPersonalityTraits(character);
    
    // Base timing from personality
    int baseDelay = 1000; // Default 1 second
    double urgency = 0.5;

    // Find matching personality timing pattern
    for (final trait in traits) {
      if (responseTimingPatterns.containsKey(trait)) {
        final pattern = responseTimingPatterns[trait]!;
        baseDelay = pattern['min']! + math.Random().nextInt(pattern['max']! - pattern['min']!);
        break;
      }
    }

    // Adjust for conversation intensity
    final conversationIntensity = _calculateConversationIntensity(conversationHistory);
    if (conversationIntensity > 0.5) {
      baseDelay = (baseDelay * 0.7).round(); // Faster in intense conversations
      urgency += 0.3;
    }

    // Adjust for group dynamics
    final dynamicsType = groupDynamics['groupDynamicsType'] as String;
    switch (dynamicsType) {
      case 'high_tension':
        baseDelay = (baseDelay * 0.6).round(); // Quick reactions
        urgency += 0.4;
        break;
      case 'intellectual_debate':
        if (traits.contains('intellectual')) {
          baseDelay = (baseDelay * 1.2).round(); // More thoughtful
        }
        break;
      case 'harmonious':
        baseDelay = (baseDelay * 1.1).round(); // Relaxed pace
        break;
    }

    // Add order-based delay to prevent simultaneous responses
    final orderDelay = responseOrder * (200 + math.Random().nextInt(300));
    final totalDelay = baseDelay + orderDelay;

    return {
      'delay': totalDelay,
      'urgency': math.min(urgency, 1.0),
      'baseDelay': baseDelay,
      'orderDelay': orderDelay,
    };
  }

  /// Calculate conversation intensity from recent messages
  static double _calculateConversationIntensity(List<GroupChatMessage> messages) {
    if (messages.length < 3) return 0.0;

    final recentMessages = messages.reversed.take(5);
    double intensity = 0.0;
    int count = 0;

    for (final message in recentMessages) {
      if (!message.isUser) {
        count++;
        final content = message.content.toLowerCase();
        
        // Check for intensity indicators
        if (content.contains(RegExp(r'[!]{2,}'))) intensity += 0.4;
        else if (content.contains('!')) intensity += 0.2;
        
        if (content.contains(RegExp(r'\b(never|always|absolutely|completely)\b'))) {
          intensity += 0.3;
        }
        
        if (content.contains(RegExp(r'\b(wrong|ridiculous|brilliant|outrageous)\b'))) {
          intensity += 0.3;
        }
      }
    }

    return count > 0 ? intensity / count : 0.0;
  }

  /// Get diagnostic information for conversation coordination
  static Map<String, dynamic> getDiagnostics(
    GroupChatModel groupChat,
    Map<String, CharacterModel> characterModels,
  ) {
    final groupDynamics = PersonalityDynamicsAnalyzer.analyzeGroupDynamics(characterModels);
    final conversationIntensity = _calculateConversationIntensity(groupChat.messages);

    return {
      'groupDynamics': groupDynamics,
      'conversationIntensity': conversationIntensity,
      'messageCount': groupChat.messages.length,
      'activeCharacters': groupChat.activeCharacterIds.length,
      'inactiveCharacters': groupChat.inactiveCharacterIds.length,
    };
  }
}
