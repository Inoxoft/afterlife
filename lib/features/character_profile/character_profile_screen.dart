import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../models/character_model.dart';
import '../providers/characters_provider.dart';
import '../character_interview/interview_screen.dart';

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

          // Create updated character with new system prompt but keep chat history
          final updatedCharacter = CharacterModel(
            id: _character!.id,
            name: characterName,
            systemPrompt: _cleanSystemPrompt(characterCard, characterName),
            imageUrl: _character!.imageUrl,
            createdAt: _character!.createdAt,
            accentColor: _character!.accentColor,
            chatHistory: _character!.chatHistory,
            additionalInfo: _character!.additionalInfo,
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

              // Re-Interview Button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Container(
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
                      icon: const Icon(Icons.refresh, size: 22),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        child: Text(
                          'Re-Interview Character',
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
                        child: ClipRRect(
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
                              ],
                            ),
                          ),
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
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
}
