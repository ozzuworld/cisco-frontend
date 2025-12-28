import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// Adaptive readability overlay that ensures text/buttons remain readable
/// across all background presets without creating "muddy" overlays
class ReadabilityOverlay extends StatelessWidget {
  final Widget child;
  final bool enabled;
  final double minimumContrast; // WCAG AA = 4.5, AAA = 7.0
  final Color backgroundColor;
  final Color foregroundColor;

  const ReadabilityOverlay({
    super.key,
    required this.child,
    this.enabled = true,
    this.minimumContrast = 4.5, // WCAG AA for normal text
    this.backgroundColor = const Color(0xFF05060A),
    this.foregroundColor = const Color(0xFFEBEBEB),
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    // Calculate if overlay is needed based on contrast
    final needsOverlay = _calculateContrastRatio(backgroundColor, foregroundColor) < minimumContrast;

    if (!needsOverlay) {
      return child;
    }

    return Stack(
      children: [
        child,
        // Subtle adaptive vignette (only when needed)
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.15), // Very subtle
                  ],
                  stops: const [0.3, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Calculate WCAG contrast ratio between two colors
  /// Returns a value between 1 and 21
  double _calculateContrastRatio(Color bg, Color fg) {
    final bgLuminance = _relativeLuminance(bg);
    final fgLuminance = _relativeLuminance(fg);

    final lighter = bgLuminance > fgLuminance ? bgLuminance : fgLuminance;
    final darker = bgLuminance > fgLuminance ? fgLuminance : bgLuminance;

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Calculate relative luminance for contrast ratio
  double _relativeLuminance(Color color) {
    final r = _sRGBtoLinear(color.red / 255.0);
    final g = _sRGBtoLinear(color.green / 255.0);
    final b = _sRGBtoLinear(color.blue / 255.0);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  double _sRGBtoLinear(double value) {
    if (value <= 0.03928) {
      return value / 12.92;
    } else {
      return ((value + 0.055) / 1.055).pow(2.4);
    }
  }
}

/// Extension to add pow method to double
extension on double {
  double pow(double exponent) {
    return ui.math.pow(this, exponent).toDouble();
  }
}

/// Scrim overlay for specific UI elements that need guaranteed readability
class ReadabilityScrim extends StatelessWidget {
  final Widget child;
  final double opacity;
  final Color color;

  const ReadabilityScrim({
    super.key,
    required this.child,
    this.opacity = 0.08,
    this.color = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Subtle scrim behind content
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withOpacity(opacity * 0.5),
                  color.withOpacity(opacity),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Contrast checker utility
class ContrastChecker {
  /// Check if a color combination meets WCAG standards
  static bool meetsWCAGAA(Color bg, Color fg) {
    return _calculateContrastRatio(bg, fg) >= 4.5;
  }

  static bool meetsWCAGAAA(Color bg, Color fg) {
    return _calculateContrastRatio(bg, fg) >= 7.0;
  }

  static double getContrastRatio(Color bg, Color fg) {
    return _calculateContrastRatio(bg, fg);
  }

  static double _calculateContrastRatio(Color bg, Color fg) {
    final bgLuminance = _relativeLuminance(bg);
    final fgLuminance = _relativeLuminance(fg);

    final lighter = bgLuminance > fgLuminance ? bgLuminance : fgLuminance;
    final darker = bgLuminance > fgLuminance ? fgLuminance : bgLuminance;

    return (lighter + 0.05) / (darker + 0.05);
  }

  static double _relativeLuminance(Color color) {
    final r = _sRGBtoLinear(color.red / 255.0);
    final g = _sRGBtoLinear(color.green / 255.0);
    final b = _sRGBtoLinear(color.blue / 255.0);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double _sRGBtoLinear(double value) {
    if (value <= 0.03928) {
      return value / 12.92;
    } else {
      return ui.math.pow((value + 0.055) / 1.055, 2.4).toDouble();
    }
  }
}
