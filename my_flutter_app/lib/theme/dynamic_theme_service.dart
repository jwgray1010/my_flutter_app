import 'package:flutter/material.dart';
import '../utils/color_extractor.dart';

class DynamicThemeService {
  static Future<ThemeData> createThemeFromLogo() async {
    // Extract colors from your logo
    final colors = await ColorExtractor.extractColorsFromAsset(
      'assets/logo_icon.png',
    );

    Color primaryColor = const Color(0xFFD9B6B0); // fallback
    Color backgroundColor = const Color(0xFFF3F0FA); // fallback

    if (colors.isNotEmpty) {
      primaryColor = colors.first;
      if (colors.length > 1) {
        backgroundColor = colors[1].withOpacity(0.1);
      }
    }

    return ThemeData(
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        background: backgroundColor,
        primary: primaryColor,
        secondary: primaryColor,
      ),
      textTheme: const TextTheme().apply(
        bodyColor: Colors.black87,
        displayColor: Colors.black87,
      ),
      useMaterial3: true,
    );
  }
}
