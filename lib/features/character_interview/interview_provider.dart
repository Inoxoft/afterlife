import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'message_model.dart';
import 'chat_service.dart';

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
  Message? existingCharacter;

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
      // Start the interview with an intro message for new character creation
      addAIMessage(
        "Hello! I'm ready to create a detailed character card for you. This will involve a series of questions to understand your personality, values, experiences, and communication style. The goal is to build a profile that could be used for AI impersonation, so the more detail you provide, the better. Are you ready to begin? We can take breaks if you need them",
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

      if (response != null) {
        // Remove loading message
        _removeLoadingMessage();

        // Use the actual AI response
        addAIMessage(response);
      } else {
        // Handle null response case
        _handleErrorState("Failed to get response from AI");
      }
    } catch (e) {
      _handleErrorState("Error sending initial edit message: $e");
    }
  }

  String _getSystemPrompt() {
    if (isEditMode) {
      return """You are an AI assistant helping to edit and improve an existing character card.

The user has shared their character's current system prompt, and you're helping them make specific improvements.

Your goal is to enhance the existing character prompt based on the user's feedback, NOT to create an entirely new character.

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
      return """You are an AI assistant helping the user create their digital twin character.

    Ask them questions about their personality, interests, communication style, and important life details.

    After gathering sufficient information, generate a detailed character summary when the user asks for it or after

    10 message exchanges. When generating a summary, start with "## CHARACTER CARD SUMMARY ##" and end with

    "## END OF CHARACTER CARD ##". Ask the user to respond with "agree" if they approve this character card.

   

    If you detect a name for this character, also include "## CHARACTER NAME: [detected name] ##" in your summary.

   

    At the end of the interview, provide a detailed, vivid summary of everything the user has shared, ensuring it paints a clear picture of their personality, experiences, and worldview as a system prompt for an AI model to follow when impersonating the user.


Example Interaction
User: "I'm a freelance designer who values creativity over rules."
AI: "Tell me about a time when you bent rules for a creative project. How did it turn out?"
User: "I redesigned a client's logo without approval—they hated it initially but loved it later."
AI: "That's bold! Do you often take risks, or was this an exception? How do you handle criticism?""";
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Check if user already agreed but we need to finalize
    if (isComplete) return;

    // Add user message
    final userMessage = Message(text: text, isUser: true);
    _messages.add(userMessage);

    // Set loading state
    _addLoadingMessage();

    try {
      // Handle agree separately - this needs to happen after processing any card summary
      if (text.toLowerCase().trim() == 'agree') {
        // Find the last message containing a character card summary
        String? foundCardSummary;
        for (int i = _messages.length - 1; i >= 0; i--) {
          final msg = _messages[i];
          if (!msg.isUser &&
              msg.text.contains('## CHARACTER CARD SUMMARY ##') &&
              msg.text.contains('## END OF CHARACTER CARD ##')) {
            foundCardSummary = msg.text;
            break;
          }
        }

        // If we have a card summary from any message, process it
        if (foundCardSummary != null) {
          // Extract the clean system prompt - this is what we need to save
          final startIndex = foundCardSummary.indexOf(
            '## CHARACTER CARD SUMMARY ##',
          );
          final cleanStart = startIndex + '## CHARACTER CARD SUMMARY ##'.length;
          final cleanEnd = foundCardSummary.indexOf(
            '## END OF CHARACTER CARD ##',
          );

          // The system prompt should be the content between the markers
          if (cleanStart >= 0 && cleanEnd > cleanStart) {
            final cleanSystemPrompt =
                foundCardSummary.substring(cleanStart, cleanEnd).trim();

            // Format the system prompt for use with the character model
            characterCardSummary = _prepareSystemPromptForCharacter(
              cleanSystemPrompt,
            );

            // Try to extract character name if not already set
            if (characterName == null) {
              final nameMarker = '## CHARACTER NAME:';
              if (foundCardSummary.contains(nameMarker)) {
                final startName =
                    foundCardSummary.indexOf(nameMarker) + nameMarker.length;
                final endLine = foundCardSummary.indexOf('\n', startName);
                if (endLine > startName) {
                  characterName =
                      foundCardSummary.substring(startName, endLine).trim();
                  // Remove any '##' if present
                  characterName = characterName?.replaceAll('##', '').trim();
                }
              }

              // If no character name found with the marker, try to find in the system prompt
              if (characterName == null || characterName!.isEmpty) {
                // Look for "You are [Name]" pattern in the system prompt
                final lines = cleanSystemPrompt.split('\n');
                for (final line in lines) {
                  if (line.contains('You are') && line.contains(',')) {
                    final startName =
                        line.indexOf('You are') + 'You are'.length;
                    final endName = line.indexOf(',', startName);
                    if (endName > startName) {
                      characterName = line.substring(startName, endName).trim();
                      break;
                    }
                  }
                }
              }
            }

            // Set completion flags - this will trigger showing the success UI
            isComplete = true;
            isSuccess = true;
            _removeLoadingMessage();

            // Add a confirmation message
            addAIMessage(
              'Character card finalized! You can now chat with your digital twin.',
            );

            // Fallback name if still none found
            if (characterName == null || characterName!.isEmpty) {
              characterName = "Character";
            }

            // Notify listeners and return early
            notifyListeners();
            return;
          } else {
            // Invalid markers found, continue with regular processing
            _removeLoadingMessage();
            addAIMessage(
              'I couldn\'t find a valid character card. Please ask me to generate a character summary.',
            );
            return;
          }
        } else {
          _removeLoadingMessage();
          addAIMessage(
            'Please ask me to generate a character summary first before agreeing.',
          );
          return;
        }
      }

      // For editing mode, try to extract character name if not present
      if (isEditMode &&
          characterName == null &&
          text.toLowerCase().contains('name is')) {
        final nameParts = text.split('name is');
        if (nameParts.length > 1) {
          final potentialName = nameParts[1]
              .trim()
              .split(' ')[0]
              .replaceAll(RegExp(r'[^\w\s]'), '');
          if (potentialName.isNotEmpty) {
            characterName = potentialName;
          }
        }
      }

      // Convert messages to format expected by API
      final apiMessages =
          _messages
              .map(
                (msg) => {
                  'role': msg.isUser ? 'user' : 'assistant',
                  'content': msg.text,
                },
              )
              .toList();

      try {
        // Get the system prompt to send to the API
        final systemPromptToUse = _getSystemPrompt();

        // For all other user inputs, send to API to get AI response
        final response = await ChatService.sendMessage(
          messages: apiMessages,
          systemPrompt: systemPromptToUse,
        );

        // Remove loading message
        _removeLoadingMessage();

        // Check if the response contains a character card summary
        if (response.contains('## CHARACTER CARD SUMMARY ##') &&
            response.contains('## END OF CHARACTER CARD ##')) {
          // Extract the clean system prompt
          final startIndex = response.indexOf('## CHARACTER CARD SUMMARY ##');
          final cleanStart = startIndex + '## CHARACTER CARD SUMMARY ##'.length;
          final cleanEnd = response.indexOf('## END OF CHARACTER CARD ##');

          if (cleanStart >= 0 && cleanEnd > cleanStart) {
            // The clean system prompt is the content between the markers
            final cleanSystemPrompt =
                response.substring(cleanStart, cleanEnd).trim();

            // Store the full response for display purposes
            characterCardSummary = response;

            // Try to extract character name if not already set
            if (characterName == null) {
              final nameMarker = '## CHARACTER NAME:';
              if (response.contains(nameMarker)) {
                final startName =
                    response.indexOf(nameMarker) + nameMarker.length;
                final endLine = response.indexOf('\n', startName);
                if (endLine > startName) {
                  characterName = response.substring(startName, endLine).trim();
                  // Remove any '##' if present
                  characterName = characterName?.replaceAll('##', '').trim();
                }
              }

              // If still no name, try other methods
              if (characterName == null || characterName!.isEmpty) {
                // Look for "You are [Name]" pattern in the clean system prompt
                final lines = cleanSystemPrompt.split('\n');
                for (final line in lines) {
                  if (line.contains('You are') && line.contains(',')) {
                    final startName =
                        line.indexOf('You are') + 'You are'.length;
                    final endName = line.indexOf(',', startName);
                    if (endName > startName) {
                      characterName = line.substring(startName, endName).trim();
                      break;
                    }
                  }
                }
              }

              // Fallback name if still none found
              if (characterName == null || characterName!.isEmpty) {
                characterName = "Character";
              }
            }
          }
        }

        // Add the AI response to chat
        addAIMessage(response);
      } catch (e) {
        _removeLoadingMessage();
        addAIMessage(
          'I\'m having trouble connecting to my AI service. Please check your internet connection and try again.',
        );
      }
    } catch (e) {
      _removeLoadingMessage();
      addAIMessage(
        'Sorry, there was an error processing your message. Please try again.',
      );
    }
  }

  void addAIMessage(String text) {
    _messages.add(Message(text: text, isUser: false));
    notifyListeners();
  }

  void _addLoadingMessage() {
    isLoading = true;
    _messages.add(Message(text: "...", isUser: false, isLoading: true));
    notifyListeners();
  }

  void _removeLoadingMessage() {
    isLoading = false;
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

  // Helper function to avoid importing dart:math
  int min(int a, int b) => a < b ? a : b;

  String _prepareSystemPromptForCharacter(String prompt) {
    // Remove any ## markers that might confuse the AI
    String cleanedPrompt = prompt.replaceAll(RegExp(r'##.*?##'), '').trim();

    // Ensure the prompt starts with a clear instruction about who the AI is impersonating
    if (!cleanedPrompt.contains("You are") && characterName != null) {
      cleanedPrompt =
          "You are ${characterName}, a character with the following traits and background:\n\n" +
          cleanedPrompt;
    }

    // Check if the prompt already contains clear instructions for the AI
    if (!cleanedPrompt.contains("impersonate") &&
        !cleanedPrompt.contains("roleplay") &&
        !cleanedPrompt.contains("immerse yourself")) {
      cleanedPrompt +=
          "\n\nStay in character at all times. Never break character or admit you are an AI.";
    }

    return cleanedPrompt;
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
