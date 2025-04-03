// lib/features/character_interview/chat_bubble.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'message_model.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final bool isLoading;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.isUser,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobileWidth = MediaQuery.of(context).size.width < 600;
    final bubbleWidth =
        isMobileWidth
            ? MediaQuery.of(context).size.width * 0.7
            : MediaQuery.of(context).size.width * 0.5;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: bubbleWidth),
          decoration: BoxDecoration(
            color:
                isUser
                    ? const Color(0xFF8B5EF0).withOpacity(0.6)
                    : (hasCharacterCard()
                        ? AppTheme.deepIndigo.withOpacity(0.7)
                        : Colors.black.withOpacity(0.4)),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft:
                  isUser ? const Radius.circular(16) : const Radius.circular(4),
              bottomRight:
                  isUser ? const Radius.circular(4) : const Radius.circular(16),
            ),
            border: Border.all(
              color:
                  isUser
                      ? const Color(0xFF8B5EF0).withOpacity(0.7)
                      : (hasCharacterCard()
                          ? AppTheme.etherealCyan.withOpacity(0.5)
                          : Colors.white.withOpacity(0.1)),
              width: hasCharacterCard() ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child:
              isLoading ? _buildLoadingIndicator() : _buildMessageText(context),
        ),
      ),
    );
  }

  bool hasCharacterCard() {
    return !isUser &&
        message.contains('## CHARACTER CARD SUMMARY ##') &&
        message.contains('## END OF CHARACTER CARD ##');
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
        ),
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
          if (message.indexOf('## CHARACTER CARD SUMMARY ##') > 0)
            Text(
              message.substring(
                0,
                message.indexOf('## CHARACTER CARD SUMMARY ##'),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),

          // Character card header
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.etherealCyan.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'CHARACTER CARD SUMMARY',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),

          // Character card content
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Text(
              _extractCharacterCardContent(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),

          // Instructions after character card
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.etherealCyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.etherealCyan.withOpacity(0.3)),
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
      message,
      style: const TextStyle(color: Colors.white, fontSize: 15),
    );
  }

  String _extractCharacterCardContent() {
    final startMarker = '## CHARACTER CARD SUMMARY ##';
    final endMarker = '## END OF CHARACTER CARD ##';

    final startIndex = message.indexOf(startMarker) + startMarker.length;
    final endIndex = message.indexOf(endMarker);

    if (startIndex < 0 || endIndex < 0 || endIndex <= startIndex) {
      return message; // Fallback if markers aren't found properly
    }

    return message.substring(startIndex, endIndex).trim();
  }
}
