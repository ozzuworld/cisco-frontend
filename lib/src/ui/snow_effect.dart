import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// A single snowflake particle
class _Snowflake {
  double x;
  double y;
  final double radius;
  final double speed;
  final double sway;
  final double swaySpeed;
  final double opacity;
  double swayOffset;

  _Snowflake({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.sway,
    required this.swaySpeed,
    required this.opacity,
    this.swayOffset = 0.0,
  });
}

/// Performance-safe snow particle system
/// Targets 60fps with configurable intensity
class SnowEffect extends StatefulWidget {
  final double intensity; // 0.0 = Off, 0.33 = Low, 0.66 = Medium, 1.0 = High
  final EdgeInsets safeArea; // Areas to avoid (e.g., buttons, key UI)

  const SnowEffect({
    super.key,
    this.intensity = 0.33,
    this.safeArea = EdgeInsets.zero,
  });

  @override
  State<SnowEffect> createState() => _SnowEffectState();
}

class _SnowEffectState extends State<SnowEffect> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final List<_Snowflake> _snowflakes = [];
  Duration _lastElapsed = Duration.zero;
  final math.Random _random = math.Random();

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
      _updateParticleCount();
    }
  }

  void _tick(Duration elapsed) {
    if (!mounted) return;

    final delta = (elapsed - _lastElapsed).inMilliseconds / 1000.0;
    _lastElapsed = elapsed;

    setState(() {
      _updateSnowflakes(delta);
    });
  }

  void _updateParticleCount() {
    final targetCount = _getTargetParticleCount();

    // Add or remove particles to match target
    while (_snowflakes.length < targetCount) {
      _addSnowflake();
    }
    while (_snowflakes.length > targetCount) {
      _snowflakes.removeLast();
    }
  }

  int _getTargetParticleCount() {
    if (widget.intensity == 0.0) return 0;
    if (widget.intensity <= 0.33) return 50; // Low
    if (widget.intensity <= 0.66) return 100; // Medium
    return 150; // High
  }

  void _addSnowflake({double? startY}) {
    final context = this.context;
    if (!context.mounted) return;

    final size = MediaQuery.of(context).size;

    // Vary snowflake properties for natural look
    final radius = 1.0 + _random.nextDouble() * 2.5; // 1-3.5px
    final speed = 20.0 + _random.nextDouble() * 40.0; // 20-60 px/s
    final sway = 15.0 + _random.nextDouble() * 25.0; // 15-40px sway amplitude
    final swaySpeed = 0.5 + _random.nextDouble() * 1.5; // 0.5-2.0 rad/s
    final opacity = 0.3 + _random.nextDouble() * 0.5; // 0.3-0.8 opacity

    _snowflakes.add(_Snowflake(
      x: _random.nextDouble() * size.width,
      y: startY ?? -10.0,
      radius: radius,
      speed: speed,
      sway: sway,
      swaySpeed: swaySpeed,
      opacity: opacity,
      swayOffset: _random.nextDouble() * 2 * math.pi,
    ));
  }

  void _updateSnowflakes(double delta) {
    if (_snowflakes.isEmpty && widget.intensity > 0.0) {
      _updateParticleCount();
    }

    final context = this.context;
    if (!context.mounted) return;

    final size = MediaQuery.of(context).size;

    for (var i = 0; i < _snowflakes.length; i++) {
      final flake = _snowflakes[i];

      // Update position
      flake.y += flake.speed * delta;
      flake.swayOffset += flake.swaySpeed * delta;
      flake.x += math.sin(flake.swayOffset) * flake.sway * delta;

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
    if (widget.intensity == 0.0 || _snowflakes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _SnowPainter(
            snowflakes: _snowflakes,
            safeArea: widget.safeArea,
          ),
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

/// Painter for snow particles
class _SnowPainter extends CustomPainter {
  final List<_Snowflake> snowflakes;
  final EdgeInsets safeArea;

  _SnowPainter({
    required this.snowflakes,
    required this.safeArea,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final flake in snowflakes) {
      // Skip if in safe area
      if (_isInSafeArea(flake, size)) {
        continue;
      }

      final paint = Paint()
        ..color = Colors.white.withOpacity(flake.opacity)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0); // Soft edges

      canvas.drawCircle(
        Offset(flake.x, flake.y),
        flake.radius,
        paint,
      );
    }
  }

  bool _isInSafeArea(_Snowflake flake, Size size) {
    // Check if snowflake is within safe area margins
    if (flake.x < safeArea.left) return false;
    if (flake.x > size.width - safeArea.right) return false;
    if (flake.y < safeArea.top) return false;
    if (flake.y > size.height - safeArea.bottom) return false;

    // If all checks pass, it's in the safe area (should be skipped)
    return safeArea.left > 0 || safeArea.right > 0 || safeArea.top > 0 || safeArea.bottom > 0;
  }

  @override
  bool shouldRepaint(covariant _SnowPainter oldDelegate) {
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
