import 'dart:convert';
import 'famous_character_prompts.dart';

/// Utility class to clean up encoding issues in text
class TextCleaner {
  /// Process all character prompts to fix encoding issues
  static void cleanAllPrompts() {
    // Process each character's system prompt
    FamousCharacterPrompts.prompts.forEach((characterName, data) {
      if (data['systemPrompt'] != null) {
        final cleanedPrompt = _cleanText(data['systemPrompt']!);
        // Update the data directly since there's no update method
        FamousCharacterPrompts.prompts[characterName]!['systemPrompt'] =
            cleanedPrompt;
      }

      if (data['shortBio'] != null) {
        final cleanedBio = _cleanText(data['shortBio']!);
        // Update the data directly since there's no update method
        FamousCharacterPrompts.prompts[characterName]!['shortBio'] = cleanedBio;
      }
    });

    print('All character prompts have been cleaned');
  }

  /// Clean a text by removing or replacing problematic characters
  static String _cleanText(String text) {
    // Replace common problematic characters
    String cleaned = text
        // Fix common encoding issues
        .replaceAll('Ã¡', 'á')
        .replaceAll('Ã©', 'é')
        .replaceAll('Ã­', 'í')
        .replaceAll('Ã³', 'ó')
        .replaceAll('Ãº', 'ú')
        .replaceAll('Ã¤', 'ä')
        .replaceAll('Ã¨', 'è')
        .replaceAll('Ã¬', 'ì')
        .replaceAll('Ã²', 'ò')
        .replaceAll('Ã¹', 'ù')
        .replaceAll('Ã±', 'ñ')
        .replaceAll('Ã¼', 'ü')
        .replaceAll('Ã¶', 'ö')
        // Fix common typographic characters
        .replaceAll('â€œ', '"')
        .replaceAll('â€', '"')
        .replaceAll('â€™', "'")
        .replaceAll('â€"', '-')
        .replaceAll('â€"', '-')
        .replaceAll('Â', '')
        // Fix other common issues
        .replaceAll('Ä', 'A')
        .replaceAll('ã', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ï¿½', '')
        .replaceAll('MariÄ', 'Marie')
        .replaceAll('LÃ¶wenthal', 'Lowenthal');

    // Remove any remaining non-standard characters
    cleaned = _removeNonStandardChars(cleaned);

    return cleaned;
  }

  /// Remove any remaining non-standard characters that might cause issues
  static String _removeNonStandardChars(String text) {
    // Keep only standard ASCII characters, basic punctuation, and common symbols
    return text.replaceAll(RegExp(r'[^\x00-\x7F]'), '');
  }

  /// Clean text for public use
  static String cleanText(String text) {
    return _cleanText(text);
  }

  /// Run the cleaner when the app starts
  static void initializeCleaner() {
    cleanAllPrompts();
    print('Text cleaner initialized');
  }
}
