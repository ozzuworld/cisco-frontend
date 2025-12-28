import 'dart:ui';
import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// FE-037: Reusable GlassCard component with glass morphism effect
///
/// Features:
/// - Blur effect behind the card (glass effect)
/// - Translucent fill with semi-transparent background
/// - Subtle border for definition
/// - Soft shadow for depth
/// - Optional header and body slots for flexible content
/// - Optimized for Flutter Web performance
class GlassCard extends StatelessWidget {
  /// Optional header widget (typically used for titles or status)
  final Widget? header;

  /// Main body content
  final Widget body;

  /// Background blur strength (sigma value for blur)
  /// Higher values = more blur. Default: 10.0
  final double blurStrength;

  /// Background color opacity (0.0 to 1.0)
  /// Lower values = more transparent. Default: 0.15
  final double backgroundOpacity;

  /// Border color opacity (0.0 to 1.0)
  /// Default: 0.2
  final double borderOpacity;

  /// Custom padding for the card content
  /// Default: EdgeInsets.all(24)
  final EdgeInsets? padding;

  /// Custom border radius
  /// Default: DesignTokens.radiusCard
  final BorderRadius? borderRadius;

  /// Whether to show the shadow
  /// Default: true
  final bool showShadow;

  /// Custom margin around the card
  /// Default: EdgeInsets.zero
  final EdgeInsets? margin;

  const GlassCard({
    super.key,
    this.header,
    required this.body,
    this.blurStrength = 10.0,
    this.backgroundOpacity = 0.15,
    this.borderOpacity = 0.2,
    this.padding,
    this.borderRadius,
    this.showShadow = true,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? const EdgeInsets.all(24);
    final effectiveBorderRadius = borderRadius ?? DesignTokens.cardBorderRadius;
    final effectiveMargin = margin ?? EdgeInsets.zero;

    return Container(
      margin: effectiveMargin,
      decoration: BoxDecoration(
        borderRadius: effectiveBorderRadius,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: effectiveBorderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurStrength,
            sigmaY: blurStrength,
          ),
          child: Container(
            decoration: BoxDecoration(
              // Semi-transparent white background for glass effect
              color: Colors.white.withOpacity(backgroundOpacity),
              borderRadius: effectiveBorderRadius,
              border: Border.all(
                color: Colors.white.withOpacity(borderOpacity),
                width: 1.5,
              ),
              // Gradient overlay for enhanced glass effect
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(backgroundOpacity * 1.2),
                  Colors.white.withOpacity(backgroundOpacity * 0.8),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (header != null) ...[
                  Padding(
                    padding: EdgeInsets.only(
                      left: effectivePadding.left,
                      right: effectivePadding.right,
                      top: effectivePadding.top,
                      bottom: DesignTokens.spacingComponent,
                    ),
                    child: header!,
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.black.withOpacity(0.08),
                  ),
                  SizedBox(height: effectivePadding.bottom),
                ],
                Padding(
                  padding: header != null
                      ? EdgeInsets.only(
                          left: effectivePadding.left,
                          right: effectivePadding.right,
                          bottom: effectivePadding.bottom,
                        )
                      : effectivePadding,
                  child: body,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact variant of GlassCard for smaller UI elements like chips
class GlassChip extends StatelessWidget {
  final Widget child;
  final bool isSelected;
  final VoidCallback? onTap;
  final EdgeInsets? padding;

  const GlassChip({
    super.key,
    required this.child,
    this.isSelected = false,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ??
        const EdgeInsets.symmetric(horizontal: 16, vertical: 10);

    return InkWell(
      onTap: onTap,
      borderRadius: DesignTokens.chipBorderRadius,
      child: ClipRRect(
        borderRadius: DesignTokens.chipBorderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: effectivePadding,
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.blue.withOpacity(0.25)
                  : Colors.white.withOpacity(0.12),
              borderRadius: DesignTokens.chipBorderRadius,
              border: Border.all(
                color: isSelected
                    ? Colors.blue.withOpacity(0.4)
                    : Colors.white.withOpacity(0.2),
                width: isSelected ? 2 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isSelected ? 0.12 : 0.06),
                  blurRadius: isSelected ? 12 : 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
