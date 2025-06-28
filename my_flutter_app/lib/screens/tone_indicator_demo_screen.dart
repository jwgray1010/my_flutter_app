import 'package:flutter/material.dart';
import '../widgets/message_composer.dart';
import '../widgets/tone_indicator.dart';

class ToneIndicatorDemoScreen extends StatefulWidget {
  const ToneIndicatorDemoScreen({super.key});

  @override
  State<ToneIndicatorDemoScreen> createState() =>
      _ToneIndicatorDemoScreenState();
}

class _ToneIndicatorDemoScreenState extends State<ToneIndicatorDemoScreen> {
  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _addDemoMessages();
  }

  void _addDemoMessages() {
    // Add some demo messages to show different tone statuses
    _messages.addAll([
      {
        'text': 'Please let me know when you have a moment to chat.',
        'status': ToneStatus.clear,
        'time': '10:30 AM',
      },
      {
        'text': 'You need to fix this ASAP! This is unacceptable!',
        'status': ToneStatus.alert,
        'time': '10:35 AM',
      },
      {
        'text': 'I need this done by tomorrow. It\'s urgent.',
        'status': ToneStatus.caution,
        'time': '10:40 AM',
      },
      {
        'text': 'Hello there!',
        'status': ToneStatus.neutral,
        'time': '10:45 AM',
      },
    ]);
  }

  void _onMessageSent(String message) {
    // Simple tone analysis for demo
    ToneStatus status = ToneStatus.neutral;

    final lowerMessage = message.toLowerCase();
    if (lowerMessage.contains(RegExp(r'\b(stupid|hate|angry|damn)\b'))) {
      status = ToneStatus.alert;
    } else if (lowerMessage.contains(
      RegExp(r'\b(must|should|urgent|asap)\b'),
    )) {
      status = ToneStatus.caution;
    } else if (lowerMessage.contains(
      RegExp(r'\b(please|thank|appreciate|sorry)\b'),
    )) {
      status = ToneStatus.clear;
    }

    setState(() {
      _messages.add({
        'text': message,
        'status': status,
        'time': _formatCurrentTime(),
      });
    });
  }

  String _formatCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : now.hour;
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tone Indicator Demo'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset('assets/logo_icon.png', width: 32, height: 32),
          ),
        ),
      ),
      body: Column(
        children: [
          // Demo explanation
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
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
                    Icon(Icons.info_outline, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Tone Indicator Legend',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildLegendItem(
                  ToneStatus.clear,
                  'Clear - Positive, friendly tone',
                  theme,
                  semanticLabel: 'Clear tone',
                ),
                _buildLegendItem(
                  ToneStatus.caution,
                  'Caution - May need adjustment',
                  theme,
                  semanticLabel: 'Caution tone',
                ),
                _buildLegendItem(
                  ToneStatus.alert,
                  'Alert - Potentially problematic',
                  theme,
                  semanticLabel: 'Alert tone',
                ),
                _buildLegendItem(
                  ToneStatus.neutral,
                  'Neutral - Standard tone',
                  theme,
                  semanticLabel: 'Neutral tone',
                ),
              ],
            ),
          ),

          // Divider for visual separation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              color: theme.colorScheme.primary.withOpacity(0.15),
              thickness: 1,
              height: 0,
            ),
          ),

          // Messages list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ToneIndicator(
                            status: message['status'],
                            size: 24,
                            showPulse: message['status'] == ToneStatus.alert,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              message['text'],
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message['time'],
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Message composer
          MessageComposer(
            onMessageSent: _onMessageSent,
            placeholder:
                'Try typing different messages to see tone analysis...',
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(ToneStatus status, String description, ThemeData theme, {String? semanticLabel}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          ToneIndicator(status: status, size: 20),
          ToneIndicator(status: status, size: 20),
          Expanded(
            child: Text(description, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  String _getToneSemanticLabel(ToneStatus status) {
    switch (status) {
      case ToneStatus.clear:
        return 'Clear tone';
      case ToneStatus.caution:
        return 'Caution tone';
      case ToneStatus.alert:
        return 'Alert tone';
      case ToneStatus.neutral:
      default:
        return 'Neutral tone';
    }
  }
}
