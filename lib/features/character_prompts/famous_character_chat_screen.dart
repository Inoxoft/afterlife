import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/animated_particles.dart';
import '../../l10n/app_localizations.dart';
import '../providers/language_provider.dart';
import 'famous_character_service.dart';
import 'famous_character_prompts.dart';
import 'package:share_plus/share_plus.dart';

import '../chat/widgets/chat_message_bubble.dart';

class FamousCharacterChatScreen extends StatefulWidget {
  final String characterName;
  final String? imageUrl;

  const FamousCharacterChatScreen({
    super.key,
    required this.characterName,
    this.imageUrl,
  });

  @override
  State<FamousCharacterChatScreen> createState() =>
      _FamousCharacterChatScreenState();
}

class _FamousCharacterChatScreenState extends State<FamousCharacterChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  bool _isLoading = false;
  bool _cancelRequested = false;
  int _currentRunId = 0;
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

    // Inject the LanguageProvider
    final languageProvider = context.read<LanguageProvider>();
    FamousCharacterService.setLanguageProvider(languageProvider);

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

    final localizations = AppLocalizations.of(context);

    // Clear the input field
    _messageController.clear();

    // Add user message to chat history immediately
    FamousCharacterService.addUserMessage(
      characterName: widget.characterName,
      message: message,
    );

    // Update UI to show user message immediately
    setState(() {
      _messages = FamousCharacterService.getFormattedChatHistory(
        widget.characterName,
      );
      _isLoading = true;
      _cancelRequested = false;
      _currentRunId++;
    });

    // Scroll to the bottom after adding user message
    _scrollToBottom();

    final int runId = _currentRunId;
    try {
      // Send the message using the simplified service (like regular character chat)
      final response = await FamousCharacterService.sendMessage(
        characterName: widget.characterName,
        message: message,
      );

      // Add artificial delay to simulate natural conversation flow
      await Future.delayed(const Duration(milliseconds: 800));

      if (_cancelRequested || runId != _currentRunId) {
        return;
      }
      // Update messages from service (will include the AI response)
      if (response != null) {
        setState(() {
          _messages = FamousCharacterService.getFormattedChatHistory(
            widget.characterName,
          );
        });
      } else {
        // Handle null response by adding a fallback message
        FamousCharacterService.addAIMessage(
          characterName: widget.characterName,
          message: localizations.errorProcessingMessage,
        );
        setState(() {
          _messages = FamousCharacterService.getFormattedChatHistory(
            widget.characterName,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.errorConnecting),
            backgroundColor: AppTheme.errorColor,
            action: SnackBarAction(
              label: localizations.retry,
              onPressed: () {
                _messageController.text = message;
                _sendMessage();
              },
            ),
          ),
        );
      }

      // Add error message to chat history
      FamousCharacterService.addAIMessage(
        characterName: widget.characterName,
        message: localizations.errorConnecting,
      );
      setState(() {
        _messages = FamousCharacterService.getFormattedChatHistory(
          widget.characterName,
        );
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

  void _stopGeneration() {
    if (!_isLoading) return;
    setState(() {
      _cancelRequested = true;
      _isLoading = false;
      _currentRunId++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
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

                // Small typing indicator
                if (_isLoading)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(left: 16, bottom: 6),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppTheme.warmGold.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.warmGold.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),

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
    // Get available models
    final models = FamousCharacterPrompts.getModelsForCharacter(
      widget.characterName,
    );

    // Current model information is available via _selectedModel

    return AppBar(
      backgroundColor: AppTheme.backgroundStart,
      elevation: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.midnightPurple.withValues(alpha: 0.7),
            backgroundImage:
                widget.imageUrl != null ? AssetImage(widget.imageUrl!) : null,
            child:
                widget.imageUrl == null
                    ? Text(
                      widget.characterName.isNotEmpty
                          ? widget.characterName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: AppTheme.warmGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        shadows: [
                          Shadow(
                            color: AppTheme.warmGold.withValues(alpha: 0.5),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
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
                                            color: AppTheme.warmGold.withValues(
                                              alpha: 0.2,
                                            ),
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
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'export') {
              _exportChat();
            } else if (value == 'clear') {
              _showClearChatDialog();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'export',
              child: Text(localizations.exportChat),
            ),
            PopupMenuItem(
              value: 'clear',
              child: Text(localizations.clearChatHistory),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChatList(AppLocalizations localizations) {
    // If no messages, show a welcome message
    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 48,
                color: AppTheme.silverMist.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                localizations.startChattingWith.replaceAll(
                  '{name}',
                  widget.characterName,
                ),
                style: TextStyle(
                  fontFamily: 'Lato',
                  fontSize: 18,
                  color: AppTheme.silverMist.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                localizations.sendMessageToBegin,
                style: TextStyle(
                  fontFamily: 'Lato',
                  fontSize: 14,
                  color: AppTheme.silverMist.withValues(alpha: 0.5),
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
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return ChatMessageBubble(
          text: message['content'] as String,
          isUser: message['isUser'] as bool,
          showAvatar: true,
          avatarText:
              message['isUser'] as bool
                  ? localizations.you
                  : widget.characterName[0].toUpperCase(),
          avatarIcon: message['isUser'] as bool ? Icons.person : null,
        );
      },
    );
  }

  Widget _buildInputArea(AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.midnightPurple.withValues(alpha: 0.3),
        border: Border(
          top: BorderSide(
            color: AppTheme.warmGold.withValues(alpha: 0.3),
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
                hintText: localizations.typeMessage,
                hintStyle: TextStyle(
                  color: AppTheme.silverMist.withValues(alpha: 0.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(
                    color: AppTheme.warmGold.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(
                    color: AppTheme.warmGold.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: AppTheme.warmGold),
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
          _isLoading
              ? Container(
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: AppTheme.errorColor.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.stop_circle_outlined),
                    color: AppTheme.errorColor,
                    onPressed: _stopGeneration,
                    tooltip: 'Stop',
                  ),
                )
              : Container(
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

  void _changeModel(String newModel) {
    setState(() {
      _selectedModel = newModel;
      // Use the new simplified service method
      FamousCharacterService.updateCharacterModel(
        widget.characterName,
        newModel,
      );
    });

    // Show a confirmation to the user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('AI model updated for ${widget.characterName}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showClearChatDialog() {
    final localizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(localizations.clearChatHistoryTitle),
            content: Text(localizations.clearChatHistoryConfirm),
            backgroundColor: AppTheme.deepIndigo,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(localizations.cancel),
              ),
              TextButton(
                onPressed: () => _clearChatHistory(context),
                child: Text(localizations.clear),
              ),
            ],
          ),
    );
  }

  void _clearChatHistory(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    // Clear chat history using simplified service
    FamousCharacterService.clearChatHistory(widget.characterName);
    setState(() {
      _messages = [];
    });

    // Close the dialog
    Navigator.pop(context);

    // Show a confirmation
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(localizations.chatHistoryCleared)));
  }

  void _exportChat() {
    final buffer = StringBuffer();
    buffer.writeln('Conversation with ${widget.characterName} — Afterlife');
    buffer.writeln('');
    for (final msg in _messages) {
      final isUser = (msg['isUser'] as bool?) ?? false;
      final content = (msg['content'] as String?) ?? '';
      final prefix = isUser ? 'You' : widget.characterName;
      buffer.writeln('$prefix: $content');
      buffer.writeln('');
    }
    final text = buffer.toString().trim();
    if (text.isEmpty) return;
    Share.share(text, subject: 'Chat with ${widget.characterName}');
  }
}
