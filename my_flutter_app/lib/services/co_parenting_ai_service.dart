import 'dart:async';
import 'dart:math' as math;

/// Advanced AI-powered Co-Parenting Communication Service
/// Designed to be the most sophisticated co-parenting communication tool on the market
class CoParentingAIService {
  static final CoParentingAIService _instance =
      CoParentingAIService._internal();
  factory CoParentingAIService() => _instance;
  CoParentingAIService._internal();

  // Advanced AI analysis for co-parenting specific communication
  Future<CoParentingAnalysis> analyzeCoParentingMessage(
    String message, {
    required CoParentingContext context,
    required UserProfile userProfile,
    required PartnerProfile? partnerProfile,
    List<String>? conversationHistory,
  }) async {
    // Simulate advanced AI processing
    await Future.delayed(const Duration(milliseconds: 800));

    final analysis = CoParentingAnalysis(
      originalMessage: message,
      childFocusScore: _calculateChildFocusScore(message),
      conflictRiskLevel: _assessConflictRisk(message, context),
      emotionalRegulationScore: _evaluateEmotionalRegulation(message),
      constructivenessScore: _measureConstructiveness(message),
      coParentingToneAnalysis: _analyzeCoParentingTone(message),
      aiSuggestions: _generateAISuggestions(
        message,
        context,
        userProfile,
        partnerProfile,
      ),
      improvedVersions: _generateImprovedVersions(
        message,
        context,
        userProfile,
      ),
      triggerWarnings: _identifyTriggers(message, context),
      childImpactAnalysis: _analyzeChildImpact(message, context),
      contextualInsights: _generateContextualInsights(
        message,
        context,
        conversationHistory,
      ),
      nextStepsRecommendations: _suggestNextSteps(message, context),
    );

    return analysis;
  }

  double _calculateChildFocusScore(String message) {
    final childFocusedTerms = [
      'our child',
      'our kids',
      'for them',
      'their needs',
      'their wellbeing',
      'school',
      'homework',
      'bedtime',
      'activities',
      'doctor',
      'health',
      'happy',
      'stable',
      'consistent',
      'routine',
      'support them',
      'their future',
      'education',
      'development',
      'growth',
    ];

    final parentFocusedTerms = [
      'you never',
      'you always',
      'I deserve',
      'it\'s not fair',
      'my rights',
      'your fault',
      'because of you',
      'you make me',
    ];

    int childFocusCount = 0;
    int parentFocusCount = 0;

    final lowerMessage = message.toLowerCase();

    for (final term in childFocusedTerms) {
      if (lowerMessage.contains(term)) childFocusCount++;
    }

    for (final term in parentFocusedTerms) {
      if (lowerMessage.contains(term)) parentFocusCount++;
    }

    if (childFocusCount + parentFocusCount == 0) return 0.5;

    return childFocusCount / (childFocusCount + parentFocusCount);
  }

  ConflictRiskLevel _assessConflictRisk(
    String message,
    CoParentingContext context,
  ) {
    final highRiskPatterns = [
      'you never',
      'you always',
      'your fault',
      'because of you',
      'terrible parent',
      'don\'t care',
      'selfish',
      'impossible',
      'had enough',
      'done with',
      'can\'t take',
      'fed up',
    ];

    final moderateRiskPatterns = [
      'frustrated',
      'disappointed',
      'concerned',
      'worried',
      'need to discuss',
      'not working',
      'problem with',
      'issue',
    ];

    final lowerMessage = message.toLowerCase();
    int highRiskScore = 0;
    int moderateRiskScore = 0;

    for (final pattern in highRiskPatterns) {
      if (lowerMessage.contains(pattern)) highRiskScore++;
    }

    for (final pattern in moderateRiskPatterns) {
      if (lowerMessage.contains(pattern)) moderateRiskScore++;
    }

    // Factor in context
    if (context.recentConflicts > 3) highRiskScore++;
    if (context.emotionalStressLevel > 0.7) moderateRiskScore++;

    if (highRiskScore > 0) return ConflictRiskLevel.high;
    if (moderateRiskScore > 1) return ConflictRiskLevel.moderate;
    return ConflictRiskLevel.low;
  }

  double _evaluateEmotionalRegulation(String message) {
    final regulatedLanguage = [
      'I feel',
      'I would appreciate',
      'could we',
      'I\'d like to',
      'perhaps',
      'what if',
      'I understand',
      'I hear you',
      'let\'s work together',
      'I\'m concerned',
      'I\'ve noticed',
    ];

    final dysregulatedLanguage = [
      'you make me',
      'you\'re being',
      'this is ridiculous',
      'I can\'t believe',
      'what\'s wrong with you',
      'obviously',
      'clearly you don\'t',
      'fine whatever',
      'I\'m done',
    ];

    final lowerMessage = message.toLowerCase();
    int regulatedCount = 0;
    int dysregulatedCount = 0;

    for (final phrase in regulatedLanguage) {
      if (lowerMessage.contains(phrase)) regulatedCount++;
    }

    for (final phrase in dysregulatedLanguage) {
      if (lowerMessage.contains(phrase)) dysregulatedCount++;
    }

    if (regulatedCount + dysregulatedCount == 0) return 0.5;

    return regulatedCount / (regulatedCount + dysregulatedCount);
  }

  double _measureConstructiveness(String message) {
    final constructiveElements = [
      'solution',
      'together',
      'plan',
      'schedule',
      'arrange',
      'work out',
      'figure out',
      'coordinate',
      'organize',
      'what works',
      'how about',
      'suggestion',
      'idea',
      'propose',
    ];

    final destructiveElements = [
      'impossible',
      'never work',
      'pointless',
      'waste of time',
      'give up',
      'hopeless',
      'can\'t be fixed',
      'too late',
    ];

    final lowerMessage = message.toLowerCase();
    int constructiveCount = 0;
    int destructiveCount = 0;

    for (final element in constructiveElements) {
      if (lowerMessage.contains(element)) constructiveCount++;
    }

    for (final element in destructiveElements) {
      if (lowerMessage.contains(element)) destructiveCount++;
    }

    final baseScore = message.contains('?')
        ? 0.6
        : 0.4; // Questions are more constructive

    if (constructiveCount + destructiveCount == 0) return baseScore;

    return math.max(
      0.0,
      math.min(
        1.0,
        baseScore + (constructiveCount * 0.2) - (destructiveCount * 0.3),
      ),
    );
  }

  CoParentingToneAnalysis _analyzeCoParentingTone(String message) {
    // Advanced tone analysis specific to co-parenting dynamics
    return CoParentingToneAnalysis(
      primaryTone: _identifyPrimaryTone(message),
      secondaryTones: _identifySecondaryTones(message),
      parentingStressIndicators: _detectStressIndicators(message),
      cooperationLevel: _assessCooperationLevel(message),
      respectLevel: _measureRespectLevel(message),
      boundaryClarity: _evaluateBoundaryClarity(message),
    );
  }

  List<AISuggestion> _generateAISuggestions(
    String message,
    CoParentingContext context,
    UserProfile userProfile,
    PartnerProfile? partnerProfile,
  ) {
    List<AISuggestion> suggestions = [];

    // Child-focus suggestions
    if (_calculateChildFocusScore(message) < 0.4) {
      suggestions.add(
        AISuggestion(
          type: SuggestionType.childFocus,
          priority: Priority.high,
          title: 'Center the conversation on your child',
          description:
              'Consider reframing this message to focus on your child\'s needs and wellbeing.',
          example:
              'Instead of discussing adult feelings, try: "What would be best for [child\'s name] in this situation?"',
          implementationTips: [
            'Start with "Our child needs..."',
            'Ask "How does this affect [child\'s name]?"',
            'Focus on practical solutions',
          ],
        ),
      );
    }

    // Emotional regulation suggestions
    if (_evaluateEmotionalRegulation(message) < 0.5) {
      suggestions.add(
        AISuggestion(
          type: SuggestionType.emotionalRegulation,
          priority: Priority.high,
          title: 'Use "I" statements for better communication',
          description:
              'Your message might come across as blaming. "I" statements help express your feelings without attacking.',
          example: 'Try: "I feel concerned when..." instead of "You always..."',
          implementationTips: [
            'Start with "I feel..."',
            'Describe the behavior, not the person',
            'Express your needs clearly',
          ],
        ),
      );
    }

    // Timing suggestions
    if (context.timeOfDay != null && _isBadTiming(context.timeOfDay!)) {
      suggestions.add(
        AISuggestion(
          type: SuggestionType.timing,
          priority: Priority.medium,
          title: 'Consider the timing of this message',
          description: 'This might not be the best time for this conversation.',
          example:
              'Consider waiting until a calmer moment or scheduling a dedicated time to talk.',
          implementationTips: [
            'Avoid late night messages about conflicts',
            'Wait 24 hours for emotionally charged topics',
            'Schedule important conversations',
          ],
        ),
      );
    }

    // Solution-oriented suggestions
    if (_measureConstructiveness(message) < 0.4) {
      suggestions.add(
        AISuggestion(
          type: SuggestionType.solutionOriented,
          priority: Priority.medium,
          title: 'Propose a solution or next step',
          description:
              'Your message identifies a problem but doesn\'t suggest a way forward.',
          example: 'Add: "What if we tried..." or "I suggest we..."',
          implementationTips: [
            'End with a question or proposal',
            'Offer 2-3 specific options',
            'Ask for their input on solutions',
          ],
        ),
      );
    }

    // Co-parenting specific suggestions based on context
    if (context.topic == CoParentingTopic.scheduling) {
      suggestions.add(_getSchedulingSuggestion(message, context));
    } else if (context.topic == CoParentingTopic.discipline) {
      suggestions.add(_getDisciplineSuggestion(message, context));
    } else if (context.topic == CoParentingTopic.activities) {
      suggestions.add(_getActivitiesSuggestion(message, context));
    }

    return suggestions;
  }

  List<ImprovedMessage> _generateImprovedVersions(
    String message,
    CoParentingContext context,
    UserProfile userProfile,
  ) {
    List<ImprovedMessage> improvements = [];

    // Child-centered version
    improvements.add(
      ImprovedMessage(
        version: 'Child-Centered',
        message: _rewriteChildCentered(message, context),
        explanation:
            'This version focuses on your child\'s needs and wellbeing first.',
        improvements: [
          'Removes blame language',
          'Focuses on child\'s best interests',
          'Promotes cooperation',
        ],
      ),
    );

    // Collaborative version
    improvements.add(
      ImprovedMessage(
        version: 'Collaborative',
        message: _rewriteCollaborative(message, context),
        explanation: 'This version emphasizes working together as co-parents.',
        improvements: [
          'Uses "we" language',
          'Invites partnership',
          'Suggests solutions',
        ],
      ),
    );

    // Professional version
    improvements.add(
      ImprovedMessage(
        version: 'Professional',
        message: _rewriteProfessional(message, context),
        explanation:
            'This version maintains clear boundaries and focuses on facts.',
        improvements: [
          'Removes emotional language',
          'States facts clearly',
          'Maintains respect',
        ],
      ),
    );

    // Empathetic version
    if (userProfile.communicationStyle != CommunicationStyle.avoidant) {
      improvements.add(
        ImprovedMessage(
          version: 'Empathetic',
          message: _rewriteEmpathetic(message, context),
          explanation:
              'This version acknowledges both perspectives and shows understanding.',
          improvements: [
            'Validates feelings',
            'Shows understanding',
            'Builds connection',
          ],
        ),
      );
    }

    return improvements;
  }

  List<TriggerWarning> _identifyTriggers(
    String message,
    CoParentingContext context,
  ) {
    List<TriggerWarning> warnings = [];

    final triggerPatterns = {
      'Blame Language': [
        'your fault',
        'because of you',
        'you made',
        'you caused',
      ],
      'Absolute Statements': [
        'you never',
        'you always',
        'every time',
        'constantly',
      ],
      'Character Attacks': [
        'terrible parent',
        'don\'t care',
        'selfish',
        'irresponsible',
      ],
      'Threat Language': [
        'if you don\'t',
        'or else',
        'I\'ll have to',
        'you\'ll regret',
      ],
      'Dismissive Language': ['whatever', 'fine', 'I don\'t care', 'pointless'],
    };

    final lowerMessage = message.toLowerCase();

    for (final category in triggerPatterns.keys) {
      for (final pattern in triggerPatterns[category]!) {
        if (lowerMessage.contains(pattern)) {
          warnings.add(
            TriggerWarning(
              category: category,
              triggeredPhrase: pattern,
              severity: _getTriggerSeverity(category),
              suggestion: _getTriggerSuggestion(category, pattern),
            ),
          );
          break; // Only add one warning per category
        }
      }
    }

    return warnings;
  }

  ChildImpactAnalysis _analyzeChildImpact(
    String message,
    CoParentingContext context,
  ) {
    return ChildImpactAnalysis(
      emotionalImpactRisk: _assessEmotionalImpactRisk(message, context),
      stabilityThreatLevel: _evaluateStabilityThreat(message, context),
      positiveModelingScore: _scorePositiveModeling(message),
      developmentalConsiderations: _getAgeAppropriateConsiderations(
        context.childAge,
      ),
      recommendations: _getChildFocusedRecommendations(message, context),
    );
  }

  List<ContextualInsight> _generateContextualInsights(
    String message,
    CoParentingContext context,
    List<String>? conversationHistory,
  ) {
    List<ContextualInsight> insights = [];

    // Pattern analysis from conversation history
    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      insights.add(_analyzePatterns(conversationHistory));
    }

    // Timing insights
    insights.add(_getTimingInsights(context));

    // Stress level insights
    if (context.emotionalStressLevel > 0.6) {
      insights.add(
        ContextualInsight(
          type: InsightType.stressLevel,
          insight: 'High stress levels detected',
          explanation:
              'When stress is high, communication often becomes less effective. Consider taking time to regulate before responding.',
          actionableAdvice: [
            'Take 10 deep breaths before sending',
            'Wait 24 hours for important decisions',
            'Focus on one issue at a time',
          ],
        ),
      );
    }

    // Frequency insights
    if (context.communicationFrequency == CommunicationFrequency.excessive) {
      insights.add(
        ContextualInsight(
          type: InsightType.frequency,
          insight: 'High communication frequency detected',
          explanation:
              'Over-communicating can increase stress. Consider consolidating messages or scheduling regular check-ins.',
          actionableAdvice: [
            'Batch similar topics together',
            'Use shared calendars for scheduling',
            'Limit emergency communications to true emergencies',
          ],
        ),
      );
    }

    return insights;
  }

  List<NextStepRecommendation> _suggestNextSteps(
    String message,
    CoParentingContext context,
  ) {
    List<NextStepRecommendation> recommendations = [];

    final conflictRisk = _assessConflictRisk(message, context);

    if (conflictRisk == ConflictRiskLevel.high) {
      recommendations.add(
        NextStepRecommendation(
          action: 'Pause and reflect',
          timeframe: 'Before sending',
          explanation:
              'This message has high conflict potential. Consider revising or waiting.',
          priority: Priority.high,
        ),
      );

      recommendations.add(
        NextStepRecommendation(
          action: 'Schedule a calm conversation',
          timeframe: 'Within 48 hours',
          explanation:
              'Complex issues are better resolved through direct conversation.',
          priority: Priority.medium,
        ),
      );
    }

    if (_measureConstructiveness(message) < 0.4) {
      recommendations.add(
        NextStepRecommendation(
          action: 'Propose specific solutions',
          timeframe: 'In your next message',
          explanation:
              'Move from problem identification to solution-oriented communication.',
          priority: Priority.medium,
        ),
      );
    }

    if (context.topic == CoParentingTopic.scheduling) {
      recommendations.add(
        NextStepRecommendation(
          action: 'Use shared calendar tool',
          timeframe: 'This week',
          explanation:
              'Scheduling conflicts are better managed with visual tools.',
          priority: Priority.low,
        ),
      );
    }

    return recommendations;
  }

  // Helper methods for generating improved versions
  String _rewriteChildCentered(String message, CoParentingContext context) {
    // AI logic to rewrite focusing on child's needs
    return 'I\'m thinking about what would be best for [child\'s name] regarding ${context.topic.toString().split('.').last}. ${_extractCoreRequest(message)} How can we work together to support them?';
  }

  String _rewriteCollaborative(String message, CoParentingContext context) {
    // AI logic to rewrite with collaborative language
    return 'I\'d like to work together on ${_extractCoreRequest(message)} What are your thoughts on how we can handle this as a team?';
  }

  String _rewriteProfessional(String message, CoParentingContext context) {
    // AI logic to rewrite professionally
    return 'Regarding ${context.topic.toString().split('.').last}: ${_extractFactualContent(message)} Please let me know your availability to discuss this further.';
  }

  String _rewriteEmpathetic(String message, CoParentingContext context) {
    // AI logic to rewrite with empathy
    return 'I understand this situation might be challenging for both of us. ${_extractCoreRequest(message)} I\'d appreciate your perspective on how we can move forward together.';
  }

  String _extractCoreRequest(String message) {
    // AI logic to extract the main request/concern from the original message
    // This would use NLP in a real implementation
    return 'I\'d like to address the concern mentioned';
  }

  String _extractFactualContent(String message) {
    // AI logic to extract factual content and remove emotional language
    return 'The situation requires attention';
  }

  // Additional helper methods would be implemented here...
  String _identifyPrimaryTone(String message) => 'neutral';
  List<String> _identifySecondaryTones(String message) => [];
  List<String> _detectStressIndicators(String message) => [];
  double _assessCooperationLevel(String message) => 0.5;
  double _measureRespectLevel(String message) => 0.5;
  double _evaluateBoundaryClarity(String message) => 0.5;
  bool _isBadTiming(DateTime time) => time.hour < 7 || time.hour > 21;

  AISuggestion _getSchedulingSuggestion(
    String message,
    CoParentingContext context,
  ) {
    return AISuggestion(
      type: SuggestionType.scheduling,
      priority: Priority.medium,
      title: 'Use shared scheduling tools',
      description: 'Scheduling discussions work better with visual aids.',
      example:
          'Consider: "I\'ve updated our shared calendar with the new schedule. Please review and let me know if you see any conflicts."',
      implementationTips: [
        'Use shared digital calendars',
        'Include transition times',
        'Plan ahead for holidays',
      ],
    );
  }

  AISuggestion _getDisciplineSuggestion(
    String message,
    CoParentingContext context,
  ) {
    return AISuggestion(
      type: SuggestionType.discipline,
      priority: Priority.high,
      title: 'Align on discipline approach',
      description:
          'Consistent discipline across households helps children feel secure.',
      example:
          'Try: "Let\'s discuss how we can both handle this behavior consistently. What approach has been working for you?"',
      implementationTips: [
        'Agree on major rules',
        'Share what works',
        'Present united front to child',
      ],
    );
  }

  AISuggestion _getActivitiesSuggestion(
    String message,
    CoParentingContext context,
  ) {
    return AISuggestion(
      type: SuggestionType.activities,
      priority: Priority.low,
      title: 'Coordinate activities planning',
      description:
          'Planning activities together ensures consistency and shared experiences.',
      example:
          'Consider: "I\'d love to coordinate on [child\'s name]\'s activities this season. What are you thinking?"',
      implementationTips: [
        'Share costs fairly',
        'Coordinate schedules',
        'Support child\'s interests',
      ],
    );
  }

  TriggerSeverity _getTriggerSeverity(String category) {
    switch (category) {
      case 'Character Attacks':
      case 'Threat Language':
        return TriggerSeverity.high;
      case 'Blame Language':
      case 'Absolute Statements':
        return TriggerSeverity.medium;
      default:
        return TriggerSeverity.low;
    }
  }

  String _getTriggerSuggestion(String category, String pattern) {
    switch (category) {
      case 'Blame Language':
        return 'Try using "I feel" statements instead of "you" statements';
      case 'Absolute Statements':
        return 'Use specific examples instead of "always" or "never"';
      case 'Character Attacks':
        return 'Focus on specific behaviors rather than personal character';
      case 'Threat Language':
        return 'Express your needs directly without threats';
      case 'Dismissive Language':
        return 'Show engagement even when frustrated';
      default:
        return 'Consider a more collaborative approach';
    }
  }

  EmotionalImpactRisk _assessEmotionalImpactRisk(
    String message,
    CoParentingContext context,
  ) {
    final conflictRisk = _assessConflictRisk(message, context);
    switch (conflictRisk) {
      case ConflictRiskLevel.high:
        return EmotionalImpactRisk.high;
      case ConflictRiskLevel.moderate:
        return EmotionalImpactRisk.medium;
      case ConflictRiskLevel.low:
        return EmotionalImpactRisk.low;
    }
  }

  StabilityThreatLevel _evaluateStabilityThreat(
    String message,
    CoParentingContext context,
  ) {
    if (message.toLowerCase().contains('custody') ||
        message.toLowerCase().contains('lawyer') ||
        message.toLowerCase().contains('court')) {
      return StabilityThreatLevel.high;
    }
    return StabilityThreatLevel.low;
  }

  double _scorePositiveModeling(String message) {
    final positiveWords = [
      'respect',
      'cooperation',
      'together',
      'support',
      'understand',
    ];
    final negativeWords = ['hate', 'stupid', 'terrible', 'awful', 'worst'];

    final lowerMessage = message.toLowerCase();
    int positiveCount = positiveWords
        .where((word) => lowerMessage.contains(word))
        .length;
    int negativeCount = negativeWords
        .where((word) => lowerMessage.contains(word))
        .length;

    return math.max(
      0.0,
      math.min(1.0, 0.5 + (positiveCount * 0.2) - (negativeCount * 0.3)),
    );
  }

  List<String> _getAgeAppropriateConsiderations(int? childAge) {
    if (childAge == null) return ['Consider your child\'s developmental stage'];

    if (childAge < 5) {
      return [
        'Young children absorb emotional tension even if they don\'t understand words',
        'Consistency in routines is crucial for security',
        'Keep explanations simple and reassuring',
      ];
    } else if (childAge < 12) {
      return [
        'School-age children notice conflict and may blame themselves',
        'They need reassurance that both parents love them',
        'Avoid putting them in the middle of adult decisions',
      ];
    } else {
      return [
        'Teenagers are highly aware of family dynamics',
        'They value honesty but need emotional safety',
        'Respect their need for stability during turbulent times',
      ];
    }
  }

  List<String> _getChildFocusedRecommendations(
    String message,
    CoParentingContext context,
  ) {
    return [
      'Frame discussions around your child\'s needs',
      'Avoid discussing adult relationship issues',
      'Focus on practical parenting decisions',
      'Model respectful communication',
    ];
  }

  ContextualInsight _analyzePatterns(List<String> conversationHistory) {
    // Analyze conversation patterns - simplified for example
    return ContextualInsight(
      type: InsightType.pattern,
      insight: 'Communication pattern detected',
      explanation:
          'Based on recent conversations, there may be opportunities to improve collaboration.',
      actionableAdvice: [
        'Focus on solutions rather than problems',
        'Use more collaborative language',
        'Schedule regular check-ins',
      ],
    );
  }

  ContextualInsight _getTimingInsights(CoParentingContext context) {
    if (context.timeOfDay != null) {
      final hour = context.timeOfDay!.hour;
      if (hour < 7 || hour > 20) {
        return ContextualInsight(
          type: InsightType.timing,
          insight: 'Late/early communication timing',
          explanation:
              'Messages sent outside normal hours may increase stress.',
          actionableAdvice: [
            'Schedule important conversations during regular hours',
            'Use emergency contact only for true emergencies',
            'Allow time for thoughtful responses',
          ],
        );
      }
    }

    return ContextualInsight(
      type: InsightType.timing,
      insight: 'Good communication timing',
      explanation:
          'This is an appropriate time for co-parenting communication.',
      actionableAdvice: ['Continue communicating during regular hours'],
    );
  }
}

// Data models for co-parenting AI analysis
class CoParentingAnalysis {
  final String originalMessage;
  final double childFocusScore;
  final ConflictRiskLevel conflictRiskLevel;
  final double emotionalRegulationScore;
  final double constructivenessScore;
  final CoParentingToneAnalysis coParentingToneAnalysis;
  final List<AISuggestion> aiSuggestions;
  final List<ImprovedMessage> improvedVersions;
  final List<TriggerWarning> triggerWarnings;
  final ChildImpactAnalysis childImpactAnalysis;
  final List<ContextualInsight> contextualInsights;
  final List<NextStepRecommendation> nextStepsRecommendations;

  CoParentingAnalysis({
    required this.originalMessage,
    required this.childFocusScore,
    required this.conflictRiskLevel,
    required this.emotionalRegulationScore,
    required this.constructivenessScore,
    required this.coParentingToneAnalysis,
    required this.aiSuggestions,
    required this.improvedVersions,
    required this.triggerWarnings,
    required this.childImpactAnalysis,
    required this.contextualInsights,
    required this.nextStepsRecommendations,
  });
}

class CoParentingContext {
  final CoParentingTopic topic;
  final int? childAge;
  final RelationshipStage relationshipStage;
  final double emotionalStressLevel;
  final CommunicationFrequency communicationFrequency;
  final int recentConflicts;
  final DateTime? timeOfDay;
  final bool isUrgent;

  CoParentingContext({
    required this.topic,
    this.childAge,
    required this.relationshipStage,
    required this.emotionalStressLevel,
    required this.communicationFrequency,
    required this.recentConflicts,
    this.timeOfDay,
    this.isUrgent = false,
  });
}

class UserProfile {
  final CommunicationStyle communicationStyle;
  final AttachmentStyle attachmentStyle;
  final double stressLevel;
  final List<String> triggers;

  UserProfile({
    required this.communicationStyle,
    required this.attachmentStyle,
    required this.stressLevel,
    required this.triggers,
  });
}

class PartnerProfile {
  final CommunicationStyle? communicationStyle;
  final AttachmentStyle? attachmentStyle;
  final List<String>? knownTriggers;

  PartnerProfile({
    this.communicationStyle,
    this.attachmentStyle,
    this.knownTriggers,
  });
}

class CoParentingToneAnalysis {
  final String primaryTone;
  final List<String> secondaryTones;
  final List<String> parentingStressIndicators;
  final double cooperationLevel;
  final double respectLevel;
  final double boundaryClarity;

  CoParentingToneAnalysis({
    required this.primaryTone,
    required this.secondaryTones,
    required this.parentingStressIndicators,
    required this.cooperationLevel,
    required this.respectLevel,
    required this.boundaryClarity,
  });
}

class AISuggestion {
  final SuggestionType type;
  final Priority priority;
  final String title;
  final String description;
  final String example;
  final List<String> implementationTips;

  AISuggestion({
    required this.type,
    required this.priority,
    required this.title,
    required this.description,
    required this.example,
    required this.implementationTips,
  });
}

class ImprovedMessage {
  final String version;
  final String message;
  final String explanation;
  final List<String> improvements;

  ImprovedMessage({
    required this.version,
    required this.message,
    required this.explanation,
    required this.improvements,
  });
}

class TriggerWarning {
  final String category;
  final String triggeredPhrase;
  final TriggerSeverity severity;
  final String suggestion;

  TriggerWarning({
    required this.category,
    required this.triggeredPhrase,
    required this.severity,
    required this.suggestion,
  });
}

class ChildImpactAnalysis {
  final EmotionalImpactRisk emotionalImpactRisk;
  final StabilityThreatLevel stabilityThreatLevel;
  final double positiveModelingScore;
  final List<String> developmentalConsiderations;
  final List<String> recommendations;

  ChildImpactAnalysis({
    required this.emotionalImpactRisk,
    required this.stabilityThreatLevel,
    required this.positiveModelingScore,
    required this.developmentalConsiderations,
    required this.recommendations,
  });
}

class ContextualInsight {
  final InsightType type;
  final String insight;
  final String explanation;
  final List<String> actionableAdvice;

  ContextualInsight({
    required this.type,
    required this.insight,
    required this.explanation,
    required this.actionableAdvice,
  });
}

class NextStepRecommendation {
  final String action;
  final String timeframe;
  final String explanation;
  final Priority priority;

  NextStepRecommendation({
    required this.action,
    required this.timeframe,
    required this.explanation,
    required this.priority,
  });
}

// Enums
enum CoParentingTopic {
  scheduling,
  discipline,
  activities,
  education,
  health,
  finances,
  communication,
  holidays,
  travel,
  newPartner,
  emergencies,
}

enum ConflictRiskLevel { low, moderate, high }

enum CommunicationStyle { direct, gentle, analytical, empathetic, avoidant }

enum AttachmentStyle { secure, anxious, avoidant, disorganized }

enum RelationshipStage { recentSeparation, divorced, longTermCoParenting }

enum CommunicationFrequency { minimal, normal, frequent, excessive }

enum SuggestionType {
  childFocus,
  emotionalRegulation,
  timing,
  solutionOriented,
  scheduling,
  discipline,
  activities,
  boundaries,
}

enum Priority { low, medium, high }

enum TriggerSeverity { low, medium, high }

enum EmotionalImpactRisk { low, medium, high }

enum StabilityThreatLevel { low, medium, high }

enum InsightType { pattern, timing, frequency, stressLevel }

class ChildDevelopmentAI {
  static Future<List<String>> suggestGoals() async {
    return [
      "Encourage your child's independence by allowing them to make age-appropriate choices.",
      "Spend at least 15 minutes daily in focused play or conversation with your child.",
      "Support your child's emotional expression by validating their feelings.",
    ];
  }
}
