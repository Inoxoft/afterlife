// lib/features/character_interview/interview_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/animated_particles.dart';
import '../models/character_model.dart';
import '../providers/characters_provider.dart';
import '../character_gallery/character_gallery_screen.dart';
import 'interview_provider.dart';
import 'chat_bubble.dart';
import 'file_processor_service.dart';
import 'package:path/path.dart' as path;

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

  Future<void> _handleFileUpload() async {
    try {
      setState(() {
        _interviewProvider.addAIMessage("Processing your file(s)...");
        _isProcessingFile = true;
      });

      final files = await FileProcessorService.pickFile();

      if (files == null || files.isEmpty) {
        setState(() {
          _interviewProvider.addAIMessage("No files selected.");
          _isProcessingFile = false;
        });
        return;
      }

      // Processing status message
      _interviewProvider.addAIMessage(
        "Processing ${files.length} ${files.length == 1 ? 'file' : 'files'} to create your character...",
      );

      // Combine content from all files
      final StringBuffer contentBuffer = StringBuffer();
      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final fileName = path.basename(file.path);

        // Add file separator if not the first file
        if (i > 0) {
          contentBuffer.writeln("\n\n--- Content from file: $fileName ---\n");
        } else {
          contentBuffer.writeln("--- Content from file: $fileName ---\n");
        }

        // Process the file and add its content
        final fileContent = await FileProcessorService.processFile(file);
        contentBuffer.writeln(fileContent);

        // Update progress
        _interviewProvider.addAIMessage(
          "Processed file ${i + 1}/${files.length}: $fileName",
        );
      }

      // Generate a single character card from all combined content
      final combinedContent = contentBuffer.toString();
      final characterCard = await FileProcessorService.generateCharacterCard(
        combinedContent,
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
        "I've created a character card based on your ${files.length > 1 ? 'files' : 'file'}. "
        "Please review it and type 'agree' if you'd like to use it, or let me know what changes you'd like to make.",
      );
    } catch (e) {
      _interviewProvider.addAIMessage(
        "I'm sorry, but I encountered an error processing your file(s): ${e.toString()}",
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
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.upload_file, color: Colors.white70),
                  onPressed: _isProcessingFile ? null : _handleFileUpload,
                  tooltip: 'Upload Character File',
                ),
              ),
            Consumer<InterviewProvider>(
              builder: (context, provider, _) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white70),
                    tooltip: 'Restart Interview',
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
                  ),
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
                                margin: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppTheme.etherealCyan.withOpacity(
                                      0.3,
                                    ),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.etherealCyan.withOpacity(
                                        0.1,
                                      ),
                                      blurRadius: 15,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        color: AppTheme.etherealCyan,
                                        size: 48,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        provider.isEditMode
                                            ? 'Character card successfully updated'
                                            : 'Character card successfully created',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        provider.isEditMode
                                            ? 'Your digital twin has been updated with the new information'
                                            : 'Your digital twin is ready to chat with you',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 24),
                                      AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.etherealCyan,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.etherealCyan
                                                  .withOpacity(0.3),
                                              blurRadius: 8,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            // Ensure we're passing back clean system prompt
                                            final cleanPrompt =
                                                provider.characterCardSummary;
                                            final characterName =
                                                provider.characterName ??
                                                "Character";

                                            if (cleanPrompt == null) {
                                              print(
                                                'Error: Character prompt is null',
                                              );
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Error: Character information is incomplete. Please try again.',
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                              return;
                                            }

                                            // Ensure we have a non-empty character name
                                            final finalCharacterName =
                                                characterName.trim().isEmpty
                                                    ? "Character"
                                                    : characterName;

                                            print(
                                              'Character creation successful:',
                                            );
                                            print('Name: $finalCharacterName');
                                            print(
                                              'System prompt length: ${cleanPrompt.length}',
                                            );

                                            try {
                                              // Create the character directly here
                                              final charactersProvider =
                                                  Provider.of<
                                                    CharactersProvider
                                                  >(context, listen: false);

                                              // Create new character
                                              final newCharacter =
                                                  CharacterModel.fromInterviewData(
                                                    name: finalCharacterName,
                                                    cardContent: cleanPrompt,
                                                  );

                                              print(
                                                'Character created with ID: ${newCharacter.id}',
                                              );

                                              // Add character to provider
                                              await charactersProvider
                                                  .addCharacter(newCharacter);
                                              print(
                                                'Character saved successfully',
                                              );

                                              // Navigate directly to "Your Twins" gallery screen
                                              if (context.mounted) {
                                                print(
                                                  'Navigating to Your Twins gallery screen',
                                                );
                                                Navigator.pushReplacement(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (context) =>
                                                            const CharacterGalleryScreen(),
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              print(
                                                'Error creating character: $e',
                                              );
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text('Error: $e'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 32,
                                              vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                provider.isEditMode
                                                    ? 'Update Character'
                                                    : 'Continue to Gallery',
                                                style: const TextStyle(
                                                  color: Colors.black87,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(
                                                Icons.arrow_forward,
                                                color: Colors.black87,
                                                size: 18,
                                              ),
                                            ],
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
                              message: message,
                              showAvatar: true,
                              avatarText: message.isUser ? "You" : "AI",
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
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black26,
                                    borderRadius: BorderRadius.circular(25.0),
                                    border: Border.all(
                                      color: Colors.white10,
                                      width: 1,
                                    ),
                                  ),
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
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          25.0,
                                        ),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                      prefixIcon: Icon(
                                        Icons.chat_bubble_outline,
                                        color: AppTheme.etherealCyan
                                            .withOpacity(0.5),
                                        size: 18,
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
                              ),
                              const SizedBox(width: 12.0),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.etherealCyan,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.etherealCyan.withOpacity(
                                        0.3,
                                      ),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.send),
                                  color: Colors.black87,
                                  onPressed:
                                      _isProcessingFile
                                          ? null
                                          : () {
                                            final text =
                                                _messageController.text;
                                            if (text.trim().isNotEmpty) {
                                              provider.sendMessage(text);
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
