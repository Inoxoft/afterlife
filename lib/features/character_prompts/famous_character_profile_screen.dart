// Removed unused import
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ukrainian_font_utils.dart';
import 'famous_character_prompts.dart';
import 'famous_character_chat_screen.dart';
import '../character_gallery/character_gallery_screen.dart';
import '../../l10n/app_localizations.dart';
import 'package:afterlife/features/widgets/background_painters.dart';

class FamousCharacterProfileScreen extends StatefulWidget {
  final String name;
  final String years;
  final String profession;
  final String? imageUrl;

  const FamousCharacterProfileScreen({
    Key? key,
    required this.name,
    required this.years,
    required this.profession,
    this.imageUrl,
  }) : super(key: key);

  @override
  State<FamousCharacterProfileScreen> createState() =>
      _FamousCharacterProfileScreenState();
}

class _FamousCharacterProfileScreenState
    extends State<FamousCharacterProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late String _selectedModel;

  @override
  void initState() {
    super.initState();

    // Initialize the selected model
    _selectedModel = FamousCharacterPrompts.getSelectedModel(widget.name);

    // Set up animation for the pulsing effect
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final shortBio =
        FamousCharacterPrompts.getShortBio(context, widget.name) ??
        localizations.noBiographyAvailable;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundStart,
        title: Text(localizations.profileOf.replaceAll('{name}', widget.name)),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Character Performance Stage
              Container(
                height: 320,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.warmGold.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.cosmicBlack.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Stage backdrop with dramatic gradient
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [AppTheme.deepNavy, AppTheme.cosmicBlack],
                            ),
                          ),
                        ),
                      ),

                      // Digital circuit pattern background (suggesting AI)
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.15,
                          child: CustomPaint(
                            painter: DigitalBackgroundPainter(
                              lineColor: AppTheme.warmGold,
                            ),
                          ),
                        ),
                      ),

                      // Spotlight cone effect
                      Positioned(
                        top: -40,
                        child: Container(
                          width: 260,
                          height: 200,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment.topCenter,
                              radius: 0.8,
                              colors: [
                                AppTheme.warmGold.withValues(alpha: 0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Dramatic mask presentation
                      Center(
                        child: Container(
                          width: 200,
                          height: 230,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.warmGold.withValues(alpha: 0.2),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child:
                              widget.imageUrl != null
                                  ? Center(
                                    child: Container(
                                      width: 190,
                                      height: 220,
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.rectangle,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.warmGold
                                                .withValues(alpha: 0.1),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: Image.asset(
                                        widget.imageUrl!,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  )
                                  : Center(
                                    child: Icon(
                                      Icons.face,
                                      color: AppTheme.warmGold.withValues(alpha: 0.5),
                                      size: 80,
                                    ),
                                  ),
                        ),
                      ),

                      // Additional spotlight highlight for the mask
                      Center(
                        child: Container(
                          width: 210,
                          height: 240,
                          decoration: BoxDecoration(
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(100),
                            gradient: RadialGradient(
                              center: Alignment.center,
                              radius: 0.5,
                              colors: [
                                AppTheme.warmGold.withValues(alpha: 0.05),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Pulsing energy ring (signifying AI consciousness)
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return RepaintBoundary(
                            child: CustomPaint(
                              size: const Size(280, 280),
                              painter: PulseRingPainter(
                                progress: _pulseAnimation.value,
                                color: AppTheme.warmGold,
                              ),
                            ),
                          );
                        },
                      ),

                      // "Character" label
                      Positioned(
                        bottom: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.deepNavy.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.warmGold.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            widget.profession,
                            style: UkrainianFontUtils.cinzelWithUkrainianSupport(
                              text: widget.profession,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.warmGold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Quick Start Chat button near the top
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToChat(context),
                  icon: const Icon(Icons.chat_bubble_outline, size: 20),
                  label: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Text(
                      'Chat with ${widget.name.split(' ').first}',
                      style: UkrainianFontUtils.latoWithUkrainianSupport(
                        text: 'Chat with ${widget.name.split(' ').first}',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.midnightPurple,
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.warmGold,
                    foregroundColor: AppTheme.midnightPurple,
                    elevation: 6,
                    shadowColor: AppTheme.warmGold.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Info Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.warmGold.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      context: context,
                      label: 'Name',
                      value: widget.name,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context: context,
                      label: 'Years',
                      value: widget.years,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context: context,
                      label: 'Profession',
                      value: widget.profession,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Biography
              Container(
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
                      localizations.biography,
                      style: UkrainianFontUtils.cinzelWithUkrainianSupport(
                        text: localizations.biography,
                        color: AppTheme.warmGold,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      shortBio,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // AI Model section styled like Biography
              Container(
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
                    _buildModelDropdown(),

                    // Removed: view-all models row to minimize scrolling
                  ],
                ),
              ),

              // Removed: bottom Start Conversation (moved near the top)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required String label,
    required String value,
  }) {
    final localizations = AppLocalizations.of(context);
    
    // Get localized label
    String localizedLabel;
    switch (label) {
      case 'Name':
        localizedLabel = localizations.name;
        break;
      case 'Years':
        localizedLabel = localizations.years;
        break;
      case 'Profession':
        localizedLabel = localizations.profession;
        break;
      default:
        localizedLabel = label;
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            localizedLabel,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => FamousCharacterChatScreen(
              characterName: widget.name,
              imageUrl: widget.imageUrl,
            ),
      ),
    ).then((_) {
      // After closing chat, also close profile to return to gallery
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  Widget _buildModelDropdown() {
    // Get available models for this character
    final models = FamousCharacterPrompts.getModelsForCharacter(widget.name);

    return Column(
      children: [
        ...models
            .map(
              (model) => _buildModelOption(
                context: context,
                id: model['id'] as String,
                name: model['name'] as String,
                description: (model['id'] == 'local/gemma-3n-e2b-it')
                    ? AppLocalizations.of(context).downloadGemmaModel
                    : (model['description'] as String),
                isRecommended: model['recommended'] == true,
                isLocal: model['isLocal'] == true,
                    isSelected: _selectedModel == model['id'],
              ),
            ),
      ],
    );
  }

  Widget _buildModelOption({
    required BuildContext context,
    required String id,
    required String name,
    required String description,
    required bool isRecommended,
    bool isLocal = false,
    required bool isSelected,
  }) {
    final localizations = AppLocalizations.of(context);
    
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
          onTap: () {
            final localizations = AppLocalizations.of(context);
            setState(() {
              _selectedModel = id;
            });
            FamousCharacterPrompts.setSelectedModel(widget.name, id);
            // Show a confirmation to the user
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(localizations.aiModelUpdatedForCharacter(widget.name)),
                duration: const Duration(seconds: 2),
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
                    isSelected ? Icons.check : (isLocal ? Icons.phone_android : Icons.psychology_outlined),
                    color: isLocal ? Colors.blue : AppTheme.warmGold,
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
                                localizations.recommended,
                                style: TextStyle(
                                  color: AppTheme.warmGold,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          if (isLocal)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                localizations.private,
                                style: TextStyle(
                                  color: Colors.blue,
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
}
