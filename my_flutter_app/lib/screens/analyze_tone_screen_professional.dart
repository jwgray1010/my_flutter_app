import 'package:flutter/material.dart';
import '../services/emotional_intelligence_coach_backup.dart' as eiq;
import '../services/predictive_ai_service_backup.dart' as pred;

class AnalyzeToneScreenProfessional extends StatefulWidget {
  const AnalyzeToneScreenProfessional({super.key});

  @override
  State<AnalyzeToneScreenProfessional> createState() =>
      _AnalyzeToneScreenProfessionalState();
}

class _AnalyzeToneScreenProfessionalState
    extends State<AnalyzeToneScreenProfessional>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  String? _selectedTone;
  String? _selectedSensitivity;
  String result = '';
  bool loading = false;

  // AI Services
  final eiq.EmotionalIntelligenceCoach _eqCoach =
      eiq.EmotionalIntelligenceCoach();
  final pred.PredictiveCoParentingAI _predictiveAI =
      pred.PredictiveCoParentingAI();

  final List<Map<String, dynamic>> toneOptions = [
    {
      'value': 'Friendly',
      'icon': Icons.sentiment_very_satisfied_rounded,
      'color': Colors.green,
    },
    {
      'value': 'Neutral',
      'icon': Icons.sentiment_neutral_rounded,
      'color': Colors.blue,
    },
    {
      'value': 'Formal',
      'icon': Icons.business_center_rounded,
      'color': Colors.indigo,
    },
    {
      'value': 'Casual',
      'icon': Icons.sentiment_satisfied_rounded,
      'color': Colors.orange,
    },
  ];

  final List<Map<String, dynamic>> sensitivityOptions = [
    {
      'value': 'Low',
      'icon': Icons.sentiment_satisfied_rounded,
      'color': Colors.green,
    },
    {
      'value': 'Medium',
      'icon': Icons.sentiment_neutral_rounded,
      'color': Colors.orange,
    },
    {
      'value': 'High',
      'icon': Icons.sentiment_very_dissatisfied_rounded,
      'color': Colors.red,
    },
  ];

  late AnimationController _resultController;
  late Animation<double> _resultAnimation;

  @override
  void initState() {
    super.initState();
    _resultController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _resultAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _resultController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  Future<void> analyze() async {
    if (_messageController.text.trim().isEmpty ||
        _selectedTone == null ||
        _selectedSensitivity == null) {
      _showSnackBar('Please fill in all fields.', isError: true);
      return;
    }

    setState(() {
      loading = true;
      result = '';
    });
    _resultController.reset();

    try {
      final message = _messageController.text.trim();

      // Create user profile based on UI selections using correct data structure
      final userProfile = eiq.UserEQProfile(
        learningStyle: _mapToneToLearningStyle(_selectedTone!),
        strengths: _getToneBasedStrengths(_selectedTone!),
        growthAreas: _getSensitivityBasedGrowthAreas(_selectedSensitivity!),
        attachmentStyle: _convertPredToEIQAttachmentStyle(pred.AttachmentStyle.secure), // TODO: Replace with actual user selection if available
        communicationStyle: _convertPredToEIQCommunicationStyle(_mapToneToCommunicationStyle(_selectedTone!)),
      );

      // Create co-parenting context using correct structure
      final context = eiq.CoParentingContext(
        topic: 'general communication',
        timeOfDay: DateTime.now(),
      );

      // Create partner profile for predictive analysis
      final partnerProfile = pred.PartnerProfile(
        triggers: ['last minute changes', 'criticism'],
        attachmentStyle: pred.AttachmentStyle.secure,
        communicationStyle: _mapToneToCommunicationStyle(_selectedTone!),
      );

      // Create conversation history
      final conversationHistory = pred.ConversationHistory(
        hasRecentConflicts: false,
        length: 10,
      );

      // Create message context
      final messageContext = pred.MessageContext(
        timeOfDay: DateTime.now(),
        topic: 'general',
      );

      // Get comprehensive AI analysis
      final results = await Future.wait([
        _eqCoach.startCoachingSession(message, userProfile, context),
        _predictiveAI.predictMessageOutcome(
          message,
          history: conversationHistory,
          partnerProfile: partnerProfile,
          context: messageContext,
        ),
      ]);

      final eqSession = results[0] as eiq.EQCoachingSession;
      final outcomeAnalysis = results[1] as pred.ConversationOutcomePrediction;

      // Generate comprehensive analysis result
      final analysisResult = _generateAdvancedAnalysisResult(
        message,
        eqSession,
        outcomeAnalysis,
        userProfile,
        _mapToneToCommunicationStyle(_selectedTone!),
      );

      setState(() {
        result = analysisResult;
      });
      _resultController.forward();
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

  // Helper methods for mapping UI selections to AI service enums/types
  eiq.LearningStyle _mapToneToLearningStyle(String tone) {
    switch (tone.toLowerCase()) {
      case 'friendly':
        return eiq.LearningStyle.visual;
      case 'neutral':
        return eiq.LearningStyle.auditory;
      case 'formal':
        return eiq.LearningStyle.reading;
      case 'casual':
        return eiq.LearningStyle.kinesthetic;
      default:
        return eiq.LearningStyle.visual;
    }
  }

  // Research-aligned mapping for communication style
  pred.CommunicationStyle _mapToneToCommunicationStyle(String tone) {
    switch (tone.toLowerCase()) {
      case 'friendly':
        return pred.CommunicationStyle.assertive;
      case 'neutral':
        return pred.CommunicationStyle.passive;
      case 'formal':
        return pred.CommunicationStyle.aggressive;
      case 'casual':
        return pred.CommunicationStyle.passiveAggressive;
      default:
        return pred.CommunicationStyle.assertive;
    }
  }

  List<String> _getToneBasedStrengths(String tone) {
    switch (tone.toLowerCase()) {
      case 'friendly':
        return ['empathy', 'warmth', 'relationship building'];
      case 'neutral':
        return ['objectivity', 'clarity', 'professionalism'];
      case 'formal':
        return ['structure', 'respect', 'clear boundaries'];
      case 'casual':
        return ['approachability', 'authenticity', 'ease of communication'];
      default:
        return ['balanced communication'];
    }
  }

  List<String> _getSensitivityBasedGrowthAreas(String sensitivity) {
    switch (sensitivity.toLowerCase()) {
      case 'low':
        return ['emotional awareness', 'sensitivity to partner needs'];
      case 'medium':
        return ['emotional regulation', 'stress management'];
      case 'high':
        return ['emotional resilience', 'conflict de-escalation'];
      default:
        return ['emotional balance'];
    }
  }

  // Color mapping for communication style
  Color _getToneColor(pred.CommunicationStyle style) {
    switch (style) {
      case pred.CommunicationStyle.assertive:
        return Colors.green;
      case pred.CommunicationStyle.passive:
        return Colors.yellow;
      case pred.CommunicationStyle.aggressive:
      case pred.CommunicationStyle.passiveAggressive:
        return Colors.red;
    }
  }

  String _generateAdvancedAnalysisResult(
    String message,
    eiq.EQCoachingSession eqSession,
    pred.ConversationOutcomePrediction outcomeAnalysis,
    eiq.UserEQProfile userProfile,
    pred.CommunicationStyle commStyle,
  ) {
    final buffer = StringBuffer();

    // Add color indicator based on communication style
    final color = _getToneColor(commStyle);
    String colorLabel;
    if (color == Colors.green) {
      colorLabel = "🟢 Assertive (Healthy, clear, respectful)";
    } else if (color == Colors.yellow) {
      colorLabel = "🟡 Passive (Room for improvement)";
    } else if (color == Colors.red) {
      colorLabel = commStyle == pred.CommunicationStyle.aggressive
          ? "🔴 Aggressive (High risk for conflict)"
          : "🔴 Passive-Aggressive (High risk for misunderstanding)";
    } else {
      colorLabel = "⚪️ Neutral/Unknown";
    }

    buffer.writeln('🎯 **COMPREHENSIVE TONE & OUTCOME ANALYSIS**\n');
    buffer.writeln('**COMMUNICATION STYLE:** $colorLabel\n');

    // Message Quality Assessment
    buffer.writeln('**MESSAGE ASSESSMENT:**');
    buffer.writeln(
      '• Success Probability: ${(outcomeAnalysis.successProbability * 100).toStringAsFixed(1)}%',
    );
    buffer.writeln(
      '• Confidence Level: ${(outcomeAnalysis.confidenceLevel * 100).toStringAsFixed(1)}%',
    );
    buffer.writeln(
      '• Risk Level: ${outcomeAnalysis.riskFactors.isNotEmpty ? "⚠️ Moderate" : "✅ Low"}',
    );
    buffer.writeln();

    // Emotional Intelligence Insights
    buffer.writeln('**EMOTIONAL INTELLIGENCE INSIGHTS:**');
    buffer.writeln(
      '• Current EQ State: ${_formatEQState(eqSession.currentState)}',
    );
    buffer.writeln(
      '• Emotional Regulation: ${_assessRegulationFromMessage(message)}',
    );
    buffer.writeln('• Communication Style: ${commStyle.name.toUpperCase()}');
    buffer.writeln();

    // Predictive Analysis
    buffer.writeln('🔮 **PREDICTIVE ANALYSIS:**');
    if (outcomeAnalysis.predictedPartnerReactions.isNotEmpty) {
      buffer.writeln(
        '• Likely Partner Response: ${outcomeAnalysis.predictedPartnerReactions.first}',
      );
    }
    buffer.writeln(
      '• Child Impact: ${_formatChildImpact(outcomeAnalysis.childImpactPrediction)}',
    );
    buffer.writeln(
      '• Optimal Timing: ${_formatOptimalTiming(outcomeAnalysis.optimalTiming)}',
    );
    buffer.writeln();

    // Personalized Recommendations
    buffer.writeln('💡 **PERSONALIZED RECOMMENDATIONS:**');
    for (var recommendation in eqSession.personalizedCoaching.recommendations) {
      buffer.writeln('• $recommendation');
    }
    buffer.writeln('• Priority: ${eqSession.personalizedCoaching.priority}');
    buffer.writeln();

    // Alternative Suggestions
    if (outcomeAnalysis.recommendedAlternatives.isNotEmpty) {
      buffer.writeln('✨ **SUGGESTED IMPROVEMENTS:**');
      for (var alternative in outcomeAnalysis.recommendedAlternatives.take(2)) {
        buffer.writeln('• $alternative');
      }
      buffer.writeln();
    }

    // Skill Development
    buffer.writeln('📈 **SKILL DEVELOPMENT:**');
    buffer.writeln('• Strengths: ${userProfile.strengths.join(", ")}');
    buffer.writeln('• Growth Areas: ${userProfile.growthAreas.join(", ")}');
    buffer.writeln();

    // Risk Factors (if any)
    if (outcomeAnalysis.riskFactors.isNotEmpty) {
      buffer.writeln('⚠️ **RISK FACTORS TO CONSIDER:**');
      for (var risk in outcomeAnalysis.riskFactors.take(3)) {
        buffer.writeln('• $risk');
      }
      buffer.writeln();
    }

    // Practice Exercises
    if (eqSession.practiceExercises.isNotEmpty) {
      buffer.writeln('🎯 **RECOMMENDED PRACTICE:**');
      for (var exercise in eqSession.practiceExercises.take(2)) {
        buffer.writeln('• $exercise');
      }
    }

    return buffer.toString();
  }

  String _formatEQState(eiq.CurrentEQState state) {
    final overall = (state.overallEQScore * 100).toStringAsFixed(0);
    return '$overall% Overall EQ Score';
  }

  String _assessRegulationFromMessage(String message) {
    final length = message.length;
    final hasEmotionalWords = message.toLowerCase().contains(
      RegExp(r'\b(feel|angry|sad|happy|frustrated|excited)\b'),
    );

    if (length > 200 && hasEmotionalWords) {
      return 'High engagement with moderate regulation';
    } else if (length < 50) {
      return 'Concise and controlled';
    } else {
      return 'Balanced emotional expression';
    }
  }

  String _formatChildImpact(pred.ChildImpactPrediction impact) {
    return '${impact.emotionalImpactLevel.name.toUpperCase()} emotional impact';
  }

  String _formatOptimalTiming(pred.OptimalTimingPrediction timing) {
    return timing.reasoning.isNotEmpty
        ? timing.reasoning
        : 'Send when both parents are relaxed';
  }

  // Helper to convert pred.AttachmentStyle to eiq.AttachmentStyle
  eiq.AttachmentStyle _convertPredToEIQAttachmentStyle(pred.AttachmentStyle style) {
    switch (style) {
      case pred.AttachmentStyle.secure:
        return eiq.AttachmentStyle.secure;
      case pred.AttachmentStyle.anxious:
        return eiq.AttachmentStyle.anxious;
      case pred.AttachmentStyle.avoidant:
        return eiq.AttachmentStyle.avoidant;
      case pred.AttachmentStyle.disorganized:
        return eiq.AttachmentStyle.disorganized;
    }
  }

  // Helper to convert pred.CommunicationStyle to eiq.CommunicationStyle
  eiq.CommunicationStyle _convertPredToEIQCommunicationStyle(pred.CommunicationStyle style) {
    switch (style) {
      case pred.CommunicationStyle.assertive:
        return eiq.CommunicationStyle.assertive;
      case pred.CommunicationStyle.passive:
        return eiq.CommunicationStyle.passive;
      case pred.CommunicationStyle.aggressive:
        return eiq.CommunicationStyle.aggressive;
      case pred.CommunicationStyle.passiveAggressive:
        return eiq.CommunicationStyle.passiveAggressive;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8F9FA), Color(0xFFE8E1FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/home',
                        (route) => false,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.asset(
                          'assets/logo_icon.png',
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Analyze Tone',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: const Color(0xFF2D3748),
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 44), // Balance the logo button
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header card with icon
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6C47FF).withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6C47FF),
                                    Color(0xFF00D2FF),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF6C47FF,
                                    ).withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.psychology_alt_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Analyze Your Message',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: const Color(0xFF2D3748),
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Get AI-powered insights into your message tone and emotional impact',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF4A5568),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Message input
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.message_rounded,
                                  color: Color(0xFF6C47FF),
                                  size: 20,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Your Message',
                                  style: TextStyle(
                                    color: Color(0xFF2D3748),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _messageController,
                              maxLines: 5,
                              decoration: InputDecoration(
                                hintText: 'Type your message here...',
                                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF4A5568),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF6C47FF),
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8F9FA),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF2D3748),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Tone selection
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.mood_rounded,
                                  color: Color(0xFF6C47FF),
                                  size: 20,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Desired Tone',
                                  style: TextStyle(
                                    color: Color(0xFF2D3748),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: toneOptions.map((tone) {
                                final isSelected =
                                    _selectedTone == tone['value'];
                                return GestureDetector(
                                  onTap: () => setState(
                                    () => _selectedTone = tone['value'],
                                  ),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(
                                              0xFF6C47FF,
                                            ).withOpacity(0.1)
                                          : const Color(0xFFF8F9FA),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF6C47FF)
                                            : const Color(0xFFE2E8F0),
                                        width: isSelected ? 2 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          tone['icon'],
                                          color: isSelected
                                              ? const Color(0xFF6C47FF)
                                              : tone['color'],
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          tone['value'],
                                          style: TextStyle(
                                            color: isSelected
                                                ? const Color(0xFF6C47FF)
                                                : const Color(0xFF2D3748),
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Sensitivity selection
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.tune_rounded,
                                  color: Color(0xFF6C47FF),
                                  size: 20,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Sensitivity Level',
                                  style: TextStyle(
                                    color: Color(0xFF2D3748),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: sensitivityOptions.map((sensitivity) {
                                final isSelected =
                                    _selectedSensitivity ==
                                    sensitivity['value'];
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(
                                      () => _selectedSensitivity =
                                          sensitivity['value'],
                                    ),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      margin: EdgeInsets.only(
                                        right:
                                            sensitivityOptions.last ==
                                                sensitivity
                                            ? 0
                                            : 12,
                                      ),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(
                                                0xFF6C47FF,
                                              ).withOpacity(0.1)
                                            : const Color(0xFFF8F9FA),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF6C47FF)
                                              : const Color(0xFFE2E8F0),
                                          width: isSelected ? 2 : 1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            sensitivity['icon'],
                                            color: isSelected
                                                ? const Color(0xFF6C47FF)
                                                : sensitivity['color'],
                                            size: 24,
                                          ),
                                          const SizedBox(height: 8), // Fix: use height instead of width for vertical spacing
                                          Text(
                                            sensitivity['value'],
                                            style: TextStyle(
                                              color: isSelected
                                                  ? const Color(0xFF6C47FF)
                                                  : const Color(0xFF2D3748),
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Analyze button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: loading ? null : analyze,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C47FF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: loading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.psychology_alt_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Analyze Tone',
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Results
                      if (result.isNotEmpty)
                        FadeTransition(
                          opacity: _resultAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF6C47FF,
                                  ).withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                              border: Border.all(
                                color: const Color(0xFF6C47FF).withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF6C47FF,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.auto_awesome_rounded,
                                        color: Color(0xFF6C47FF),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Analysis Results',
                                      style: theme.textTheme.headlineMedium
                                          ?.copyWith(
                                            color: const Color(0xFF2D3748),
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  result,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF2D3748),
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
