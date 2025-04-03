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
        title: const Text('Character Profile'),
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
              // Character Avatar
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: _character!.accentColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _character!.accentColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _character!.name.isNotEmpty
                          ? _character!.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: _character!.accentColor,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Basic Information
              _buildSection(
                title: 'Basic Information',
                child: Column(
                  children: [
                    _buildTextField(
                      label: 'Name',
                      controller: _nameController,
                      enabled: _isEditing,
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
              const SizedBox(height: 24),

              // Re-Interview Button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: ElevatedButton.icon(
                  onPressed: _startReinterview,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Re-Interview Character'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.etherealCyan,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // System Prompt
              _buildSection(
                title: 'System Prompt',
                child: _buildTextField(
                  label: 'System Prompt',
                  controller: _systemPromptController,
                  enabled: _isEditing,
                  maxLines: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
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
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _character!.accentColor),
        ),
        filled: true,
        fillColor: Colors.black26,
      ),
    );
  }

  Widget _buildInfoRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7))),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
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
