import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/chat_message.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/ukrainian_font_utils.dart';
import '../models/chat_message.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showAvatar;
  final String? avatarText;
  final IconData? avatarIcon;
  final bool showTimestamp;

  const ChatMessageBubble({
    Key? key,
    required this.message,
    this.showAvatar = true,
    this.avatarText,
    this.avatarIcon,
    this.showTimestamp = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser && showAvatar) ...[
            _buildAvatar(),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? AppTheme.warmGold.withOpacity(0.1)
                        : AppTheme.midnightPurple.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: message.isUser
                          ? AppTheme.warmGold.withOpacity(0.3)
                          : AppTheme.silverMist.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    message.content,
                    style: UkrainianFontUtils.latoWithUkrainianSupport(
                      text: message.content,
                      color: message.isUser
                          ? AppTheme.warmGold
                          : AppTheme.silverMist,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
                if (showTimestamp)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                    child: Text(
                      DateFormat('HH:mm').format(message.timestamp),
                      style: TextStyle(
                        color: AppTheme.silverMist.withOpacity(0.5),
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (message.isUser && showAvatar) ...[
            const SizedBox(width: 8),
            _buildAvatar(),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppTheme.midnightPurple,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.warmGold.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: avatarIcon != null
          ? Icon(
              avatarIcon,
              color: AppTheme.warmGold,
              size: 18,
            )
          : Center(
              child: Text(
                avatarText ?? (message.isUser ? 'You' : 'AI'),
                style: UkrainianFontUtils.latoWithUkrainianSupport(
                  text: avatarText ?? (message.isUser ? 'You' : 'AI'),
                  color: AppTheme.warmGold,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    );
  }
} 