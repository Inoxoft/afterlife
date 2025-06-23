import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/character_model.dart';
import '../providers/characters_provider.dart';
import '../../core/theme/app_theme.dart';
import '../character_profile/character_profile_screen.dart';
import '../settings/settings_screen.dart';
import '../character_chat/chat_screen.dart';
import '../character_interview/interview_screen.dart';
import '../character_prompts/famous_character_profile_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../core/utils/ukrainian_font_utils.dart';
import '../../core/utils/responsive_utils.dart';
import '../widgets/background_painters.dart';

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
  List<BottomNavigationBarItem> _getNavigationItems(AppLocalizations localizations) {
    return [
      BottomNavigationBarItem(
        icon: const Icon(Icons.explore, size: 24),
        label: localizations.explore,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.person_outline, size: 24),
        label: localizations.yourTwins,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.add_circle_outline, size: 24),
        label: localizations.create,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.settings, size: 24),
        label: localizations.settings,
      ),
    ];
  }

  // Sample famous people for the Explore tab - using const for better performance
  List<Map<String, dynamic>> _getFamousPeople(AppLocalizations localizations) {
    return [
      {
        'name': 'Albert Einstein',
        'years': '1879-1955',
        'profession': localizations.physicist,
        'imageUrl': 'assets/images/einstein.png',
      },
      {
        'name': 'Ronald Reagan',
        'years': '1911-2004',
        'profession': localizations.presidentActor,
        'imageUrl': 'assets/images/reagan.png',
      },
      {
        'name': 'Alan Turing',
        'years': '1912-1954',
        'profession': localizations.computerScientist,
        'imageUrl': 'assets/images/turing.png',
      },
      {
        'name': 'Marilyn Monroe',
        'years': '1926-1962',
        'profession': localizations.actressModelSinger,
        'imageUrl': 'assets/images/monroe.png',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final navigationItems = _getNavigationItems(localizations);
    final famousPeople = _getFamousPeople(localizations);

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
                  padding: EdgeInsets.fromLTRB(
                    ResponsiveUtils.getScreenPadding(context).left,
                    32,
                    ResponsiveUtils.getScreenPadding(context).right,
                    24,
                  ),
                  child: Text(
                    _selectedIndex == 0
                        ? localizations.exploreDigitalTwins
                        : localizations.yourDigitalTwins,
                    style: UkrainianFontUtils.cinzelWithUkrainianSupport(
                      text: _selectedIndex == 0
                          ? localizations.exploreDigitalTwins
                          : localizations.yourDigitalTwins,
                      fontSize: 24 * ResponsiveUtils.getFontSizeScale(context),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3.0,
                      color: AppTheme.silverMist,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: AppTheme.warmGold.withValues(alpha: 0.8),
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),

                // Main content area with PageView
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    children: [
                      _buildExploreTab(localizations, famousPeople),
                      _buildYourTwinsTab(localizations),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          textTheme: Theme.of(context).textTheme.copyWith(
            bodySmall: UkrainianFontUtils.latoWithUkrainianSupport(
              text: "Sample", // This will be used for tab labels
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.midnightPurple.withValues(alpha: 0.7),
            border: Border(
              top: BorderSide(
                color: AppTheme.warmGold.withValues(alpha: 0.3),
                width: 1.0,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.deepNavy.withValues(alpha: 0.3),
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
            selectedLabelStyle: UkrainianFontUtils.latoWithUkrainianSupport(
              text: "Tab", // Placeholder text for style detection
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.warmGold,
            ),
            unselectedLabelStyle: UkrainianFontUtils.latoWithUkrainianSupport(
              text: "Tab", // Placeholder text for style detection
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppTheme.silverMist.withValues(alpha: 0.5),
            ),
            unselectedItemColor: AppTheme.silverMist.withValues(alpha: 0.5),
            selectedItemColor: AppTheme.warmGold,
            items: navigationItems,
          ),
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
  Widget _buildExploreTab(AppLocalizations localizations, List<Map<String, dynamic>> famousPeople) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.interactWithHistoricalFigures,
            style: UkrainianFontUtils.latoWithUkrainianSupport(
              text: localizations.interactWithHistoricalFigures,
              fontSize: 16,
              color: AppTheme.silverMist.withValues(alpha: 0.8),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ResponsiveUtils.shouldUseWideLayout(context)
              ? _buildHorizontalGallery(famousPeople, isExploreTab: true)
              : _buildGridGallery(famousPeople, isExploreTab: true),
          ),
        ],
      ),
    );
  }

  // Your Twins tab with user's digital twins
  Widget _buildYourTwinsTab(AppLocalizations localizations) {
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
                  localizations.accessingDataStorage,
                  style: UkrainianFontUtils.cinzelWithUkrainianSupport(
                    text: localizations.accessingDataStorage,
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
          return _buildEmptyState(context, localizations);
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ResponsiveUtils.shouldUseWideLayout(context)
            ? _buildHorizontalGallery(characters, isExploreTab: false)
            : _buildGridGallery(characters, isExploreTab: false),
        );
      },
    );
  }

  Widget _buildGridGallery(List<dynamic> items, {required bool isExploreTab}) {
    return GridView.builder(
      key: PageStorageKey(isExploreTab ? 'exploreTab' : 'yourTwinsTab'),
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getGridSpacing(context),
        vertical: 24,
      ),
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveUtils.getGridCrossAxisCount(context),
        childAspectRatio: ResponsiveUtils.getGridChildAspectRatio(context),
        crossAxisSpacing: ResponsiveUtils.getGridSpacing(context),
        mainAxisSpacing: ResponsiveUtils.getGridSpacing(context),
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        if (isExploreTab) {
          final famousPerson = item as Map<String, dynamic>;
          return _FamousPersonCard(
            key: ValueKey('famous_person_${famousPerson['name']}'),
            name: famousPerson['name'] as String,
            years: famousPerson['years'] as String,
            profession: famousPerson['profession'] as String,
            imageUrl: famousPerson['imageUrl'] as String?,
            isHorizontalLayout: false,
          );
        } else {
          final character = item as CharacterModel;
          return _YourTwinCard(
            key: ValueKey(character.id),
            character: character,
            isHorizontalLayout: false,
          );
        }
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations localizations) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Empty state illustration
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.midnightPurple.withValues(alpha: 0.3),
              border: Border.all(
                color: AppTheme.warmGold.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.person_outline,
              size: 80,
              color: AppTheme.warmGold.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 32),

          // Empty state message
          Text(
            localizations.noDigitalTwinsDetected,
            style: UkrainianFontUtils.cinzelWithUkrainianSupport(
              text: localizations.noDigitalTwinsDetected,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.warmGold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),

          // Description text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              localizations.createNewTwinDescription,
              textAlign: TextAlign.center,
              style: UkrainianFontUtils.latoWithUkrainianSupport(
                text: localizations.createNewTwinDescription,
                fontSize: 16,
                color: AppTheme.silverMist.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Create button
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
                      AppTheme.warmGold.withValues(alpha: 0.8),
                      AppTheme.midnightPurple.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.warmGold.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ],
                  border: Border.all(
                    color: AppTheme.silverMist.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add,
                      size: 20,
                      color: AppTheme.silverMist.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      localizations.createNewTwin,
                      style: UkrainianFontUtils.cinzelWithUkrainianSupport(
                        text: localizations.createNewTwin,
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

  // Card for displaying a user-created character
  Widget _YourTwinCard({
    required Key key,
    required CharacterModel character,
    required bool isHorizontalLayout,
  }) {
    final localizations = AppLocalizations.of(context);

    return GestureDetector(
      key: key,
      onTap: () => _onCharacterSelected(context, character),
      child: Card(
        // ...
      ),
    );
  }

  Widget _buildHorizontalGallery(List<dynamic> items, {required bool isExploreTab}) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calculate card dimensions based on screen width
    double cardWidth = screenWidth > 1200 ? 320 : 280;
    double cardHeight = cardWidth * 1.4; // Maintain aspect ratio
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gallery title
        if (items.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 16),
            child: Text(
              isExploreTab ? 'Historical Figures' : 'Your Digital Twins',
              style: UkrainianFontUtils.cinzelWithUkrainianSupport(
                text: isExploreTab ? 'Historical Figures' : 'Your Digital Twins',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.warmGold,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
        
        // Horizontal scrolling gallery
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              
              return Container(
                width: cardWidth,
                height: cardHeight,
                margin: const EdgeInsets.only(right: 24),
                child: isExploreTab
                  ? _FamousPersonCard(
                      key: ValueKey('famous_person_${item['name']}'),
                      name: item['name'] as String,
                      years: item['years'] as String,
                      profession: item['profession'] as String,
                      imageUrl: item['imageUrl'] as String?,
                      isHorizontalLayout: true,
                    )
                  : _YourTwinCard(
                      key: ValueKey('character_${item.id}'),
                      character: item as CharacterModel,
                      isHorizontalLayout: true,
                    ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Extracted as a separate stateful widget for better performance through memoization
class _FamousPersonCard extends StatefulWidget {
  final String name;
  final String years;
  final String profession;
  final String? imageUrl;
  final bool isHorizontalLayout;

  const _FamousPersonCard({
    Key? key,
    required this.name,
    required this.years,
    required this.profession,
    this.imageUrl,
    this.isHorizontalLayout = false,
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
                                  ? accentColor.withValues(alpha: 0.6)
                                  : AppTheme.midnightPurple.withValues(alpha: 0.3),
                          blurRadius: _isHovering ? 15 : 8,
                          spreadRadius: _isHovering ? 2 : 0,
                          offset: Offset(0, 5 * _glowAnimation.value),
                        ),
                      ],
                      border: Border.all(
                        color:
                            _isHovering
                                ? accentColor.withValues(alpha: 0.7)
                                : accentColor.withValues(alpha: 0.3),
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
                            padding: EdgeInsets.symmetric(
                              vertical: widget.isHorizontalLayout ? 20 : 10,
                              horizontal: widget.isHorizontalLayout ? 15 : 5,
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
                                  AppTheme.deepNavy.withValues(alpha: 0.4),
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
                          size: widget.isHorizontalLayout ? 120 : 80,
                          color: accentColor.withValues(alpha: 0.5),
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
                          AppTheme.deepNavy.withValues(alpha: 0.7),
                          AppTheme.deepNavy.withValues(alpha: 0.9),
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
                    padding: EdgeInsets.all(widget.isHorizontalLayout ? 20 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Digital twin name
                        Text(
                          widget.name,
                          style: UkrainianFontUtils.cinzelWithUkrainianSupport(
                            text: widget.name,
                            fontSize: widget.isHorizontalLayout ? 22 : 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: AppTheme.warmGold,
                            shadows: [
                              Shadow(
                                color: AppTheme.warmGold.withValues(alpha: 0.5),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          maxLines: widget.isHorizontalLayout ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        SizedBox(height: widget.isHorizontalLayout ? 8 : 6),

                        // Years
                        Row(
                          children: [
                            // Pulsing indicator
                            _buildPulsingDot(),
                            const SizedBox(width: 8),
                            Text(
                              widget.years,
                              style: UkrainianFontUtils.cinzelWithUkrainianSupport(
                                text: widget.years,
                                fontSize: widget.isHorizontalLayout ? 16 : 14,
                                color: AppTheme.warmGold,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    color: AppTheme.warmGold.withValues(alpha: 0.5),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: widget.isHorizontalLayout ? 12 : 10),

                        // Profession label with elegant styling
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: widget.isHorizontalLayout ? 12 : 8,
                            vertical: widget.isHorizontalLayout ? 6 : 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.warmGold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(widget.isHorizontalLayout ? 6 : 4),
                            border: Border.all(
                              color: AppTheme.warmGold.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            widget.profession,
                            style: UkrainianFontUtils.cinzelWithUkrainianSupport(
                              text: widget.profession,
                              fontSize: widget.isHorizontalLayout ? 13 : 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                              color: AppTheme.warmGold,
                            ),
                            maxLines: widget.isHorizontalLayout ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
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
                        color: AppTheme.warmGold.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.deepNavy.withValues(alpha: 0.2),
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
                            color: AppTheme.midnightPurple.withValues(alpha: 0.9),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'View',
                            style: UkrainianFontUtils.cinzelWithUkrainianSupport(
                              text: 'View',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.midnightPurple,
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

// Custom painter for the starfield background effect
class StarfieldPainter extends CustomPainter {
  final int starCount;
  final List<_Star> _stars = [];
  final Random _random = Random(42);
  final Paint _goldStarPaint =
      Paint()..color = AppTheme.warmGold.withValues(alpha: 0.8);
  final Paint _purpleStarPaint =
      Paint()..color = AppTheme.gentlePurple.withValues(alpha: 0.6);
  final Paint _silverStarPaint =
      Paint()..color = AppTheme.silverMist.withValues(alpha: 0.7);

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
