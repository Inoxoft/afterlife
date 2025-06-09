import 'dart:math';
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
            ? AppTheme.midnightPurple.withValues(alpha: 0.6)
            : (hasCharacterCard()
                ? AppTheme.midnightPurple.withValues(alpha: 0.8)
                : AppTheme.midnightPurple.withValues(alpha: 0.5));

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
                // Don't limit height by default to avoid overflow issues
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
                          ? AppTheme.warmGold.withValues(alpha: 0.5)
                          : (hasCharacterCard()
                              ? AppTheme.warmGold.withValues(alpha: 0.7)
                              : AppTheme.warmGold.withValues(alpha: 0.4)),
                  width:
                      hasCharacterCard()
                          ? 2.0
                          : 1, // Thicker border for character cards
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        hasCharacterCard()
                            ? AppTheme.warmGold.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.1),
                    blurRadius: hasCharacterCard() ? 8 : 3,
                    spreadRadius: hasCharacterCard() ? 2 : 0,
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
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.warmGold.withValues(alpha: 0.3), width: 1),
      ),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: AppTheme.midnightPurple.withValues(alpha: 0.8),
        child: Text(
          avatarText.isNotEmpty ? avatarText : (message.isUser ? 'You' : 'AI'),
          style: TextStyle(
            color: AppTheme.warmGold,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  bool hasCharacterCard() {
    return !message.isUser &&
        message.text.contains('## CHARACTER CARD SUMMARY ##') &&
        message.text.contains('## END OF CHARACTER CARD ##');
  }

  // Extract character name from the card if available
  String _extractCharacterName() {
    final nameMarker = '## CHARACTER NAME:';
    if (message.text.contains(nameMarker)) {
      final startIndex = message.text.indexOf(nameMarker) + nameMarker.length;
      final endIndex = message.text.indexOf('\n', startIndex);
      if (endIndex > startIndex) {
        return message.text
            .substring(startIndex, endIndex)
            .trim()
            .replaceAll('##', '');
      }
    }
    return "";
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.warmGold.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Thinking...',
            style: TextStyle(
              color: AppTheme.silverMist.withValues(alpha: 0.7),
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
      // Use a fixed max height for character cards with ScrollView to handle overflow
      final cardMaxHeight = MediaQuery.of(context).size.height * 0.6;
      final characterName = _extractCharacterName();

      // Format the character card with sections
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: cardMaxHeight),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Regular text before character card
              if (message.text.indexOf('## CHARACTER CARD SUMMARY ##') > 0)
                Text(
                  _filterPreCardText(
                    message.text.substring(
                      0,
                      message.text.indexOf('## CHARACTER CARD SUMMARY ##'),
                    ),
                  ),
                  style: TextStyle(color: AppTheme.silverMist, fontSize: 15),
                ),

              // Character card header with name if available
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.warmGold.withValues(alpha: 0.4),
                      AppTheme.midnightPurple.withValues(alpha: 0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.warmGold.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 18,
                          color: AppTheme.warmGold,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'CHARACTER CARD',
                          style: TextStyle(
                            color: AppTheme.silverMist,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    if (characterName.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.midnightPurple.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.warmGold.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          characterName,
                          style: TextStyle(
                            color: AppTheme.warmGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Character card content with scrolling capability
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.midnightPurple.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.warmGold.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 5,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: _buildFormattedCardContent(),
              ),

              // Instructions after character card
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.midnightPurple.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.warmGold.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.warmGold.withValues(alpha: 0.05),
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
                          color: AppTheme.warmGold,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Instructions',
                          style: TextStyle(
                            color: AppTheme.silverMist,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Type "agree" to confirm this character card or continue the conversation to make changes.',
                      style: TextStyle(
                        color: AppTheme.silverMist,
                        fontSize: 14,
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

    // Regular text messages
    return Text(
      message.text,
      style: TextStyle(color: AppTheme.silverMist, fontSize: 15, height: 1.4),
    );
  }

  // Filter out CHARACTER NAME line from the text before the card
  String _filterPreCardText(String text) {
    final nameMarker = '## CHARACTER NAME:';
    if (text.contains(nameMarker)) {
      final startIndex = text.indexOf(nameMarker);
      final endIndex = text.indexOf('\n', startIndex);
      if (endIndex > startIndex) {
        // Remove the CHARACTER NAME line
        return text.substring(0, startIndex) + text.substring(endIndex + 1);
      }
    }
    return text;
  }

  String _extractCharacterCardContent() {
    final startMarker = '## CHARACTER CARD SUMMARY ##';
    final endMarker = '## END OF CHARACTER CARD ##';

    final startIndex = message.text.indexOf(startMarker) + startMarker.length;
    final endIndex = message.text.indexOf(endMarker);

    if (startIndex < 0 || endIndex < 0 || endIndex <= startIndex) {
      return message.text; // Fallback if markers aren't found properly
    }

    String content = message.text.substring(startIndex, endIndex).trim();

    // Process the markdown-style formatting to improve readability
    // but preserve the original formatting for extraction elsewhere
    return _formatMarkdownContent(content);
  }

  // Process markdown-style formatting to improve readability
  String _formatMarkdownContent(String content) {
    // Format section headers (###)
    content = content.replaceAllMapped(
      RegExp(r'###\s+(.*?)(?=\n|$)'),
      (match) => '\n\n${match.group(1)}\n',
    );

    // Format subsection titles (**)
    content = content.replaceAllMapped(
      RegExp(r'\*\*(.*?)\*\*'),
      (match) => '${match.group(1)}',
    );

    // Format lists
    content = content.replaceAllMapped(
      RegExp(r'^\s*-\s+(.*?)$', multiLine: true),
      (match) => '• ${match.group(1)}',
    );

    // Clean up any unnecessary markdown markers
    content = content.replaceAll(r'##', '');

    return content;
  }

  Widget _buildFormattedCardContent() {
    final content = _extractCharacterCardContent();
    return RichText(
      text: TextSpan(
        style: TextStyle(color: AppTheme.silverMist, fontSize: 14, height: 1.5),
        children: _buildFormattedTextSpans(content),
      ),
    );
  }

  List<TextSpan> _buildFormattedTextSpans(String content) {
    final List<TextSpan> spans = [];
    final lines = content.split('\n');

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];

      // Handle section headers (###)
      if (line.trim().startsWith('###')) {
        final headerText = line.replaceFirst(RegExp(r'###\s+'), '').trim();
        spans.add(
          TextSpan(
            text: headerText + '\n',
            style: TextStyle(
              color: AppTheme.warmGold,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              height: 2.0,
            ),
          ),
        );
        continue;
      }

      // Handle bold text (**)
      if (line.contains('**')) {
        List<TextSpan> lineSpans = [];
        final segments = line.split(RegExp(r'\*\*'));

        for (int j = 0; j < segments.length; j++) {
          if (j % 2 == 0) {
            lineSpans.add(TextSpan(text: segments[j]));
          } else {
            // This is the text between ** markers
            lineSpans.add(
              TextSpan(
                text: segments[j],
                style: TextStyle(
                  color: AppTheme.warmGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }
        }

        spans.add(TextSpan(children: lineSpans));
        spans.add(const TextSpan(text: '\n'));
        continue;
      }

      // Handle bullet points
      if (line.trim().startsWith('-')) {
        final bulletText = line.replaceFirst(RegExp(r'-\s+'), '').trim();
        spans.add(
          TextSpan(
            text: '• ',
            style: TextStyle(
              color: AppTheme.warmGold,
              fontWeight: FontWeight.bold,
            ),
            children: [
              TextSpan(
                text: bulletText + '\n',
                style: TextStyle(
                  color: AppTheme.silverMist,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        );
        continue;
      }

      // Regular text
      spans.add(TextSpan(text: line + '\n'));
    }

    return spans;
  }
}
