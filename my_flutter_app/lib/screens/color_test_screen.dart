import 'package:flutter/material.dart';
import '../widgets/tone_indicator.dart';

/// This screen demonstrates the research-backed color mapping for tone/communication/attachment styles:
/// - Green: Assertive/Secure (Clear/Good Tone)
/// - Yellow: Passive (Caution Tone)
/// - Red: Aggressive/Passive-Aggressive (Alert Tone)
/// - Gray: Unknown/Neutral (Neutral Tone)
class ColorTestScreen extends StatelessWidget {
  const ColorTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Color Test'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildColorTest(
              'Clear/Good Tone (Assertive/Secure)',
              ToneStatus.clear,
              'Green: Healthy, clear, respectful communication',
            ),
            _buildColorTest(
              'Caution Tone (Passive)',
              ToneStatus.caution,
              'Yellow: Room for improvement, indirect or hesitant',
            ),
            _buildColorTest(
              'Alert Tone (Aggressive/Passive-Aggressive)',
              ToneStatus.alert,
              'Red: High risk for conflict or misunderstanding',
            ),
            _buildColorTest(
              'Neutral Tone (Unknown/Gray)',
              ToneStatus.neutral,
              'Gray: Neutral, unclear, or not enough data',
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a color test card with research-backed label and explanation.
  Widget _buildColorTest(String label, ToneStatus status, String explanation) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ToneIndicator(
          status: status,
          size: 80,
          showPulse: status == ToneStatus.alert,
        ),
        const SizedBox(height: 10),
        Text(
          'Expected: ${_getExpectedColor(status)}',
          style: TextStyle(
            color: _getColorForStatus(status),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          explanation,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Maps ToneStatus to color label for display.
  String _getExpectedColor(ToneStatus status) {
    switch (status) {
      case ToneStatus.clear:
        return 'Bright Green';
      case ToneStatus.caution:
        return 'Bright Yellow';
      case ToneStatus.alert:
        return 'Bright Red';
      case ToneStatus.neutral:
        return 'Dark Gray';
    }
  }

  /// Maps ToneStatus to research-backed color.
  Color _getColorForStatus(ToneStatus status) {
    switch (status) {
      case ToneStatus.clear:
        return const Color(0xFF00E676); // Bright Green
      case ToneStatus.caution:
        return const Color(0xFFFFD600); // Bright Yellow
      case ToneStatus.alert:
        return const Color(0xFFFF1744); // Bright Red
      case ToneStatus.neutral:
        return const Color(0xFF757575); // Darker Gray
    }
  }
}
