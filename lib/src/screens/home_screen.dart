import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../config/config_service.dart';
import '../ui/glass_scaffold.dart';
import '../ui/design_tokens.dart';
import 'collection_wizard_screen.dart';

/// FE-SPRINT-LANDING-001: Minimal landing page with API key input
/// Super clean secret tool interface - just an input box
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _apiKeyController = TextEditingController();
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
      scrollable: false,
      body: SizedBox.expand(
        child: Stack(
          children: [
            // voip.json lottie animation as background - centered and sized
            Center(
              child: Opacity(
                opacity: 0.20,
                child: SizedBox(
                  width: 800,
                  height: 600,
                  child: Lottie.asset(
                    'assets/lottie/voip.json',
                    fit: BoxFit.contain,
                    repeat: true,
                  ),
                ),
              ),
            ),
            // Minimal API key input
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Container(
                    height: 56, // Professional input height
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _apiKeyController,
                      obscureText: _obscureText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: DesignTokens.textPrimary,
                        fontSize: 16,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'API KEY',
                        hintStyle: TextStyle(
                          color: DesignTokens.textMuted.withOpacity(0.3),
                          letterSpacing: 2,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Show/hide toggle
                            IconButton(
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20,
                                color: DesignTokens.textSecondary.withOpacity(0.5),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                            ),
                            // Submit button
                            if (_isLoading)
                              Padding(
                                padding: const EdgeInsets.only(right: 12.0),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      DesignTokens.accentPrimary.withOpacity(0.7),
                                    ),
                                  ),
                                ),
                              )
                            else
                              IconButton(
                                icon: Icon(
                                  Icons.arrow_forward,
                                  size: 20,
                                  color: DesignTokens.accentPrimary.withOpacity(0.7),
                                ),
                                onPressed: _handleSubmit,
                              ),
                          ],
                        ),
                      ),
                      onSubmitted: (_) => _handleSubmit(),
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

  void _handleSubmit() async {
    final apiKey = _apiKeyController.text.trim();

    if (apiKey.isEmpty) {
      _showError('Enter API key');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final configService = context.read<ConfigService>();
      await configService.updateApiKey(apiKey, true); // Always remember

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
        _showError('Failed: $e');
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
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
