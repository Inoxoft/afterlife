import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/utils/ukrainian_font_utils.dart';

class LLMPage extends StatefulWidget {
  final AnimationController animationController;

  const LLMPage({Key? key, required this.animationController})
    : super(key: key);

  @override
  State<LLMPage> createState() => _LLMPageState();
}

class _LLMPageState extends State<LLMPage> {
  // Track selected LLM option (0 = OpenRouter Models, 1 = Local LLMs)
  // int _selectedOption = 0; // Removed as per request

  @override
  Widget build(BuildContext context) {
    // Create staggered animations with smoother curves
    final titleAnimation = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: widget.animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    final imageAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: widget.animationController,
        curve: const Interval(0.1, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    final contentAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: widget.animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Determine which LLM to highlight based on selected option
    // final bool highlightAdvancedLLM = _selectedOption == 0; // OpenRouter = Advanced
    // final bool highlightBasicLLM = _selectedOption == 1; // Local = Basic
    // Always highlight Advanced LLM and de-emphasize Basic LLM
    const bool highlightAdvancedLLM = true;
    const bool highlightBasicLLM = false;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title with animation
            SlideTransition(
              position: titleAnimation,
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: widget.animationController,
                  curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.theMindBehindTwins,
                      textAlign: TextAlign.center,
                      style: UkrainianFontUtils.cinzelWithUkrainianSupport(
                        text: AppLocalizations.of(context)!.theMindBehindTwins,
                        fontSize: 24,
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
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.poweredByAdvancedLanguageModels,
                      textAlign: TextAlign.center,
                      style: UkrainianFontUtils.latoWithUkrainianSupport(
                        text: AppLocalizations.of(context)!.poweredByAdvancedLanguageModels,
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                        color: AppTheme.silverMist.withValues(alpha: 0.9),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Main explanation
            SlideTransition(
              position: contentAnimation,
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: widget.animationController,
                  curve: const Interval(0.3, 1.0),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.midnightPurple.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.warmGold.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.psychology,
                            color: AppTheme.warmGold,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(context)!.howItWorks,
                            style: UkrainianFontUtils.cinzelWithUkrainianSupport(
                              text: AppLocalizations.of(context)!.howItWorks,
                              color: AppTheme.warmGold,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.twinsPoweredByAI,
                        style: UkrainianFontUtils.latoWithUkrainianSupport(
                          text: AppLocalizations.of(context)!.twinsPoweredByAI,
                          color: AppTheme.silverMist,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // LLM comparison visualization
            SlideTransition(
              position: contentAnimation,
              child: FadeTransition(
                opacity: imageAnimation,
                child: ScaleTransition(
                  scale: imageAnimation,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final maxWidth = constraints.maxWidth;
                      final visualHeight = maxWidth * 0.4;
                      return SizedBox(
                        height: visualHeight,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Left side - Basic LLM
                            Positioned(
                              left: 0,
                              child: SizedBox(
                                width: maxWidth * 0.45,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!.basicLLM,
                                      textAlign: TextAlign.center,
                                      style: UkrainianFontUtils.cinzelWithUkrainianSupport(
                                        text: AppLocalizations.of(context)!.basicLLM,
                                        fontSize: maxWidth * 0.035,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.silverMist.withValues(alpha: 0.8),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: maxWidth * 0.22,
                                      height: maxWidth * 0.22,
                                      child: CustomPaint(
                                        painter: SimpleNeuronPainter(
                                          highlighted: false,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      AppLocalizations.of(context)!.limitedKnowledge,
                                      textAlign: TextAlign.center,
                                      style: UkrainianFontUtils.latoWithUkrainianSupport(
                                        text: AppLocalizations.of(context)!.limitedKnowledge,
                                        fontSize: maxWidth * 0.03,
                                        fontWeight: FontWeight.w300,
                                        color: AppTheme.silverMist.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Right side - Advanced LLM
                            Positioned(
                              right: 0,
                              child: SizedBox(
                                width: maxWidth * 0.45,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!.advancedLLM,
                                      textAlign: TextAlign.center,
                                      style: UkrainianFontUtils.cinzelWithUkrainianSupport(
                                        text: AppLocalizations.of(context)!.advancedLLM,
                                        fontSize: maxWidth * 0.035,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.warmGold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: maxWidth * 0.22,
                                      height: maxWidth * 0.22,
                                      child: CustomPaint(
                                        painter: ComplexNeuronPainter(
                                          highlighted: true,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      AppLocalizations.of(context)!.deepKnowledge,
                                      textAlign: TextAlign.center,
                                      style: UkrainianFontUtils.latoWithUkrainianSupport(
                                        text: AppLocalizations.of(context)!.deepKnowledge,
                                        fontSize: maxWidth * 0.03,
                                        fontWeight: FontWeight.w300,
                                        color: AppTheme.warmGold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Center connecting line
                            Center(
                              child: Container(
                                width: maxWidth * 0.1,
                                height: 2,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      AppTheme.silverMist.withValues(alpha: 0.2),
                                      AppTheme.warmGold.withValues(alpha: 0.7),
                                      AppTheme.silverMist.withValues(alpha: 0.2),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Example Scenario
            SlideTransition(
              position: contentAnimation,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.midnightPurple.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.warmGold.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: AppTheme.warmGold,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          AppLocalizations.of(context)!.exampleInteraction,
                          style: UkrainianFontUtils.cinzelWithUkrainianSupport(
                            text: AppLocalizations.of(context)!.exampleInteraction,
                            color: AppTheme.warmGold,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.whenDiscussingRelativityWithEinstein,
                      style: UkrainianFontUtils.latoWithUkrainianSupport(
                        text: AppLocalizations.of(context)!.whenDiscussingRelativityWithEinstein,
                        color: AppTheme.warmGold,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildExampleBubble(
                      AppLocalizations.of(context)!.withAdvancedLLMLabel,
                      AppLocalizations.of(context)!.withAdvancedLLMExample,
                      true,
                    ),
                    const SizedBox(height: 8),
                    _buildExampleBubble(
                      AppLocalizations.of(context)!.withBasicLLMLabel,
                      AppLocalizations.of(context)!.withBasicLLMExample,
                      false,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildModelTile(String name, String description, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.midnightPurple.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.warmGold,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: UkrainianFontUtils.cinzelWithUkrainianSupport(
                  text: name,
                  color: AppTheme.warmGold,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: UkrainianFontUtils.latoWithUkrainianSupport(
                  text: description,
                  color: AppTheme.silverMist,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExampleBubble(String title, String content, bool isAdvanced) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.midnightPurple.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAdvanced ? AppTheme.warmGold.withValues(alpha: 0.3) : AppTheme.silverMist.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: UkrainianFontUtils.latoWithUkrainianSupport(
              text: title,
              color: isAdvanced ? AppTheme.warmGold : AppTheme.silverMist,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: UkrainianFontUtils.latoWithUkrainianSupport(
              text: content,
              color: isAdvanced ? AppTheme.silverMist : AppTheme.silverMist.withValues(alpha: 0.7),
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// Paint a simple neuron network
class SimpleNeuronPainter extends CustomPainter {
  final bool highlighted;
  
  SimpleNeuronPainter({this.highlighted = false});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = highlighted 
              ? AppTheme.warmGold.withValues(alpha: 0.6) 
              : AppTheme.silverMist.withValues(alpha: 0.3)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

    final dotPaint =
        Paint()
          ..color = highlighted 
              ? AppTheme.warmGold.withValues(alpha: 0.8) 
              : AppTheme.silverMist.withValues(alpha: 0.5)
          ..style = PaintingStyle.fill;

    // Draw a few simple connections
    final center = Offset(size.width / 2, size.height / 2);

    // Draw 4 nodes and connections
    for (int i = 0; i < 4; i++) {
      final angle = i * (pi / 2);
      final nodeOffset = Offset(
        center.dx + cos(angle) * 30,
        center.dy + sin(angle) * 30,
      );

      // Draw connection
      canvas.drawLine(center, nodeOffset, paint);

      // Draw node
      canvas.drawCircle(nodeOffset, 3, dotPaint);
    }

    // Draw center node
    canvas.drawCircle(center, 5, dotPaint);
    
    // Add glow effect if highlighted
    if (highlighted) {
      canvas.drawCircle(
        center,
        25,
        Paint()
          ..color = AppTheme.warmGold.withValues(alpha: 0.1)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => 
      oldDelegate is SimpleNeuronPainter && 
      oldDelegate.highlighted != highlighted;
}

// Paint a complex neuron network
class ComplexNeuronPainter extends CustomPainter {
  final bool highlighted;
  
  ComplexNeuronPainter({this.highlighted = true});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = highlighted 
              ? AppTheme.warmGold.withValues(alpha: 0.6) 
              : AppTheme.silverMist.withValues(alpha: 0.3)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

    final dotPaint =
        Paint()
          ..color = highlighted 
              ? AppTheme.warmGold.withValues(alpha: 0.8) 
              : AppTheme.silverMist.withValues(alpha: 0.5)
          ..style = PaintingStyle.fill;

    // Draw many connections in a more complex pattern
    final center = Offset(size.width / 2, size.height / 2);

    // Draw first layer - 8 nodes
    List<Offset> firstLayer = [];
    for (int i = 0; i < 8; i++) {
      final angle = i * (pi / 4);
      final nodeOffset = Offset(
        center.dx + cos(angle) * 40,
        center.dy + sin(angle) * 40,
      );
      firstLayer.add(nodeOffset);

      // Draw connection to center
      canvas.drawLine(center, nodeOffset, paint);

      // Draw node
      canvas.drawCircle(nodeOffset, 2, dotPaint);
    }

    // Draw some inter-connections between nodes
    for (int i = 0; i < firstLayer.length; i++) {
      for (int j = i + 2; j < firstLayer.length; j += 3) {
        canvas.drawLine(firstLayer[i], firstLayer[j], paint..strokeWidth = 0.5);
      }
    }

    // Draw center node
    canvas.drawCircle(center, 5, dotPaint);

    // Add some glowing effect
    if (highlighted) {
      canvas.drawCircle(
        center,
        25,
        Paint()
          ..color = AppTheme.warmGold.withValues(alpha: 0.1)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => 
      oldDelegate is ComplexNeuronPainter && 
      oldDelegate.highlighted != highlighted;
}
