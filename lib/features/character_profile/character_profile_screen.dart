import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ukrainian_font_utils.dart';
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
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

class CharacterProfileScreen extends StatefulWidget {
  final String characterId;

  const CharacterProfileScreen({super.key, required this.characterId});

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
    // Character not loaded yet
    if (_character == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Character Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Build sections from prompt
    final sections = _parseSystemPrompt(_character!.systemPrompt);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.midnightPurple,
        title: Text(_isEditing ? 'Edit Character' : 'Character Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.silverMist),
              tooltip: 'Edit Character',
              onPressed: () {
                setState(() {
                  _isEditing = true;
                  _nameController.text = _character!.name;
                  _systemPromptController.text = _character!.systemPrompt;
                });
              },
            ),
          if (_isEditing)
            TextButton(
              onPressed: _saveChanges,
              child: Text(
                'SAVE',
                style: TextStyle(
                  color: AppTheme.warmGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
        child: _isEditing ? _buildEditMode() : _buildViewMode(sections),
      ),
    );
  }

  Widget _buildViewMode(List<_PromptSection> sections) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Character header card
        _buildCharacterHeader(),
        const SizedBox(height: 24),

        // Character info sections
        ...sections.map(_buildSectionCard),

        // Add AI Model Selection section
        const SizedBox(height: 24),
        _buildAIModelSection(),

        // Reinterview button
        const SizedBox(height: 24),
        _buildReinterviewButton(),
      ],
    );
  }

  Widget _buildAIModelSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warmGold.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI MODEL',
            style: UkrainianFontUtils.cinzelWithUkrainianSupport(
              text: 'AI MODEL',
              color: AppTheme.warmGold,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          _buildModelOptions(),

          // View all models option
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              final result = await ModelSelectionDialog.show(
                context,
                currentModel: _character!.model,
              );

              if (result != null && mounted) {
                final charactersProvider = Provider.of<CharactersProvider>(
                  context,
                  listen: false,
                );

                final updatedCharacter = CharacterModel(
                  id: _character!.id,
                  name: _character!.name,
                  systemPrompt: _character!.systemPrompt,
                  imageUrl: _character!.imageUrl,
                  createdAt: _character!.createdAt,
                  accentColor: _character!.accentColor,
                  chatHistory: _character!.chatHistory,
                  additionalInfo: _character!.additionalInfo,
                  model: result,
                );

                await charactersProvider.updateCharacter(updatedCharacter);
                _loadCharacter();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('AI model updated for ${_character!.name}'),
                  ),
                );
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black12,
                border: Border(
                  top: BorderSide(
                    color: AppTheme.warmGold.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'View all available models',
                        style: UkrainianFontUtils.latoWithUkrainianSupport(
                          text: 'View all available models',
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Explore more AI options',
                        style: UkrainianFontUtils.latoWithUkrainianSupport(
                          text: 'Explore more AI options',
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppTheme.warmGold,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelOptions() {
    // Define the models for user-created twins
    final models = [
      {
        'id': 'google/gemini-2.0-flash-001',
        'name': 'Gemini 2.0 Flash',
        'description': 'Speed, multimodal support, and 1M token context window',
        'provider': 'Google Cloud',
        'recommended': true,
      },
      {
        'id': 'mistralai/mistral-small-3.1-24b-instruct:free',
        'name': 'Mistral Small 3.1',
        'description':
            'Lightweight, instruction-tuned model for conversational creativity',
        'provider': 'apidog',
        'free': true,
        'recommended': false,
      },
      {
        'id': 'openai/gpt-4o',
        'name': 'GPT-4o',
        'description':
            'Superior multilingual and vision capabilities via OpenRouter',
        'provider': 'OpenRouter',
        'recommended': false,
      },
      {
        'id': 'deepseek/deepseek-r1',
        'name': 'DeepSeek R1',
        'description':
            'MoE-based specialist for scientific and logical reasoning',
        'provider': 'apidog',
        'recommended': false,
      },
    ];

    return Column(
      children: [
        ...models
            .map(
              (model) => _buildModelOption(
                id: model['id'] as String,
                name: model['name'] as String,
                description: model['description'] as String,
                provider: model['provider'] as String,
                isRecommended: model['recommended'] == true,
                isFree: model['free'] == true,
                isSelected: _character!.model == model['id'],
              ),
            ),
      ],
    );
  }

  Widget _buildModelOption({
    required String id,
    required String name,
    required String description,
    required String provider,
    required bool isRecommended,
    bool isFree = false,
    required bool isSelected,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color:
            isSelected ? AppTheme.deepIndigo.withValues(alpha: 0.7) : Colors.black12,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isSelected
                  ? AppTheme.warmGold.withValues(alpha: 0.7)
                  : AppTheme.warmGold.withValues(alpha: 0.2),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            // Update the character's model
            final charactersProvider = Provider.of<CharactersProvider>(
              context,
              listen: false,
            );

            final updatedCharacter = CharacterModel(
              id: _character!.id,
              name: _character!.name,
              systemPrompt: _character!.systemPrompt,
              imageUrl: _character!.imageUrl,
              createdAt: _character!.createdAt,
              accentColor: _character!.accentColor,
              chatHistory: _character!.chatHistory,
              additionalInfo: _character!.additionalInfo,
              model: id,
            );

            await charactersProvider.updateCharacter(updatedCharacter);
            _loadCharacter();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('AI model updated for ${_character!.name}'),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        isSelected
                            ? AppTheme.warmGold.withValues(alpha: 0.2)
                            : Colors.black26,
                    border: Border.all(
                      color:
                          isSelected
                              ? AppTheme.warmGold
                              : AppTheme.warmGold.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    isSelected ? Icons.check : Icons.psychology_outlined,
                    color: AppTheme.warmGold,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isRecommended)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.warmGold.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'RECOMMENDED',
                                style: TextStyle(
                                  color: AppTheme.warmGold,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          if (isFree)
                            Container(
                              margin: const EdgeInsets.only(left: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.gentlePurple.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'FREE',
                                style: TextStyle(
                                  color: AppTheme.gentlePurple,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        provider,
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.radio_button_checked,
                  color: isSelected ? AppTheme.warmGold : Colors.transparent,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCharacterHeader() {
    return Column(
      children: [
        // Character avatar with glow
        Stack(
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
                    color: AppTheme.warmGold.withValues(alpha: 0.4),
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
                    AppTheme.midnightPurple.withValues(alpha: 0.7),
                    AppTheme.deepNavy.withValues(alpha: 0.5),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.warmGold.withValues(alpha: 0.6),
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
        const SizedBox(height: 16),

        // Character name display
        Center(
          child: Text(
            _character!.name,
            style: UkrainianFontUtils.cinzelWithUkrainianSupport(
              text: _character!.name,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.silverMist,
              letterSpacing: 1.5,
              shadows: [
                Shadow(
                  blurRadius: 3,
                  color: AppTheme.warmGold.withValues(alpha: 0.5),
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(_PromptSection section) {
    return _buildSection(
      title: section.title,
      child: Column(
        children: [
          if (_isEditing)
            _buildTextField(
              label: section.title,
              controller: TextEditingController(text: section.content),
              enabled: true,
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.midnightPurple.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.warmGold.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Text(
                section.content,
                style: TextStyle(
                  color: AppTheme.silverMist,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Created:',
                style: TextStyle(
                  color: AppTheme.silverMist.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.midnightPurple.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.warmGold.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  _formatDate(_character!.createdAt),
                  style: TextStyle(
                    color: AppTheme.silverMist,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Messages:',
                style: TextStyle(
                  color: AppTheme.silverMist.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.midnightPurple.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.warmGold.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${_character!.chatHistory.length}',
                  style: TextStyle(
                    color: AppTheme.silverMist,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warmGold.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
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
                  color: AppTheme.warmGold,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: UkrainianFontUtils.cinzelWithUkrainianSupport(
                    text: title,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.warmGold,
                    letterSpacing: 2.0,
                    shadows: [
                      Shadow(
                        blurRadius: 2,
                        color: Colors.black.withValues(alpha: 0.3),
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Divider(
              color: AppTheme.warmGold.withValues(alpha: 0.3),
              thickness: 1,
              height: 24,
            ),
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
      style: TextStyle(color: AppTheme.silverMist, fontSize: 15, height: 1.5),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: AppTheme.silverMist.withValues(alpha: 0.8),
          fontWeight: FontWeight.w500,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.warmGold.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.warmGold, width: 2),
        ),
        filled: true,
        fillColor: AppTheme.midnightPurple.withValues(alpha: 0.5),
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
          Text(
            label,
            style: TextStyle(
              color: AppTheme.silverMist.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.midnightPurple.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.warmGold.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: AppTheme.silverMist,
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

  // Parse the system prompt into sections
  List<_PromptSection> _parseSystemPrompt(String systemPrompt) {
    final List<_PromptSection> sections = [];

    // Try to extract sections from the prompt
    final RegExp sectionRegex = RegExp(
      r'#+\s*([^#\n]+)\n+([\s\S]*?)(?=\n#+\s*[^#\n]+\n+|$)',
    );
    final matches = sectionRegex.allMatches(systemPrompt);

    if (matches.isNotEmpty) {
      for (final match in matches) {
        if (match.groupCount >= 2) {
          final title = match.group(1)?.trim() ?? 'Unnamed Section';
          final content = match.group(2)?.trim() ?? '';
          sections.add(_PromptSection(title: title, content: content));
        }
      }
    } else {
      // If no sections found, create a single "Description" section
      sections.add(_PromptSection(title: 'Description', content: systemPrompt));
    }

    return sections;
  }

  Widget _buildEditMode() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Name field
        _buildTextField(
          label: 'Character Name',
          controller: _nameController,
          enabled: true,
        ),
        const SizedBox(height: 16),

        // System prompt field
        _buildTextField(
          label: 'System Prompt',
          controller: _systemPromptController,
          enabled: true,
          maxLines: 15,
        ),

        const SizedBox(height: 24),

        // Cancel button
        Center(
          child: TextButton(
            onPressed: () {
              setState(() {
                _isEditing = false;
              });
            },
            child: Text(
              'CANCEL',
              style: TextStyle(
                color: AppTheme.silverMist.withValues(alpha: 0.8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReinterviewButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.midnightPurple.withValues(alpha: 0.7),
            AppTheme.deepNavy.withValues(alpha: 0.9),
          ],
        ),
        border: Border.all(color: AppTheme.warmGold.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _startReinterview,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit_note, color: AppTheme.warmGold, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Recreate Character Through Interview',
                  style: TextStyle(
                    color: AppTheme.silverMist,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Show character card info dialog with AI-structured information
  void _showCharacterCardInfo() {
    if (_character == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Could not load character information'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }


    // Parse the system prompt to detect headings and sections
    final parsedSections = _parseSystemPrompt(_character!.systemPrompt);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppTheme.backgroundStart,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: AppTheme.warmGold.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    'Character Card: ${_character!.name}',
                    style: UkrainianFontUtils.cinzelWithUkrainianSupport(
                      text: 'Character Card: ${_character!.name}',
                      color: AppTheme.warmGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.content_copy,
                    size: 20,
                    color: AppTheme.warmGold,
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
                        color: AppTheme.warmGold.withValues(alpha: 0.3),
                      ),
                    ),

                    // AI Model section styled like Biography
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI MODEL',
                          style: UkrainianFontUtils.cinzelWithUkrainianSupport(
                            text: 'AI MODEL',
                            color: AppTheme.warmGold,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
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
                        color: AppTheme.warmGold.withValues(alpha: 0.3),
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
          style: UkrainianFontUtils.cinzelWithUkrainianSupport(
            text: title,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.warmGold,
            letterSpacing: 1.5,
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
        color: AppTheme.midnightPurple.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.warmGold.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(
              label,
              style: TextStyle(
                color: AppTheme.silverMist.withValues(alpha: 0.7),
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
                color: AppTheme.midnightPurple.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.warmGold.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: AppTheme.silverMist,
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
                color: AppTheme.silverMist,
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
            color: AppTheme.warmGold.withValues(alpha: 0.3),
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
          foregroundColor: AppTheme.silverMist,
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
