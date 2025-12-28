import 'package:flutter/material.dart';

/// FE-035: Compact visual density design tokens
/// Centralized sizing constants for consistent UI across the application
class DesignTokens {
  // Prevent instantiation
  DesignTokens._();

  // ==================== FORM CONTROLS ====================

  /// Maximum width for form controls (inputs, buttons)
  /// FE-032: Constrain form width for better readability
  static const double formMaxWidth = 640.0;

  /// Form input height (standard)
  static const double inputHeight = 44.0;

  /// Form input height (compact)
  static const double inputHeightCompact = 40.0;

  // ==================== PADDING & SPACING ====================

  /// Standard padding for form fields
  static const double paddingStandard = 16.0;

  /// Compact padding for tight layouts
  static const double paddingCompact = 12.0;

  /// Large padding for card interiors
  static const double paddingLarge = 24.0;

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

  // ==================== BORDER RADIUS ====================

  /// Border radius for cards (Glass UI)
  /// FE-036: Increased for softer, more modern look
  static const double radiusCard = 24.0;

  /// Border radius for buttons
  static const double radiusButton = 16.0;

  /// Border radius for inputs
  static const double radiusInput = 12.0;

  /// Border radius for chips/badges
  static const double radiusChip = 16.0;

  /// Border radius for small elements
  static const double radiusSmall = 8.0;

  // ==================== GLASS UI (FE-036) ====================

  /// Blur strength for glass morphism effect
  static const double blurStrength = 16.0;

  /// Blur strength for chips/small elements
  static const double blurStrengthChip = 10.0;

  /// Card fill opacity for glass effect
  static const double glassFillOpacity = 0.15;

  /// Border opacity for glass effect
  static const double glassBorderOpacity = 0.2;

  /// Shadow strength for glass cards
  static const double glassShadowOpacity = 0.1;

  /// Shadow blur radius for glass cards
  static const double glassShadowBlur = 24.0;

  // ==================== CONTENT WIDTH CONSTRAINTS ====================

  /// Maximum width for page content (FE-022)
  static const double contentMaxWidth = 1200.0;

  /// Maximum width for step card inner content (FE-034)
  static const double stepContentMaxWidth = 800.0;

  /// Breakpoint for mobile layout
  static const double breakpointMobile = 600.0;

  /// Breakpoint for tablet layout
  static const double breakpointTablet = 900.0;

  /// Breakpoint for desktop layout
  static const double breakpointDesktop = 1200.0;

  // ==================== ELEVATION & SHADOWS ====================

  /// Card elevation (standard)
  static const double elevationCard = 2.0;

  /// Card elevation (raised)
  static const double elevationCardRaised = 4.0;

  /// Shadow opacity (subtle)
  static const double shadowOpacitySubtle = 0.04;

  /// Shadow opacity (standard)
  static const double shadowOpacityStandard = 0.08;

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
