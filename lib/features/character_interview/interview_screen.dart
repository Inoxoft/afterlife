// lib/features/character_interview/interview_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/animated_particles.dart';
import '../models/character_model.dart';
import '../providers/characters_provider.dart';
import '../providers/language_provider.dart';
import '../character_gallery/character_gallery_screen.dart';
import 'interview_provider.dart';
import 'chat_bubble.dart';
import 'file_processor_service.dart';
import 'package:path/path.dart' as path;
import 'package:google_fonts/google_fonts.dart';
import '../chat/models/chat_message.dart';
import '../chat/widgets/chat_message_bubble.dart';

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
    
    // Inject the LanguageProvider
    final languageProvider = context.read<LanguageProvider>();
    _interviewProvider.setLanguageProvider(languageProvider);

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
                              backgroundColor: AppTheme.midnightPurple,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: AppTheme.warmGold.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: AppTheme.silverMist,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    provider.resetInterview();
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    'Restart',
                                    style: TextStyle(color: AppTheme.warmGold),
                                  ),
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: provider.messages.length + (provider.isSuccess ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (provider.isSuccess && index == provider.messages.length) {
                              return _buildSuccessMessage(context, provider);
                            }

                            final message = provider.messages[index];
                            return ChatMessageBubble(
                              message: ChatMessage(
                                content: message.text,
                                isUser: message.isUser,
                                timestamp: DateTime.now(), // TODO: Add actual timestamp to messages
                              ),
                              showAvatar: true,
                              avatarText: message.isUser ? 'You' : 'AI',
                              avatarIcon: message.isUser ? Icons.person : null,
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // Input area
                  Consumer<InterviewProvider>(
                    builder: (context, provider, _) {
                      if (provider.isSuccess) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.midnightPurple.withOpacity(0.3),
                          border: Border(
                            top: BorderSide(
                              color: AppTheme.warmGold.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                style: TextStyle(color: AppTheme.silverMist),
                                decoration: InputDecoration(
                                  hintText: 'Type your message...',
                                  hintStyle: TextStyle(
                                    color: AppTheme.silverMist.withOpacity(0.5),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: BorderSide(
                                      color: AppTheme.warmGold.withOpacity(0.3),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: BorderSide(
                                      color: AppTheme.warmGold.withOpacity(0.3),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: BorderSide(
                                      color: AppTheme.warmGold,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                ),
                                onSubmitted: (_) => _sendMessage(provider),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.warmGold,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.send),
                                color: AppTheme.midnightPurple,
                                onPressed: () => _sendMessage(provider),
                              ),
                            ),
                          ],
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

  Widget _buildSuccessMessage(BuildContext context, InterviewProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.midnightPurple.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.warmGold.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Interview Complete!',
            style: GoogleFonts.cinzel(
              color: AppTheme.warmGold,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'I have gathered enough information to create your digital twin.',
            style: GoogleFonts.lato(
              color: AppTheme.silverMist,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (provider.isEditMode) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, '/gallery');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warmGold,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  provider.isEditMode ? 'Update Character' : 'Continue to Gallery',
                  style: GoogleFonts.lato(
                    color: AppTheme.midnightPurple,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward,
                  color: AppTheme.midnightPurple,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(InterviewProvider provider) {
    final text = _messageController.text;
    if (text.trim().isNotEmpty) {
      provider.sendMessage(text);
      _messageController.clear();
    }
  }
}
