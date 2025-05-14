import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import '../models/character_model.dart';
import '../providers/characters_provider.dart';
import '../../core/theme/app_theme.dart';
import '../character_profile/character_profile_screen.dart';
import '../settings/settings_screen.dart';
import '../character_chat/chat_screen.dart';
import '../character_interview/interview_screen.dart';
import '../character_prompts/famous_character_profile_screen.dart';

class PulseRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  PulseRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint =
        Paint()
          ..color = color.withOpacity(0.3 * (1 - progress))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 * (1 + progress);

    final double radius = size.width / 2 * (0.8 + progress * 0.2);
    final Offset center = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(PulseRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class CharacterGalleryScreen extends StatefulWidget {
  const CharacterGalleryScreen({Key? key}) : super(key: key);

  @override
  State<CharacterGalleryScreen> createState() => _CharacterGalleryScreenState();
}

class _CharacterGalleryScreenState extends State<CharacterGalleryScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Cache text styles for better performance
  late final TextStyle _titleStyle = AppTheme.titleStyle;

  late final TextStyle _subtitleStyle = AppTheme.subtitleStyle;

  late final TextStyle _captionStyle = AppTheme.captionStyle;

  // Cached bottom navigation items for better performance
  final List<BottomNavigationBarItem> _navigationItems = const [
    BottomNavigationBarItem(
      icon: Icon(Icons.explore, size: 24),
      label: 'Explore',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline, size: 24),
      label: 'Your Twins',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.add_circle_outline, size: 24),
      label: 'Create',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.settings, size: 24),
      label: 'Settings',
    ),
  ];

  // Sample famous people for the Explore tab - using const for better performance
  final List<Map<String, dynamic>> _famousPeople = const [
    {
      'name': 'Albert Einstein',
      'years': '1879-1955',
      'profession': 'PHYSICIST',
      'imageUrl': 'assets/images/einstein.png',
    },
    {
      'name': 'Ronald Reagan',
      'years': '1911-2004',
      'profession': 'PRESIDENT, ACTOR',
      'imageUrl': 'assets/images/reagan.png',
    },
    {
      'name': 'Alan Turing',
      'years': '1912-1954',
      'profession': 'COMPUTER SCIENTIST',
      'imageUrl': 'assets/images/turing.png',
    },
    {
      'name': 'Marilyn Monroe',
      'years': '1926-1962',
      'profession': 'ACTRESS, MODEL & SINGER',
      'imageUrl': 'assets/images/monroe.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background with gradient
          Container(
            decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
          ),

          // Stars effect with reduced opacity - wrapped in RepaintBoundary for performance
          RepaintBoundary(
            child: CustomPaint(
              painter: StarfieldPainter(starCount: 80), // Reduced count
              size: Size.infinite,
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section with enhanced styling
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main title with elegant styling
                      Text('AFTERLIFE', style: _titleStyle),

                      // Animated divider with gradient effect
                      const SizedBox(height: 16),
                      Container(
                        width: 120,
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.warmGold,
                              AppTheme.warmGold.withOpacity(0.1),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.7, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.warmGold.withOpacity(0.4),
                              blurRadius: 6,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Subtitle with section indicator
                      Text(
                        _selectedIndex == 0
                            ? 'EXPLORE DIGITAL TWINS'
                            : 'YOUR DIGITAL TWINS',
                        style: _subtitleStyle,
                      ),

                      const SizedBox(height: 8),

                      // Caption text
                      Text(
                        'Interact with historical figures through their masks',
                        style: _captionStyle,
                      ),
                    ],
                  ),
                ),

                // Content based on selected tab
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    children: [_buildExploreTab(), _buildYourTwinsTab()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.midnightPurple.withOpacity(0.7),
          border: Border(
            top: BorderSide(
              color: AppTheme.warmGold.withOpacity(0.3),
              width: 1.0,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.deepNavy.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onTabTapped,
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: GoogleFonts.lato(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelStyle: GoogleFonts.lato(
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          unselectedItemColor: AppTheme.silverMist.withOpacity(0.5),
          selectedItemColor: AppTheme.warmGold,
          items: _navigationItems,
        ),
      ),
    );
  }

  void _onTabTapped(int index) {
    // Animate to the selected page
    if (index < 2) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    setState(() {
      _selectedIndex = index;
    });

    // Handle "Create" tab action
    if (index == 2) {
      _onAddCharacter(context);
    }
    // Handle "Settings" tab action
    else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsScreen()),
      ).then((_) {
        // Reset selected index to previous tab when returning from settings
        setState(() {
          _selectedIndex = _selectedIndex < 2 ? _selectedIndex : 1;
        });
      });
    }
  }

  // Explore tab with famous digital twins
  Widget _buildExploreTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        key: const PageStorageKey('exploreTab'),
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
        ),
        itemCount: _famousPeople.length,
        itemBuilder: (context, index) {
          final person = _famousPeople[index];
          return _FamousPersonCard(
            key: ValueKey('famous_person_${person['name']}'),
            name: person['name'] as String,
            years: person['years'] as String,
            profession: person['profession'] as String,
            imageUrl: person['imageUrl'] as String?,
          );
        },
      ),
    );
  }

  // Your Twins tab with user's digital twins
  Widget _buildYourTwinsTab() {
    return Consumer<CharactersProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.warmGold,
                    ),
                    strokeWidth: 2,
                    backgroundColor: AppTheme.deepNavy,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'ACCESSING DATA STORAGE',
                  style: GoogleFonts.cinzel(
                    fontSize: 14,
                    color: AppTheme.warmGold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          );
        }

        final characters = provider.characters;

        if (characters.isEmpty) {
          return _buildEmptyState(context);
        }

        // Grid of user-created character cards
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.builder(
            key: const PageStorageKey('yourTwinsTab'),
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: characters.length,
            itemBuilder: (context, index) {
              final character = characters[index];
              return FutureBuilder<Widget>(
                // Using a slight delay for staggered animation
                future: Future.delayed(
                  Duration(milliseconds: 100 * index),
                  () => _CharacterCard(
                    key: ValueKey('character_${character.id}'),
                    character: character,
                    onTap: () => _onCharacterSelected(context, character),
                  ),
                ),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Container(
                      decoration: BoxDecoration(
                        color: AppTheme.deepSpaceNavy.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    );
                  }
                  return AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: snapshot.hasData ? 1.0 : 0.0,
                    child: snapshot.data!,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Empty state icon with glow effect
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.midnightPurple.withOpacity(0.3),
                border: Border.all(
                  color: AppTheme.warmGold.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.warmGold.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                Icons.person_outline,
                size: 50,
                color: AppTheme.warmGold.withOpacity(0.7),
              ),
            ),

            const SizedBox(height: 24),

            // Empty state title
            Text(
              'NO DIGITAL TWINS DETECTED',
              style: GoogleFonts.cinzel(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.silverMist,
                letterSpacing: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Empty state description
            Text(
              'Create a new digital twin to begin interacting with your preserved consciousness',
              style: AppTheme.captionStyle,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Create button with energy field styling
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _onAddCharacter(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.warmGold.withOpacity(0.8),
                        AppTheme.midnightPurple.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.warmGold.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ],
                    border: Border.all(
                      color: AppTheme.silverMist.withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add,
                        size: 20,
                        color: AppTheme.silverMist.withOpacity(0.9),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'CREATE NEW TWIN',
                        style: GoogleFonts.cinzel(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.silverMist,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onCharacterSelected(BuildContext context, CharacterModel character) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CharacterChatScreen(characterId: character.id),
      ),
    );
  }

  void _onAddCharacter(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const InterviewScreen()),
    );

    if (result != null && result is CharacterModel) {
      await Provider.of<CharactersProvider>(
        context,
        listen: false,
      ).addCharacter(result);
    }
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) return 'today';
    if (difference.inDays == 1) return 'yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

// Extracted as a separate stateful widget for better performance through memoization
class _FamousPersonCard extends StatefulWidget {
  final String name;
  final String years;
  final String profession;
  final String? imageUrl;

  const _FamousPersonCard({
    Key? key,
    required this.name,
    required this.years,
    required this.profession,
    this.imageUrl,
  }) : super(key: key);

  @override
  State<_FamousPersonCard> createState() => _FamousPersonCardState();
}

class _FamousPersonCardState extends State<_FamousPersonCard>
    with SingleTickerProviderStateMixin {
  // Animation controller for hover effects
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  late Animation<double> _scaleAnimation;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Create a custom accent color for the card
    final Color accentColor = AppTheme.warmGold;

    return GestureDetector(
      onTap: () => _navigateToProfile(context),
      child: MouseRegion(
        onEnter:
            (_) => setState(() {
              _isHovering = true;
              _controller.forward();
            }),
        onExit:
            (_) => setState(() {
              _isHovering = false;
              _controller.reverse();
            }),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _isHovering ? _scaleAnimation.value : 1.0,
              child: Stack(
                children: [
                  // Main card with glowing effect
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.midnightPurple, AppTheme.deepNavy],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color:
                              _isHovering
                                  ? accentColor.withOpacity(0.6)
                                  : AppTheme.midnightPurple.withOpacity(0.3),
                          blurRadius: _isHovering ? 15 : 8,
                          spreadRadius: _isHovering ? 2 : 0,
                          offset: Offset(0, 5 * _glowAnimation.value),
                        ),
                      ],
                      border: Border.all(
                        color:
                            _isHovering
                                ? accentColor.withOpacity(0.7)
                                : accentColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: child,
                    ),
                  ),

                  // Pulse ring animation when hovering
                  if (_isHovering)
                    AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, _) {
                        return Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: CustomPaint(
                              painter: PulseRingPainter(
                                progress: _glowAnimation.value,
                                color: accentColor,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Background image if available
                if (widget.imageUrl != null)
                  Positioned.fill(
                    child: Stack(
                      children: [
                        // Dramatic background for masks
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppTheme.midnightPurple,
                                AppTheme.deepNavy,
                              ],
                            ),
                          ),
                        ),
                        // Centered mask image with subtle shadow effect
                        Center(
                          child: Container(
                            width: double.infinity,
                            height: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 5,
                            ),
                            child: Image.asset(
                              widget.imageUrl!,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        // Subtle spotlight effect overlay
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment.center,
                                radius: 1.2,
                                colors: [
                                  Colors.transparent,
                                  AppTheme.deepNavy.withOpacity(0.4),
                                ],
                                stops: const [0.6, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                // If no image, use gradient background
                else
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppTheme.deepNavy, AppTheme.midnightPurple],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.person_outline,
                          size: 80,
                          color: accentColor.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),

                // Gradient overlay for better text contrast
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppTheme.deepNavy.withOpacity(0.7),
                          AppTheme.deepNavy.withOpacity(0.9),
                        ],
                        stops: const [0.6, 0.85, 1.0],
                      ),
                    ),
                  ),
                ),

                // Card content
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Digital twin name
                        Text(
                          widget.name,
                          style: AppTheme.twinNameStyle.copyWith(
                            shadows: [
                              Shadow(
                                color: AppTheme.warmGold.withOpacity(0.5),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 6),

                        // Years
                        Row(
                          children: [
                            // Pulsing indicator
                            _buildPulsingDot(),
                            const SizedBox(width: 8),
                            Text(
                              widget.years,
                              style: AppTheme.metadataStyle.copyWith(
                                shadows: [
                                  Shadow(
                                    color: AppTheme.warmGold.withOpacity(0.5),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Profession label with elegant styling
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.warmGold.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppTheme.warmGold.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            widget.profession,
                            style: TextStyle(
                              color: AppTheme.warmGold,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Add a subtle "Coming Soon" overlay for unreleased characters
                // Only shown if the _isReleased flag is specifically set to false
                if (_isHovering)
                  Positioned(
                    right: 16,
                    top: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.warmGold.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.deepNavy.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_forward,
                            color: AppTheme.midnightPurple.withOpacity(0.9),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'View',
                            style: TextStyle(
                              color: AppTheme.midnightPurple,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPulsingDot() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.warmGold,
            boxShadow: [
              BoxShadow(
                color: AppTheme.warmGold.withOpacity(
                  0.5 * _glowAnimation.value,
                ),
                blurRadius: 4 * _glowAnimation.value,
                spreadRadius: 1 * _glowAnimation.value,
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => FamousCharacterProfileScreen(
              name: widget.name,
              years: widget.years,
              profession: widget.profession,
              imageUrl: widget.imageUrl,
            ),
      ),
    );
  }
}

// Custom painter for ethereal particle effect with subtle movement
class EtherealParticlePainter extends CustomPainter {
  final int particleCount;
  final Color color;
  final double pulsePhase;
  final double opacity;

  EtherealParticlePainter({
    required this.particleCount,
    required this.color,
    this.pulsePhase = 0.0,
    this.opacity = 0.1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42); // Fixed seed for deterministic pattern
    final width = size.width;
    final height = size.height;

    for (int i = 0; i < particleCount; i++) {
      final x = random.nextDouble() * width;
      final y = random.nextDouble() * height;
      final baseSize = 0.5 + random.nextDouble() * 1.5;
      final particlePulse = (sin((pulsePhase * pi * 2) + (i * 0.2)) + 1) / 2;
      final particleSize = baseSize * (0.5 + (particlePulse * 0.5));

      // Vary opacity based on pulse
      final particleOpacity = opacity * (0.5 + particlePulse * 0.5);

      final paint =
          Paint()
            ..color = color.withOpacity(particleOpacity)
            ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), particleSize, paint);

      // Add subtle glow
      final glowPaint =
          Paint()
            ..color = color.withOpacity(particleOpacity * 0.5)
            ..style = PaintingStyle.fill
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawCircle(Offset(x, y), particleSize * 2, glowPaint);
    }
  }

  @override
  bool shouldRepaint(EtherealParticlePainter oldDelegate) {
    return oldDelegate.particleCount != particleCount ||
        oldDelegate.color != color ||
        oldDelegate.pulsePhase != pulsePhase ||
        oldDelegate.opacity != opacity;
  }
}

// Custom painter for film grain texture
class FilmGrainPainter extends CustomPainter {
  final double density;
  final double opacity;
  final Random random = Random(42);

  FilmGrainPainter({this.density = 0.5, this.opacity = 0.1});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(opacity)
          ..style = PaintingStyle.fill;

    final numPoints = (size.width * size.height * density / 30).round();

    for (int i = 0; i < numPoints; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final pointSize = random.nextDouble() * 1.0;

      canvas.drawCircle(Offset(x, y), pointSize, paint);
    }
  }

  @override
  bool shouldRepaint(FilmGrainPainter oldDelegate) {
    return oldDelegate.density != density || oldDelegate.opacity != opacity;
  }
}

// Extracted as a separate stateful widget for better performance through memoization
class _CharacterCard extends StatefulWidget {
  final CharacterModel character;
  final VoidCallback onTap;

  const _CharacterCard({Key? key, required this.character, required this.onTap})
    : super(key: key);

  @override
  State<_CharacterCard> createState() => _CharacterCardState();
}

class _CharacterCardState extends State<_CharacterCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  // Cache image widget for performance
  late final ImageProvider? _characterImageProvider =
      widget.character.imageUrl != null
          ? ResizeImage.resizeIfNeeded(
            500,
            null,
            NetworkImage(widget.character.imageUrl!),
          )
          : null;

  // Pre-calculate accent color
  late final Color _accentColor = _getAccentColor();

  @override
  void initState() {
    super.initState();

    // Set up subtle pulsing animation for the card
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  Color _getAccentColor() {
    // Choose accent color based on character name's first letter
    final letter =
        widget.character.name.isNotEmpty
            ? widget.character.name[0].toLowerCase()
            : 'a';

    if ('abcde'.contains(letter)) {
      return AppTheme.etherealCyan;
    } else if ('fghij'.contains(letter)) {
      return AppTheme.accentPurple;
    } else if ('klmno'.contains(letter)) {
      return AppTheme.starlight;
    } else if ('pqrst'.contains(letter)) {
      return AppTheme.accentPurple;
    } else {
      return AppTheme.warmGold;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _deleteCharacter() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppTheme.midnightPurple,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: AppTheme.warmGold.withOpacity(0.3),
                width: 1,
              ),
            ),
            title: Text(
              'Delete Character',
              style: TextStyle(
                color: AppTheme.silverMist,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Are you sure you want to delete ${widget.character.name}? This action cannot be undone.',
              style: TextStyle(color: AppTheme.silverMist.withOpacity(0.7)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppTheme.silverMist.withOpacity(0.7)),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Delete the character
                  final provider = Provider.of<CharactersProvider>(
                    context,
                    listen: false,
                  );
                  provider.deleteCharacter(widget.character.id);
                },
                child: Text(
                  'Delete',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return GestureDetector(
            onTap: widget.onTap,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.warmGold.withOpacity(
                      0.2 + _glowAnimation.value * 0.1,
                    ),
                    blurRadius: 8 + _glowAnimation.value * 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Character image or background pattern
                    Positioned.fill(
                      child:
                          widget.character.imageUrl != null
                              ? Image(
                                image: _characterImageProvider!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildBackgroundPattern();
                                },
                              )
                              : _buildBackgroundPattern(),
                    ),

                    // Gradient overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppTheme.midnightPurple.withOpacity(0.3),
                              AppTheme.deepNavy.withOpacity(0.85),
                            ],
                            stops: const [0.5, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Delete button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: _deleteCharacter,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.midnightPurple.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.warmGold.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            color: AppTheme.silverMist,
                            size: 20,
                          ),
                        ),
                      ),
                    ),

                    // Character info content
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Character name
                            Text(
                              widget.character.name,
                              style: GoogleFonts.spaceMono(
                                color: AppTheme.silverMist,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    color: AppTheme.warmGold.withOpacity(0.5),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Build a background pattern based on character properties
  Widget _buildBackgroundPattern() {
    // Get a consistent background based on the character's name or ID
    final hashValue = widget.character.id.hashCode;
    final patternIndex = hashValue % 6; // 6 different patterns

    // Background pattern options
    switch (patternIndex) {
      case 0:
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.warmGold.withOpacity(0.3),
                AppTheme.midnightPurple,
              ],
            ),
          ),
          child: CustomPaint(
            painter: GeometricBackgroundPainter(color: AppTheme.warmGold),
          ),
        );
      case 1:
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppTheme.deepNavy, AppTheme.cosmicBlack],
            ),
          ),
          child: CustomPaint(
            painter: CosmicBackgroundPainter(starColor: AppTheme.warmGold),
          ),
        );
      case 2:
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                AppTheme.deepSpaceNavy,
                AppTheme.deepNavy.withOpacity(0.7),
              ],
            ),
          ),
          child: CustomPaint(
            painter: NeuralBackgroundPainter(lineColor: AppTheme.warmGold),
          ),
        );
      case 3:
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.deepIndigo.withOpacity(0.8),
                AppTheme.cosmicBlack,
              ],
            ),
          ),
          child: CustomPaint(
            painter: WaveBackgroundPainter(
              waveColor: AppTheme.warmGold.withOpacity(0.5),
            ),
          ),
        );
      case 4:
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [AppTheme.cosmicBlack, AppTheme.deepSpaceNavy],
            ),
          ),
          child: CustomPaint(
            painter: DigitalBackgroundPainter(lineColor: AppTheme.warmGold),
          ),
        );
      default:
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.deepSpaceNavy, AppTheme.deepIndigo],
            ),
          ),
          child: CustomPaint(
            painter: LightBackgroundPainter(lightColor: AppTheme.warmGold),
          ),
        );
    }
  }
}

// Background painter classes
class GeometricBackgroundPainter extends CustomPainter {
  final Color color;

  GeometricBackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color.withOpacity(0.15)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;

    final random = Random(42); // Fixed seed for consistent pattern

    // Draw some triangles and circles
    for (int i = 0; i < 15; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 10 + random.nextDouble() * 30;

      if (i % 2 == 0) {
        // Draw triangles
        final path = Path();
        path.moveTo(x, y - radius);
        path.lineTo(x + radius, y + radius);
        path.lineTo(x - radius, y + radius);
        path.close();
        canvas.drawPath(path, paint);
      } else {
        // Draw circles
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class CosmicBackgroundPainter extends CustomPainter {
  final Color starColor;

  CosmicBackgroundPainter({required this.starColor});

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(100); // Fixed seed for consistent stars

    // Draw stars
    for (int i = 0; i < 100; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 0.5 + random.nextDouble() * 1.5;
      final opacity = 0.3 + random.nextDouble() * 0.7;

      final paint =
          Paint()
            ..color = starColor.withOpacity(opacity)
            ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Draw a few larger glowing stars
    for (int i = 0; i < 5; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 1.5 + random.nextDouble() * 2.0;

      final paint =
          Paint()
            ..color = starColor.withOpacity(0.8)
            ..style = PaintingStyle.fill;

      // Inner glow
      final glowPaint =
          Paint()
            ..color = starColor.withOpacity(0.2)
            ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), radius * 3, glowPaint);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class NeuralBackgroundPainter extends CustomPainter {
  final Color lineColor;

  NeuralBackgroundPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(25); // Fixed seed for consistency
    final paint =
        Paint()
          ..color = lineColor.withOpacity(0.2)
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke;

    final nodePaint =
        Paint()
          ..color = lineColor.withOpacity(0.3)
          ..style = PaintingStyle.fill;

    // Create a network of nodes and connections
    final nodes = <Offset>[];

    // Generate node positions
    for (int i = 0; i < 12; i++) {
      nodes.add(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
      );
    }

    // Draw connections between some nodes
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        if (random.nextDouble() < 0.3) {
          canvas.drawLine(nodes[i], nodes[j], paint);
        }
      }
    }

    // Draw nodes
    for (final node in nodes) {
      canvas.drawCircle(node, 2.5, nodePaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class WaveBackgroundPainter extends CustomPainter {
  final Color waveColor;

  WaveBackgroundPainter({required this.waveColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = waveColor.withOpacity(0.2)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    // Draw several wave patterns
    for (int w = 0; w < 5; w++) {
      final path = Path();
      final amplitude = 5.0 + (w * 3);
      final frequency = 0.02 + (w * 0.005);
      final verticalShift = (w * 30) + (size.height * 0.2);

      path.moveTo(0, size.height / 2);

      for (double x = 0; x <= size.width; x += 1) {
        double y = sin(x * frequency) * amplitude + verticalShift;
        path.lineTo(x, y);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class DigitalBackgroundPainter extends CustomPainter {
  final Color lineColor;

  DigitalBackgroundPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = lineColor.withOpacity(0.25)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

    final random = Random(55);

    // Draw digital circuit-like patterns
    for (int i = 0; i < 8; i++) {
      final startX = random.nextDouble() * size.width * 0.2;
      final startY = (i * size.height / 8) + random.nextDouble() * 20;

      final path = Path();
      path.moveTo(startX, startY);

      double currentX = startX;
      double currentY = startY;

      // Create a path with horizontal and vertical lines only
      for (int j = 0; j < 5; j++) {
        // Horizontal line
        final horizontalLength = 20 + random.nextDouble() * (size.width / 3);
        currentX += horizontalLength;
        path.lineTo(currentX, currentY);

        // Sometimes add a vertical segment
        if (random.nextDouble() > 0.3) {
          final verticalLength = (random.nextDouble() - 0.5) * 40;
          currentY += verticalLength;
          path.lineTo(currentX, currentY);
        }
      }

      canvas.drawPath(path, paint);

      // Add some circuit nodes/connection points
      final nodePaint =
          Paint()
            ..color = lineColor.withOpacity(0.4)
            ..style = PaintingStyle.fill;

      currentX = startX;
      currentY = startY;
      canvas.drawCircle(Offset(currentX, currentY), 2, nodePaint);

      for (int j = 0; j < 3; j++) {
        currentX += 40 + random.nextDouble() * 60;
        canvas.drawCircle(Offset(currentX, currentY), 2, nodePaint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class LightBackgroundPainter extends CustomPainter {
  final Color lightColor;

  LightBackgroundPainter({required this.lightColor});

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);

    // Draw light rays or beams
    for (int i = 0; i < 15; i++) {
      final startX = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;
      final angle = random.nextDouble() * pi * 2;
      final length = 30 + random.nextDouble() * 100;
      final opacity = 0.1 + random.nextDouble() * 0.15;

      final paint =
          Paint()
            ..color = lightColor.withOpacity(opacity)
            ..strokeWidth = 1 + random.nextDouble() * 3
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke;

      final endX = startX + cos(angle) * length;
      final endY = startY + sin(angle) * length;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);

      // Add a subtle glow at the start point
      final glowPaint =
          Paint()
            ..color = lightColor.withOpacity(opacity * 0.8)
            ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(startX, startY),
        3 + random.nextDouble() * 2,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Custom widget for dotted border
class DottedBorderContainer extends StatelessWidget {
  final Widget child;

  const DottedBorderContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Dotted border effect
          CustomPaint(
            painter: DottedBorderPainter(
              color: Colors.white30,
              strokeWidth: 1.5,
              gap: 5,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          // Content
          child,
        ],
      ),
    );
  }
}

// Custom painter for dotted border
class DottedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DottedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;

    final path =
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.width, size.height),
            const Radius.circular(16),
          ),
        );

    // Create dotted effect
    final dashPath = Path();
    const dashWidth = 5.0;

    for (
      var i = 0.0;
      i < path.computeMetrics().first.length;
      i += dashWidth + gap
    ) {
      final metric = path.computeMetrics().first;
      final start = i;
      final end =
          (i + dashWidth) < metric.length ? i + dashWidth : metric.length;
      dashPath.addPath(metric.extractPath(start, end), Offset.zero);
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for bubble effect
class BubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Base bubble paint
    final bubblePaint =
        Paint()
          ..color = Colors.white.withOpacity(0.25)
          ..style = PaintingStyle.fill;

    // Highlight paint for bubble shine
    final highlightPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.6)
          ..style = PaintingStyle.fill;

    // Draw different sized bubbles in a natural pattern
    final random = DateTime.now().millisecondsSinceEpoch;
    final bubblePositions = [
      // Left side bubbles
      Offset(size.width * 0.15, size.height * 0.25),
      Offset(size.width * 0.10, size.height * 0.45),
      Offset(size.width * 0.12, size.height * 0.65),
      Offset(size.width * 0.20, size.height * 0.80),
      // Middle bubbles
      Offset(size.width * 0.35, size.height * 0.35),
      Offset(size.width * 0.40, size.height * 0.15),
      Offset(size.width * 0.45, size.height * 0.70),
      // Right side bubbles
      Offset(size.width * 0.70, size.height * 0.25),
      Offset(size.width * 0.75, size.height * 0.50),
      Offset(size.width * 0.65, size.height * 0.80),
    ];

    // Bubble sizes
    final bubbleSizes = [2.5, 3.0, 2.0, 3.5, 2.0, 3.0, 2.5, 2.0, 3.5, 3.0];

    // Draw each bubble
    for (int i = 0; i < bubblePositions.length; i++) {
      final position = bubblePositions[i];
      final radius = bubbleSizes[i];

      // Draw bubble
      canvas.drawCircle(position, radius, bubblePaint);

      // Draw highlight in top-left of bubble
      canvas.drawCircle(
        Offset(position.dx - radius * 0.3, position.dy - radius * 0.3),
        radius * 0.3,
        highlightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Cyberpunk grid overlay painter
class GridOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.cyanAccent.withOpacity(0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5;

    // Horizontal lines
    const double gridSpacing = 35.0;
    for (double y = 0; y <= size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Vertical lines
    for (double x = 0; x <= size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for hexagonal grid effect
class HexGridPainter extends CustomPainter {
  final Color color;
  final double lineWidth;
  final double opacity;

  HexGridPainter({
    required this.color,
    this.lineWidth = 0.5,
    this.opacity = 0.2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color.withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = lineWidth;

    final hexSize = size.width / 12; // Size of each hexagon
    final height = size.height;
    final width = size.width;
    final sqrt3 = 1.732; // sqrt(3)

    // Horizontal distance between hex centers
    final hStep = hexSize * 2;
    // Vertical distance between hex centers
    final vStep = hexSize * sqrt3;

    // Calculate offset to center the grid
    final rows = (height / vStep).ceil() + 1;
    final cols = (width / hStep).ceil() + 1;

    // Draw hexagonal grid
    for (int r = -1; r < rows; r++) {
      for (int c = -1; c < cols; c++) {
        // Stagger odd rows
        final xOffset = c * hStep + (r % 2 == 0 ? 0 : hexSize);
        final yOffset = r * vStep;

        _drawHexagon(canvas, paint, xOffset, yOffset, hexSize);
      }
    }
  }

  void _drawHexagon(
    Canvas canvas,
    Paint paint,
    double xCenter,
    double yCenter,
    double size,
  ) {
    final path = Path();
    const double rotationOffset = 30 * (3.14159 / 180); // 30 degrees in radians

    for (int i = 0; i < 6; i++) {
      final angle =
          rotationOffset + (i * 60) * (3.14159 / 180); // Convert to radians
      final x = xCenter + size * cos(angle);
      final y = yCenter + size * sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(HexGridPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.lineWidth != lineWidth ||
        oldDelegate.opacity != opacity;
  }
}

// Custom painter for energy particles
class EnergyParticlePainter extends CustomPainter {
  final int particleCount;
  final Color color;
  final double pulsePhase;
  final double particleScale;

  EnergyParticlePainter({
    required this.particleCount,
    required this.color,
    this.pulsePhase = 0.0,
    this.particleScale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42); // Fixed seed for deterministic pattern
    final width = size.width;
    final height = size.height;

    // Generate particles
    for (int i = 0; i < particleCount; i++) {
      final x = random.nextDouble() * width;
      final y = random.nextDouble() * height;
      final baseSize = 1.0 + random.nextDouble() * 2.0;
      final particlePulse =
          (sin((pulsePhase * 3.14159 * 2) + (i * 0.2)) + 1) / 2;
      final particleSize =
          baseSize * particleScale * (0.5 + (particlePulse * 0.5));

      // Vary opacity based on particle size and position
      final opacity = 0.2 + (particlePulse * 0.6);

      final paint =
          Paint()
            ..color = color.withOpacity(opacity)
            ..style = PaintingStyle.fill;

      // Draw the particle
      canvas.drawCircle(Offset(x, y), particleSize, paint);

      // Add a glow effect
      final glowPaint =
          Paint()
            ..color = color.withOpacity(opacity * 0.3)
            ..style = PaintingStyle.fill
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawCircle(Offset(x, y), particleSize * 1.8, glowPaint);
    }
  }

  @override
  bool shouldRepaint(EnergyParticlePainter oldDelegate) {
    return oldDelegate.particleCount != particleCount ||
        oldDelegate.color != color ||
        oldDelegate.pulsePhase != pulsePhase ||
        oldDelegate.particleScale != particleScale;
  }
}

// Custom painter for CRT/digital scan lines
class ScanLinePainter extends CustomPainter {
  final double lineSpacing;
  final double lineOpacity;

  ScanLinePainter({this.lineSpacing = 4.0, this.lineOpacity = 0.1});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = AppTheme.midnightPurple.withOpacity(lineOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5;

    // Draw horizontal scan lines
    for (double y = 0; y < size.height; y += lineSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Add some faint vertical distortion lines occasionally
    final distortionPaint =
        Paint()
          ..color = AppTheme.warmGold.withOpacity(lineOpacity * 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5;

    final random = Random(12345); // Fixed seed for deterministic pattern

    for (int i = 0; i < 5; i++) {
      final x = random.nextDouble() * size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), distortionPaint);
    }
  }

  @override
  bool shouldRepaint(ScanLinePainter oldDelegate) {
    return oldDelegate.lineSpacing != lineSpacing ||
        oldDelegate.lineOpacity != lineOpacity;
  }
}

// Custom painter for the starfield background effect
class StarfieldPainter extends CustomPainter {
  final int starCount;
  final List<_Star> _stars = [];
  final Random _random = Random(42);
  final Paint _goldStarPaint =
      Paint()..color = AppTheme.warmGold.withOpacity(0.8);
  final Paint _purpleStarPaint =
      Paint()..color = AppTheme.gentlePurple.withOpacity(0.6);
  final Paint _silverStarPaint =
      Paint()..color = AppTheme.silverMist.withOpacity(0.7);

  StarfieldPainter({this.starCount = 100}) {
    // Pre-generate stars only once for performance
    _generateStars();
  }

  void _generateStars() {
    for (int i = 0; i < starCount; i++) {
      final starType = _random.nextInt(10); // 0-9 random value for star type
      final Color starColor;

      // Distribute colors: 20% gold, 30% purple, 50% silver
      if (starType < 2) {
        starColor = AppTheme.warmGold;
      } else if (starType < 5) {
        starColor = AppTheme.gentlePurple;
      } else {
        starColor = AppTheme.silverMist;
      }

      _stars.add(
        _Star(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: _random.nextDouble() * 2 + 0.5,
          opacity: _random.nextDouble() * 0.7 + 0.3,
          color: starColor,
        ),
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in _stars) {
      final x = star.x * size.width;
      final y = star.y * size.height;

      final Paint starPaint =
          Paint()..color = star.color.withOpacity(star.opacity);

      canvas.drawCircle(Offset(x, y), star.size, starPaint);

      // Add subtle glow to larger stars
      if (star.size > 1.2) {
        final glowPaint =
            Paint()
              ..color = star.color.withOpacity(star.opacity * 0.3)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

        canvas.drawCircle(Offset(x, y), star.size * 2, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(StarfieldPainter oldDelegate) => false; // Never repaint
}

class _Star {
  final double x;
  final double y;
  final double size;
  final double opacity;
  final Color color;

  _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.color,
  });
}
