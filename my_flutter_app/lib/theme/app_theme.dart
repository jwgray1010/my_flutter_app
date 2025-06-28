import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _primary = Color(0xFF6C47FF);
  static const _primaryDark = Color(0xFF4A2FE7);
  static const _secondary = Color(0xFF00D2FF);
  static const _accent = Color(0xFFFF6B6B);
  static const _success = Color(0xFF4CAF50);
  static const _warning = Color(0xFFFF9800);
  static const _error = Color(0xFFF44336);

  // Premium gradient colors
  static const _premiumGold = Color(0xFFFFD700);
  static const _premiumGoldDark = Color(0xFFB8860B);

  // Neutral colors
  static const _background = Color(0xFFF8F9FA);
  static const _surface = Color(0xFFFFFFFF);
  static const _onSurface = Color(0xFF1A1A1A);
  static const _onBackground = Color(0xFF2D3748);
  static const _outline = Color(0xFFE2E8F0);

  // Text colors
  static const _textPrimary = Color(0xFF1A202C);
  static const _textSecondary = Color(0xFF4A5568);
  static const _textTertiary = Color(0xFF718096);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: _primary,
      primaryContainer: Color(0xFFE8E1FF),
      secondary: _secondary,
      secondaryContainer: Color(0xFFB3F5FF),
      tertiary: _accent,
      surface: _surface,
      error: _error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: _onSurface,
      outline: _outline,
    ),

    textTheme: GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        color: _textPrimary,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: _textPrimary,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: _textPrimary,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: _textPrimary,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: _textPrimary,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: _textPrimary,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: _textPrimary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: _textPrimary,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: _textPrimary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: _textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: _textSecondary,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: _textTertiary,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: _textPrimary,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: _textSecondary,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: _textTertiary,
      ),
    ),

    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: _surface,
      foregroundColor: _textPrimary,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: _textPrimary,
      ),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _primary,
        side: const BorderSide(color: _primary, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: GoogleFonts.inter(
        color: _textTertiary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      labelStyle: GoogleFonts.inter(
        color: _textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      color: _surface,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _outline, width: 0.5),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: _surface,
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: _textPrimary,
      ),
      contentTextStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: _textSecondary,
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: _onSurface,
      contentTextStyle: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
      elevation: 8,
    ),

    sliderTheme: SliderThemeData(
      activeTrackColor: _primary,
      inactiveTrackColor: _outline,
      thumbColor: _primary,
      overlayColor: _primary.withOpacity(0.1),
      valueIndicatorColor: _primary,
      valueIndicatorTextStyle: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return _primary;
        return Colors.grey;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primary.withOpacity(0.3);
        }
        return Colors.grey.withOpacity(0.3);
      }),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _primary,
      linearTrackColor: _outline,
      circularTrackColor: _outline,
    ),

    dividerTheme: const DividerThemeData(
      color: _outline,
      thickness: 1,
      space: 1,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: _background,
      selectedColor: _primary.withOpacity(0.1),
      secondarySelectedColor: _secondary.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: _textPrimary,
      ),
      secondaryLabelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: _primary,
      ),
      brightness: Brightness.light,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: _outline),
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _surface,
      selectedItemColor: _primary,
      unselectedItemColor: _textTertiary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );

  // Premium theme for special UI elements
  static LinearGradient premiumGradient = const LinearGradient(
    colors: [_premiumGold, _premiumGoldDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Primary and secondary gradients for UI elements
  static LinearGradient primaryGradient = const LinearGradient(
    colors: [_primary, _primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient secondaryGradient = const LinearGradient(
    colors: [_secondary, Color(0xFF0088CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient accentGradient = const LinearGradient(
    colors: [_accent, Color(0xFFFF4757)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Advanced shadows
  static List<BoxShadow> primaryShadow = [
    BoxShadow(
      color: _primary.withOpacity(0.2),
      blurRadius: 16,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 24,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 6,
      offset: const Offset(0, 1),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> floatingShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 32,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
  ];

  // Animation durations
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  // Spacing system
  static const double spaceXS = 4;
  static const double spaceSM = 8;
  static const double spaceMD = 16;
  static const double spaceLG = 24;
  static const double spaceXL = 32;
  static const double space2XL = 48;
  static const double space3XL = 64;

  // Border radius system
  static const double radiusXS = 4;
  static const double radiusSM = 8;
  static const double radiusMD = 12;
  static const double radiusLG = 16;
  static const double radiusXL = 20;
  static const double radius2XL = 24;
  static const double radiusFull = 1000;

  // Add static methods for accessing theme data
  static AppThemeData of(BuildContext context) {
    final theme = Theme.of(context);
    return AppThemeData(theme);
  }

  // Gradient definitions
  static const LinearGradient lightGradient = LinearGradient(
    colors: [Color(0xFFF8F9FA), Color(0xFFFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF1A202C), Color(0xFF2D3748)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadow definitions
  static List<BoxShadow> get shadows => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get shadowsMedium => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  // Error color getter
  static Color get errorColor => _error;

  // Dot notation access for static usage
  static _Spacing get spacing => _Spacing();
  static _Spacing get spacingDot => _Spacing();
  static _BorderRadius get radius => _BorderRadius();
  static _BorderRadius get radiusDot => _BorderRadius();
  static _Shadows get shadow => _Shadows();
  static _Shadows get shadowsDot => _Shadows();
}

// Theme data wrapper class
class AppThemeData {
  final ThemeData _theme;

  AppThemeData(this._theme);

  ColorScheme get colorScheme => _theme.colorScheme;
  TextTheme get textTheme => _theme.textTheme;

  // Color system for professional screens
  _Colors get colors => _Colors(_theme);

  // Typography system
  _Typography get typography => _Typography(_theme.textTheme);

  // Gradients system
  _Gradients get gradients => _Gradients();

  // Primary and secondary colors
  Color get primary => _theme.colorScheme.primary;
  Color get secondary => _theme.colorScheme.secondary;

  // Status colors
  Color get error => _theme.colorScheme.error;
  Color get success => const Color(0xFF10B981);
  Color get warning => const Color(0xFFF59E0B);
  Color get info => const Color(0xFF3B82F6);

  // Background colors
  Color get backgroundPrimary => _theme.colorScheme.surface;
  Color get backgroundSecondary => _theme.colorScheme.surfaceContainerLow;
  Color get surfacePrimary => _theme.colorScheme.surface;

  // Text colors
  Color get textPrimary => _theme.colorScheme.onSurface;
  Color get textSecondary =>
      _theme.colorScheme.onSurface.withValues(alpha: 0.7);

  // Border color
  Color get borderColor => _theme.colorScheme.outline;

  // Gradient definitions
  LinearGradient get lightGradient => AppTheme.lightGradient;
  LinearGradient get darkGradient => AppTheme.darkGradient;

  // Shadow definitions
  _Shadows get shadows => _Shadows();
  List<BoxShadow> get shadowsMedium => AppTheme.shadowsMedium;

  // Spacing system with dot notation
  _Spacing get spacing => _Spacing();
  double get spaceXS => AppTheme.spaceXS;
  double get spaceSM => AppTheme.spaceSM;
  double get spaceMD => AppTheme.spaceMD;
  double get spaceLG => AppTheme.spaceLG;
  double get spaceXL => AppTheme.spaceXL;
  double get space2XL => AppTheme.space2XL;
  double get space3XL => AppTheme.space3XL;

  // Border radius system
  double get radius => AppTheme.radiusMD;
  double get radiusXS => AppTheme.radiusXS;
  double get radiusSM => AppTheme.radiusSM;
  double get radiusMD => AppTheme.radiusMD;
  double get radiusLG => AppTheme.radiusLG;
  double get radiusXL => AppTheme.radiusXL;
  double get radius2XL => AppTheme.radius2XL;
  double get radiusFull => AppTheme.radiusFull;

  // Border radius with dot notation
  _BorderRadius get borderRadius => _BorderRadius();

  // Spacing with dot notation access
  _Spacing get spacingDot => _Spacing();

  // Shadows with dot notation access
  _Shadows get shadowsDot => _Shadows();

  // Error color
  Color get errorColor => AppTheme.errorColor;

  // Animation durations
  Duration get fastAnimation => AppTheme.fastAnimation;
  Duration get normalAnimation => AppTheme.normalAnimation;
  Duration get slowAnimation => AppTheme.slowAnimation;
}

// Helper classes for dot notation access
class _BorderRadius {
  double get xs => AppTheme.radiusXS;
  double get sm => AppTheme.radiusSM;
  double get md => AppTheme.radiusMD;
  double get lg => AppTheme.radiusLG;
  double get xl => AppTheme.radiusXL;
  double get xxl => AppTheme.radius2XL;
}

class _Spacing {
  double get xs => AppTheme.spaceXS;
  double get sm => AppTheme.spaceSM;
  double get md => AppTheme.spaceMD;
  double get lg => AppTheme.spaceLG;
  double get xl => AppTheme.spaceXL;
  double get xxl => AppTheme.space2XL;
  double get xxxl => AppTheme.space3XL;
}

class _Shadows {
  List<BoxShadow> get small => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  List<BoxShadow> get medium => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];

  List<BoxShadow> get large => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];
}

// Colors helper class
class _Colors {
  final ThemeData _theme;

  _Colors(this._theme);

  Color get primary => _theme.colorScheme.primary;
  Color get secondary => _theme.colorScheme.secondary;
  Color get error => _theme.colorScheme.error;
  Color get success => const Color(0xFF10B981);
  Color get warning => const Color(0xFFF59E0B);
  Color get info => const Color(0xFF3B82F6);
  Color get surface => _theme.colorScheme.surface;
  Color get onSurface => _theme.colorScheme.onSurface;
  Color get outline => _theme.colorScheme.outline;

  // Additional colors needed by professional screens
  Color get background => _theme.colorScheme.surface;
  Color get accent => _theme.colorScheme.secondary;
  Color get textSecondary =>
      _theme.colorScheme.onSurface.withValues(alpha: 0.7);
  Color get textPrimary => _theme.colorScheme.onSurface;
  Color get border => _theme.colorScheme.outline;
}

// Typography helper class
class _Typography {
  final TextTheme _textTheme;

  _Typography(this._textTheme);

  TextStyle get h1 => _textTheme.headlineLarge ?? const TextStyle();
  TextStyle get h2 => _textTheme.headlineMedium ?? const TextStyle();
  TextStyle get h3 => _textTheme.headlineSmall ?? const TextStyle();
  TextStyle get h4 => _textTheme.titleLarge ?? const TextStyle();
  TextStyle get h5 => _textTheme.titleMedium ?? const TextStyle();
  TextStyle get h6 => _textTheme.titleSmall ?? const TextStyle();
  TextStyle get body1 => _textTheme.bodyLarge ?? const TextStyle();
  TextStyle get body2 => _textTheme.bodyMedium ?? const TextStyle();
  TextStyle get caption => _textTheme.bodySmall ?? const TextStyle();
  TextStyle get button => _textTheme.labelLarge ?? const TextStyle();

  // Additional getters for professional screens
  TextStyle get headingLarge => _textTheme.headlineLarge ?? const TextStyle();
  TextStyle get headingMedium => _textTheme.headlineMedium ?? const TextStyle();
  TextStyle get headingSmall => _textTheme.headlineSmall ?? const TextStyle();
  TextStyle get bodyLarge => _textTheme.bodyLarge ?? const TextStyle();
  TextStyle get bodyMedium => _textTheme.bodyMedium ?? const TextStyle();
  TextStyle get bodySmall => _textTheme.bodySmall ?? const TextStyle();
  TextStyle get titleLarge => _textTheme.titleLarge ?? const TextStyle();
  TextStyle get titleMedium => _textTheme.titleMedium ?? const TextStyle();
  TextStyle get titleSmall => _textTheme.titleSmall ?? const TextStyle();
  TextStyle get labelMedium => _textTheme.labelMedium ?? const TextStyle();
  TextStyle get labelSmall => _textTheme.labelSmall ?? const TextStyle();
  TextStyle get displaySmall => _textTheme.displaySmall ?? const TextStyle();
}

// Gradients helper class
class _Gradients {
  LinearGradient get primary => const LinearGradient(
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  LinearGradient get secondary => const LinearGradient(
    colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  LinearGradient get success => const LinearGradient(
    colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  LinearGradient get light => AppTheme.lightGradient;
  LinearGradient get dark => AppTheme.darkGradient;
  LinearGradient get accent => secondary; // Add accent gradient
}
