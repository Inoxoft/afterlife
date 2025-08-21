import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

/// Adaptive text widget that automatically adjusts font size to fit content
/// without truncation, providing better user experience on all screen sizes.
class AdaptiveText extends StatelessWidget {
  final String text;
  final TextStyle baseStyle;
  final double maxFontSize;
  final double minFontSize;
  final int maxLines;
  final TextAlign textAlign;
  final double stepSize;
  final bool useDeviceScaling;
  final EdgeInsets padding;

  const AdaptiveText({
    Key? key,
    required this.text,
    required this.baseStyle,
    required this.maxFontSize,
    required this.minFontSize,
    this.maxLines = 2,
    this.textAlign = TextAlign.start,
    this.stepSize = 0.5,
    this.useDeviceScaling = true,
    this.padding = EdgeInsets.zero,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return _buildAdaptiveText(context, constraints);
      },
    );
  }

  Widget _buildAdaptiveText(BuildContext context, BoxConstraints constraints) {
    // Apply device scaling if enabled
    double scaledMaxFontSize = maxFontSize;
    double scaledMinFontSize = minFontSize;

    if (useDeviceScaling) {
      final deviceScale = ResponsiveUtils.getFontSizeScale(context);
      scaledMaxFontSize = maxFontSize * deviceScale;
      scaledMinFontSize = minFontSize * deviceScale;
    }

    // Account for padding in available space
    final availableWidth = constraints.maxWidth - padding.horizontal;
    final availableHeight = constraints.maxHeight - padding.vertical;

    final adjustedConstraints = BoxConstraints(
      maxWidth: availableWidth,
      maxHeight: availableHeight,
    );

    double optimalFontSize = _findOptimalFontSize(
      scaledMaxFontSize,
      scaledMinFontSize,
      adjustedConstraints,
    );

    final textWidget = Text(
      text,
      style: baseStyle.copyWith(fontSize: optimalFontSize),
      maxLines: maxLines,
      textAlign: textAlign,
      overflow: TextOverflow.clip,
      softWrap: maxLines == 1 ? false : true,
    );

    // For single-line text, always allow scaleDown to guarantee fit
    Widget child = maxLines == 1
        ? FittedBox(
            fit: BoxFit.scaleDown,
            alignment: textAlign == TextAlign.center
                ? Alignment.center
                : textAlign == TextAlign.right
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
            child: textWidget,
          )
        : textWidget;

    return Padding(padding: padding, child: child);
  }

  /// Uses binary search to find the optimal font size that fits in constraints
  double _findOptimalFontSize(
    double maxSize,
    double minSize,
    BoxConstraints constraints,
  ) {
    double high = maxSize;
    double low = minSize;
    double optimalSize = minSize;

    // Use binary search for efficient font size finding
    while (high - low > stepSize) {
      double mid = (high + low) / 2;

      if (_textFitsInConstraints(mid, constraints)) {
        low = mid;
        optimalSize = mid;
      } else {
        high = mid;
      }
    }

    return optimalSize;
  }

  bool _textFitsInConstraints(double fontSize, BoxConstraints constraints) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: baseStyle.copyWith(fontSize: fontSize)),
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(maxWidth: constraints.maxWidth);
    // For single-line text, ensure it fits within available width
    if (maxLines == 1) {
      final fitsWidth = textPainter.size.width <= constraints.maxWidth + 0.1;
      if (!constraints.maxHeight.isFinite) return fitsWidth;
      return fitsWidth && textPainter.height <= constraints.maxHeight;
    }

    // If height is unbounded for multi-line, rely on didExceedMaxLines
    if (!constraints.maxHeight.isFinite) {
      return !textPainter.didExceedMaxLines;
    }
    return textPainter.height <= constraints.maxHeight;
  }
}

/// Helper extension for creating commonly used adaptive text configurations
extension AdaptiveTextPresets on AdaptiveText {
  /// Creates an adaptive text for character names in gallery cards
  static AdaptiveText characterName({
    required String text,
    required TextStyle baseStyle,
    required bool isHorizontalLayout,
  }) {
    return AdaptiveText(
      text: text,
      baseStyle: baseStyle,
      maxFontSize: isHorizontalLayout ? 22 : 18,
      minFontSize: isHorizontalLayout ? 9 : 6,
      maxLines: 1,
      textAlign: TextAlign.start,
    );
  }

  /// Creates an adaptive text for profession/model labels
  static AdaptiveText label({
    required String text,
    required TextStyle baseStyle,
    required bool isHorizontalLayout,
  }) {
    return AdaptiveText(
      text: text,
      baseStyle: baseStyle,
      maxFontSize: isHorizontalLayout ? 13 : 11,
      minFontSize: isHorizontalLayout ? 8 : 7,
      maxLines: 1,
      textAlign: TextAlign.start,
    );
  }

  /// Creates an adaptive text for metadata like dates or years
  static AdaptiveText metadata({
    required String text,
    required TextStyle baseStyle,
    required bool isHorizontalLayout,
  }) {
    return AdaptiveText(
      text: text,
      baseStyle: baseStyle,
      maxFontSize: isHorizontalLayout ? 16 : 14,
      minFontSize: isHorizontalLayout ? 12 : 10,
      maxLines: 1,
      textAlign: TextAlign.start,
    );
  }
}
