import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/background_preset.dart';
import '../models/background_preset_registry.dart';
import '../services/background_service.dart';
import 'design_tokens.dart';

/// Debug panel for background preset testing
/// Only visible in debug builds
class BackgroundDebugPanel extends StatefulWidget {
  const BackgroundDebugPanel({super.key});

  @override
  State<BackgroundDebugPanel> createState() => _BackgroundDebugPanelState();
}

class _BackgroundDebugPanelState extends State<BackgroundDebugPanel> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<BackgroundService>(
      builder: (context, backgroundService, child) {
        return Positioned(
          top: 80,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  InkWell(
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.palette_outlined,
                            color: DesignTokens.accentPrimary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Background Debug',
                            style: TextStyle(
                              color: DesignTokens.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            _isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: DesignTokens.textSecondary,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content (expandable)
                  if (_isExpanded) ...[
                    Divider(
                      color: Colors.white.withOpacity(0.1),
                      height: 1,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Mode selector
                          _buildSectionLabel('Mode'),
                          const SizedBox(height: 8),
                          _buildModeSelector(backgroundService),
                          const SizedBox(height: 16),

                          // Time of Day (Debug Override)
                          _buildSectionLabel('Time of Day (Debug)'),
                          const SizedBox(height: 8),
                          _buildTimeOfDaySelector(backgroundService),
                          const SizedBox(height: 16),

                          // Season (Debug Override)
                          _buildSectionLabel('Season (Debug)'),
                          const SizedBox(height: 8),
                          _buildSeasonSelector(backgroundService),
                          const SizedBox(height: 16),

                          // FE-BG-106: Weather Effects Controls
                          _buildSectionLabel('Weather Effects'),
                          const SizedBox(height: 8),
                          _buildWeatherToggle(backgroundService),
                          const SizedBox(height: 12),
                          _buildWeatherIntensitySlider(backgroundService),
                          const SizedBox(height: 16),

                          // Current Preset Info
                          _buildSectionLabel('Current Preset'),
                          const SizedBox(height: 8),
                          _buildPresetInfo(backgroundService),
                          const SizedBox(height: 16),

                          // Actions
                          _buildActionButtons(backgroundService),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: DesignTokens.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildModeSelector(BackgroundService service) {
    return Row(
      children: [
        Expanded(
          child: _buildModeButton(
            label: 'Auto',
            isSelected: service.mode == BackgroundMode.auto,
            onTap: () => service.setMode(BackgroundMode.auto),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildModeButton(
            label: 'Manual',
            isSelected: service.mode == BackgroundMode.manual,
            onTap: () => service.setMode(BackgroundMode.manual),
          ),
        ),
      ],
    );
  }

  Widget _buildModeButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? DesignTokens.accentPrimary.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? DesignTokens.accentPrimary
                : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? DesignTokens.accentPrimary : DesignTokens.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeOfDaySelector(BackgroundService service) {
    final times = [null, BackgroundTimeOfDay.dawn, BackgroundTimeOfDay.day, BackgroundTimeOfDay.dusk, BackgroundTimeOfDay.night];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: times.map((time) {
        final isSelected = service.debugTimeOfDay == time;
        final label = time == null ? 'Auto' : _timeOfDayLabel(time);

        return InkWell(
          onTap: () => service.setDebugTimeOfDay(time),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? DesignTokens.accentPrimary.withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected
                    ? DesignTokens.accentPrimary
                    : Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? DesignTokens.accentPrimary : DesignTokens.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSeasonSelector(BackgroundService service) {
    final seasons = [null, Season.spring, Season.summer, Season.fall, Season.winter];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: seasons.map((season) {
        final isSelected = service.debugSeason == season;
        final label = season == null ? 'Auto' : _seasonLabel(season);

        return InkWell(
          onTap: () => service.setDebugSeason(season),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? DesignTokens.accentPrimary.withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected
                    ? DesignTokens.accentPrimary
                    : Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? DesignTokens.accentPrimary : DesignTokens.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // FE-BG-106: Weather effects toggle
  Widget _buildWeatherToggle(BackgroundService service) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Enabled',
          style: TextStyle(
            color: DesignTokens.textSecondary,
            fontSize: 12,
          ),
        ),
        Switch(
          value: service.weatherEffectsEnabled,
          onChanged: (value) => service.setWeatherEffectsEnabled(value),
          activeColor: DesignTokens.accentPrimary,
        ),
      ],
    );
  }

  // FE-BG-100-106: Weather intensity slider
  Widget _buildWeatherIntensitySlider(BackgroundService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _weatherIntensityLabel(service.weatherIntensity),
              style: TextStyle(
                color: DesignTokens.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${(service.weatherIntensity * 100).round()}%',
              style: TextStyle(
                color: DesignTokens.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: DesignTokens.accentPrimary,
            inactiveTrackColor: Colors.white.withOpacity(0.1),
            thumbColor: DesignTokens.accentPrimary,
            overlayColor: DesignTokens.accentPrimary.withOpacity(0.2),
            trackHeight: 3,
          ),
          child: Slider(
            value: service.weatherIntensity,
            min: 0.0,
            max: 1.0,
            divisions: 3,
            onChanged: (value) => service.setWeatherIntensity(value),
          ),
        ),
      ],
    );
  }

  String _weatherIntensityLabel(double intensity) {
    if (intensity == 0.0) return 'Off';
    if (intensity <= 0.33) return 'Low';
    if (intensity <= 0.66) return 'Medium';
    return 'High';
  }

  Widget _buildPresetInfo(BackgroundService service) {
    final preset = service.activePreset;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: preset.baseColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                preset.name,
                style: TextStyle(
                  color: DesignTokens.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'ID: ${preset.id}',
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            'Blooms: ${preset.blooms.length} | Bands: ${preset.bands.length}',
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BackgroundService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () => service.clearDebugOverrides(),
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Reset to Auto'),
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignTokens.accentPrimary.withOpacity(0.2),
            foregroundColor: DesignTokens.accentPrimary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: DesignTokens.accentPrimary.withOpacity(0.5),
                width: 1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _copyScreenshotName,
          icon: const Icon(Icons.screenshot, size: 16),
          label: const Text('Copy Screenshot Name'),
          style: OutlinedButton.styleFrom(
            foregroundColor: DesignTokens.textSecondary,
            side: BorderSide(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  void _copyScreenshotName() {
    final service = context.read<BackgroundService>();
    final preset = service.activePreset;
    final weather = service.weatherIntensity.snowIntensityLabel.toLowerCase();

    final filename = 'bg-${preset.id}-weather-$weather-${DateTime.now().millisecondsSinceEpoch}.png';

    Clipboard.setData(ClipboardData(text: filename));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied: $filename'),
        duration: const Duration(seconds: 2),
        backgroundColor: DesignTokens.accentPrimary,
      ),
    );
  }

  String _timeOfDayLabel(BackgroundTimeOfDay time) {
    switch (time) {
      case BackgroundTimeOfDay.dawn:
        return 'Dawn';
      case BackgroundTimeOfDay.day:
        return 'Day';
      case BackgroundTimeOfDay.dusk:
        return 'Dusk';
      case BackgroundTimeOfDay.night:
        return 'Night';
    }
  }

  String _seasonLabel(Season season) {
    switch (season) {
      case Season.spring:
        return 'Spring';
      case Season.summer:
        return 'Summer';
      case Season.fall:
        return 'Fall';
      case Season.winter:
        return 'Winter';
    }
  }
}

/// Extension for weather intensity labels
extension on double {
  String get snowIntensityLabel {
    if (this == 0.0) return 'Off';
    if (this <= 0.33) return 'Low';
    if (this <= 0.66) return 'Medium';
    return 'High';
  }
}
