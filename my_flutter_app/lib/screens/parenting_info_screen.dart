import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ParentingInfoScreen extends StatefulWidget {
  const ParentingInfoScreen({super.key});

  @override
  State<ParentingInfoScreen> createState() => _ParentingInfoScreenState();
}

class _ParentingInfoScreenState extends State<ParentingInfoScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _answer;
  bool _loading = false;

  Future<void> _askAI(String question) async {
    setState(() {
      _loading = true;
      _answer = null;
    });
    // TODO: Replace this with your actual GPT AI service call
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _answer =
          'This is a sample AI answer to: "$question"\n\n(Integrate your GPT service here for real answers.)';
      _loading = false;
    });
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parenting Info'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Ask Parenting AI',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Type your parenting question...',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (q) {
                    if (q.trim().isNotEmpty) _askAI(q.trim());
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _loading || _controller.text.trim().isEmpty
                    ? null
                    : () => _askAI(_controller.text.trim()),
                child: _loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Ask'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_answer != null)
            Card(
              color: theme.colorScheme.surfaceContainerHighest,
              margin: const EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_answer!, style: theme.textTheme.bodyLarge),
              ),
            ),
          const Divider(height: 40),
          Text(
            'Need Professional Help?',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.local_hospital),
            label: const Text('Find Online Therapy (BetterHelp)'),
            onPressed: () => _launchUrl('https://www.betterhelp.com/'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.gavel),
            label: const Text('Find Legal Counseling (Rocket Lawyer)'),
            onPressed: () => _launchUrl('https://www.rocketlawyer.com/'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          ),
          const SizedBox(height: 32),
          Text(
            'Remember: You are not alone. Reaching out for help is a sign of strength, not weakness.',
            style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
