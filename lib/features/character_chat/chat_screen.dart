import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/animated_particles.dart';
import '../models/character_model.dart';
import '../providers/characters_provider.dart';
import 'chat_service.dart';

class CharacterChatScreen extends StatefulWidget {
  final String characterId;

  const CharacterChatScreen({Key? key, required this.characterId})
    : super(key: key);

  @override
  State<CharacterChatScreen> createState() => _CharacterChatScreenState();
}

class _CharacterChatScreenState extends State<CharacterChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  bool _isLoading = false;
  CharacterModel? _character;

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

  void _loadCharacter() {
    final charactersProvider = Provider.of<CharactersProvider>(
      context,
      listen: false,
    );

    try {
      // Find the character by ID
      final character = charactersProvider.characters.firstWhere(
        (c) => c.id == widget.characterId,
        orElse: () => throw Exception('Character not found'),
      );

      setState(() {
        _character = character;
      });

      // Select this character in the provider
      charactersProvider.selectCharacter(widget.characterId);

      print('Loaded character: ${character.name}');
      print('Chat history length: ${character.chatHistory.length}');
    } catch (e) {
      print('Error loading character: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: Could not load character'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
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

    // Set loading state
    setState(() {
      _isLoading = true;
    });

    // Scroll to the bottom
    _scrollToBottom();

    try {
      // Get the updated character
      final character = charactersProvider.selectedCharacter;
      if (character == null) {
        throw Exception('Character not selected');
      }

      // Prepare the chat history for the API
      final apiChatHistory =
          character.chatHistory
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
      print('Error sending message: $e');

      // Show error message to user
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
        });

        // Update character reference
        _loadCharacter();

        // Scroll to bottom to show new messages
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_character == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chat'),
          backgroundColor: AppTheme.backgroundStart,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // We have a character, render the chat UI
    return Scaffold(
      appBar: AppBar(
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'clear') {
                _showClearChatDialog();
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20),
                        SizedBox(width: 8),
                        Text('Clear Chat'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
        child: Stack(
          children: [
            // Background particles with reduced opacity
            const Opacity(
              opacity: 0.5,
              child: AnimatedParticles(
                particleCount: 30,
                particleColor: Colors.white,
                minSpeed: 0.01,
                maxSpeed: 0.03,
              ),
            ),

            Column(
              children: [
                // Chat messages
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _character!.chatHistory.length,
                    itemBuilder: (context, index) {
                      final message = _character!.chatHistory[index];
                      return AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: 1.0,
                        curve: Curves.easeOutQuad,
                        child: _buildMessageBubble(message),
                      );
                    },
                  ),
                ),

                // Input area
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.deepIndigo.withOpacity(0.7),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
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
                              hintStyle: TextStyle(color: Colors.white60),
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
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color:
                                _isLoading
                                    ? AppTheme.etherealCyan.withOpacity(0.3)
                                    : AppTheme.etherealCyan,
                            shape: BoxShape.circle,
                            boxShadow: [
                              if (!_isLoading)
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
                              transitionBuilder: (
                                Widget child,
                                Animation<double> animation,
                              ) {
                                return ScaleTransition(
                                  scale: animation,
                                  child: child,
                                );
                              },
                              child:
                                  _isLoading
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
                            onPressed:
                                _isLoading
                                    ? null
                                    : () {
                                      if (_messageController.text
                                          .trim()
                                          .isNotEmpty) {
                                        _sendMessage();
                                      }
                                    },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isUser = message['isUser'] as bool;
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
        child: Text(
          message['content'] as String,
          style: const TextStyle(color: Colors.white),
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
                onPressed: () {
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

                  // Show a confirmation
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chat history cleared')),
                  );
                },
                child: const Text('Clear'),
              ),
            ],
          ),
    );
  }
}
