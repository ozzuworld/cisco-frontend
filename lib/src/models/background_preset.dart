import 'package:flutter/material.dart';

/// Represents a bloom gradient in the background
class BackgroundBloom {
  final Alignment alignment;
  final double radius;
  final List<Color> colors;
  final List<double> stops;

  const BackgroundBloom({
    required this.alignment,
    required this.radius,
    required this.colors,
    required this.stops,
  });

  BackgroundBloom copyWith({
    Alignment? alignment,
    double? radius,
    List<Color>? colors,
    List<double>? stops,
  }) {
    return BackgroundBloom(
      alignment: alignment ?? this.alignment,
      radius: radius ?? this.radius,
      colors: colors ?? this.colors,
      stops: stops ?? this.stops,
    );
  }
}

/// Represents a diagonal gradient band in the background
class BackgroundBand {
  final Alignment begin;
  final Alignment end;
  final List<Color> colors;
  final List<double> stops;

  const BackgroundBand({
    required this.begin,
    required this.end,
    required this.colors,
    required this.stops,
  });

  BackgroundBand copyWith({
    Alignment? begin,
    Alignment? end,
    List<Color>? colors,
    List<double>? stops,
  }) {
    return BackgroundBand(
      begin: begin ?? this.begin,
      end: end ?? this.end,
      colors: colors ?? this.colors,
      stops: stops ?? this.stops,
    );
  }
}

/// Configuration for background noise effect
class BackgroundNoiseConfig {
  final double opacity;
  final double dotRadius;
  final double samplingGrid;
  final double drawProbability;
  final int randomSeed;

  const BackgroundNoiseConfig({
    this.opacity = 0.04,
    this.dotRadius = 0.4,
    this.samplingGrid = 6.0,
    this.drawProbability = 0.4,
    this.randomSeed = 123,
  });

  BackgroundNoiseConfig copyWith({
    double? opacity,
    double? dotRadius,
    double? samplingGrid,
    double? drawProbability,
    int? randomSeed,
  }) {
    return BackgroundNoiseConfig(
      opacity: opacity ?? this.opacity,
      dotRadius: dotRadius ?? this.dotRadius,
      samplingGrid: samplingGrid ?? this.samplingGrid,
      drawProbability: drawProbability ?? this.drawProbability,
      randomSeed: randomSeed ?? this.randomSeed,
    );
  }
}

/// Enum for time of day (renamed to avoid conflict with Flutter's TimeOfDay)
enum BackgroundTimeOfDay {
  dawn,
  day,
  dusk,
  night,
}

/// Enum for seasons
enum Season {
  spring,
  summer,
  fall,
  winter,
}

/// Data-driven background preset configuration
class BackgroundPreset {
  final String id;
  final String name;
  final Color baseColor;
  final List<BackgroundBloom> blooms;
  final List<BackgroundBand> bands;
  final BackgroundNoiseConfig noiseConfig;
  final double vignetteOpacity;
  final BackgroundTimeOfDay? timeOfDay;
  final Season? season;

  const BackgroundPreset({
    required this.id,
    required this.name,
    required this.baseColor,
    required this.blooms,
    required this.bands,
    this.noiseConfig = const BackgroundNoiseConfig(),
    this.vignetteOpacity = 0.10,
    this.timeOfDay,
    this.season,
  });

  BackgroundPreset copyWith({
    String? id,
    String? name,
    Color? baseColor,
    List<BackgroundBloom>? blooms,
    List<BackgroundBand>? bands,
    BackgroundNoiseConfig? noiseConfig,
    double? vignetteOpacity,
    BackgroundTimeOfDay? timeOfDay,
    Season? season,
  }) {
    return BackgroundPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      baseColor: baseColor ?? this.baseColor,
      blooms: blooms ?? this.blooms,
      bands: bands ?? this.bands,
      noiseConfig: noiseConfig ?? this.noiseConfig,
      vignetteOpacity: vignetteOpacity ?? this.vignetteOpacity,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      season: season ?? this.season,
    );
  }

  /// Lerp between two presets for smooth transitions
  static BackgroundPreset lerp(BackgroundPreset a, BackgroundPreset b, double t) {
    // Lerp blooms (matching by index, pad with transparent if counts differ)
    final maxBlooms = a.blooms.length > b.blooms.length ? a.blooms.length : b.blooms.length;
    final lerpedBlooms = <BackgroundBloom>[];

    for (int i = 0; i < maxBlooms; i++) {
      final bloomA = i < a.blooms.length ? a.blooms[i] : _transparentBloom;
      final bloomB = i < b.blooms.length ? b.blooms[i] : _transparentBloom;

      lerpedBlooms.add(BackgroundBloom(
        alignment: Alignment.lerp(bloomA.alignment, bloomB.alignment, t)!,
        radius: bloomA.radius + (bloomB.radius - bloomA.radius) * t,
        colors: List.generate(
          bloomA.colors.length,
          (j) => Color.lerp(
            j < bloomA.colors.length ? bloomA.colors[j] : Colors.transparent,
            j < bloomB.colors.length ? bloomB.colors[j] : Colors.transparent,
            t,
          )!,
        ),
        stops: bloomA.stops,
      ));
    }

    // Lerp bands similarly
    final maxBands = a.bands.length > b.bands.length ? a.bands.length : b.bands.length;
    final lerpedBands = <BackgroundBand>[];

    for (int i = 0; i < maxBands; i++) {
      final bandA = i < a.bands.length ? a.bands[i] : _transparentBand;
      final bandB = i < b.bands.length ? b.bands[i] : _transparentBand;

      lerpedBands.add(BackgroundBand(
        begin: Alignment.lerp(bandA.begin, bandB.begin, t)!,
        end: Alignment.lerp(bandA.end, bandB.end, t)!,
        colors: List.generate(
          bandA.colors.length,
          (j) => Color.lerp(
            j < bandA.colors.length ? bandA.colors[j] : Colors.transparent,
            j < bandB.colors.length ? bandB.colors[j] : Colors.transparent,
            t,
          )!,
        ),
        stops: bandA.stops,
      ));
    }

    return BackgroundPreset(
      id: t < 0.5 ? a.id : b.id,
      name: t < 0.5 ? a.name : b.name,
      baseColor: Color.lerp(a.baseColor, b.baseColor, t)!,
      blooms: lerpedBlooms,
      bands: lerpedBands,
      noiseConfig: BackgroundNoiseConfig(
        opacity: a.noiseConfig.opacity + (b.noiseConfig.opacity - a.noiseConfig.opacity) * t,
        dotRadius: a.noiseConfig.dotRadius + (b.noiseConfig.dotRadius - a.noiseConfig.dotRadius) * t,
        samplingGrid: a.noiseConfig.samplingGrid + (b.noiseConfig.samplingGrid - a.noiseConfig.samplingGrid) * t,
        drawProbability: a.noiseConfig.drawProbability + (b.noiseConfig.drawProbability - a.noiseConfig.drawProbability) * t,
        randomSeed: t < 0.5 ? a.noiseConfig.randomSeed : b.noiseConfig.randomSeed,
      ),
      vignetteOpacity: a.vignetteOpacity + (b.vignetteOpacity - a.vignetteOpacity) * t,
      timeOfDay: t < 0.5 ? a.timeOfDay : b.timeOfDay,
      season: t < 0.5 ? a.season : b.season,
    );
  }

  static const _transparentBloom = BackgroundBloom(
    alignment: Alignment.center,
    radius: 1.0,
    colors: [Colors.transparent, Colors.transparent],
    stops: [0.0, 1.0],
  );

  static const _transparentBand = BackgroundBand(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.transparent, Colors.transparent],
    stops: [0.0, 1.0],
  );
}
