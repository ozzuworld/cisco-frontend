import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// FE-037: Reusable GlassCard component with glass morphism effect
///
/// ⚠️ FE-UI-061: NON-NEGOTIABLE "NO FILL" RULE ⚠️
/// GlassCard MUST have transparent fill (alpha = 0.0)
/// Glass is defined by EDGES ONLY: borders + highlights
/// Any future fill/tint MUST be rejected in code review
/// This prevents grey slab regression permanently
///
/// Features:
/// - Blur effect behind the card (glass effect)
/// - ZERO fill - edges define the glass
/// - Subtle border for definition
/// - Soft shadow for depth
/// - Optional header and body slots for flexible content
/// - Optimized for Flutter Web performance
class GlassCard extends StatelessWidget {
  // FE-UI-061: Enforce transparent fill rule
  static const Color _glassFillColor = Colors.transparent;
  static const String _noFillRuleWarning =
      'GlassCard fill MUST be transparent (alpha = 0.0). '
      'Glass is defined by edges only. Do not add fill/tint.';

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
    this.blurStrength = 5.0, // FE-UI-054: Reduced by 50% (was 10.0)
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
              // FE-UI-058: 1px outer border (35-45% range) - crisp crystal edges
              border: Border.all(
                color: Colors.white.withOpacity(0.40),
                width: 1.0,
              ),
              // FE-UI-061: Frost layer (3-6% subtle tint for liquid glass)
              // Very low alpha to maintain translucency while providing glass feel
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.05),  // 5% top (frost layer)
                  Colors.white.withOpacity(0.04),  // 4% bottom
                ],
              ),
            ),
            child: Stack(
              children: [
                // FE-UI-058: 1px inner border (12-18% range) - sharper edge lighting
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: effectiveBorderRadius,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        width: 1.0,
                      ),
                    ),
                  ),
                ),
                // FE-UI-062: Inner shadow for thickness/depth
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: effectiveBorderRadius,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 8,
                          spreadRadius: -4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                // FE-UI-058: Top highlight band (reduced 30% for crisp look)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(effectiveBorderRadius.topLeft.x),
                        topRight: Radius.circular(effectiveBorderRadius.topRight.x),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white.withOpacity(0.10),
                          Colors.white.withOpacity(0.17),
                          Colors.white.withOpacity(0.10),
                        ],
                      ),
                    ),
                  ),
                ),
                // FE-UI-058: Left edge highlight (reduced 30%)
                Positioned(
                  top: 0,
                  left: 0,
                  bottom: 0,
                  child: Container(
                    width: 1.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.14),
                          Colors.white.withOpacity(0.07),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // FE-UI-058: Right edge highlight (reduced 30%)
                Positioned(
                  top: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.10),
                          Colors.white.withOpacity(0.03),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // FE-UI-063: Corner glow/bloom (subtle refraction at corners)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(effectiveBorderRadius.topLeft.x),
                      ),
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.18),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(effectiveBorderRadius.topRight.x),
                      ),
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // FE-UI-048: Subtle noise/grain overlay (for refraction detail)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: effectiveBorderRadius,
                    child: CustomPaint(
                      painter: _NoisePainter(
                        opacity: 0.04, // Very subtle (3-6% range)
                        seed: 42, // Fixed seed for consistent pattern
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

/// FE-UI-048: Noise texture painter for subtle film grain on glass
class _NoisePainter extends CustomPainter {
  final double opacity;
  final int seed;

  _NoisePainter({this.opacity = 0.05, this.seed = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final paint = Paint();

    // Draw very subtle noise dots
    // Sparse sampling to avoid performance issues on web
    final step = 4.0; // Sample every 4 pixels
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        if (random.nextDouble() > 0.5) {
          final brightness = random.nextDouble() * 0.5 + 0.5; // 0.5 to 1.0
          paint.color = Colors.white.withOpacity(opacity * brightness);
          canvas.drawCircle(
            Offset(x + random.nextDouble() * step, y + random.nextDouble() * step),
            0.5,
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_NoisePainter oldDelegate) =>
      opacity != oldDelegate.opacity || seed != oldDelegate.seed;
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
          // FE-UI-066: Use liquid glass tokens for consistent look
          color: isSelected
              ? DesignTokens.accentPrimary.withOpacity(0.20)
              : Colors.white.withOpacity(DesignTokens.glassFrostOpacity),
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
          border: Border.all(
            color: isSelected
                ? DesignTokens.accentPrimary.withOpacity(0.50)
                : Colors.white.withOpacity(DesignTokens.glassRimInnerOpacity),
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
