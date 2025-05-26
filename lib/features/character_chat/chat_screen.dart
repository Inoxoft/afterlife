import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/animated_particles.dart';
import '../models/character_model.dart';
import '../providers/characters_provider.dart';
import '../character_profile/character_profile_screen.dart';
import 'chat_service.dart';
import 'package:google_fonts/google_fonts.dart';
import '../chat/models/chat_message.dart';
import '../chat/widgets/chat_message_bubble.dart';

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
  bool _isLoading = false;
  CharacterModel? _character;
  String? _loadError;

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

  // Keep this screen alive in navigation stack for better performance
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _isLoading = false;

    // Load the character on the next frame for better UI responsiveness
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCharacter();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _loadCharacter() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final charactersProvider = Provider.of<CharactersProvider>(
        context,
        listen: false,
      );

      // Use the provider to load the character
      final character = await charactersProvider.loadCharacterById(
        widget.characterId,
      );

      if (character != null && mounted) {
        setState(() {
          _character = character;
          _isLoading = false;
          _loadError = null;
        });

        // Select this character in the provider
        charactersProvider.selectCharacter(widget.characterId);
      } else if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = 'Character not found';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = 'Could not load character - $e';
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Show error here instead of in initState
    if (_loadError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $_loadError'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
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
    if (message.isEmpty || _isLoading || _character == null) return;

    // Clear the input field
    _messageController.clear();

    // Get the character provider
    final charactersProvider = Provider.of<CharactersProvider>(
      context,
      listen: false,
    );

    // Add user message to chat history
    await charactersProvider.addMessageToSelectedCharacter(
      text: message,
      isUser: true,
    );

    // Update state
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
      // Get the updated character
      final character = charactersProvider.selectedCharacter;
      if (character == null) {
        throw Exception('Character not selected');
      }

      // Prepare the chat history for the API - limit to last 10 messages for performance
      final recentMessages =
          character.chatHistory.length > 10
              ? character.chatHistory.sublist(character.chatHistory.length - 10)
              : character.chatHistory;

      final apiChatHistory =
          recentMessages
              .map(
                (msg) => {
                  'role': msg['isUser'] == true ? 'user' : 'assistant',
                  'content': msg['content'] as String,
                },
              )
              .toList();

      // Send the message to the character
      final response = await ChatService.sendMessageToCharacter(
        characterId: character.id,
        message: message,
        systemPrompt: character.systemPrompt,
        chatHistory: apiChatHistory,
        model: character.model,
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
          text:
              "I'm sorry, I couldn't process your message at this time. Please try again later.",
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
        text:
            "I'm sorry, there was an error processing your message. Please try again.",
        isUser: false,
      );
    } finally {
      // Update UI
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Refresh character data
          _character =
              Provider.of<CharactersProvider>(
                context,
                listen: false,
              ).selectedCharacter;
        });

        // Scroll to bottom to show new messages
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    if (_character == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chat'),
          backgroundColor: AppTheme.backgroundStart,
        ),
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // We have a character, render the chat UI
    return Scaffold(
      appBar: _buildAppBar(),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
        child: Stack(
          children: [
            // Background particles with reduced opacity
            _particleBackground,

            Column(
              children: [
                // Chat messages
                Expanded(child: _buildChatList()),

                // Input area
                _buildInputArea(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Extract app bar to a separate method for readability and performance
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.backgroundStart,
      elevation: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.midnightPurple.withOpacity(0.7),
            child: Text(
              _character!.name.isNotEmpty
                  ? _character!.name[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: AppTheme.warmGold,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                shadows: [
                  Shadow(
                    color: AppTheme.warmGold.withOpacity(0.5),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _character!.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Your Digital Twin',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.silverMist.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Profile button
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: AppTheme.midnightPurple.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.warmGold.withOpacity(0.3),
              width: 0.5,
            ),
          ),
          child: IconButton(
            icon: Icon(Icons.person_outline, color: AppTheme.silverMist),
            tooltip: 'View Profile',
            onPressed: () => _navigateToProfile(),
          ),
        ),

        // Clear chat button
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: AppTheme.midnightPurple.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.warmGold.withOpacity(0.3),
              width: 0.5,
            ),
          ),
          child: IconButton(
            icon: Icon(Icons.delete_outline, color: AppTheme.silverMist),
            tooltip: 'Clear Chat',
            onPressed: _showClearChatDialog,
          ),
        ),
      ],
    );
  }

  // Extract chat list to a separate method for readability and performance
  Widget _buildChatList() {
    // If no messages, show a welcome message
    if (_character!.chatHistory.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 48,
                color: AppTheme.silverMist.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Start chatting with ${_character!.name}',
                style: GoogleFonts.lato(
                  fontSize: 18,
                  color: AppTheme.silverMist.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Send a message below to begin the conversation',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: AppTheme.silverMist.withOpacity(0.5),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _character!.chatHistory.length,
      itemBuilder: (context, index) {
        final message = _character!.chatHistory[index];
        return ChatMessageBubble(
          message: ChatMessage(
            content: message['content'] as String,
            isUser: message['isUser'] as bool,
            timestamp: DateTime.now(), // TODO: Add actual timestamp to messages
          ),
          showAvatar: true,
          avatarText: message['isUser'] as bool ? 'You' : _character!.name[0].toUpperCase(),
          avatarIcon: message['isUser'] as bool ? Icons.person : null,
        );
      },
    );
  }

  // Extract input area to a separate method for readability and performance
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.midnightPurple.withOpacity(0.3),
        border: Border(
          top: BorderSide(
            color: AppTheme.warmGold.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _inputFocusNode,
              style: TextStyle(color: AppTheme.silverMist),
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: TextStyle(
                  color: AppTheme.silverMist.withOpacity(0.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(
                    color: AppTheme.warmGold.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(
                    color: AppTheme.warmGold.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(
                    color: AppTheme.warmGold,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.warmGold,
              borderRadius: BorderRadius.circular(25),
            ),
            child: IconButton(
              icon: const Icon(Icons.send),
              color: AppTheme.midnightPurple,
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  void _showClearChatDialog() {
    if (_character == null) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Clear Chat History',
              style: GoogleFonts.cinzel(
                color: AppTheme.warmGold,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'This will delete all messages in this conversation. This action cannot be undone.',
              style: TextStyle(color: AppTheme.silverMist),
            ),
            backgroundColor: AppTheme.midnightPurple,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: AppTheme.warmGold.withOpacity(0.3),
                width: 1,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppTheme.silverMist),
                ),
              ),
              TextButton(
                onPressed: () => _clearChatHistory(context),
                child: Text(
                  'Clear',
                  style: TextStyle(color: AppTheme.warmGold),
                ),
              ),
            ],
          ),
    );
  }

  void _clearChatHistory(BuildContext context) {
    // Clear chat history
    final charactersProvider = Provider.of<CharactersProvider>(
      context,
      listen: false,
    );

    // Create a new character with empty chat history
    final updatedCharacter = CharacterModel(
      id: _character!.id,
      name: _character!.name,
      systemPrompt: _character!.systemPrompt,
      imageUrl: _character!.imageUrl,
      createdAt: _character!.createdAt,
      accentColor: _character!.accentColor,
      chatHistory: [],
    );

    // Update the character
    charactersProvider.updateCharacter(updatedCharacter);

    // Close the dialog
    Navigator.pop(context);

    // Update local state
    setState(() {
      _character = updatedCharacter;
    });

    // Show a confirmation
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Chat history cleared')));
  }

  void _navigateToProfile() {
    if (_character == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Could not load character profile'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CharacterProfileScreen(characterId: _character!.id),
      ),
    ).then((_) {
      // Reload character data when returning from profile
      _loadCharacter();
    });
  }
}

// Extracted as a separate stateless widget for better performance
class _MessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;

  const _MessageBubble({Key? key, required this.message, required this.isUser})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bubbleColor =
        isUser
            ? AppTheme.midnightPurple.withOpacity(0.6)
            : AppTheme.midnightPurple.withOpacity(0.5);
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;

    // Check if message is very long (over 1000 characters)
    final bool isVeryLong = message.length > 1000;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment:
            isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI avatar (only shown for AI messages)
          if (!isUser) _buildAvatar(context),
          if (!isUser) const SizedBox(width: 8),

          // Message bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
                maxHeight:
                    isVeryLong
                        ? MediaQuery.of(context).size.height * 0.4
                        : double.infinity,
              ),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft:
                      isUser
                          ? const Radius.circular(16)
                          : const Radius.circular(4),
                  bottomRight:
                      isUser
                          ? const Radius.circular(4)
                          : const Radius.circular(16),
                ),
                border: Border.all(
                  color:
                      isUser
                          ? AppTheme.warmGold.withOpacity(0.5)
                          : AppTheme.warmGold.withOpacity(0.4),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child:
                  isVeryLong
                      ? SingleChildScrollView(child: _buildMessageText())
                      : _buildMessageText(),
            ),
          ),

          // User avatar (only shown for user messages)
          if (isUser) const SizedBox(width: 8),
          if (isUser) _buildAvatar(context),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor:
          isUser
              ? AppTheme.midnightPurple.withOpacity(0.8)
              : AppTheme.midnightPurple.withOpacity(0.8),
      child: Text(
        isUser ? 'You' : 'AI',
        style: TextStyle(
          color: AppTheme.warmGold,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  // Extracted method to build the message text with proper styling
  Widget _buildMessageText() {
    return Text(
      message,
      style: TextStyle(
        color: AppTheme.silverMist,
        height: 1.4, // Improve line spacing
      ),
      softWrap: true, // Ensure text wraps properly
      textWidthBasis:
          TextWidthBasis.longestLine, // Better handling of long content
    );
  }
}

// Extracted as a separate stateless widget for better performance
class _SendButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const _SendButton({Key? key, required this.isLoading, this.onPressed})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color:
            isLoading ? AppTheme.warmGold.withOpacity(0.3) : AppTheme.warmGold,
        shape: BoxShape.circle,
        boxShadow: [
          if (!isLoading)
            BoxShadow(
              color: AppTheme.warmGold.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
        ],
      ),
      child: IconButton(
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child:
              isLoading
                  ? Icon(
                    Icons.hourglass_top,
                    key: ValueKey('loading'),
                    color: AppTheme.silverMist.withOpacity(0.6),
                  )
                  : const Icon(
                    Icons.send,
                    key: ValueKey('send'),
                    color: Colors.black87,
                  ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
