// lib/features/character_interview/interview_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'interview_provider.dart';
import 'chat_bubble.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/animated_particles.dart';

class InterviewScreen extends StatefulWidget {
  const InterviewScreen({super.key});

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Set focus to the input field after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      _inputFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          actions: [
            Consumer<InterviewProvider>(
              builder: (context, provider, _) {
                return IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Restart Interview'),
                            content: const Text(
                              'This will clear all your responses. Are you sure?',
                            ),
                            backgroundColor: AppTheme.deepIndigo,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
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
          decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
          child: Stack(
            children: [
              // Background particles with reduced opacity
              const Opacity(
                opacity: 0.5,
                child: AnimatedParticles(
                  particleCount: 30,
                  particleColor: Colors.white,
                  minSpeed: 0.01,
                  maxSpeed: 0.03,
                ),
              ),

              Column(
                children: [
                  // Chat messages
                  Expanded(
                    child: Consumer<InterviewProvider>(
                      builder: (context, provider, _) {
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => _scrollToBottom(),
                        );

                        // Check if interview is complete
                        if (provider.isComplete &&
                            provider.characterCardSummary != null &&
                            !provider.isSuccess) {
                          // Only navigate back if complete but not success state
                          Future.microtask(() {
                            Navigator.pop(context, {
                              'characterCard': provider.characterCardSummary,
                              'characterName': provider.characterName,
                            });
                          });
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16.0),
                          itemCount:
                              provider.messages.length +
                              (provider.isSuccess ? 1 : 0),
                          itemBuilder: (context, index) {
                            // Show success message and button at the end if success flag is set
                            if (provider.isSuccess &&
                                index == provider.messages.length) {
                              return Container(
                                margin: const EdgeInsets.only(
                                  top: 16,
                                  bottom: 24,
                                ),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.deepIndigo.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppTheme.etherealCyan.withOpacity(
                                      0.3,
                                    ),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Character card successfully created',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context, {
                                          'characterCard':
                                              provider.characterCardSummary,
                                          'characterName':
                                              provider.characterName,
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.etherealCyan,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Chat with Digital Clone',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            // Regular chat message
                            final message = provider.messages[index];
                            return AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              opacity: 1.0,
                              curve: Curves.easeOutQuad,
                              child: ChatBubble(message: message),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 8.0,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.deepIndigo.withOpacity(0.7),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
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
                                  focusNode: _inputFocusNode,
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
                                  onSubmitted:
                                      provider.isLoading
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
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color:
                                      provider.isLoading
                                          ? AppTheme.etherealCyan.withOpacity(
                                            0.3,
                                          )
                                          : AppTheme.etherealCyan,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    if (!provider.isLoading)
                                      BoxShadow(
                                        color: AppTheme.etherealCyan
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    transitionBuilder: (
                                      Widget child,
                                      Animation<double> animation,
                                    ) {
                                      return ScaleTransition(
                                        scale: animation,
                                        child: child,
                                      );
                                    },
                                    child:
                                        provider.isLoading
                                            ? const Icon(
                                              Icons.hourglass_top,
                                              key: ValueKey('loading'),
                                              color: Colors.white60,
                                            )
                                            : const Icon(
                                              Icons.send,
                                              key: ValueKey('send'),
                                              color: Colors.black87,
                                            ),
                                  ),
                                  onPressed:
                                      provider.isLoading
                                          ? null
                                          : () {
                                            if (_messageController.text
                                                .trim()
                                                .isNotEmpty) {
                                              provider.sendMessage(
                                                _messageController.text,
                                              );
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
            ],
          ),
        ),
      ),
    );
  }
}
