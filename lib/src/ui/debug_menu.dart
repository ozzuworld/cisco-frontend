import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// FE-UI-PROD-1 & FE-UI-PROD-3: Consolidated debug menu
///
/// Provides organized access to all debug features in a single modal/dropdown
/// instead of cluttering the AppBar with multiple icon buttons.
///
/// Features:
/// - Glass QA tools (fill proof, test pattern, glass stage, blur toggle)
/// - Background controls (environment plate, debug panel toggle)
/// - Clean, organized UI
/// - Only visible in debug mode
class DebugMenu {
  /// Show the debug menu as a modal bottom sheet
  static void show(
    BuildContext context, {
    required bool showFillProof,
    required bool showTestPattern,
    required bool showGlassStage,
    required bool disableBlur,
    required bool showEnvironmentPlate,
    required bool showBackgroundDebugPanel,
    required Function(bool) onToggleFillProof,
    required Function(bool) onToggleTestPattern,
    required Function(bool) onToggleGlassStage,
    required Function(bool) onToggleBlur,
    required Function(bool) onToggleEnvironmentPlate,
    required Function(bool) onToggleBackgroundDebugPanel,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _DebugMenuContent(
        showFillProof: showFillProof,
        showTestPattern: showTestPattern,
        showGlassStage: showGlassStage,
        disableBlur: disableBlur,
        showEnvironmentPlate: showEnvironmentPlate,
        showBackgroundDebugPanel: showBackgroundDebugPanel,
        onToggleFillProof: onToggleFillProof,
        onToggleTestPattern: onToggleTestPattern,
        onToggleGlassStage: onToggleGlassStage,
        onToggleBlur: onToggleBlur,
        onToggleEnvironmentPlate: onToggleEnvironmentPlate,
        onToggleBackgroundDebugPanel: onToggleBackgroundDebugPanel,
      ),
    );
  }
}

class _DebugMenuContent extends StatelessWidget {
  final bool showFillProof;
  final bool showTestPattern;
  final bool showGlassStage;
  final bool disableBlur;
  final bool showEnvironmentPlate;
  final bool showBackgroundDebugPanel;
  final Function(bool) onToggleFillProof;
  final Function(bool) onToggleTestPattern;
  final Function(bool) onToggleGlassStage;
  final Function(bool) onToggleBlur;
  final Function(bool) onToggleEnvironmentPlate;
  final Function(bool) onToggleBackgroundDebugPanel;

  const _DebugMenuContent({
    required this.showFillProof,
    required this.showTestPattern,
    required this.showGlassStage,
    required this.disableBlur,
    required this.showEnvironmentPlate,
    required this.showBackgroundDebugPanel,
    required this.onToggleFillProof,
    required this.onToggleTestPattern,
    required this.onToggleGlassStage,
    required this.onToggleBlur,
    required this.onToggleEnvironmentPlate,
    required this.onToggleBackgroundDebugPanel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: DesignTokens.accentPrimary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.developer_mode,
                      color: DesignTokens.accentPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Debug Tools',
                    style: TextStyle(
                      color: DesignTokens.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: DesignTokens.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Glass QA Section
              _buildSectionHeader('Glass QA Tools', Icons.blur_on),
              const SizedBox(height: 12),
              _buildToggle(
                label: 'Fill Proof',
                subtitle: 'Show hot pink if fill is not transparent',
                value: showFillProof,
                onChanged: onToggleFillProof,
                activeColor: const Color(0xFFFF1493),
              ),
              _buildToggle(
                label: 'Test Pattern',
                subtitle: 'Show grid pattern for glass refraction testing',
                value: showTestPattern,
                onChanged: onToggleTestPattern,
                activeColor: Colors.orange,
              ),
              _buildToggle(
                label: 'Glass Stage',
                subtitle: 'Hard-edge bands for refraction visibility',
                value: showGlassStage,
                onChanged: onToggleGlassStage,
                activeColor: const Color(0xFF9D7FFF),
              ),
              _buildToggle(
                label: 'Disable Blur',
                subtitle: 'Test glass without backdrop blur',
                value: disableBlur,
                onChanged: onToggleBlur,
                activeColor: Colors.amber,
              ),
              const SizedBox(height: 24),

              // Background Section
              _buildSectionHeader('Background Tools', Icons.landscape),
              const SizedBox(height: 12),
              _buildToggle(
                label: 'Environment Plate',
                subtitle: 'Background rendering (disable to test on black)',
                value: showEnvironmentPlate,
                onChanged: onToggleEnvironmentPlate,
                activeColor: const Color(0xFF00FF00),
              ),
              _buildToggle(
                label: 'Background Debug Panel',
                subtitle: 'Show advanced background/weather controls',
                value: showBackgroundDebugPanel,
                onChanged: onToggleBackgroundDebugPanel,
                activeColor: DesignTokens.accentPrimary,
              ),
              const SizedBox(height: 16),

              // Info text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Debug tools are only visible in debug builds',
                        style: TextStyle(
                          color: Colors.blue.shade300,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: DesignTokens.textSecondary, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: DesignTokens.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildToggle({
    required String label,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required Color activeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: value
                ? activeColor.withOpacity(0.1)
                : Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: value
                  ? activeColor.withOpacity(0.3)
                  : Colors.white.withOpacity(0.08),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: DesignTokens.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: DesignTokens.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: activeColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
