import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/character_model.dart';
import 'models/group_chat_message.dart';

/// Analyzes personality dynamics between characters for more natural conversations
class PersonalityDynamicsAnalyzer {
  // Personality trait keywords for analysis
  static const Map<String, List<String>> personalityTraits = {
    'intellectual': ['science', 'philosophy', 'theory', 'logic', 'knowledge', 'research', 'analytical'],
    'emotional': ['passionate', 'empathetic', 'sensitive', 'caring', 'dramatic', 'emotional'],
    'dominant': ['leader', 'commanding', 'authoritative', 'powerful', 'control', 'emperor', 'ruler'],
    'creative': ['artistic', 'imaginative', 'creative', 'aesthetic', 'beauty', 'innovative'],
    'philosophical': ['meaning', 'existence', 'truth', 'wisdom', 'spiritual', 'contemplative'],
    'practical': ['realistic', 'pragmatic', 'practical', 'efficient', 'focused', 'organized'],
    'rebellious': ['revolutionary', 'challenger', 'rebel', 'nonconformist', 'independent'],
    'diplomatic': ['diplomatic', 'peaceful', 'negotiator', 'mediator', 'harmonious']
  };

  // Conflict triggers based on personality combinations
  static const Map<String, List<String>> conflictTriggers = {
    'intellectual_vs_emotional': ['logic vs feeling', 'rational vs intuitive'],
    'dominant_vs_dominant': ['authority clash', 'power struggle'],
    'practical_vs_philosophical': ['action vs contemplation', 'concrete vs abstract'],
    'rebellious_vs_traditional': ['innovation vs tradition', 'change vs stability']
  };

  /// Analyze personality compatibility between characters
  static Map<String, dynamic> analyzePersonalityCompatibility(
    CharacterModel character1,
    CharacterModel character2,
  ) {
    final traits1 = extractPersonalityTraits(character1);
    final traits2 = extractPersonalityTraits(character2);

    final compatibility = _calculateCompatibilityScore(traits1, traits2);
    final conflictPotential = _calculateConflictPotential(traits1, traits2);
    final agreementPotential = _calculateAgreementPotential(traits1, traits2);

    return {
      'compatibility': compatibility,
      'conflictPotential': conflictPotential,
      'agreementPotential': agreementPotential,
      'dominantTraits1': traits1,
      'dominantTraits2': traits2,
      'interactionStyle': _determineInteractionStyle(traits1, traits2),
      'debateLikelihood': _calculateDebateLikelihood(traits1, traits2),
    };
  }

  /// Extract dominant personality traits from character
  static List<String> extractPersonalityTraits(CharacterModel character) {
    final characterText = '${character.name} ${character.systemPrompt}'.toLowerCase();
    final extractedTraits = <String>[];

    for (final traitEntry in personalityTraits.entries) {
      final traitName = traitEntry.key;
      final keywords = traitEntry.value;

      double traitScore = 0.0;
      for (final keyword in keywords) {
        if (characterText.contains(keyword)) {
          traitScore += 1.0;
        }
      }

      // Normalize score and add if significant
      final normalizedScore = traitScore / keywords.length;
      if (normalizedScore > 0.3) { // Threshold for trait presence
        extractedTraits.add(traitName);
      }
    }

    return extractedTraits;
  }

  /// Calculate overall compatibility score (0.0 to 1.0)
  static double _calculateCompatibilityScore(List<String> traits1, List<String> traits2) {
    if (traits1.isEmpty || traits2.isEmpty) return 0.5;

    final commonTraits = traits1.where((trait) => traits2.contains(trait)).length;
    final totalUniqueTraits = {...traits1, ...traits2}.length;

    return totalUniqueTraits > 0 ? commonTraits / totalUniqueTraits : 0.5;
  }

  /// Calculate conflict potential (0.0 to 1.0)
  static double _calculateConflictPotential(List<String> traits1, List<String> traits2) {
    double conflictScore = 0.0;

    // Check for dominant personalities clash
    if (traits1.contains('dominant') && traits2.contains('dominant')) {
      conflictScore += 0.4;
    }

    // Check for intellectual vs emotional clash
    if ((traits1.contains('intellectual') && traits2.contains('emotional')) ||
        (traits1.contains('emotional') && traits2.contains('intellectual'))) {
      conflictScore += 0.3;
    }

    // Check for practical vs philosophical clash
    if ((traits1.contains('practical') && traits2.contains('philosophical')) ||
        (traits1.contains('philosophical') && traits2.contains('practical'))) {
      conflictScore += 0.2;
    }

    // Check for rebellious vs traditional (inferred from non-rebellious traits)
    if (traits1.contains('rebellious') && !traits2.contains('rebellious')) {
      conflictScore += 0.2;
    }

    return math.min(conflictScore, 1.0);
  }

  /// Calculate agreement potential (0.0 to 1.0)
  static double _calculateAgreementPotential(List<String> traits1, List<String> traits2) {
    double agreementScore = 0.0;

    // Similar intellectual approach
    if (traits1.contains('intellectual') && traits2.contains('intellectual')) {
      agreementScore += 0.3;
    }

    // Similar philosophical outlook
    if (traits1.contains('philosophical') && traits2.contains('philosophical')) {
      agreementScore += 0.3;
    }

    // Both creative minds
    if (traits1.contains('creative') && traits2.contains('creative')) {
      agreementScore += 0.2;
    }

    // Both diplomatic
    if (traits1.contains('diplomatic') && traits2.contains('diplomatic')) {
      agreementScore += 0.3;
    }

    return math.min(agreementScore, 1.0);
  }

  /// Determine interaction style between characters
  static String _determineInteractionStyle(List<String> traits1, List<String> traits2) {
    final conflictPotential = _calculateConflictPotential(traits1, traits2);
    final agreementPotential = _calculateAgreementPotential(traits1, traits2);

    if (conflictPotential > 0.6) {
      return 'antagonistic';
    } else if (agreementPotential > 0.6) {
      return 'harmonious';
    } else if (conflictPotential > 0.3 && agreementPotential > 0.3) {
      return 'debative';
    } else {
      return 'neutral';
    }
  }

  /// Calculate likelihood of debate/discussion (0.0 to 1.0)
  static double _calculateDebateLikelihood(List<String> traits1, List<String> traits2) {
    double debateScore = 0.0;

    // Intellectual characters tend to debate
    if (traits1.contains('intellectual') || traits2.contains('intellectual')) {
      debateScore += 0.3;
    }

    // Philosophical characters love discussions
    if (traits1.contains('philosophical') || traits2.contains('philosophical')) {
      debateScore += 0.3;
    }

    // Dominant personalities create debate
    if (traits1.contains('dominant') || traits2.contains('dominant')) {
      debateScore += 0.2;
    }

    // Some conflict potential increases debate likelihood
    final conflictPotential = _calculateConflictPotential(traits1, traits2);
    debateScore += conflictPotential * 0.3;

    return math.min(debateScore, 1.0);
  }

  /// Analyze group dynamics for all characters
  static Map<String, dynamic> analyzeGroupDynamics(
    Map<String, CharacterModel> characters,
  ) {
    final characterIds = characters.keys.toList();
    final pairwiseAnalysis = <String, Map<String, dynamic>>{};
    
    double totalConflictPotential = 0.0;
    double totalAgreementPotential = 0.0;
    double totalDebateLikelihood = 0.0;
    int pairCount = 0;

    // Analyze all character pairs
    for (int i = 0; i < characterIds.length; i++) {
      for (int j = i + 1; j < characterIds.length; j++) {
        final char1Id = characterIds[i];
        final char2Id = characterIds[j];
        final char1 = characters[char1Id]!;
        final char2 = characters[char2Id]!;

        final analysis = analyzePersonalityCompatibility(char1, char2);
        pairwiseAnalysis['${char1Id}_${char2Id}'] = analysis;

        totalConflictPotential += analysis['conflictPotential'] as double;
        totalAgreementPotential += analysis['agreementPotential'] as double;
        totalDebateLikelihood += analysis['debateLikelihood'] as double;
        pairCount++;
      }
    }

    // Calculate group averages
    final avgConflictPotential = pairCount > 0 ? totalConflictPotential / pairCount : 0.0;
    final avgAgreementPotential = pairCount > 0 ? totalAgreementPotential / pairCount : 0.0;
    final avgDebateLikelihood = pairCount > 0 ? totalDebateLikelihood / pairCount : 0.0;

    return {
      'pairwiseAnalysis': pairwiseAnalysis,
      'groupAverages': {
        'conflictPotential': avgConflictPotential,
        'agreementPotential': avgAgreementPotential,
        'debateLikelihood': avgDebateLikelihood,
      },
      'groupDynamicsType': _determineGroupDynamicsType(
        avgConflictPotential,
        avgAgreementPotential,
        avgDebateLikelihood,
      ),
      'dominantPersonalities': _identifyDominantPersonalities(characters),
    };
  }

  /// Determine overall group dynamics type
  static String _determineGroupDynamicsType(
    double conflictPotential,
    double agreementPotential,
    double debateLikelihood,
  ) {
    if (conflictPotential > 0.6) {
      return 'high_tension';
    } else if (agreementPotential > 0.6) {
      return 'harmonious';
    } else if (debateLikelihood > 0.6) {
      return 'intellectual_debate';
    } else if (conflictPotential > 0.3 && debateLikelihood > 0.3) {
      return 'dynamic_discussion';
    } else {
      return 'casual_conversation';
    }
  }

  /// Identify characters with dominant personalities
  static List<String> _identifyDominantPersonalities(
    Map<String, CharacterModel> characters,
  ) {
    final dominantCharacters = <String>[];

    for (final entry in characters.entries) {
      final traits = extractPersonalityTraits(entry.value);
      if (traits.contains('dominant')) {
        dominantCharacters.add(entry.key);
      }
    }

    return dominantCharacters;
  }

  /// Suggest response patterns based on personality analysis
  static Map<String, dynamic> suggestResponsePatterns(
    String characterId,
    Map<String, CharacterModel> characters,
    List<GroupChatMessage> recentMessages,
  ) {
    final character = characters[characterId];
    if (character == null) return {};

    // Removed unused variable in release build

    // Find characters who recently spoke
    final recentSpeakers = recentMessages
        .where((m) => !m.isUser && m.characterId != characterId)
        .map((m) => m.characterId)
        .toSet()
        .toList();

    final responsePatterns = <String, dynamic>{};

    // Analyze relationship with recent speakers
    for (final speakerId in recentSpeakers) {
      final otherCharacter = characters[speakerId];
      if (otherCharacter != null) {
        final analysis = analyzePersonalityCompatibility(character, otherCharacter);
        responsePatterns[speakerId] = {
          'shouldRespond': _shouldRespondBasedOnPersonality(analysis),
          'responseStyle': _determineResponseStyle(analysis),
          'urgency': _calculateResponseUrgency(analysis),
        };
      }
    }

    return {
      'characterTraits': extractPersonalityTraits(character),
      'responsePatterns': responsePatterns,
      'overallMood': _determineCharacterMood(character, recentMessages),
    };
  }

  /// Determine if character should respond based on personality
  static bool _shouldRespondBasedOnPersonality(Map<String, dynamic> analysis) {
    final conflictPotential = analysis['conflictPotential'] as double;
    final debateLikelihood = analysis['debateLikelihood'] as double;
    final interactionStyle = analysis['interactionStyle'] as String;

    // High conflict or debate likelihood increases response probability
    if (conflictPotential > 0.5 || debateLikelihood > 0.5) {
      return math.Random().nextDouble() < 0.8;
    }

    // Antagonistic relationships often respond
    if (interactionStyle == 'antagonistic') {
      return math.Random().nextDouble() < 0.7;
    }

    // Default probability
    return math.Random().nextDouble() < 0.4;
  }

  /// Determine response style based on personality analysis
  static String _determineResponseStyle(Map<String, dynamic> analysis) {
    final conflictPotential = analysis['conflictPotential'] as double;
    final agreementPotential = analysis['agreementPotential'] as double;
    final interactionStyle = analysis['interactionStyle'] as String;

    if (conflictPotential > 0.6) {
      return 'challenging';
    } else if (agreementPotential > 0.6) {
      return 'supportive';
    } else if (interactionStyle == 'debative') {
      return 'analytical';
    } else {
      return 'conversational';
    }
  }

  /// Calculate response urgency (0.0 to 1.0)
  static double _calculateResponseUrgency(Map<String, dynamic> analysis) {
    final conflictPotential = analysis['conflictPotential'] as double;
    final debateLikelihood = analysis['debateLikelihood'] as double;

    // High conflict = high urgency
    if (conflictPotential > 0.7) return 0.9;
    if (debateLikelihood > 0.7) return 0.8;
    if (conflictPotential > 0.4) return 0.6;

    return 0.3; // Default low urgency
  }

  /// Determine character's current mood based on recent conversation
  static String _determineCharacterMood(
    CharacterModel character,
    List<GroupChatMessage> recentMessages,
  ) {
    final traits = extractPersonalityTraits(character);
    
    // Analyze recent message sentiment (simplified)
    final recentContent = recentMessages
        .where((m) => !m.isUser)
        .take(3)
        .map((m) => m.content.toLowerCase())
        .join(' ');

    // Emotional characters react more to sentiment
    if (traits.contains('emotional')) {
      if (recentContent.contains(RegExp(r'\b(angry|furious|outraged|disagree)\b'))) {
        return 'agitated';
      } else if (recentContent.contains(RegExp(r'\b(wonderful|excellent|agree|brilliant)\b'))) {
        return 'enthusiastic';
      }
    }

    // Intellectual characters focus on ideas
    if (traits.contains('intellectual')) {
      if (recentContent.contains(RegExp(r'\b(theory|analysis|research|study)\b'))) {
        return 'engaged';
      }
    }

    // Default mood
    return 'neutral';
  }

  /// Log personality analysis for debugging
  static void logPersonalityAnalysis(
    String characterId,
    CharacterModel character,
    Map<String, dynamic> analysis,
  ) {
    if (kDebugMode) {
      
    }
  }
}
