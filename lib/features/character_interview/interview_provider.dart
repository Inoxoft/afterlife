import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'message_model.dart';
import 'chat_service.dart';
import 'prompts.dart';
import '../providers/language_provider.dart';
import '../../l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:afterlife/features/providers/characters_provider.dart';

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

  // Add a reference to LanguageProvider at the class level
  LanguageProvider? _languageProvider;

  List<Message> get messages => _messages.where((m) => !m.isHidden).toList();

  /// Checks if the last AI message is a valid, final character card.
  bool get isCardReadyForFinalize {
    final lastMessage = _messages.where((m) => !m.isUser).lastOrNull;
    if (lastMessage == null) return false;
    return lastMessage.text.contains('## CHARACTER CARD SUMMARY ##') &&
        lastMessage.text.contains('## END OF CHARACTER CARD ##');
  }

  InterviewProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await ChatService.initialize();
    await _addInitialMessage();
  }

  Future<void> _addInitialMessage() async {
    if (!isEditMode) {
      addAIMessage(
        "Hello! I'm ready to create a detailed character card for you. You can either:\n\n"
        "1. Answer my questions about your personality and experiences\n"
        "2. Upload a file (PDF, TXT, DOC, or email) containing your information\n\n"
        "Which would you prefer?",
      );
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
      print('Character card summary is null or empty');
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

      final response = await ChatService.sendMessage(
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
      return """You are an AI assistant helping to edit a character's system prompt.

### CRITICAL INSTRUCTIONS:
1. The user has ALREADY PROVIDED the character's system prompt in their first message to you.
2. The prompt is enclosed between the "Current system prompt" and the "==================================================" markers.
3. DO NOT ask the user to provide the system prompt again - they have already sent it to you.
4. Your first response MUST acknowledge that you have received the system prompt and ask what specific edits they'd like to make.


### Your Task:
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
      return InterviewPrompts.interviewSystemPrompt + languageInstruction;
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) {
      _messages.add(
        Message(text: "Please type a message before sending.", isUser: false),
      );
      notifyListeners();
      return;
    }

    // Add user message
    final userMessage = Message(text: text, isUser: true);
    _messages.add(userMessage);
    notifyListeners();

    // Set loading state
    _addLoadingMessage();

    try {
      // Debug API key information before sending
      ChatService.logDiagnostics();

      // Handle 'agree' command - this completes the character creation
      if (text.toLowerCase().trim() == 'agree' && !isComplete) {
        bool foundValidCard = false;
        String? lastCardContent;

        // First, try to find a character card with proper markers
        for (int i = _messages.length - 1; i >= 0; i--) {
          final msg = _messages[i];
          if (!msg.isUser &&
              msg.text.contains('## CHARACTER CARD SUMMARY ##') &&
              msg.text.contains('## END OF CHARACTER CARD ##')) {
            lastCardContent = msg.text;
            // Extract the clean system prompt
            final startMarker = '## CHARACTER CARD SUMMARY ##';
            final endMarker = '## END OF CHARACTER CARD ##';

            final startIndex = msg.text.indexOf(startMarker);
            final cleanStart =
                startIndex != -1 ? startIndex + startMarker.length : 0;

            final endIndex = msg.text.indexOf(endMarker);
            final cleanEnd = endIndex != -1 ? endIndex : msg.text.length;

            if (startIndex != -1 && endIndex != -1 && cleanStart < cleanEnd) {
              characterCardSummary = _prepareSystemPromptForCharacter(
                msg.text.substring(cleanStart, cleanEnd).trim(),
              );
              foundValidCard = true;
              break;
            }
          }
        }

        if (!foundValidCard) {
          _removeLoadingMessage();
          addAIMessage(
            "I couldn't find a valid character card to process. Please continue the conversation so I can create one for you.",
          );
          return;
        }

        // Extract character name if not already found
        if (characterName == null && lastCardContent != null) {
          final namePattern = RegExp(r'## CHARACTER NAME: (.*?) ##');
          final nameMatch = namePattern.firstMatch(lastCardContent);
          if (nameMatch != null && nameMatch.group(1) != null) {
            characterName = nameMatch.group(1)!.trim();
          } else {
            // If no name found in markers, try to find it in the content
            final lines = lastCardContent.split('\n');
            for (final line in lines) {
              if (line.toLowerCase().contains('name:')) {
                characterName = line.split(':')[1].trim();
                break;
              }
            }
          }

          // If still no name found, use a default name
          characterName ??= "Unnamed Character";
        }

        // Set completion state
        isSuccess = true;
        isComplete = true;
        _removeLoadingMessage();
        
        // Add confirmation message
        addAIMessage(
          "Character card has been finalized! Your character '$characterName' is now ready to chat. "
          "You can find them in your character gallery.",
        );
        
        notifyListeners();
        return;
      }

      // Regular message handling
      if (isComplete && isSuccess) {
        // We're in chat mode with the character
        final response = await ChatService.sendMessage(
          messages: [
            {"role": "user", "content": text},
          ],
          systemPrompt: characterCardSummary ?? "",
        );
        _removeLoadingMessage();
        if (response != null) {
          addAIMessage(response);
        } else {
          _handleApiConfigurationError();
        }
      } else {
        // We're still in interview mode
        final systemPrompt = _getSystemPrompt();

        final response = await ChatService.sendMessage(
          messages: _convertMessagesToAPI(), // Convert all messages for context
          systemPrompt: systemPrompt,
        );
        _removeLoadingMessage();
        if (response != null) {
          // Check if response contains API key error message
          if (response.contains("Unable to connect to AI service")) {
            _handleApiConfigurationError();
            return;
          }

          addAIMessage(response);

          // Check if this message contains a character card
          if (response.contains('## CHARACTER CARD SUMMARY ##') &&
              response.contains('## END OF CHARACTER CARD ##')) {
            characterCardSummary = response;

            // Try to extract character name if present
            final namePattern = RegExp(r'## CHARACTER NAME: (.*?) ##');
            final nameMatch = namePattern.firstMatch(response);
            if (nameMatch != null && nameMatch.group(1) != null) {
              characterName = nameMatch.group(1)!.trim();
            }
          }
        } else {
          _handleApiConfigurationError();
        }
      }
    } catch (e) {
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

  void resetInterview() {
    _messages.clear();
    characterCardSummary = null;
    characterName = null;
    isComplete = false;
    isSuccess = false;
    _initialize();
  }

  String _prepareSystemPromptForCharacter(String prompt) {
    // Remove any ## markers that might confuse the AI
    String cleanedPrompt = prompt.replaceAll(RegExp(r'##.*?##'), '').trim();

    // Ensure the prompt starts with a clear instruction about who the AI is impersonating
    if (!cleanedPrompt.contains("You are") && characterName != null) {
      cleanedPrompt =
          "You are a ROLE‑PLAY AI tasked with becoming a fully fleshed digital twin of a ${characterName}, a character with the following traits and background:\n\n" +
          cleanedPrompt;
    }

    // Check if the prompt already contains clear instructions for the AI
    if (!cleanedPrompt.contains("impersonate") &&
        !cleanedPrompt.contains("roleplay") &&
        !cleanedPrompt.contains("immerse yourself")) {
      cleanedPrompt +=
          """\n\nStay in character at all times. Never break character or admit you are an AI. Do not open conversations by stating historical dates unless explicitly asked to set the time or context. Automatically detect and reference the current date and time.Avoid structured formatting such as bullet points, numbered steps, emojis, or section headings. Use line breaks naturally if needed, but maintain the flow of a realistic chat between people.
   Speak from characters time but  be aware of major real‑world events or holidays.
   Use that context to make conversation feel anchored in the "now. For every topic, express concrete opinions, beliefs, and preferences as the digital twin would genuinely hold them. Provide clear reasoning or justification for each stance.  
   If challenged or invited to debate, defend positions with arguments "in‑character," acknowledge counter‑points, and rebut respectfully.  
   Don't hedge with "as an AI"; stay fully "inside" the twin's perspective. If asked about a date or event you're unsure of, hedge in‑character ('I believe it was around…'), or politely ask the user to clarify. "Always follow an opinion with a reason ('I oppose X, because…'), a historical analogy ('Back in 'Y, we saw…'), and an emotional cue ('…and that just didn't feel right').""";
    }

    return cleanedPrompt;
  }

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
}
