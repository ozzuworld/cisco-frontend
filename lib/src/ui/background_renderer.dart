import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/background_preset.dart';

/// Renders a background preset with blooms, bands, noise, and vignette
class BackgroundRenderer extends StatelessWidget {
  final BackgroundPreset preset;
  final bool enabled;

  const BackgroundRenderer({
    super.key,
    required this.preset,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return Container(color: preset.baseColor);
    }

    return Container(
      color: preset.baseColor,
      child: Stack(
        children: [
          // Large blooms
          ...preset.blooms.map((bloom) => _buildBloom(bloom)),

          // Diagonal gradient bands
          ...preset.bands.map((band) => _buildBand(band)),

          // Background noise
          Positioned.fill(
            child: CustomPaint(
              painter: _BackgroundNoisePainter(
                opacity: preset.noiseConfig.opacity,
                dotRadius: preset.noiseConfig.dotRadius,
                samplingGrid: preset.noiseConfig.samplingGrid,
                drawProbability: preset.noiseConfig.drawProbability,
                randomSeed: preset.noiseConfig.randomSeed,
              ),
            ),
          ),

          // Micro vignette
          if (preset.vignetteOpacity > 0)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.0,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(preset.vignetteOpacity),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBloom(BackgroundBloom bloom) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: bloom.alignment,
            radius: bloom.radius,
            colors: bloom.colors,
            stops: bloom.stops,
          ),
        ),
      ),
    );
  }

  Widget _buildBand(BackgroundBand band) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: band.begin,
            end: band.end,
            colors: band.colors,
            stops: band.stops,
          ),
        ),
      ),
    );
  }
}

/// Painter for background noise texture
class _BackgroundNoisePainter extends CustomPainter {
  final double opacity;
  final double dotRadius;
  final double samplingGrid;
  final double drawProbability;
  final int randomSeed;

  _BackgroundNoisePainter({
    required this.opacity,
    required this.dotRadius,
    required this.samplingGrid,
    required this.drawProbability,
    required this.randomSeed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    final random = math.Random(randomSeed);

    for (double x = 0; x < size.width; x += samplingGrid) {
      for (double y = 0; y < size.height; y += samplingGrid) {
        if (random.nextDouble() <= drawProbability) {
          canvas.drawCircle(
            Offset(x, y),
            dotRadius,
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundNoisePainter oldDelegate) {
    return oldDelegate.opacity != opacity ||
        oldDelegate.dotRadius != dotRadius ||
        oldDelegate.samplingGrid != samplingGrid ||
        oldDelegate.drawProbability != drawProbability ||
        oldDelegate.randomSeed != randomSeed;
  }
}
