import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

class ColorExtractor {
  static Future<List<Color>> extractColorsFromAsset(String assetPath) async {
    try {
      // Load the image from assets
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();

      // Decode the image
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;

      // Convert to byte data
      final ByteData? byteData = await image.toByteData();
      if (byteData == null) return [];

      final Uint8List pixels = byteData.buffer.asUint8List();
      final Map<int, int> colorCounts = {};

      // Sample pixels (every 4th pixel to avoid performance issues)
      for (int i = 0; i < pixels.length; i += 16) {
        if (i + 3 < pixels.length) {
          final int r = pixels[i];
          final int g = pixels[i + 1];
          final int b = pixels[i + 2];
          final int a = pixels[i + 3];

          // Skip transparent pixels
          if (a < 128) continue;

          final int colorValue = (a << 24) | (r << 16) | (g << 8) | b;
          colorCounts[colorValue] = (colorCounts[colorValue] ?? 0) + 1;
        }
      }

      // Get the most common colors
      final List<MapEntry<int, int>> sortedColors = colorCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Return top 5 colors
      return sortedColors.take(5).map((entry) => Color(entry.key)).toList();
    } catch (e) {
      print('Error extracting colors: $e');
      return [];
    }
  }

  static Future<Color> extractDominantColor(String assetPath) async {
    final colors = await extractColorsFromAsset(assetPath);
    return colors.isNotEmpty ? colors.first : Colors.grey;
  }
}
