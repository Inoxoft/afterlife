// lib/core/widgets/animated_particles.dart
import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedParticles extends StatefulWidget {
  final int particleCount;
  final Color particleColor;
  
  const AnimatedParticles({
    Key? key,
    this.particleCount = 50,
    this.particleColor = Colors.white,
  }) : super(key: key);

  @override
  State<AnimatedParticles> createState() => _AnimatedParticlesState();
}

class _AnimatedParticlesState extends State<AnimatedParticles> with TickerProviderStateMixin {
  late AnimationController _animController;
  late List<Particle> particles;
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    
    // Initialize particles
    particles = List.generate(
      widget.particleCount,
      (_) => Particle(
        position: Offset(
          random.nextDouble() * 400,
          random.nextDouble() * 800,
        ),
        speed: Offset(
          (random.nextDouble() - 0.5) * 0.2,
          (random.nextDouble() - 0.5) * 0.2,
        ),
        radius: random.nextDouble() * 2 + 0.5,
      ),
    );
    
    _animController.addListener(() {
      for (var particle in particles) {
        particle.position += particle.speed;
        
        // Wrap particles around screen edges
        if (particle.position.dx < 0) particle.position = Offset(400, particle.position.dy);
        if (particle.position.dx > 400) particle.position = Offset(0, particle.position.dy);
        if (particle.position.dy < 0) particle.position = Offset(particle.position.dx, 800);
        if (particle.position.dy > 800) particle.position = Offset(particle.position.dx, 0);
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ParticlePainter(
        particles: particles,
        color: widget.particleColor,
      ),
      size: Size.infinite,
    );
  }
}

class Particle {
  Offset position;
  Offset speed;
  double radius;
  
  Particle({
    required this.position,
    required this.speed,
    required this.radius,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Color color;
  
  ParticlePainter({required this.particles, required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    
    for (var particle in particles) {
      canvas.drawCircle(particle.position, particle.radius, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
