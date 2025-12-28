import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Snow depth layer for parallax effect
enum SnowLayer { far, mid, near }

/// FE-BG-P100: Premium snowflake with depth and lighting
class _PremiumSnowflake {
  double x;
  double y;
  final double radius;
  final double baseSpeed;
  final double sway;
  final double swaySpeed;
  final double opacity;
  final SnowLayer layer;
  final double blur; // FE-BG-P103: DOF blur amount
  final double lightingAngle; // FE-BG-P101: Lighting direction
  double swayOffset;

  // FE-BG-P102: Turbulence state
  double turbulencePhase;
  double driftPhase;

  _PremiumSnowflake({
    required this.x,
    required this.y,
    required this.radius,
    required this.baseSpeed,
    required this.sway,
    required this.swaySpeed,
    required this.opacity,
    required this.layer,
    required this.blur,
    required this.lightingAngle,
    this.swayOffset = 0.0,
    this.turbulencePhase = 0.0,
    this.driftPhase = 0.0,
  });
}

/// FE-BG-P107: Performance monitoring
class _PerformanceMonitor {
  final List<double> _frameTimes = [];
  static const int _sampleSize = 60; // Track last 60 frames

  void recordFrameTime(double deltaMs) {
    _frameTimes.add(deltaMs);
    if (_frameTimes.length > _sampleSize) {
      _frameTimes.removeAt(0);
    }
  }

  double get averageFrameTime {
    if (_frameTimes.isEmpty) return 0.0;
    return _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
  }

  double get fps => averageFrameTime > 0 ? 1000.0 / averageFrameTime : 60.0;

  bool get shouldDegrade => fps < 55.0; // Below 55fps, start degrading
}

/// FE-BG-P100-P104: Premium cinematic snow effect
/// Multi-layer depth, soft lighting, organic motion, DOF
class SnowEffect extends StatefulWidget {
  final double intensity; // 0.0 = Off, 0.33 = Low, 0.66 = Medium, 1.0 = High
  final EdgeInsets safeArea;
  final bool enablePremiumEffects; // FE-BG-P106: Quality toggle

  const SnowEffect({
    super.key,
    this.intensity = 0.33,
    this.safeArea = EdgeInsets.zero,
    this.enablePremiumEffects = true,
  });

  @override
  State<SnowEffect> createState() => _SnowEffectState();
}

class _SnowEffectState extends State<SnowEffect> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final Map<SnowLayer, List<_PremiumSnowflake>> _snowflakesByLayer = {
    SnowLayer.far: [],
    SnowLayer.mid: [],
    SnowLayer.near: [],
  };

  Duration _lastElapsed = Duration.zero;
  final math.Random _random = math.Random();
  final _PerformanceMonitor _perfMonitor = _PerformanceMonitor();

  // FE-BG-P102: Wind and turbulence state
  double _windPhase = 0.0;
  double _windStrength = 0.0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    _ticker.start();
  }

  @override
  void didUpdateWidget(SnowEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.intensity != oldWidget.intensity) {
      _updateParticleCounts();
    }
  }

  void _tick(Duration elapsed) {
    if (!mounted) return;

    final delta = (elapsed - _lastElapsed).inMilliseconds / 1000.0;
    _lastElapsed = elapsed;

    // FE-BG-P107: Performance monitoring
    _perfMonitor.recordFrameTime(delta * 1000.0);

    setState(() {
      _updateWindAndTurbulence(delta);
      _updateAllSnowflakes(delta);
    });
  }

  /// FE-BG-P102: Update wind and turbulence
  void _updateWindAndTurbulence(double delta) {
    _windPhase += delta * 0.3; // Slow wind oscillation
    _windStrength = math.sin(_windPhase) * 15.0; // ±15px drift
  }

  void _updateParticleCounts() {
    final baseCounts = _getBaseParticleCounts();

    // FE-BG-P107: Auto-degrade if performance is poor
    final degradeFactor = _perfMonitor.shouldDegrade ? 0.6 : 1.0;

    for (final layer in SnowLayer.values) {
      final targetCount = (baseCounts[layer]! * degradeFactor).round();
      final currentList = _snowflakesByLayer[layer]!;

      while (currentList.length < targetCount) {
        _addSnowflake(layer);
      }
      while (currentList.length > targetCount) {
        currentList.removeLast();
      }
    }
  }

  /// FE-BG-P100: Layer-based particle distribution
  Map<SnowLayer, int> _getBaseParticleCounts() {
    if (widget.intensity == 0.0) {
      return {SnowLayer.far: 0, SnowLayer.mid: 0, SnowLayer.near: 0};
    }

    final totalParticles = widget.intensity <= 0.33
        ? 80 // Low
        : widget.intensity <= 0.66
            ? 150 // Medium
            : 220; // High

    // FE-BG-P100: Layer distribution (more far, fewer near for depth)
    return {
      SnowLayer.far: (totalParticles * 0.50).round(), // 50% far
      SnowLayer.mid: (totalParticles * 0.35).round(), // 35% mid
      SnowLayer.near: (totalParticles * 0.15).round(), // 15% near
    };
  }

  /// FE-BG-P100: Add snowflake with layer-specific properties
  void _addSnowflake(SnowLayer layer, {double? startY}) {
    final context = this.context;
    if (!context.mounted) return;

    final size = MediaQuery.of(context).size;

    // FE-BG-P100: Layer-specific properties for depth
    late double radius, baseSpeed, opacity, blur;

    switch (layer) {
      case SnowLayer.far:
        radius = 0.5 + _random.nextDouble() * 1.0; // 0.5-1.5px (tiny)
        baseSpeed = 10.0 + _random.nextDouble() * 15.0; // 10-25 px/s (slow)
        opacity = 0.15 + _random.nextDouble() * 0.20; // 0.15-0.35 (faint)
        blur = 0.0; // Sharp
        break;

      case SnowLayer.mid:
        radius = 1.0 + _random.nextDouble() * 2.0; // 1-3px (medium)
        baseSpeed = 25.0 + _random.nextDouble() * 25.0; // 25-50 px/s (medium)
        opacity = 0.35 + _random.nextDouble() * 0.30; // 0.35-0.65 (visible)
        blur = 0.5; // Slight blur
        break;

      case SnowLayer.near:
        // FE-BG-P103: Near layer with DOF blur
        radius = 2.5 + _random.nextDouble() * 3.5; // 2.5-6px (large)
        baseSpeed = 50.0 + _random.nextDouble() * 40.0; // 50-90 px/s (fast)
        opacity = 0.45 + _random.nextDouble() * 0.40; // 0.45-0.85 (bright)
        blur = widget.enablePremiumEffects ? 1.5 : 0.5; // DOF blur
        break;
    }

    final sway = 20.0 + _random.nextDouble() * 30.0; // 20-50px sway
    final swaySpeed = 0.4 + _random.nextDouble() * 1.2; // 0.4-1.6 rad/s

    // FE-BG-P101: Lighting angle (top-left bias to match glass)
    final lightingAngle = -math.pi / 4 + (_random.nextDouble() - 0.5) * 0.3; // ~-45° ± variation

    _snowflakesByLayer[layer]!.add(_PremiumSnowflake(
      x: _random.nextDouble() * size.width,
      y: startY ?? -10.0,
      radius: radius,
      baseSpeed: baseSpeed,
      sway: sway,
      swaySpeed: swaySpeed,
      opacity: opacity,
      layer: layer,
      blur: blur,
      lightingAngle: lightingAngle,
      swayOffset: _random.nextDouble() * 2 * math.pi,
      turbulencePhase: _random.nextDouble() * 2 * math.pi,
      driftPhase: _random.nextDouble() * 2 * math.pi,
    ));
  }

  void _updateAllSnowflakes(double delta) {
    for (final layer in SnowLayer.values) {
      final flakes = _snowflakesByLayer[layer]!;

      if (flakes.isEmpty && widget.intensity > 0.0) {
        _updateParticleCounts();
      }

      _updateSnowflakesInLayer(flakes, delta);
    }
  }

  /// FE-BG-P102: Update snowflakes with organic motion
  void _updateSnowflakesInLayer(List<_PremiumSnowflake> flakes, double delta) {
    final context = this.context;
    if (!context.mounted) return;

    final size = MediaQuery.of(context).size;

    for (var flake in flakes) {
      // Base sway motion
      flake.swayOffset += flake.swaySpeed * delta;
      final swayX = math.sin(flake.swayOffset) * flake.sway * delta;

      // FE-BG-P102: Add wind drift
      final windDrift = _windStrength * delta;

      // FE-BG-P102: Add micro-turbulence (high-frequency jitter)
      flake.turbulencePhase += delta * 3.0; // Fast oscillation
      final turbulenceX = math.sin(flake.turbulencePhase) * 2.0 * delta;
      final turbulenceY = math.cos(flake.turbulencePhase * 1.3) * 1.5 * delta;

      // FE-BG-P102: Combine all motion components
      flake.x += swayX + windDrift + turbulenceX;
      flake.y += flake.baseSpeed * delta + turbulenceY;

      // Respawn at top when it falls off bottom
      if (flake.y > size.height + 10) {
        flake.y = -10.0;
        flake.x = _random.nextDouble() * size.width;
      }

      // Wrap around sides
      if (flake.x < -10) {
        flake.x = size.width + 10;
      } else if (flake.x > size.width + 10) {
        flake.x = -10;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.intensity == 0.0) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // FE-BG-P100: Render layers back-to-front for proper depth
            ...[SnowLayer.far, SnowLayer.mid, SnowLayer.near].map(
              (layer) => Positioned.fill(
                child: CustomPaint(
                  painter: _PremiumSnowPainter(
                    snowflakes: _snowflakesByLayer[layer]!,
                    safeArea: widget.safeArea,
                    enablePremiumEffects: widget.enablePremiumEffects,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

/// FE-BG-P101: Premium snow painter with soft lighting
class _PremiumSnowPainter extends CustomPainter {
  final List<_PremiumSnowflake> snowflakes;
  final EdgeInsets safeArea;
  final bool enablePremiumEffects;

  _PremiumSnowPainter({
    required this.snowflakes,
    required this.safeArea,
    required this.enablePremiumEffects,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final flake in snowflakes) {
      if (_isInSafeArea(flake, size)) {
        continue;
      }

      // FE-BG-P101: Soft radial blob with lighting
      if (enablePremiumEffects) {
        _drawPremiumFlake(canvas, flake);
      } else {
        _drawBasicFlake(canvas, flake);
      }
    }
  }

  /// FE-BG-P101: Draw snowflake as soft luminous disc with highlight
  void _drawPremiumFlake(Canvas canvas, _PremiumSnowflake flake) {
    final center = Offset(flake.x, flake.y);

    // FE-BG-P101: Soft radial gradient (glow)
    final glowPaint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        flake.radius * 1.5,
        [
          Colors.white.withOpacity(flake.opacity * 0.9), // Bright center
          Colors.white.withOpacity(flake.opacity * 0.5), // Soft falloff
          Colors.transparent, // Fade to nothing
        ],
        [0.0, 0.6, 1.0],
      )
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, flake.blur);

    canvas.drawCircle(center, flake.radius * 1.5, glowPaint);

    // FE-BG-P101: Add subtle highlight (top-left bias)
    final highlightOffset = Offset(
      center.dx + math.cos(flake.lightingAngle) * flake.radius * 0.3,
      center.dy + math.sin(flake.lightingAngle) * flake.radius * 0.3,
    );

    final highlightPaint = Paint()
      ..shader = ui.Gradient.radial(
        highlightOffset,
        flake.radius * 0.5,
        [
          Colors.white.withOpacity(flake.opacity * 0.4), // Bright spot
          Colors.transparent,
        ],
        [0.0, 1.0],
      )
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, flake.blur * 0.5);

    canvas.drawCircle(highlightOffset, flake.radius * 0.6, highlightPaint);
  }

  /// Basic rendering for performance mode
  void _drawBasicFlake(Canvas canvas, _PremiumSnowflake flake) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(flake.opacity)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, flake.blur.clamp(0.5, 1.5));

    canvas.drawCircle(
      Offset(flake.x, flake.y),
      flake.radius,
      paint,
    );
  }

  bool _isInSafeArea(_PremiumSnowflake flake, Size size) {
    if (flake.x < safeArea.left) return false;
    if (flake.x > size.width - safeArea.right) return false;
    if (flake.y < safeArea.top) return false;
    if (flake.y > size.height - safeArea.bottom) return false;

    return safeArea.left > 0 || safeArea.right > 0 || safeArea.top > 0 || safeArea.bottom > 0;
  }

  @override
  bool shouldRepaint(covariant _PremiumSnowPainter oldDelegate) {
    return true; // Always repaint for animation
  }
}

/// Extension methods for snow intensity
extension SnowIntensityExtension on double {
  String get snowIntensityLabel {
    if (this == 0.0) return 'Off';
    if (this <= 0.33) return 'Low';
    if (this <= 0.66) return 'Medium';
    return 'High';
  }
}
