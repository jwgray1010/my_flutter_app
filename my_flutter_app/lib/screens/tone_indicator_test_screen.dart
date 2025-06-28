import 'package:flutter/material.dart';
import '../widgets/tone_indicator.dart';

class ToneIndicatorTestScreen extends StatelessWidget {
  const ToneIndicatorTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tone Indicator Test'),
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset('assets/logo_icon.png', width: 32, height: 32),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tone Indicator Examples',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            _buildToneExample(
              context,
              ToneStatus.clear,
              'Clear/Good Tone',
              'Indicates positive, friendly communication',
              '"Thank you for your help!"',
              semanticLabel: 'Clear tone',
              theme: theme,
            ),

            const SizedBox(height: 20),

            _buildToneExample(
              context,
              ToneStatus.caution,
              'Caution Tone',
              'May need adjustment, slightly direct',
              '"You should fix this immediately"',
              semanticLabel: 'Caution tone',
              theme: theme,
            ),

            const SizedBox(height: 20),

            _buildToneExample(
              context,
              ToneStatus.alert,
              'Alert Tone',
              'Potentially problematic language',
              '"This is ridiculous and stupid!"',
              showPulse: true,
              semanticLabel: 'Alert tone',
              theme: theme,
            ),

            const SizedBox(height: 20),

            _buildToneExample(
              context,
              ToneStatus.neutral,
              'Neutral Tone',
              'Standard, balanced communication',
              '"Can you check this please?"',
              semanticLabel: 'Neutral tone',
              theme: theme,
            ),

            const Spacer(),

            // Divider for clarity
            Divider(
              color: theme.colorScheme.primary.withOpacity(0.15),
              thickness: 1,
              height: 32,
            ),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'How it works',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'The Unsaid logo changes color based on your message tone:\n'
                    '• Green: Positive, friendly tone\n'
                    '• Yellow: Direct or urgent tone\n'
                    '• Red: Potentially harsh tone (with pulse animation)\n'
                    '• Gray: Neutral tone',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToneExample(
    BuildContext context,
    ToneStatus status,
    String title,
    String description,
    String example, {
    bool showPulse = false,
    String? semanticLabel,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          ToneIndicator(
            status: status,
            size: 32,
            showPulse: showPulse,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Example: $example',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
