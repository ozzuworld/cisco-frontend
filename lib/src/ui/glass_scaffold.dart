import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/background_service.dart';
import 'background_renderer.dart';
import 'weather_effect.dart';
import 'design_tokens.dart';

/// FE-REFACTOR-13: Reusable scaffold that combines background + weather + content
///
/// This widget encapsulates the common pattern used across screens:
/// Stack → BackgroundRenderer → WeatherEffect → SafeArea → Content
///
/// Usage:
/// ```dart
/// GlassScaffold(
///   appBar: AppBar(title: Text('My Screen')),
///   body: Column(
///     children: [
///       GlassCard(body: Text('Content')),
///     ],
///   ),
/// )
/// ```
class GlassScaffold extends StatelessWidget {
  /// Optional app bar
  final PreferredSizeWidget? appBar;

  /// Main content (will be wrapped with background + weather)
  final Widget body;

  /// Maximum width for content (default: wizardCardMaxWidth)
  final double? maxWidth;

  /// Whether to enable background renderer
  final bool enableBackground;

  /// Custom padding for content (default: horizontal 16, vertical 24)
  final EdgeInsets? padding;

  /// Whether content should be scrollable (default: true)
  final bool scrollable;

  /// Optional scroll controller
  final ScrollController? scrollController;

  /// Optional floating action button
  final Widget? floatingActionButton;

  /// Optional drawer
  final Widget? drawer;

  const GlassScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.maxWidth,
    this.enableBackground = true,
    this.padding,
    this.scrollable = true,
    this.scrollController,
    this.floatingActionButton,
    this.drawer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      body: Consumer<BackgroundService>(
        builder: (context, backgroundService, child) {
          // If background is disabled, just show content
          if (!enableBackground) {
            return _buildContent();
          }

          // Full background + weather + content stack
          return Stack(
            children: [
              // Background renderer with data-driven presets
              Positioned.fill(
                child: BackgroundRenderer(
                  preset: backgroundService.activePreset,
                  enabled: enableBackground,
                ),
              ),

              // Lottie-based weather effects
              WeatherEffect(
                season: backgroundService.activePreset.season,
                intensity: backgroundService.weatherIntensity,
                timeOfDayOpacity: WeatherOpacityHelper.getTimeOfDayOpacity(
                  backgroundService.activePreset.timeOfDay,
                ),
                enabled: backgroundService.weatherEffectsEnabled,
                enablePerformanceMode: backgroundService.weatherPerformanceMode,
              ),

              // Main content
              _buildContent(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    final contentPadding = padding ?? const EdgeInsets.symmetric(
      horizontal: 16.0,
      vertical: 24.0,
    );

    final content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? DesignTokens.wizardCardMaxWidth,
        ),
        child: body,
      ),
    );

    if (scrollable) {
      return SingleChildScrollView(
        controller: scrollController,
        padding: contentPadding,
        child: content,
      );
    }

    return Padding(
      padding: contentPadding,
      child: content,
    );
  }
}
