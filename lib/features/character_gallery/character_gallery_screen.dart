import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../models/character_model.dart';
import '../providers/characters_provider.dart';
import '../character_chat/chat_screen.dart';
import '../character_interview/interview_screen.dart';

class CharacterGalleryScreen extends StatefulWidget {
  const CharacterGalleryScreen({Key? key}) : super(key: key);

  @override
  State<CharacterGalleryScreen> createState() => _CharacterGalleryScreenState();
}

class _CharacterGalleryScreenState extends State<CharacterGalleryScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  // Cache text styles for better performance
  late final TextStyle _titleStyle = const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: 2,
    color: Colors.white,
  );

  late final TextStyle _subtitleStyle = TextStyle(
    fontSize: 14,
    letterSpacing: 1.5,
    color: Colors.white.withOpacity(0.8),
  );

  late final TextStyle _captionStyle = TextStyle(
    fontSize: 12,
    color: Colors.white.withOpacity(0.6),
  );

  // Cached bottom navigation items for better performance
  final List<BottomNavigationBarItem> _navigationItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      label: 'Your Twins',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.add_circle_outline),
      label: 'Create',
    ),
    BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
  ];

  // Sample famous people for the Explore tab - using const for better performance
  final List<Map<String, dynamic>> _famousPeople = const [
    {
      'name': 'Albert Einstein',
      'years': '1879-1955',
      'profession': 'PHYSICIST',
      'imageUrl': null,
    },
    {
      'name': 'Ronald Reagan',
      'years': '1911-2004',
      'profession': 'PRESIDENT, ACTOR',
      'imageUrl': null,
    },
    {
      'name': 'Alan Turing',
      'years': '1912-1954',
      'profession': 'COMPUTER SCIENTIST',
      'imageUrl': null,
    },
    {
      'name': 'Marilyn Monroe',
      'years': '1926-1962',
      'profession': 'ACTRESS, MODEL & SINGER',
      'imageUrl': null,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header - using cached widgets for better performance
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AFTERLIFE', style: _titleStyle),
                    const SizedBox(height: 8),
                    Text(
                      _selectedIndex == 0
                          ? 'EXPLORE DIGITAL TWINS'
                          : 'YOUR DIGITAL TWINS',
                      style: _subtitleStyle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Interact with preserved consciousness',
                      style: _captionStyle,
                    ),
                  ],
                ),
              ),

              // Content based on selected tab
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex < 2 ? _selectedIndex : 0,
                  children: [_buildExploreTab(), _buildYourTwinsTab()],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        backgroundColor: AppTheme.backgroundEnd,
        type: BottomNavigationBarType.fixed,
        unselectedItemColor: Colors.white.withOpacity(0.5),
        selectedItemColor: AppTheme.etherealCyan,
        items: _navigationItems,
      ),
    );
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Handle "Create" tab action
    if (index == 2) {
      _onAddCharacter(context);
    }
  }

  // Explore tab with famous people
  Widget _buildExploreTab() {
    return GridView.builder(
      key: const PageStorageKey('exploreTab'),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
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
    );
  }

  // Your Twins tab with user's characters
  Widget _buildYourTwinsTab() {
    return Consumer<CharactersProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.etherealCyan),
            ),
          );
        }

        final characters = provider.characters;

        if (characters.isEmpty) {
          return _buildEmptyState(context);
        }

        // Grid of character cards
        return GridView.builder(
          key: const PageStorageKey('yourTwinsTab'),
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: characters.length,
          itemBuilder: (context, index) {
            final character = characters[index];
            return _CharacterCard(
              key: ValueKey('character_${character.id}'),
              character: character,
              onTap: () => _onCharacterSelected(context, character),
            );
          },
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
            Icon(
              Icons.person_off_outlined,
              size: 72,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No digital twins available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a new digital twin to begin interacting with your preserved consciousness',
              style: _captionStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _onAddCharacter(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.etherealCyan,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add),
                  SizedBox(width: 8),
                  Text('CREATE NEW TWIN'),
                ],
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

// Extracted as a separate stateless widget for better performance through memoization
class _FamousPersonCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundEnd.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.etherealCyan.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: AppTheme.etherealCyan.withOpacity(0.3),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Character image or placeholder
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundStart.withOpacity(0.7),
                image:
                    imageUrl != null
                        ? DecorationImage(
                          image: NetworkImage(imageUrl!),
                          fit: BoxFit.cover,
                        )
                        : null,
              ),
              child:
                  imageUrl == null
                      ? Center(
                        child: Icon(
                          Icons.person_outline,
                          size: 60,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      )
                      : null,
            ),
          ),

          // Info
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Name and years
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.deepIndigo.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '• $years',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        profession,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.etherealCyan,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Extracted as a separate stateless widget for better performance through memoization
class _CharacterCard extends StatelessWidget {
  final CharacterModel character;
  final VoidCallback onTap;

  const _CharacterCard({Key? key, required this.character, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundEnd.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.etherealCyan.withOpacity(0.15),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: AppTheme.etherealCyan.withOpacity(0.2),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Character image or placeholder
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.backgroundStart,
                  image:
                      character.imageUrl != null &&
                              character.imageUrl!.isNotEmpty
                          ? DecorationImage(
                            image: NetworkImage(character.imageUrl!),
                            fit: BoxFit.cover,
                          )
                          : null,
                ),
                child:
                    character.imageUrl == null || character.imageUrl!.isEmpty
                        ? Center(
                          child: Icon(
                            Icons.person_outline,
                            size: 60,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        )
                        : null,
              ),
            ),

            // Character info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Name and date
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          character.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Created ${_formatDate(character.createdAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),

                    // Chat button
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.etherealCyan.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 14,
                            color: AppTheme.etherealCyan,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'CHAT',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.etherealCyan,
                            ),
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
    );
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
