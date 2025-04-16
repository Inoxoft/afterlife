import 'package:flutter/material.dart';
import 'package:afterlife/core/theme/app_theme.dart';
import 'package:afterlife/core/widgets/animated_particles.dart';
import 'package:afterlife/features/chat/chat_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Discover',
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Featured Digital Twins',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: const [
                        FeaturedCharacterCard(
                          name: 'Albert Einstein',
                          role: 'Physicist',
                          imagePath: 'assets/images/einstein.jpg',
                          description:
                              'The genius behind the theory of relativity.',
                          characterId: 'einstein',
                        ),
                        FeaturedCharacterCard(
                          name: 'Frida Kahlo',
                          role: 'Artist',
                          imagePath: 'assets/images/frida.jpg',
                          description:
                              'Iconic Mexican painter known for her self-portraits.',
                          characterId: 'frida',
                        ),
                        FeaturedCharacterCard(
                          name: 'Steve Jobs',
                          role: 'Innovator',
                          imagePath: 'assets/images/jobs.jpg',
                          description:
                              'Co-founder of Apple and visionary leader.',
                          characterId: 'jobs',
                        ),
                        FeaturedCharacterCard(
                          name: 'Marie Curie',
                          role: 'Scientist',
                          imagePath: 'assets/images/curie.jpg',
                          description: 'Pioneer in radioactivity research.',
                          characterId: 'curie',
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
}

class FeaturedCharacterCard extends StatelessWidget {
  final String name;
  final String role;
  final String imagePath;
  final String description;
  final String characterId;

  const FeaturedCharacterCard({
    Key? key,
    required this.name,
    required this.role,
    required this.imagePath,
    required this.description,
    required this.characterId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    ChatScreen(characterId: characterId, characterName: name),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withOpacity(0.1),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.person,
                        color: Colors.white70,
                        size: 64,
                      ),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
}
