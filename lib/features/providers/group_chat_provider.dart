// removed unused convert import for release cleanliness
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers/base_provider.dart';
import '../../core/services/preferences_service.dart';
import '../group_chat/models/group_chat_model.dart';
import '../chat/models/message_status.dart';
import '../group_chat/models/group_chat_message.dart';
import '../group_chat/persistence/group_chat_storage.dart';
import '../group_chat/group_chat_service.dart';
import 'characters_provider.dart';

/// Provider for managing group chat state and operations
class GroupChatProvider extends BaseProvider {
  static const String _storageKey = 'group_chats';
  static const String _selectedGroupKey = 'selected_group_id';

  List<GroupChatModel> _groupChats = [];
  String? _selectedGroupId;
  CharactersProvider? _charactersProvider;

  // Memory cache for quick lookups
  final Map<String, GroupChatModel> _groupCache = {};
  
  // Current chat state
  bool _isTyping = false;
  Set<String> _typingCharacterIds = {};
  StreamController<List<GroupChatMessage>>? _messageStreamController;
  StreamSubscription<GroupChatMessage>? _activeResponseSubscription;

  // (removed unused) Performance tracking placeholder for future telemetry

  /// Public getters
  List<GroupChatModel> get groupChats => List.unmodifiable(_groupChats);
  String? get selectedGroupId => _selectedGroupId;
  bool get isTyping => _isTyping;
  Set<String> get typingCharacterIds => Set.unmodifiable(_typingCharacterIds);
  bool get hasGroups => _groupChats.isNotEmpty;
  bool get isStreaming => _activeResponseSubscription != null;

  /// Selected group
  GroupChatModel? get selectedGroup {
    if (_selectedGroupId == null) {
      return _groupChats.isNotEmpty ? _groupChats.first : null;
    }

    // Check cache first
    if (_groupCache.containsKey(_selectedGroupId)) {
      return _groupCache[_selectedGroupId];
    }

    // Look in main list
    try {
      final group = _groupChats.firstWhere((g) => g.id == _selectedGroupId);
      _groupCache[_selectedGroupId!] = group;
      return group;
    } catch (_) {
      return _groupChats.isNotEmpty ? _groupChats.first : null;
    }
  }

  /// Message stream for real-time updates
  Stream<List<GroupChatMessage>>? get messageStream => 
      _messageStreamController?.stream;

  GroupChatProvider() {
    _initialize();
  }

  /// Set the characters provider for character lookups
  void setCharactersProvider(CharactersProvider provider) {
    _charactersProvider = provider;
    GroupChatService.setCharactersProvider(provider);
  }

  /// Initialize the provider
  Future<void> _initialize() async {
    await executeWithState(
      operation: () async {
        // Initialize the service
        await GroupChatService.initialize();
        
        // Load existing group chats
        await _loadGroupChats();
        
        // Load selected group
        await _loadSelectedGroup();
        
        // Initialize message stream
        _messageStreamController = StreamController<List<GroupChatMessage>>.broadcast();
        
        logStateChange('Provider initialized', context: {
          'groupCount': _groupChats.length,
          'selectedGroupId': _selectedGroupId,
        });
      },
      operationName: 'initialize group chat provider',
    );
  }

  /// Get shared preferences instance
  Future<SharedPreferences> _getPrefs() async {
    return await PreferencesService.getPrefs();
  }

  /// Load group chats from storage
  Future<void> _loadGroupChats() async {
    await executeWithState(
      operation: () async {
        // Debug logs removed for release cleanliness
        try {
          // Use the comprehensive storage class with logging
          _groupChats = await GroupChatStorage.loadGroupChats();
          
          
          // Update cache
          _groupCache.clear();
          for (var group in _groupChats) {
            _groupCache[group.id] = group;
          }
          

          _sortGroupChats();
          _updateSelectedGroup();
          
        } catch (e) {
          
          setError('Error loading group chats: $e', error: e);
          _groupChats = [];
        }
      },
      operationName: 'load group chats',
    );
  }

  /// Parse group chat JSON in isolate for performance
  // Removed unused isolate parser in release build

  /// Sort group chats by last message time
  void _sortGroupChats() {
    _groupChats.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
  }

  /// Update selected group logic
  void _updateSelectedGroup() {
    if (_groupChats.isNotEmpty && _selectedGroupId == null) {
      _selectedGroupId = _groupChats.first.id;
    } else if (_groupChats.isEmpty) {
      _selectedGroupId = null;
    }
  }

  /// Load selected group from preferences
  Future<void> _loadSelectedGroup() async {
    try {
      final prefs = await _getPrefs();
      _selectedGroupId = prefs.getString(_selectedGroupKey);
    } catch (e) {
      
    }
  }

  /// Save group chats to storage
  Future<void> _saveGroupChats() async {
    try {
      // Use the comprehensive storage class with logging
      await GroupChatStorage.saveGroupChats(_groupChats);
      
      clearError();
    } catch (e) {
      
      setError('Error saving group chats: $e', error: e);
      rethrow;
    }
  }

  /// Encode group chat JSON in isolate
  // Removed unused isolate encoder in release build

  /// Save selected group to preferences
  Future<void> _saveSelectedGroup() async {
    try {
      final prefs = await _getPrefs();
      if (_selectedGroupId != null) {
        await prefs.setString(_selectedGroupKey, _selectedGroupId!);
      } else {
        await prefs.remove(_selectedGroupKey);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving selected group: $e');
      }
    }
  }

  /// Create a new group chat
  Future<GroupChatModel?> createGroupChat({
    required String name,
    required List<String> characterIds,
    String? description,
  }) async {
    
    
    return await executeWithState(
      operation: () async {
        
        
        try {
          
          final groupChat = GroupChatModel(
            name: name,
            characterIds: characterIds,
            description: description,
            settings: {
              'groupModel': 'local/gemma-3-1b-it',
              'maxResponseChars': 600,
              'maxInputChars': 400,
            },
          );
          
          

          
          _groupChats.insert(0, groupChat); // Add to top
          _groupCache[groupChat.id] = groupChat;
          
          
          
          await _saveGroupChats();
          
          
          // Select the new group
          
          _selectedGroupId = groupChat.id;
          await _saveSelectedGroup();
          
          
          logUserAction('created group chat', context: {
            'groupId': groupChat.id,
            'characterCount': characterIds.length,
          });
          

          
          return groupChat;
        } catch (e) {
          rethrow;
        }
      },
      operationName: 'create group chat',
    );
  }

  /// Update group's AI model/provider selection
  Future<void> setGroupModel(String groupId, String modelId) async {
    final group = getGroupChatById(groupId);
    if (group == null) return;
    final newSettings = Map<String, dynamic>.from(group.settings ?? {});
    newSettings['groupModel'] = modelId;
    final updated = GroupChatModel(
      id: group.id,
      name: group.name,
      characterIds: group.characterIds,
      messages: group.messages,
      createdAt: group.createdAt,
      lastMessageAt: group.lastMessageAt,
      description: group.description,
      settings: newSettings,
      metadata: group.metadata,
    );
    await updateGroupChat(updated);
  }

  /// Update group's limits (chars)
  Future<void> setGroupLimits(String groupId, {int? maxInputChars, int? maxResponseChars}) async {
    final group = getGroupChatById(groupId);
    if (group == null) return;
    final newSettings = Map<String, dynamic>.from(group.settings ?? {});
    if (maxInputChars != null) newSettings['maxInputChars'] = maxInputChars;
    if (maxResponseChars != null) newSettings['maxResponseChars'] = maxResponseChars;
    final updated = GroupChatModel(
      id: group.id,
      name: group.name,
      characterIds: group.characterIds,
      messages: group.messages,
      createdAt: group.createdAt,
      lastMessageAt: group.lastMessageAt,
      description: group.description,
      settings: newSettings,
      metadata: group.metadata,
    );
    await updateGroupChat(updated);
  }

  /// Update an existing group chat
  Future<void> updateGroupChat(GroupChatModel updatedGroup) async {
    await executeWithState(
      operation: () async {
        final index = _groupChats.indexWhere((g) => g.id == updatedGroup.id);
        
        if (index >= 0) {
          _groupChats[index] = updatedGroup;
          _groupCache[updatedGroup.id] = updatedGroup;
          
          await _saveGroupChats();
          
          logUserAction('updated group chat', context: {
            'groupId': updatedGroup.id,
          });
        } else {
          throw Exception('Group chat not found');
        }
      },
      operationName: 'update group chat',
    );
  }

  /// Delete a group chat
  Future<void> deleteGroupChat(String groupId) async {
    await executeWithState(
      operation: () async {
        _groupChats.removeWhere((g) => g.id == groupId);
        _groupCache.remove(groupId);
        
        // Clear service state
        GroupChatService.clearGroupState(groupId);
        
        // Update selected group if deleted
        if (_selectedGroupId == groupId) {
          _selectedGroupId = _groupChats.isNotEmpty ? _groupChats.first.id : null;
          await _saveSelectedGroup();
        }
        
        await _saveGroupChats();
        
        logUserAction('deleted group chat', context: {
          'groupId': groupId,
        });
      },
      operationName: 'delete group chat',
    );
  }

  /// Select a group chat
  Future<void> selectGroupChat(String groupId) async {
    if (_selectedGroupId == groupId) return;

    try {
      _selectedGroupId = groupId;
      await _saveSelectedGroup();
      
      // Update message stream with new group's messages
      final selectedGroup = this.selectedGroup;
      if (selectedGroup != null) {
        _messageStreamController?.add(selectedGroup.messages);
      }
      
      notifyListeners();
      
      logUserAction('selected group chat', context: {
        'groupId': groupId,
      });
    } catch (e) {
      setError('Error selecting group chat: $e', error: e);
    }
  }

  /// Send a message to the selected group
  Future<void> sendMessage(String message) async {
    final group = selectedGroup;
    if (group == null) {
      setError('No group selected');
      return;
    }

    await sendMessageToGroup(group.id, message);
  }

  /// Send a message to a specific group
  Future<void> sendMessageToGroup(String groupId, String message) async {
    // Get the most recent group state from service first, then fall back to cache/list
    var group = GroupChatService.getActiveGroup(groupId) ??
                _groupCache[groupId] ??
                (_groupChats.where((g) => g.id == groupId).isNotEmpty
                    ? _groupChats.firstWhere((g) => g.id == groupId)
                    : null);

    if (group == null) {
      setError('Group not found');
      return;
    }

    try {
      // Enforce input length limit if configured
      final maxInput = (group.settings?['maxInputChars'] is int)
          ? group.settings!['maxInputChars'] as int
          : null;
      var trimmedMessage = message;
      if (maxInput != null && message.length > maxInput) {
        trimmedMessage = message.substring(0, maxInput);
      }
      // 1) Optimistic UI: show user message instantly
      final userMsg = GroupChatMessage.user(
        content: trimmedMessage,
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
      );

      var localUpdatedGroup = group.addMessage(userMsg);

      // Update local collections and stream immediately
      final existingIndex = _groupChats.indexWhere((g) => g.id == groupId);
      if (existingIndex >= 0) {
        _groupChats[existingIndex] = localUpdatedGroup;
      }
      _groupCache[groupId] = localUpdatedGroup;
      _messageStreamController?.add(localUpdatedGroup.messages);
      notifyListeners();

      // Set typing state for characters
      _setTypingState(true);

      // Cancel any existing stream before starting a new one
      await _activeResponseSubscription?.cancel();
      _activeResponseSubscription = null;

      // 2) Use streaming API so responses arrive one-by-one
      final responseStream = await GroupChatService.sendMessageToGroupStream(
        groupId: groupId,
        userMessage: trimmedMessage,
        groupChat: group,
      );
      _activeResponseSubscription = responseStream.listen((streamedMessage) async {
        // Skip duplicate user message from service stream (we already added it)
        if (streamedMessage.isUser) {
          return;
        }

        // Update typing indicators based on thinking messages
        if (streamedMessage.status == MessageStatus.characterTyping) {
          _typingCharacterIds = {
            ..._typingCharacterIds,
            streamedMessage.characterId,
          };
          notifyListeners();
        }

        // Pull the latest group from service which is the source of truth
        final latest = GroupChatService.getActiveGroup(groupId);
        if (latest != null) {
          if (existingIndex >= 0) {
            _groupChats[existingIndex] = latest;
          }
          _groupCache[groupId] = latest;
          _messageStreamController?.add(latest.messages);
          _sortGroupChats();
          notifyListeners();
        }

        // Clear typing flag for this character when a real message arrives
        if (streamedMessage.status != MessageStatus.characterTyping &&
            _typingCharacterIds.contains(streamedMessage.characterId)) {
          _typingCharacterIds.remove(streamedMessage.characterId);
          notifyListeners();
        }
      }, onError: (e) {
        setError('Error sending message: $e', error: e);
      }, onDone: () async {
        // Persist groups after streaming completes
        await _saveGroupChats();
        _setTypingState(false);
        _typingCharacterIds.clear();
        _activeResponseSubscription = null;
        notifyListeners();
        logUserAction('sent message to group (streamed)', context: {
          'groupId': groupId,
          'messageLength': trimmedMessage.length,
        });
      }, cancelOnError: true);
    } catch (e) {
      setError('Error sending message: $e', error: e);
    } finally {
      // Keep typing state controlled by stream lifecycle/cancel
    }
  }

  /// Cancel active streaming responses, if any
  Future<void> cancelStreamingResponses() async {
    try {
      await _activeResponseSubscription?.cancel();
    } catch (_) {}
    _activeResponseSubscription = null;
    // Invalidate current run so pending async emissions are ignored
    GroupChatService.cancelGroupRun(_selectedGroupId ?? selectedGroup?.id ?? '');
    _setTypingState(false);
    if (_typingCharacterIds.isNotEmpty) {
      _typingCharacterIds.clear();
    }
    notifyListeners();
  }

  /// Set typing indicators
  void _setTypingState(bool typing, [Set<String>? characterIds]) {
    _isTyping = typing;
    _typingCharacterIds = characterIds ?? {};
    notifyListeners();
  }

  /// Update message status
  Future<void> updateMessageStatus(String groupId, String messageId, MessageStatus status) async {
    try {
      final group = _groupCache[groupId] ?? _groupChats.firstWhere((g) => g.id == groupId);
      final updatedGroup = group.updateMessageStatus(messageId, status);

      final index = _groupChats.indexWhere((g) => g.id == groupId);
      if (index >= 0) {
        _groupChats[index] = updatedGroup;
        _groupCache[groupId] = updatedGroup;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating message status: $e');
      }
    }
  }

  /// Clear all group chats
  Future<void> clearAllGroupChats() async {
    await executeWithState(
      operation: () async {
        _groupChats.clear();
        _groupCache.clear();
        _selectedGroupId = null;
        
        final prefs = await _getPrefs();
        await prefs.remove(_storageKey);
        await prefs.remove(_selectedGroupKey);
        
        logUserAction('cleared all group chats');
      },
      operationName: 'clear all group chats',
    );
  }

  /// Get group chat by ID
  GroupChatModel? getGroupChatById(String groupId) {
    return _groupCache[groupId] ?? 
           _groupChats.cast<GroupChatModel?>().firstWhere(
             (g) => g?.id == groupId, 
             orElse: () => null,
           );
  }

  /// Get conversation flow analysis
  Map<String, dynamic> getConversationFlow(String groupId) {
    try {
      return GroupChatService.analyzeConversationFlow(groupId);
    } catch (e) {
      return {'error': 'Analysis failed: $e'};
    }
  }

  /// Get performance diagnostics
  Map<String, dynamic> getDiagnostics() {
    return {
      'groupCount': _groupChats.length,
      'selectedGroupId': _selectedGroupId,
      'cacheSize': _groupCache.length,
      'isLoading': isLoading,
      'hasError': hasError,
      'lastError': lastError,
      'serviceReady': GroupChatService.isReady,
      'hasCharactersProvider': _charactersProvider != null,
    };
  }

  /// Load group chats from storage
  Future<void> loadGroupChats() async {
    if (isLoading) return;
    
    setLoading(true);
    try {
      _groupChats = await GroupChatStorage.loadGroupChats();
      _updateCache();
      
      logUserAction('loaded group chats', context: {
        'count': _groupChats.length,
      });
    } catch (e) {
      setError('Error loading group chats: $e', error: e);
    } finally {
      setLoading(false);
    }
  }

  /// Update the local cache with current groups
  void _updateCache() {
    _groupCache.clear();
    for (final group in _groupChats) {
      _groupCache[group.id] = group;
    }
  }

  @override
  void dispose() {
    _activeResponseSubscription?.cancel();
    _messageStreamController?.close();
    super.dispose();
  }
}