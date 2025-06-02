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
    // Preserve Ukrainian characters explicitly
    if (text.contains('і') || text.contains('ї')) {
      // Store Ukrainian characters temporarily
      final ukrainianChars = <int, String>{};
      int index = 0;
      
      // Replace Ukrainian characters with placeholders
      String tempText = text;
      for (int i = 0; i < text.length; i++) {
        if (text[i] == 'і' || text[i] == 'ї') {
          final placeholder = '___UKRAINIAN_${index}___';
          ukrainianChars[index] = text[i];
          tempText = tempText.replaceFirst(text[i], placeholder);
          index++;
        }
      }
      
      // Process the text normally
      String cleaned = tempText;
      
      // Apply normal cleaning
      cleaned = _applyCleaning(cleaned);
      
      // Restore Ukrainian characters
      ukrainianChars.forEach((idx, char) {
        cleaned = cleaned.replaceFirst('___UKRAINIAN_${idx}___', char);
      });
      
      return cleaned;
    }
    
    // Normal processing for non-Ukrainian text
    return _applyCleaning(text);
  }
  
  /// Apply standard text cleaning operations
  static String _applyCleaning(String text) {
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

    // DO NOT remove Unicode characters - preserve international text
    // cleaned = _removeNonStandardChars(cleaned);

    return cleaned;
  }

  /// Remove only problematic control characters while preserving Unicode
  static String _removeProblematicChars(String text) {
    // Remove only control characters and problematic sequences
    // Preserve all Unicode characters for international languages
    return text
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '') // Control chars
        .replaceAll(RegExp(r'[^\S ]+'), ' ') // Multiple whitespace to single space
        .trim();
  }

  /// Clean text for public use
  static String cleanText(String text) {
    return _cleanText(text);
  }

  /// Run the cleaner when the app starts
  static void initializeCleaner() {
    cleanAllPrompts();
    print('Text cleaner initialized - Unicode characters preserved');
  }
}
