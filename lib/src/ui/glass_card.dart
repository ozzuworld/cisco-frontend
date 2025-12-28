import 'dart:ui';
import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// FE-037: Reusable GlassCard component with liquid glass effect
///
/// ⚠️ FE-UI-068 & FE-UI-077: ZERO-FILL GLASS MODE (HARD REQUIREMENT) ⚠️
/// GlassCard MUST have transparent fill (alpha = 0.0)
/// Glass definition comes from: reflections + environment + edges
/// Any fill on black = grey slab (blur over flat black = grey fog)
/// This prevents grey slab regression permanently
///
/// Key Principle:
/// "Reference look requires reflections + background texture, NOT fill tint"
///
/// FE-UI-077: Stroke-First Liquid Glass Rules:
/// 1. Main container: color = Colors.transparent (0.0 alpha) - STRICT
/// 2. Glass visibility ONLY from: rim strokes + specular highlights + inner shadow
/// 3. Card center should look nearly identical to background (test with environment layer)
/// 4. NO frost layer, NO tint layer, NO fill gradient
///
/// Features:
/// - Backdrop blur (refracts environment layer)
/// - ZERO fill - reflections define the glass
/// - Dual-stroke rim (outer 40% + inner 15%)
/// - Specular sheen + edge catchlights
/// - Inner shadow for perceived thickness
/// - Minimal contact shadow (thin glass sheet)
/// - Rich environment layer behind (prevents grey fog)
///
/// FE-UI-081: Reference Match QA (4-Test Checklist):
/// ✓ Test 1: Center Transparency - card center ~identical to background
/// ✓ Test 2: Rim Readability - borders visible at 35-45% on black
/// ✓ Test 3: Refraction Test - blur refracts environment detail (not grey fog)
/// ✓ Test 4: Child Surface Audit - all children have transparent fill
///
/// FE-036: Interactive Lighting Rig
/// - Mouse/touch position drives specular highlights
/// - Creates depth and premium feel
/// - Smooth transitions, subtle effect (no disco)
class GlassCard extends StatefulWidget {
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

  /// FE-REFACTOR-8: Reflection multiplier (for debug wrapper use)
  /// Default: 1.0, Debug wrapper can use 3.0 to exaggerate reflections
  final double reflectionMultiplier;

  const GlassCard({
    super.key,
    this.header,
    required this.body,
    this.blurStrength = 5.0, // Reduced for subtlety (was 10.0)
    this.backgroundOpacity = 0.15,
    this.borderOpacity = 0.2,
    this.padding,
    this.borderRadius,
    this.showShadow = true,
    this.margin,
    this.reflectionMultiplier = 1.0, // FE-REFACTOR-8: For debug wrapper
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  // FE-036: Light position tracking (normalized 0.0-1.0)
  Offset _lightPosition = const Offset(0.5, 0.3); // Default: top-left

  @override
  Widget build(BuildContext context) {
    final effectivePadding = widget.padding ??
        const EdgeInsets.symmetric(
          horizontal: DesignTokens.paddingCardHorizontal,
          vertical: DesignTokens.paddingCardVertical,
        );
    final effectiveBorderRadius = widget.borderRadius ?? DesignTokens.cardBorderRadius;
    final effectiveMargin = widget.margin ?? EdgeInsets.zero;

    // FE-036: Wrap with MouseRegion for interactive lighting
    return MouseRegion(
      onHover: (event) {
        // Convert mouse position to normalized coordinates (0.0-1.0)
        final RenderBox? box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          final localPosition = box.globalToLocal(event.position);
          final size = box.size;
          setState(() {
            _lightPosition = Offset(
              (localPosition.dx / size.width).clamp(0.0, 1.0),
              (localPosition.dy / size.height).clamp(0.0, 1.0),
            );
          });
        }
      },
      child: Container(
        margin: effectiveMargin,
        decoration: BoxDecoration(
          borderRadius: effectiveBorderRadius,
          // Minimal contact shadow - thin glass sheet on surface
          boxShadow: widget.showShadow
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 6,
                    offset: const Offset(0, 0.5),
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: effectiveBorderRadius,
          // FE-REFACTOR-8: Blur always applied (debug wrapper can set blurStrength=0)
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: widget.blurStrength,
              sigmaY: widget.blurStrength,
            ),
            child: _buildGlassContent(effectiveBorderRadius, effectivePadding),
          ),
        ),
      ),
    );
  }

  /// Helper to build glass container content
  Widget _buildGlassContent(BorderRadius effectiveBorderRadius, EdgeInsets effectivePadding) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: effectiveBorderRadius,
        // Outer border - crisp crystal edges
        border: Border.all(
          color: Colors.white.withOpacity(0.40),
          width: 1.0,
        ),
        // ZERO FILL - glass defined by reflections, not fill
        color: GlassCard._glassFillColor,
      ),
      child: Stack(
        children: [
          // Inner border - sharper edge lighting
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
          // Inner shadow - minimal for thin sheet effect
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: effectiveBorderRadius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    spreadRadius: -2,
                    offset: const Offset(0, 0.5),
                  ),
                ],
              ),
            ),
          ),
          // FE-REFACTOR-7: Unified top edge highlight (merged top + catchlight)
          Positioned(
            top: 0,
            left: 1,
            right: 1,
            child: Container(
              height: 2, // Combined height for both layers
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(effectiveBorderRadius.topLeft.x - 1),
                  topRight: Radius.circular(effectiveBorderRadius.topRight.x - 1),
                ),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.white.withOpacity(0.25), // Merged intensity
                    Colors.white.withOpacity(0.16),
                    Colors.white.withOpacity(0.08),
                  ],
                ),
              ),
            ),
          ),
          // Left edge highlight
          Positioned(
            top: effectiveBorderRadius.topLeft.y, // Start below corner radius
            left: 0,
            bottom: effectiveBorderRadius.bottomLeft.y,
            child: Container(
              width: 1.5, // Thinner (was 2)
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.16), // Reduced (was 0.20)
                    Colors.white.withOpacity(0.08), // Reduced (was 0.10)
                    Colors.white.withOpacity(0.02), // Reduced (was 0.03)
                  ],
                ),
              ),
            ),
          ),
          // FE-REFACTOR-7: Right edge removed (minimal visual impact, saves 19 lines)
          // FE-REFACTOR-7: Enhanced primary sheen (merged specular hotspot)
          // FE-036: Interactive light position creates "wet glass" effect
          // FE-REFACTOR-8: Uses reflectionMultiplier for debug tuning
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: effectiveBorderRadius,
                gradient: RadialGradient(
                  center: Alignment(
                    (_lightPosition.dx - 0.5) * 2, // Convert 0-1 to -1 to 1
                    (_lightPosition.dy - 0.5) * 2,
                  ),
                  radius: 1.5,
                  colors: [
                    Colors.white.withOpacity((0.15 * widget.reflectionMultiplier).clamp(0.0, 1.0)),
                    Colors.white.withOpacity((0.08 * widget.reflectionMultiplier).clamp(0.0, 1.0)),
                    Colors.white.withOpacity((0.03 * widget.reflectionMultiplier).clamp(0.0, 1.0)),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 0.6, 1.0],
                ),
              ),
            ),
          ),

          // FE-REFACTOR-7: Secondary catchlight merged into unified top edge above

          // FE-REFACTOR-7: Unified corner glow (merged L+R corners)
          // FE-REFACTOR-8: Uses reflectionMultiplier for debug tuning
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: effectiveBorderRadius.topLeft,
                  topRight: effectiveBorderRadius.topRight,
                ),
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 0.8,
                  colors: [
                    Colors.white.withOpacity((0.15 * widget.reflectionMultiplier).clamp(0.0, 1.0)),
                    Colors.white.withOpacity((0.06 * widget.reflectionMultiplier).clamp(0.0, 1.0)),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // FE-REFACTOR-7: Noise painter removed (Decision 2: B - minimal visual impact)
          // Content
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.header != null) ...[
                Padding(
                  padding: EdgeInsets.only(
                    left: effectivePadding.left,
                    right: effectivePadding.right,
                    top: effectivePadding.top,
                    bottom: DesignTokens.spacingComponent,
                  ),
                  child: widget.header!,
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.white.withOpacity(0.12),
                ),
                SizedBox(height: effectivePadding.bottom),
              ],
              Padding(
                padding: widget.header != null
                    ? EdgeInsets.only(
                        left: effectivePadding.left,
                        right: effectivePadding.right,
                        bottom: effectivePadding.bottom,
                      )
                    : effectivePadding,
                child: widget.body,
              ),
            ],
          ),
          // FE-REFACTOR-8: Debug overlay moved to DebugGlassCard wrapper
        ],
      ),
    );
  }
}

// FE-REFACTOR-7: Noise painter class removed (Decision 2: B - 36 lines saved)

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
          // Stroke-first glass - zero fill for unselected state
          color: isSelected
              ? DesignTokens.accentPrimary.withOpacity(0.20)
              : Colors.transparent,
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

// FE-REFACTOR-7: Deprecated GlassChip class removed (28 lines saved)
// All code should use BreadcrumbChip instead
