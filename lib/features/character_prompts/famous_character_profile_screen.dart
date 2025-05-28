import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import 'famous_character_prompts.dart';
import 'famous_character_chat_screen.dart';
import '../character_gallery/character_gallery_screen.dart';
import '../../l10n/app_localizations.dart';
import 'dart:math';

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
        FamousCharacterPrompts.getShortBio(widget.name) ??
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
                    color: AppTheme.warmGold.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.cosmicBlack.withOpacity(0.3),
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
                                AppTheme.warmGold.withOpacity(0.3),
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
                                color: AppTheme.warmGold.withOpacity(0.2),
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
                                                .withOpacity(0.1),
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
                                      color: AppTheme.warmGold.withOpacity(0.5),
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
                                AppTheme.warmGold.withOpacity(0.05),
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
                            color: AppTheme.deepNavy.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.warmGold.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            widget.profession,
                            style: GoogleFonts.cinzel(
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

              // Info Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.warmGold.withOpacity(0.3),
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
                    color: AppTheme.warmGold.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Biography',
                      style: GoogleFonts.cinzel(
                        textStyle: TextStyle(
                          color: AppTheme.warmGold,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
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
                        textStyle: TextStyle(
                          color: AppTheme.warmGold,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildModelDropdown(),

                    // View all models option
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () {
                        // This will be implemented later
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'This feature will be available soon',
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          border: Border(
                            top: BorderSide(
                              color: AppTheme.warmGold.withOpacity(0.3),
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
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Explore more AI options',
                                  style: TextStyle(
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
              ),

              const SizedBox(height: 24),

              // Start Chat Button
              Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: AppTheme.warmGold,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.warmGold.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToChat(context),
                    icon: const Icon(Icons.chat_bubble_outline, size: 20),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Text(
                        'Start Conversation',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
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
    );
  }

  Widget _buildModelDropdown() {
    // Get available models for this character
    final models = FamousCharacterPrompts.getModelsForCharacter(widget.name);

    return Column(
      children: [
        ...models
            .map(
              (model) => _buildModelOption(
                id: model['id'] as String,
                name: model['name'] as String,
                description: model['description'] as String,
                isRecommended: model['recommended'] == true,
                isSelected: _selectedModel == model['id'],
              ),
            )
            .toList(),
      ],
    );
  }

  Widget _buildModelOption({
    required String id,
    required String name,
    required String description,
    required bool isRecommended,
    required bool isSelected,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color:
            isSelected ? AppTheme.deepIndigo.withOpacity(0.7) : Colors.black12,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isSelected
                  ? AppTheme.warmGold.withOpacity(0.7)
                  : AppTheme.warmGold.withOpacity(0.2),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedModel = id;
              FamousCharacterPrompts.setSelectedModel(widget.name, id);
            });
            // Show a confirmation to the user
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('AI model updated for ${widget.name}'),
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
                            ? AppTheme.warmGold.withOpacity(0.2)
                            : Colors.black26,
                    border: Border.all(
                      color:
                          isSelected
                              ? AppTheme.warmGold
                              : AppTheme.warmGold.withOpacity(0.3),
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
                                color: AppTheme.warmGold.withOpacity(0.2),
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
