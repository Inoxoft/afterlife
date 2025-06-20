import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_utils.dart';

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
    final fontScale = ResponsiveUtils.getFontSizeScale(context);
    final maxWidthFactor = ResponsiveUtils.getChatMessageMaxWidthFactor(context);
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16.0 * fontScale, 
        vertical: 8.0 * fontScale,
      ),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser && showAvatar) ...[
            Container(
              width: 32 * fontScale,
              height: 32 * fontScale,
              margin: EdgeInsets.only(right: 8.0 * fontScale),
              decoration: BoxDecoration(
                color: AppTheme.warmGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16 * fontScale),
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
                    fontSize: 12 * fontScale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * maxWidthFactor,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? AppTheme.warmGold.withOpacity(0.1)
                    : AppTheme.midnightPurple.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16 * fontScale),
                border: Border.all(
                  color: AppTheme.warmGold.withOpacity(0.3),
                  width: 1,
                ),
              ),
              padding: EdgeInsets.all(12 * fontScale),
              child: _buildMessageContent(context),
            ),
          ),
          if (isUser && showAvatar) ...[
            Container(
              width: 32 * fontScale,
              height: 32 * fontScale,
              margin: EdgeInsets.only(left: 8.0 * fontScale),
              decoration: BoxDecoration(
                color: AppTheme.warmGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16 * fontScale),
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
                    fontSize: 12 * fontScale,
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
    final fontScale = ResponsiveUtils.getFontSizeScale(context);
    
    // Check if this is a character card
    if (text.contains('## CHARACTER CARD SUMMARY ##') && text.contains('## END OF CHARACTER CARD ##')) {
      return _buildCharacterCard(context);
    }

    // Regular message
    return SelectableText(
      text,
      style: TextStyle(
        color: AppTheme.silverMist,
        fontSize: 14 * fontScale,
        height: 1.6,
      ),
    );
  }

  Widget _buildCharacterCard(BuildContext context) {
    final fontScale = ResponsiveUtils.getFontSizeScale(context);
    
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
        borderRadius: BorderRadius.circular(12 * fontScale),
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
            padding: EdgeInsets.symmetric(
              vertical: 12 * fontScale, 
              horizontal: 16 * fontScale,
            ),
            decoration: BoxDecoration(
              color: AppTheme.warmGold.withOpacity(0.15),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(11 * fontScale),
              ),
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
                fontSize: 18 * fontScale,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Card sections
          Padding(
            padding: EdgeInsets.all(16 * fontScale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sections.map((section) => _buildSection(section, fontScale)).toList(),
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

  Widget _buildSection(Map<String, String> section, double fontScale) {
    final title = section['title'] ?? '';
    final content = section['content'] ?? '';
    
    return Padding(
      padding: EdgeInsets.only(bottom: 16 * fontScale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          if (title.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: 8 * fontScale, 
                horizontal: 12 * fontScale,
              ),
              margin: EdgeInsets.only(bottom: 8 * fontScale),
              decoration: BoxDecoration(
                color: AppTheme.warmGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6 * fontScale),
                border: Border.all(
                  color: AppTheme.warmGold.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                title,
                style: TextStyle(
                  color: AppTheme.warmGold,
                  fontSize: 15 * fontScale,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          // Section content
          Padding(
            padding: EdgeInsets.only(left: 8 * fontScale),
            child: SelectableText(
              _formatContent(content),
              style: TextStyle(
                color: AppTheme.silverMist,
                fontSize: 14 * fontScale,
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