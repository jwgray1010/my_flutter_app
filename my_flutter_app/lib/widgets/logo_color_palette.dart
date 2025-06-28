import 'package:flutter/material.dart';
import '../utils/color_extractor.dart';

class LogoColorPalette extends StatefulWidget {
  final String assetPath;
  final Function(List<Color>)? onColorsExtracted;

  const LogoColorPalette({
    super.key,
    this.assetPath = 'assets/logo_icon.png',
    this.onColorsExtracted,
  });

  @override
  State<LogoColorPalette> createState() => _LogoColorPaletteState();
}

class _LogoColorPaletteState extends State<LogoColorPalette> {
  List<Color> extractedColors = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _extractColors();
  }

  Future<void> _extractColors() async {
    try {
      final colors = await ColorExtractor.extractColorsFromAsset(
        widget.assetPath,
      );
      setState(() {
        extractedColors = colors;
        isLoading = false;
      });

      if (widget.onColorsExtracted != null) {
        widget.onColorsExtracted!(colors);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error extracting colors: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Display the logo
        Image.asset(widget.assetPath, height: 100, width: 100),
        const SizedBox(height: 16),

        // Display extracted colors
        if (extractedColors.isNotEmpty) ...[
          const Text(
            'Extracted Colors:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: extractedColors
                .map(
                  (color) => Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Center(
                      child: Text(
                        '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
                        style: TextStyle(
                          fontSize: 8,
                          color: color.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ] else
          const Text('No colors extracted'),
      ],
    );
  }
}
