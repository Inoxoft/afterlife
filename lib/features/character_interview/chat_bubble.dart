// lib/features/character_interview/chat_bubble.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'message_model.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  
  const ChatBubble({Key? key, required this.message}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser)
            Container(
              height: 36,
              width: 36,
              margin: const EdgeInsets.only(right: 8.0, top: 4.0),
              decoration: BoxDecoration(
                color: AppTheme.deepIndigo,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.etherealCyan, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.etherealCyan.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
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
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: message.isUser
                    ? AppTheme.deepIndigo
                    : AppTheme.softLavender.withOpacity(0.15),
                borderRadius: BorderRadius.circular(18),
                boxShadow: message.isUser
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        )
                      ]
                    : null,
              ),
              child: message.isLoading
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.etherealCyan.withOpacity(0.7),
                        ),
                      ),
                    )
                  : Text(
                      message.text,
                      style: message.isUser
                          ? const TextStyle(color: Colors.white)
                          : const TextStyle(color: Colors.white),
                    ),
            ),
          ),
          
          if (message.isUser)
            Container(
              height: 36,
              width: 36,
              margin: const EdgeInsets.only(left: 8.0, top: 4.0),
              decoration: BoxDecoration(
                color: AppTheme.etherealCyan.withOpacity(0.2),
                shape: BoxShape.circle,
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
}
