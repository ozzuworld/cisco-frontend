import 'package:flutter/material.dart';
import 'background_preset.dart';

/// Registry of all available background presets
class BackgroundPresetRegistry {
  BackgroundPresetRegistry._();

  // Time-of-day presets
  static final BackgroundPreset dawn = BackgroundPreset(
    id: 'dawn',
    name: 'Dawn',
    timeOfDay: TimeOfDay.dawn,
    baseColor: const Color(0xFF0A0D15),
    blooms: [
      // Soft orange-pink sunrise bloom
      BackgroundBloom(
        alignment: const Alignment(-0.3, -0.5),
        radius: 1.5,
        colors: [
          const Color(0xFFFF9E80).withOpacity(0.18),
          const Color(0xFFFFB74D).withOpacity(0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ),
      // Soft purple-blue bloom
      BackgroundBloom(
        alignment: const Alignment(0.5, 0.3),
        radius: 1.2,
        colors: [
          const Color(0xFF9FA8DA).withOpacity(0.14),
          const Color(0xFF7986CB).withOpacity(0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
      // Gentle white highlight
      BackgroundBloom(
        alignment: const Alignment(-0.7, 0.2),
        radius: 1.0,
        colors: [
          Colors.white.withOpacity(0.10),
          Colors.white.withOpacity(0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      ),
    ],
    bands: [
      BackgroundBand(
        begin: const Alignment(-1.5, -0.8),
        end: const Alignment(1.5, 0.8),
        colors: [
          Colors.transparent,
          const Color(0xFFFFAB91).withOpacity(0.10),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
    ],
  );

  static final BackgroundPreset day = BackgroundPreset(
    id: 'day',
    name: 'Day',
    timeOfDay: TimeOfDay.day,
    baseColor: const Color(0xFF05060A),
    blooms: [
      // Primary blue-white bloom
      BackgroundBloom(
        alignment: const Alignment(0.3, -0.4),
        radius: 1.5,
        colors: [
          const Color(0xFFBBDEFB).withOpacity(0.22),
          const Color(0xFF90CAF9).withOpacity(0.14),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
      // Secondary purple bloom
      BackgroundBloom(
        alignment: const Alignment(-0.5, 0.6),
        radius: 1.3,
        colors: [
          const Color(0xFFB39DDB).withOpacity(0.18),
          const Color(0xFF9575CD).withOpacity(0.10),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
      // Tertiary white-blue bloom
      BackgroundBloom(
        alignment: const Alignment(0.7, 0.5),
        radius: 1.2,
        colors: [
          Colors.white.withOpacity(0.20),
          const Color(0xFF64B5F6).withOpacity(0.10),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      ),
    ],
    bands: [
      BackgroundBand(
        begin: const Alignment(-1.2, -0.9),
        end: const Alignment(1.2, 0.9),
        colors: [
          Colors.transparent,
          const Color(0xFF81D4FA).withOpacity(0.14),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
    ],
  );

  static final BackgroundPreset dusk = BackgroundPreset(
    id: 'dusk',
    name: 'Dusk',
    timeOfDay: TimeOfDay.dusk,
    baseColor: const Color(0xFF0D0A0F),
    blooms: [
      // Deep orange-red sunset bloom
      BackgroundBloom(
        alignment: const Alignment(0.4, -0.6),
        radius: 1.4,
        colors: [
          const Color(0xFFFF7043).withOpacity(0.20),
          const Color(0xFFFF8A65).withOpacity(0.14),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ),
      // Purple twilight bloom
      BackgroundBloom(
        alignment: const Alignment(-0.6, 0.4),
        radius: 1.3,
        colors: [
          const Color(0xFF9C27B0).withOpacity(0.16),
          const Color(0xFFBA68C8).withOpacity(0.10),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
      // Deep blue night approaching
      BackgroundBloom(
        alignment: const Alignment(0.2, 0.7),
        radius: 1.1,
        colors: [
          const Color(0xFF3F51B5).withOpacity(0.14),
          const Color(0xFF5C6BC0).withOpacity(0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      ),
    ],
    bands: [
      BackgroundBand(
        begin: const Alignment(-1.3, -1.0),
        end: const Alignment(1.3, 1.0),
        colors: [
          Colors.transparent,
          const Color(0xFFFF6E40).withOpacity(0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
    ],
  );

  static final BackgroundPreset night = BackgroundPreset(
    id: 'night',
    name: 'Night',
    timeOfDay: TimeOfDay.night,
    baseColor: const Color(0xFF020305),
    blooms: [
      // Deep blue-purple bloom
      BackgroundBloom(
        alignment: const Alignment(-0.2, -0.3),
        radius: 1.3,
        colors: [
          const Color(0xFF3F51B5).withOpacity(0.16),
          const Color(0xFF283593).withOpacity(0.10),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
      // Subtle indigo bloom
      BackgroundBloom(
        alignment: const Alignment(0.5, 0.4),
        radius: 1.2,
        colors: [
          const Color(0xFF5C6BC0).withOpacity(0.12),
          const Color(0xFF3949AB).withOpacity(0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      ),
      // Faint white starlight
      BackgroundBloom(
        alignment: const Alignment(-0.6, 0.6),
        radius: 0.9,
        colors: [
          Colors.white.withOpacity(0.08),
          Colors.white.withOpacity(0.03),
          Colors.transparent,
        ],
        stops: const [0.0, 0.7, 1.0],
      ),
    ],
    bands: [
      BackgroundBand(
        begin: const Alignment(-1.0, -1.1),
        end: const Alignment(1.0, 1.1),
        colors: [
          Colors.transparent,
          const Color(0xFF1A237E).withOpacity(0.10),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
    ],
    vignetteOpacity: 0.15,
  );

  // Seasonal presets
  static final BackgroundPreset spring = BackgroundPreset(
    id: 'spring',
    name: 'Spring',
    season: Season.spring,
    baseColor: const Color(0xFF080A10),
    blooms: [
      // Fresh green bloom
      BackgroundBloom(
        alignment: const Alignment(-0.4, -0.5),
        radius: 1.4,
        colors: [
          const Color(0xFF81C784).withOpacity(0.18),
          const Color(0xFF66BB6A).withOpacity(0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
      // Soft pink cherry blossom
      BackgroundBloom(
        alignment: const Alignment(0.5, 0.3),
        radius: 1.2,
        colors: [
          const Color(0xFFF48FB1).withOpacity(0.16),
          const Color(0xFFEC407A).withOpacity(0.10),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
      // Light sky blue
      BackgroundBloom(
        alignment: const Alignment(0.1, 0.7),
        radius: 1.1,
        colors: [
          const Color(0xFF4FC3F7).withOpacity(0.14),
          const Color(0xFF29B6F6).withOpacity(0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      ),
    ],
    bands: [
      BackgroundBand(
        begin: const Alignment(-1.4, -0.7),
        end: const Alignment(1.4, 0.7),
        colors: [
          Colors.transparent,
          const Color(0xFF4DB6AC).withOpacity(0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
    ],
  );

  static final BackgroundPreset summer = BackgroundPreset(
    id: 'summer',
    name: 'Summer',
    season: Season.summer,
    baseColor: const Color(0xFF060810),
    blooms: [
      // Bright yellow-gold sun
      BackgroundBloom(
        alignment: const Alignment(0.3, -0.6),
        radius: 1.5,
        colors: [
          const Color(0xFFFFD54F).withOpacity(0.20),
          const Color(0xFFFFCA28).withOpacity(0.14),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ),
      // Warm orange bloom
      BackgroundBloom(
        alignment: const Alignment(-0.5, 0.3),
        radius: 1.3,
        colors: [
          const Color(0xFFFFB74D).withOpacity(0.18),
          const Color(0xFFFFA726).withOpacity(0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
      // Vibrant cyan sky
      BackgroundBloom(
        alignment: const Alignment(0.6, 0.6),
        radius: 1.2,
        colors: [
          const Color(0xFF26C6DA).withOpacity(0.16),
          const Color(0xFF00BCD4).withOpacity(0.10),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      ),
    ],
    bands: [
      BackgroundBand(
        begin: const Alignment(-1.1, -1.0),
        end: const Alignment(1.1, 1.0),
        colors: [
          Colors.transparent,
          const Color(0xFFFFC107).withOpacity(0.14),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
    ],
  );

  static final BackgroundPreset fall = BackgroundPreset(
    id: 'fall',
    name: 'Fall',
    season: Season.fall,
    baseColor: const Color(0xFF0A0806),
    blooms: [
      // Deep orange autumn
      BackgroundBloom(
        alignment: const Alignment(-0.3, -0.4),
        radius: 1.4,
        colors: [
          const Color(0xFFFF8A65).withOpacity(0.20),
          const Color(0xFFFF7043).withOpacity(0.14),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ),
      // Rich amber
      BackgroundBloom(
        alignment: const Alignment(0.5, 0.2),
        radius: 1.3,
        colors: [
          const Color(0xFFFFB74D).withOpacity(0.18),
          const Color(0xFFFFA726).withOpacity(0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
      // Rusty red
      BackgroundBloom(
        alignment: const Alignment(-0.2, 0.7),
        radius: 1.1,
        colors: [
          const Color(0xFFE57373).withOpacity(0.16),
          const Color(0xFFEF5350).withOpacity(0.10),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      ),
    ],
    bands: [
      BackgroundBand(
        begin: const Alignment(-1.3, -0.8),
        end: const Alignment(1.3, 0.8),
        colors: [
          Colors.transparent,
          const Color(0xFFD84315).withOpacity(0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
    ],
  );

  static final BackgroundPreset winter = BackgroundPreset(
    id: 'winter',
    name: 'Winter',
    season: Season.winter,
    baseColor: const Color(0xFF08090C),
    blooms: [
      // Cool blue ice
      BackgroundBloom(
        alignment: const Alignment(0.2, -0.5),
        radius: 1.4,
        colors: [
          const Color(0xFF64B5F6).withOpacity(0.18),
          const Color(0xFF42A5F5).withOpacity(0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
      // Frosty white
      BackgroundBloom(
        alignment: const Alignment(-0.5, 0.3),
        radius: 1.2,
        colors: [
          Colors.white.withOpacity(0.16),
          const Color(0xFFE3F2FD).withOpacity(0.10),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
      // Icy cyan
      BackgroundBloom(
        alignment: const Alignment(0.4, 0.6),
        radius: 1.1,
        colors: [
          const Color(0xFF4DD0E1).withOpacity(0.14),
          const Color(0xFF26C6DA).withOpacity(0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      ),
    ],
    bands: [
      BackgroundBand(
        begin: const Alignment(-1.2, -0.9),
        end: const Alignment(1.2, 0.9),
        colors: [
          Colors.transparent,
          const Color(0xFF80DEEA).withOpacity(0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
    ],
  );

  /// Get all presets as a map
  static Map<String, BackgroundPreset> get all => {
        dawn.id: dawn,
        day.id: day,
        dusk.id: dusk,
        night.id: night,
        spring.id: spring,
        summer.id: summer,
        fall.id: fall,
        winter.id: winter,
      };

  /// Get presets by time of day
  static Map<TimeOfDay, BackgroundPreset> get byTimeOfDay => {
        TimeOfDay.dawn: dawn,
        TimeOfDay.day: day,
        TimeOfDay.dusk: dusk,
        TimeOfDay.night: night,
      };

  /// Get presets by season
  static Map<Season, BackgroundPreset> get bySeason => {
        Season.spring: spring,
        Season.summer: summer,
        Season.fall: fall,
        Season.winter: winter,
      };

  /// Get a preset by ID
  static BackgroundPreset? getById(String id) => all[id];
}
