import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/animated_particles.dart';
import '../models/character_model.dart';
import '../providers/characters_provider.dart';
import '../character_profile/character_profile_screen.dart';
import '../chat/widgets/chat_message_bubble.dart';
import '../../l10n/app_localizations.dart';
import '../../core/utils/ukrainian_font_utils.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/services/hybrid_chat_service.dart';
import '../../core/services/local_llm_service.dart';
import 'package:share_plus/share_plus.dart';
import '../settings/local_llm_settings_screen.dart';

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
  bool _cancelRequested = false;
  int _currentRunId = 0;

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

    // If using a local model on Android, ensure it's downloaded before sending
    // On iOS, we always use Apple Foundation Models and skip Gemma checks entirely
    if (!Platform.isIOS) {
      try {
        if (_character != null && CharacterModel.isLocalModel(_character!.model)) {
          if (!LocalLLMService.isInitialized) {
            await LocalLLMService.initialize();
          }

          if (LocalLLMService.modelStatus != ModelDownloadStatus.downloaded) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${localizations.localModel} • ${localizations.notDownloaded}',
                  ),
                  action: SnackBarAction(
                    label: localizations.downloadModel,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LocalLLMSettingsScreen(),
                        ),
                      );
                    },
                  ),
                ),
              );
            }
            return;
          }
        }
      } catch (_) {
        // If status check fails, fall through to normal error handling later
      }
    }

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
        _cancelRequested = false;
        _currentRunId++;
      });

      // Reload the character to get updated chat history
      await _loadCharacter();
    }

    // Scroll to the bottom after state update
    _scrollToBottom();

    final int runId = _currentRunId;
    try {
      // Create a copy of chat history excluding the message we just added
      // to prevent duplication in the AI request
      final chatHistoryForAI =
          _character!.chatHistory.where((msg) {
            // Exclude the message we just added (last user message with same content)
            return !(msg['isUser'] == true && msg['content'] == message);
          }).toList();

      // Ensure local LLM chat session is fresh per character on Android only
      if (!Platform.isIOS && _character != null && CharacterModel.isLocalModel(_character!.model)) {
        await LocalLLMService.startNewChatSession();
      }

      // Send the message to the character
      final response = await HybridChatService.sendMessageToCharacter(
        characterId: widget.characterId,
        message: message,
        systemPrompt: _character!.systemPrompt,
        chatHistory: chatHistoryForAI,
        model: _character!.model,
        localPrompt: _character!.localPrompt,
      );

      // Add artificial delay to simulate natural conversation flow
      await Future.delayed(const Duration(milliseconds: 800));

      // Add AI response to chat history if not null
      if (_cancelRequested || runId != _currentRunId) {
        return;
      }
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
    return AppBar(
      backgroundColor: AppTheme.backgroundStart,
      elevation: 0,
      title: Row(
        children: [
          // Character avatar
          CircleAvatar(
            backgroundColor: AppTheme.midnightPurple,
            child:
                _character!.icon != null
                    ? Icon(
                      _character!.icon!,
                      color: AppTheme.warmGold,
                      size: 20,
                    )
                    : Text(
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
                builder:
                    (context) =>
                        CharacterProfileScreen(characterId: _character!.id),
              ),
            );
          },
        ),
        // Options menu: Export chat or Clear chat
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'export') {
              _exportChat();
            } else if (value == 'clear') {
              _showClearChatDialog(localizations);
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
          avatarText:
              message['isUser'] as bool
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
          // Stop/Send button
          _isLoading
              ? Container(
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.errorColor.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    onPressed: _stopGeneration,
                    icon: Icon(
                      Icons.stop_circle_outlined,
                      color: AppTheme.errorColor,
                      size: 22 * fontScale,
                    ),
                    tooltip: 'Stop',
                  ),
                )
              : IconButton(
                  icon: Icon(Icons.send, size: 24 * fontScale),
                  color: AppTheme.warmGold,
                  onPressed: _sendMessage,
                ),
        ],
      ),
    );
  }

  Future<void> _showClearChatDialog(AppLocalizations localizations) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
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

  void _exportChat() {
    if (_character == null) return;

    final String characterName = _character!.name;
    final buffer = StringBuffer();
    buffer.writeln('Conversation with $characterName — Afterlife');
    buffer.writeln('');
    for (final msg in _character!.chatHistory) {
      final isUser = (msg['isUser'] as bool?) ?? false;
      final content = (msg['content'] as String?) ?? '';
      final prefix = isUser ? 'You' : characterName;
      buffer.writeln('$prefix: $content');
      buffer.writeln('');
    }
    final text = buffer.toString().trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nothing to export yet')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    final box = context.findRenderObject() as RenderBox?;
    Share.share(
      text,
      subject: 'Chat with $characterName',
      sharePositionOrigin:
          box != null ? box.localToGlobal(Offset.zero) & box.size : const Rect.fromLTWH(0, 0, 0, 0),
    );
  }
}
