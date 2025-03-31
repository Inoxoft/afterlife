// lib/features/character_interview/chat_bubble.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'message_model.dart';

class ChatBubble extends StatelessWidget {
  final Message message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser)
            Hero(
              tag: 'ai-avatar',
              child: Container(
                height: 36,
                width: 36,
                margin: const EdgeInsets.only(right: 10.0, top: 4.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.deepIndigo, Color(0xFF3D405B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.etherealCyan, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.etherealCyan.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.psychology_alt,
                    color: AppTheme.etherealCyan,
                    size: 20,
                  ),
                ),
              ),
            ),

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              decoration: BoxDecoration(
                color:
                    message.isUser
                        ? AppTheme.accentPurple.withOpacity(0.15)
                        : AppTheme.softLavender.withOpacity(0.15),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(message.isUser ? 18 : 4),
                  topRight: Radius.circular(message.isUser ? 4 : 18),
                  bottomLeft: const Radius.circular(18),
                  bottomRight: const Radius.circular(18),
                ),
                border: Border.all(
                  color:
                      message.isUser
                          ? AppTheme.accentPurple.withOpacity(0.3)
                          : AppTheme.etherealCyan.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow:
                    message.isUser
                        ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ]
                        : null,
              ),
              child:
                  message.isLoading
                      ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.etherealCyan,
                            ),
                          ),
                        ),
                      )
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!message.isUser &&
                              message.text.contains(
                                "## CHARACTER CARD SUMMARY ##",
                              ))
                            _buildCharacterCard(message.text)
                          else
                            SelectableText(
                              message.text,
                              style:
                                  message.isUser
                                      ? const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w400,
                                      )
                                      : const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w300,
                                      ),
                            ),
                        ],
                      ),
            ),
          ),

          if (message.isUser)
            Container(
              height: 36,
              width: 36,
              margin: const EdgeInsets.only(left: 10.0, top: 4.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.accentPurple, Color(0xFF7B68EE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentPurple.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCharacterCard(String text) {
    // Attempt to extract card content
    final startIndex = text.indexOf('## CHARACTER CARD SUMMARY ##');
    final endIndex = text.indexOf('## END OF CHARACTER CARD ##');
    if (startIndex == -1 || endIndex == -1) return SelectableText(text);

    final beforeCard = text.substring(0, startIndex);
    final cardContent =
        text
            .substring(
              startIndex + '## CHARACTER CARD SUMMARY ##'.length,
              endIndex,
            )
            .trim();
    final afterCard = text.substring(
      endIndex + '## END OF CHARACTER CARD ##'.length,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (beforeCard.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SelectableText(beforeCard),
          ),

        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.deepIndigo, Color(0xFF3D4366)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.etherealCyan.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.etherealCyan.withOpacity(0.1),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: SelectableText(
            cardContent,
            style: const TextStyle(color: Colors.white, height: 1.5),
          ),
        ),

        if (afterCard.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: SelectableText(afterCard),
          ),
      ],
    );
  }
}
