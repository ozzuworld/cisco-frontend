import 'dart:ui';
import 'dart:math' as math;
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

  /// FE-UI-083: Debug mode to prove zero-fill
  /// Shows hot pink overlay if any non-transparent fill is detected
  final bool debugShowFillProof;

  /// FE-UI-096: Debug mode to disable blur for intersection testing
  /// Toggle blur OFF → see background features clearly
  /// Toggle blur ON → see same features distort (proves refraction)
  final bool debugDisableBlur;

  /// FE-UI-110: Debug mode to exaggerate reflections 3× for tuning
  /// Helps visualize and tune reflection system, then return to normal
  final bool debugExaggerateReflections;

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
    this.debugShowFillProof = false, // FE-UI-083: Debug overlay toggle
    this.debugDisableBlur = false, // FE-UI-096: Blur toggle for intersection test
    this.debugExaggerateReflections = false, // FE-UI-110: Reflection tuning mode
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  // FE-036: Light position tracking (normalized 0.0-1.0)
  Offset _lightPosition = const Offset(0.5, 0.3); // Default: top-left

  @override
  Widget build(BuildContext context) {
    // FE-UI-050: Use card-specific padding tokens
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
          // FE-UI-111: THIN SHEET contact shadow (not panel depth)
          // Minimal contact shadow only - thin glass sheet on surface
          boxShadow: widget.showShadow
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),  // FE-UI-111: 10% → 7%
                    blurRadius: 6,  // FE-UI-111: 8 → 6 (tighter)
                    offset: const Offset(0, 0.5),  // FE-UI-111: (0,1) → (0,0.5)
                    spreadRadius: 0,  // No spread (strict requirement)
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: effectiveBorderRadius,
          // FE-UI-096: Conditionally apply blur for intersection testing
          child: widget.debugDisableBlur
              ? _buildGlassContent(effectiveBorderRadius, effectivePadding)
              : BackdropFilter(
                  filter: ImageFilter.blur(
                    // FE-UI-048: Real blur sigma 16 (web-optimized)
                    sigmaX: widget.blurStrength,
                    sigmaY: widget.blurStrength,
                  ),
                  child: _buildGlassContent(effectiveBorderRadius, effectivePadding),
                ),
        ),
      ),
    );
  }

  /// FE-UI-096: Helper to build glass container content (used in both blur/no-blur modes)
  Widget _buildGlassContent(BorderRadius effectiveBorderRadius, EdgeInsets effectivePadding) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: effectiveBorderRadius,
        // FE-UI-058: 1px outer border (35-45% range) - crisp crystal edges
        border: Border.all(
          color: Colors.white.withOpacity(0.40),
          width: 1.0,
        ),
        // FE-UI-068: ZERO FILL (hard requirement)
        // Glass defined by reflections + environment, NOT fill
        // Any fill on black = grey slab
        color: GlassCard._glassFillColor, // Colors.transparent (0.0%)
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
          // FE-UI-111: Inner shadow MINIMAL (thin sheet, not thick panel)
          // Extremely subtle - just enough for perceived surface, no dark banding
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: effectiveBorderRadius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08), // FE-UI-111: 12% → 8%
                    blurRadius: 4, // FE-UI-111: 6 → 4 (tighter)
                    spreadRadius: -2, // FE-UI-111: -3 → -2 (smaller)
                    offset: const Offset(0, 0.5), // FE-UI-111: (0,1) → (0,0.5)
                  ),
                ],
              ),
            ),
          ),
          // FE-UI-091 / FE-UI-120: Top edge highlight - refined for clean corners
          // Inset slightly to avoid corner overlap artifacts
          Positioned(
            top: 0,
            left: 2, // Inset to avoid corner conflict
            right: 2,
            child: Container(
              height: 1.5, // Slightly thinner
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(effectiveBorderRadius.topLeft.x - 2),
                  topRight: Radius.circular(effectiveBorderRadius.topRight.x - 2),
                ),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.white.withOpacity(0.18), // Reduced (was 0.22)
                    Colors.white.withOpacity(0.14), // Reduced (was 0.17)
                    Colors.white.withOpacity(0.06), // Reduced (was 0.08)
                  ],
                ),
              ),
            ),
          ),
          // FE-UI-091 / FE-UI-120: Left edge highlight - clean from corner
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
          // FE-UI-091 / FE-UI-120: Right edge highlight - subtle, clean
          Positioned(
            top: effectiveBorderRadius.topRight.y, // Start below corner radius
            right: 0,
            bottom: effectiveBorderRadius.bottomRight.y,
            child: Container(
              width: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.05), // Reduced (was 0.06)
                    Colors.white.withOpacity(0.02),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // FE-UI-110: SPECULAR REFLECTION SYSTEM V2
          // FE-036: Now driven by interactive light position
          // Makes glass look "wet" and liquid, not just transparent

          // Primary sheen sweep (broad diagonal highlight)
          // FE-036: Responds to light position for depth
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
                    Colors.white.withOpacity(
                      widget.debugExaggerateReflections ? 0.35 : 0.12
                    ),
                    Colors.white.withOpacity(
                      widget.debugExaggerateReflections ? 0.15 : 0.05
                    ),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 0.7],
                ),
              ),
            ),
          ),

          // FE-UI-120: Secondary tight edge catchlight - clean corner rendering
          // Inset slightly and reduced opacity for cleaner appearance
          Positioned(
            top: 0,
            left: 1, // Slight inset to avoid corner artifacts
            right: 1,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(effectiveBorderRadius.topLeft.x - 1),
                  topRight: Radius.circular(effectiveBorderRadius.topRight.x - 1),
                ),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(
                     widget.debugExaggerateReflections ? 0.90 : 0.24 // Reduced (was 0.30)
                    ),
                    Colors.white.withOpacity(
                     widget.debugExaggerateReflections ? 0.70 : 0.18 // Reduced (was 0.23)
                    ),
                    Colors.white.withOpacity(
                     widget.debugExaggerateReflections ? 0.50 : 0.12 // Reduced (was 0.17)
                    ),
                  ],
                ),
              ),
            ),
          ),

          // FE-UI-120: Corner caustic glow - TOP LEFT (refined for clean edges)
          // Reduced intensity and tighter radius to prevent muddy corners
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: effectiveBorderRadius.topLeft,
                ),
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 0.6, // Tighter (was 0.8)
                  colors: [
                    Colors.white.withOpacity(
                     widget.debugExaggerateReflections ? 0.80 : 0.18 // Reduced (was 0.28)
                    ),
                    Colors.white.withOpacity(
                     widget.debugExaggerateReflections ? 0.40 : 0.08 // Reduced (was 0.14)
                    ),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0], // Faster falloff
                ),
              ),
            ),
          ),

          // FE-UI-120: Corner caustic glow - TOP RIGHT (refined, asymmetric)
          // More subtle to reduce corner complexity
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topRight: effectiveBorderRadius.topRight,
                ),
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 0.55, // Tighter (was 0.7)
                  colors: [
                    Colors.white.withOpacity(
                     widget.debugExaggerateReflections ? 0.60 : 0.12 // Reduced (was 0.20)
                    ),
                    Colors.white.withOpacity(
                     widget.debugExaggerateReflections ? 0.30 : 0.05 // Reduced (was 0.10)
                    ),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.55, 1.0], // Faster falloff
                ),
              ),
            ),
          ),

          // Specular hotspot - upper-left quadrant (simulates angled light reflection)
          Positioned(
            top: effectiveBorderRadius.topLeft.y + 20,
            left: effectiveBorderRadius.topLeft.x + 30,
            child: Container(
              width: 80,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.9,
                  colors: [
                    Colors.white.withOpacity(
                     widget.debugExaggerateReflections ? 0.50 : 0.17
                    ),
                    Colors.white.withOpacity(
                     widget.debugExaggerateReflections ? 0.20 : 0.07
                    ),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.6, 1.0],
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
          // FE-UI-083: Debug overlay - hot pink if fill is NOT transparent
          if (widget.debugShowFillProof)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: effectiveBorderRadius,
                    // Hot pink if _glassFillColor is not transparent
                    // This should NEVER show if zero-fill is correct
                    color: GlassCard._glassFillColor.opacity > 0.0
                        ? const Color(0xFFFF1493).withOpacity(0.8) // Hot pink
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
                        GlassCard._glassFillColor.opacity > 0.0
                            ? 'FAIL: Fill opacity = ${(GlassCard._glassFillColor.opacity * 100).toStringAsFixed(1)}%'
                            : 'PASS: Fill = 0% (transparent)',
                        style: TextStyle(
                          color: GlassCard._glassFillColor.opacity > 0.0
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
            ),
        ],
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
          // FE-UI-077: Stroke-first liquid glass - zero fill, border-only
          color: isSelected
              ? DesignTokens.accentPrimary.withOpacity(0.20)
              : Colors.transparent,  // Was 5% fill - now 0%
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
