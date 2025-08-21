import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/character_model.dart';
import 'models/group_chat_model.dart';
import 'models/group_chat_message.dart';

/// Coordinates character responses in group conversations
class CharacterResponseCoordinator {
  static const int _maxSimultaneousResponses = 2;
  static const double _multipleResponseProbability = 0.3;
  static const double _directAddressingBonus = 0.8;
  static const double _recentSpeakerPenalty = 0.5;
  static const int _recentMessageWindow = 3;

  /// Determine which characters should respond to a user message
  static Future<List<String>> determineRespondingCharacters({
    required GroupChatModel groupChat,
    required String userMessage,
    required Map<String, CharacterModel> characterModels,
    String? lastRespondingCharacterId,
  }) async {
    if (groupChat.characterIds.isEmpty) return [];

    final responseScores = <String, double>{};
    final conversationHistory = groupChat.messages;

    // Initialize all characters with base score
    for (final characterId in groupChat.characterIds) {
      responseScores[characterId] = 0.5; // Base probability
    }

    // Factor 1: Direct addressing detection
    await _applyDirectAddressingBonus(
      responseScores,
      userMessage,
      characterModels,
    );

    // Factor 2: Recent activity penalty
    _applyRecentActivityPenalty(
      responseScores,
      conversationHistory,
      lastRespondingCharacterId,
    );

    // Factor 3: Conversation engagement boost
    _applyEngagementBoost(
      responseScores,
      conversationHistory,
      userMessage,
    );

    // Factor 4: Topic relevance (basic keyword matching)
    await _applyTopicRelevance(
      responseScores,
      userMessage,
      characterModels,
    );

    // Factor 5: First message special handling
    _applyFirstMessageLogic(
      responseScores,
      conversationHistory,
    );

    if (kDebugMode) {
      print('CharacterResponseCoordinator: Response scores:');
      responseScores.forEach((id, score) {
        final character = characterModels[id];
        print('  ${character?.name ?? id}: ${score.toStringAsFixed(2)}');
      });
    }

    // Select characters based on scores
    return _selectCharactersFromScores(responseScores, characterModels);
  }

  /// Detect if specific characters are directly addressed
  static Future<void> _applyDirectAddressingBonus(
    Map<String, double> scores,
    String userMessage,
    Map<String, CharacterModel> characterModels,
  ) async {
    final messageLower = userMessage.toLowerCase();

    for (final entry in characterModels.entries) {
      final characterId = entry.key;
      final character = entry.value;
      
      // Check various ways the character might be addressed
      final nameLower = character.name.toLowerCase();
      final firstNameLower = character.name.split(' ').first.toLowerCase();
      
      // Direct name mention
      if (messageLower.contains(nameLower) || 
          messageLower.contains(firstNameLower)) {
        scores[characterId] = (scores[characterId] ?? 0.5) + _directAddressingBonus;
        continue;
      }

      // Addressing patterns like "@Einstein" or "Einstein,"
      if (messageLower.contains('@$firstNameLower') ||
          messageLower.contains('$firstNameLower,') ||
          messageLower.contains('$firstNameLower:')) {
        scores[characterId] = (scores[characterId] ?? 0.5) + _directAddressingBonus;
        continue;
      }

      // Question directed at specific character
      if (messageLower.contains('what do you think, $firstNameLower') ||
          messageLower.contains('$firstNameLower, what') ||
          messageLower.contains('hey $firstNameLower')) {
        scores[characterId] = (scores[characterId] ?? 0.5) + _directAddressingBonus;
      }
    }
  }

  /// Reduce probability for characters who spoke recently
  static void _applyRecentActivityPenalty(
    Map<String, double> scores,
    List<GroupChatMessage> conversationHistory,
    String? lastRespondingCharacterId,
  ) {
    // Heavy penalty for the immediate last responder
    if (lastRespondingCharacterId != null) {
      scores[lastRespondingCharacterId] = 
          (scores[lastRespondingCharacterId] ?? 0.5) * _recentSpeakerPenalty;
    }

    // Lighter penalty for characters who spoke in recent messages
    final recentMessages = conversationHistory
        .where((m) => !m.isUser)
        .toList()
        .reversed
        .take(_recentMessageWindow)
        .toList();

    for (final message in recentMessages) {
      if (message.characterId != lastRespondingCharacterId) {
        scores[message.characterId] = 
            (scores[message.characterId] ?? 0.5) * 0.8; // Lighter penalty
      }
    }
  }

  /// Boost characters who haven't participated much
  static void _applyEngagementBoost(
    Map<String, double> scores,
    List<GroupChatMessage> conversationHistory,
    String userMessage,
  ) {
    // Count how many times each character has spoken
    final speakingCounts = <String, int>{};
    for (final message in conversationHistory) {
      if (!message.isUser) {
        speakingCounts[message.characterId] = 
            (speakingCounts[message.characterId] ?? 0) + 1;
      }
    }

    // Find the character who has spoken the most
    final maxCount = speakingCounts.values.isNotEmpty 
        ? speakingCounts.values.reduce(max) 
        : 0;

    // Boost characters who have spoken less
    for (final characterId in scores.keys) {
      final speakingCount = speakingCounts[characterId] ?? 0;
      if (maxCount > 0) {
        final engagementRatio = 1.0 - (speakingCount / maxCount);
        scores[characterId] = (scores[characterId] ?? 0.5) + (engagementRatio * 0.3);
      }
    }
  }

  /// Apply topic relevance based on character expertise
  static Future<void> _applyTopicRelevance(
    Map<String, double> scores,
    String userMessage,
    Map<String, CharacterModel> characterModels,
  ) async {
    final messageLower = userMessage.toLowerCase();

    // Define topic keywords and associated character types
    final topicKeywords = {
      'science': ['science', 'physics', 'chemistry', 'experiment', 'theory', 'research'],
      'philosophy': ['philosophy', 'meaning', 'existence', 'truth', 'ethics', 'morality'],
      'art': ['art', 'painting', 'music', 'creativity', 'beauty', 'aesthetic'],
      'history': ['history', 'past', 'ancient', 'war', 'civilization', 'empire'],
      'technology': ['technology', 'invention', 'innovation', 'future', 'machine'],
      'literature': ['literature', 'poetry', 'writing', 'story', 'novel', 'book'],
      'politics': ['politics', 'government', 'power', 'leadership', 'democracy'],
      'sports': ['sports', 'athletic', 'competition', 'game', 'victory'],
    };

    // Simple keyword matching for topic relevance
    for (final entry in characterModels.entries) {
      final characterId = entry.key;
      final character = entry.value;
      final characterInfo = '${character.name} ${character.systemPrompt}'.toLowerCase();

      double topicBonus = 0.0;

      for (final topicEntry in topicKeywords.entries) {
        final topic = topicEntry.key;
        final keywords = topicEntry.value;

        // Check if message contains topic keywords
        final messageRelevance = keywords.any((keyword) => 
            messageLower.contains(keyword));

        // Check if character is associated with this topic
        final characterRelevance = keywords.any((keyword) => 
            characterInfo.contains(keyword)) ||
            characterInfo.contains(topic);

        if (messageRelevance && characterRelevance) {
          topicBonus += 0.2;
        }
      }

      scores[characterId] = (scores[characterId] ?? 0.5) + topicBonus;
    }
  }

  /// Special logic for first messages in a conversation
  static void _applyFirstMessageLogic(
    Map<String, double> scores,
    List<GroupChatMessage> conversationHistory,
  ) {
    final aiMessages = conversationHistory.where((m) => !m.isUser).toList();
    
    // If this is the first user message, encourage 1-2 characters to respond
    if (aiMessages.isEmpty) {
      // Boost scores slightly to encourage initial responses
      for (final characterId in scores.keys) {
        scores[characterId] = (scores[characterId] ?? 0.5) + 0.2;
      }
    }
  }

  /// Select characters based on calculated scores
  static List<String> _selectCharactersFromScores(
    Map<String, double> scores,
    Map<String, CharacterModel> characterModels,
  ) {
    if (scores.isEmpty) return [];

    // Sort characters by score (highest first)
    final sortedEntries = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Check for very high scores (direct addressing)
    final highScoreThreshold = 1.0;
    final highScoreCharacters = sortedEntries
        .where((entry) => entry.value >= highScoreThreshold)
        .map((entry) => entry.key)
        .toList();

    if (highScoreCharacters.isNotEmpty) {
      // If characters are directly addressed, they should respond
      return highScoreCharacters.take(_maxSimultaneousResponses).toList();
    }

    // Normal selection logic
    final selectedCharacters = <String>[];
    
    // Always include the highest scoring character
    selectedCharacters.add(sortedEntries.first.key);

    // Decide if multiple characters should respond
    final shouldMultipleRespond = Random().nextDouble() < _multipleResponseProbability;
    
    if (shouldMultipleRespond && 
        sortedEntries.length > 1 && 
        selectedCharacters.length < _maxSimultaneousResponses) {
      
      // Add second highest scoring character if their score is reasonable
      final secondScore = sortedEntries[1].value;
      if (secondScore > 0.4) { // Minimum threshold for second responder
        selectedCharacters.add(sortedEntries[1].key);
      }
    }

    if (kDebugMode) {
      print('CharacterResponseCoordinator: Selected characters: $selectedCharacters');
    }

    return selectedCharacters;
  }

  /// Analyze conversation flow and suggest next actions
  static Map<String, dynamic> analyzeConversationFlow(
    GroupChatModel groupChat,
    Map<String, CharacterModel> characterModels,
  ) {
    final recentMessages = groupChat.messages
        .where((m) => !m.isUser)
        .toList()
        .reversed
        .take(5)
        .toList();

    final participatingCharacters = recentMessages
        .map((m) => m.characterId)
        .toSet();

    final inactiveCharacters = groupChat.characterIds
        .where((id) => !participatingCharacters.contains(id))
        .toList();

    return {
      'recentParticipants': participatingCharacters.length,
      'inactiveCharacters': inactiveCharacters.length,
      'conversationBalance': participatingCharacters.length / groupChat.characterIds.length,
      'suggestions': _generateConversationSuggestions(
        groupChat, 
        characterModels, 
        inactiveCharacters,
      ),
    };
  }

  /// Generate suggestions to improve conversation flow
  static List<String> _generateConversationSuggestions(
    GroupChatModel groupChat,
    Map<String, CharacterModel> characterModels,
    List<String> inactiveCharacters,
  ) {
    final suggestions = <String>[];

    if (inactiveCharacters.isNotEmpty) {
      final inactiveNames = inactiveCharacters
          .map((id) => characterModels[id]?.name ?? 'Unknown')
          .take(2)
          .join(' and ');
      
      suggestions.add('Try asking $inactiveNames what they think');
    }

    if (groupChat.messages.length > 10) {
      suggestions.add('Ask for a different perspective on the topic');
    }

    if (groupChat.messages.where((m) => m.isUser).length < 3) {
      suggestions.add('Share your own thoughts to encourage discussion');
    }

    return suggestions;
  }
}