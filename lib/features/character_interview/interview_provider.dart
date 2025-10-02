import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/utils/app_logger.dart';
import 'message_model.dart';
import 'prompts.dart';
import '../providers/language_provider.dart';
import '../models/character_model.dart';
import '../../core/services/hybrid_chat_service.dart';

/// Manages the interview process for creating or editing a character.
///
/// Important: The character card summary contains markdown formatting with
/// markers (## CHARACTER CARD SUMMARY ## and ## END OF CHARACTER CARD ##)
/// for display purposes, but when saving the character, we need to extract
/// just the content between these markers as the system prompt. This ensures
/// the AI can properly role-play as the character during chat.
class InterviewProvider with ChangeNotifier {
  final List<Message> _messages = [];
  String? characterCardSummary;
  String? characterName;
  bool isLoading = false;
  bool isComplete = false;
  bool isSuccess = false;
  bool isEditMode = false;
  bool isAiThinking = false;
  // Creation mode: local vs cloud
  bool useLocalModel = false;

  // Add a reference to LanguageProvider at the class level
  LanguageProvider? _languageProvider;

  // Callback for saving characters
  Future<void> Function(CharacterModel)? _onCharacterSaved;

  List<Message> get messages => _messages.where((m) => !m.isHidden).toList();

  /// Checks if the last AI message is a valid, final character card.
  bool get isCardReadyForFinalize {
    final lastMessage = _messages.where((m) => !m.isUser).lastOrNull;
    if (lastMessage == null) return false;
    return lastMessage.text.contains('## CHARACTER CARD SUMMARY ##') &&
        lastMessage.text.contains('## END OF CHARACTER CARD ##');
  }

  InterviewProvider({Future<void> Function(CharacterModel)? onCharacterSaved}) {
    _onCharacterSaved = onCharacterSaved;
    _initialize();
  }

  Future<void> _initialize() async {
    await HybridChatService.initialize();
    // Don't add initial message here - wait for localization to be set
    // Add a fallback timer in case localization setup is delayed
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!_initialMessageAdded && !isEditMode) {
        _addInitialMessage();
      }
    });
  }

  String? _initialMessage;
  bool _initialMessageAdded = false;

  void setInitialMessage(String message) {
    _initialMessage = message;
    // Add the initial message only once, and only if not in edit mode
    if (!_initialMessageAdded && !isEditMode) {
      addAIMessage(_initialMessage!);
      _initialMessageAdded = true;
    }
  }

  Future<void> _addInitialMessage() async {
    // This method is now only used as a fallback if setInitialMessage wasn't called
    if (!isEditMode && !_initialMessageAdded) {
      final message = _initialMessage ??
          "Hello! We'll create your character card with a short, friendly interview. I'll ask three quick questions about you, your personality, and a memorable moment.\n\n"
          "Let's begin: tell me a bit about yourself — what do you do, and what matters most to you?";
      addAIMessage(message);
      _initialMessageAdded = true;
    }
  }

  void setEditMode({
    required String existingName,
    required String existingSystemPrompt,
  }) {
    isEditMode = true;
    characterName = existingName;

    // Store the existing system prompt - vital for continuing the edit flow
    characterCardSummary = existingSystemPrompt;

    // Debug the system prompt to ensure it's being loaded properly
    print(
      'First 200 chars: ${existingSystemPrompt.substring(0, min(200, existingSystemPrompt.length))}...',
    );
    print(
      'Last 200 chars: ...${existingSystemPrompt.substring(max(0, existingSystemPrompt.length - 200))}',
    );

    // Add loading message to indicate AI is thinking
    _addLoadingMessage();

    // Call the method to send the initial edit message
    _sendInitialEditMessage();
  }

  Future<void> _sendInitialEditMessage() async {
    if (!isEditMode || characterName == null) return;

    final systemPrompt = _getSystemPrompt();

    print(
      'Character card summary length: ${characterCardSummary?.length ?? 0}',
    );
    if (characterCardSummary != null && characterCardSummary!.isNotEmpty) {
      print(
        'First 200 chars of card summary: ${characterCardSummary!.substring(0, min(200, characterCardSummary!.length))}...',
      );
    } else {
              AppLogger.warning('Character card summary is null or empty', tag: 'InterviewProvider');
    }

    try {
      // Create a formatted message to send to the AI with the existing character details
      final existingCharacterInfo = """
I am providing the COMPLETE system prompt for my character. This is what we will be editing:

Character name: $characterName

===== SYSTEM PROMPT - START =====
${characterCardSummary ?? ""}
===== SYSTEM PROMPT - END =====

DO NOT ask me to send you the system prompt. I have already provided it above.

In your first response, repeat the COMPLETE system prompt and then ask me what changes I want to make.

I want to make specific edits to this system prompt. I will tell you exactly what changes I want. Please preserve all existing content unless I explicitly ask for something to be changed.

What specific edits would you like me to make?
""";

      // Add the initial message to our history but hide it from UI
      _messages.add(
        Message(text: existingCharacterInfo, isUser: true, isHidden: true),
      );
      notifyListeners();

      final response = await HybridChatService.sendMessage(
        messages:
            _convertMessagesToAPI(), // Use all messages including the initial one
        systemPrompt: systemPrompt,
      );

      // Remove loading message
      _removeLoadingMessage();

      // Add the AI response to chat
      if (response != null) {
        addAIMessage(response);
      } else {
        addAIMessage(
          "I couldn't load your character's system prompt. Please try again.",
        );
      }
    } catch (e) {
      _handleErrorState("Error sending initial edit message: $e");
    }
  }

  void setLanguageProvider(LanguageProvider languageProvider) {
    _languageProvider = languageProvider;
  }

  String _getSystemPrompt() {
    String languageInstruction = '';
    if (_languageProvider != null &&
        _languageProvider!.currentLanguageCode != 'en') {
      final languageName = _languageProvider!.currentLanguageName;
      languageInstruction =
          '\n\n### LANGUAGE INSTRUCTIONS:\nPlease respond in $languageName language. The user has selected $languageName as their preferred language.\n';
    }

    if (isEditMode) {
      return """You are helping the user edit their existing character. The user has provided their current character information and wants to make specific changes.

Your task:
- Listen carefully to what changes the user wants to make
- Help the user edit the system prompt they've already provided
- Make only the specific changes they request
- Preserve all content they don't explicitly ask to change
- When edits are requested, show the full updated system prompt with changes highlighted

### Formatting Final Result:
When the user types "agree", format the final prompt as:
```
## CHARACTER NAME: [character name] ##
## CHARACTER CARD SUMMARY ##
[FULL UPDATED SYSTEM PROMPT WITH ALL CHANGES]
## END OF CHARACTER CARD ##
```$languageInstruction""";
    } else {
      final base = useLocalModel
          ? InterviewPrompts.localInterviewSystemPrompt
          : InterviewPrompts.interviewSystemPrompt;
      return base + languageInstruction;
    }
  }

  String _getSystemPromptForEditing() {
    String languageInstruction = '';
    if (_languageProvider != null &&
        _languageProvider!.currentLanguageCode != 'en') {
      final languageName = _languageProvider!.currentLanguageName;
      languageInstruction =
          '\n\n### LANGUAGE INSTRUCTIONS:\nPlease respond in $languageName language. The user has selected $languageName as their preferred language.\n';
    }

    return """You are helping the user modify their character card. They have a complete character card but want to make changes to it.

CURRENT CHARACTER CARD:
$characterCardSummary

Your task:
- Listen to the user's requested changes
- Modify only the specific aspects they mention
- Keep everything else exactly the same
- Maintain the character's core identity while incorporating the requested changes
- Be precise with the modifications - don't change unrelated parts

### Important Instructions:
- If the user asks to change personality traits, update only those traits
- If they want to modify background/history, change only the relevant sections
- If they request name changes, update the character name accordingly
- Always preserve the overall character structure and format

### Formatting Updated Result:
When providing the updated character card, format it as:
```
## CHARACTER NAME: [updated character name] ##
## CHARACTER CARD SUMMARY ##
[FULL UPDATED CHARACTER CARD WITH REQUESTED CHANGES]
## END OF CHARACTER CARD ##
```

After showing the updated card, ask the user to review it and type 'agree' if they're satisfied, or request further changes if needed.

$languageInstruction""";
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    addMessage(content: text, isUser: true);
    _addLoadingMessage();

    try {
      // Debug logging
      print('🔍 DEBUG: User typed: "${text.trim()}"');
      print('🔍 DEBUG: Lowercased: "${text.trim().toLowerCase()}"');
      print(
        '🔍 DEBUG: characterCardSummary is null: ${characterCardSummary == null}',
      );
      print('🔍 DEBUG: characterName is null: ${characterName == null}');
      print('🔍 DEBUG: isComplete: $isComplete');

      // Check if user typed "agree" and character card is ready
      if (text.trim().toLowerCase() == 'agree' &&
          characterCardSummary != null &&
          characterName != null &&
          isComplete) {
        _removeLoadingMessage();

        // Create and save the character
        await _saveCharacterToDevice();

        // Add artificial delay to simulate natural conversation flow
        await Future.delayed(const Duration(milliseconds: 800));

        addAIMessage(
          "Perfect! Your character '$characterName' has been saved successfully. "
          "You can now find them in your \"Your Twins\" tab and start chatting immediately!\n\n"
          "Use the button below when you're ready to continue.",
        );

        // Mark as success for navigation (but don't auto-navigate)
        isSuccess = true;
        notifyListeners();
        return;
      }

      // Alternative check for "agree" when we have character card but maybe missing name
      if (text.trim().toLowerCase() == 'agree' &&
          characterCardSummary != null &&
          isComplete) {
        // Try to extract name from character card summary if not already set
        if (characterName == null) {
          // Try multiple patterns for character name extraction
          final namePatterns = [
            RegExp(r'## CHARACTER NAME:\s*(.*?)\s*##', caseSensitive: false),
            RegExp(r'Character\s*Name:\s*(.*?)(?:\n|\.)', caseSensitive: false),
            RegExp(r'Name:\s*(.*?)(?:\n|\.)', caseSensitive: false),
            RegExp(r'I am\s+([A-Z][a-zA-Z\s]+)', caseSensitive: false),
            RegExp(r'You are\s+([A-Z][a-zA-Z\s]+)', caseSensitive: false),
          ];

          for (final pattern in namePatterns) {
            final match = pattern.firstMatch(characterCardSummary!);
            if (match != null && match.group(1) != null) {
              characterName = match.group(1)!.trim();
              break;
            }
          }

          // If still no name found, use a default
          if (characterName == null) {
            characterName =
                "Character_${DateTime.now().millisecondsSinceEpoch}";
          }
        }

        _removeLoadingMessage();

        // Create and save the character
        await _saveCharacterToDevice();

        // Add artificial delay to simulate natural conversation flow
        await Future.delayed(const Duration(milliseconds: 800));

        addAIMessage(
          "Perfect! Your character '$characterName' has been saved successfully. "
          "You can now find them in your \"Your Twins\" tab and start chatting immediately!\n\n"
          "Use the button below when you're ready to continue.",
        );

        // Mark as success for navigation (but don't auto-navigate)
        isSuccess = true;
        notifyListeners();
        return;
      }

      // Regular message handling
      if (isComplete && !isSuccess) {
        // We have a character card but user wants to make changes
        final systemPrompt = _getSystemPromptForEditing();

        final response = await HybridChatService.sendMessage(
          messages: _convertMessagesToAPI(), // Convert all messages for context
          systemPrompt: systemPrompt,
          preferredProvider: useLocalModel ? LLMProvider.local : LLMProvider.openRouter,
        );

        // Add artificial delay to simulate natural conversation flow
        await Future.delayed(const Duration(milliseconds: 800));

        _removeLoadingMessage();
        if (response != null) {
          // Check if response contains API key error message
          if (response.contains("Unable to connect to AI service")) {
            _handleApiConfigurationError();
            return;
          }

          addAIMessage(response);

          // Check if this AI response contains an updated character card
          if (response.contains('## CHARACTER CARD SUMMARY ##') &&
              response.contains('## END OF CHARACTER CARD ##')) {
            characterCardSummary = response;

            // Try to extract character name if present
            final namePattern = RegExp(r'## CHARACTER NAME: (.*?) ##');
            final nameMatch = namePattern.firstMatch(response);
            if (nameMatch != null && nameMatch.group(1) != null) {
              characterName = nameMatch.group(1)!.trim();
            }

            // Keep as complete since we have an updated character card
            isComplete = true;
            // Prompt user to confirm or request changes, matching file flow
            addAIMessage(
              "Great! I've updated your character card. Review it above and:\n\n"
              "• Type 'agree' to save your character\n"
              "• Or describe any changes you'd like me to make",
            );
            notifyListeners();
          }
        } else {
          _handleApiConfigurationError();
        }
      } else if (isComplete && isSuccess) {
        // We're in chat mode with the character
        final response = await HybridChatService.sendMessage(
          messages: [
            {"role": "user", "content": text},
          ],
          systemPrompt: characterCardSummary ?? "",
          preferredProvider: useLocalModel ? LLMProvider.local : LLMProvider.openRouter,
        );

        // Add artificial delay to simulate natural conversation flow
        await Future.delayed(const Duration(milliseconds: 800));

        _removeLoadingMessage();
        if (response != null) {
          addAIMessage(response);
        } else {
          _handleApiConfigurationError();
        }
      } else {
        // We're still in interview mode
        final systemPrompt = _getSystemPrompt();

        final response = await HybridChatService.sendMessage(
          messages: _convertMessagesToAPI(), // Convert all messages for context
          systemPrompt: systemPrompt,
          preferredProvider: useLocalModel ? LLMProvider.local : LLMProvider.openRouter,
        );

        // Add artificial delay to simulate natural conversation flow
        await Future.delayed(const Duration(milliseconds: 800));

        _removeLoadingMessage();
        if (response != null) {
          // Check if response contains API key error message
          if (response.contains("Unable to connect to AI service")) {
            _handleApiConfigurationError();
            return;
          }

          addAIMessage(response);

          // Check if this AI response contains a character card
          if (response.contains('## CHARACTER CARD SUMMARY ##') &&
              response.contains('## END OF CHARACTER CARD ##')) {
            characterCardSummary = response;

            // Try to extract character name if present
            final namePattern = RegExp(r'## CHARACTER NAME: (.*?) ##');
            final nameMatch = namePattern.firstMatch(response);
            if (nameMatch != null && nameMatch.group(1) != null) {
              characterName = nameMatch.group(1)!.trim();
            }

            // Mark as complete since AI generated the character card
            isComplete = true;
            // Prompt user to confirm or request changes, matching file flow
            addAIMessage(
              "Perfect! I've created your character card based on our interview. Review it above and:\n\n"
              "• Type 'agree' to save your character\n"
              "• Or describe any changes you'd like me to make",
            );
            notifyListeners();
          }
        } else {
          _handleApiConfigurationError();
        }
      }
    } catch (e) {
      if (kDebugMode) AppLogger.error('Error in sendMessage', tag: 'InterviewProvider', error: e);
      _handleErrorState("Error sending message: $e");
    }
  }

  // Helper function to convert local messages to API format
  List<Map<String, dynamic>> _convertMessagesToAPI() {
    return _messages
        .where((m) => !m.isLoading) // Skip loading messages
        .map(
          (m) => {"role": m.isUser ? "user" : "assistant", "content": m.text},
        )
        .toList();
  }

  // Helper to get min value
  int min(int a, int b) => a < b ? a : b;

  void addAIMessage(String text) {
    _messages.add(Message(text: text, isUser: false));
    notifyListeners();
  }

  // Add message with content parameter
  void addMessage({required String content, required bool isUser}) {
    _messages.add(Message(text: content, isUser: isUser));
    notifyListeners();
  }

  // Update character card summary from file processing
  void updateCardSummary(String cardContent) {
    if (cardContent.contains('## CHARACTER CARD SUMMARY ##') &&
        cardContent.contains('## END OF CHARACTER CARD ##')) {
      characterCardSummary = cardContent;

      // Try to extract character name if present
      if (cardContent.contains('## CHARACTER NAME:')) {
        final startName =
            cardContent.indexOf('## CHARACTER NAME:') +
            '## CHARACTER NAME:'.length;
        final endLine = cardContent.indexOf('\n', startName);
        if (endLine > startName) {
          final name = cardContent.substring(startName, endLine).trim();
          characterName = name.replaceAll('##', '').trim();
        }
      }

      // Mark as complete since character card is ready
      isComplete = true;
    }
    notifyListeners();
  }

  void _addLoadingMessage() {
    isAiThinking = true;
    _messages.add(Message(text: '', isUser: false, isLoading: true));
    notifyListeners();
  }

  void _removeLoadingMessage() {
    isAiThinking = false;
    _messages.removeWhere((message) => message.isLoading);
    notifyListeners();
  }

  /// Public method to cancel current AI thinking/loading state
  void cancelThinking() {
    _removeLoadingMessage();
  }

  void resetInterview() {
    _messages.clear();
    characterCardSummary = null;
    characterName = null;
    isComplete = false;
    isSuccess = false;
    _initialize();
  }

  // Removed unused _prepareSystemPromptForCharacter method

  void _handleApiConfigurationError() {
    _removeLoadingMessage();
    addAIMessage(
      "I couldn't connect to the AI service. It seems there might be an issue with the API key configuration.\n\n"
      "Please check the following:\n"
      "1. Make sure you have a valid OpenRouter API key\n"
      "2. Ensure the key is properly set in the .env file\n"
      "3. Verify that the .env file is included in your assets\n\n"
      "The application cannot function properly without a valid API key.",
    );
    notifyListeners();
  }

  void _handleErrorState(String message) {
    // Implement the logic to handle an error state
    _removeLoadingMessage();
    addAIMessage(
      "I apologize, but there was an error processing your request. Please try again.",
    );
    isAiThinking = false;
    notifyListeners();
  }

  // New method to save character to device
  Future<void> _saveCharacterToDevice() async {
    print('🔍 DEBUG: _saveCharacterToDevice called');
    if (characterCardSummary == null || characterName == null) {
      print(
        '🔍 DEBUG: Character data is incomplete - summary: ${characterCardSummary != null}, name: ${characterName != null}',
      );
      throw Exception('Character data is incomplete');
    }

    try {
      print('🔍 DEBUG: Creating CharacterModel with name: $characterName');
      // Create character model from interview data
      final character = CharacterModel.fromInterviewData(
        name: characterName!,
        cardContent: characterCardSummary!,
      );

      print('🔍 DEBUG: Character created with ID: ${character.id}');
      // Call the callback to save the character if provided
      if (_onCharacterSaved != null) {
        print('🔍 DEBUG: Calling save callback...');
        await _onCharacterSaved!(character);
        print('🔍 DEBUG: Save callback completed successfully');
      } else {
        print('🔍 DEBUG: No character save callback provided');
        throw Exception('No character save callback provided');
      }
    } catch (e) {
      print('🔍 DEBUG: Error in _saveCharacterToDevice: $e');
      _removeLoadingMessage();
      addAIMessage(
        "Sorry, there was an error saving your character: $e\n\n"
        "Please try again or contact support if the problem persists.",
      );
      throw Exception('Failed to save character: $e');
    }
  }
}
