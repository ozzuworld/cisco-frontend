import 'dart:async';
import 'package:flutter/material.dart';
import '../models/background_preset.dart';
import '../models/background_preset_registry.dart';
import 'storage_service.dart';

/// Hemisphere for season calculation
enum Hemisphere { northern, southern }

/// Background mode - auto or manual
enum BackgroundMode { auto, manual }

/// Service that manages background presets with automatic time-of-day and season resolution
class BackgroundService extends ChangeNotifier {
  final StorageService _storageService;

  // State
  BackgroundMode _mode = BackgroundMode.auto;
  BackgroundPreset? _manualPreset;
  String? _sessionOverride;
  Hemisphere _hemisphere = Hemisphere.northern;

  // Crossfade state
  BackgroundPreset? _previousPreset;
  BackgroundPreset? _currentPreset;
  double _transitionProgress = 1.0;
  Timer? _transitionTimer;
  Timer? _autoUpdateTimer;

  // Snow settings (Epic 2)
  double _snowIntensity = 0.0; // 0.0 = Off, 0.33 = Low, 0.66 = Medium, 1.0 = High

  // Debug overrides
  BackgroundTimeOfDay? _debugTimeOfDay;
  Season? _debugSeason;

  BackgroundService(this._storageService) {
    _initialize();
  }

  // Getters
  BackgroundMode get mode => _mode;
  BackgroundPreset? get manualPreset => _manualPreset;
  String? get sessionOverride => _sessionOverride;
  Hemisphere get hemisphere => _hemisphere;
  BackgroundTimeOfDay? get debugTimeOfDay => _debugTimeOfDay;
  Season? get debugSeason => _debugSeason;
  double get snowIntensity => _snowIntensity;
  double get transitionProgress => _transitionProgress;

  /// Get the currently active preset (with transition if applicable)
  BackgroundPreset get activePreset {
    // If crossfade is in progress, lerp between presets
    if (_transitionProgress < 1.0 && _previousPreset != null && _currentPreset != null) {
      return BackgroundPreset.lerp(_previousPreset!, _currentPreset!, _transitionProgress);
    }
    return _currentPreset ?? BackgroundPresetRegistry.day;
  }

  /// Initialize the service
  Future<void> _initialize() async {
    await _loadPreferences();
    _updateCurrentPreset();

    // Start auto-update timer (check every minute for time-of-day changes)
    _autoUpdateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_mode == BackgroundMode.auto) {
        _updateCurrentPreset();
      }
    });
  }

  /// Load preferences from storage
  Future<void> _loadPreferences() async {
    try {
      final modeStr = await _storageService.read('background_mode');
      if (modeStr == 'manual') {
        _mode = BackgroundMode.manual;
      }

      final presetId = await _storageService.read('background_manual_preset');
      if (presetId != null) {
        _manualPreset = BackgroundPresetRegistry.getById(presetId);
      }

      final sessionOverrideId = await _storageService.read('background_session_override');
      if (sessionOverrideId != null) {
        _sessionOverride = sessionOverrideId;
      }

      final hemisphereStr = await _storageService.read('background_hemisphere');
      if (hemisphereStr == 'southern') {
        _hemisphere = Hemisphere.southern;
      }

      final snowStr = await _storageService.read('background_snow_intensity');
      if (snowStr != null) {
        _snowIntensity = double.tryParse(snowStr) ?? 0.0;
      }
    } catch (e) {
      debugPrint('Error loading background preferences: $e');
    }
  }

  /// Save preferences to storage
  Future<void> _savePreferences() async {
    try {
      await _storageService.write(
        'background_mode',
        _mode == BackgroundMode.auto ? 'auto' : 'manual',
      );

      if (_manualPreset != null) {
        await _storageService.write('background_manual_preset', _manualPreset!.id);
      }

      if (_sessionOverride != null) {
        await _storageService.write('background_session_override', _sessionOverride!);
      }

      await _storageService.write(
        'background_hemisphere',
        _hemisphere == Hemisphere.northern ? 'northern' : 'southern',
      );

      await _storageService.write('background_snow_intensity', _snowIntensity.toString());
    } catch (e) {
      debugPrint('Error saving background preferences: $e');
    }
  }

  /// Update the current preset based on mode and context
  void _updateCurrentPreset() {
    BackgroundPreset newPreset;

    // Priority 1: Session override (e.g., "holiday mode")
    if (_sessionOverride != null) {
      newPreset = BackgroundPresetRegistry.getById(_sessionOverride!) ?? _resolveAutoPreset();
    }
    // Priority 2: Manual mode
    else if (_mode == BackgroundMode.manual && _manualPreset != null) {
      newPreset = _manualPreset!;
    }
    // Priority 3: Auto mode
    else {
      newPreset = _resolveAutoPreset();
    }

    // Only trigger transition if preset actually changed
    if (_currentPreset?.id != newPreset.id) {
      _startTransition(newPreset);
    }
  }

  /// Resolve automatic preset based on time and season
  BackgroundPreset _resolveAutoPreset() {
    // For auto mode, prefer season over time-of-day for richer visuals
    // But if debug overrides are set, use those
    if (_debugSeason != null) {
      return BackgroundPresetRegistry.bySeason[_debugSeason]!;
    } else if (_debugTimeOfDay != null) {
      return BackgroundPresetRegistry.byTimeOfDay[_debugTimeOfDay]!;
    }

    // Determine current season
    final season = _getCurrentSeason();

    // Auto-enable low snow in winter if not manually set
    if (season == Season.winter && _snowIntensity == 0.0) {
      _snowIntensity = 0.33; // Low intensity
    }

    return BackgroundPresetRegistry.bySeason[season]!;
  }

  /// Get current season based on date and hemisphere
  Season _getCurrentSeason() {
    final now = DateTime.now();
    final month = now.month;
    final day = now.day;

    // Northern hemisphere seasons
    if (_hemisphere == Hemisphere.northern) {
      if ((month == 3 && day >= 20) || (month > 3 && month < 6) || (month == 6 && day < 21)) {
        return Season.spring; // Mar 20 - Jun 20
      } else if ((month == 6 && day >= 21) || (month > 6 && month < 9) || (month == 9 && day < 23)) {
        return Season.summer; // Jun 21 - Sep 22
      } else if ((month == 9 && day >= 23) || (month > 9 && month < 12) || (month == 12 && day < 21)) {
        return Season.fall; // Sep 23 - Dec 20
      } else {
        return Season.winter; // Dec 21 - Mar 19
      }
    }
    // Southern hemisphere (seasons are reversed)
    else {
      if ((month == 3 && day >= 20) || (month > 3 && month < 6) || (month == 6 && day < 21)) {
        return Season.fall;
      } else if ((month == 6 && day >= 21) || (month > 6 && month < 9) || (month == 9 && day < 23)) {
        return Season.winter;
      } else if ((month == 9 && day >= 23) || (month > 9 && month < 12) || (month == 12 && day < 21)) {
        return Season.spring;
      } else {
        return Season.summer;
      }
    }
  }

  /// Get current time of day
  BackgroundTimeOfDay _getCurrentTimeOfDay() {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour >= 5 && hour < 8) {
      return BackgroundTimeOfDay.dawn; // 5am - 8am
    } else if (hour >= 8 && hour < 17) {
      return BackgroundTimeOfDay.day; // 8am - 5pm
    } else if (hour >= 17 && hour < 20) {
      return BackgroundTimeOfDay.dusk; // 5pm - 8pm
    } else {
      return BackgroundTimeOfDay.night; // 8pm - 5am
    }
  }

  /// Start a smooth crossfade transition to a new preset
  void _startTransition(BackgroundPreset newPreset, {Duration duration = const Duration(milliseconds: 800)}) {
    _previousPreset = _currentPreset;
    _currentPreset = newPreset;
    _transitionProgress = 0.0;

    _transitionTimer?.cancel();

    const frameDuration = Duration(milliseconds: 16); // ~60fps
    final totalFrames = duration.inMilliseconds / frameDuration.inMilliseconds;
    var currentFrame = 0.0;

    _transitionTimer = Timer.periodic(frameDuration, (timer) {
      currentFrame++;
      _transitionProgress = (currentFrame / totalFrames).clamp(0.0, 1.0);

      // Apply easing curve for smooth transition
      final easedProgress = _easeInOutCubic(_transitionProgress);
      _transitionProgress = easedProgress;

      notifyListeners();

      if (_transitionProgress >= 1.0) {
        timer.cancel();
        _previousPreset = null;
      }
    });

    notifyListeners();
  }

  /// Easing function for smooth transitions
  double _easeInOutCubic(double t) {
    return t < 0.5 ? 4 * t * t * t : 1 - ((-2 * t + 2) * (-2 * t + 2) * (-2 * t + 2)) / 2;
  }

  // Public API

  /// Set background mode (auto or manual)
  Future<void> setMode(BackgroundMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    await _savePreferences();
    _updateCurrentPreset();
    notifyListeners();
  }

  /// Set manual preset (switches to manual mode)
  Future<void> setManualPreset(BackgroundPreset preset) async {
    _manualPreset = preset;
    _mode = BackgroundMode.manual;
    await _savePreferences();
    _updateCurrentPreset();
    notifyListeners();
  }

  /// Set manual preset by ID
  Future<void> setManualPresetById(String presetId) async {
    final preset = BackgroundPresetRegistry.getById(presetId);
    if (preset != null) {
      await setManualPreset(preset);
    }
  }

  /// Set session override (e.g., "holiday mode")
  Future<void> setSessionOverride(String? presetId) async {
    _sessionOverride = presetId;
    await _savePreferences();
    _updateCurrentPreset();
    notifyListeners();
  }

  /// Set hemisphere for season calculation
  Future<void> setHemisphere(Hemisphere hemisphere) async {
    if (_hemisphere == hemisphere) return;
    _hemisphere = hemisphere;
    await _savePreferences();
    if (_mode == BackgroundMode.auto) {
      _updateCurrentPreset();
    }
    notifyListeners();
  }

  /// Set snow intensity (0.0 = Off, 0.33 = Low, 0.66 = Medium, 1.0 = High)
  Future<void> setSnowIntensity(double intensity) async {
    _snowIntensity = intensity.clamp(0.0, 1.0);
    await _savePreferences();
    notifyListeners();
  }

  /// Reset to auto mode
  Future<void> resetToAuto() async {
    _mode = BackgroundMode.auto;
    _manualPreset = null;
    _sessionOverride = null;
    await _savePreferences();
    _updateCurrentPreset();
    notifyListeners();
  }

  // Debug methods

  /// Force a specific time of day (debug only)
  void setDebugTimeOfDay(BackgroundTimeOfDay? timeOfDay) {
    _debugTimeOfDay = timeOfDay;
    _debugSeason = null; // Clear season override
    if (_mode == BackgroundMode.auto) {
      _updateCurrentPreset();
    }
    notifyListeners();
  }

  /// Force a specific season (debug only)
  void setDebugSeason(Season? season) {
    _debugSeason = season;
    _debugTimeOfDay = null; // Clear time override
    if (_mode == BackgroundMode.auto) {
      _updateCurrentPreset();
    }
    notifyListeners();
  }

  /// Clear all debug overrides
  void clearDebugOverrides() {
    _debugTimeOfDay = null;
    _debugSeason = null;
    if (_mode == BackgroundMode.auto) {
      _updateCurrentPreset();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _transitionTimer?.cancel();
    _autoUpdateTimer?.cancel();
    super.dispose();
  }
}
