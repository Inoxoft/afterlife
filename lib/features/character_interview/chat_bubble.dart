// lib/features/character_interview/chat_bubble.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'message_model.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final bool showAvatar;
  final String avatarText;

  const ChatBubble({
    Key? key,
    required this.message,
    this.showAvatar = false,
    this.avatarText = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bubbleColor =
        message.isUser
            ? AppTheme.accentPurple.withOpacity(0.6)
            : (hasCharacterCard()
                ? AppTheme.deepIndigo.withOpacity(0.7)
                : Colors.black.withOpacity(0.4));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser && showAvatar) _buildAvatar(),
          if (!message.isUser && showAvatar) const SizedBox(width: 8),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
                maxHeight:
                    hasCharacterCard()
                        ? MediaQuery.of(context).size.height * 0.5
                        : double.infinity,
              ),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft:
                      message.isUser
                          ? const Radius.circular(16)
                          : const Radius.circular(4),
                  bottomRight:
                      message.isUser
                          ? const Radius.circular(4)
                          : const Radius.circular(16),
                ),
                border: Border.all(
                  color:
                      message.isUser
                          ? AppTheme.accentPurple.withOpacity(0.7)
                          : (hasCharacterCard()
                              ? AppTheme.etherealCyan.withOpacity(0.5)
                              : AppTheme.etherealCyan.withOpacity(0.3)),
                  width: hasCharacterCard() ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child:
                  message.isLoading
                      ? _buildLoadingIndicator()
                      : _buildMessageText(context),
            ),
          ),
          if (message.isUser && showAvatar) const SizedBox(width: 8),
          if (message.isUser && showAvatar) _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundColor:
          message.isUser
              ? AppTheme.accentPurple.withOpacity(0.8)
              : AppTheme.etherealCyan.withOpacity(0.8),
      child: Text(
        avatarText.isNotEmpty ? avatarText : (message.isUser ? 'You' : 'AI'),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  bool hasCharacterCard() {
    return !message.isUser &&
        message.text.contains('## CHARACTER CARD SUMMARY ##') &&
        message.text.contains('## END OF CHARACTER CARD ##');
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Thinking...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageText(BuildContext context) {
    if (hasCharacterCard()) {
      // Format the character card with sections
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Regular text before character card
          if (message.text.indexOf('## CHARACTER CARD SUMMARY ##') > 0)
            Text(
              message.text.substring(
                0,
                message.text.indexOf('## CHARACTER CARD SUMMARY ##'),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),

          // Character card header
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.etherealCyan.withOpacity(0.3),
                  AppTheme.accentPurple.withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.etherealCyan.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: AppTheme.etherealCyan,
                ),
                const SizedBox(width: 8),
                const Text(
                  'CHARACTER CARD SUMMARY',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Character card content
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Text(
              _extractCharacterCardContent(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),

          // Instructions after character card
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.etherealCyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.etherealCyan.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.etherealCyan.withOpacity(0.05),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppTheme.etherealCyan,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Instructions',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Type "agree" to confirm this character card or continue the conversation to make changes.',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Text(
      message.text,
      style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
    );
  }

  String _extractCharacterCardContent() {
    final startMarker = '## CHARACTER CARD SUMMARY ##';
    final endMarker = '## END OF CHARACTER CARD ##';

    final startIndex = message.text.indexOf(startMarker) + startMarker.length;
    final endIndex = message.text.indexOf(endMarker);

    if (startIndex < 0 || endIndex < 0 || endIndex <= startIndex) {
      return message.text; // Fallback if markers aren't found properly
    }

    return message.text.substring(startIndex, endIndex).trim();
  }
}
