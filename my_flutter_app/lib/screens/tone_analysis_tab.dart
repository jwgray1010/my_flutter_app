import 'package:flutter/material.dart';
import '../services/advanced_tone_analysis_service.dart';

class ToneAnalysisTab extends StatefulWidget {
  const ToneAnalysisTab({super.key});

  @override
  State<ToneAnalysisTab> createState() => _ToneAnalysisTabState();
}

class _ToneAnalysisTabState extends State<ToneAnalysisTab> {
  final TextEditingController _controller = TextEditingController();
  dynamic analysisResult;
  bool loading = false;

  Future<void> analyzeTone() async {
    setState(() {
      loading = true;
      analysisResult = null;
    });

    final service = AdvancedToneAnalysisService();
    final result = await service.analyzeMessage(_controller.text);

    setState(() {
      analysisResult = result;
      loading = false;
    });
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
                    Icons.graphic_eq,
                    color: Color(0xFF7B61FF),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Advanced Tone Analysis',
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
                    TextField(
                      controller: _controller,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Enter a message to analyze',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: loading ? null : analyzeTone,
                      icon: const Icon(Icons.analytics),
                      label: const Text('Analyze Tone'),
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
            if (analysisResult != null) ...[
              _buildResultCard(context, analysisResult),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, dynamic result) {
    final theme = Theme.of(context);

    final overallTone = result.overallTone ?? 'Unknown';
    final dimensions = result.dimensions ?? <String, dynamic>{};
    final suggestions = result.suggestions ?? <String>[];
    final indicators = result.indicators ?? <String, dynamic>{};

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
              'Analysis Result',
              style: theme.textTheme.titleMedium?.copyWith(
                color: const Color(0xFF7B61FF),
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24, thickness: 1.2),
            Row(
              children: [
                const Icon(Icons.emoji_objects, color: Color(0xFF7B61FF)),
                const SizedBox(width: 8),
                Text(
                  'Overall Tone: ',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(overallTone, style: theme.textTheme.bodyLarge),
              ],
            ),
            const SizedBox(height: 16),
            if (dimensions.isNotEmpty) ...[
              Text(
                'Tone Dimensions',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 8),
              ...dimensions.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 8, color: Colors.grey.shade400),
                      const SizedBox(width: 8),
                      Text(
                        '${entry.key}: ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value.toString(),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (indicators.isNotEmpty) ...[
              Text(
                'Emotional Indicators',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 8),
              ...indicators.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        Icons.bubble_chart,
                        size: 16,
                        color: Colors.blueGrey.shade300,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${entry.key}: ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value.toString(),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
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
