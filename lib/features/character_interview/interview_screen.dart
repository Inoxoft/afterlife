// lib/features/character_interview/interview_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/interview_provider.dart';
import 'chat_bubble.dart';
import '../../core/theme/app_theme.dart';

class InterviewScreen extends StatefulWidget {
  const InterviewScreen({Key? key}) : super(key: key);

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InterviewProvider(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.backgroundStart,
          elevation: 0,
          title: const Text(
            "Creating Your Digital Twin",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            Consumer<InterviewProvider>(
              builder: (context, provider, _) {
                return IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Restart Interview'),
                        content: const Text('This will clear all your responses. Are you sure?'),
                        backgroundColor: AppTheme.deepIndigo,
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              provider.resetInterview();
                              Navigator.pop(context);
                            },
                            child: const Text('Restart'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppTheme.backgroundStart, AppTheme.backgroundEnd],
            ),
          ),
          child: Column(
            children: [
              // Chat messages
              Expanded(
                child: Consumer<InterviewProvider>(
                  builder: (context, provider, _) {
                    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                    
                    // Check if interview is complete
                    if (provider.isComplete && provider.characterCardSummary != null) {
                      // Process complete - navigate back or show completion UI
                      Future.microtask(() {
                        Navigator.pop(context, {
                          'characterCard': provider.characterCardSummary,
                          'characterName': provider.characterName,
                        });
                      });
                    }
                    
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(8.0),
                      itemCount: provider.messages.length,
                      itemBuilder: (context, index) {
                        return ChatBubble(
                          message: provider.messages[index],
                        );
                      },
                    );
                  },
                ),
              ),
              
              // Input area
              Consumer<InterviewProvider>(
                builder: (context, provider, _) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: AppTheme.deepIndigo.withOpacity(0.7),
                      boxShadow: [
                        BoxShadow(
                          offset: const Offset(0, -1),
                          blurRadius: 6.0,
                          spreadRadius: 0.0,
                          color: Colors.black.withOpacity(0.1),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Type your response...',
                                hintStyle: TextStyle(color: Colors.white60),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25.0),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.black26,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 14.0,
                                ),
                              ),
                              style: const TextStyle(color: Colors.white),
                              minLines: 1,
                              maxLines: 5,
                              onSubmitted: provider.isLoading
                                  ? null
                                  : (text) {
                                      if (text.trim().isNotEmpty) {
                                        provider.sendMessage(text);
                                        _messageController.clear();
                                      }
                                    },
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Container(
                            decoration: BoxDecoration(
                              color: provider.isLoading
                                  ? AppTheme.etherealCyan.withOpacity(0.3)
                                  : AppTheme.etherealCyan,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                provider.isLoading ? Icons.hourglass_top : Icons.send,
                                color: provider.isLoading
                                    ? Colors.white60
                                    : Colors.black87,
                              ),
                              onPressed: provider.isLoading
                                  ? null
                                  : () {
                                      if (_messageController.text.trim().isNotEmpty) {
                                        provider.sendMessage(_messageController.text);
                                        _messageController.clear();
                                      }
                                    },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
