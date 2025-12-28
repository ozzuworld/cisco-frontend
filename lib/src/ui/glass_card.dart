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
  /// FE-043: Default reduced to 16 for compact design
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
    // FE-043: Reduced default padding from 24 to 16
    final effectivePadding = padding ?? const EdgeInsets.all(16);
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

/// FE-042 & FE-044: Breadcrumb-style chip without blur (text-first, neutral)
class BreadcrumbChip extends StatelessWidget {
  final Widget child;
  final bool isSelected;
  final bool isCompleted;
  final VoidCallback? onTap;
  final EdgeInsets? padding;

  const BreadcrumbChip({
    super.key,
    required this.child,
    this.isSelected = false,
    this.isCompleted = false,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    // FE-043: Compact padding
    final effectivePadding = padding ??
        const EdgeInsets.symmetric(horizontal: 12, vertical: 6);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: effectivePadding,
        decoration: BoxDecoration(
          // FE-041 & FE-044: Neutral colors, no accent unless selected
          color: isSelected
              ? DesignTokens.accentColor.shade50
              : Colors.grey.shade100.withOpacity(0.6),
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
          border: isSelected
              ? Border.all(
                  color: DesignTokens.accentColor.shade300,
                  width: 1.5,
                )
              : null,
        ),
        child: child,
      ),
    );
  }
}

/// Legacy GlassChip - kept for backwards compatibility
/// FE-042: Not used in new design, glass effect limited to main card
@Deprecated('Use BreadcrumbChip instead')
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
    return BreadcrumbChip(
      isSelected: isSelected,
      onTap: onTap,
      padding: padding,
      child: child,
    );
  }
}
