import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/config/config_service.dart';
import 'src/services/storage_service.dart';
import 'src/services/http_client.dart';
import 'src/models/collection_flow_state.dart';
import 'src/screens/home_screen.dart';
import 'src/ui/design_tokens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final storageService = StorageService();
  final configService = ConfigService(storageService);

  // Load saved configuration
  await configService.initialize();

  runApp(CiscoApp(
    configService: configService,
  ));
}

class CiscoApp extends StatelessWidget {
  final ConfigService configService;

  const CiscoApp({
    super.key,
    required this.configService,
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

      // FE-UI-055: Disable Material surface/canvas color inheritance
      canvasColor: isDark ? DesignTokens.backgroundBase : Colors.white,
      cardColor: Colors.transparent, // Force cards to use explicit colors only
      dialogBackgroundColor: isDark ? DesignTokens.backgroundBase : Colors.white,

      // FE-UI-055: Input decoration with TRANSPARENT background
      // Only ONE translucent layer allowed (the card itself)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.transparent, // FE-UI-055: No background, border-only
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
            width: 1.5,
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

      // FE-UI-055: Card theme - transparent to prevent grey slab
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
        home: const HomeScreen(),
      ),
    );
  }
}
