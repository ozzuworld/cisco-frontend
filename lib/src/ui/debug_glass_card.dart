import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'glass_card.dart';
import 'design_tokens.dart';

/// FE-REFACTOR-8: Debug wrapper for GlassCard with testing/tuning features
///
/// This wrapper provides debug-only features for glass card development:
/// - debugShowFillProof: Hot pink overlay if fill is not transparent
/// - debugDisableBlur: Toggle blur to test background intersection
/// - debugExaggerateReflections: 3x reflection opacity for tuning
///
/// Only available in kDebugMode. In production, use GlassCard directly.
class DebugGlassCard extends StatelessWidget {
  /// Optional header widget
  final Widget? header;

  /// Main body content
  final Widget body;

  /// Background blur strength
  final double blurStrength;

  /// Background color opacity
  final double backgroundOpacity;

  /// Border color opacity
  final double borderOpacity;

  /// Custom padding
  final EdgeInsets? padding;

  /// Custom border radius
  final BorderRadius? borderRadius;

  /// Whether to show shadow
  final bool showShadow;

  /// Custom margin
  final EdgeInsets? margin;

  /// FE-UI-083: Show hot pink overlay if fill is not transparent
  final bool debugShowFillProof;

  /// FE-UI-096: Disable blur to test background intersection
  final bool debugDisableBlur;

  /// FE-UI-110: Exaggerate reflections 3x for tuning
  final bool debugExaggerateReflections;

  const DebugGlassCard({
    super.key,
    this.header,
    required this.body,
    this.blurStrength = 5.0,
    this.backgroundOpacity = 0.15,
    this.borderOpacity = 0.2,
    this.padding,
    this.borderRadius,
    this.showShadow = true,
    this.margin,
    this.debugShowFillProof = false,
    this.debugDisableBlur = false,
    this.debugExaggerateReflections = false,
  });

  @override
  Widget build(BuildContext context) {
    // In production, debug features are disabled
    if (!kDebugMode) {
      return GlassCard(
        header: header,
        body: body,
        blurStrength: blurStrength,
        backgroundOpacity: backgroundOpacity,
        borderOpacity: borderOpacity,
        padding: padding,
        borderRadius: borderRadius,
        showShadow: showShadow,
        margin: margin,
      );
    }

    // In debug mode, wrap with debug features
    return Stack(
      children: [
        GlassCard(
          header: header,
          body: body,
          blurStrength: debugDisableBlur ? 0 : blurStrength,
          backgroundOpacity: backgroundOpacity,
          borderOpacity: borderOpacity,
          padding: padding,
          borderRadius: borderRadius,
          showShadow: showShadow,
          margin: margin,
          reflectionMultiplier: debugExaggerateReflections ? 3.0 : 1.0,
        ),

        // FE-UI-083: Debug fill proof overlay
        if (debugShowFillProof)
          _buildFillProofOverlay(),
      ],
    );
  }

  /// FE-UI-083: Build the fill proof debug overlay
  Widget _buildFillProofOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          margin: margin ?? EdgeInsets.zero,
          decoration: BoxDecoration(
            borderRadius: borderRadius ?? DesignTokens.cardBorderRadius,
            // Hot pink if fill is detected (should never show)
            color: backgroundOpacity > 0.0
                ? const Color(0xFFFF1493).withOpacity(0.8)
                : Colors.transparent,
            border: Border.all(
              color: const Color(0xFF00FF00), // Green border = debug mode active
              width: 3,
            ),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black.withOpacity(0.8),
              child: Text(
                backgroundOpacity > 0.0
                    ? 'FAIL: Fill opacity = ${(backgroundOpacity * 100).toStringAsFixed(1)}%'
                    : 'PASS: Fill = 0% (transparent)',
                style: TextStyle(
                  color: backgroundOpacity > 0.0
                      ? const Color(0xFFFF1493)
                      : const Color(0xFF00FF00),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
