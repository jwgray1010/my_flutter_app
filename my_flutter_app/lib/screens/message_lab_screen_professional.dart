import 'package:flutter/material.dart';
import '../services/emotional_intelligence_coach_backup.dart' as eiq;
import '../services/predictive_ai_service_backup.dart' as pred;
import '../services/advanced_tone_analysis_service.dart';

class MessageLabScreenProfessional extends StatefulWidget {
  final String userStyle;
  const MessageLabScreenProfessional({super.key, required this.userStyle});

  @override
  State<MessageLabScreenProfessional> createState() =>
      _MessageLabScreenProfessionalState();
}

class _MessageLabScreenProfessionalState
    extends State<MessageLabScreenProfessional> {
  final TextEditingController _controller = TextEditingController();
  String? _selectedScenario;
  String? _selectedTone;
  String? _selectedSensitivity;
  String result = '';
  bool loading = false;
  bool _aiCoachingEnabled = true;

  final eiq.EmotionalIntelligenceCoach _eqCoach =
      eiq.EmotionalIntelligenceCoach();
  final pred.PredictiveCoParentingAI _predictiveAI =
      pred.PredictiveCoParentingAI();

  final List<String> scenarios = [
    'Schedule Change',
    'Discipline Discussion',
    'Praise/Encouragement',
    'Logistics/Planning',
    'Conflict Resolution',
  ];

  final List<Map<String, dynamic>> toneOptions = [
    {
      'value': 'Friendly',
      'icon': Icons.sentiment_very_satisfied_rounded,
      'color': Colors.green,
      'semanticsLabel': 'Friendly tone',
    },
    {
      'value': 'Neutral',
      'icon': Icons.sentiment_neutral_rounded,
      'color': Colors.blue,
      'semanticsLabel': 'Neutral tone',
    },
    {
      'value': 'Formal',
      'icon': Icons.business_center_rounded,
      'color': Colors.indigo,
      'semanticsLabel': 'Formal tone',
    },
    {
      'value': 'Casual',
      'icon': Icons.sentiment_satisfied_rounded,
      'color': Colors.orange,
      'semanticsLabel': 'Casual tone',
    },
  ];

  final List<Map<String, dynamic>> sensitivityOptions = [
    {
      'value': 'Low',
      'icon': Icons.sentiment_satisfied_rounded,
      'color': Colors.green,
      'semanticsLabel': 'Low sensitivity',
    },
    {
      'value': 'Medium',
      'icon': Icons.sentiment_neutral_rounded,
      'color': Colors.amber,
      'semanticsLabel': 'Medium sensitivity',
    },
    {
      'value': 'High',
      'icon': Icons.sentiment_dissatisfied_rounded,
      'color': Colors.red,
      'semanticsLabel': 'High sensitivity',
    },
  ];

  // --- Mapping helpers ---
  eiq.LearningStyle learningStyleFromString(String? tone) {
    switch (tone) {
      case 'Friendly':
        return eiq.LearningStyle.visual;
      case 'Formal':
        return eiq.LearningStyle.reading;
      case 'Casual':
        return eiq.LearningStyle.auditory;
      default:
        return eiq.LearningStyle.kinesthetic;
    }
  }

  eiq.AttachmentStyle toEiqAttachmentStyle(String? tone) {
    switch (tone) {
      case 'Friendly':
        return eiq.AttachmentStyle.secure;
      case 'Formal':
        return eiq.AttachmentStyle.avoidant;
      case 'Casual':
        return eiq.AttachmentStyle.anxious;
      default:
        return eiq.AttachmentStyle.disorganized;
    }
  }

  eiq.CommunicationStyle toEiqCommunicationStyle(String? tone) {
    switch (tone) {
      case 'Friendly':
        return eiq.CommunicationStyle.assertive;
      case 'Neutral':
        return eiq.CommunicationStyle.passive;
      case 'Formal':
        return eiq.CommunicationStyle.aggressive;
      case 'Casual':
        return eiq.CommunicationStyle.passiveAggressive;
      default:
        return eiq.CommunicationStyle.assertive;
    }
  }

  pred.CommunicationStyle predCommunicationStyleFromString(String? tone) {
    switch (tone) {
      case 'Friendly':
        return pred.CommunicationStyle.assertive;
      case 'Neutral':
        return pred.CommunicationStyle.passive;
      case 'Formal':
        return pred.CommunicationStyle.aggressive;
      case 'Casual':
        return pred.CommunicationStyle.passiveAggressive;
      default:
        return pred.CommunicationStyle.assertive;
    }
  }

  pred.AttachmentStyle toPredAttachmentStyle(eiq.AttachmentStyle style) {
    switch (style) {
      case eiq.AttachmentStyle.secure:
        return pred.AttachmentStyle.secure;
      case eiq.AttachmentStyle.anxious:
        return pred.AttachmentStyle.anxious;
      case eiq.AttachmentStyle.avoidant:
        return pred.AttachmentStyle.avoidant;
      case eiq.AttachmentStyle.disorganized:
        return pred.AttachmentStyle.disorganized;
    }
  }

  // --- Main Combined Analysis Logic ---
  Future<void> analyze() async {
    if (!_aiCoachingEnabled) {
      setState(() {
        result = 'AI Coaching is disabled. Enable it to analyze your message.';
      });
      return;
    }
    if (_controller.text.trim().isEmpty ||
        _selectedTone == null ||
        _selectedSensitivity == null ||
        _selectedScenario == null) {
      _showSnackBar('Please fill in all fields.', isError: true);
      return;
    }
    setState(() {
      loading = true;
      result = '';
    });

    try {
      final message = _controller.text.trim();

      final userProfile = eiq.UserEQProfile(
        learningStyle: learningStyleFromString(_selectedTone),
        strengths: [_selectedTone ?? 'Neutral'],
        growthAreas: [_selectedSensitivity ?? 'Medium'],
        attachmentStyle: toEiqAttachmentStyle(_selectedTone),
        communicationStyle: toEiqCommunicationStyle(_selectedTone),
      );

      final partnerProfile = pred.PartnerProfile(
        triggers: ['criticism', 'last minute changes'],
        attachmentStyle: pred.AttachmentStyle.secure,
        communicationStyle: pred.CommunicationStyle.assertive,
      );

      final context = eiq.CoParentingContext(
        topic: _selectedScenario!,
        timeOfDay: DateTime.now(),
      );

      final conversationHistory = pred.ConversationHistory(
        hasRecentConflicts: false,
        length: 10,
      );

      final messageContext = pred.MessageContext(
        timeOfDay: DateTime.now(),
        topic: _selectedScenario!,
      );

      // --- Combine all async calls ---
      final eqCoachFuture = _eqCoach.startCoachingSession(
        message,
        userProfile,
        context,
      );
      final predictiveAIFuture = _predictiveAI.predictMessageOutcome(
        message,
        partnerProfile: partnerProfile,
        history: conversationHistory,
        context: messageContext,
      );
      final toneAnalysisFuture = AdvancedToneAnalysisService().analyzeMessage(
        message,
      );

      final results = await Future.wait([
        eqCoachFuture,
        predictiveAIFuture,
        toneAnalysisFuture,
      ]);

      final eqSession = results[0];
      final outcomeAnalysis = results[1];
      final toneAnalysis = results[2];

      setState(() {
        result = _generateCombinedAnalysisResult(
          message: message,
          eqSession: eqSession,
          outcomeAnalysis: outcomeAnalysis,
          toneAnalysis: toneAnalysis,
          userProfile: userProfile,
          partnerProfile: partnerProfile,
        );
      });
    } catch (e) {
      setState(() {
        result =
            'An error occurred while analyzing your message: ${e.toString()}';
      });
      _showSnackBar('Analysis error occurred', isError: true);
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF7B61FF)),
              )
            : SingleChildScrollView(
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
                            Icons.psychology,
                            color: Color(0xFF7B61FF),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Advanced Messaging Lab',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: _aiCoachingEnabled,
                          onChanged: (val) =>
                              setState(() => _aiCoachingEnabled = val),
                          activeColor: const Color(0xFF7B61FF),
                        ),
                        const SizedBox(width: 4),
                        const Text('AI Coaching'),
                      ],
                    ),
                    const SizedBox(height: 24),
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
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: 'Your Message',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedTone,
                      items: toneOptions
                          .map<DropdownMenuItem<String>>(
                            (t) => DropdownMenuItem<String>(
                              value: t['value'] as String,
                              child: Row(
                                children: [
                                  Icon(
                                    t['icon'],
                                    color: t['color'],
                                    semanticLabel: t['semanticsLabel'],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(t['value']),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _selectedTone = val),
                      decoration: InputDecoration(
                        labelText: 'Tone',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedSensitivity,
                      items: sensitivityOptions
                          .map<DropdownMenuItem<String>>(
                            (s) => DropdownMenuItem<String>(
                              value: s['value'] as String,
                              child: Row(
                                children: [
                                  Icon(
                                    s['icon'],
                                    color: s['color'],
                                    semanticLabel: s['semanticsLabel'],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(s['value']),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedSensitivity = val),
                      decoration: InputDecoration(
                        labelText: 'Sensitivity',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: loading ? null : analyze,
                      icon: const Icon(Icons.psychology),
                      label: const Text('Analyze & Coach'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B61FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (result.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x147B61FF),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: SelectableText(
                          result,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF2D3748),
                            height: 1.6,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  String _generateCombinedAnalysisResult({
    required String message,
    required dynamic eqSession,
    required dynamic outcomeAnalysis,
    required dynamic toneAnalysis,
    required dynamic userProfile,
    required dynamic partnerProfile,
  }) {
    // Defensive: check for dimensions property
    String dimensionsString = 'N/A';
    try {
      if (toneAnalysis != null && toneAnalysis.dimensions != null) {
        dimensionsString = toneAnalysis.dimensions.toString();
      }
    } catch (_) {
      // Property does not exist, leave as 'N/A'
    }

    final toneSection =
        '''
**Tone Analysis**
- Overall Tone: ${toneAnalysis.overallTone ?? 'N/A'}
- Dimensions: $dimensionsString
- Suggestions: ${(toneAnalysis.suggestions as List?)?.join(', ') ?? 'N/A'}
''';

    final eqSection =
        '''
**EQ Coaching**
- Strengths: ${(userProfile.strengths as List?)?.join(', ') ?? 'N/A'}
- Growth Areas: ${(userProfile.growthAreas as List?)?.join(', ') ?? 'N/A'}
- Coaching: $eqSession
''';

    final aiSection =
        '''
**Predictive AI**
- Predicted Outcome: ${outcomeAnalysis.outcome ?? 'N/A'}
- Confidence: ${outcomeAnalysis.confidence != null ? (outcomeAnalysis.confidence * 100).toStringAsFixed(1) + '%' : 'N/A'}
- Risks: ${(outcomeAnalysis.risks as List?)?.join(', ') ?? 'N/A'}
- Suggestions: ${(outcomeAnalysis.suggestions as List?)?.join(', ') ?? 'N/A'}
''';

    return '''
**Message:**  \n$message

$toneSection
$eqSection
$aiSection
''';
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // --- Feedback Helper ---
  String attachmentStyleToneFeedback({
    required pred.AttachmentStyle senderStyle,
    required pred.AttachmentStyle receiverStyle,
    required String tone,
  }) {
    if (senderStyle == pred.AttachmentStyle.secure) {
      return "Your secure attachment style helps you communicate openly and directly. Using a ' 27$tone' tone is likely to be received well, especially by secure or anxious partners.";
    }
    if (senderStyle == pred.AttachmentStyle.anxious) {
      if (receiverStyle == pred.AttachmentStyle.avoidant) {
        return "As someone with an anxious attachment style, using a ' 27$tone' tone may come across as needy to an avoidant partner. Consider giving space and using a neutral or friendly tone.";
      }
      if (receiverStyle == pred.AttachmentStyle.anxious) {
        return "Both you and your partner have anxious tendencies. Using a friendly or reassuring tone can help reduce mutual anxiety.";
      }
      return "Your anxious attachment style may lead you to seek reassurance. Be mindful of over-texting or overanalyzing responses.";
    }
    if (senderStyle == pred.AttachmentStyle.avoidant) {
      if (receiverStyle == pred.AttachmentStyle.anxious) {
        return "Your avoidant style and a ' 27$tone' tone may feel distant to an anxious partner. Try to be a bit more responsive and open to support their need for connection.";
      }
      return "Your avoidant attachment style values independence. Using a formal or brief tone is natural for you, but consider adding warmth if your partner is more anxious or secure.";
    }
    if (senderStyle == pred.AttachmentStyle.disorganized) {
      return "Disorganized attachment can lead to mixed signals. Try to be consistent with your tone and responses to avoid confusing your partner.";
    }
    return "";
  }
}
