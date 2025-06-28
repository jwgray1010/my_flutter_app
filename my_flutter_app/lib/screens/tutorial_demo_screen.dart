import 'package:flutter/material.dart';
import 'tone_indicator_tutorial_screen.dart';

class TutorialDemoScreen extends StatelessWidget {
  const TutorialDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutorial Demo'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      // To use your app's gradient, wrap Center with a Container and set decoration
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Tone Indicator Tutorial Demo',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'This tutorial shows users how the tone indicator works\nwith iPhone message examples showing different tones.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ToneIndicatorTutorialScreen(
                      onComplete: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Tutorial completed! In the real app, this would navigate to keyboard setup.',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.play_circle_fill, semanticLabel: 'Start Tutorial'),
              label: const Text(
                'Start Tutorial',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Navigation Flow:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '1. Questionnaire/Personality Test',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text(
                    '2. Personality Results',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text('3. Premium Screen', style: TextStyle(fontSize: 14)),
                  Text(
                    '4. → Tone Indicator Tutorial ←',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    '5. Keyboard Setup/Intro',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text('6. Main App', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
