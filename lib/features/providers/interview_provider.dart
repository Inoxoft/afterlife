// lib/features/providers/interview_provider.dart
import 'package:flutter/foundation.dart';
import '../character_interview/message_model.dart';
import '../character_interview/chat_service.dart';

class InterviewProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  List<Message> messages = [];
  bool isLoading = false;
  String? characterCardSummary;
  String? characterName;
  bool isComplete = false;
  
  InterviewProvider() {
    _initialize();
  }
  
  Future<void> _initialize() async {
    await _chatService.initialize();
    // Start the interview with an intro message
    _addAIMessage("Hello! I'm here to help create your digital twin. I'll ask you questions about yourself to understand who you are. Let's start with your name - what would you like me to call you?");
    notifyListeners();
  }
  
  String _getSystemPrompt() {
    return """You are an AI assistant helping the user create their digital twin character. 
    Ask them questions about their personality, interests, communication style, and important life details.
    After gathering sufficient information, generate a detailed character summary when the user asks for it or after 
    10 message exchanges. When generating a summary, start with "## CHARACTER CARD SUMMARY ##" and end with 
    "## END OF CHARACTER CARD ##". Ask the user to respond with "agree" if they approve this character card.
    
    If you detect a name for this character, also include "## CHARACTER NAME: [detected name] ##" in your summary.
    
    At the end of the interview, provide a detailed, vivid summary of everything the user has shared, ensuring it paints a clear picture of their personality, experiences, and worldview as a system prompt for an AI model to follow when impersonating the user.""";
  }
  
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    
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
      _addAIMessage(response);
      
      // Check if response contains character card summary
      if (response.contains('## CHARACTER CARD SUMMARY ##') && 
          response.contains('## END OF CHARACTER CARD ##')) {
        
        // Extract character card
        final startIndex = response.indexOf('## CHARACTER CARD SUMMARY ##');
        final endIndex = response.indexOf('## END OF CHARACTER CARD ##') + '## END OF CHARACTER CARD ##'.length;
        characterCardSummary = response.substring(startIndex, endIndex);
        
        // Extract character name if present
        final namePattern = RegExp(r'## CHARACTER NAME: (.*?) ##');
        final nameMatch = namePattern.firstMatch(response);
        if (nameMatch != null && nameMatch.groupCount >= 1) {
          characterName = nameMatch.group(1);
        }
        
        // Mark as complete if user agrees
        if (text.toLowerCase().trim() == 'agree') {
          isComplete = true;
        }
      }
      
    } catch (e) {
      // Remove loading message
      _removeLoadingMessage();
      
      // Add error message
      _addAIMessage("I'm having trouble connecting. Please try again in a moment.");
      print("Error in chat: $e");
    }
  }
  
  void _addAIMessage(String text) {
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
    _chatService.clearHistory();
    _initialize();
  }
}
