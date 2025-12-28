import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:lottie/lottie.dart';
import '../models/background_preset.dart';

/// FE-BG-100-106: Lottie-based weather effects for seasonal backgrounds
/// Renders weather animations (snow, rain, leaves, petals) behind glass cards
class WeatherEffect extends StatefulWidget {
  final Season? season;
  final double intensity; // 0.0 = Off, 0.33 = Low, 0.66 = Medium, 1.0 = High
  final double timeOfDayOpacity; // FE-BG-103: Day=1.0, Night=0.7-0.8
  final bool enabled; // FE-BG-106: Debug toggle
  final bool enablePerformanceMode; // FE-BG-105: Performance enforcement

  const WeatherEffect({
    super.key,
    this.season,
    this.intensity = 0.33,
    this.timeOfDayOpacity = 1.0,
    this.enabled = true,
    this.enablePerformanceMode = false,
  });

  @override
  State<WeatherEffect> createState() => _WeatherEffectState();
}

class _WeatherEffectState extends State<WeatherEffect>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;
  bool _isTabActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // FE-BG-105: Create animation controller for Lottie
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    if (widget.enabled && _shouldShowWeather()) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(WeatherEffect oldWidget) {
    super.didUpdateWidget(oldWidget);

    // FE-BG-102: React to season changes
    if (widget.season != oldWidget.season ||
        widget.enabled != oldWidget.enabled ||
        widget.intensity != oldWidget.intensity) {
      if (widget.enabled && _shouldShowWeather()) {
        if (!_controller.isAnimating) {
          _controller.repeat();
        }
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // FE-BG-105: Pause animation when tab inactive
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _isTabActive = false;
      _controller.stop();
    } else if (state == AppLifecycleState.resumed) {
      _isTabActive = true;
      if (widget.enabled && _shouldShowWeather()) {
        _controller.repeat();
      }
    }
  }

  /// FE-BG-102: Determine if weather should be shown based on season
  /// FE-REFACTOR-2: Enable all seasonal Lottie weather effects
  bool _shouldShowWeather() {
    if (widget.intensity == 0.0) return false;
    // Enable weather effects for winter (snow), spring (petals), and fall (leaves)
    return widget.season == Season.winter ||
           widget.season == Season.spring ||
           widget.season == Season.fall;
  }

  /// Get the appropriate Lottie asset path based on season
  String? _getWeatherAssetPath() {
    switch (widget.season) {
      case Season.winter:
        return 'assets/lottie/weather_snow.json';
      case Season.fall:
        return 'assets/lottie/weather_leaves.json';
      case Season.spring:
        return 'assets/lottie/weather_petals.json';
      case Season.summer:
        return null; // No weather effect for summer
      case null:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || !_shouldShowWeather()) {
      return const SizedBox.shrink();
    }

    final assetPath = _getWeatherAssetPath();
    if (assetPath == null) {
      return const SizedBox.shrink();
    }

    // FE-BG-103: Calculate final opacity based on time of day and intensity
    final baseOpacity = widget.intensity.clamp(0.0, 1.0);
    final finalOpacity = baseOpacity * widget.timeOfDayOpacity;

    // FE-BG-101: Positioned.fill renders behind glass, above gradient
    // FE-BG-104: Rendered OUTSIDE BackdropFilter to avoid blur/grey fog
    return Positioned.fill(
      child: IgnorePointer(
        // FE-BG-101: Must not affect input interaction
        child: Opacity(
          opacity: finalOpacity,
          child: Lottie.asset(
            assetPath,
            controller: _controller,
            fit: BoxFit.cover,
            // FE-BG-105: Performance mode reduces quality slightly
            frameRate: widget.enablePerformanceMode
                ? FrameRate.composition
                : FrameRate.max,
            // FE-BG-104: Sharp rendering, no blur
            filterQuality: FilterQuality.high,
            // FE-BG-101: No clipping
            repeat: true,
            // FE-BG-105: Error handling
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Weather effect error: $error');
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }
}

/// FE-BG-103: Helper to calculate time-of-day opacity
class WeatherOpacityHelper {
  /// Calculate opacity based on time of day
  /// Day: 100%, Night: 70-80%, Dawn/Dusk: interpolated
  static double getTimeOfDayOpacity(BackgroundTimeOfDay? timeOfDay) {
    switch (timeOfDay) {
      case BackgroundTimeOfDay.day:
        return 1.0; // 100%
      case BackgroundTimeOfDay.night:
        return 0.75; // 75%
      case BackgroundTimeOfDay.dawn:
        return 0.85; // 85% (transitioning to day)
      case BackgroundTimeOfDay.dusk:
        return 0.85; // 85% (transitioning to night)
      case null:
        return 1.0; // Default to full opacity
    }
  }
}
