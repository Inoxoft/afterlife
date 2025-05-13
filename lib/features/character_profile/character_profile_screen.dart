import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../models/character_model.dart';
import '../providers/characters_provider.dart';
import '../character_interview/interview_screen.dart';
import '../../core/widgets/model_selection_dialog.dart';

// Helper class to store parsed prompt sections
class _PromptSection {
  final String title;
  final String content;

  _PromptSection({required this.title, required this.content});
}

// Extension method to capitalize strings
extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) return this;
    return this[0].toUpperCase() + this.substring(1);
  }
}

class CharacterProfileScreen extends StatefulWidget {
  final String characterId;

  const CharacterProfileScreen({Key? key, required this.characterId})
    : super(key: key);

  @override
  State<CharacterProfileScreen> createState() => _CharacterProfileScreenState();
}

class _CharacterProfileScreenState extends State<CharacterProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _systemPromptController;
  CharacterModel? _character;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadCharacter();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _systemPromptController.dispose();
    super.dispose();
  }

  void _loadCharacter() {
    final charactersProvider = Provider.of<CharactersProvider>(
      context,
      listen: false,
    );

    try {
      final character = charactersProvider.characters.firstWhere(
        (c) => c.id == widget.characterId,
        orElse: () => throw Exception('Character not found'),
      );

      setState(() {
        _character = character;
        _nameController = TextEditingController(text: character.name);
        _systemPromptController = TextEditingController(
          text: character.systemPrompt,
        );
      });
    } catch (e) {
      print('Error loading character: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Could not load character'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    if (_character == null) return;

    try {
      final charactersProvider = Provider.of<CharactersProvider>(
        context,
        listen: false,
      );

      // Clean the system prompt before saving
      final cleanedPrompt = _cleanSystemPrompt(
        _systemPromptController.text.trim(),
        _nameController.text.trim(),
      );

      // Create updated character
      final updatedCharacter = CharacterModel(
        id: _character!.id,
        name: _nameController.text.trim(),
        systemPrompt: cleanedPrompt,
        imageUrl: _character!.imageUrl,
        createdAt: _character!.createdAt,
        accentColor: _character!.accentColor,
        chatHistory: _character!.chatHistory,
        additionalInfo: _character!.additionalInfo,
        model: _character!.model,
      );

      // Update in provider
      await charactersProvider.updateCharacter(updatedCharacter);

      setState(() {
        _isEditing = false;
        _character = updatedCharacter;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Changes saved successfully')),
        );
      }
    } catch (e) {
      print('Error saving changes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving changes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startReinterview() async {
    if (_character == null) return;

    // Navigate to interview screen with existing character data
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                InterviewScreen(editMode: true, existingCharacter: _character),
      ),
    );

    // Process result if the user completed the interview
    if (result != null && mounted) {
      final characterCard = result['characterCard'];
      final characterName = result['characterName'];

      if (characterCard != null && characterName != null) {
        try {
          final charactersProvider = Provider.of<CharactersProvider>(
            context,
            listen: false,
          );

          // Update the character in place with new data
          final originalCharacter = _character!;
          final cleanedPrompt = _cleanSystemPrompt(
            characterCard,
            characterName,
          );

          final updatedCharacter = CharacterModel(
            id: originalCharacter.id,
            name: characterName,
            systemPrompt: cleanedPrompt,
            imageUrl: originalCharacter.imageUrl,
            createdAt: originalCharacter.createdAt,
            accentColor: originalCharacter.accentColor,
            chatHistory: originalCharacter.chatHistory,
            additionalInfo: originalCharacter.additionalInfo,
            model: originalCharacter.model,
          );

          // Update the character
          await charactersProvider.updateCharacter(updatedCharacter);

          // Reload character data
          _loadCharacter();

          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Character updated successfully')),
            );
          }
        } catch (e) {
          print('Error updating character: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error updating character: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_character == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Character Profile'),
          backgroundColor: AppTheme.backgroundStart,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundStart,
        title: Text('${_character!.name}\'s Profile'),
        actions: [
          if (_isEditing)
            IconButton(icon: const Icon(Icons.save), onPressed: _saveChanges)
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Character Avatar with improved styling
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow effect
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _character!.accentColor.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                    // Character avatar
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _character!.accentColor.withOpacity(0.7),
                            _character!.accentColor.withOpacity(0.3),
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.6),
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _character!.name.isNotEmpty
                              ? _character!.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 4,
                                color: Colors.black26,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Character name display (when not editing)
              if (!_isEditing)
                Center(
                  child: Text(
                    _character!.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          blurRadius: 3,
                          color: Colors.black45,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Basic Information
              _buildSection(
                title: 'Basic Information',
                child: Column(
                  children: [
                    if (_isEditing)
                      _buildTextField(
                        label: 'Name',
                        controller: _nameController,
                        enabled: true,
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            const Text(
                              'Name:',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              _nameController.text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      label: 'Created',
                      value: _formatDate(_character!.createdAt),
                    ),
                    _buildInfoRow(
                      label: 'Chat Messages',
                      value: '${_character!.chatHistory.length}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // AI Model section styled like Biography
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.deepIndigo.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.warmGold.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI MODEL',
                      style: GoogleFonts.cinzel(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: AppTheme.warmGold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Model info with dropdown-like appearance
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.psychology_outlined,
                            size: 20,
                            color: AppTheme.warmGold,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getModelDisplayName(_character!.model),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  _getModelDescription(_character!.model),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: _showModelSelectionDialog,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.warmGold.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'CHANGE',
                                    style: TextStyle(
                                      color: AppTheme.warmGold,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    color: AppTheme.warmGold,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Re-Interview Button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.etherealCyan.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _startReinterview,
                      icon: const Icon(Icons.edit, size: 22),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        child: Text(
                          'Edit Character through chat',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.etherealCyan,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Character Card Actions
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        'Character Card Options',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildCardOptionButton(
                            icon: Icons.visibility,
                            label: 'View Card Info',
                            onPressed: _showCharacterCardInfo,
                            backgroundColor: _character!.accentColor
                                .withOpacity(0.8),
                          ),
                          _buildCardOptionButton(
                            icon: Icons.psychology,
                            label: 'Change AI Model',
                            onPressed: _showModelSelectionDialog,
                            backgroundColor: AppTheme.etherealCyan.withOpacity(
                              0.8,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // System Prompt
              _buildSection(
                title: 'System Prompt',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isEditing)
                      _buildTextField(
                        label: 'System Prompt',
                        controller: _systemPromptController,
                        enabled: true,
                        maxLines: 15,
                      )
                    else
                      Container(
                        height: 300,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Styled text for system prompt
                                    Text(
                                      _systemPromptController.text,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        height: 1.5,
                                      ),
                                    ),
                                    // Add extra padding at the bottom to avoid text being hidden by copy button
                                    const SizedBox(height: 40),
                                  ],
                                ),
                              ),
                            ),
                            // Copy button overlay
                            Positioned(
                              right: 8,
                              bottom: 8,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.content_copy,
                                    color: Colors.white70,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(
                                        text: _systemPromptController.text,
                                      ),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Prompt copied to clipboard',
                                        ),
                                      ),
                                    );
                                  },
                                  tooltip: 'Copy prompt',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    if (!_isEditing)
                      Center(
                        child: Text(
                          '↑ Scroll to view full prompt ↑',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Add some spacing at the bottom for better scrolling experience
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  title == 'Basic Information'
                      ? Icons.person
                      : Icons.text_fields,
                  color: _character!.accentColor,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        blurRadius: 2,
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white24, thickness: 1, height: 24),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withOpacity(0.8),
          fontWeight: FontWeight.w500,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _character!.accentColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.black26,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
    );
  }

  Widget _buildInfoRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _character!.accentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _character!.accentColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      if (difference.inHours < 1) {
        return 'Just now';
      } else {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      }
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Helper method to clean system prompts
  String _cleanSystemPrompt(String prompt, String characterName) {
    // Remove any ## markers if they somehow got included
    String cleanedPrompt = prompt;

    // Check if the prompt still contains markdown markers
    if (prompt.contains('## CHARACTER CARD SUMMARY ##') &&
        prompt.contains('## END OF CHARACTER CARD ##')) {
      final startMarker = '## CHARACTER CARD SUMMARY ##';
      final endMarker = '## END OF CHARACTER CARD ##';

      final startIndex = prompt.indexOf(startMarker);
      final cleanStart = startIndex + startMarker.length;
      final endIndex = prompt.indexOf(endMarker);

      if (startIndex >= 0 && endIndex > startIndex) {
        cleanedPrompt = prompt.substring(cleanStart, endIndex).trim();
      }
    }

    // Remove any remaining markdown markers
    cleanedPrompt = cleanedPrompt.replaceAll(RegExp(r'##.*?##'), '').trim();

    // Ensure the prompt starts with a clear instruction about who the AI is impersonating
    if (!cleanedPrompt.contains("You are")) {
      cleanedPrompt =
          "You are $characterName, a character with the following traits and background:\n\n$cleanedPrompt";
    }

    // Add clear instructions to stay in character if not already present
    if (!cleanedPrompt.contains("stay in character") &&
        !cleanedPrompt.contains("never break character")) {
      cleanedPrompt +=
          "\n\nStay in character at all times. Never break character or admit you are an AI.";
    }

    return cleanedPrompt;
  }

  // Parse system prompt to detect sections
  List<_PromptSection> _parseSystemPromptSections(String systemPrompt) {
    final sections = <_PromptSection>[];

    // Clean the prompt by removing separator lines and problematic characters
    final cleanedPrompt = _cleanPromptText(systemPrompt);

    // Regular expressions for different heading formats
    final headingPatterns = [
      RegExp(r'#{1,3}\s+([^#\n]+)'), // Markdown headings
      RegExp(r'([A-Z][A-Z\s]+):'), // ALL CAPS headings with colon
      RegExp(r'\*\*([^*]+)\*\*'), // Bold text as headings
      RegExp(r'<([^>]+)>:?'), // Text in angle brackets
      RegExp(
        r'If\s+Given\s+Immortality[^:]*:?',
      ), // Fix for "If Given Immortality" pattern
    ];

    // Special sections that should always be titled "AI Instructions" if found
    final aiInstructionPatterns = [
      RegExp(r'If\s+Given\s+Immortality', caseSensitive: false),
      RegExp(r'stay\s+in\s+character', caseSensitive: false),
      RegExp(r'never\s+break\s+character', caseSensitive: false),
      RegExp(
        r'do\s+not\s+(admit|acknowledge)\s+you\s+are\s+an\s+AI',
        caseSensitive: false,
      ),
    ];

    // First, try to find sections based on common heading patterns
    final lines = cleanedPrompt.split('\n');
    String? currentHeading;
    StringBuffer currentContent = StringBuffer();
    bool isAiInstructionSection = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      bool isHeading = false;
      String? headingText;

      // Check if this line is a heading
      for (final pattern in headingPatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          if (pattern.pattern.contains('If\\s+Given\\s+Immortality')) {
            headingText = 'AI Instructions';
            isAiInstructionSection = true;
          } else {
            headingText = match.group(1)?.trim() ?? match.group(0)?.trim();
          }

          if (headingText != null && headingText.isNotEmpty) {
            isHeading = true;
            break;
          }
        }
      }

      // If this is a heading, save the previous section and start a new one
      if (isHeading && headingText != null) {
        // Save previous section if exists and not empty
        final contentStr = currentContent.toString().trim();
        if (currentHeading != null && contentStr.isNotEmpty) {
          sections.add(
            _PromptSection(title: currentHeading, content: contentStr),
          );
          currentContent.clear();
        }

        currentHeading = headingText;
        isAiInstructionSection = currentHeading == 'AI Instructions';
      } else {
        // Check if this line contains AI instruction patterns
        if (!isAiInstructionSection && currentHeading == null) {
          for (final pattern in aiInstructionPatterns) {
            if (pattern.hasMatch(line)) {
              // If we find AI instructions but we're not in an AI section,
              // create a new AI Instructions section
              if (currentContent.isNotEmpty) {
                // Save previous content to a generic section
                sections.add(
                  _PromptSection(
                    title: 'Character Description',
                    content: currentContent.toString().trim(),
                  ),
                );
                currentContent.clear();
              }
              currentHeading = 'AI Instructions';
              isAiInstructionSection = true;
              break;
            }
          }
        }

        // This is content - add to current section
        if (currentHeading != null) {
          currentContent.writeln(line);
        } else if (line.trim().isNotEmpty) {
          // If no heading yet but we have content, buffer it
          currentContent.writeln(line);
        }
      }
    }

    // Add the last section if not empty
    final finalContent = currentContent.toString().trim();
    if (currentHeading != null && finalContent.isNotEmpty) {
      sections.add(
        _PromptSection(title: currentHeading, content: finalContent),
      );
    } else if (finalContent.isNotEmpty) {
      // If there's content without a heading, add as character description
      sections.add(
        _PromptSection(title: 'Character Description', content: finalContent),
      );
    }

    // If no sections were detected, create a default section
    if (sections.isEmpty) {
      sections.add(
        _PromptSection(
          title: 'Character Description',
          content: cleanedPrompt.trim(),
        ),
      );
    }

    return sections;
  }

  // Helper to clean prompt text of separators and problematic characters
  String _cleanPromptText(String text) {
    // First remove separator lines
    String cleaned = _removeAllSeparatorLines(text);

    // Remove non-standard characters and Unicode control chars
    cleaned = cleaned.replaceAll(
      RegExp(r'[\u0080-\u009F\u200B-\u200F\u2028-\u202F\uFEFF]'),
      '',
    );

    // Replace "ã" characters often seen in "Immortalityã" with nothing
    cleaned = cleaned.replaceAll('ã', '');

    // Replace common malformed patterns
    cleaned = cleaned.replaceAll(
      'If Given Immortalityï¿½:',
      'AI Instructions:',
    );
    cleaned = cleaned.replaceAll('If Given Immortality:', 'AI Instructions:');

    return cleaned;
  }

  // Helper to remove all separator lines from a string
  String _removeAllSeparatorLines(String text) {
    // Define a pattern for separator lines
    final separatorPattern = RegExp(r'^[-_*=]{3,}$');

    // Split the text into lines, filter out the separators, and join back
    final lines = text.split('\n');
    final filteredLines =
        lines.where((line) {
          final trimmed = line.trim();
          return trimmed.isEmpty || !separatorPattern.hasMatch(trimmed);
        }).toList();

    return filteredLines.join('\n');
  }

  // Show character card info dialog with AI-structured information
  void _showCharacterCardInfo() {
    if (_character == null) {
      print('Error: Character is null when trying to show character card info');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Could not load character information'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('Showing character card info for: ${_character!.name}');

    // Parse the system prompt to detect headings and sections
    final parsedSections = _parseSystemPromptSections(_character!.systemPrompt);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppTheme.backgroundStart,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: _character!.accentColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    'Character Card: ${_character!.name}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.content_copy,
                    size: 20,
                    color: Colors.white70,
                  ),
                  onPressed: () {
                    _copyFullCharacterCard();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Full character card copied to clipboard',
                        ),
                      ),
                    );
                  },
                  tooltip: 'Copy full card',
                ),
              ],
            ),
            content: Container(
              width: double.maxFinite,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic information section
                    _buildInfoSection(
                      title: 'Basic Information',
                      content: [
                        _buildInfoItem(label: 'Name', value: _character!.name),
                        _buildInfoItem(
                          label: 'Created',
                          value: _formatDate(_character!.createdAt),
                        ),
                      ],
                    ),

                    // Divider
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Container(
                        height: 1,
                        color: _character!.accentColor.withOpacity(0.3),
                      ),
                    ),

                    // AI Model section styled like Biography
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI MODEL',
                          style: GoogleFonts.cinzel(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                            color: AppTheme.warmGold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24, width: 1),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.psychology_outlined,
                                size: 20,
                                color: AppTheme.warmGold,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getModelDisplayName(_character!.model),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      _getModelDescription(_character!.model),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                    if (_character!.imageUrl != null &&
                        _character!.imageUrl!.isNotEmpty)
                      _buildInfoItem(
                        label: 'Image URL',
                        value: _character!.imageUrl!,
                      ),

                    // Divider
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Container(
                        height: 1,
                        color: _character!.accentColor.withOpacity(0.3),
                      ),
                    ),

                    // Dynamic sections from system prompt
                    ...parsedSections
                        .where((section) => section.content.trim().isNotEmpty)
                        .map(
                          (section) => _buildInfoSection(
                            title: section.title,
                            content: [
                              _buildInfoItem(
                                value: section.content,
                                isMultiline: true,
                              ),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
    );
  }

  // Helper method to build a section with a title and content
  Widget _buildInfoSection({
    required String title,
    required List<Widget> content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: _character!.accentColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        ...content,
        const SizedBox(height: 16),
      ],
    );
  }

  // Helper method to build an info item with label and value
  Widget _buildInfoItem({
    String? label,
    required String value,
    bool isMultiline = false,
    bool isModelInfo = false,
    Color? accentColor,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(
              label,
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
          ],
          if (isModelInfo && accentColor != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accentColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            )
          else
            SelectableText(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: isMultiline ? 14 : 15,
                height: isMultiline ? 1.5 : 1.2,
              ),
            ),
        ],
      ),
    );
  }

  // Copy full character card to clipboard
  void _copyFullCharacterCard() {
    Clipboard.setData(ClipboardData(text: _formatCharacterCard()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Full character card copied to clipboard')),
    );
  }

  // Format character card for display or export
  String _formatCharacterCard() {
    final sb = StringBuffer();
    sb.writeln('## CHARACTER CARD ##');
    sb.writeln('Name: ${_character!.name}');
    sb.writeln('Created: ${_formatDate(_character!.createdAt)}');
    if (_character!.imageUrl != null) {
      sb.writeln('Image URL: ${_character!.imageUrl}');
    }
    sb.writeln('\n## CHARACTER PROMPT ##');
    sb.writeln(_character!.systemPrompt);
    sb.writeln('\n## END OF CHARACTER CARD ##');

    return sb.toString();
  }

  // Add the helper method for building card option buttons
  Widget _buildCardOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color backgroundColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _character!.accentColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  // Show model selection dialog and update if changed
  Future<void> _showModelSelectionDialog() async {
    if (_character == null) return;

    final selectedModel = await ModelSelectionDialog.show(
      context,
      currentModel: _character!.model,
    );

    if (selectedModel != null && selectedModel != _character!.model) {
      try {
        final charactersProvider = Provider.of<CharactersProvider>(
          context,
          listen: false,
        );

        // Create updated character with new model
        final updatedCharacter = CharacterModel(
          id: _character!.id,
          name: _character!.name,
          systemPrompt: _character!.systemPrompt,
          imageUrl: _character!.imageUrl,
          createdAt: _character!.createdAt,
          accentColor: _character!.accentColor,
          chatHistory: _character!.chatHistory,
          additionalInfo: _character!.additionalInfo,
          model: selectedModel,
        );

        // Update in provider
        await charactersProvider.updateCharacter(updatedCharacter);

        setState(() {
          _character = updatedCharacter;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('AI model updated successfully')),
          );
        }
      } catch (e) {
        print('Error updating model: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating model: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Get a user-friendly name for the model
  String _getModelDisplayName(String modelId) {
    // Look up model information from a map similar to the one in ModelSelectionDialog
    final Map<String, Map<String, String>> modelInfo = {
      'google/gemini-2.0-flash-001': {
        'name': 'Gemini 2.0 Flash',
        'provider': 'Google',
      },
      'anthropic/claude-3-5-sonnet': {
        'name': 'Claude 3.5 Sonnet',
        'provider': 'Anthropic',
      },
      'google/gemini-2.0-pro-001': {
        'name': 'Gemini 2.0 Pro',
        'provider': 'Google',
      },
      'anthropic/claude-3-opus': {
        'name': 'Claude 3 Opus',
        'provider': 'Anthropic',
      },
      'meta-llama/llama-3-70b-instruct': {
        'name': 'Llama 3 70B',
        'provider': 'Meta',
      },
      'openai/gpt-4o': {'name': 'GPT-4o', 'provider': 'OpenAI'},
    };

    // If we have info for this model, return formatted name
    if (modelInfo.containsKey(modelId)) {
      final info = modelInfo[modelId]!;
      return '${info['name']} by ${info['provider']}';
    }

    // Fallback to the previous parsing method if model not in our map
    final parts = modelId.split('/');
    if (parts.length < 2) return modelId;

    // Get provider and model parts
    final provider = parts[0].capitalize();
    final model = parts[1].replaceAll('-', ' ').capitalize();

    return '$model by $provider';
  }

  // Get a description for the AI model
  String _getModelDescription(String modelId) {
    final Map<String, String> modelDescriptions = {
      'google/gemini-2.0-flash-001': 'Fast responses with good quality',
      'anthropic/claude-3-5-sonnet':
          'High quality responses with strong reasoning',
      'google/gemini-2.0-pro-001': 'Higher quality responses than Flash',
      'anthropic/claude-3-opus':
          'Top-tier intelligence, slower and more expensive',
      'meta-llama/llama-3-70b-instruct':
          'Open-source model with good capabilities',
      'openai/gpt-4o': 'Powerful model with excellent language understanding',
    };

    return modelDescriptions[modelId] ?? 'Advanced language model';
  }
}
