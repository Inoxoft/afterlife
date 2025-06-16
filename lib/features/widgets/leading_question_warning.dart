import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

/// Widget that displays a warning when a leading question is detected
class LeadingQuestionWarning extends StatelessWidget {
  final String warningMessage;
  final double confidence;
  final VoidCallback onContinueAnyway;
  final VoidCallback onRephrase;

  const LeadingQuestionWarning({
    Key? key,
    required this.warningMessage,
    required this.confidence,
    required this.onContinueAnyway,
    required this.onRephrase,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.midnightPurple.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getWarningColor(confidence), width: 2),
        boxShadow: [
          BoxShadow(
            color: _getWarningColor(confidence).withValues(alpha: 0.3),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Warning header
            Row(
              children: [
                Icon(
                  Icons.warning_rounded,
                  color: _getWarningColor(confidence),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Leading Question Detected',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getWarningColor(confidence),
                    ),
                  ),
                ),
                // Confidence indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getWarningColor(confidence).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(confidence * 100).toInt()}%',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getWarningColor(confidence),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Warning message
            Text(
              warningMessage,
              style: GoogleFonts.lato(
                fontSize: 14,
                color: AppTheme.silverMist,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRephrase,
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: Text(
                      'Rephrase',
                      style: GoogleFonts.lato(fontSize: 14),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.warmGold,
                      side: BorderSide(
                        color: AppTheme.warmGold.withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onContinueAnyway,
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      'Send Anyway',
                      style: GoogleFonts.lato(fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getWarningColor(
                        confidence,
                      ).withValues(alpha: 0.8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Tips section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundStart.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 Better questions:',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.warmGold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• "What was your favorite memory from...?"'
                    '\n• "How did you feel when...?"'
                    '\n• "Can you tell me about...?"',
                    style: GoogleFonts.lato(
                      fontSize: 11,
                      color: AppTheme.silverMist.withValues(alpha: 0.8),
                      height: 1.3,
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

  /// Get warning color based on confidence level
  Color _getWarningColor(double confidence) {
    if (confidence > 0.8) {
      return Colors.red;
    } else if (confidence > 0.65) {
      return Colors.orange;
    } else {
      return Colors.yellow;
    }
  }
}
