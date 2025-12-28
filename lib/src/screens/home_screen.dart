import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../config/config_service.dart';
import '../ui/glass_scaffold.dart';
import '../ui/glass_card.dart';
import '../ui/design_tokens.dart';
import 'collection_wizard_screen.dart';

/// FE-SPRINT-LANDING-001: Simplified landing page with API key input
/// Features:
/// - voip.json lottie animation as background
/// - Clean, minimal UI with single API key input
/// - Liquid glass design aesthetic
/// - Direct navigation to main app after configuration
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _apiKeyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _rememberKey = false;
  bool _obscureText = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      enableBackground: true,
      scrollable: false, // Disable scrolling to allow Stack to fill screen
      body: SizedBox.expand(
        child: Stack(
          children: [
            // voip.json lottie animation as background
            Positioned.fill(
              child: Opacity(
                opacity: 0.3, // Subtle effect, doesn't distract from UI
                child: Lottie.asset(
                  'assets/lottie/voip.json',
                  fit: BoxFit.cover,
                  repeat: true,
                ),
              ),
            ),
            // Main content - scrollable for overflow protection
            SingleChildScrollView(
              child: SizedBox(
                height: MediaQuery.of(context).size.height,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: GlassCard(
                  body: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // App branding
                        Icon(
                          Icons.cloud_outlined,
                          size: 64,
                          color: DesignTokens.accentPrimary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Cisco Frontend',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: DesignTokens.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter your API key to continue',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: DesignTokens.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 32),

                        // API Key input
                        TextFormField(
                          controller: _apiKeyController,
                          obscureText: _obscureText,
                          style: TextStyle(
                            color: DesignTokens.textPrimary,
                          ),
                          decoration: InputDecoration(
                            labelText: 'API Key',
                            labelStyle: TextStyle(
                              color: DesignTokens.textSecondary.withOpacity(
                                DesignTokens.inputLabelOpacity,
                              ),
                            ),
                            hintText: 'Enter your API key',
                            hintStyle: TextStyle(
                              color: DesignTokens.textMuted,
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(
                              DesignTokens.inputBackgroundOpacity,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: DesignTokens.inputBorderRadius,
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(
                                  DesignTokens.inputBorderOpacity,
                                ),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: DesignTokens.inputBorderRadius,
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(
                                  DesignTokens.inputBorderOpacity,
                                ),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: DesignTokens.inputBorderRadius,
                              borderSide: BorderSide(
                                color: DesignTokens.accentPrimary.withOpacity(
                                  DesignTokens.inputFocusBorderOpacity,
                                ),
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: DesignTokens.inputBorderRadius,
                              borderSide: BorderSide(
                                color: Colors.red.withOpacity(0.7),
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: DesignTokens.inputBorderRadius,
                              borderSide: BorderSide(
                                color: Colors.red.withOpacity(0.9),
                                width: 1.5,
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: DesignTokens.textSecondary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter an API key';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Remember checkbox
                        InkWell(
                          onTap: () {
                            setState(() {
                              _rememberKey = !_rememberKey;
                            });
                          },
                          borderRadius: BorderRadius.circular(
                            DesignTokens.radiusSmall,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                              vertical: 8.0,
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _rememberKey,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberKey = value ?? false;
                                    });
                                  },
                                  fillColor: MaterialStateProperty.resolveWith(
                                    (states) {
                                      if (states.contains(MaterialState.selected)) {
                                        return DesignTokens.accentPrimary;
                                      }
                                      return Colors.white.withOpacity(0.2);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Remember API Key',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: DesignTokens.textPrimary,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Continue button
                        SizedBox(
                          height: DesignTokens.inputHeight,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: DesignTokens.accentPrimary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  DesignTokens.accentPrimary.withOpacity(0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: DesignTokens.buttonBorderRadius,
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Continue',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleContinue() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final apiKey = _apiKeyController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      // Save to ConfigService
      final configService = context.read<ConfigService>();
      await configService.updateApiKey(apiKey, _rememberKey);

      // Navigate to main app
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const CollectionWizardScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to configure API key: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.withOpacity(0.9),
      ),
    );
  }
}
