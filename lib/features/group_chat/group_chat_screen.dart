import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/utils/ukrainian_font_utils.dart';
import '../../core/widgets/animated_particles.dart';
import '../../l10n/app_localizations.dart';
import 'models/group_chat_model.dart';
import 'models/group_chat_message.dart';
import '../providers/group_chat_provider.dart';
import 'widgets/group_chat_message_bubble.dart';
import 'character_selection_screen.dart';
import '../providers/characters_provider.dart';
import '../../features/chat/models/message_status.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;

  const GroupChatScreen({
    Key? key,
    required this.groupId,
  }) : super(key: key);

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  
  // Controllers and focus nodes
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // State
  GroupChatModel? _groupChat;
  bool _isLoading = false;
  bool _isFirstLoad = true;
  StreamSubscription<List<GroupChatMessage>>? _messageSubscription;
  
  // Cached widgets for performance
  late final Widget _particleBackground = const Opacity(
    opacity: 0.3,
    child: AnimatedParticles(
      particleCount: 15,
      particleColor: AppTheme.warmGold,
      minSpeed: 0.01,
      maxSpeed: 0.03,
    ),
  );

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadGroupChat();
    _setupMessageStream();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));

    if (_isFirstLoad) {
      _fadeController.forward();
      _slideController.forward();
    }
  }

  void _setupMessageStream() {
    final provider = Provider.of<GroupChatProvider>(context, listen: false);
    _messageSubscription = provider.messageStream?.listen((messages) {
      if (mounted) {
        setState(() {
          // Update will come through provider
        });
        _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _messageSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadGroupChat() async {
    final provider = Provider.of<GroupChatProvider>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });

    try {
      _groupChat = provider.getGroupChatById(widget.groupId);
      
      if (_groupChat != null) {
        // Select this group
        await provider.selectGroupChat(widget.groupId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading group chat: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isFirstLoad = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    final provider = Provider.of<GroupChatProvider>(context, listen: false);
    final localizations = AppLocalizations.of(context);

    // Clear input
    _messageController.clear();
    _inputFocusNode.unfocus();

    try {
      await provider.sendMessageToGroup(widget.groupId, message);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.errorConnecting),
            backgroundColor: AppTheme.errorColor,
            action: SnackBarAction(
              label: localizations.retry,
              textColor: AppTheme.warmGold,
              onPressed: () {
                _messageController.text = message;
                _sendMessage();
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
        child: Stack(
          children: [
            // Background particles
            RepaintBoundary(child: _particleBackground),
            
            // Main content
            SafeArea(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusScope.of(context).unfocus(),
                child: Column(
                children: [
                  _buildAppBar(),
                  Expanded(child: _buildChatContent()),
                  _buildInputArea(),
                ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final fontScale = ResponsiveUtils.getFontSizeScale(context);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getScreenPadding(context).left,
        vertical: 10 * fontScale,
      ).copyWith(
        right: ResponsiveUtils.getScreenPadding(context).right,
      ),
      child: Row(
        children: [
          // Back button
          Container(
            decoration: BoxDecoration(
              color: AppTheme.midnightPurple.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.warmGold.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: AppTheme.warmGold,
                size: 20 * fontScale,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Group info
          Expanded(
            child: Consumer<GroupChatProvider>(
              builder: (context, provider, child) {
                final group = provider.getGroupChatById(widget.groupId);
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group?.name ?? 'Group Chat',
                      style: UkrainianFontUtils.cinzelWithUkrainianSupport(
                        text: group?.name ?? 'Group Chat',
                        fontSize: 18 * fontScale,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.warmGold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${group?.characterCount ?? 0} members • ${group?.messageCount ?? 0} messages',
                      style: UkrainianFontUtils.latoWithUkrainianSupport(
                        text: '${group?.characterCount ?? 0} members • ${group?.messageCount ?? 0} messages',
                        fontSize: 12 * fontScale,
                        color: AppTheme.silverMist.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          
          // Menu button
          Container(
            decoration: BoxDecoration(
              color: AppTheme.midnightPurple.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.warmGold.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: _showGroupMenu,
              icon: Icon(
                Icons.more_vert,
                color: AppTheme.warmGold,
                size: 20 * fontScale,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatContent() {
    if (_isLoading && _isFirstLoad) {
      return _buildLoadingState();
    }

    return Consumer<GroupChatProvider>(
      builder: (context, provider, child) {
        final group = provider.getGroupChatById(widget.groupId);
        
        if (group == null) {
          return _buildErrorState();
        }

        if (group.messages.isEmpty) {
          return _buildEmptyState(group);
        }

        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: _buildMessageList(group, provider),
          ),
        );
      },
    );
  }

  Widget _buildMessageList(GroupChatModel group, GroupChatProvider provider) {
    return Column(
      children: [
        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.only(
              top: 16,
              bottom: 16,
              left: ResponsiveUtils.getChatListPadding(context).left,
              right: ResponsiveUtils.getChatListPadding(context).right,
            ),
            itemCount: group.messages.length,
            itemBuilder: (context, index) {
              final message = group.messages[index];
              final previousMessage = index > 0 ? group.messages[index - 1] : null;
              final showAvatar = _shouldShowAvatar(message, previousMessage);
              final showCharacterName = _shouldShowCharacterName(message, previousMessage);
              
              return GroupChatMessageBubble(
                message: message,
                showAvatar: showAvatar,
                showCharacterName: showCharacterName,
                onRetry: message.status == MessageStatus.error 
                    ? () => _retryMessage(message) 
                    : null,
                onTap: () => _onMessageTap(message),
                onLongPress: () => _onMessageLongPress(message),
              );
            },
          ),
        ),
        
        // Typing indicator
        SizedBox(height: 4 * ResponsiveUtils.getFontSizeScale(context)),
        Consumer<GroupChatProvider>(
          builder: (context, provider, child) {
            if (provider.isTyping) {
              return GroupChatTypingIndicator(
                typingCharacterNames: provider.typingCharacterIds
                    .map((id) => _getCharacterName(id))
                    .toSet(),
                fontScale: ResponsiveUtils.getFontSizeScale(context),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildInputArea() {
    final fontScale = ResponsiveUtils.getFontSizeScale(context);
    final localizations = AppLocalizations.of(context);
    
    return Container(
      padding: ResponsiveUtils.getChatInputPadding(context),
      decoration: BoxDecoration(
        color: AppTheme.deepNavy.withValues(alpha: 0.8),
        border: Border(
          top: BorderSide(
            color: AppTheme.warmGold.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Message input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.midnightPurple.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.warmGold.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _inputFocusNode,
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: localizations.sendMessage,
                  hintStyle: UkrainianFontUtils.latoWithUkrainianSupport(
                    text: localizations.sendMessage,
                    fontSize: 14 * fontScale,
                    color: AppTheme.silverMist.withValues(alpha: 0.5),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16 * fontScale,
                    vertical: 12 * fontScale,
                  ),
                ),
                style: UkrainianFontUtils.latoWithUkrainianSupport(
                  text: _messageController.text,
                  fontSize: 14 * fontScale,
                  color: AppTheme.silverMist,
                ),
              ),
            ),
          ),
          
          SizedBox(width: 12 * fontScale),
          
          // Send button
          Consumer<GroupChatProvider>(
            builder: (context, provider, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.warmGold,
                      AppTheme.warmGold.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.warmGold.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: _messageController.text.trim().isNotEmpty && !provider.isLoading
                      ? _sendMessage
                      : null,
                  icon: provider.isLoading
                      ? SizedBox(
                          width: 20 * fontScale,
                          height: 20 * fontScale,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.deepNavy,
                          ),
                        )
                      : Icon(
                          Icons.send,
                          color: AppTheme.deepNavy,
                          size: 20 * fontScale,
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppTheme.warmGold,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading group chat...',
            style: UkrainianFontUtils.latoWithUkrainianSupport(
              text: 'Loading group chat...',
              fontSize: 16,
              color: AppTheme.silverMist.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final localizations = AppLocalizations.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.errorColor.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'Group chat not found',
            style: UkrainianFontUtils.latoWithUkrainianSupport(
              text: 'Group chat not found',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.errorColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This group chat may have been deleted.',
            style: UkrainianFontUtils.latoWithUkrainianSupport(
              text: 'This group chat may have been deleted.',
              fontSize: 14,
              color: AppTheme.silverMist.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warmGold,
              foregroundColor: AppTheme.deepNavy,
            ),
            child: Text(localizations.goBack),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(GroupChatModel group) {
    final fontScale = ResponsiveUtils.getFontSizeScale(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Group avatar
            Container(
              width: 100 * fontScale,
              height: 100 * fontScale,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.warmGold.withValues(alpha: 0.3),
                    AppTheme.warmGold.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.warmGold.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.group,
                size: 48 * fontScale,
                color: AppTheme.warmGold,
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Welcome to ${group.name}!',
              style: UkrainianFontUtils.cinzelWithUkrainianSupport(
                text: 'Welcome to ${group.name}!',
                fontSize: 24 * fontScale,
                fontWeight: FontWeight.bold,
                color: AppTheme.warmGold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'Start a conversation with your selected characters.',
              style: UkrainianFontUtils.latoWithUkrainianSupport(
                text: 'Start a conversation with your selected characters.',
                fontSize: 16 * fontScale,
                color: AppTheme.silverMist.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Conversation starters
            _buildConversationStarters(group, fontScale),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationStarters(GroupChatModel group, double fontScale) {
    final starters = [
      "Hello everyone! Let's start our conversation.",
      "What are your thoughts on the meaning of life?",
      "Tell me about your greatest achievements.",
      "What advice would you give to future generations?",
    ];

    return Column(
      children: starters.map((starter) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          child: ElevatedButton(
            onPressed: () {
              _messageController.text = starter;
              _inputFocusNode.requestFocus();
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.midnightPurple.withValues(alpha: 0.5),
              foregroundColor: AppTheme.silverMist,
              side: BorderSide(
                color: AppTheme.warmGold.withValues(alpha: 0.3),
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
            ),
            child: Text(
              starter,
              style: UkrainianFontUtils.latoWithUkrainianSupport(
                text: starter,
                fontSize: 14 * fontScale,
                color: AppTheme.silverMist,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }).toList(),
    );
  }

  bool _shouldShowAvatar(GroupChatMessage message, GroupChatMessage? previousMessage) {
    if (message.isUser) return false;
    if (previousMessage == null) return true;
    if (previousMessage.isUser) return true;
    if (previousMessage.characterId != message.characterId) return true;
    
    // Show avatar if more than 5 minutes apart
    final timeDifference = message.timestamp.difference(previousMessage.timestamp);
    return timeDifference.inMinutes > 5;
  }

  bool _shouldShowCharacterName(GroupChatMessage message, GroupChatMessage? previousMessage) {
    if (message.isUser) return false;
    return _shouldShowAvatar(message, previousMessage);
  }

  String _getCharacterName(String characterId) {
    if (characterId.startsWith('famous_')) {
      return characterId.substring(7);
    }
    
    final charactersProvider = Provider.of<CharactersProvider>(context, listen: false);
    final character = charactersProvider.characters
        .where((c) => c.id == characterId)
        .firstOrNull;
    
    return character?.name ?? 'Unknown';
  }

  void _retryMessage(GroupChatMessage message) {
    // TODO: Implement retry logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Retry functionality coming soon')),
    );
  }

  void _onMessageTap(GroupChatMessage message) {
    // TODO: Implement message tap handling
  }

  void _onMessageLongPress(GroupChatMessage message) {
    // TODO: Implement message long press menu
  }

  void _showGroupMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.deepNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(child: _buildGroupMenuSheet()),
    );
  }

  Widget _buildGroupMenuSheet() {
    final localizations = AppLocalizations.of(context);
    final fontScale = ResponsiveUtils.getFontSizeScale(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.warmGold.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Menu items
          _buildMenuOption(
            Icons.edit,
            localizations.editGroupChat,
            _editGroup,
            fontScale,
          ),
          _buildMenuOption(
            Icons.delete_outline,
            localizations.deleteGroup,
            _deleteGroup,
            fontScale,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOption(
    IconData icon,
    String title,
    VoidCallback onTap,
    double fontScale, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppTheme.errorColor : AppTheme.warmGold,
        size: 24 * fontScale,
      ),
      title: Text(
        title,
        style: UkrainianFontUtils.latoWithUkrainianSupport(
          text: title,
          fontSize: 16 * fontScale,
          color: isDestructive ? AppTheme.errorColor : AppTheme.silverMist,
        ),
      ),
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
    );
  }

  void _editGroup() {
    final group = _groupChat;
    if (group == null) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CharacterSelectionScreen(
          existingGroup: group,
        ),
      ),
    ).then((result) {
      if (result != null) {
        _loadGroupChat();
      }
    });
  }

  // Note: Add/Remove members were removed from the group menu per UX request.

  void _deleteGroup() {
    final localizations = AppLocalizations.of(context);
    final group = _groupChat;
    if (group == null) return;

    FocusScope.of(context).unfocus();

    showDialog<bool>(
      context: context,
      builder: (context) {
        final fontScale = ResponsiveUtils.getFontSizeScale(context);
        return AlertDialog(
          backgroundColor: AppTheme.deepNavy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: AppTheme.warmGold.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          title: Text(
            localizations.deleteGroup,
            style: UkrainianFontUtils.cinzelWithUkrainianSupport(
              text: localizations.deleteGroup,
              fontSize: 20 * fontScale,
              fontWeight: FontWeight.bold,
              color: AppTheme.warmGold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${group.name}"? This action cannot be undone.',
            style: UkrainianFontUtils.latoWithUkrainianSupport(
              text: 'Are you sure you want to delete "${group.name}"? This action cannot be undone.',
              fontSize: 14 * fontScale,
              color: AppTheme.silverMist,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                localizations.cancel,
                style: UkrainianFontUtils.latoWithUkrainianSupport(
                  text: localizations.cancel,
                  fontSize: 14 * fontScale,
                  color: AppTheme.silverMist,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
              ),
              child: Text(
                localizations.delete,
                style: UkrainianFontUtils.latoWithUkrainianSupport(
                  text: localizations.delete,
                  fontSize: 14 * fontScale,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    ).then((confirmed) async {
      if (confirmed != true) return;
      final provider = Provider.of<GroupChatProvider>(context, listen: false);
      try {
        await provider.deleteGroupChat(group.id);
        if (!mounted) return;
        Navigator.of(context).pop(); // Leave chat screen back to list
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting group: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    });
  }
}