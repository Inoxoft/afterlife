import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/animated_particles.dart';
import '../models/character_model.dart';
import '../providers/characters_provider.dart';
import '../character_profile/character_profile_screen.dart';
import 'chat_service.dart';

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
      );

      // Add AI response to chat history
      await charactersProvider.addMessageToSelectedCharacter(
        text: response,
        isUser: false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
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
            backgroundColor: _character!.accentColor.withOpacity(0.2),
            child: Text(
              _character!.name.isNotEmpty
                  ? _character!.name[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: _character!.accentColor,
                fontWeight: FontWeight.bold,
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
                    color: Colors.white60,
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
        IconButton(
          icon: const Icon(Icons.person_outline),
          onPressed: () => _navigateToProfile(),
        ),
        // Clear chat button
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: _showClearChatDialog,
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
              const Icon(
                Icons.chat_bubble_outline,
                size: 48,
                color: Colors.white54,
              ),
              const SizedBox(height: 16),
              Text(
                'Start chatting with ${_character!.name}',
                style: const TextStyle(fontSize: 18, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Send a message below to begin the conversation',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.5),
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
      padding: const EdgeInsets.all(16.0),
      itemCount: _character!.chatHistory.length,
      itemBuilder: (context, index) {
        final message = _character!.chatHistory[index];
        return _MessageBubble(
          key: ValueKey('msg_${index}_${message['isUser']}'),
          message: message['content'] as String,
          isUser: message['isUser'] as bool,
        );
      },
    );
  }

  // Extract input area to a separate method for readability and performance
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: AppTheme.deepIndigo.withOpacity(0.7),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 6.0,
            spreadRadius: 0.0,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _inputFocusNode,
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: const TextStyle(color: Colors.white60),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.black26,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 14.0,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                minLines: 1,
                maxLines: 5,
                onSubmitted:
                    _isLoading
                        ? null
                        : (text) {
                          if (text.trim().isNotEmpty) {
                            _sendMessage();
                          }
                        },
              ),
            ),
            const SizedBox(width: 8.0),
            _SendButton(
              isLoading: _isLoading,
              onPressed:
                  _isLoading
                      ? null
                      : () {
                        if (_messageController.text.trim().isNotEmpty) {
                          _sendMessage();
                        }
                      },
            ),
          ],
        ),
      ),
    );
  }

  void _showClearChatDialog() {
    if (_character == null) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear Chat History'),
            content: const Text(
              'This will delete all messages in this conversation. This action cannot be undone.',
            ),
            backgroundColor: AppTheme.deepIndigo,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => _clearChatHistory(context),
                child: const Text('Clear'),
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
            ? AppTheme.accentPurple.withOpacity(0.5)
            : Colors.black.withOpacity(0.3);
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;

    return Align(
      alignment: alignment,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(message, style: const TextStyle(color: Colors.white)),
      ),
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
            isLoading
                ? AppTheme.etherealCyan.withOpacity(0.3)
                : AppTheme.etherealCyan,
        shape: BoxShape.circle,
        boxShadow: [
          if (!isLoading)
            BoxShadow(
              color: AppTheme.etherealCyan.withOpacity(0.3),
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
                  ? const Icon(
                    Icons.hourglass_top,
                    key: ValueKey('loading'),
                    color: Colors.white60,
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
