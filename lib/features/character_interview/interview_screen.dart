import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import '../../core/theme/app_theme.dart';
import '../../core/utils/ukrainian_font_utils.dart';
import '../../core/widgets/animated_particles.dart';
import '../../core/utils/responsive_utils.dart';
import '../models/character_model.dart';
import '../providers/characters_provider.dart';
import '../providers/language_provider.dart';
import '../character_gallery/character_gallery_screen.dart';
import '../chat/models/chat_message.dart';
import '../chat/widgets/chat_message_bubble.dart';
import 'interview_provider.dart';
import 'file_processor_service.dart';
import '../../l10n/app_localizations.dart';

class InterviewScreen extends StatefulWidget {
  final bool editMode;
  final CharacterModel? existingCharacter;

  const InterviewScreen({
    super.key,
    this.editMode = false,
    this.existingCharacter,
  });

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
    // Get the CharactersProvider first to avoid context issues
    final charactersProvider = Provider.of<CharactersProvider>(
      context,
      listen: false,
    );

    _interviewProvider = InterviewProvider(
      onCharacterSaved: (character) async {
        // Save the character using the CharactersProvider
        await charactersProvider.addCharacter(character);

        // Don't auto-navigate - let the user navigate manually with the button
        // The success button will handle navigation when the user is ready
      },
    );

    // Inject the LanguageProvider and set the initial localized message
    final languageProvider = context.read<LanguageProvider>();
    _interviewProvider.setLanguageProvider(languageProvider);

    // Set the initial welcome message in the user's preferred language
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final localizations = AppLocalizations.of(context);
      _interviewProvider.setInitialMessage(
        localizations.interviewWelcomeMessage,
      );
    });

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
    final localizations = AppLocalizations.of(context);

    try {
      setState(() {
        _interviewProvider.addAIMessage(localizations.processingFiles);
        _isProcessingFile = true;
      });

      final files = await FileProcessorService.pickFile();

      if (files == null || files.isEmpty) {
        setState(() {
          _interviewProvider.addAIMessage(localizations.noFilesSelected);
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
        _interviewProvider.updateCardSummary(characterCard);
      }

      // Ask for confirmation
      _interviewProvider.addAIMessage(
        "Perfect! I've created your character card based on your ${files.length > 1 ? 'files' : 'file'}. "
        "Review it above and:\n\n"
        "• Type 'agree' to save your character\n"
        "• Or describe any changes you'd like me to make (e.g., 'make them more outgoing', 'change their background to include more travel')",
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
    final fontScale = ResponsiveUtils.getFontSizeScale(context);
    final localizations = AppLocalizations.of(context);

    return ChangeNotifierProvider(
      create: (_) => _interviewProvider,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.backgroundStart,
          elevation: 0,
          title: Text(
            widget.editMode
                ? localizations.editingCharacter.replaceAll(
                  '{name}',
                  widget.existingCharacter?.name ?? 'Character',
                )
                : localizations.creatingYourDigitalTwin,
            style: TextStyle(
              fontSize: 18 * fontScale,
              fontWeight: FontWeight.w500,
            ),
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
                  tooltip: localizations.uploadCharacterFile,
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
                    tooltip: localizations.restartInterview,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: Text(localizations.restartInterview),
                              content: Text(
                                localizations.restartInterviewConfirmation,
                              ),
                              backgroundColor: AppTheme.midnightPurple,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: AppTheme.warmGold.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 1,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    localizations.cancel,
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
                                    localizations.restart,
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
                      builder: (context, provider, child) {
                        // Scroll to bottom when new messages are added
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_scrollController.hasClients) {
                            _scrollController.jumpTo(
                              _scrollController.position.maxScrollExtent,
                            );
                          }
                        });

                        return ListView.builder(
                          controller: _scrollController,
                          padding: ResponsiveUtils.getChatListPadding(context),
                          itemCount: provider.messages.length,
                          itemBuilder: (context, index) {
                            final message = provider.messages[index];
                            if (message.isLoading) {
                              // Display a loading indicator bubble
                              return ChatMessageBubble(
                                text: '...',
                                isUser: false,
                                showAvatar: true,
                                avatarText: 'AI',
                              );
                            }
                            return ChatMessageBubble(
                              text:
                                  message.text.contains(
                                        '## CHARACTER CARD SUMMARY ##',
                                      )
                                      ? _formatCharacterCard(message.text)
                                      : message.text,
                              isUser: message.isUser,
                              showAvatar: true,
                              avatarText: message.isUser ? 'You' : 'AI',
                              avatarIcon: message.isUser ? Icons.person : null,
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // Success message when character is created
                  Consumer<InterviewProvider>(
                    builder: (context, provider, child) {
                      if (provider.isSuccess) {
                        return _buildSuccessMessage(
                          context,
                          provider,
                          localizations,
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Finalize button area
                  Consumer<InterviewProvider>(
                    builder: (context, provider, child) {
                      if (provider.isCardReadyForFinalize) {
                        // Find the last message containing the character card
                        final cardMessage = provider.messages.lastWhere(
                          (msg) =>
                              !msg.isUser &&
                              msg.text.contains('## CHARACTER CARD SUMMARY ##'),
                          orElse: () => provider.messages.last,
                        );

                        return Column(
                          children: [
                            // Highlighted character card container
                            Container(
                              margin: const EdgeInsets.all(16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.warmGold.withOpacity(0.15),
                                    AppTheme.midnightPurple.withOpacity(0.3),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.warmGold.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.warmGold.withOpacity(0.1),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: AppTheme.midnightPurple.withOpacity(
                                      0.2,
                                    ),
                                    blurRadius: 15,
                                    spreadRadius: -2,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: AppTheme.warmGold,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        localizations.characterCardReady,
                                        style: TextStyle(
                                          color: AppTheme.warmGold,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.warmGold.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppTheme.warmGold.withValues(
                                          alpha: 0.3,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      localizations.reviewCharacterCard,
                                      style: TextStyle(
                                        color: AppTheme.silverMist,
                                        fontSize: 14,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.midnightPurple
                                          .withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppTheme.warmGold.withValues(
                                          alpha: 0.2,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Name marker highlight
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                            horizontal: 12,
                                          ),
                                          margin: const EdgeInsets.only(
                                            bottom: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.warmGold
                                                .withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: AppTheme.warmGold
                                                  .withValues(alpha: 0.5),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            cardMessage.text
                                                .split('\n')
                                                .firstWhere(
                                                  (line) => line.contains(
                                                    '## CHARACTER NAME:',
                                                  ),
                                                  orElse: () => '',
                                                ),
                                            style: TextStyle(
                                              color: AppTheme.warmGold,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        // Summary marker and content highlight
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: AppTheme.warmGold
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: AppTheme.warmGold
                                                  .withValues(alpha: 0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Summary start marker
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 4,
                                                      horizontal: 8,
                                                    ),
                                                margin: const EdgeInsets.only(
                                                  bottom: 12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.warmGold
                                                      .withOpacity(0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '## CHARACTER CARD SUMMARY ##',
                                                  style: TextStyle(
                                                    color: AppTheme.warmGold,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              // Card content
                                              SelectableText(
                                                _extractCardContent(
                                                  cardMessage.text,
                                                ),
                                                style: TextStyle(
                                                  color: AppTheme.silverMist,
                                                  fontSize: 14,
                                                  height: 1.6,
                                                ),
                                              ),
                                              // Summary end marker
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 4,
                                                      horizontal: 8,
                                                    ),
                                                margin: const EdgeInsets.only(
                                                  top: 12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.warmGold
                                                      .withOpacity(0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '## END OF CHARACTER CARD ##',
                                                  style: TextStyle(
                                                    color: AppTheme.warmGold,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Finalize button
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  provider.sendMessage('agree');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.warmGold,
                                  foregroundColor: AppTheme.midnightPurple,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  localizations.finalizeCharacter,
                                  style:
                                      UkrainianFontUtils.cinzelWithUkrainianSupport(
                                        text: localizations.finalizeCharacter,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Message input
                  Consumer<InterviewProvider>(
                    builder: (context, provider, _) {
                      if (provider.isSuccess) {
                        return const SizedBox.shrink();
                      }

                      return Container(
                        padding: ResponsiveUtils.getChatInputPadding(context),
                        decoration: BoxDecoration(
                          color: AppTheme.midnightPurple.withValues(alpha: 0.3),
                          border: Border(
                            top: BorderSide(
                              color: AppTheme.warmGold.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                focusNode: _inputFocusNode,
                                style: TextStyle(
                                  color: AppTheme.silverMist,
                                  fontSize: 14 * fontScale,
                                ),
                                decoration: InputDecoration(
                                  hintText: localizations.typeYourMessage,
                                  hintStyle: TextStyle(
                                    color: AppTheme.silverMist.withValues(
                                      alpha: 0.5,
                                    ),
                                    fontSize: 14 * fontScale,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: BorderSide(
                                      color: AppTheme.warmGold.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: BorderSide(
                                      color: AppTheme.warmGold.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: BorderSide(
                                      color: AppTheme.warmGold,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20 * fontScale,
                                    vertical: 10 * fontScale,
                                  ),
                                ),
                                onSubmitted: (_) => _sendMessage(provider),
                              ),
                            ),
                            SizedBox(width: 8 * fontScale),
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.warmGold,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: IconButton(
                                icon: Icon(Icons.send, size: 20 * fontScale),
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

  Widget _buildSuccessMessage(
    BuildContext context,
    InterviewProvider provider,
    AppLocalizations localizations,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.midnightPurple.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.warmGold.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            localizations.interviewComplete,
            style: UkrainianFontUtils.cinzelWithUkrainianSupport(
              text: localizations.interviewComplete,
              color: AppTheme.warmGold,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            localizations.interviewCompleteDescription,
            style: UkrainianFontUtils.latoWithUkrainianSupport(
              text: localizations.interviewCompleteDescription,
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
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CharacterGalleryScreen(),
                  ),
                );
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
                  provider.isEditMode
                      ? localizations.updateCharacter
                      : localizations.continueToGallery,
                  style: UkrainianFontUtils.latoWithUkrainianSupport(
                    text:
                        provider.isEditMode
                            ? localizations.updateCharacter
                            : localizations.continueToGallery,
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

  void _sendMessage(InterviewProvider provider) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Clear the input field
    _messageController.clear();

    // Send the message
    provider.sendMessage(text);
  }

  String _extractCardContent(String text) {
    final startMarker = '## CHARACTER CARD SUMMARY ##';
    final endMarker = '## END OF CHARACTER CARD ##';

    final startIndex = text.indexOf(startMarker) + startMarker.length;
    final endIndex = text.indexOf(endMarker);

    if (startIndex >= 0 && endIndex > startIndex) {
      return text.substring(startIndex, endIndex).trim();
    }
    return text;
  }

  // Add this helper method to format the character card
  String _formatCharacterCard(String text) {
    final lines = text.split('\n');
    final formattedLines = <String>[];
    bool isInSummary = false;

    for (final line in lines) {
      if (line.contains('## CHARACTER NAME:')) {
        formattedLines.add('<highlight>$line</highlight>');
      } else if (line.contains('## CHARACTER CARD SUMMARY ##')) {
        isInSummary = true;
        formattedLines.add('<highlight>$line</highlight>');
      } else if (line.contains('## END OF CHARACTER CARD ##')) {
        isInSummary = false;
        formattedLines.add('<highlight>$line</highlight>');
      } else if (isInSummary && line.startsWith('### ')) {
        // Highlight section headers
        formattedLines.add('<section>$line</section>');
      } else {
        formattedLines.add(line);
      }
    }

    return formattedLines.join('\n');
  }
}
