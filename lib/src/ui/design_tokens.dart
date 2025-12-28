import 'package:flutter/material.dart';

/// FE-UI-046: Liquid Glass design tokens
/// Single source of truth for all colors, opacity, radius, and shadows
class DesignTokens {
  // Prevent instantiation
  DesignTokens._();

  // ==================== BACKGROUND COLORS ====================

  /// Background base color - not pure black to avoid banding
  /// FE-UI-046: #05060A for depth without pure black artifacts
  static const Color backgroundBase = Color(0xFF05060A);

  /// Bloom glow colors (very subtle)
  static const Color bloomPrimary = Colors.white;
  static const Color bloomSecondary = Color(0xFF6B7FFF); // Subtle blue
  static const Color bloomTertiary = Color(0xFF9D7FFF); // Subtle purple

  // ==================== TEXT COLORS (FE-UI-046) ====================

  /// Primary text - white at 92% opacity
  static const Color textPrimary = Color(0xFFEBEBEB); // ~92% white

  /// Secondary text - white at 70% opacity
  static const Color textSecondary = Color(0xFFB3B3B3); // ~70% white

  /// Muted text - white at 50% opacity
  static const Color textMuted = Color(0xFF808080); // ~50% white

  // ==================== GLASS FILL & BORDER (FE-UI-046) ====================

  /// Glass fill base opacity (6-10% range)
  static const double glassFillOpacity = 0.08;

  /// Glass fill opacity for focused/active elements
  static const double glassFillOpacityFocus = 0.10;

  /// Glass border opacity (14-18% range)
  static const double glassBorderOpacity = 0.16;

  /// Inner highlight opacity (top edge only)
  static const double glassHighlightOpacity = 0.10;

  // ==================== GLASS BLUR (FE-UI-048) ====================

  /// Glass blur strength for cards (web-optimized: 12-18)
  static const double blurStrength = 16.0;

  /// Glass blur strength for inputs
  static const double blurStrengthInput = 12.0;

  /// Blur strength for chips/small elements
  static const double blurStrengthChip = 10.0;

  // ==================== BORDER RADIUS (FE-UI-046) ====================

  /// FE-UI-058: Border radius for cards (reduced 15% for crisp edges: 26 → 22)
  static const double radiusCard = 22.0;

  /// Border radius for buttons
  static const double radiusButton = 16.0;

  /// Border radius for inputs (14-16 range)
  static const double radiusInput = 15.0;

  /// Border radius for chips/badges
  static const double radiusChip = 16.0;

  /// Border radius for small elements
  static const double radiusSmall = 8.0;

  // ==================== SHADOWS (FE-UI-046) ====================

  /// Outer shadow opacity
  static const double shadowOuterOpacity = 0.45;

  /// Outer shadow blur radius
  static const double shadowOuterBlur = 38.0;

  /// Outer shadow spread
  static const double shadowOuterSpread = 1.0;

  /// Inner shadow opacity (optional)
  static const double shadowInnerOpacity = 0.20;

  /// Inner shadow blur radius
  static const double shadowInnerBlur = 14.0;

  // ==================== FORM CONTROLS (FE-UI-050) ====================

  /// Maximum width for wizard card (820-940px range)
  static const double wizardCardMaxWidth = 880.0;

  /// Maximum width for form column inside card (520-640px range)
  static const double formMaxWidth = 580.0;

  /// Form input height (standard)
  static const double inputHeight = 44.0;

  /// Form input height (compact)
  static const double inputHeightCompact = 40.0;

  // ==================== PADDING & SPACING ====================

  /// Vertical padding inside card (20-28px range)
  static const double paddingCardVertical = 24.0;

  /// Horizontal padding inside card
  static const double paddingCardHorizontal = 24.0;

  /// Standard padding for form fields
  static const double paddingStandard = 16.0;

  /// Compact padding for tight layouts
  static const double paddingCompact = 12.0;

  /// Large padding for card interiors
  static const double paddingLarge = 20.0;

  /// Extra compact padding for dense UI elements
  static const double paddingXCompact = 8.0;

  /// Spacing between form sections
  static const double spacingSection = 24.0;

  /// Spacing between form fields
  static const double spacingField = 16.0;

  /// Spacing between components
  static const double spacingComponent = 12.0;

  /// Spacing between inline elements
  static const double spacingInline = 8.0;

  /// Spacing for chips/pills
  static const double spacingChip = 8.0;

  // ==================== ACCENT COLORS ====================

  /// Primary accent color - desaturated blue for premium look
  /// FE-UI-049: Not pure Material blue
  static const Color accentPrimary = Color(0xFF5B8DEE);

  /// Accent color for hover states
  static const Color accentHover = Color(0xFF7BA5F3);

  /// Accent color for focus states
  static const Color accentFocus = Color(0xFF4A7CD9);

  /// Legacy: MaterialColor for backward compatibility with shade access
  /// Use accentPrimary for new code
  static const MaterialColor accentColor = Colors.blue;

  /// Neutral color for completed/success states
  static const MaterialColor neutralColor = Colors.grey;

  // ==================== CONTENT WIDTH CONSTRAINTS ====================

  /// Maximum width for page content
  static const double contentMaxWidth = 1200.0;

  /// Breakpoint for mobile layout
  static const double breakpointMobile = 600.0;

  /// Breakpoint for tablet layout
  static const double breakpointTablet = 900.0;

  /// Breakpoint for desktop layout
  static const double breakpointDesktop = 1200.0;

  // ==================== INPUT STYLES (FE-UI-049) ====================

  /// Input background opacity (4-6% range)
  static const double inputBackgroundOpacity = 0.05;

  /// Input border opacity
  static const double inputBorderOpacity = 0.14;

  /// Input focus border opacity (60-80% range)
  static const double inputFocusBorderOpacity = 0.70;

  /// Input label text opacity (55-65% range)
  static const double inputLabelOpacity = 0.60;

  // ==================== HELPER METHODS ====================

  /// Returns EdgeInsets for form field padding
  static EdgeInsets get formFieldPadding =>
      const EdgeInsets.all(paddingStandard);

  /// Returns EdgeInsets for compact padding
  static EdgeInsets get compactPadding =>
      const EdgeInsets.all(paddingCompact);

  /// Returns EdgeInsets for card padding
  static EdgeInsets get cardPadding =>
      const EdgeInsets.all(paddingLarge);

  /// Returns BorderRadius for cards
  static BorderRadius get cardBorderRadius =>
      BorderRadius.circular(radiusCard);

  /// Returns BorderRadius for buttons
  static BorderRadius get buttonBorderRadius =>
      BorderRadius.circular(radiusButton);

  /// Returns BorderRadius for inputs
  static BorderRadius get inputBorderRadius =>
      BorderRadius.circular(radiusInput);

  /// Returns BorderRadius for chips
  static BorderRadius get chipBorderRadius =>
      BorderRadius.circular(radiusChip);

  /// Determines if the given width is mobile
  static bool isMobile(double width) => width < breakpointMobile;

  /// Determines if the given width is tablet
  static bool isTablet(double width) =>
      width >= breakpointMobile && width < breakpointTablet;

  /// Determines if the given width is desktop
  static bool isDesktop(double width) => width >= breakpointTablet;

  /// Returns the number of grid columns based on width
  static int getGridColumns(double width) {
    if (width > breakpointTablet) return 3; // Desktop: 3 columns
    if (width > breakpointMobile) return 2; // Tablet: 2 columns
    return 1; // Mobile: 1 column
  }
}
