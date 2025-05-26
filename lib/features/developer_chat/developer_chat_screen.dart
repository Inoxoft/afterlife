import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../chat/widgets/chat_message_bubble.dart';
import '../chat/models/chat_message.dart';

class DeveloperChatScreen extends StatefulWidget {
  const DeveloperChatScreen({Key? key}) : super(key: key);

  @override
  State<DeveloperChatScreen> createState() => _DeveloperChatScreenState();
}

class _DeveloperChatScreenState extends State<DeveloperChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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
    if (_messageController.text.trim().isEmpty || _isLoading) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _messages.add(ChatMessage(
        content: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    // Scroll to show the new message
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    // TODO: Implement actual developer chat logic here
    // For now, just add a placeholder response
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _messages.add(ChatMessage(
          content: "Thanks for reaching out! The developer chat feature is coming soon. For now, you can find us on GitHub or Discord.",
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });

      // Scroll to show the response
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Chat header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.midnightPurple.withOpacity(0.3),
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.warmGold.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.warmGold.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          color: AppTheme.warmGold,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Developer info
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.midnightPurple,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.warmGold.withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.developer_mode,
                              color: AppTheme.warmGold,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Developer Chat',
                                style: GoogleFonts.cinzel(
                                  color: AppTheme.warmGold,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Direct line to the development team',
                                style: GoogleFonts.lato(
                                  color: AppTheme.silverMist.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
                      message: message,
                      showAvatar: !message.isUser,
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
                        style: TextStyle(
                          color: AppTheme.silverMist.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

              // Message input
              Container(
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
                    // Text input
                    Expanded(
                      child: TextField(
                        controller: _messageController,
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
      ),
    );
  }
} 