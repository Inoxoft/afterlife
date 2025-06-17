import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ChatMessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool showAvatar;
  final String avatarText;
  final IconData? avatarIcon;
  final bool showTimestamp;

  const ChatMessageBubble({
    super.key,
    required this.text,
    required this.isUser,
    required this.showAvatar,
    required this.avatarText,
    this.avatarIcon,
    this.showTimestamp = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser && showAvatar) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8.0),
              decoration: BoxDecoration(
                color: AppTheme.warmGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.warmGold.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  avatarText,
                  style: TextStyle(
                    color: AppTheme.warmGold,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? AppTheme.warmGold.withOpacity(0.1)
                    : AppTheme.midnightPurple.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.warmGold.withOpacity(0.3),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: _buildMessageContent(context),
            ),
          ),
          if (isUser && showAvatar) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 8.0),
              decoration: BoxDecoration(
                color: AppTheme.warmGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.warmGold.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  avatarText,
                  style: TextStyle(
                    color: AppTheme.warmGold,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    // Check if this is a character card
    if (text.contains('## CHARACTER CARD SUMMARY ##') && text.contains('## END OF CHARACTER CARD ##')) {
      return _buildCharacterCard(context);
    }

    // Regular message
    return SelectableText(
      text,
      style: TextStyle(
        color: AppTheme.silverMist,
        fontSize: 14,
        height: 1.6,
      ),
    );
  }

  Widget _buildCharacterCard(BuildContext context) {
    // Extract character name
    final nameMarkerPattern = RegExp(r'## CHARACTER NAME: (.*?) ##');
    final nameMatch = nameMarkerPattern.firstMatch(text);
    final characterName = nameMatch?.group(1)?.trim() ?? 'Character';

    // Extract content between markers
    final summaryStart = '## CHARACTER CARD SUMMARY ##';
    final summaryEnd = '## END OF CHARACTER CARD ##';
    final startIndex = text.indexOf(summaryStart) + summaryStart.length;
    final endIndex = text.indexOf(summaryEnd);
    
    if (startIndex < summaryStart.length || endIndex <= startIndex) {
      return SelectableText('Invalid character card format');
    }

    String rawContent = text.substring(startIndex, endIndex).trim();

    // Clean up the content by removing unwanted tags and markers
    rawContent = _cleanContent(rawContent);

    // Parse sections
    final sections = _parseSections(rawContent);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.warmGold.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.warmGold.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Character name header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.warmGold.withOpacity(0.15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.warmGold.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Text(
              characterName,
              style: TextStyle(
                color: AppTheme.warmGold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Card sections
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sections.map((section) => _buildSection(section)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _cleanContent(String content) {
    // Remove HTML-like tags
    content = content.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Remove extra whitespace and normalize line breaks
    content = content.replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n');
    content = content.replaceAll(RegExp(r'^\s+', multiLine: true), '');
    
    // Remove any remaining unwanted markers
    content = content.replaceAll(RegExp(r'---\s*\n'), '\n');
    
    return content.trim();
  }

  List<Map<String, String>> _parseSections(String content) {
    List<Map<String, String>> sections = [];
    
    // Split by markdown headers (### or ##)
    final sectionPattern = RegExp(r'^#{2,3}\s+(.+?)$', multiLine: true);
    final matches = sectionPattern.allMatches(content).toList();
    
    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];
      final title = match.group(1)?.trim() ?? '';
      
      // Get content between this header and the next one
      final startIndex = match.end;
      final endIndex = i < matches.length - 1 ? matches[i + 1].start : content.length;
      final sectionContent = content.substring(startIndex, endIndex).trim();
      
      if (title.isNotEmpty && sectionContent.isNotEmpty) {
        sections.add({
          'title': title,
          'content': sectionContent,
        });
      }
    }
    
    // If no sections found, treat entire content as one section
    if (sections.isEmpty) {
      sections.add({
        'title': 'Character Summary',
        'content': content,
      });
    }
    
    return sections;
  }

  Widget _buildSection(Map<String, String> section) {
    final title = section['title'] ?? '';
    final content = section['content'] ?? '';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          if (title.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppTheme.warmGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppTheme.warmGold.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                title,
                style: TextStyle(
                  color: AppTheme.warmGold,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          // Section content
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: SelectableText(
              _formatContent(content),
              style: TextStyle(
                color: AppTheme.silverMist,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatContent(String content) {
    // Clean up bullet points and formatting
    content = content.replaceAllMapped(
      RegExp(r'^- \*\*([^*]+)\*\*', multiLine: true),
      (match) => '• ${match.group(1)}:',
    );
    content = content.replaceAllMapped(
      RegExp(r'^\*\*([^*]+)\*\*', multiLine: true),
      (match) => '${match.group(1)}:',
    );
    content = content.replaceAllMapped(
      RegExp(r'\*\*([^*]+)\*\*'),
      (match) => '${match.group(1)}',
    );
    content = content.replaceAll(RegExp(r'^\s*-\s+', multiLine: true), '• ');
    
    // Clean up extra whitespace
    content = content.replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n');
    
    return content.trim();
  }
} 