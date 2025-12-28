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
    // FE-UI-050: Use card-specific padding tokens
    final effectivePadding = padding ??
        const EdgeInsets.symmetric(
          horizontal: DesignTokens.paddingCardHorizontal,
          vertical: DesignTokens.paddingCardVertical,
        );
    final effectiveBorderRadius = borderRadius ?? DesignTokens.cardBorderRadius;
    final effectiveMargin = margin ?? EdgeInsets.zero;

    return Container(
      margin: effectiveMargin,
      decoration: BoxDecoration(
        borderRadius: effectiveBorderRadius,
        // FE-UI-048: Soft shadows (not heavy gray block)
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(DesignTokens.shadowOuterOpacity),
                  blurRadius: DesignTokens.shadowOuterBlur,
                  offset: const Offset(0, 8),
                  spreadRadius: DesignTokens.shadowOuterSpread,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(DesignTokens.shadowInnerOpacity),
                  blurRadius: DesignTokens.shadowInnerBlur,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: effectiveBorderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            // FE-UI-048: Real blur sigma 16 (web-optimized)
            sigmaX: blurStrength,
            sigmaY: blurStrength,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: effectiveBorderRadius,
              // FE-UI-048: Outer border - white 14-18%
              border: Border.all(
                color: Colors.white.withOpacity(DesignTokens.glassBorderOpacity),
                width: 1,
              ),
              // FE-UI-048: Glass fill with vertical gradient (top brighter)
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(DesignTokens.glassFillOpacityFocus),
                  Colors.white.withOpacity(DesignTokens.glassFillOpacity),
                ],
              ),
            ),
            child: Stack(
              children: [
                // FE-UI-048: Inner highlight rim (top edge stronger)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white.withOpacity(DesignTokens.glassHighlightOpacity),
                          Colors.white.withOpacity(DesignTokens.glassHighlightOpacity * 0.5),
                          Colors.white.withOpacity(DesignTokens.glassHighlightOpacity),
                        ],
                      ),
                    ),
                  ),
                ),
                // FE-UI-048: Optional subtle specular sheen (diagonal)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: effectiveBorderRadius,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.04),
                            Colors.transparent,
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.3, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                // Content
                Column(
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
                        color: Colors.white.withOpacity(0.12),
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
    final effectivePadding = padding ??
        const EdgeInsets.symmetric(horizontal: 12, vertical: 6);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: effectivePadding,
        decoration: BoxDecoration(
          // FE-UI-046: Use design tokens for consistent glass look
          color: isSelected
              ? DesignTokens.accentPrimary.withOpacity(0.20)
              : Colors.white.withOpacity(DesignTokens.glassFillOpacity),
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
          border: Border.all(
            color: isSelected
                ? DesignTokens.accentPrimary.withOpacity(0.50)
                : Colors.white.withOpacity(DesignTokens.glassBorderOpacity),
            width: 1,
          ),
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
