import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/config/config_service.dart';
import 'src/services/storage_service.dart';
import 'src/services/http_client.dart';
import 'src/services/background_service.dart';
import 'src/models/collection_flow_state.dart';
import 'src/screens/home_screen.dart';
import 'src/screens/collection_wizard_screen.dart';
import 'src/ui/design_tokens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final storageService = StorageService();
  final configService = ConfigService(storageService);
  final backgroundService = BackgroundService(storageService);

  // Load saved configuration
  await configService.initialize();

  runApp(CiscoApp(
    configService: configService,
    backgroundService: backgroundService,
  ));
}

class CiscoApp extends StatelessWidget {
  final ConfigService configService;
  final BackgroundService backgroundService;

  const CiscoApp({
    super.key,
    required this.configService,
    required this.backgroundService,
  });

  /// FE-UI-049: Build liquid glass theme with custom input and button styles
  static ThemeData _buildLiquidGlassTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: DesignTokens.accentPrimary,
        brightness: brightness,
        primary: DesignTokens.accentPrimary,
        secondary: DesignTokens.accentPrimary,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: isDark ? DesignTokens.backgroundBase : Colors.white,

      // FE-UI-076: Lock Material transparency - kill surface/elevation bleed
      canvasColor: isDark ? DesignTokens.backgroundBase : Colors.white,
      cardColor: Colors.transparent, // Force cards to use explicit colors only
      dialogBackgroundColor: Colors.transparent, // Dialogs use glass styling

      // FE-UI-059: Flat content mode - inputs etched directly on glass
      // No pill containers, transparent background, border-only
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.transparent, // FE-UI-059: No background, etched appearance
        // Icon styling to match glass aesthetic
        iconColor: isDark ? DesignTokens.textSecondary : Colors.black54,
        prefixIconColor: isDark ? DesignTokens.textSecondary : Colors.black54,
        suffixIconColor: isDark ? DesignTokens.textSecondary : Colors.black54,
        border: OutlineInputBorder(
          borderRadius: DesignTokens.inputBorderRadius,
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(DesignTokens.inputBorderOpacity)
                : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: DesignTokens.inputBorderRadius,
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(DesignTokens.inputBorderOpacity)
                : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: DesignTokens.inputBorderRadius,
          borderSide: BorderSide(
            color: DesignTokens.accentPrimary.withOpacity(DesignTokens.inputFocusBorderOpacity),
            width: 1.0, // FE-UI-059: 1px for etched look (not thick pill)
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: DesignTokens.inputBorderRadius,
          borderSide: BorderSide(
            color: Colors.red.withOpacity(0.6),
            width: 1,
          ),
        ),
        labelStyle: TextStyle(
          color: isDark
              ? Colors.white.withOpacity(DesignTokens.inputLabelOpacity)
              : Colors.black.withOpacity(0.6),
          fontSize: 14,
        ),
        hintStyle: TextStyle(
          color: isDark
              ? DesignTokens.textMuted
              : Colors.black.withOpacity(0.4),
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      // FE-UI-049: Primary button with desaturated blue
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.accentPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: DesignTokens.buttonBorderRadius,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ).copyWith(
          // Hover state
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.hovered)) {
              return DesignTokens.accentHover;
            }
            if (states.contains(MaterialState.pressed)) {
              return DesignTokens.accentFocus;
            }
            if (states.contains(MaterialState.disabled)) {
              return isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.3);
            }
            return DesignTokens.accentPrimary;
          }),
        ),
      ),

      // FE-UI-049: Secondary buttons with glass style
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? DesignTokens.textPrimary : DesignTokens.accentPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: DesignTokens.buttonBorderRadius,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
        ),
      ),

      // FE-UI-076: Card theme - transparent to prevent grey slab
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: DesignTokens.cardBorderRadius,
        ),
        // Transparent - use GlassCard for actual glass styling
        color: Colors.transparent,
        margin: EdgeInsets.zero,
      ),

      // FE-UI-076: Dialog theme - transparent for glass styling
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: DesignTokens.cardBorderRadius,
        ),
      ),

      // FE-UI-076: SnackBar theme - stroke-first, no solid backgrounds
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark
            ? DesignTokens.backgroundBase.withOpacity(0.95)
            : Colors.white.withOpacity(0.95),
        contentTextStyle: TextStyle(
          color: isDark ? DesignTokens.textPrimary : Colors.black87,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
          side: BorderSide(
            color: Colors.white.withOpacity(isDark ? 0.15 : 0.3),
            width: 1,
          ),
        ),
        elevation: 0,
        behavior: SnackBarBehavior.floating,
      ),

      // Text theme
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: isDark ? DesignTokens.textPrimary : Colors.black87),
        bodyMedium: TextStyle(color: isDark ? DesignTokens.textSecondary : Colors.black87),
        bodySmall: TextStyle(color: isDark ? DesignTokens.textMuted : Colors.black54),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: configService),
        ChangeNotifierProvider.value(value: backgroundService),
        Provider(
          create: (context) => HttpClientService(configService),
        ),
        ChangeNotifierProvider(
          create: (context) => CollectionFlowState(),
        ),
      ],
      child: MaterialApp(
        title: 'Cisco Frontend',
        debugShowCheckedModeBanner: false,
        // FE-UI-049: Glass-styled theme with liquid glass inputs and buttons
        theme: _buildLiquidGlassTheme(Brightness.light),
        darkTheme: _buildLiquidGlassTheme(Brightness.dark),
        themeMode: ThemeMode.dark, // Default to dark theme for liquid glass
        // FE-SPRINT-LANDING-001: Conditional routing based on API key configuration
        home: Consumer<ConfigService>(
          builder: (context, config, _) {
            // Show landing page if no API key configured
            if (!config.isConfigured) {
              return const HomeScreen();
            }
            // Show main app (collection wizard) if already configured
            return const CollectionWizardScreen();
          },
        ),
      ),
    );
  }
}
