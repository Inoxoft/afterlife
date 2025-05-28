import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/animated_particles.dart';
import '../models/character_model.dart';
import '../providers/characters_provider.dart';
import '../providers/language_provider.dart';
import '../character_profile/character_profile_screen.dart';
import 'chat_service.dart';
import 'package:google_fonts/google_fonts.dart';
import '../chat/models/chat_message.dart';
import '../chat/widgets/chat_message_bubble.dart';
import '../../l10n/app_localizations.dart';

class CharacterChatScreen extends StatefulWidget {
  final String characterId;

  const CharacterChatScreen({Key? key, required this.characterId})
    : super(key: key);

  @override
  State<CharacterChatScreen> createState() => _CharacterChatScreenState();
}

class _CharacterChatScreenState extends State<CharacterChatScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
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
      }
    } catch (e) {
      print('Error loading character: $e');
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
    await charactersProvider.addMessageToSelectedCharacter(
      text: message,
      isUser: true,
    );

    if (mounted) {
      setState(() {
        _isLoading = true;
        // Update character reference to reflect new message
        _character = charactersProvider.selectedCharacter;
      });
    }

    // Scroll to the bottom after state update
    _scrollToBottom();

    try {
      // Send the message to the character
      final response = await ChatService.sendMessageToCharacter(
        characterId: widget.characterId,
        message: message,
        systemPrompt: _character!.systemPrompt,
        chatHistory: _character!.chatHistory,
        model: _character!.model,
      );

      // Add AI response to chat history if not null
      if (response != null) {
        await charactersProvider.addMessageToSelectedCharacter(
          text: response,
          isUser: false,
        );
      } else {
        // Handle null response by showing a fallback message
        await charactersProvider.addMessageToSelectedCharacter(
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
      await charactersProvider.addMessageToSelectedCharacter(
        text: localizations.errorConnecting,
        isUser: false,
      );
    } finally {
      // Update UI
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Refresh character data
          _character = charactersProvider.selectedCharacter;
        });

        // Scroll to bottom to show new messages
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
              style: GoogleFonts.cinzel(
                textStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: AppTheme.warmGold.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              localizations.startChattingWith.replaceAll('{name}', _character!.name),
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              localizations.sendMessageToBegin,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _character!.chatHistory.length,
      itemBuilder: (context, index) {
        final message = _character!.chatHistory[index];
        return ChatMessageBubble(
          message: ChatMessage(
            content: message['content'] as String,
            isUser: message['isUser'] as bool,
            timestamp: DateTime.parse(message['timestamp'] as String),
          ),
          avatarText: message['isUser'] as bool
              ? localizations.you
              : _character!.name[0].toUpperCase(),
        );
      },
    );
  }

  Widget _buildInputArea(AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundStart.withOpacity(0.8),
        border: Border(
          top: BorderSide(
            color: AppTheme.warmGold.withOpacity(0.2),
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
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: AppTheme.warmGold.withOpacity(0.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: AppTheme.warmGold.withOpacity(0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: AppTheme.warmGold.withOpacity(0.5),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: const TextStyle(color: Colors.white),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.warmGold,
                      ),
                    ),
                  )
                : const Icon(Icons.send),
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
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          localizations.clearChatHistoryConfirm,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              localizations.cancel,
              style: const TextStyle(color: AppTheme.warmGold),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              localizations.clear,
              style: const TextStyle(color: Colors.red),
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
