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

  /// Send a user message to a group and coordinate AI responses
  static Future<List<GroupChatMessage>> sendMessageToGroup({
    required String groupId,
    required String userMessage,
    required GroupChatModel groupChat,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final responses = <GroupChatMessage>[];

    try {
      // Add user message
      final userMsg = GroupChatMessage.user(
        content: userMessage,
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
      );
      responses.add(userMsg);

      // Update active group
      _activeGroups[groupId] = groupChat.addMessage(userMsg);
      _charactersInConversation[groupId] = groupChat.characterIds.toSet();

      // Determine which character(s) should respond
      final respondingCharacterIds = await _determineRespondingCharacters(
        groupId: groupId,
        groupChat: _activeGroups[groupId]!,
        userMessage: userMessage,
      );

      if (kDebugMode) {
        print('GroupChatService: $groupId - Characters responding: $respondingCharacterIds');
      }

      // Get responses from selected characters
      for (final characterId in respondingCharacterIds) {
        try {
          final characterResponse = await _getCharacterResponse(
            groupId: groupId,
            characterId: characterId,
            userMessage: userMessage,
            conversationContext: _activeGroups[groupId]!.messages,
          );

          if (characterResponse != null) {
            responses.add(characterResponse);
            
            // Update group with character response
            _activeGroups[groupId] = _activeGroups[groupId]!.addMessage(characterResponse);
            _lastRespondingCharacter[groupId] = characterId;

            // Add delay between character responses for natural flow
            if (respondingCharacterIds.length > 1 && 
                characterId != respondingCharacterIds.last) {
              await Future.delayed(Duration(
                milliseconds: 500 + Random().nextInt(1000),
              ));
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error getting response from character $characterId: $e');
          }
          
          // Add error message
          final errorMsg = await _createErrorMessage(characterId, 
              'I apologize, but I encountered an issue. Please try again.');
          if (errorMsg != null) {
            responses.add(errorMsg);
          }
        }
      }

      return responses;
    } catch (e) {
      AppLogger.error('Failed to send message to group $groupId: $e', tag: 'GroupChatService');
      
      // Return at least the user message
      if (responses.isEmpty) {
        responses.add(GroupChatMessage.user(
          content: userMessage,
          status: MessageStatus.error,
        ));
      }
      
      return responses;
    }
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

  /// Get AI response from a specific character
  static Future<GroupChatMessage?> _getCharacterResponse({
    required String groupId,
    required String characterId,
    required String userMessage,
    required List<GroupChatMessage> conversationContext,
  }) async {
    final character = await _getCharacterById(characterId);
    if (character == null) {
      if (kDebugMode) {
        print('Character not found: $characterId');
      }
      return null;
    }

    try {
      // Build conversation context for this character
      final contextMessages = _buildConversationContext(
        conversationContext, 
        character,
      );

      // Get AI response using HybridChatService
      final aiResponse = await HybridChatService.sendMessageToCharacter(
        characterId: characterId,
        message: userMessage,
        systemPrompt: _buildGroupSystemPrompt(character, conversationContext),
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
            'responseType': 'ai_generated',
          },
        );
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error generating response for character ${character.name}: $e');
      }
      return null;
    }
  }

  /// Build system prompt for group context
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

  /// Build conversation context for AI model
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