// Removed unused import
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ukrainian_font_utils.dart';
import '../../core/utils/image_utils.dart';
import '../models/character_model.dart';
import '../providers/characters_provider.dart';
import '../character_interview/interview_screen.dart';
import '../../core/widgets/model_selection_dialog.dart';
import '../character_chat/chat_screen.dart';
import '../../core/utils/responsive_utils.dart';
import '../../l10n/app_localizations.dart';

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
  late TextEditingController _localPromptController;
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
    _localPromptController.dispose();
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
        _localPromptController = TextEditingController(
          text: character.localPrompt,
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
        localPrompt: _localPromptController.text.trim(),
        imageUrl: _character!.imageUrl,
        userImagePath: _character!.userImagePath, // Preserve user image
        iconImagePath: _character!.iconImagePath, // Preserve icon image
        icon: _character!.icon, // Preserve the icon
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
            userImagePath:
                originalCharacter.userImagePath, // Preserve user image
            iconImagePath:
                originalCharacter.iconImagePath, // Preserve icon image
            icon: originalCharacter.icon, // Preserve the icon
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
        appBar: AppBar(
          title: Text(AppLocalizations.of(context).characterProfile),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Build sections from prompt
    final sections = _parseSystemPrompt(_character!.systemPrompt);
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.midnightPurple,
        title: Text(
          _isEditing
              ? localizations.editCharacter
              : localizations.characterProfile,
        ),
        actions: [
          if (!_isEditing)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppTheme.warmGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.warmGold.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: IconButton(
                icon: const Icon(Icons.edit, color: AppTheme.warmGold),
                tooltip: localizations.editCharacter,
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                    _nameController.text = _character!.name;
                    _systemPromptController.text = _character!.systemPrompt;
                    _localPromptController.text = _character!.localPrompt;
                  });
                },
              ),
            ),
          if (_isEditing)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _saveChanges,
                child: Text(
                  'SAVE',
                  style: TextStyle(
                    color: AppTheme.warmGold,
                    fontWeight: FontWeight.bold,
                  ),
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

        // Character Card section (simplified)
        _buildCharacterCardSection(),

        // Add AI Model Selection section
        const SizedBox(height: 24),
        _buildAIModelSection(),

        // Reinterview button
        const SizedBox(height: 24),
        _buildReinterviewButton(),
      ],
    );
  }

  // New simplified character card section
  Widget _buildCharacterCardSection() {
    final localizations = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.warmGold.withValues(alpha: 0.3),
          width: 1,
        ),
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
            // Header with title and copy button
            Row(
              children: [
                Icon(Icons.badge, color: AppTheme.warmGold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    localizations.characterPrompts,
                    style: UkrainianFontUtils.cinzelWithUkrainianSupport(
                      text: localizations.characterPrompts,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.warmGold,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(
                          blurRadius: 2,
                          color: Colors.black.withValues(alpha: 0.3),
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Divider(
              color: AppTheme.warmGold.withValues(alpha: 0.3),
              thickness: 1,
              height: 20,
            ),

            // Prompt tabs/sections
            DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  // Tab bar
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.midnightPurple.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TabBar(
                      labelColor: AppTheme.warmGold,
                      unselectedLabelColor: AppTheme.silverMist.withValues(
                        alpha: 0.6,
                      ),
                      indicatorColor: AppTheme.warmGold,
                      indicatorSize: TabBarIndicatorSize.tab,
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud, size: 16),
                              SizedBox(width: 4),
                              Text(
                                localizations.apiModels,
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.phone_android, size: 16),
                              SizedBox(width: 4),
                              Text(
                                localizations.localModel,
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),

                  // Tab content
                  Container(
                    height: 200,
                    child: TabBarView(
                      children: [
                        // Full prompt for API models
                        _buildPromptContainer(
                          title: localizations.fullDetailedPrompt,
                          subtitle: localizations.usedForCloudAiModels,
                          content: _character!.systemPrompt,
                          onCopy:
                              () => _copyPrompt(
                                _character!.systemPrompt,
                                localizations.fullDetailedPrompt,
                              ),
                        ),
                        // Local prompt for DeepSeek
                        _buildPromptContainer(
                          title: localizations.optimizedLocalPrompt,
                          subtitle: localizations.usedForLocalModels,
                          content: _character!.localPrompt,
                          onCopy:
                              () => _copyPrompt(
                                _character!.localPrompt,
                                localizations.optimizedLocalPrompt,
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
    );
  }

  Widget _buildPromptContainer({
    required String title,
    required String subtitle,
    required String content,
    required VoidCallback onCopy,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.midnightPurple.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.warmGold.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppTheme.warmGold,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.silverMist.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onCopy,
                icon: Icon(Icons.copy, color: AppTheme.warmGold, size: 16),
                padding: EdgeInsets.all(4),
                constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                tooltip: AppLocalizations.of(context).copyPrompt,
              ),
            ],
          ),
          SizedBox(height: 8),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                child: Text(
                  content,
                  style: TextStyle(
                    color: AppTheme.silverMist,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyPrompt(String prompt, String promptType) {
    Clipboard.setData(ClipboardData(text: prompt));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).promptCopiedToClipboard),
        backgroundColor: AppTheme.warmGold.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildAIModelSection() {
    final localizations = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.warmGold.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.aiModel,
            style: UkrainianFontUtils.cinzelWithUkrainianSupport(
              text: localizations.aiModel,
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
                  icon: _character!.icon, // Preserve the icon
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
                    content: Text(
                      AppLocalizations.of(context).aiModelUpdatedFor.replaceAll(
                        '{name}',
                        _character!.name,
                      ),
                    ),
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
                        localizations.viewAllAvailableModels,
                        style: UkrainianFontUtils.latoWithUkrainianSupport(
                          text: localizations.viewAllAvailableModels,
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        localizations.exploreMoreAiOptions,
                        style: UkrainianFontUtils.latoWithUkrainianSupport(
                          text: localizations.exploreMoreAiOptions,
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
    final localizations = AppLocalizations.of(context);

    // Define the models for user-created twins
    final models = [
      {
        'id': 'local/gemma-3n-e2b-it',
        'name': 'Local Gemma 3n E2B IT',
        'description': 'Privacy-first local AI with multimodal support (2.9GB)',
        'provider': 'Local Device',
        'recommended': true,
        'isLocal': true,
      },
      {
        'id': 'google/gemini-2.5-pro',
        'name': 'Gemini 2.5 Pro',
        'description': localizations.speedMultimodalSupport,
        'provider': 'Google Cloud',
        'recommended': true,
      },
      {
        'id': 'openai/gpt-5-chat',
        'name': 'GPT-5 Chat',
        'description':
            'Superior multilingual and vision capabilities via OpenRouter',
        'provider': 'OpenRouter',
        'recommended': false,
      },
      {
        'id': 'qwen/qwen3-235b-a22b-07-25:free',
        'name': 'Qwen 3 235B (Free)',
        'description': 'Free model with solid conversational abilities',
        'provider': 'OpenRouter',
        'free': true,
        'recommended': false,
      },
      // Keep existing free options as-is
    ];

    return Column(
      children: [
        ...models.map(
          (model) => _buildModelOption(
            id: model['id'] as String,
            name: model['name'] as String,
            description: model['description'] as String,
            provider: model['provider'] as String,
            isRecommended: model['recommended'] == true,
            isFree: model['free'] == true,
            isLocal: model['isLocal'] == true,
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
    bool isLocal = false,
    required bool isSelected,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color:
            isSelected
                ? AppTheme.deepIndigo.withValues(alpha: 0.7)
                : Colors.black12,
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
              icon: _character!.icon, // Preserve the icon
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Model icon based on type
                    Icon(
                      isLocal ? Icons.phone_android : Icons.cloud,
                      size: 20,
                      color: isLocal ? Colors.green : AppTheme.warmGold,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isRecommended)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.warmGold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'RECOMMENDED',
                          style: TextStyle(
                            color: AppTheme.warmGold,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (isFree)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'FREE',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (isLocal)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'PRIVATE',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Provider: $provider',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                if (isLocal) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Requires model download • No internet needed',
                    style: TextStyle(
                      color: Colors.blue.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCharacterHeader() {
    final fontScale = ResponsiveUtils.getFontSizeScale(context);

    return Column(
      children: [
        // Character avatar with glow
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow effect
            Container(
              width: 140 * fontScale,
              height: 140 * fontScale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.warmGold.withValues(alpha: 0.4),
                    blurRadius: 20 * fontScale,
                    spreadRadius: 5 * fontScale,
                  ),
                ],
              ),
            ),
            // Character avatar
            Container(
              width: 130 * fontScale,
              height: 130 * fontScale,
              decoration: BoxDecoration(
                gradient:
                    _character!.userImagePath != null
                        ? null
                        : LinearGradient(
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
              child: ClipOval(
                child:
                    _character!.userImagePath != null
                        ? ImageUtils.buildCharacterAvatar(
                          imagePath: _character!.userImagePath,
                          size: 130 * fontScale,
                          fallbackIcon: _character!.icon,
                          fallbackText: _character!.name,
                          backgroundColor: AppTheme.midnightPurple.withValues(
                            alpha: 0.7,
                          ),
                          foregroundColor: AppTheme.warmGold,
                        )
                        : Center(
                          child:
                              _character!.iconImagePath != null
                                  ? ImageUtils.buildIconAvatar(
                                    iconImagePath: _character!.iconImagePath,
                                    size: 130 * fontScale,
                                    fallbackIcon: _character!.icon,
                                    fallbackText: _character!.name,
                                    backgroundColor: AppTheme.midnightPurple
                                        .withValues(alpha: 0.7),
                                    foregroundColor: AppTheme.warmGold,
                                  )
                                  : _character!.icon != null
                                  ? Icon(
                                    _character!.icon!,
                                    size: 60 * fontScale,
                                    color: AppTheme.warmGold,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 4,
                                        color: Colors.black26,
                                        offset: Offset(2, 2),
                                      ),
                                    ],
                                  )
                                  : Text(
                                    _character!.name.isNotEmpty
                                        ? _character!.name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontSize: 52 * fontScale,
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
            ),
            // Action buttons in profile view mode (always visible)
            // Icon selection button
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 40 * fontScale,
                height: 40 * fontScale,
                decoration: BoxDecoration(
                  color: AppTheme.warmGold,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.midnightPurple, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.edit,
                    size: 20 * fontScale,
                    color: AppTheme.midnightPurple,
                  ),
                  onPressed: _showIconSelectionDialog,
                  padding: EdgeInsets.zero,
                  tooltip: 'Change Icon',
                ),
              ),
            ),
            // Image upload button
            Positioned(
              bottom: 0,
              left: 0,
              child: Container(
                width: 40 * fontScale,
                height: 40 * fontScale,
                decoration: BoxDecoration(
                  color: AppTheme.silverMist,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.midnightPurple, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.camera_alt,
                    size: 20 * fontScale,
                    color: AppTheme.midnightPurple,
                  ),
                  onPressed: _showImageSelectionDialog,
                  padding: EdgeInsets.zero,
                  tooltip: 'Upload Image',
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
              fontSize: 28 * fontScale,
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
        const SizedBox(height: 20),

        // Chat button
        if (!_isEditing)
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          CharacterChatScreen(characterId: _character!.id),
                ),
              ).then((_) {
                // After closing chat, return to gallery by popping profile
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              });
            },
            icon: Icon(Icons.chat_bubble_outline, size: 20 * fontScale),
            label: Text(
              AppLocalizations.of(context).startChat,
              style: UkrainianFontUtils.latoWithUkrainianSupport(
                text: AppLocalizations.of(context).startChat,
                fontSize: 16 * fontScale,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warmGold,
              foregroundColor: AppTheme.midnightPurple,
              padding: EdgeInsets.symmetric(
                horizontal: 24 * fontScale,
                vertical: 12 * fontScale,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 8,
              shadowColor: AppTheme.warmGold.withValues(alpha: 0.3),
            ),
          ),
      ],
    );
  }

  // Icon selection dialog
  void _showIconSelectionDialog() {
    final localizations = AppLocalizations.of(context);

    final List<IconData> availableIcons = [
      Icons.person,
      Icons.face,
      Icons.emoji_emotions,
      Icons.account_circle,
      Icons.sentiment_satisfied,
      Icons.psychology,
      Icons.auto_awesome,
      Icons.star,
      Icons.favorite,
      Icons.lightbulb,
      Icons.science,
      Icons.school,
      Icons.work,
      Icons.sports_esports,
      Icons.music_note,
      Icons.palette,
      Icons.camera_alt,
      Icons.pets,
      Icons.nature,
      Icons.local_florist,
      Icons.wb_sunny,
      Icons.nightlight,
      Icons.rocket_launch,
      Icons.explore,
      Icons.travel_explore,
      Icons.home,
      Icons.restaurant,
      Icons.coffee,
      Icons.book,
      Icons.library_books,
      Icons.brush,
      Icons.code,
      Icons.build,
      Icons.fitness_center,
      Icons.directions_bike,
      Icons.flight,
      Icons.sailing,
      Icons.theater_comedy,
      Icons.celebration,
      Icons.cake,
      Icons.diamond,
      Icons.spa,
      Icons.self_improvement,
      Icons.volunteer_activism,
      Icons.handshake,
      Icons.group,
      Icons.family_restroom,
      Icons.child_friendly,
      Icons.elderly,
      Icons.accessibility,
      Icons.healing,
      Icons.medical_services,
      Icons.local_hospital,
      Icons.psychology_alt,
      Icons.mood,
      Icons.sentiment_very_satisfied,
      Icons.sentiment_neutral,
      Icons.sentiment_dissatisfied,
      Icons.sentiment_very_dissatisfied,
      Icons.tag_faces,
      Icons.insert_emoticon,
      Icons.emoji_people,
      Icons.emoji_nature,
      Icons.emoji_food_beverage,
      Icons.emoji_transportation,
      Icons.emoji_symbols,
      Icons.emoji_flags,
      Icons.emoji_objects,
    ];

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
            title: Text(
              localizations.selectCharacterIcon,
              style: UkrainianFontUtils.cinzelWithUkrainianSupport(
                text: localizations.selectCharacterIcon,
                color: AppTheme.warmGold,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            content: Container(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  // Remove icon option
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(bottom: 16),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _updateCharacterIcon(null);
                      },
                      icon: Icon(Icons.clear, color: AppTheme.midnightPurple),
                      label: Text(
                        localizations.useFirstLetter,
                        style: TextStyle(color: AppTheme.midnightPurple),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.silverMist,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  // Icon grid
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        childAspectRatio: 1,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: availableIcons.length,
                      itemBuilder: (context, index) {
                        final icon = availableIcons[index];
                        final isSelected = _character!.icon == icon;

                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                            _updateCharacterIcon(icon);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? AppTheme.warmGold.withValues(alpha: 0.3)
                                      : AppTheme.midnightPurple.withValues(
                                        alpha: 0.5,
                                      ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? AppTheme.warmGold
                                        : AppTheme.warmGold.withValues(
                                          alpha: 0.3,
                                        ),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                icon,
                                size: 28,
                                color:
                                    isSelected
                                        ? AppTheme.warmGold
                                        : AppTheme.silverMist,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppTheme.silverMist),
                ),
              ),
            ],
          ),
    );
  }

  // Image selection dialog
  void _showImageSelectionDialog() {
    final localizations = AppLocalizations.of(context);

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
            title: Text(
              localizations.characterImage,
              style: UkrainianFontUtils.cinzelWithUkrainianSupport(
                text: localizations.characterImage,
                color: AppTheme.warmGold,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Upload from gallery
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: 12),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _uploadImageFromGallery();
                    },
                    icon: Icon(
                      Icons.photo_library,
                      color: AppTheme.midnightPurple,
                    ),
                    label: Text(
                      'Choose from Gallery',
                      style: TextStyle(color: AppTheme.midnightPurple),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.warmGold,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                // Remove current image
                if (_character!.userImagePath != null)
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(bottom: 12),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _removeCharacterImage();
                      },
                      icon: Icon(Icons.delete, color: AppTheme.midnightPurple),
                      label: Text(
                        'Remove Current Image',
                        style: TextStyle(color: AppTheme.midnightPurple),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.silverMist,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                // Image guidelines
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.midnightPurple.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Image Guidelines:',
                        style: TextStyle(
                          color: AppTheme.warmGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• Square images work best\n'
                        '• Maximum size: 512x512 pixels\n'
                        '• Supported formats: JPG, PNG\n'
                        '• Images will be optimized automatically',
                        style: TextStyle(
                          color: AppTheme.silverMist,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppTheme.silverMist),
                ),
              ),
            ],
          ),
    );
  }

  // Icon image selection dialog
  void _showIconImageSelectionDialog() {
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
            title: Text(
              'Character Icon Image',
              style: UkrainianFontUtils.cinzelWithUkrainianSupport(
                text: 'Character Icon Image',
                color: AppTheme.warmGold,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Upload from gallery
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: 12),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _uploadIconImageFromGallery();
                    },
                    icon: Icon(
                      Icons.photo_library,
                      color: AppTheme.midnightPurple,
                    ),
                    label: Text(
                      'Choose Icon from Gallery',
                      style: TextStyle(color: AppTheme.midnightPurple),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.warmGold,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                // Remove current icon image
                if (_character!.iconImagePath != null)
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(bottom: 12),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _removeCharacterIconImage();
                      },
                      icon: Icon(Icons.delete, color: AppTheme.midnightPurple),
                      label: Text(
                        'Remove Icon Image',
                        style: TextStyle(color: AppTheme.midnightPurple),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.silverMist,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                // Icon image guidelines
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.midnightPurple.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Icon Image Guidelines:',
                        style: TextStyle(
                          color: AppTheme.warmGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• Square images work best for icons\n'
                        '• Maximum size: 256x256 pixels\n'
                        '• Supported formats: JPG, PNG\n'
                        '• Images will be optimized for icon use\n'
                        '• This will be used as the character icon',
                        style: TextStyle(
                          color: AppTheme.silverMist,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppTheme.silverMist),
                ),
              ),
            ],
          ),
    );
  }

  // Upload image from gallery
  Future<void> _uploadImageFromGallery() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => Center(
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundStart,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.warmGold.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTheme.warmGold),
                    SizedBox(height: 16),
                    Text(
                      'Optimizing image...',
                      style: TextStyle(color: AppTheme.silverMist),
                    ),
                  ],
                ),
              ),
            ),
      );

      final String? imagePath = await ImageUtils.pickAndOptimizeImage();

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (imagePath != null && mounted) {
        await _updateCharacterImage(imagePath);
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Upload icon image from gallery
  Future<void> _uploadIconImageFromGallery() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => Center(
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundStart,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.warmGold.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTheme.warmGold),
                    SizedBox(height: 16),
                    Text(
                      'Optimizing icon image...',
                      style: TextStyle(color: AppTheme.silverMist),
                    ),
                  ],
                ),
              ),
            ),
      );

      final String? iconImagePath = await ImageUtils.pickAndOptimizeIconImage();

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (iconImagePath != null && mounted) {
        await _updateCharacterIconImage(iconImagePath);
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading icon image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Remove character image
  Future<void> _removeCharacterImage() async {
    if (_character == null) return;

    try {
      // Delete the old image file if it exists
      if (_character!.userImagePath != null) {
        await ImageUtils.deleteCharacterImage(_character!.userImagePath!);
      }

      final charactersProvider = Provider.of<CharactersProvider>(
        context,
        listen: false,
      );

      final updatedCharacter = CharacterModel(
        id: _character!.id,
        name: _character!.name,
        systemPrompt: _character!.systemPrompt,
        localPrompt: _character!.localPrompt,
        imageUrl: _character!.imageUrl,
        userImagePath: null, // Remove user image
        iconImagePath: _character!.iconImagePath,
        icon: _character!.icon,
        createdAt: _character!.createdAt,
        accentColor: _character!.accentColor,
        chatHistory: _character!.chatHistory,
        additionalInfo: _character!.additionalInfo,
        model: _character!.model,
      );

      await charactersProvider.updateCharacter(updatedCharacter);

      setState(() {
        _character = updatedCharacter;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Character image removed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Update character image
  Future<void> _updateCharacterImage(String imagePath) async {
    if (_character == null) return;

    try {
      // Delete the old image file if it exists
      if (_character!.userImagePath != null) {
        await ImageUtils.deleteCharacterImage(_character!.userImagePath!);
      }

      final charactersProvider = Provider.of<CharactersProvider>(
        context,
        listen: false,
      );

      final updatedCharacter = CharacterModel(
        id: _character!.id,
        name: _character!.name,
        systemPrompt: _character!.systemPrompt,
        localPrompt: _character!.localPrompt,
        imageUrl: _character!.imageUrl,
        userImagePath: imagePath,
        iconImagePath: _character!.iconImagePath,
        icon: _character!.icon,
        createdAt: _character!.createdAt,
        accentColor: _character!.accentColor,
        chatHistory: _character!.chatHistory,
        additionalInfo: _character!.additionalInfo,
        model: _character!.model,
      );

      await charactersProvider.updateCharacter(updatedCharacter);

      setState(() {
        _character = updatedCharacter;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Character image updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Update character icon image
  Future<void> _updateCharacterIconImage(String iconImagePath) async {
    if (_character == null) return;

    try {
      // Delete the old icon image file if it exists
      if (_character!.iconImagePath != null) {
        await ImageUtils.deleteCharacterIconImage(_character!.iconImagePath!);
      }

      final charactersProvider = Provider.of<CharactersProvider>(
        context,
        listen: false,
      );

      final updatedCharacter = CharacterModel(
        id: _character!.id,
        name: _character!.name,
        systemPrompt: _character!.systemPrompt,
        localPrompt: _character!.localPrompt,
        imageUrl: _character!.imageUrl,
        userImagePath: _character!.userImagePath,
        iconImagePath: iconImagePath,
        icon: _character!.icon,
        createdAt: _character!.createdAt,
        accentColor: _character!.accentColor,
        chatHistory: _character!.chatHistory,
        additionalInfo: _character!.additionalInfo,
        model: _character!.model,
      );

      await charactersProvider.updateCharacter(updatedCharacter);

      setState(() {
        _character = updatedCharacter;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Character icon image updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating icon image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Update character icon
  Future<void> _updateCharacterIcon(IconData? icon) async {
    if (_character == null) return;

    try {
      final charactersProvider = Provider.of<CharactersProvider>(
        context,
        listen: false,
      );

      final updatedCharacter = CharacterModel(
        id: _character!.id,
        name: _character!.name,
        systemPrompt: _character!.systemPrompt,
        localPrompt: _character!.localPrompt,
        imageUrl: _character!.imageUrl,
        userImagePath: _character!.userImagePath,
        iconImagePath: _character!.iconImagePath,
        icon: icon,
        createdAt: _character!.createdAt,
        accentColor: _character!.accentColor,
        chatHistory: _character!.chatHistory,
        additionalInfo: _character!.additionalInfo,
        model: _character!.model,
      );

      await charactersProvider.updateCharacter(updatedCharacter);

      setState(() {
        _character = updatedCharacter;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              icon != null
                  ? 'Character icon updated successfully'
                  : 'Character icon removed successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating icon: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Remove character icon image
  Future<void> _removeCharacterIconImage() async {
    if (_character == null) return;

    try {
      // Delete the old icon image file if it exists
      if (_character!.iconImagePath != null) {
        await ImageUtils.deleteCharacterIconImage(_character!.iconImagePath!);
      }

      final charactersProvider = Provider.of<CharactersProvider>(
        context,
        listen: false,
      );

      final updatedCharacter = CharacterModel(
        id: _character!.id,
        name: _character!.name,
        systemPrompt: _character!.systemPrompt,
        localPrompt: _character!.localPrompt,
        imageUrl: _character!.imageUrl,
        userImagePath: _character!.userImagePath,
        iconImagePath: null, // Remove icon image
        icon: _character!.icon,
        createdAt: _character!.createdAt,
        accentColor: _character!.accentColor,
        chatHistory: _character!.chatHistory,
        additionalInfo: _character!.additionalInfo,
        model: _character!.model,
      );

      await charactersProvider.updateCharacter(updatedCharacter);

      setState(() {
        _character = updatedCharacter;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Character icon image removed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing icon image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildEditMode() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Name field with consistent styling
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Character Name',
              style: TextStyle(
                color: AppTheme.warmGold,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              enabled: true,
              style: TextStyle(color: AppTheme.silverMist),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black26,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: AppTheme.warmGold.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.warmGold, width: 1),
                ),
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // System prompt field with consistent styling
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Full Detailed Prompt (API Models)',
              style: TextStyle(
                color: AppTheme.warmGold,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _systemPromptController,
              enabled: true,
              maxLines: 15,
              style: TextStyle(color: AppTheme.silverMist),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black26,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: AppTheme.warmGold.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.warmGold, width: 1),
                ),
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Local prompt field with generate button
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Local Prompt (Local Models)',
                  style: TextStyle(
                    color: AppTheme.warmGold,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // Generate local prompt from system prompt
                    final generatedLocalPrompt =
                        CharacterModel.generateLocalPrompt(
                          _systemPromptController.text.trim(),
                          _nameController.text.trim(),
                        );
                    setState(() {
                      _localPromptController.text = generatedLocalPrompt;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Local prompt regenerated')),
                    );
                  },
                  icon: Icon(
                    Icons.auto_fix_high,
                    color: AppTheme.warmGold,
                    size: 16,
                  ),
                  label: Text(
                    'Generate',
                    style: TextStyle(color: AppTheme.warmGold, fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    backgroundColor: AppTheme.midnightPurple.withValues(
                      alpha: 0.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: AppTheme.warmGold.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _localPromptController,
              enabled: true,
              maxLines: 15,
              style: TextStyle(color: AppTheme.silverMist),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black26,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: AppTheme.warmGold.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.warmGold, width: 1),
                ),
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Save and Cancel buttons in a row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Save button
            ElevatedButton(
              onPressed: _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warmGold.withValues(alpha: 0.8),
                foregroundColor: AppTheme.midnightPurple,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'SAVE',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(width: 16),
            // Cancel button
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditing = false;
                });
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: AppTheme.silverMist.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                'CANCEL',
                style: TextStyle(
                  color: AppTheme.silverMist.withValues(alpha: 0.8),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
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
        border: Border.all(
          color: AppTheme.warmGold.withValues(alpha: 0.3),
          width: 1,
        ),
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
                          label: AppLocalizations.of(context).created,
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
        border: Border.all(
          color: AppTheme.warmGold.withValues(alpha: 0.3),
          width: 1,
        ),
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
      SnackBar(
        content: Text(
          'Character card for "${_character!.name}" copied to clipboard',
        ),
        backgroundColor: AppTheme.warmGold.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
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
          icon: _character!.icon, // Preserve the icon
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
      'local/gemma-3n-e2b-it': {
        'name': 'Local Gemma 3n E2B IT',
        'provider': 'Local Device',
      },
      'google/gemini-2.5-pro': {
        'name': 'Gemini 2.5 Pro',
        'provider': 'Google',
      },
      'anthropic/claude-sonnet-4': {
        'name': 'Claude 4 Sonnet',
        'provider': 'Anthropic',
      },
      'openai/gpt-5-chat': {'name': 'GPT-5 Chat', 'provider': 'OpenAI'},
      'qwen/qwen3-235b-a22b-07-25:free': {
        'name': 'Qwen 3 235B',
        'provider': 'OpenRouter',
      },
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
      'local/gemma-3n-e2b-it':
          'Privacy-first local AI with multimodal support (2.9GB)',
      'google/gemini-2.0-flash-001':
          'Fast responses with multimodal capabilities',
      'anthropic/claude-3-5-sonnet': 'High-quality reasoning and analysis',
      'google/gemini-2.0-pro-001': 'Advanced multimodal understanding',
      'anthropic/claude-3-opus': 'Top-tier intelligence and creativity',
      'meta-llama/llama-3-70b-instruct': 'Open-source conversational AI',
      'openai/gpt-4o': 'Powerful language understanding and generation',
      'qwen/qwen3-235b-a22b-07-25:free':
          'Free model with solid conversational abilities',
    };

    return modelDescriptions[modelId] ?? 'Advanced AI language model';
  }

  // Essential helper methods
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
          borderSide: BorderSide(
            color: AppTheme.warmGold.withValues(alpha: 0.3),
          ),
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

    // Optimize for DeepSeek: Make the prompt more direct and conversational
    if (!cleanedPrompt.contains("You are")) {
      cleanedPrompt =
          "You are $characterName. You will speak and act as this character in all responses.\n\n$cleanedPrompt";
    }

    // Add DeepSeek-optimized character persistence instructions
    if (!cleanedPrompt.contains("stay in character") &&
        !cleanedPrompt.contains("never break character")) {
      cleanedPrompt +=
          "\n\nYou must stay completely in character. Never break character, never mention you are an AI, and never show reasoning or thinking processes. Respond naturally as $characterName would.";
    }

    return cleanedPrompt;
  }

  // Parse the system prompt into sections (kept for compatibility)
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
}
