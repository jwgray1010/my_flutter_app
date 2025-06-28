import 'package:flutter/material.dart';
import 'tone_indicator.dart';

class MessageComposer extends StatefulWidget {
  final Function(String)? onMessageSent;
  final String? placeholder;

  const MessageComposer({
    super.key,
    this.onMessageSent,
    this.placeholder = 'Type your message...',
  });

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  final TextEditingController _textController = TextEditingController();
  ToneStatus _currentStatus = ToneStatus.neutral;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _textController.text.toLowerCase();

    // Simple tone analysis
    ToneStatus newStatus = ToneStatus.neutral;
    if (text.contains(RegExp(r'\b(stupid|hate|angry|damn)\b'))) {
      newStatus = ToneStatus.alert;
    } else if (text.contains(RegExp(r'\b(must|should|urgent|asap)\b'))) {
      newStatus = ToneStatus.caution;
    } else if (text.contains(RegExp(r'\b(please|thank|appreciate|sorry)\b'))) {
      newStatus = ToneStatus.clear;
    }

    if (newStatus != _currentStatus) {
      setState(() {
        _currentStatus = newStatus;
      });
    }
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      widget.onMessageSent?.call(text);
      _textController.clear();
      setState(() {
        _currentStatus = ToneStatus.neutral;
      });
    }
  }

  void _showToneDetails() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ToneIndicator(status: _currentStatus, size: 32),
                const SizedBox(width: 12),
                Text(
                  'Tone Analysis',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _getToneDescription(_currentStatus),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getToneDescription(ToneStatus status) {
    switch (status) {
      case ToneStatus.clear:
        return 'Your message has a positive, friendly tone.';
      case ToneStatus.caution:
        return 'Your message may come across as direct or urgent.';
      case ToneStatus.alert:
        return 'Your message might be perceived as harsh or aggressive.';
      case ToneStatus.neutral:
        return 'Your message has a neutral tone.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Tone indicator (logo with dynamic color)
            GestureDetector(
              onTap: _showToneDetails,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: ToneIndicator(
                  status: _currentStatus,
                  size: 28,
                  showPulse: _currentStatus == ToneStatus.alert,
                  onTap: _showToneDetails,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Text input
            Expanded(
              child: TextField(
                controller: _textController,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: widget.placeholder,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Send button
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _textController.text.trim().isNotEmpty
                    ? _sendMessage
                    : null,
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
