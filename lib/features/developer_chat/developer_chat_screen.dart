import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../chat/widgets/chat_message_bubble.dart';
import '../chat/models/chat_message.dart';
import '../models/leading_question_detector.dart';
import '../widgets/leading_question_warning.dart';

class DeveloperChatScreen extends StatefulWidget {
  const DeveloperChatScreen({Key? key}) : super(key: key);

  @override
  State<DeveloperChatScreen> createState() => _DeveloperChatScreenState();
}

class _DeveloperChatScreenState extends State<DeveloperChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // Leading question detection state
  Map<String, dynamic>? _leadingQuestionWarning;
  String? _pendingMessage;

  @override
  void initState() {
    super.initState();
    _initializeLeadingQuestionDetector();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeLeadingQuestionDetector() async {
    try {
      await LeadingQuestionDetector.initialize();
    } catch (e) {
      print('Error initializing leading question detector: $e');
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

  /// Check if a message contains leading questions
  Future<Map<String, dynamic>?> _checkForLeadingQuestion(String message) async {
    try {
      print('🔍 Checking for leading question: "$message"');
      
      final result = await LeadingQuestionDetector.detectLeadingQuestion(message);
      
      if (result['isLeading'] == true) {
        print('⚠️ Leading question detected with confidence: ${result['confidence']}');
        return result;
      } else {
        print('✅ No leading question detected (confidence: ${result['confidence']})');
        return null;
      }
    } catch (e) {
      print('❌ Leading question detection failed: $e');
      return null;
    }
  }

  Future<void> _sendMessage({bool bypassWarning = false}) async {
    if (_messageController.text.trim().isEmpty || _isLoading) return;

    final userMessage = _messageController.text.trim();

    // If we're not bypassing the warning, check for leading questions first
    if (!bypassWarning) {
      try {
        final leadingQuestionResult = await _checkForLeadingQuestion(userMessage);
        if (leadingQuestionResult != null) {
          // Show warning instead of sending message
          setState(() {
            _leadingQuestionWarning = leadingQuestionResult;
            _pendingMessage = userMessage;
          });
          return;
        }
      } catch (e) {
        // If detection fails, proceed with sending the message
        print('Leading question detection failed: $e');
      }
    }

    // Clear the input field and any warnings
    _messageController.clear();
    setState(() {
      _leadingQuestionWarning = null;
      _pendingMessage = null;
    });

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
          content: "Thanks for reaching out! The developer chat feature is coming soon. For now, you can find us on GitHub or Discord. Your message has been noted and the API provider has been informed that your message contains user data.",
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });

      // Scroll to show the response
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _handleContinueAnyway() {
    if (_pendingMessage != null) {
      _messageController.text = _pendingMessage!;
      _sendMessage(bypassWarning: true);
    }
  }

  void _handleRephrase() {
    if (_pendingMessage != null) {
      _messageController.text = _pendingMessage!;
    }
    setState(() {
      _leadingQuestionWarning = null;
      _pendingMessage = null;
    });
    _inputFocusNode.requestFocus();
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
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.silverMist,
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
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.warmGold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Get help with technical issues or share feedback directly with our development team.',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: AppTheme.silverMist.withValues(alpha: 0.8),
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
                    text: message.content,
                    isUser: message.isUser,
                    showAvatar: true,
                    avatarText: message.isUser ? 'You' : 'AI',
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
                        color: AppTheme.silverMist.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

            // Leading question warning
            if (_leadingQuestionWarning != null)
              LeadingQuestionWarning(
                warningMessage: _leadingQuestionWarning!['message'] as String,
                confidence: _leadingQuestionWarning!['confidence'] as double,
                onContinueAnyway: _handleContinueAnyway,
                onRephrase: _handleRephrase,
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
                      style: TextStyle(color: AppTheme.silverMist),
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
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