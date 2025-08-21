import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/character_model.dart';
import 'models/group_chat_message.dart';
import 'personality_dynamics_analyzer.dart';

/// Conversation topic with relevance tracking
class ConversationTopic {
  final String topic;
  final List<String> keywords;
  final double intensity;
  final DateTime firstMentioned;
  final DateTime lastMentioned;
  final List<String> participatingCharacters;
  final String sentiment; // positive, negative, neutral
  
  ConversationTopic({
    required this.topic,
    required this.keywords,
    required this.intensity,
    required this.firstMentioned,
    required this.lastMentioned,
    required this.participatingCharacters,
    required this.sentiment,
  });

  Map<String, dynamic> toJson() => {
    'topic': topic,
    'keywords': keywords,
    'intensity': intensity,
    'firstMentioned': firstMentioned.toIso8601String(),
    'lastMentioned': lastMentioned.toIso8601String(),
    'participatingCharacters': participatingCharacters,
    'sentiment': sentiment,
  };

  factory ConversationTopic.fromJson(Map<String, dynamic> json) => ConversationTopic(
    topic: json['topic'],
    keywords: List<String>.from(json['keywords']),
    intensity: json['intensity'],
    firstMentioned: DateTime.parse(json['firstMentioned']),
    lastMentioned: DateTime.parse(json['lastMentioned']),
    participatingCharacters: List<String>.from(json['participatingCharacters']),
    sentiment: json['sentiment'],
  );
}

/// Character's emotional state and position in conversation
class CharacterEmotionalState {
  final String characterId;
  final String mood; // engaged, agitated, thoughtful, supportive, challenging
  final double intensity; // 0.0 to 1.0
  final List<String> recentTopics;
  final Map<String, String> positionsOnTopics; // topic -> stance
  final DateTime lastUpdate;
  
  CharacterEmotionalState({
    required this.characterId,
    required this.mood,
    required this.intensity,
    required this.recentTopics,
    required this.positionsOnTopics,
    required this.lastUpdate,
  });

  Map<String, dynamic> toJson() => {
    'characterId': characterId,
    'mood': mood,
    'intensity': intensity,
    'recentTopics': recentTopics,
    'positionsOnTopics': positionsOnTopics,
    'lastUpdate': lastUpdate.toIso8601String(),
  };

  factory CharacterEmotionalState.fromJson(Map<String, dynamic> json) => CharacterEmotionalState(
    characterId: json['characterId'],
    mood: json['mood'],
    intensity: json['intensity'],
    recentTopics: List<String>.from(json['recentTopics']),
    positionsOnTopics: Map<String, String>.from(json['positionsOnTopics']),
    lastUpdate: DateTime.parse(json['lastUpdate']),
  );
}

/// Main conversation memory state
class ConversationMemory {
  final String groupId;
  final List<ConversationTopic> activeTopics;
  final Map<String, CharacterEmotionalState> characterStates;
  final List<String> conversationFlow; // Track conversation narrative
  final double overallTension; // 0.0 to 1.0
  final String dominantMood; // intellectual, emotional, conflicted, harmonious
  final DateTime lastUpdate;

  ConversationMemory({
    required this.groupId,
    required this.activeTopics,
    required this.characterStates,
    required this.conversationFlow,
    required this.overallTension,
    required this.dominantMood,
    required this.lastUpdate,
  });

  Map<String, dynamic> toJson() => {
    'groupId': groupId,
    'activeTopics': activeTopics.map((t) => t.toJson()).toList(),
    'characterStates': characterStates.map((k, v) => MapEntry(k, v.toJson())),
    'conversationFlow': conversationFlow,
    'overallTension': overallTension,
    'dominantMood': dominantMood,
    'lastUpdate': lastUpdate.toIso8601String(),
  };

  factory ConversationMemory.fromJson(Map<String, dynamic> json) => ConversationMemory(
    groupId: json['groupId'],
    activeTopics: (json['activeTopics'] as List)
        .map((t) => ConversationTopic.fromJson(t))
        .toList(),
    characterStates: (json['characterStates'] as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, CharacterEmotionalState.fromJson(v))),
    conversationFlow: List<String>.from(json['conversationFlow']),
    overallTension: json['overallTension'],
    dominantMood: json['dominantMood'],
    lastUpdate: DateTime.parse(json['lastUpdate']),
  );
}

/// Tracks conversation context, topics, and emotional undertones for natural flow
class ConversationMemorySystem {
  static const int _maxTopicMemory = 10;
  static const int _maxEmotionalMemory = 15;
  static const int _contextWindow = 20;

  // Memory storage
  static final Map<String, ConversationMemory> _conversationMemories = {};

  /// Update conversation memory with new message
  static ConversationMemory updateMemory({
    required String groupId,
    required List<GroupChatMessage> recentMessages,
    required Map<String, CharacterModel> characterModels,
    ConversationMemory? existingMemory,
  }) {
    final now = DateTime.now();
    final memory = existingMemory ?? ConversationMemory(
      groupId: groupId,
      activeTopics: [],
      characterStates: {},
      conversationFlow: [],
      overallTension: 0.0,
      dominantMood: 'neutral',
      lastUpdate: now,
    );

    // Analyze recent messages for topics and emotional content
    final updatedTopics = _updateTopics(memory.activeTopics, recentMessages);
    final updatedCharacterStates = _updateCharacterStates(
      memory.characterStates,
      recentMessages,
      characterModels,
      updatedTopics,
    );
    final updatedFlow = _updateConversationFlow(memory.conversationFlow, recentMessages);
    final tension = _calculateOverallTension(recentMessages, updatedCharacterStates);
    final mood = _determineDominantMood(recentMessages, updatedCharacterStates);

    final updatedMemory = ConversationMemory(
      groupId: groupId,
      activeTopics: updatedTopics,
      characterStates: updatedCharacterStates,
      conversationFlow: updatedFlow,
      overallTension: tension,
      dominantMood: mood,
      lastUpdate: now,
    );

    _conversationMemories[groupId] = updatedMemory;

    if (kDebugMode) {
      _logMemoryUpdate(updatedMemory);
    }

    return updatedMemory;
  }

  /// Extract and update conversation topics
  static List<ConversationTopic> _updateTopics(
    List<ConversationTopic> existingTopics,
    List<GroupChatMessage> recentMessages,
  ) {
    final topicMap = <String, ConversationTopic>{};
    
    // Add existing topics
    for (final topic in existingTopics) {
      topicMap[topic.topic] = topic;
    }

    final now = DateTime.now();
    
    // Predefined topic categories with keywords
    final topicCategories = {
      'science': ['science', 'physics', 'theory', 'research', 'experiment', 'discovery'],
      'philosophy': ['philosophy', 'meaning', 'existence', 'truth', 'wisdom', 'ethics'],
      'politics': ['politics', 'power', 'government', 'leadership', 'democracy', 'empire'],
      'art': ['art', 'beauty', 'creativity', 'music', 'painting', 'aesthetic'],
      'war': ['war', 'battle', 'conflict', 'military', 'strategy', 'victory'],
      'love': ['love', 'romance', 'passion', 'heart', 'relationship', 'devotion'],
      'death': ['death', 'mortality', 'legacy', 'afterlife', 'eternal', 'finite'],
      'technology': ['technology', 'innovation', 'invention', 'future', 'progress'],
      'religion': ['god', 'divine', 'spiritual', 'faith', 'belief', 'sacred'],
      'justice': ['justice', 'fairness', 'equality', 'rights', 'law', 'moral'],
    };

    // Analyze recent messages for topics
    for (final message in recentMessages.reversed.take(10)) {
      if (message.isUser) continue;

      final content = message.content.toLowerCase();
      final characterId = message.characterId;

      for (final categoryEntry in topicCategories.entries) {
        final topicName = categoryEntry.key;
        final keywords = categoryEntry.value;

        // Check if message contains topic keywords
        final matchingKeywords = keywords.where((keyword) => 
            content.contains(keyword)).toList();

        if (matchingKeywords.isNotEmpty) {
          final intensity = _calculateTopicIntensity(content, matchingKeywords);
          final sentiment = _analyzeSentiment(content);

          if (topicMap.containsKey(topicName)) {
            // Update existing topic
            final existingTopic = topicMap[topicName]!;
            final updatedParticipants = {...existingTopic.participatingCharacters, characterId}.toList();
            
            topicMap[topicName] = ConversationTopic(
              topic: topicName,
              keywords: {...existingTopic.keywords, ...matchingKeywords}.toList(),
              intensity: math.max(existingTopic.intensity, intensity),
              firstMentioned: existingTopic.firstMentioned,
              lastMentioned: message.timestamp,
              participatingCharacters: updatedParticipants,
              sentiment: _combineSentiment(existingTopic.sentiment, sentiment),
            );
          } else {
            // Create new topic
            topicMap[topicName] = ConversationTopic(
              topic: topicName,
              keywords: matchingKeywords,
              intensity: intensity,
              firstMentioned: message.timestamp,
              lastMentioned: message.timestamp,
              participatingCharacters: [characterId],
              sentiment: sentiment,
            );
          }
        }
      }
    }

    // Remove old or inactive topics
    final activeTopics = topicMap.values.where((topic) {
      final timeSinceLastMention = now.difference(topic.lastMentioned).inMinutes;
      return timeSinceLastMention < 30; // Keep topics active for 30 minutes
    }).toList();

    // Sort by intensity and recency, keep top topics
    activeTopics.sort((a, b) {
      final aScore = a.intensity + (1.0 / (1 + now.difference(a.lastMentioned).inMinutes));
      final bScore = b.intensity + (1.0 / (1 + now.difference(b.lastMentioned).inMinutes));
      return bScore.compareTo(aScore);
    });

    return activeTopics.take(_maxTopicMemory).toList();
  }

  /// Calculate topic intensity based on content analysis
  static double _calculateTopicIntensity(String content, List<String> matchingKeywords) {
    double intensity = matchingKeywords.length * 0.2;

    // Check for intensity indicators
    if (content.contains(RegExp(r'[!]{2,}'))) intensity += 0.4;
    else if (content.contains('!')) intensity += 0.2;

    if (content.contains(RegExp(r'\b(absolutely|completely|never|always)\b'))) {
      intensity += 0.3;
    }

    if (content.contains(RegExp(r'\b(passionate|strongly|deeply)\b'))) {
      intensity += 0.2;
    }

    return math.min(intensity, 1.0);
  }

  /// Analyze sentiment of content
  static String _analyzeSentiment(String content) {
    final positiveWords = ['love', 'beautiful', 'wonderful', 'brilliant', 'excellent', 'amazing', 'perfect'];
    final negativeWords = ['hate', 'terrible', 'awful', 'wrong', 'horrible', 'disgusting', 'failed'];

    int positiveCount = 0;
    int negativeCount = 0;

    for (final word in positiveWords) {
      if (content.contains(word)) positiveCount++;
    }

    for (final word in negativeWords) {
      if (content.contains(word)) negativeCount++;
    }

    if (positiveCount > negativeCount) return 'positive';
    if (negativeCount > positiveCount) return 'negative';
    return 'neutral';
  }

  /// Combine sentiments from multiple mentions
  static String _combineSentiment(String existing, String newSentiment) {
    if (existing == newSentiment) return existing;
    if (existing == 'neutral') return newSentiment;
    if (newSentiment == 'neutral') return existing;
    return 'mixed'; // Conflicting sentiments
  }

  /// Update character emotional states
  static Map<String, CharacterEmotionalState> _updateCharacterStates(
    Map<String, CharacterEmotionalState> existingStates,
    List<GroupChatMessage> recentMessages,
    Map<String, CharacterModel> characterModels,
    List<ConversationTopic> activeTopics,
  ) {
    final updatedStates = <String, CharacterEmotionalState>{};
    final now = DateTime.now();

    // Initialize states for all characters
    for (final characterId in characterModels.keys) {
      updatedStates[characterId] = existingStates[characterId] ?? CharacterEmotionalState(
        characterId: characterId,
        mood: 'neutral',
        intensity: 0.0,
        recentTopics: [],
        positionsOnTopics: {},
        lastUpdate: now,
      );
    }

    // Analyze recent messages for emotional content
    final characterMessages = <String, List<GroupChatMessage>>{};
    for (final message in recentMessages.reversed.take(15)) {
      if (!message.isUser) {
        characterMessages[message.characterId] = 
            (characterMessages[message.characterId] ?? [])..add(message);
      }
    }

    for (final entry in characterMessages.entries) {
      final characterId = entry.key;
      final messages = entry.value;
      final character = characterModels[characterId];
      
      if (character == null) continue;

      final mood = _analyzeMood(messages, character);
      final intensity = _calculateEmotionalIntensity(messages);
      final recentTopics = _extractCharacterTopics(messages, activeTopics);
      final positions = _extractCharacterPositions(messages, activeTopics);

      updatedStates[characterId] = CharacterEmotionalState(
        characterId: characterId,
        mood: mood,
        intensity: intensity,
        recentTopics: recentTopics,
        positionsOnTopics: positions,
        lastUpdate: now,
      );
    }

    return updatedStates;
  }

  /// Analyze character mood from their recent messages
  static String _analyzeMood(List<GroupChatMessage> messages, CharacterModel character) {
    if (messages.isEmpty) return 'neutral';

    final traits = PersonalityDynamicsAnalyzer.extractPersonalityTraits(character);
    final combinedContent = messages.map((m) => m.content.toLowerCase()).join(' ');

    // Emotional indicators
    final agitatedWords = ['disagree', 'wrong', 'ridiculous', 'absurd', 'nonsense'];
    final engagedWords = ['interesting', 'fascinating', 'consider', 'analyze', 'think'];
    final supportiveWords = ['agree', 'exactly', 'brilliant', 'wonderful', 'yes'];
    final challengingWords = ['however', 'but', 'challenge', 'question', 'doubt'];

    int agitatedScore = agitatedWords.where((word) => combinedContent.contains(word)).length;
    int engagedScore = engagedWords.where((word) => combinedContent.contains(word)).length;
    int supportiveScore = supportiveWords.where((word) => combinedContent.contains(word)).length;
    int challengingScore = challengingWords.where((word) => combinedContent.contains(word)).length;

    // Adjust scores based on personality traits
    if (traits.contains('emotional')) {
      agitatedScore = (agitatedScore * 1.5).round();
      supportiveScore = (supportiveScore * 1.3).round();
    }

    if (traits.contains('intellectual')) {
      engagedScore = (engagedScore * 1.4).round();
      challengingScore = (challengingScore * 1.2).round();
    }

    if (traits.contains('dominant')) {
      challengingScore = (challengingScore * 1.3).round();
    }

    // Determine dominant mood
    final scores = {
      'agitated': agitatedScore,
      'engaged': engagedScore,
      'supportive': supportiveScore,
      'challenging': challengingScore,
    };

    final maxScore = scores.values.reduce(math.max);
    if (maxScore == 0) return 'thoughtful';

    return scores.entries.firstWhere((entry) => entry.value == maxScore).key;
  }

  /// Calculate emotional intensity from messages
  static double _calculateEmotionalIntensity(List<GroupChatMessage> messages) {
    if (messages.isEmpty) return 0.0;

    double totalIntensity = 0.0;

    for (final message in messages) {
      final content = message.content;
      double messageIntensity = 0.0;

      // Punctuation indicators
      if (content.contains(RegExp(r'[!]{2,}'))) messageIntensity += 0.5;
      else if (content.contains('!')) messageIntensity += 0.2;

      if (content.contains('?')) messageIntensity += 0.1;

      // Intensity words
      if (content.toLowerCase().contains(RegExp(r'\b(absolutely|completely|utterly|totally)\b'))) {
        messageIntensity += 0.3;
      }

      if (content.toLowerCase().contains(RegExp(r'\b(strongly|deeply|passionately)\b'))) {
        messageIntensity += 0.2;
      }

      totalIntensity += messageIntensity;
    }

    return math.min(totalIntensity / messages.length, 1.0);
  }

  /// Extract topics character has discussed
  static List<String> _extractCharacterTopics(
    List<GroupChatMessage> messages,
    List<ConversationTopic> activeTopics,
  ) {
    final characterTopics = <String>[];
    final combinedContent = messages.map((m) => m.content.toLowerCase()).join(' ');

    for (final topic in activeTopics) {
      if (topic.keywords.any((keyword) => combinedContent.contains(keyword))) {
        characterTopics.add(topic.topic);
      }
    }

    return characterTopics;
  }

  /// Extract character positions on topics
  static Map<String, String> _extractCharacterPositions(
    List<GroupChatMessage> messages,
    List<ConversationTopic> activeTopics,
  ) {
    final positions = <String, String>{};

    for (final topic in activeTopics) {
      final topicMessages = messages.where((m) => 
          topic.keywords.any((keyword) => m.content.toLowerCase().contains(keyword))
      ).toList();

      if (topicMessages.isNotEmpty) {
        final combinedContent = topicMessages.map((m) => m.content.toLowerCase()).join(' ');
        
        // Simple stance detection
        if (combinedContent.contains(RegExp(r'\b(disagree|oppose|against|wrong)\b'))) {
          positions[topic.topic] = 'opposing';
        } else if (combinedContent.contains(RegExp(r'\b(agree|support|favor|correct)\b'))) {
          positions[topic.topic] = 'supporting';
        } else {
          positions[topic.topic] = 'analytical';
        }
      }
    }

    return positions;
  }

  /// Update conversation flow narrative
  static List<String> _updateConversationFlow(
    List<String> existingFlow,
    List<GroupChatMessage> recentMessages,
  ) {
    final flow = List<String>.from(existingFlow);
    
    // Analyze conversation patterns in recent messages
    final patterns = _identifyConversationPatterns(recentMessages);
    
    for (final pattern in patterns) {
      if (!flow.contains(pattern)) {
        flow.add(pattern);
      }
    }

    // Keep only recent flow items
    return flow.length > 20 ? flow.sublist(flow.length - 20) : flow;
  }

  /// Identify conversation patterns
  static List<String> _identifyConversationPatterns(List<GroupChatMessage> messages) {
    final patterns = <String>[];
    
    if (messages.length < 3) return patterns;

    // Check for debate pattern
    final debateIndicators = ['disagree', 'however', 'but', 'wrong', 'challenge'];
    if (messages.any((m) => debateIndicators.any((indicator) => 
        m.content.toLowerCase().contains(indicator)))) {
      patterns.add('debate_emerged');
    }

    // Check for agreement cascade
    final agreementIndicators = ['agree', 'exactly', 'yes', 'correct', 'brilliant'];
    if (messages.where((m) => !m.isUser).take(3).every((m) => 
        agreementIndicators.any((indicator) => m.content.toLowerCase().contains(indicator)))) {
      patterns.add('agreement_cascade');
    }

    // Check for topic shift
    if (messages.length >= 5) {
      patterns.add('topic_development');
    }

    return patterns;
  }

  /// Calculate overall conversation tension
  static double _calculateOverallTension(
    List<GroupChatMessage> messages,
    Map<String, CharacterEmotionalState> characterStates,
  ) {
    if (messages.isEmpty) return 0.0;

    double tension = 0.0;
    int count = 0;

    // Tension from character emotional states
    for (final state in characterStates.values) {
      if (state.mood == 'agitated' || state.mood == 'challenging') {
        tension += state.intensity;
        count++;
      }
    }

    // Tension from message content
    final recentContent = messages.reversed.take(10)
        .where((m) => !m.isUser)
        .map((m) => m.content.toLowerCase())
        .join(' ');

    final conflictWords = ['disagree', 'wrong', 'ridiculous', 'absurd', 'challenge', 'oppose'];
    final conflictCount = conflictWords.where((word) => recentContent.contains(word)).length;
    
    tension += conflictCount * 0.1;
    count++;

    return count > 0 ? math.min(tension / count, 1.0) : 0.0;
  }

  /// Determine dominant mood of conversation
  static String _determineDominantMood(
    List<GroupChatMessage> messages,
    Map<String, CharacterEmotionalState> characterStates,
  ) {
    final moodCounts = <String, int>{};

    // Count character moods
    for (final state in characterStates.values) {
      moodCounts[state.mood] = (moodCounts[state.mood] ?? 0) + 1;
    }

    // Analyze conversation content
    final recentContent = messages.reversed.take(10)
        .where((m) => !m.isUser)
        .map((m) => m.content.toLowerCase())
        .join(' ');

    if (recentContent.contains(RegExp(r'\b(theory|analysis|science|philosophy)\b'))) {
      moodCounts['intellectual'] = (moodCounts['intellectual'] ?? 0) + 2;
    }

    if (recentContent.contains(RegExp(r'\b(disagree|challenge|wrong)\b'))) {
      moodCounts['conflicted'] = (moodCounts['conflicted'] ?? 0) + 2;
    }

    if (recentContent.contains(RegExp(r'\b(agree|wonderful|brilliant)\b'))) {
      moodCounts['harmonious'] = (moodCounts['harmonious'] ?? 0) + 1;
    }

    // Find dominant mood
    if (moodCounts.isEmpty) return 'neutral';
    
    final maxCount = moodCounts.values.reduce(math.max);
    return moodCounts.entries.firstWhere((entry) => entry.value == maxCount).key;
  }

  /// Get conversation memory for a group
  static ConversationMemory? getMemory(String groupId) {
    return _conversationMemories[groupId];
  }

  /// Clear memory for a group
  static void clearMemory(String groupId) {
    _conversationMemories.remove(groupId);
  }

  /// Get suggestions based on conversation memory
  static List<String> getSuggestions(ConversationMemory memory) {
    final suggestions = <String>[];

    // Suggest addressing inactive characters
    final inactiveCharacters = memory.characterStates.entries
        .where((entry) => entry.value.recentTopics.isEmpty)
        .map((entry) => entry.key)
        .take(2)
        .toList();

    if (inactiveCharacters.isNotEmpty) {
      suggestions.add('Ask ${inactiveCharacters.join(' or ')} what they think');
    }

    // Suggest exploring high-intensity topics
    final highIntensityTopics = memory.activeTopics
        .where((topic) => topic.intensity > 0.6)
        .take(2)
        .toList();

    for (final topic in highIntensityTopics) {
      suggestions.add('Explore the ${topic.topic} discussion further');
    }

    // Suggest resolving conflicts
    if (memory.overallTension > 0.6) {
      suggestions.add('Ask for different perspectives to resolve the tension');
    }

    return suggestions;
  }

  /// Log memory update for debugging
  static void _logMemoryUpdate(ConversationMemory memory) {
    if (kDebugMode) {
      print('=== Conversation Memory Update ===');
      print('Group: ${memory.groupId}');
      print('Active Topics: ${memory.activeTopics.map((t) => '${t.topic}(${t.intensity.toStringAsFixed(2)})').join(', ')}');
      print('Overall Tension: ${memory.overallTension.toStringAsFixed(2)}');
      print('Dominant Mood: ${memory.dominantMood}');
      print('Character States:');
      memory.characterStates.forEach((id, state) {
        print('  $id: ${state.mood} (${state.intensity.toStringAsFixed(2)})');
      });
      print('==================================');
    }
  }
}
