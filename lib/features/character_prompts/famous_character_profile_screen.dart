import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import 'famous_character_prompts.dart';
import 'famous_character_chat_screen.dart';
import '../character_gallery/character_gallery_screen.dart';
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

  @override
  void initState() {
    super.initState();

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
    final shortBio =
        FamousCharacterPrompts.getShortBio(widget.name) ??
        'No biography available.';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundStart,
        title: Text('${widget.name}\'s Profile'),
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
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 12),
                    const Text(
                      'Biography',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      shortBio,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.5,
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
}
