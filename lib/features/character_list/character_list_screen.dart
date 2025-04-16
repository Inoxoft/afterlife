import 'package:flutter/material.dart';
import 'package:afterlife/core/theme/app_theme.dart';
import 'package:afterlife/core/widgets/animated_particles.dart';
import 'package:afterlife/features/models/character_model.dart';
import 'package:afterlife/features/character_interview/interview_screen.dart';
import 'package:afterlife/features/chat/chat_screen.dart';
import 'package:afterlife/features/character_storage/character_storage.dart';

class CharacterListScreen extends StatefulWidget {
  const CharacterListScreen({Key? key}) : super(key: key);

  @override
  State<CharacterListScreen> createState() => _CharacterListScreenState();
}

class _CharacterListScreenState extends State<CharacterListScreen> {
  List<CharacterModel> _characters = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCharacters();
  }

  Future<void> _loadCharacters() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final characters = await CharacterStorage.getCharacters();
      setState(() {
        _characters = characters;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteCharacter(String id) async {
    final bool confirmed =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                backgroundColor: AppTheme.deepIndigo,
                title: const Text(
                  'Delete Character',
                  style: TextStyle(color: Colors.white),
                ),
                content: const Text(
                  'Are you sure you want to delete this character? This action cannot be undone.',
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirmed) {
      try {
        await CharacterStorage.deleteCharacter(id);
        _loadCharacters();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting character: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Your Digital Twins',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.backgroundStart,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
        child: Stack(
          children: [
            const Opacity(
              opacity: 0.5,
              child: AnimatedParticles(
                particleCount: 30,
                particleColor: Colors.white,
                minSpeed: 0.01,
                maxSpeed: 0.03,
              ),
            ),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _characters.isEmpty
                ? _buildEmptyState()
                : _buildCharacterList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off,
            size: 80,
            color: Colors.white.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Digital Twins Yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first digital twin by going to the Create tab!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterList() {
    return RefreshIndicator(
      onRefresh: _loadCharacters,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _characters.length,
        itemBuilder: (context, index) {
          final character = _characters[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            color: Colors.white.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ChatScreen(
                          characterId: character.id,
                          characterName: character.name,
                        ),
                  ),
                ).then((_) => _loadCharacters());
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white24,
                      child: Text(
                        character.name.isNotEmpty
                            ? character.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            character.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            character.getShortDescription(),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Created: ${character.getFormattedDate()}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white70),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => InterviewScreen(
                                      editMode: true,
                                      existingCharacter: character,
                                    ),
                              ),
                            ).then((_) => _loadCharacters());
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.white70),
                          onPressed: () => _deleteCharacter(character.id),
                        ),
                      ],
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
}
