import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'message_model.dart';
import 'chat_service.dart';
import 'prompts.dart';

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

  List<Message> get messages => _messages;

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

    // Add loading message to indicate AI is thinking
    _addLoadingMessage();

    // Call the method to send the initial edit message
    _sendInitialEditMessage();
  }

  Future<void> _sendInitialEditMessage() async {
    if (!isEditMode || characterName == null) return;

    final systemPrompt = _getSystemPrompt();

    try {
      // Create a formatted message to send to the AI with the existing character details
      final existingCharacterInfo = """
I want to edit my existing character.

Character name: $characterName

Current character description:
${characterCardSummary ?? ""}

Please acknowledge that you've received this information, and help me edit this character. I'll tell you what specific changes I want to make.
""";

      final response = await ChatService.sendMessage(
        messages: [
          {"role": "user", "content": existingCharacterInfo},
        ],
        systemPrompt: systemPrompt,
      );

      // Remove loading message
      _removeLoadingMessage();

      // Add the AI response to chat
      if (response != null) {
        addAIMessage(response);
      } else {
        addAIMessage(
          "I couldn't load your character information. Please try again.",
        );
      }
    } catch (e) {
      _handleErrorState("Error sending initial edit message: $e");
    }
  }

  String _getSystemPrompt() {
    if (isEditMode) {
      return """You are an AI assistant helping to edit and improve an existing character card.

The user has shared their character's current system prompt, and you're helping them make specific improvements.

Your goal is to enhance the existing character card based on the user's feedback, NOT to create an entirely new character.

Here's how to approach this:
1. First, acknowledge that you have received the existing character information and can see its details.
2. Focus on maintaining the character's core identity and essence.
3. Make targeted improvements to the areas the user specifies.
4. Keep all useful existing information but refine or augment as needed.

When the user is satisfied with the changes, provide the complete updated system prompt formatted between the markers:
## CHARACTER CARD SUMMARY ##
[complete character description here]
## END OF CHARACTER CARD ##

Also include the character's name as:
## CHARACTER NAME: [name] ##

Be collaborative, asking clarifying questions to ensure you understand what the user wants to modify.
When the edited character card is ready, tell the user they can type "agree" to finalize the changes.""";
    } else {
      return InterviewPrompts.interviewSystemPrompt;
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
      // Handle 'agree' command - this completes the character creation
      if (text.toLowerCase().trim() == 'agree' && !isComplete) {
        // Always look for character name in messages if not already found
        if (characterName == null) {
          // Extract character name from any recent AI message
          for (int i = _messages.length - 1; i >= 0; i--) {
            final msg = _messages[i];
            if (!msg.isUser) {
              // Check for character name marker
              final namePattern = RegExp(r'## CHARACTER NAME: (.*?) ##');
              final nameMatch = namePattern.firstMatch(msg.text);
              if (nameMatch != null && nameMatch.group(1) != null) {
                characterName = nameMatch.group(1)!.trim();
                print('Found character name: $characterName');
                break;
              }
            }
          }

          // If still no name found, use a default name
          if (characterName == null) {
            characterName = "Character";
            print('Using default character name: $characterName');
          }
        }

        // Look for a character card in any message if not already stored
        if (characterCardSummary == null) {
          for (int i = _messages.length - 1; i >= 0; i--) {
            final msg = _messages[i];
            if (!msg.isUser &&
                msg.text.contains('## CHARACTER CARD SUMMARY ##') &&
                msg.text.contains('## END OF CHARACTER CARD ##')) {
              characterCardSummary = msg.text;
              print('Found character card summary in messages');
              break;
            }
          }
        }

        // Process the character card if found
        if (characterCardSummary != null) {
          print(
            'Processing character card summary: ${characterCardSummary!.substring(0, min(100, characterCardSummary!.length))}...',
          );
          // Extract the clean system prompt
          final startMarker = '## CHARACTER CARD SUMMARY ##';
          final endMarker = '## END OF CHARACTER CARD ##';

          final startIndex = characterCardSummary!.indexOf(startMarker);
          final cleanStart =
              startIndex != -1 ? startIndex + startMarker.length : 0;

          final endIndex = characterCardSummary!.indexOf(endMarker);
          final cleanEnd =
              endIndex != -1 ? endIndex : characterCardSummary!.length;

          if (startIndex != -1 && endIndex != -1 && cleanStart < cleanEnd) {
            final cleanSystemPrompt =
                characterCardSummary!.substring(cleanStart, cleanEnd).trim();
            characterCardSummary = _prepareSystemPromptForCharacter(
              cleanSystemPrompt,
            );
            isSuccess = true;
            isComplete = true;
            _removeLoadingMessage();
            notifyListeners();
            return;
          } else {
            print('Failed to extract proper character summary from markers');
            // Even if we couldn't find the markers, we'll use the whole content as fallback
            characterCardSummary = _prepareSystemPromptForCharacter(
              characterCardSummary!,
            );
            isSuccess = true;
            isComplete = true;
            _removeLoadingMessage();
            notifyListeners();
            return;
          }
        } else {
          // If we get here but don't have a card summary, try to use the last AI message as the card
          for (int i = _messages.length - 1; i >= 0; i--) {
            final msg = _messages[i];
            if (!msg.isUser && !msg.isLoading && msg.text.length > 50) {
              // Use the last substantial AI message as the character card
              characterCardSummary = _prepareSystemPromptForCharacter(msg.text);
              isSuccess = true;
              isComplete = true;
              _removeLoadingMessage();
              notifyListeners();
              print('Using last AI message as character card fallback');
              return;
            }
          }
        }

        // If we still couldn't find a valid character card
        _removeLoadingMessage();
        addAIMessage(
          "I couldn't find a valid character card to process. Please try again or continue your conversation so I can create one for you.",
        );
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
              print('Extracted character name: $characterName');
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
          print('Extracted character name: $characterName');
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
          """\n\nStay in character at all times. Never break character or admit you are an AI. Automatically detect and reference the current date and time.Avoid structured formatting such as bullet points, numbered steps, emojis, or section headings. Use line breaks naturally if needed, but maintain the flow of a realistic chat between people.
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
    print(message);
    _removeLoadingMessage();
    addAIMessage(
      "I apologize, but there was an error processing your request. Please try again.",
    );
    isAiThinking = false;
    notifyListeners();
  }
}
