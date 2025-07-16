import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/animated_particles.dart';
import '../../core/utils/ukrainian_font_utils.dart';
import '../providers/language_provider.dart';
import '../character_prompts/famous_character_service.dart';
import '../chat/models/chat_message.dart';
import '../chat/widgets/chat_message_bubble.dart';
import '../../l10n/app_localizations.dart';

class DeveloperChatScreen extends StatefulWidget {
  const DeveloperChatScreen({Key? key}) : super(key: key);

  @override
  State<DeveloperChatScreen> createState() => _DeveloperChatScreenState();
}

class _DeveloperChatScreenState extends State<DeveloperChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  bool _isLoading = false;
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
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
      await FamousCharacterService.initializeChat('Developer');
      setState(() {
        _messages = FamousCharacterService.getFormattedChatHistory('Developer');
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
      // Send the message to the developer character
      final response = await FamousCharacterService.sendMessage(
        characterName: 'Developer',
        message: message,
      );

      // Add AI response to chat history if not null
      if (response != null) {
        setState(() {
          _messages = FamousCharacterService.getFormattedChatHistory('Developer');
        });
      } else {
        // Handle null response by showing a fallback message
        _messages.add({
          'content': localizations.errorProcessingMessage,
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
        'content': localizations.errorConnecting,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.warmGold,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.developer_mode,
                color: AppTheme.midnightPurple,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Developer Chat',
              style: UkrainianFontUtils.createGlobalTextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.silverMist, 
                fontFamily: 'Lato',
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.midnightPurple,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
        child: Column(
          children: [
            // Welcome banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.midnightPurple.withValues(alpha: 0.8),
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.warmGold.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '🚀 Developer Support',
                    style: UkrainianFontUtils.createGlobalTextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.warmGold,
                      fontFamily: 'Lato',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Get help with technical issues or share feedback directly with our development team.',
                    style: UkrainianFontUtils.createGlobalTextStyle(
                      fontSize: 14,
                      color: AppTheme.silverMist.withValues(alpha: 0.8),
                      fontFamily: 'Lato',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Chat messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return ChatMessageBubble(
                    text: message['content'] as String,
                    isUser: message['isUser'] as bool,
                    showAvatar: true,
                    avatarText: message['isUser'] as bool ? 'You' : 'AI',
                  );
                },
              ),
            ),

            // Loading indicator
            if (_isLoading)
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.warmGold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Developer is typing...',
                      style: UkrainianFontUtils.createGlobalTextStyle(
                        color: AppTheme.silverMist.withValues(alpha: 0.7),
                        fontSize: 14,
                        fontFamily: 'Lato',
                      ),
                    ),
                  ],
                ),
              ),

            // Message input
            Container(
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
                  // Text input
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _inputFocusNode,
                      style: UkrainianFontUtils.createGlobalTextStyle(
                        color: AppTheme.silverMist,
                        fontFamily: 'Lato',
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: UkrainianFontUtils.createGlobalTextStyle(
                          color: AppTheme.silverMist.withValues(alpha: 0.5),
                          fontFamily: 'Lato',
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
                  // Send button
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
            ),
          ],
        ),
      ),
    );
  }
} 