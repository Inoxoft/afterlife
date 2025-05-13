import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/animated_particles.dart';
import 'famous_character_service.dart';
import 'famous_character_prompts.dart';

class FamousCharacterChatScreen extends StatefulWidget {
  final String characterName;
  final String? imageUrl;

  const FamousCharacterChatScreen({
    Key? key,
    required this.characterName,
    this.imageUrl,
  }) : super(key: key);

  @override
  State<FamousCharacterChatScreen> createState() =>
      _FamousCharacterChatScreenState();
}

class _FamousCharacterChatScreenState extends State<FamousCharacterChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  bool _isLoading = false;
  List<Map<String, dynamic>> _messages = [];
  late String _selectedModel;

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
  void initState() {
    super.initState();
    _isLoading = false;
    _selectedModel = FamousCharacterPrompts.getSelectedModel(
      widget.characterName,
    );
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FamousCharacterService.initializeChat(widget.characterName);
      setState(() {
        _messages = FamousCharacterService.getFormattedChatHistory(
          widget.characterName,
        );
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
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
    if (message.isEmpty || _isLoading) return;

    // Clear the input field
    _messageController.clear();

    // Add user message to chat locally for immediate UI update
    setState(() {
      _isLoading = true;
      _messages.add({
        'content': message,
        'isUser': true,
        'timestamp': DateTime.now().toIso8601String(),
      });
    });

    // Scroll to the bottom after state update
    _scrollToBottom();

    try {
      // Send the message to the character
      final response = await FamousCharacterService.sendMessage(
        characterName: widget.characterName,
        message: message,
      );

      // Add AI response to chat history if not null
      if (response != null) {
        setState(() {
          _messages = FamousCharacterService.getFormattedChatHistory(
            widget.characterName,
          );
        });
      } else {
        // Handle null response by showing a fallback message
        final fallbackMessage =
            "I'm sorry, I couldn't process your message at this time. Please try again later.";
        _messages.add({
          'content': fallbackMessage,
          'isUser': false,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }

      // Add error message to chat history
      _messages.add({
        'content':
            "I'm sorry, there was an error processing your message. Please try again.",
        'isUser': false,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } finally {
      // Update UI
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Scroll to bottom to show new messages
        _scrollToBottom();
      }
    }
  }

  void _showClearChatDialog() {
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
    FamousCharacterService.clearChatHistory(widget.characterName);
    setState(() {
      _messages = [];
    });

    // Close the dialog
    Navigator.pop(context);

    // Show a confirmation
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Chat history cleared')));
  }

  void _changeModel(String newModel) {
    setState(() {
      _selectedModel = newModel;
      FamousCharacterPrompts.setSelectedModel(widget.characterName, newModel);
    });

    // Show a confirmation to the user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('AI model updated for ${widget.characterName}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
    // Get available models
    final models = FamousCharacterPrompts.getModelsForCharacter(
      widget.characterName,
    );

    // Find current model details
    final selectedModel = models.firstWhere(
      (model) => model['id'] == _selectedModel,
      orElse: () => {'name': 'Default Model'},
    );

    return AppBar(
      backgroundColor: AppTheme.backgroundStart,
      elevation: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.etherealCyan.withOpacity(0.3),
            backgroundImage:
                widget.imageUrl != null ? AssetImage(widget.imageUrl!) : null,
            child:
                widget.imageUrl == null
                    ? Text(
                      widget.characterName.isNotEmpty
                          ? widget.characterName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: AppTheme.etherealCyan,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    )
                    : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.characterName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedModel,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: AppTheme.warmGold,
                            size: 16,
                          ),
                          isDense: true,
                          dropdownColor: AppTheme.deepIndigo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          items:
                              models.map<DropdownMenuItem<String>>((model) {
                                return DropdownMenuItem<String>(
                                  value: model['id'] as String,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.memory_rounded,
                                        color: AppTheme.warmGold,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        model['name'] as String,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (model['recommended'] == true)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            left: 4,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 2,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.warmGold
                                                .withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                          child: const Text(
                                            'RECOMMENDED',
                                            style: TextStyle(
                                              color: AppTheme.warmGold,
                                              fontSize: 6,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              _changeModel(newValue);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Clear chat button
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white70),
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
    if (_messages.isEmpty) {
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
                'Start chatting with ${widget.characterName}',
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
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
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
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(25.0),
                  border: Border.all(color: Colors.white10, width: 1),
                ),
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
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 14.0,
                    ),
                    prefixIcon: Icon(
                      Icons.chat_bubble_outline,
                      color: AppTheme.etherealCyan.withOpacity(0.5),
                      size: 18,
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
            ),
            const SizedBox(width: 12.0),
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
            ? AppTheme.accentPurple.withOpacity(0.6)
            : Colors.black.withOpacity(0.4);
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;

    // Check if message is very long (over 1000 characters)
    final bool isVeryLong = message.length > 1000;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                          ? AppTheme.accentPurple.withOpacity(0.7)
                          : AppTheme.etherealCyan.withOpacity(0.5),
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
              ? AppTheme.accentPurple.withOpacity(0.8)
              : AppTheme.etherealCyan.withOpacity(0.8),
      child: Text(
        isUser ? 'You' : 'AI',
        style: const TextStyle(
          color: Colors.white,
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
      style: const TextStyle(
        color: Colors.white,
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
