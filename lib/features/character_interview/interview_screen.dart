// lib/features/character_interview/interview_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_selector/file_selector.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/animated_particles.dart';
import '../models/character_model.dart';
import 'interview_provider.dart';
import 'chat_bubble.dart';
import 'file_processor_service.dart';

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
  bool _isProcessingFile = false;

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

  Future<void> _handleFileUpload() async {
    setState(() => _isProcessingFile = true);

    try {
      final file = await FileProcessorService.pickFile();
      if (file == null) {
        setState(() => _isProcessingFile = false);
        return;
      }

      // Show processing message
      _interviewProvider.addAIMessage("Processing your file...");

      // Process the file
      final content = await FileProcessorService.processFile(file);

      // Generate character card
      final characterCard = await FileProcessorService.generateCharacterCard(
        content,
      );

      // Add the generated card to the chat
      _interviewProvider.addAIMessage(characterCard);

      // Store the character card summary in the provider
      if (characterCard.contains('## CHARACTER CARD SUMMARY ##') &&
          characterCard.contains('## END OF CHARACTER CARD ##')) {
        _interviewProvider.characterCardSummary = characterCard;

        // Try to extract character name
        if (characterCard.contains('## CHARACTER NAME:')) {
          final startName =
              characterCard.indexOf('## CHARACTER NAME:') +
              '## CHARACTER NAME:'.length;
          final endLine = characterCard.indexOf('\n', startName);
          if (endLine > startName) {
            final name = characterCard.substring(startName, endLine).trim();
            _interviewProvider.characterName = name.replaceAll('##', '').trim();
          }
        }
      }

      // Ask for confirmation
      _interviewProvider.addAIMessage(
        "I've created a character card based on your file. Please review it and type 'agree' if you'd like to use it, or let me know what changes you'd like to make.",
      );
    } catch (e) {
      _interviewProvider.addAIMessage(
        "I'm sorry, but I encountered an error processing your file: ${e.toString()}",
      );
    } finally {
      setState(() => _isProcessingFile = false);
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
            if (!widget.editMode)
              IconButton(
                icon: const Icon(Icons.upload_file),
                onPressed: _isProcessingFile ? null : _handleFileUpload,
                tooltip: 'Upload Character File',
              ),
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
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText:
                                        _isProcessingFile
                                            ? 'Processing file...'
                                            : 'Type your message...',
                                    hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  onSubmitted: (text) {
                                    if (!_isProcessingFile &&
                                        text.trim().isNotEmpty) {
                                      provider.sendMessage(text);
                                      _messageController.clear();
                                    }
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.send),
                                color: Colors.white,
                                onPressed:
                                    _isProcessingFile
                                        ? null
                                        : () {
                                          final text = _messageController.text;
                                          if (text.trim().isNotEmpty) {
                                            provider.sendMessage(text);
                                            _messageController.clear();
                                          }
                                        },
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
