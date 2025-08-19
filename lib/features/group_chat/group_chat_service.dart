import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../core/services/hybrid_chat_service.dart';
import '../../core/utils/app_logger.dart';
import '../models/character_model.dart';
import '../providers/characters_provider.dart';
import '../character_prompts/famous_character_service.dart';
import '../character_prompts/famous_character_prompts.dart';
import '../chat/models/message_status.dart';
import 'models/group_chat_model.dart';
import 'models/group_chat_message.dart';
import 'character_response_coordinator.dart';
import 'enhanced_conversation_coordinator.dart';
import 'personality_dynamics_analyzer.dart';
import 'conversation_memory_system.dart';
import 'dynamic_timing_controller.dart';

/// Service for managing group conversations with multiple AI characters
class GroupChatService {
  static GroupChatService? _instance;
  static GroupChatService get instance => _instance ??= GroupChatService._();
  GroupChatService._();

  static bool _isInitialized = false;
  static CharactersProvider? _charactersProvider;
  
  // Cache for character models to avoid repeated lookups
  static final Map<String, CharacterModel> _characterCache = {};
  
  // Active group conversations
  static final Map<String, GroupChatModel> _activeGroups = {};
  
  // Response coordination state
  static final Map<String, String?> _lastRespondingCharacter = {};
  static final Map<String, Set<String>> _charactersInConversation = {};

  /// Initialize the service
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize dependencies
      await HybridChatService.initialize();
      
      _isInitialized = true;
      AppLogger.serviceInitialized('GroupChatService');
      
      if (kDebugMode) {
        print('GroupChatService initialized successfully');
      }
    } catch (e) {
      AppLogger.serviceError('GroupChatService', 'initialization failed', e);
      _isInitialized = true; // Prevent retry loops
      rethrow;
    }
  }

  /// Set the characters provider for accessing user characters
  static void setCharactersProvider(CharactersProvider provider) {
    _charactersProvider = provider;
  }

  /// Get character model by ID (from user characters or famous characters)
  static Future<CharacterModel?> _getCharacterById(String characterId) async {
    // Check cache first
    if (_characterCache.containsKey(characterId)) {
      return _characterCache[characterId];
    }

    CharacterModel? character;

    // Check if it's a famous character (starts with 'famous_')
    if (characterId.startsWith('famous_')) {
      final characterName = characterId.substring(7); // Remove 'famous_' prefix
      final virtualCharacter = FamousCharacterService.getVirtualCharacter(characterName);
      if (virtualCharacter != null) {
        character = virtualCharacter;
      } else {
        // Create virtual character if it doesn't exist
        await FamousCharacterService.initializeChat(characterName);
        character = FamousCharacterService.getVirtualCharacter(characterName);
      }
    } else {
      // It's a user character
      if (_charactersProvider != null) {
        character = await _charactersProvider!.loadCharacterById(characterId);
      }
    }

    // Cache the character if found
    if (character != null) {
      _characterCache[characterId] = character;
    }

    return character;
  }

  /// Get character display info for UI
  static Future<Map<String, dynamic>?> getCharacterDisplayInfo(String characterId) async {
    final character = await _getCharacterById(characterId);
    if (character == null) return null;

    return {
      'id': character.id,
      'name': character.name,
      'avatarUrl': character.imageUrl,
      'avatarText': character.name.isNotEmpty ? 
          character.name.substring(0, 1).toUpperCase() : '?',
      'accentColor': character.accentColor.value,
    };
  }

  /// Send a user message to a group and coordinate AI responses with natural flow
  static Future<Stream<GroupChatMessage>> sendMessageToGroupStream({
    required String groupId,
    required String userMessage,
    required GroupChatModel groupChat,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final controller = StreamController<GroupChatMessage>();

    try {
      // Add user message immediately
      final userMsg = GroupChatMessage.user(
        content: userMessage,
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
      );
      controller.add(userMsg);

      // Update active group
      _activeGroups[groupId] = groupChat.addMessage(userMsg);
      _charactersInConversation[groupId] = groupChat.characterIds.toSet();

      // Update conversation memory
      final characterModels = <String, CharacterModel>{};
      for (final characterId in groupChat.characterIds) {
        final character = await _getCharacterById(characterId);
        if (character != null) {
          characterModels[characterId] = character;
        }
      }

      final existingMemory = ConversationMemorySystem.getMemory(groupId);
      final updatedMemory = ConversationMemorySystem.updateMemory(
        groupId: groupId,
        recentMessages: _activeGroups[groupId]!.messages,
        characterModels: characterModels,
        existingMemory: existingMemory,
      );

      // Use enhanced conversation coordinator
      final responseSchedule = await EnhancedConversationCoordinator.determineRespondingCharactersAdvanced(
        groupChat: _activeGroups[groupId]!,
        userMessage: userMessage,
        characterModels: characterModels,
        lastRespondingCharacterId: _lastRespondingCharacter[groupId],
      );

      if (kDebugMode) {
        print('GroupChatService: $groupId - Enhanced response schedule created');
        for (final response in responseSchedule) {
          print('  ${characterModels[response['characterId']]?.name}: ${response['delay']}ms');
        }
      }

      // Execute responses with natural timing
      _executeResponseSchedule(
        controller,
        groupId,
        responseSchedule,
        userMessage,
        characterModels,
        updatedMemory,
      );

    } catch (e) {
      AppLogger.error('Failed to send message to group $groupId: $e', tag: 'GroupChatService');
      
      controller.addError(e);
    }

    return controller.stream;
  }

  /// Execute response schedule with natural timing and character interactions
  static void _executeResponseSchedule(
    StreamController<GroupChatMessage> controller,
    String groupId,
    List<Map<String, dynamic>> responseSchedule,
    String userMessage,
    Map<String, CharacterModel> characterModels,
    ConversationMemory conversationMemory,
  ) async {
    try {
      for (final responseInfo in responseSchedule) {
        final characterId = responseInfo['characterId'] as String;
        final delay = responseInfo['delay'] as int;
        final showThinking = responseInfo['showThinking'] as bool? ?? false;
        final thinkingDuration = responseInfo['thinkingDuration'] as int? ?? 0;
        
        // Wait for the calculated delay
        if (delay > 0) {
          await Future.delayed(Duration(milliseconds: delay));
        }

        // Show thinking indicator if appropriate
        if (showThinking && thinkingDuration > 0) {
          final character = characterModels[characterId]!;
          final thinkingMsg = GroupChatMessage.character(
            content: '',
            characterId: characterId,
            characterName: character.name,
            characterAvatarUrl: character.imageUrl,
            status: MessageStatus.characterTyping,
            metadata: {'isThinking': true, 'thinkingDuration': thinkingDuration},
          );
          controller.add(thinkingMsg);

          // Wait for thinking duration
          await Future.delayed(Duration(milliseconds: thinkingDuration));
        }

        try {
          // Get enhanced character response
          final characterResponse = await _getEnhancedCharacterResponse(
            groupId: groupId,
            characterId: characterId,
            userMessage: userMessage,
            conversationContext: _activeGroups[groupId]!.messages,
            conversationMemory: conversationMemory,
            characterModels: characterModels,
          );

          if (characterResponse != null) {
            controller.add(characterResponse);
            
            // Update group with character response
            _activeGroups[groupId] = _activeGroups[groupId]!.addMessage(characterResponse);
            _lastRespondingCharacter[groupId] = characterId;

            // Update conversation memory with new response
            ConversationMemorySystem.updateMemory(
              groupId: groupId,
              recentMessages: _activeGroups[groupId]!.messages,
              characterModels: characterModels,
              existingMemory: conversationMemory,
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error getting enhanced response from character $characterId: $e');
          }
          
          // Add error message
          final errorMsg = await _createErrorMessage(characterId, 
              'I apologize, but I encountered an issue. Please try again.');
          if (errorMsg != null) {
            controller.add(errorMsg);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error executing response schedule: $e');
      }
    } finally {
      controller.close();
    }
  }

  /// Legacy method for backward compatibility
  @Deprecated('Use sendMessageToGroupStream for incremental responses and natural UI updates')
  static Future<List<GroupChatMessage>> sendMessageToGroup({
    required String groupId,
    required String userMessage,
    required GroupChatModel groupChat,
  }) async {
    final responseStream = await sendMessageToGroupStream(
      groupId: groupId,
      userMessage: userMessage,
      groupChat: groupChat,
    );

    final responses = <GroupChatMessage>[];
    await for (final message in responseStream) {
      responses.add(message);
    }

    return responses;
  }

  /// Determine which characters should respond to the user message
  static Future<List<String>> _determineRespondingCharacters({
    required String groupId,
    required GroupChatModel groupChat,
    required String userMessage,
  }) async {
    // Build character models map for the coordinator
    final characterModels = <String, CharacterModel>{};
    for (final characterId in groupChat.characterIds) {
      final character = await _getCharacterById(characterId);
      if (character != null) {
        characterModels[characterId] = character;
      }
    }

    // Use the sophisticated character response coordinator
    return await CharacterResponseCoordinator.determineRespondingCharacters(
      groupChat: groupChat,
      userMessage: userMessage,
      characterModels: characterModels,
      lastRespondingCharacterId: _lastRespondingCharacter[groupId],
    );
  }

  /// Get enhanced AI response from a specific character with personality and context awareness
  static Future<GroupChatMessage?> _getEnhancedCharacterResponse({
    required String groupId,
    required String characterId,
    required String userMessage,
    required List<GroupChatMessage> conversationContext,
    required ConversationMemory conversationMemory,
    required Map<String, CharacterModel> characterModels,
  }) async {
    final character = await _getCharacterById(characterId);
    if (character == null) {
      if (kDebugMode) {
        print('Character not found: $characterId');
      }
      return null;
    }

    try {
      // Build enhanced conversation context
      final contextMessages = _buildEnhancedConversationContext(
        conversationContext, 
        character,
        conversationMemory,
      );

      // Build enhanced system prompt with personality and memory context
      final enhancedSystemPrompt = _buildEnhancedGroupSystemPrompt(
        character, 
        conversationContext,
        conversationMemory,
        characterModels,
      );

      // Get AI response using HybridChatService
      final aiResponse = await HybridChatService.sendMessageToCharacter(
        characterId: characterId,
        message: userMessage,
        systemPrompt: enhancedSystemPrompt,
        chatHistory: contextMessages,
        model: character.model,
        localPrompt: character.localPrompt,
      );

      if (aiResponse != null && aiResponse.isNotEmpty) {
        // Get character display info
        final displayInfo = await getCharacterDisplayInfo(characterId);
        
        return GroupChatMessage.character(
          content: aiResponse,
          characterId: characterId,
          characterName: character.name,
          characterAvatarUrl: character.imageUrl,
          characterAvatarText: displayInfo?['avatarText'],
          timestamp: DateTime.now(),
          status: MessageStatus.sent,
          model: character.model,
          metadata: {
            'groupId': groupId,
            'responseType': 'enhanced_ai_generated',
            'conversationMood': conversationMemory.dominantMood,
            'tensionLevel': conversationMemory.overallTension.toStringAsFixed(2),
            'activeTopics': conversationMemory.activeTopics.map((t) => t.topic).toList(),
          },
        );
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error generating enhanced response for character ${character.name}: $e');
      }
      return null;
    }
  }

  /// Legacy method for backward compatibility
  static Future<GroupChatMessage?> _getCharacterResponse({
    required String groupId,
    required String characterId,
    required String userMessage,
    required List<GroupChatMessage> conversationContext,
  }) async {
    // Build minimal character models map for compatibility
    final characterModels = <String, CharacterModel>{};
    final character = await _getCharacterById(characterId);
    if (character != null) {
      characterModels[characterId] = character;
    }

    // Create minimal conversation memory
    final minimalMemory = ConversationMemory(
      groupId: groupId,
      activeTopics: [],
      characterStates: {},
      conversationFlow: [],
      overallTension: 0.0,
      dominantMood: 'neutral',
      lastUpdate: DateTime.now(),
    );

    return _getEnhancedCharacterResponse(
      groupId: groupId,
      characterId: characterId,
      userMessage: userMessage,
      conversationContext: conversationContext,
      conversationMemory: minimalMemory,
      characterModels: characterModels,
    );
  }

  /// Build enhanced system prompt with personality, memory, and relationship context
  static String _buildEnhancedGroupSystemPrompt(
    CharacterModel character, 
    List<GroupChatMessage> conversationContext,
    ConversationMemory conversationMemory,
    Map<String, CharacterModel> characterModels,
  ) {
    final basePrompt = character.systemPrompt;
    
    // Get other character names and their recent interactions
    final otherCharacters = conversationContext
        .where((m) => !m.isUser && m.characterId != character.id)
        .map((m) => m.characterName)
        .toSet()
        .toList();

    if (otherCharacters.isEmpty) {
      return basePrompt;
    }

    // Build relationship context
    final relationshipContext = _buildRelationshipContext(character, characterModels);
    
    // Build topic context
    final topicContext = _buildTopicContext(conversationMemory);
    
    // Build emotional context
    final emotionalContext = _buildEmotionalContext(character.id, conversationMemory);
    
    // Build conversation flow context
    final flowContext = _buildConversationFlowContext(conversationMemory);

    final enhancedInstruction = '''

=== ENHANCED GROUP CONVERSATION CONTEXT ===
You are ${character.name} participating in a dynamic group conversation with: ${otherCharacters.join(', ')}.

RELATIONSHIP DYNAMICS:
$relationshipContext

CURRENT CONVERSATION STATE:
- Overall mood: ${conversationMemory.dominantMood}
- Tension level: ${(conversationMemory.overallTension * 100).round()}%
- Active topics: ${conversationMemory.activeTopics.map((t) => t.topic).join(', ')}

TOPIC CONTEXT:
$topicContext

YOUR EMOTIONAL STATE:
$emotionalContext

CONVERSATION FLOW:
$flowContext

NATURAL RESPONSE GUIDELINES:
- Respond as ${character.name} would, considering the relationship dynamics above
- Be aware of the conversation's emotional undertone and respond appropriately
- Reference or build upon previous points when relevant
- Show your unique perspective and expertise areas
- React naturally to agreements, disagreements, or challenges
- Maintain conversational flow - don't be overly formal or robotic
- Let your personality shine through in both content and tone
- Consider the current tension level in your response style

Remember: This is a natural conversation between historical figures. Be authentic to your character while engaging meaningfully with others.
''';

    return basePrompt + enhancedInstruction;
  }

  /// Build legacy system prompt for backward compatibility
  static String _buildGroupSystemPrompt(
    CharacterModel character, 
    List<GroupChatMessage> conversationContext,
  ) {
    final basePrompt = character.systemPrompt;
    
    // Get other character names in the conversation
    final otherCharacters = conversationContext
        .where((m) => !m.isUser && m.characterId != character.id)
        .map((m) => m.characterName)
        .toSet()
        .toList();

    if (otherCharacters.isEmpty) {
      return basePrompt;
    }

    final groupInstruction = '''

IMPORTANT GROUP CONVERSATION CONTEXT:
You are participating in a group conversation with other historical figures: ${otherCharacters.join(', ')}.

Guidelines:
- Respond naturally as ${character.name} would in a group discussion
- You may reference or respond to what others have said
- Keep your responses conversational and engaging
- Maintain your unique personality and perspective
- Don't dominate the conversation - leave room for others to contribute
- You can agree, disagree, or build upon what others have said
''';

    return basePrompt + groupInstruction;
  }

  /// Build relationship context based on personality analysis
  static String _buildRelationshipContext(
    CharacterModel character,
    Map<String, CharacterModel> characterModels,
  ) {
    final relationships = <String>[];
    
    for (final otherEntry in characterModels.entries) {
      if (otherEntry.key == character.id) continue;
      
      final otherCharacter = otherEntry.value;
      final analysis = PersonalityDynamicsAnalyzer.analyzePersonalityCompatibility(
        character, 
        otherCharacter,
      );
      
      final interactionStyle = analysis['interactionStyle'] as String;
      final conflictPotential = analysis['conflictPotential'] as double;
      final agreementPotential = analysis['agreementPotential'] as double;
      
      String relationshipDesc = '';
      if (conflictPotential > 0.6) {
        relationshipDesc = 'likely to clash or debate with';
      } else if (agreementPotential > 0.6) {
        relationshipDesc = 'naturally aligned with';
      } else if (interactionStyle == 'debative') {
        relationshipDesc = 'enjoys intellectual discourse with';
      } else {
        relationshipDesc = 'has neutral dynamics with';
      }
      
      relationships.add('- ${otherCharacter.name}: You are $relationshipDesc them');
    }
    
    return relationships.join('\n');
  }

  /// Build topic context from conversation memory
  static String _buildTopicContext(ConversationMemory memory) {
    if (memory.activeTopics.isEmpty) {
      return 'No specific topics are currently being discussed in depth.';
    }
    
    final topicDescriptions = memory.activeTopics.map((topic) {
      final intensityDesc = topic.intensity > 0.7 ? 'intensely' : 
                           topic.intensity > 0.4 ? 'moderately' : 'lightly';
      return '- ${topic.topic}: Being discussed $intensityDesc (${topic.sentiment} sentiment)';
    }).toList();
    
    return topicDescriptions.join('\n');
  }

  /// Build emotional context for specific character
  static String _buildEmotionalContext(String characterId, ConversationMemory memory) {
    final characterState = memory.characterStates[characterId];
    if (characterState == null) {
      return 'Your emotional state is neutral - engage naturally with the conversation.';
    }
    
    final moodDesc = {
      'agitated': 'You are feeling agitated or provoked by recent comments',
      'challenging': 'You are in a challenging mood, ready to question or debate',
      'supportive': 'You are feeling supportive and agreeable',
      'engaged': 'You are intellectually engaged and curious',
      'thoughtful': 'You are in a contemplative, thoughtful state',
    }[characterState.mood] ?? 'You are feeling neutral';
    
    final intensityDesc = characterState.intensity > 0.7 ? 'strongly' :
                         characterState.intensity > 0.4 ? 'moderately' : 'mildly';
    
    String positionsDesc = '';
    if (characterState.positionsOnTopics.isNotEmpty) {
      final positions = characterState.positionsOnTopics.entries
          .map((e) => '${e.key} (${e.value})')
          .join(', ');
      positionsDesc = '\nYour positions: $positions';
    }
    
    return '$moodDesc ($intensityDesc).$positionsDesc';
  }

  /// Build conversation flow context
  static String _buildConversationFlowContext(ConversationMemory memory) {
    if (memory.conversationFlow.isEmpty) {
      return 'The conversation is just beginning - set a natural tone.';
    }
    
    final flowPatterns = memory.conversationFlow.map((pattern) {
      switch (pattern) {
        case 'debate_emerged':
          return 'A debate has emerged in the conversation';
        case 'agreement_cascade':
          return 'There has been a series of agreements';
        case 'topic_development':
          return 'Topics are being developed thoughtfully';
        default:
          return pattern;
      }
    }).join(', ');
    
    return 'Recent conversation patterns: $flowPatterns';
  }

  /// Build enhanced conversation context with emotional and relational awareness
  static List<Map<String, dynamic>> _buildEnhancedConversationContext(
    List<GroupChatMessage> messages,
    CharacterModel character,
    ConversationMemory conversationMemory,
  ) {
    final contextMessages = <Map<String, dynamic>>[];
    
    // Take more recent messages for better context
    final recentMessages = messages.reversed.take(20).toList().reversed.toList();
    
    for (final msg in recentMessages) {
      if (msg.isUser) {
        contextMessages.add({
          'role': 'user',
          'content': msg.content,
          'timestamp': msg.timestamp.toIso8601String(),
        });
      } else {
        // Enhanced context for AI messages
        final role = msg.characterId == character.id ? 'assistant' : 'user';
        String content;
        
        if (msg.characterId == character.id) {
          // Own previous message
          content = msg.content;
        } else {
          // Other character's message with enhanced context
          final characterState = conversationMemory.characterStates[msg.characterId];
          String emotionalContext = '';
          
          if (characterState != null && characterState.mood != 'neutral') {
            emotionalContext = ' [${characterState.mood}]';
          }
          
          content = '${msg.characterName}$emotionalContext: ${msg.content}';
        }
        
        contextMessages.add({
          'role': role,
          'content': content,
          'timestamp': msg.timestamp.toIso8601String(),
          'characterId': msg.characterId,
          'characterName': msg.characterName,
        });
      }
    }
    
    return contextMessages;
  }

  /// Build legacy conversation context for backward compatibility
  static List<Map<String, dynamic>> _buildConversationContext(
    List<GroupChatMessage> messages,
    CharacterModel character,
  ) {
    return messages.map((msg) {
      if (msg.isUser) {
        return {
          'role': 'user',
          'content': msg.content,
          'timestamp': msg.timestamp.toIso8601String(),
        };
      } else {
        // For AI messages, include who said it for context
        final role = msg.characterId == character.id ? 'assistant' : 'user';
        final content = msg.characterId == character.id 
            ? msg.content
            : '${msg.characterName}: ${msg.content}';
        
        return {
          'role': role,
          'content': content,
          'timestamp': msg.timestamp.toIso8601String(),
        };
      }
    }).toList();
  }

  /// Create error message for a character
  static Future<GroupChatMessage?> _createErrorMessage(
    String characterId, 
    String errorText,
  ) async {
    final character = await _getCharacterById(characterId);
    if (character == null) return null;

    final displayInfo = await getCharacterDisplayInfo(characterId);

    return GroupChatMessage.character(
      content: errorText,
      characterId: characterId,
      characterName: character.name,
      characterAvatarUrl: character.imageUrl,
      characterAvatarText: displayInfo?['avatarText'],
      status: MessageStatus.error,
      metadata: {'isError': true},
    );
  }

  /// Clear character cache
  static void clearCharacterCache() {
    _characterCache.clear();
  }

  /// Clear group conversation state
  static void clearGroupState(String groupId) {
    _activeGroups.remove(groupId);
    _lastRespondingCharacter.remove(groupId);
    _charactersInConversation.remove(groupId);
  }

  /// Get active group
  static GroupChatModel? getActiveGroup(String groupId) {
    return _activeGroups[groupId];
  }

  /// Update active group
  static void updateActiveGroup(String groupId, GroupChatModel groupChat) {
    _activeGroups[groupId] = groupChat;
  }

  /// Check if service is ready
  static bool get isReady => _isInitialized && HybridChatService.serviceAvailability.canSendMessages;

  /// Analyze conversation flow for a group
  static Map<String, dynamic> analyzeConversationFlow(String groupId) {
    final groupChat = _activeGroups[groupId];
    if (groupChat == null) {
      return {'error': 'Group not found'};
    }

    // Build character models map
    final characterModels = <String, CharacterModel>{};
    for (final entry in _characterCache.entries) {
      if (groupChat.characterIds.contains(entry.key)) {
        characterModels[entry.key] = entry.value;
      }
    }

    return CharacterResponseCoordinator.analyzeConversationFlow(
      groupChat,
      characterModels,
    );
  }

  /// Get diagnostic information
  static Map<String, dynamic> getDiagnostics() {
    return {
      'isInitialized': _isInitialized,
      'isReady': isReady,
      'cachedCharacters': _characterCache.length,
      'activeGroups': _activeGroups.length,
      'hasCharactersProvider': _charactersProvider != null,
      'hybridChatServiceReady': HybridChatService.serviceAvailability.canSendMessages,
    };
  }

  /// Log diagnostic information
  static void logDiagnostics() {
    if (kDebugMode) {
      print('=== GroupChatService Diagnostics ===');
      final diagnostics = getDiagnostics();
      diagnostics.forEach((key, value) {
        print('$key: $value');
      });
      print('=====================================');
    }
  }
}