import 'package:flutter/material.dart';

class VoiceCommandsHelpScreen extends StatelessWidget {
  const VoiceCommandsHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voice Commands')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _Section(
            title: 'Transport',
            lines: [
              'play / start / resume',
              'pause / stop',
            ],
          ),
          _Section(
            title: 'Measure Navigation',
            lines: [
              'measure 32',
              'from measure 32',
              'go to measure 32',
              'bar 32',
              'letter A / B / C',
              'back two measures / back 2',
              'back one measure',
              'forward two measures / forward 2',
            ],
          ),
          _Section(
            title: 'Tempo',
            lines: [
              'slower',
              'faster',
              'tempo 70',
              'set tempo to 80',
              'seventy percent',
              'seventy five percent',
            ],
          ),
          _Section(
            title: 'Loop',
            lines: [
              'loop',
              'loop this',
              'set loop A',
              'set loop B',
              'loop measures 48 to 56',
              'clear loop',
            ],
          ),
          _Section(
            title: 'Parts / Mixing',
            lines: [
              'all',
              'piano / piano on / piano off',
              'sopranos',
              'altos',
              'tenors',
              'basses',
              'sopranos and altos',
              'tenors and basses',
              'only altos / altos only',
            ],
          ),
          _Section(
            title: 'Starting Pitch',
            lines: [
              'starting pitch',
              'give me starting pitches',
              'give pitches',
              'play starting pitches',
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Tip: hold the MIC button while speaking, then release to process.',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.lines,
  });

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...lines.map(
              (line) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('- $line', style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

