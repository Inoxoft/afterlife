// lib/features/character_interview/interview_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/animated_particles.dart';
import '../models/character_model.dart';
import 'interview_provider.dart';
import 'chat_bubble.dart';

class InterviewScreen extends StatefulWidget {
  final bool editMode;
  final CharacterModel? existingCharacter;

  const InterviewScreen({
    Key? key,
    this.editMode = false,
    this.existingCharacter,
  }) : super(key: key);

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  late InterviewProvider _interviewProvider;

  @override
  void initState() {
    super.initState();
    _initializeProvider();
    // Set focus to the input field after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      _inputFocusNode.requestFocus();
    });
  }

  void _initializeProvider() {
    _interviewProvider = InterviewProvider();

    // If editing an existing character, initialize with their data
    if (widget.editMode && widget.existingCharacter != null) {
      _interviewProvider.setEditMode(
        existingName: widget.existingCharacter!.name,
        existingSystemPrompt: widget.existingCharacter!.systemPrompt,
      );
    }
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
      create: (_) => _interviewProvider,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.backgroundStart,
          elevation: 0,
          title: Text(
            widget.editMode
                ? "Editing ${widget.existingCharacter?.name ?? 'Character'}"
                : "Creating Your Digital Twin",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
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
                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16.0),
                          itemCount:
                              provider.messages.length +
                              (provider.isSuccess ? 1 : 0),
                          itemBuilder: (context, index) {
                            // If this is the success message, show it with the chat button
                            if (provider.isSuccess &&
                                index == provider.messages.length) {
                              return Container(
                                padding: const EdgeInsets.all(20),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Text(
                                        provider.isEditMode
                                            ? 'Character card successfully updated'
                                            : 'Character card successfully created',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      ElevatedButton(
                                        onPressed: () {
                                          // Ensure we're passing back clean system prompt
                                          final cleanPrompt =
                                              provider.characterCardSummary;

                                          Navigator.pop(context, {
                                            'characterCard': cleanPrompt,
                                            'characterName':
                                                provider.characterName,
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppTheme.etherealCyan,
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
                                        child: Text(
                                          provider.isEditMode
                                              ? 'Update Character'
                                              : 'Chat with Digital Clone',
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final message = provider.messages[index];
                            return ChatBubble(
                              message: message.text,
                              isUser: message.isUser,
                              isLoading: message.isLoading,
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
