import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// A themed icon widget that provides consistent styling for icons
/// throughout the settings screen.
class ThemedIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double size;
  final bool showGlow;

  const ThemedIcon({
    Key? key,
    required this.icon,
    this.color,
    this.size = 24.0,
    this.showGlow = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? AppTheme.warmGold;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        boxShadow:
            showGlow
                ? [
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ]
                : null,
      ),
      child: Icon(icon, color: iconColor, size: size),
    );
  }
}
