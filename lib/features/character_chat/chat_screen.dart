import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/animated_particles.dart';
import '../models/character_model.dart';
import '../providers/characters_provider.dart';
import '../providers/language_provider.dart';
import '../character_profile/character_profile_screen.dart';
import 'chat_service.dart';
import '../chat/models/chat_message.dart';
import '../chat/widgets/chat_message_bubble.dart';
import '../../l10n/app_localizations.dart';
import '../../core/utils/ukrainian_font_utils.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/services/hybrid_chat_service.dart';

class CharacterChatScreen extends StatefulWidget {
  final String characterId;

  const CharacterChatScreen({Key? key, required this.characterId})
    : super(key: key);

  @override
  State<CharacterChatScreen> createState() => _CharacterChatScreenState();
}

class _CharacterChatScreenState extends State<CharacterChatScreen>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  CharacterModel? _character;
  bool _isLoading = false;

  // Cached widgets and values for performance
  late final Widget _particleBackground = const Opacity(
    opacity: 0.5,
    child: AnimatedParticles(
      particleCount: 20, // Reduced for better performance
      particleColor: Colors.white,
      minSpeed: 0.01,
      maxSpeed: 0.03,
    ),
  );

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadCharacter();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadCharacter() async {
    final charactersProvider = Provider.of<CharactersProvider>(
      context,
      listen: false,
    );

    try {
      final character = await charactersProvider.loadCharacterById(
        widget.characterId,
      );

      if (mounted) {
        setState(() {
          _character = character;
        });
        
        // Select this character so it becomes the active one
        if (character != null) {
          charactersProvider.selectCharacter(character.id);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading character: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    final charactersProvider = Provider.of<CharactersProvider>(
      context,
      listen: false,
    );
    final localizations = AppLocalizations.of(context);

    // Clear the input field
    _messageController.clear();

    // Add user message to chat history
    await charactersProvider.addMessageToCharacter(
      characterId: widget.characterId,
      text: message,
      isUser: true,
    );

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
      
      // Reload the character to get updated chat history
      await _loadCharacter();
    }

    // Scroll to the bottom after state update
    _scrollToBottom();

    try {
      // Send the message to the character
      final response = await HybridChatService.sendMessageToCharacter(
        characterId: widget.characterId,
        message: message,
        systemPrompt: _character!.systemPrompt,
        chatHistory: _character!.chatHistory,
        model: _character!.model,
      );

      // Add AI response to chat history if not null
      if (response != null) {
        await charactersProvider.addMessageToCharacter(
          characterId: widget.characterId,
          text: response,
          isUser: false,
        );
      } else {
        // Handle null response by showing a fallback message
        await charactersProvider.addMessageToCharacter(
          characterId: widget.characterId,
          text: localizations.errorProcessingMessage,
          isUser: false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }

      // Add error message to chat history
      await charactersProvider.addMessageToCharacter(
        characterId: widget.characterId,
        text: localizations.errorConnecting,
        isUser: false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        await _loadCharacter();
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final localizations = AppLocalizations.of(context);

    if (_character == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(localizations.chat),
          backgroundColor: AppTheme.backgroundStart,
        ),
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(localizations),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
        child: Stack(
          children: [
            // Background particles with reduced opacity
            _particleBackground,

            Column(
              children: [
                // Chat messages
                Expanded(child: _buildChatList(localizations)),

                // Input area
                _buildInputArea(localizations),
              ],
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations localizations) {
    return AppBar(
      backgroundColor: AppTheme.backgroundStart,
      elevation: 0,
      title: Row(
        children: [
          // Character avatar
          CircleAvatar(
            backgroundColor: AppTheme.midnightPurple,
            child: Text(
              _character!.name[0].toUpperCase(),
              style: TextStyle(
                color: AppTheme.warmGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Character name
          Expanded(
            child: Text(
              _character!.name,
              style: UkrainianFontUtils.cinzelWithUkrainianSupport(
                text: _character!.name,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        // View profile button
        IconButton(
          icon: const Icon(Icons.person_outline),
          tooltip: localizations.viewProfile,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CharacterProfileScreen(
                  characterId: _character!.id,
                ),
              ),
            );
          },
        ),
        // Clear chat history button
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: localizations.clearChatHistory,
          onPressed: () => _showClearChatDialog(localizations),
        ),
      ],
    );
  }

  Widget _buildChatList(AppLocalizations localizations) {
    if (_character!.chatHistory.isEmpty) {
      final fontScale = ResponsiveUtils.getFontSizeScale(context);
      
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 64 * fontScale,
                color: Colors.white54,
              ),
              const SizedBox(height: 16),
              Text(
                localizations.startConversation,
                style: UkrainianFontUtils.latoWithUkrainianSupport(
                  text: localizations.startConversation,
                  fontSize: 18 * fontScale,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: ResponsiveUtils.getChatListPadding(context),
      itemCount: _character!.chatHistory.length,
      itemBuilder: (context, index) {
        final message = _character!.chatHistory[index];
        return ChatMessageBubble(
          text: message['content'] as String,
          isUser: message['isUser'] as bool,
          showAvatar: true,
          avatarText: message['isUser'] as bool
              ? localizations.you
              : _character!.name[0].toUpperCase(),
        );
      },
    );
  }

  Widget _buildInputArea(AppLocalizations localizations) {
    final fontScale = ResponsiveUtils.getFontSizeScale(context);
    
    return Container(
      padding: ResponsiveUtils.getChatInputPadding(context),
      decoration: BoxDecoration(
        color: AppTheme.backgroundStart.withValues(alpha: 0.8),
        border: Border(
          top: BorderSide(
            color: AppTheme.warmGold.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Message input field
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _inputFocusNode,
              decoration: InputDecoration(
                hintText: localizations.typeMessage,
                hintStyle: UkrainianFontUtils.latoWithUkrainianSupport(
                  text: localizations.typeMessage,
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14 * fontScale,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: AppTheme.warmGold.withValues(alpha: 0.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: AppTheme.warmGold.withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: AppTheme.warmGold.withValues(alpha: 0.5),
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16 * fontScale,
                  vertical: 12 * fontScale,
                ),
              ),
              style: UkrainianFontUtils.latoWithUkrainianSupport(
                text: "Sample text", // Placeholder for style detection
                color: Colors.white,
                fontSize: 14 * fontScale,
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          SizedBox(width: 8 * fontScale),
          // Send button
          IconButton(
            icon: _isLoading
                ? SizedBox(
                    width: 24 * fontScale,
                    height: 24 * fontScale,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.warmGold,
                      ),
                    ),
                  )
                : Icon(Icons.send, size: 24 * fontScale),
            color: AppTheme.warmGold,
            onPressed: _isLoading ? null : _sendMessage,
          ),
        ],
      ),
    );
  }

  Future<void> _showClearChatDialog(AppLocalizations localizations) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundStart,
        title: Text(
          localizations.clearChatHistoryTitle,
          style: UkrainianFontUtils.cinzelWithUkrainianSupport(
            text: localizations.clearChatHistoryTitle,
            color: Colors.white,
          ),
        ),
        content: Text(
          localizations.clearChatHistoryConfirm,
          style: UkrainianFontUtils.latoWithUkrainianSupport(
            text: localizations.clearChatHistoryConfirm,
            color: Colors.white70,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              localizations.cancel,
              style: UkrainianFontUtils.latoWithUkrainianSupport(
                text: localizations.cancel,
                color: AppTheme.warmGold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              localizations.clear,
              style: UkrainianFontUtils.latoWithUkrainianSupport(
                text: localizations.clear,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      final charactersProvider = Provider.of<CharactersProvider>(
        context,
        listen: false,
      );

      try {
        // Create updated character with empty chat history
        final updatedCharacter = CharacterModel(
          id: _character!.id,
          name: _character!.name,
          systemPrompt: _character!.systemPrompt,
          imageUrl: _character!.imageUrl,
          createdAt: _character!.createdAt,
          accentColor: _character!.accentColor,
          chatHistory: [],
          additionalInfo: _character!.additionalInfo,
          model: _character!.model,
        );

        // Update in provider
        await charactersProvider.updateCharacter(updatedCharacter);

        setState(() {
          _character = updatedCharacter;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizations.chatHistoryCleared)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.errorClearingData),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
