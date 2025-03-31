import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/animated_particles.dart';
import '../models/character_model.dart';
import '../providers/characters_provider.dart';
import '../character_chat/chat_screen.dart';
import '../character_interview/interview_screen.dart';

class CharacterGalleryScreen extends StatelessWidget {
  const CharacterGalleryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Twins'),
        backgroundColor: AppTheme.backgroundStart,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
        child: Consumer<CharactersProvider>(
          builder: (context, provider, child) {
            final characters = provider.characters;

            if (provider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.etherealCyan,
                  ),
                ),
              );
            }

            if (characters.isEmpty) {
              return _buildEmptyState(context);
            }

            // Grid of character cards
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: characters.length,
              itemBuilder: (context, index) {
                final character = characters[index];
                return _buildCharacterCard(context, character);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onAddCharacter(context),
        backgroundColor: AppTheme.etherealCyan,
        child: const Icon(Icons.add, color: Colors.black87),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.person_add_alt_1_outlined,
              size: 64,
              color: AppTheme.etherealCyan.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Digital Twins Yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Create your first digital twin by tapping the + button below.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _onAddCharacter(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Digital Twin'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.etherealCyan,
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterCard(BuildContext context, CharacterModel character) {
    return GestureDetector(
      onTap: () => _onCharacterTap(context, character),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Character image or avatar
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: character.accentColor.withOpacity(0.2),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child:
                      character.imageUrl != null
                          ? ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            child: Image.network(
                              character.imageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildAvatarFallback(character);
                              },
                              loadingBuilder: (
                                context,
                                child,
                                loadingProgress,
                              ) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      character.accentColor,
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                          : _buildAvatarFallback(character),
                ),
              ),
            ),

            // Character info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
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
                      'Created: ${_formatDate(character.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Chat button
                        GestureDetector(
                          onTap: () => _onChatTap(context, character),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: character.accentColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 14,
                                  color: character.accentColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Chat',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: character.accentColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Delete button
                        GestureDetector(
                          onTap: () => _onDeleteTap(context, character),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: Colors.red.withOpacity(0.7),
                            ),
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
      ),
    );
  }

  Widget _buildAvatarFallback(CharacterModel character) {
    return CircleAvatar(
      radius: 40,
      backgroundColor: character.accentColor.withOpacity(0.3),
      child: Text(
        character.name.isNotEmpty ? character.name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: character.accentColor,
        ),
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

  void _onCharacterTap(BuildContext context, CharacterModel character) {
    _onChatTap(context, character);
  }

  void _onChatTap(BuildContext context, CharacterModel character) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CharacterChatScreen(characterId: character.id),
      ),
    );
  }

  void _onDeleteTap(BuildContext context, CharacterModel character) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Digital Twin'),
            content: Text(
              'Are you sure you want to delete ${character.name}? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Provider.of<CharactersProvider>(
                    context,
                    listen: false,
                  ).deleteCharacter(character.id);
                  Navigator.pop(context);
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _onAddCharacter(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const InterviewScreen()),
    );

    if (result != null) {
      // Process the returned character data
      final characterCard = result['characterCard'];
      final characterName = result['characterName'];

      if (characterCard != null && characterName != null) {
        print('New character data received - Name: $characterName');

        // Create new character
        final charactersProvider = Provider.of<CharactersProvider>(
          context,
          listen: false,
        );

        final newCharacter = CharacterModel.fromInterviewData(
          name: characterName,
          cardContent: characterCard,
        );

        // Add to provider
        charactersProvider.addCharacter(newCharacter);
        print('New character added to provider');
      }
    }
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
