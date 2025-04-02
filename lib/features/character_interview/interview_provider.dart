import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../character_interview/message_model.dart';
import '../character_interview/chat_service.dart';

class InterviewProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  List<Message> messages = [];
  bool isLoading = false;
  String? characterCardSummary;
  String? characterName;
  bool isComplete = false;
  bool isSuccess = false;

  // Debug flags
  bool _debugPrintData = true;

  InterviewProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _chatService.initialize();
    // Start the interview with an intro message
    addAIMessage(
      "Hello! I'm ready to create a detailed character card for you. This will involve a series of questions to understand your personality, values, experiences, and communication style. The goal is to build a profile that could be used for AI impersonation, so the more detail you provide, the better. Are you ready to begin? We can take breaks if you need them",
    );
    notifyListeners();
  }

  String _getSystemPrompt() {
    return """You are an AI tasked with creating a hyper-detailed, product-grade character card of the user through a structured interview. Your goal is to gather granular details to build a rich, multidimensional profile for accurate AI impersonation.

Phase 1: Deep-Dive Interview
Structured Questioning Framework:

Personality:

Core traits: “What 3 adjectives define you? How do these traits manifest in your daily life?”

Strengths/Weaknesses: “What’s a strength you’re proud of, and a flaw you’re working on?”

Quirks: “Do you have any habits, phrases, or rituals that feel uniquely ‘you’?”

Values & Beliefs:

Moral compass: “What’s a non-negotiable principle you’d never compromise?”

Passions: “What injustice or cause fires you up?”

Dealbreakers: “What behaviors or attitudes instantly make you dislike someone?”

Communication Style:

Tone: “Do you prefer directness or diplomacy? Give an example.”

Listening habits: “Do you interrupt often, or are you a silent processor?”

Pet peeves: “What makes you roll your eyes in a conversation?”

Life Experiences:

Pivotal moments: “Share a story that changed your perspective or trajectory.”

Milestones: “What achievement or failure shaped who you are today?”

Relationships: “Describe someone who influenced you deeply and why.”

Worldview:

Philosophy: “Do you believe people are inherently good or self-serving? Why?”

Fears/Aspirations: “What’s your biggest fear? What legacy do you want to leave?”

Probing Tactics:

If answers are vague: “Can you share a specific example or memory that illustrates that?”

If contradictions arise: “You mentioned [X] earlier but just said [Y]—can you clarify?”

If emotions surface: “How did that experience make you feel at the time vs. now?”

Dynamic Pacing:

Extend beyond 10 messages if needed. Periodically ask: “Would you like to dive deeper into [topic], or move to the next section?”

Phase 2: Character Card Generation
When triggered, structure the card with markdown formatting and these sections:

## CHARACTER CARD SUMMARY ##  
## CHARACTER NAME: [Name] ##  

### **Core Identity**  
- **Personality**: [Traits + examples, e.g., *“Empathetic listener who defaults to asking ‘How did that make you feel?’”*]  
- **Values**: [Non-negotiables + motivations, e.g., *“Champions fairness—hates when effort goes unrecognized.”*]  
- **Communication Style**: [Tone, pet peeves, quirks, e.g., *“Uses sarcasm to deflect vulnerability; hates small talk.”*]  

### **Life Narrative**  
- **Key Experiences**: [Milestones, traumas, triumphs with emotional context]  
- **Relationships**: [Influential people + dynamics, e.g., *“Close to her sister but competitive with peers.”*]  
- **Worldview**: [Beliefs about humanity, politics, spirituality]  

### **Behavioral Nuances**  
- **Habits/Routines**: [Daily rituals, e.g., *“Night owl who journals with black coffee.”*]  
- **Decision-Making**: [Rational vs. emotional, e.g., *“Weighs pros/cons but trusts gut in crises.”*]  
- **Aspirations**: [Short-term goals + lifelong dreams]  

### **AI Impersonation Guide**  
- **Do**: [Instructions like *“Use dry humor in tense situations”*]  
- **Avoid**: [Red flags like *“Never use emojis or exclamation points.”*]  

## END OF CHARACTER CARD ##  
Approval Workflow:

Ask the user to confirm or request edits. Revise iteratively until they respond “Finalize.”

Phase 3: System Prompt for Impersonation
Generate a ready-to-use prompt for an AI model:

“You are [Name], [age/role] known for [key traits]. You [core behaviors, e.g., *‘prioritize logic but mask anxiety with self-deprecating jokes’*].  
**Style**: Communicate in [tone] and avoid [pet peeves].  
**Beliefs**: [Worldview summary].  
**Background**: [Relevant life experiences].  
**Rules**: Always [do/avoid list].”  
Example Interaction
User: “I’m a freelance designer who values creativity over rules.”
AI: “Tell me about a time when you bent rules for a creative project. How did it turn out?”
User: “I redesigned a client’s logo without approval—they hated it initially but loved it later.”
AI: “That’s bold! Do you often take risks, or was this an exception? How do you handle criticism?”""";
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Check if user already agreed but we need to finalize
    if (isComplete) {
      if (_debugPrintData) {
        print('User already agreed, interview complete');
        print('Character name: $characterName');
        print('Character card: $characterCardSummary');
      }
      return;
    }

    // Add user message
    final userMessage = Message(text: text, isUser: true);
    messages.add(userMessage);

    // Set loading state
    _addLoadingMessage();

    try {
      // Get AI response
      final response = await _chatService.sendMessage(
        text,
        systemPrompt: _getSystemPrompt(),
      );

      // Remove loading message
      _removeLoadingMessage();

      // Add AI response
      addAIMessage(response);

      // Check if response contains character card summary
      if (response.contains('## CHARACTER CARD SUMMARY ##') &&
          response.contains('## END OF CHARACTER CARD ##')) {
        // Extract character card
        final startIndex = response.indexOf('## CHARACTER CARD SUMMARY ##');
        final endIndex =
            response.indexOf('## END OF CHARACTER CARD ##') +
            '## END OF CHARACTER CARD ##'.length;
        characterCardSummary = response.substring(startIndex, endIndex);

        // Extract character name if present
        final namePattern = RegExp(r'## CHARACTER NAME: (.*?) ##');
        final nameMatch = namePattern.firstMatch(response);
        if (nameMatch != null && nameMatch.groupCount >= 1) {
          characterName = nameMatch.group(1);
        }

        if (_debugPrintData) {
          print('Extracted character card summary markers.');
          print('Character name: $characterName');
        }
      }

      // Handle agree separately - this needs to happen after processing any card summary
      if (text.toLowerCase().trim() == 'agree') {
        if (characterCardSummary != null &&
            characterCardSummary!.contains('## CHARACTER CARD SUMMARY ##')) {
          // Extract clean system prompt
          final startIndex = characterCardSummary!.indexOf(
            '## CHARACTER CARD SUMMARY ##',
          );
          final cleanStart = startIndex + '## CHARACTER CARD SUMMARY ##'.length;
          final cleanEnd = characterCardSummary!.indexOf(
            '## END OF CHARACTER CARD ##',
          );

          // The system prompt should be the content between the markers
          final cleanSystemPrompt =
              characterCardSummary!.substring(cleanStart, cleanEnd).trim();

          // Replace the original with the clean version for actual use
          characterCardSummary = cleanSystemPrompt;

          // Store the system prompt in local storage
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'system_prompt_${characterName ?? 'unnamed'}',
            cleanSystemPrompt,
          );

          // Set completion flags - this will trigger showing the success UI
          isComplete = true;
          isSuccess = true;

          if (_debugPrintData) {
            print('User agreed, interview complete!');
            print('Final character name: $characterName');
            print('Final system prompt size: ${characterCardSummary?.length}');
          }

          // Notify listeners and return early to prevent adding AI response
          notifyListeners();
          return;
        }
      }
    } catch (e) {
      // Remove loading message
      _removeLoadingMessage();

      // Add error message
      addAIMessage(
        "I'm having trouble connecting. Please try again in a moment.",
      );
      print("Error in chat: $e");
    }
  }

  void addAIMessage(String text) {
    messages.add(Message(text: text, isUser: false));
    notifyListeners();
  }

  void _addLoadingMessage() {
    isLoading = true;
    messages.add(Message(text: "...", isUser: false, isLoading: true));
    notifyListeners();
  }

  void _removeLoadingMessage() {
    isLoading = false;
    messages.removeWhere((message) => message.isLoading);
    notifyListeners();
  }

  void resetInterview() {
    messages.clear();
    characterCardSummary = null;
    characterName = null;
    isComplete = false;
    isSuccess = false;
    _chatService.clearHistory();
    _initialize();
  }
}
