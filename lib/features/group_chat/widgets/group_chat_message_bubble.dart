import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../chat/models/message_status.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/ukrainian_font_utils.dart';
import '../models/group_chat_message.dart';

class GroupChatMessageBubble extends StatelessWidget {
  final GroupChatMessage message;
  final bool showAvatar;
  final bool showTimestamp;
  final bool showCharacterName;
  final VoidCallback? onRetry;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const GroupChatMessageBubble({
    super.key,
    required this.message,
    this.showAvatar = true,
    this.showTimestamp = true,
    this.showCharacterName = true,
    this.onRetry,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final fontScale = ResponsiveUtils.getFontSizeScale(context);
    final maxWidthFactor = ResponsiveUtils.getChatMessageMaxWidthFactor(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16.0 * fontScale,
        vertical: 6.0 * fontScale,
      ),
      child: Row(
        mainAxisAlignment: message.isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Character avatar (left side for non-user messages)
          if (!message.isUser && showAvatar) ...[
            _buildCharacterAvatar(fontScale),
            SizedBox(width: 8.0 * fontScale),
          ],
          
          // Message content
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * maxWidthFactor,
              ),
              child: Column(
                crossAxisAlignment: message.isUser 
                    ? CrossAxisAlignment.end 
                    : CrossAxisAlignment.start,
                children: [
                  // Character name (for non-user messages)
                  if (!message.isUser && showCharacterName) 
                    _buildCharacterNameHeader(fontScale),
                  
                  // Message bubble
                  GestureDetector(
                    onTap: onTap,
                    onLongPress: onLongPress,
                    child: _buildMessageBubble(context, fontScale),
                  ),
                  
                  // Timestamp and status
                  if (showTimestamp || message.status != MessageStatus.sent)
                    _buildMessageFooter(fontScale),
                ],
              ),
            ),
          ),
          
          // User avatar (right side for user messages)
          if (message.isUser && showAvatar) ...[
            SizedBox(width: 8.0 * fontScale),
            _buildUserAvatar(fontScale),
          ],
        ],
      ),
    );
  }

  Widget _buildCharacterAvatar(double fontScale) {
    final avatarSize = 40.0 * fontScale;
    
    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        color: AppTheme.warmGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(avatarSize / 2),
        border: Border.all(
          color: AppTheme.warmGold.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.warmGold.withValues(alpha: 0.2),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(avatarSize / 2),
        child: message.characterAvatarUrl != null
            ? Image.asset(
                message.characterAvatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildAvatarFallback(fontScale);
                },
              )
            : _buildAvatarFallback(fontScale),
      ),
    );
  }

  Widget _buildUserAvatar(double fontScale) {
    final avatarSize = 32.0 * fontScale;
    
    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        color: AppTheme.warmGold.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(avatarSize / 2),
        border: Border.all(
          color: AppTheme.warmGold.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          'You'.substring(0, 1),
          style: UkrainianFontUtils.latoWithUkrainianSupport(
            text: 'You',
            fontSize: 14 * fontScale,
            fontWeight: FontWeight.bold,
            color: AppTheme.warmGold,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(double fontScale) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.warmGold.withValues(alpha: 0.3),
            AppTheme.warmGold.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Center(
        child: Text(
          message.characterAvatarText ?? message.characterName.substring(0, 1),
          style: UkrainianFontUtils.latoWithUkrainianSupport(
            text: message.characterAvatarText ?? message.characterName,
            fontSize: 16 * fontScale,
            fontWeight: FontWeight.bold,
            color: AppTheme.warmGold,
          ),
        ),
      ),
    );
  }

  Widget _buildCharacterNameHeader(double fontScale) {
    return Padding(
      padding: EdgeInsets.only(
        left: 12.0 * fontScale,
        bottom: 4.0 * fontScale,
      ),
      child: Text(
        message.characterName,
        style: UkrainianFontUtils.latoWithUkrainianSupport(
          text: message.characterName,
          fontSize: 12 * fontScale,
          fontWeight: FontWeight.bold,
          color: AppTheme.warmGold,
        ),
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, double fontScale) {
    final isError = message.status == MessageStatus.error;
    final isSending = message.status == MessageStatus.sending;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _getBubbleColor(isError),
        borderRadius: _getBubbleBorderRadius(fontScale),
        border: Border.all(
          color: _getBorderColor(isError),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepNavy.withValues(alpha: 0.3),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Message content
          Padding(
            padding: EdgeInsets.all(12 * fontScale),
            child: _buildMessageContent(context, fontScale),
          ),
          
          // Loading indicator overlay
          if (isSending)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.deepNavy.withValues(alpha: 0.1),
                  borderRadius: _getBubbleBorderRadius(fontScale),
                ),
                child: Center(
                  child: SizedBox(
                    width: 16 * fontScale,
                    height: 16 * fontScale,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.warmGold.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ),
          
          // Retry button for errors
          if (isError && onRetry != null)
            Positioned(
              bottom: 4,
              right: 4,
              child: GestureDetector(
                onTap: onRetry,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.errorColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.refresh,
                    size: 16 * fontScale,
                    color: AppTheme.errorColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, double fontScale) {
    // Check if this is a character card
    if (message.content.contains('## CHARACTER CARD SUMMARY ##') &&
        message.content.contains('## END OF CHARACTER CARD ##')) {
      return _buildCharacterCard(context, fontScale);
    }

    // Regular message
    return SelectableText(
      message.content,
      style: UkrainianFontUtils.latoWithUkrainianSupport(
        text: message.content,
        fontSize: 14 * fontScale,
        color: AppTheme.silverMist,
        height: 1.5,
      ),
    );
  }

  Widget _buildCharacterCard(BuildContext context, double fontScale) {
    // This is a simplified version - can be enhanced later
    return Container(
      padding: EdgeInsets.all(12 * fontScale),
      decoration: BoxDecoration(
        color: AppTheme.warmGold.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8 * fontScale),
        border: Border.all(
          color: AppTheme.warmGold.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 16 * fontScale,
                color: AppTheme.warmGold,
              ),
              SizedBox(width: 8 * fontScale),
              Text(
                'Character Card',
                style: UkrainianFontUtils.latoWithUkrainianSupport(
                  text: 'Character Card',
                  fontSize: 12 * fontScale,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.warmGold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8 * fontScale),
          Text(
            'Character information has been generated.',
            style: UkrainianFontUtils.latoWithUkrainianSupport(
              text: 'Character information has been generated.',
              fontSize: 12 * fontScale,
              color: AppTheme.silverMist.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageFooter(double fontScale) {
    return Padding(
      padding: EdgeInsets.only(
        top: 4.0 * fontScale,
        left: message.isUser ? 0 : 12.0 * fontScale,
        right: message.isUser ? 12.0 * fontScale : 0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timestamp
          if (showTimestamp) ...[
            Text(
              _formatTimestamp(message.timestamp),
              style: UkrainianFontUtils.latoWithUkrainianSupport(
                text: _formatTimestamp(message.timestamp),
                fontSize: 10 * fontScale,
                color: AppTheme.silverMist.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(width: 4 * fontScale),
          ],
          
          // Status indicator
          _buildStatusIndicator(fontScale),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(double fontScale) {
    switch (message.status) {
      case MessageStatus.sending:
        return SizedBox(
          width: 12 * fontScale,
          height: 12 * fontScale,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: AppTheme.warmGold.withValues(alpha: 0.7),
          ),
        );
      
      case MessageStatus.sent:
        return Icon(
          Icons.check,
          size: 12 * fontScale,
          color: AppTheme.warmGold.withValues(alpha: 0.7),
        );
      
      case MessageStatus.error:
        return Icon(
          Icons.error_outline,
          size: 12 * fontScale,
          color: AppTheme.errorColor,
        );
      
      case MessageStatus.typing:
      case MessageStatus.characterTyping:
      case MessageStatus.multipleTyping:
      case MessageStatus.characterResponding:
      case MessageStatus.queuedForResponse:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12 * fontScale,
              height: 12 * fontScale,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppTheme.warmGold.withValues(alpha: 0.5),
              ),
            ),
            SizedBox(width: 4 * fontScale),
            Text(
              message.status.displayText,
              style: UkrainianFontUtils.latoWithUkrainianSupport(
                text: message.status.displayText,
                fontSize: 9 * fontScale,
                color: AppTheme.silverMist.withValues(alpha: 0.5),
              ),
            ),
          ],
        );
      
      default:
        return const SizedBox.shrink();
    }
  }

  Color _getBubbleColor(bool isError) {
    if (isError) {
      return AppTheme.errorColor.withValues(alpha: 0.1);
    }
    
    return message.isUser
        ? AppTheme.warmGold.withValues(alpha: 0.1)
        : AppTheme.midnightPurple.withValues(alpha: 0.4);
  }

  Color _getBorderColor(bool isError) {
    if (isError) {
      return AppTheme.errorColor.withValues(alpha: 0.3);
    }
    
    return AppTheme.warmGold.withValues(alpha: 0.3);
  }

  BorderRadius _getBubbleBorderRadius(double fontScale) {
    final radius = 16.0 * fontScale;
    
    if (message.isUser) {
      return BorderRadius.only(
        topLeft: Radius.circular(radius),
        topRight: Radius.circular(4 * fontScale),
        bottomLeft: Radius.circular(radius),
        bottomRight: Radius.circular(radius),
      );
    } else {
      return BorderRadius.only(
        topLeft: Radius.circular(4 * fontScale),
        topRight: Radius.circular(radius),
        bottomLeft: Radius.circular(radius),
        bottomRight: Radius.circular(radius),
      );
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }
}

/// Typing indicator widget for group chats
class GroupChatTypingIndicator extends StatefulWidget {
  final Set<String> typingCharacterNames;
  final double fontScale;

  const GroupChatTypingIndicator({
    super.key,
    required this.typingCharacterNames,
    this.fontScale = 1.0,
  });

  @override
  State<GroupChatTypingIndicator> createState() => _GroupChatTypingIndicatorState();
}

class _GroupChatTypingIndicatorState extends State<GroupChatTypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Align(
        alignment: Alignment.centerLeft,
        widthFactor: 1.0,
        heightFactor: 1.0,
        child: Container(
          margin: EdgeInsets.only(
            left: 16.0 * widget.fontScale,
            bottom: 6.0 * widget.fontScale,
          ),
          width: 10 * widget.fontScale,
          height: 10 * widget.fontScale,
          decoration: BoxDecoration(
            color: AppTheme.warmGold.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(2 * widget.fontScale),
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
    );
  }

  // Previous implementations for avatars/dots/text were removed to keep
  // the indicator minimal and non-intrusive per new UI requirement.
}