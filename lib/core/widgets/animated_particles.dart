import 'dart:math';
// lib/core/widgets/animated_particles.dart
import 'package:flutter/material.dart';

class AnimatedParticles extends StatefulWidget {
  final int particleCount;
  final Color particleColor;
  final double minSpeed;
  final double maxSpeed;

  const AnimatedParticles({
    super.key,
    this.particleCount = 50,
    this.particleColor = Colors.white,
    this.minSpeed = 0.05,
    this.maxSpeed = 0.2,
  });

  @override
  State<AnimatedParticles> createState() => _AnimatedParticlesState();
}

class _AnimatedParticlesState extends State<AnimatedParticles>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late List<Particle> particles;
  final Random random = Random();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Add post-frame callback to ensure we have valid dimensions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeParticles();
      }
    });
  }

  void _initializeParticles() {
    if (!mounted) return;

    try {
      final size = MediaQuery.of(context).size;

      if (size.width <= 0 || size.height <= 0) {
        // Invalid size, try again after delay
        Future.delayed(Duration(milliseconds: 200), () {
          if (mounted) _initializeParticles();
        });
        return;
      }

      // Initialize particles with proper screen dimensions
      particles = List.generate(
        widget.particleCount,
        (_) => Particle(
          position: Offset(
            random.nextDouble() * size.width,
            random.nextDouble() * size.height,
          ),
          speed: _generateSpeed(),
          radius: random.nextDouble() * 2 + 0.5,
          opacity: random.nextDouble() * 0.5 + 0.1,
        ),
      );

      _animController.addListener(_updateParticles);
      _initialized = true;
      if (mounted) setState(() {});
    } catch (e) {
      // Try again after delay
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) _initializeParticles();
      });
    }
  }

  void _updateParticles() {
    if (!mounted || !_initialized) return;

    try {
      final size = MediaQuery.of(context).size;
      if (size.width <= 0 || size.height <= 0) return;

      for (var particle in particles) {
        particle.position += particle.speed;

        // Wrap particles around screen edges with proper dimensions
        if (particle.position.dx < 0)
          particle.position = Offset(size.width, particle.position.dy);
        if (particle.position.dx > size.width)
          particle.position = Offset(0, particle.position.dy);
        if (particle.position.dy < 0)
          particle.position = Offset(particle.position.dx, size.height);
        if (particle.position.dy > size.height)
          particle.position = Offset(particle.position.dx, 0);
      }

      if (mounted) setState(() {});
    } catch (e) {
    }
  }

  Offset _generateSpeed() {
    final speedRange = widget.maxSpeed - widget.minSpeed;
    final xSpeed =
        (random.nextDouble() - 0.5) *
        2 *
        (widget.minSpeed + random.nextDouble() * speedRange);
    final ySpeed =
        (random.nextDouble() - 0.5) *
        2 *
        (widget.minSpeed + random.nextDouble() * speedRange);
    return Offset(xSpeed, ySpeed);
  }

  @override
  void dispose() {
    _animController.removeListener(_updateParticles);
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Safety check to ensure we're not rendering with invalid constraints
        if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
          return const SizedBox.shrink();
        }

        return CustomPaint(
          painter: ParticlePainter(
            particles: particles,
            color: widget.particleColor,
          ),
          size: Size(constraints.maxWidth, constraints.maxHeight),
        );
      },
    );
  }
}

class Particle {
  Offset position;
  Offset speed;
  double radius;
  double opacity;

  Particle({
    required this.position,
    required this.speed,
    required this.radius,
    this.opacity = 0.2,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Color color;

  ParticlePainter({required this.particles, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Safety check
    if (size.width <= 0 || size.height <= 0) return;

    for (var particle in particles) {
      final paint =
          Paint()
            ..color = color.withOpacity(particle.opacity)
            ..style = PaintingStyle.fill;

      // Only draw particles within the visible area
      if (particle.position.dx >= 0 &&
          particle.position.dx <= size.width &&
          particle.position.dy >= 0 &&
          particle.position.dy <= size.height) {
        canvas.drawCircle(particle.position, particle.radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
