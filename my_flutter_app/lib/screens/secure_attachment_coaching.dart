import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SecureAttachmentCoachingPage extends StatefulWidget {
  const SecureAttachmentCoachingPage({super.key});

  @override
  State<SecureAttachmentCoachingPage> createState() =>
      _SecureAttachmentCoachingPageState();
}

class _SecureAttachmentCoachingPageState
    extends State<SecureAttachmentCoachingPage> {
  final TextEditingController _journalController = TextEditingController();

  @override
  void dispose() {
    _journalController.dispose();
    super.dispose();
  }

  void _launchLearnMore() async {
    const url =
        'https://www.attachmentproject.com/learn-more-about-attachment/';
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  Widget _buildStep(int number, String title, List<String> bullets,
      {Color? color}) {
    color ??= const Color(0xFF7B61FF);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Visual step number
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                ...bullets.map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text('• $b'),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Attachment Coaching'),
        backgroundColor: const Color(0xFF7B61FF),
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            Text(
              "How to Become More Securely Attached",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Secure attachment is built through consistent, caring actions. Here are research-backed steps to help you move toward secure attachment:",
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),

            // Steps with visual numbers
            _buildStep(
              4,
              "Set Healthy Boundaries",
              [
                "Clearly express your needs and boundaries respectfully.",
                "Respect your partner's boundaries to build mutual trust.",
              ],
            ),
            _buildStep(
              5,
              "Practice Self-Care and Self-Compassion",
              [
                "Develop self-awareness and notice when you're reacting from insecurity.",
                "Practice mindfulness and be patient with yourself as you grow.",
              ],
            ),
            _buildStep(
              6,
              "Seek Support",
              [
                "Consider therapy with an attachment-informed professional.",
                "Join support groups to connect and learn with others on the same journey.",
              ],
            ),
            const SizedBox(height: 24),

            // Reflection Journal
            Text(
              "Reflection Journal",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Write your thoughts, feelings, or insights as you work on secure attachment. Reflect on boundaries, self-care, or support you might seek.",
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x147B61FF),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _journalController,
                maxLines: 6,
                decoration: const InputDecoration.collapsed(
                  hintText: "Start journaling here...",
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Learn More Button
            Center(
              child: ElevatedButton.icon(
                onPressed: _launchLearnMore,
                icon: const Icon(Icons.open_in_new, semanticLabel: 'Learn More'),
                label: const Text("Learn More About Attachment"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B61FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Remember: Secure attachment is built over time. Be patient and compassionate with yourself as you learn and grow.",
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
