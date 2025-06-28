import 'package:flutter/material.dart';
import '../services/predictive_ai_service_backup.dart' as pred;

class PredictiveAITab extends StatefulWidget {
  const PredictiveAITab({super.key});

  @override
  State<PredictiveAITab> createState() => _PredictiveAITabState();
}

class _PredictiveAITabState extends State<PredictiveAITab> {
  final TextEditingController _controller = TextEditingController();
  String? _selectedScenario;
  bool loading = false;
  dynamic predictionResult;

  final List<String> scenarios = [
    'Schedule Change',
    'Discipline Discussion',
    'Praise/Encouragement',
    'Logistics/Planning',
    'Conflict Resolution',
  ];

  final pred.PredictiveCoParentingAI _predictiveAI =
      pred.PredictiveCoParentingAI();

  Future<void> predictOutcome() async {
    setState(() {
      loading = true;
      predictionResult = null;
    });

    try {
      final message = _controller.text.trim();
      final context = pred.MessageContext(
        timeOfDay: DateTime.now(),
        topic: _selectedScenario ?? 'General',
      );
      final partnerProfile = pred.PartnerProfile(
        triggers: ['criticism', 'last minute changes'],
        attachmentStyle: pred.AttachmentStyle.secure,
        communicationStyle: pred.CommunicationStyle.assertive,
      );
      final history = pred.ConversationHistory(
        hasRecentConflicts: false,
        length: 10,
      );

      final result = await _predictiveAI.predictMessageOutcome(
        message,
        partnerProfile: partnerProfile,
        history: history,
        context: context,
      );

      setState(() {
        predictionResult = result;
        loading = false;
      });
    } catch (e) {
      setState(() {
        predictionResult = null;
        loading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Prediction failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B61FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.auto_graph,
                    color: Color(0xFF7B61FF),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Predictive AI',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedScenario,
                      items: scenarios
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedScenario = val),
                      decoration: InputDecoration(
                        labelText: 'Scenario',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _controller,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Enter your message',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: loading ? null : predictOutcome,
                      icon: const Icon(Icons.auto_graph),
                      label: const Text('Predict Outcome'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B61FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (loading)
              const Center(
                child: CircularProgressIndicator(color: Color(0xFF7B61FF)),
              ),
            if (predictionResult != null) ...[
              _buildResultCard(context, predictionResult),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, dynamic result) {
    final theme = Theme.of(context);

    // Adjust these fields to match your actual result object
    final outcome = result.outcome ?? 'Unknown';
    final risks = result.risks ?? <String>[];
    final suggestions = result.suggestions ?? <String>[];

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prediction Result',
              style: theme.textTheme.titleMedium?.copyWith(
                color: const Color(0xFF7B61FF),
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24, thickness: 1.2),
            Row(
              children: [
                const Icon(Icons.trending_up, color: Color(0xFF7B61FF)),
                const SizedBox(width: 8),
                Text(
                  'Predicted Outcome: ',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(outcome, style: theme.textTheme.bodyLarge),
              ],
            ),
            const SizedBox(height: 16),
            if (risks.isNotEmpty) ...[
              Text(
                'Risks',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 8),
              ...risks.map(
                (risk) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(risk)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (suggestions.isNotEmpty) ...[
              Text(
                'Suggestions',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 8),
              ...suggestions.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.tips_and_updates,
                        color: Color(0xFF7B61FF),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(s)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
