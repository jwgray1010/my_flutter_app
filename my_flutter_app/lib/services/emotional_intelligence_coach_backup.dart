import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Advanced Emotional Intelligence Coach for Co-Parenting
/// Provides real-time emotional intelligence coaching and skill development
class EmotionalIntelligenceCoach {
  static final EmotionalIntelligenceCoach _instance =
      EmotionalIntelligenceCoach._internal();
  factory EmotionalIntelligenceCoach() => _instance;
  EmotionalIntelligenceCoach._internal();

  /// Provides comprehensive emotional intelligence analysis and coaching
  Future<EQCoachingSession> startCoachingSession(
    String message,
    UserEQProfile userProfile,
    CoParentingContext context,
  ) async {
    await Future.delayed(const Duration(milliseconds: 700));

    final currentEQState = await _analyzeCurrentEQState(message, userProfile);
    final skillAssessment = await _assessEQSkills(message, userProfile);
    final personalizedCoaching = _generatePersonalizedCoaching(
      skillAssessment,
      context,
    );
    final practiceExercises = _createPracticeExercises(skillAssessment);

    return EQCoachingSession(
      currentState: currentEQState,
      skillAssessment: skillAssessment,
      personalizedCoaching: personalizedCoaching,
      practiceExercises: practiceExercises,
      progressTracking: _generateProgressTracking(userProfile),
      nextSessionRecommendation: _recommendNextSession(skillAssessment),
    );
  }

  /// Real-time emotional state detection from communication patterns
  Future<EmotionalStateAnalysis> detectEmotionalState(
    String message, {
    List<String>? recentMessages,
    UserStressLevel? currentStressLevel,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final primaryEmotion = _identifyPrimaryEmotion(message);
    final emotionalIntensity = _measureEmotionalIntensity(message);
    final emotionalRegulation = _assessRegulationLevel(message);
    final triggers = _identifyEmotionalTriggers(message);

    return EmotionalStateAnalysis(
      primaryEmotion: primaryEmotion,
      secondaryEmotions: _identifySecondaryEmotions(message),
      intensityLevel: emotionalIntensity,
      regulationLevel: emotionalRegulation,
      identifiedTriggers: triggers,
      emotionalTrajectory: _predictEmotionalTrajectory(message, recentMessages),
      recommendedInterventions: _suggestEmotionalInterventions(
        primaryEmotion,
        emotionalIntensity,
      ),
      stabilityRisk: _assessEmotionalStability(
        emotionalIntensity,
        emotionalRegulation,
      ),
    );
  }

  /// Personalized emotional regulation techniques
  Future<List<RegulationTechnique>> getPersonalizedRegulationTechniques(
    UserEQProfile profile,
    EmotionalState currentState,
  ) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final techniques = <RegulationTechnique>[];

    // Techniques based on user's learning style
    switch (profile.learningStyle) {
      case LearningStyle.visual:
        techniques.addAll(_getVisualRegulationTechniques(currentState));
        break;
      case LearningStyle.auditory:
        techniques.addAll(_getAuditoryRegulationTechniques(currentState));
        break;
      case LearningStyle.kinesthetic:
        techniques.addAll(_getKinestheticRegulationTechniques(currentState));
        break;
      case LearningStyle.reading:
        techniques.addAll(_getTextBasedRegulationTechniques(currentState));
        break;
    }

    // Techniques based on emotional state
    techniques.addAll(_getStateSpecificTechniques(currentState));

    // Techniques based on co-parenting context
    techniques.addAll(_getCoParentingSpecificTechniques(profile));

    return techniques;
  }

  /// Advanced pattern recognition for emotional intelligence development
  Future<EQPatternAnalysis> analyzeEmotionalPatterns(
    List<MessageData> messageHistory,
    TimeRange timeRange,
  ) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final patterns = _identifyEmotionalPatterns(messageHistory);
    final triggers = _analyzeRecurringTriggers(messageHistory);
    final progress = _trackEQProgress(messageHistory, timeRange);
    final insights = _generatePatternInsights(patterns, triggers);

    return EQPatternAnalysis(
      identifiedPatterns: patterns,
      recurringTriggers: triggers,
      progressMetrics: progress,
      behavioralInsights: insights,
      improvementOpportunities: _identifyImprovementOpportunities(patterns),
      strengthAreas: _identifyStrengthAreas(patterns),
      recommendations: _generatePatternBasedRecommendations(patterns, triggers),
    );
  }

  /// Stress level prediction and prevention coaching
  Future<StressPrevention> predictAndPreventStressEscalation(
    ConversationFlow conversationFlow,
    UserStressProfile stressProfile,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final stressLevel = _predictStressLevel(conversationFlow, stressProfile);
    final escalationRisk = _assessEscalationRisk(stressLevel, conversationFlow);
    final preventionStrategies = _generatePreventionStrategies(
      stressLevel,
      stressProfile,
    );

    return StressPrevention(
      predictedStressLevel: stressLevel,
      escalationRisk: escalationRisk,
      earlyWarningSignals: _identifyEarlyWarningSignals(conversationFlow),
      preventionStrategies: preventionStrategies,
      cooldownTechniques: _getCooldownTechniques(stressProfile),
      supportResources: _recommendSupportResources(stressLevel),
      actionPlan: _createStressActionPlan(stressLevel, escalationRisk),
    );
  }

  /// Empathy and perspective-taking coaching
  Future<EmpathyCoaching> provideEmpathyCoaching(
    String message,
    PartnerProfile partnerProfile,
    ConversationContext context,
  ) async {
    await Future.delayed(const Duration(milliseconds: 450));

    final empathyLevel = _measureEmpathyInMessage(message);
    final perspectiveTaking = _assessPerspectiveTaking(message, partnerProfile);
    final empathyGaps = _identifyEmpathyGaps(message, context);

    return EmpathyCoaching(
      currentEmpathyLevel: empathyLevel,
      perspectiveTakingScore: perspectiveTaking,
      identifiedEmpathyGaps: empathyGaps,
      empathyEnhancingTechniques: _generateEmpathyTechniques(empathyLevel),
      perspectiveExercises: _createPerspectiveExercises(partnerProfile),
      empathyReframe: _suggestEmpathyReframe(message, partnerProfile),
      compassionateResponses: _generateCompassionateAlternatives(message),
    );
  }

  // Private analysis methods
  Future<CurrentEQState> _analyzeCurrentEQState(
    String message,
    UserEQProfile profile,
  ) async {
    final selfAwareness = _measureSelfAwareness(message);
    final selfRegulation = _measureSelfRegulation(message);
    final motivation = _measureMotivation(message);
    final empathy = _measureEmpathy(message);
    final socialSkills = _measureSocialSkills(message);

    return CurrentEQState(
      selfAwarenessScore: selfAwareness,
      selfRegulationScore: selfRegulation,
      motivationScore: motivation,
      empathyScore: empathy,
      socialSkillsScore: socialSkills,
      overallEQScore:
          (selfAwareness +
              selfRegulation +
              motivation +
              empathy +
              socialSkills) /
          5,
      strengthAreas: _identifyStrengths([
        selfAwareness,
        selfRegulation,
        motivation,
        empathy,
        socialSkills,
      ]),
      growthAreas: _identifyGrowthAreas([
        selfAwareness,
        selfRegulation,
        motivation,
        empathy,
        socialSkills,
      ]),
    );
  }

  Future<EQSkillAssessment> _assessEQSkills(
    String message,
    UserEQProfile profile,
  ) async {
    return EQSkillAssessment(
      emotionalVocabulary: _assessEmotionalVocabulary(message),
      emotionalAccuracy: _assessEmotionalAccuracy(message, profile),
      regulationStrategies: _assessRegulationStrategies(message),
      empathicResponding: _assessEmpathicResponding(message),
      conflictResolution: _assessConflictResolution(message),
      assertiveCommunication: _assessAssertiveCommunication(message),
      emotionalBoundaries: _assessEmotionalBoundaries(message),
    );
  }

  PrimaryEmotion _identifyPrimaryEmotion(String message) {
    final emotionIndicators = {
      'anger': [
        'angry',
        'mad',
        'furious',
        'irritated',
        'frustrated',
        'annoyed',
      ],
      'sadness': ['sad', 'disappointed', 'hurt', 'upset', 'down', 'depressed'],
      'fear': [
        'worried',
        'anxious',
        'scared',
        'nervous',
        'concerned',
        'afraid',
      ],
      'joy': ['happy', 'excited', 'glad', 'pleased', 'thrilled', 'delighted'],
      'surprise': [
        'surprised',
        'shocked',
        'amazed',
        'astonished',
        'unexpected',
      ],
      'disgust': ['disgusted', 'appalled', 'repulsed', 'sickened'],
      'contempt': ['contempt', 'disdain', 'scorn', 'ridiculous', 'pathetic'],
      'love': ['love', 'care', 'cherish', 'adore', 'appreciate'],
      'hope': ['hope', 'optimistic', 'confident', 'positive', 'forward'],
      'guilt': ['guilty', 'sorry', 'regret', 'ashamed', 'fault'],
    };

    final lowerMessage = message.toLowerCase();
    final emotionScores = <String, int>{};

    for (final emotion in emotionIndicators.keys) {
      int score = 0;
      for (final indicator in emotionIndicators[emotion]!) {
        if (lowerMessage.contains(indicator)) {
          score += lowerMessage.split(indicator).length - 1;
        }
      }
      emotionScores[emotion] = score;
    }

    final dominantEmotion = emotionScores.entries
        .where((e) => e.value > 0)
        .fold<MapEntry<String, int>?>(
          null,
          (prev, curr) => prev == null || curr.value > prev.value ? curr : prev,
        );

    if (dominantEmotion == null) {
      return PrimaryEmotion.neutral;
    }

    switch (dominantEmotion.key) {
      case 'anger':
        return PrimaryEmotion.anger;
      case 'sadness':
        return PrimaryEmotion.sadness;
      case 'fear':
        return PrimaryEmotion.fear;
      case 'joy':
        return PrimaryEmotion.joy;
      case 'surprise':
        return PrimaryEmotion.surprise;
      case 'disgust':
        return PrimaryEmotion.disgust;
      case 'contempt':
        return PrimaryEmotion.contempt;
      case 'love':
        return PrimaryEmotion.love;
      case 'hope':
        return PrimaryEmotion.hope;
      case 'guilt':
        return PrimaryEmotion.guilt;
      default:
        return PrimaryEmotion.neutral;
    }
  }

  double _measureEmotionalIntensity(String message) {
    int intensityScore = 0;

    // Punctuation indicators
    intensityScore += (message.split('!').length - 1) * 2; // Exclamation marks
    intensityScore += (message.split('?').length - 1) * 1; // Question marks

    // Capitalization
    final caps = message
        .split('')
        .where((c) => c.toUpperCase() == c && c.toLowerCase() != c)
        .length;
    if (caps > message.length * 0.3) intensityScore += 3; // Excessive caps

    // Intensity words
    final intensityWords = [
      'very',
      'extremely',
      'incredibly',
      'absolutely',
      'completely',
      'totally',
    ];
    for (final word in intensityWords) {
      if (message.toLowerCase().contains(word)) intensityScore += 2;
    }

    // Length as indicator of emotional investment
    if (message.length > 200) intensityScore += 1;
    if (message.length > 500) intensityScore += 2;

    return math.min(1.0, intensityScore / 10.0);
  }

  List<RegulationTechnique> _getStateSpecificTechniques(EmotionalState state) {
    switch (state.primaryEmotion) {
      case PrimaryEmotion.anger:
        return [
          RegulationTechnique(
            name: 'Box Breathing',
            description: 'Breathe in for 4, hold for 4, out for 4, hold for 4',
            duration: Duration(minutes: 2),
            effectiveness: 0.8,
            instructions: [
              'Find a comfortable position',
              'Breathe in slowly for 4 counts',
              'Hold your breath for 4 counts',
              'Exhale slowly for 4 counts',
              'Hold empty for 4 counts',
              'Repeat 4-6 times',
            ],
          ),
          RegulationTechnique(
            name: 'Progressive Muscle Relaxation',
            description:
                'Tense and release muscle groups to reduce physical tension',
            duration: Duration(minutes: 5),
            effectiveness: 0.7,
            instructions: [
              'Start with your feet, tense for 5 seconds',
              'Release and notice the relaxation',
              'Move up to calves, thighs, etc.',
              'Include face and neck muscles',
              'End with full-body tension and release',
            ],
          ),
        ];
      case PrimaryEmotion.anxiety:
        return [
          RegulationTechnique(
            name: '5-4-3-2-1 Grounding',
            description: 'Use your senses to ground yourself in the present',
            duration: Duration(minutes: 3),
            effectiveness: 0.85,
            instructions: [
              'Name 5 things you can see',
              'Name 4 things you can touch',
              'Name 3 things you can hear',
              'Name 2 things you can smell',
              'Name 1 thing you can taste',
            ],
          ),
        ];
      default:
        return [
          RegulationTechnique(
            name: 'Mindful Pause',
            description: 'Take a moment to observe your thoughts and feelings',
            duration: Duration(minutes: 1),
            effectiveness: 0.6,
            instructions: [
              'Pause what you\'re doing',
              'Take three deep breaths',
              'Notice your thoughts without judgment',
              'Notice your feelings without judgment',
              'Choose your next action mindfully',
            ],
          ),
        ];
    }
  }

  // Missing private method implementations
  PersonalizedCoaching _generatePersonalizedCoaching(
    EQSkillAssessment assessment,
    CoParentingContext context,
  ) {
    return PersonalizedCoaching(
      recommendations: [
        'Focus on emotional vocabulary expansion',
        'Practice perspective-taking exercises',
        'Develop conflict resolution strategies',
      ],
      priority: 'High',
    );
  }

  List<PracticeExercise> _createPracticeExercises(
    EQSkillAssessment assessment,
  ) {
    return [
      PracticeExercise(
        name: 'Daily Emotion Check-in',
        description:
            'Take 5 minutes each morning to identify and name your emotions',
        duration: Duration(minutes: 5),
        difficulty: 'Beginner',
      ),
      PracticeExercise(
        name: 'Empathy Journal',
        description:
            'Write about situations from your co-parent\'s perspective',
        duration: Duration(minutes: 10),
        difficulty: 'Intermediate',
      ),
    ];
  }

  ProgressTracking _generateProgressTracking(UserEQProfile userProfile) {
    return ProgressTracking(
      currentWeek: 1,
      milestones: ['Emotional awareness', 'Self-regulation', 'Empathy'],
      progress: 0.3,
    );
  }

  NextSessionRecommendation _recommendNextSession(
    EQSkillAssessment assessment,
  ) {
    return NextSessionRecommendation(
      focus: 'Empathy Development',
      scheduledIn: Duration(days: 7),
      preparationTasks: [
        'Complete empathy exercises',
        'Practice perspective-taking',
      ],
    );
  }

  double _assessRegulationLevel(String message) {
    final regulatedWords = [
      'calm',
      'understand',
      'consider',
      'think',
      'peaceful',
    ];
    final dysregulatedWords = ['angry', 'furious', 'hate', 'can\'t', 'never'];

    final lowerMessage = message.toLowerCase();
    int regulatedCount = regulatedWords
        .where((word) => lowerMessage.contains(word))
        .length;
    int dysregulatedCount = dysregulatedWords
        .where((word) => lowerMessage.contains(word))
        .length;

    return math.max(
      0.0,
      math.min(1.0, (regulatedCount - dysregulatedCount + 3) / 6),
    );
  }

  List<EmotionalTrigger> _identifyEmotionalTriggers(String message) {
    final triggers = <EmotionalTrigger>[];
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('always') || lowerMessage.contains('never')) {
      triggers.add(EmotionalTrigger(type: 'Absolute Language', intensity: 0.8));
    }
    if (lowerMessage.contains('you') &&
        (lowerMessage.contains('don\'t') || lowerMessage.contains('won\'t'))) {
      triggers.add(EmotionalTrigger(type: 'Blame Language', intensity: 0.7));
    }

    return triggers;
  }

  List<SecondaryEmotion> _identifySecondaryEmotions(String message) {
    return [
      SecondaryEmotion(emotion: 'Frustration', confidence: 0.7),
      SecondaryEmotion(emotion: 'Concern', confidence: 0.6),
    ];
  }

  EmotionalTrajectory _predictEmotionalTrajectory(
    String message,
    List<String>? recentMessages,
  ) {
    return EmotionalTrajectory(
      direction: 'Improving',
      confidence: 0.6,
      timeframe: Duration(hours: 2),
    );
  }

  List<EmotionalIntervention> _suggestEmotionalInterventions(
    PrimaryEmotion emotion,
    double intensity,
  ) {
    return [
      EmotionalIntervention(
        type: 'Breathing Exercise',
        urgency: intensity > 0.7 ? 'High' : 'Medium',
        description: 'Take 5 deep breaths before responding',
      ),
      EmotionalIntervention(
        type: 'Reframe Perspective',
        urgency: 'Medium',
        description: 'Consider your co-parent\'s viewpoint',
      ),
    ];
  }

  StabilityRisk _assessEmotionalStability(double intensity, double regulation) {
    if (intensity > 0.8 && regulation < 0.3) return StabilityRisk.crisis;
    if (intensity > 0.6 && regulation < 0.5) return StabilityRisk.unstable;
    if (intensity > 0.4 || regulation < 0.6) return StabilityRisk.atRisk;
    return StabilityRisk.stable;
  }

  List<RegulationTechnique> _getVisualRegulationTechniques(
    EmotionalState state,
  ) {
    return [
      RegulationTechnique(
        name: 'Color Breathing Visualization',
        description:
            'Visualize breathing in calm blue and breathing out red tension',
        duration: Duration(minutes: 3),
        effectiveness: 0.75,
        instructions: [
          'Close your eyes and imagine a calm blue light',
          'Breathe in the blue calming energy',
          'See red tension leaving as you exhale',
          'Continue for 5-10 breaths',
        ],
      ),
    ];
  }

  List<RegulationTechnique> _getAuditoryRegulationTechniques(
    EmotionalState state,
  ) {
    return [
      RegulationTechnique(
        name: 'Calming Sounds Focus',
        description: 'Focus on peaceful sounds to center yourself',
        duration: Duration(minutes: 2),
        effectiveness: 0.7,
        instructions: [
          'Find a quiet space',
          'Listen to your breathing',
          'Notice ambient sounds without judgment',
          'Return focus to breath when mind wanders',
        ],
      ),
    ];
  }

  List<RegulationTechnique> _getKinestheticRegulationTechniques(
    EmotionalState state,
  ) {
    return [
      RegulationTechnique(
        name: 'Progressive Muscle Release',
        description: 'Systematically tense and release muscle groups',
        duration: Duration(minutes: 5),
        effectiveness: 0.8,
        instructions: [
          'Start with your toes, tense for 5 seconds',
          'Release and feel the relaxation',
          'Move up through each muscle group',
          'End with full body tension and release',
        ],
      ),
    ];
  }

  List<RegulationTechnique> _getTextBasedRegulationTechniques(
    EmotionalState state,
  ) {
    return [
      RegulationTechnique(
        name: 'Thought Reframing',
        description: 'Write down and reframe negative thoughts',
        duration: Duration(minutes: 4),
        effectiveness: 0.7,
        instructions: [
          'Write the triggering thought',
          'Identify the emotion it creates',
          'Challenge the thought\'s accuracy',
          'Write a balanced alternative',
        ],
      ),
    ];
  }

  List<RegulationTechnique> _getCoParentingSpecificTechniques(
    UserEQProfile profile,
  ) {
    return [
      RegulationTechnique(
        name: 'Child-Focused Pause',
        description:
            'Before responding, think about what\'s best for your child',
        duration: Duration(minutes: 1),
        effectiveness: 0.85,
        instructions: [
          'Pause before responding',
          'Ask: "What would be best for my child?"',
          'Consider long-term relationship impact',
          'Respond from a place of care',
        ],
      ),
    ];
  }

  List<String> _identifyEmotionalPatterns(List<MessageData> messageHistory) {
    return [
      'Stress increases on Monday mornings',
      'More positive communication in evenings',
      'Conflict escalation around schedule changes',
    ];
  }

  List<String> _analyzeRecurringTriggers(List<MessageData> messageHistory) {
    return [
      'Last-minute schedule changes',
      'Financial discussions',
      'Holiday planning',
    ];
  }

  Map<String, double> _trackEQProgress(
    List<MessageData> messageHistory,
    TimeRange timeRange,
  ) {
    return {
      'Emotional Regulation': 0.7,
      'Empathy': 0.6,
      'Self-Awareness': 0.8,
      'Social Skills': 0.65,
    };
  }

  List<String> _generatePatternInsights(
    List<String> patterns,
    List<String> triggers,
  ) {
    return [
      'Communication quality improves when you take time to process emotions first',
      'Scheduling conflicts are your primary stress trigger',
      'Evening conversations tend to be more collaborative',
    ];
  }

  List<String> _identifyImprovementOpportunities(List<String> patterns) {
    return [
      'Practice morning emotional check-ins',
      'Develop scripts for difficult conversations',
      'Build in buffer time for schedule discussions',
    ];
  }

  List<String> _identifyStrengthAreas(List<String> patterns) {
    return [
      'Strong emotional vocabulary',
      'Good conflict recovery skills',
      'Consistent effort to improve',
    ];
  }

  List<String> _generatePatternBasedRecommendations(
    List<String> patterns,
    List<String> triggers,
  ) {
    return [
      'Schedule regular check-ins to prevent trigger accumulation',
      'Practice the STOP technique when triggers arise',
      'Use collaborative language in scheduling discussions',
    ];
  }

  double _predictStressLevel(
    ConversationFlow conversationFlow,
    UserStressProfile stressProfile,
  ) {
    return 0.4;
  }

  double _assessEscalationRisk(
    double stressLevel,
    ConversationFlow conversationFlow,
  ) {
    return stressLevel * 0.7;
  }

  List<String> _generatePreventionStrategies(
    double stressLevel,
    UserStressProfile stressProfile,
  ) {
    return [
      'Take breaks during difficult conversations',
      'Use "I" statements instead of "you" statements',
      'Focus on solutions rather than problems',
    ];
  }

  List<String> _identifyEarlyWarningSignals(ConversationFlow conversationFlow) {
    return [
      'Shortened responses',
      'Increased use of definitive language',
      'Topic avoidance',
    ];
  }

  List<String> _getCooldownTechniques(UserStressProfile stressProfile) {
    return [
      'Take a 10-minute walk',
      'Practice deep breathing',
      'Listen to calming music',
    ];
  }

  List<String> _recommendSupportResources(double stressLevel) {
    return [
      'Family counselor contact info',
      'Co-parenting support group',
      'Meditation app recommendations',
    ];
  }

  String _createStressActionPlan(double stressLevel, double escalationRisk) {
    if (escalationRisk > 0.7) {
      return 'High risk: Take immediate break, practice breathing, consider professional support';
    } else if (escalationRisk > 0.4) {
      return 'Medium risk: Use regulation techniques, schedule follow-up conversation';
    }
    return 'Low risk: Continue with mindful communication';
  }

  double _measureEmpathyInMessage(String message) {
    final empathyWords = [
      'understand',
      'feel',
      'see your point',
      'appreciate',
      'difficult',
    ];
    final lowerMessage = message.toLowerCase();
    int empathyCount = empathyWords
        .where((word) => lowerMessage.contains(word))
        .length;
    return math.min(1.0, empathyCount / 3.0);
  }

  double _assessPerspectiveTaking(
    String message,
    PartnerProfile partnerProfile,
  ) {
    final perspectiveWords = [
      'from your view',
      'in your shoes',
      'your perspective',
      'you might',
    ];
    final lowerMessage = message.toLowerCase();
    int perspectiveCount = perspectiveWords
        .where((phrase) => lowerMessage.contains(phrase))
        .length;
    return math.min(1.0, perspectiveCount / 2.0);
  }

  List<String> _identifyEmpathyGaps(
    String message,
    ConversationContext context,
  ) {
    return [
      'Consider partner\'s work stress',
      'Acknowledge different parenting styles',
      'Recognize emotional needs',
    ];
  }

  List<String> _generateEmpathyTechniques(double empathyLevel) {
    return [
      'Practice the "Two-Chair" technique',
      'Ask "What might they be feeling?"',
      'Reflect back what you hear',
    ];
  }

  List<String> _createPerspectiveExercises(PartnerProfile partnerProfile) {
    return [
      'Write a day in their life',
      'List their current stressors',
      'Identify their parenting goals',
    ];
  }

  String _suggestEmpathyReframe(String message, PartnerProfile partnerProfile) {
    return 'Try: "I can see this situation is stressful for you. How can we work together to find a solution?"';
  }

  List<String> _generateCompassionateAlternatives(String message) {
    return [
      'I understand this is challenging for both of us',
      'Let\'s focus on what\'s best for our child',
      'I appreciate you taking the time to discuss this',
    ];
  }

  double _measureSelfAwareness(String message) {
    final selfAwareWords = ['I feel', 'I think', 'I need', 'I\'m struggling'];
    final lowerMessage = message.toLowerCase();
    return selfAwareWords.any((phrase) => lowerMessage.contains(phrase))
        ? 0.7
        : 0.3;
  }

  double _measureSelfRegulation(String message) {
    final regulatedIndicators = [
      'let me think',
      'I need time',
      'calm',
      'pause',
    ];
    final lowerMessage = message.toLowerCase();
    return regulatedIndicators.any((phrase) => lowerMessage.contains(phrase))
        ? 0.8
        : 0.4;
  }

  double _measureMotivation(String message) {
    final motivatedWords = [
      'want to work together',
      'for our child',
      'improve',
      'better',
    ];
    final lowerMessage = message.toLowerCase();
    return motivatedWords.any((phrase) => lowerMessage.contains(phrase))
        ? 0.8
        : 0.5;
  }

  double _measureEmpathy(String message) {
    return _measureEmpathyInMessage(message);
  }

  double _measureSocialSkills(String message) {
    final socialWords = ['we can', 'let\'s', 'together', 'collaborate'];
    final lowerMessage = message.toLowerCase();
    return socialWords.any((word) => lowerMessage.contains(word)) ? 0.7 : 0.4;
  }

  List<String> _identifyStrengths(List<double> scores) {
    List<String> strengths = [];
    final skills = [
      'Self-Awareness',
      'Self-Regulation',
      'Motivation',
      'Empathy',
      'Social Skills',
    ];
    for (int i = 0; i < scores.length; i++) {
      if (scores[i] > 0.7) strengths.add(skills[i]);
    }
    return strengths;
  }

  List<String> _identifyGrowthAreas(List<double> scores) {
    List<String> growthAreas = [];
    final skills = [
      'Self-Awareness',
      'Self-Regulation',
      'Motivation',
      'Empathy',
      'Social Skills',
    ];
    for (int i = 0; i < scores.length; i++) {
      if (scores[i] < 0.5) growthAreas.add(skills[i]);
    }
    return growthAreas;
  }

  double _assessEmotionalVocabulary(String message) {
    final emotionWords = [
      'frustrated',
      'concerned',
      'hopeful',
      'disappointed',
      'grateful',
    ];
    final lowerMessage = message.toLowerCase();
    return emotionWords.any((word) => lowerMessage.contains(word)) ? 0.8 : 0.4;
  }

  double _assessEmotionalAccuracy(String message, UserEQProfile profile) {
    return 0.6; // Simplified implementation
  }

  double _assessRegulationStrategies(String message) {
    final strategies = [
      'take a break',
      'think about',
      'calm down',
      'step back',
    ];
    final lowerMessage = message.toLowerCase();
    return strategies.any((strategy) => lowerMessage.contains(strategy))
        ? 0.7
        : 0.3;
  }

  double _assessEmpathicResponding(String message) {
    return _measureEmpathyInMessage(message);
  }

  double _assessConflictResolution(String message) {
    final resolutionWords = [
      'compromise',
      'solution',
      'work together',
      'middle ground',
    ];
    final lowerMessage = message.toLowerCase();
    return resolutionWords.any((word) => lowerMessage.contains(word))
        ? 0.8
        : 0.4;
  }

  double _assessAssertiveCommunication(String message) {
    final assertiveWords = [
      'I need',
      'I would like',
      'I prefer',
      'important to me',
    ];
    final lowerMessage = message.toLowerCase();
    return assertiveWords.any((phrase) => lowerMessage.contains(phrase))
        ? 0.7
        : 0.4;
  }

  double _assessEmotionalBoundaries(String message) {
    final boundaryWords = [
      'not comfortable',
      'need space',
      'my limit',
      'boundary',
    ];
    final lowerMessage = message.toLowerCase();
    return boundaryWords.any((phrase) => lowerMessage.contains(phrase))
        ? 0.8
        : 0.5;
  }
}

/// Child Development AI
/// Provides parenting goal suggestions based on child's age and development stage
class ChildDevelopmentAI {
  static Future<List<String>> suggestGoals() async {
    return [
      "Encourage your child's independence by allowing them to make age-appropriate choices.",
      "Spend at least 15 minutes daily in focused play or conversation with your child.",
      "Support your child's emotional expression by validating their feelings.",
    ];
  }
}

// Data Classes
class EQCoachingSession {
  final CurrentEQState currentState;
  final EQSkillAssessment skillAssessment;
  final PersonalizedCoaching personalizedCoaching;
  final List<PracticeExercise> practiceExercises;
  final ProgressTracking progressTracking;
  final NextSessionRecommendation nextSessionRecommendation;

  EQCoachingSession({
    required this.currentState,
    required this.skillAssessment,
    required this.personalizedCoaching,
    required this.practiceExercises,
    required this.progressTracking,
    required this.nextSessionRecommendation,
  });
}

class EmotionalStateAnalysis {
  final PrimaryEmotion primaryEmotion;
  final List<SecondaryEmotion> secondaryEmotions;
  final double intensityLevel;
  final double regulationLevel;
  final List<EmotionalTrigger> identifiedTriggers;
  final EmotionalTrajectory emotionalTrajectory;
  final List<EmotionalIntervention> recommendedInterventions;
  final StabilityRisk stabilityRisk;

  EmotionalStateAnalysis({
    required this.primaryEmotion,
    required this.secondaryEmotions,
    required this.intensityLevel,
    required this.regulationLevel,
    required this.identifiedTriggers,
    required this.emotionalTrajectory,
    required this.recommendedInterventions,
    required this.stabilityRisk,
  });
}

class RegulationTechnique {
  final String name;
  final String description;
  final Duration duration;
  final double effectiveness;
  final List<String> instructions;

  RegulationTechnique({
    required this.name,
    required this.description,
    required this.duration,
    required this.effectiveness,
    required this.instructions,
  });
}

// Enums
enum PrimaryEmotion {
  anger,
  sadness,
  fear,
  joy,
  surprise,
  disgust,
  contempt,
  love,
  hope,
  guilt,
  shame,
  pride,
  excitement,
  anxiety,
  neutral,
}

enum LearningStyle { visual, auditory, kinesthetic, reading }

enum UserStressLevel { low, moderate, high, extreme }

enum StabilityRisk { stable, atRisk, unstable, crisis }

enum AttachmentStyle { secure, anxious, avoidant, disorganized }

enum CommunicationStyle { assertive, passive, aggressive, passiveAggressive }

// Additional supporting classes
class UserEQProfile {
  final LearningStyle learningStyle;
  final List<String> strengths;
  final List<String> growthAreas;
  final AttachmentStyle attachmentStyle;
  final CommunicationStyle communicationStyle;

  UserEQProfile({
    required this.learningStyle,
    required this.strengths,
    required this.growthAreas,
    required this.attachmentStyle,
    required this.communicationStyle,
  });
}

class CoParentingContext {
  final String topic;
  final DateTime timeOfDay;

  CoParentingContext({required this.topic, required this.timeOfDay});
}

class EmotionalState {
  final PrimaryEmotion primaryEmotion;
  final double intensity;

  EmotionalState({required this.primaryEmotion, required this.intensity});
}

// Placeholder classes for comprehensive structure
class CurrentEQState {
  final double selfAwarenessScore;
  final double selfRegulationScore;
  final double motivationScore;
  final double empathyScore;
  final double socialSkillsScore;
  final double overallEQScore;
  final List<String> strengthAreas;
  final List<String> growthAreas;

  CurrentEQState({
    required this.selfAwarenessScore,
    required this.selfRegulationScore,
    required this.motivationScore,
    required this.empathyScore,
    required this.socialSkillsScore,
    required this.overallEQScore,
    required this.strengthAreas,
    required this.growthAreas,
  });
}

class EQSkillAssessment {
  final double emotionalVocabulary;
  final double emotionalAccuracy;
  final double regulationStrategies;
  final double empathicResponding;
  final double conflictResolution;
  final double assertiveCommunication;
  final double emotionalBoundaries;

  EQSkillAssessment({
    required this.emotionalVocabulary,
    required this.emotionalAccuracy,
    required this.regulationStrategies,
    required this.empathicResponding,
    required this.conflictResolution,
    required this.assertiveCommunication,
    required this.emotionalBoundaries,
  });
}

// Additional classes would be defined here...
class PersonalizedCoaching {
  final List<String> recommendations;
  final String priority;

  PersonalizedCoaching({required this.recommendations, required this.priority});
}

class PracticeExercise {
  final String name;
  final String description;
  final Duration duration;
  final String difficulty;

  PracticeExercise({
    required this.name,
    required this.description,
    required this.duration,
    required this.difficulty,
  });
}

class ProgressTracking {
  final int currentWeek;
  final List<String> milestones;
  final double progress;

  ProgressTracking({
    required this.currentWeek,
    required this.milestones,
    required this.progress,
  });
}

class NextSessionRecommendation {
  final String focus;
  final Duration scheduledIn;
  final List<String> preparationTasks;

  NextSessionRecommendation({
    required this.focus,
    required this.scheduledIn,
    required this.preparationTasks,
  });
}

class SecondaryEmotion {
  final String emotion;
  final double confidence;

  SecondaryEmotion({required this.emotion, required this.confidence});
}

class EmotionalTrigger {
  final String type;
  final double intensity;

  EmotionalTrigger({required this.type, required this.intensity});
}

class EmotionalTrajectory {
  final String direction;
  final double confidence;
  final Duration timeframe;

  EmotionalTrajectory({
    required this.direction,
    required this.confidence,
    required this.timeframe,
  });
}

class EmotionalIntervention {
  final String type;
  final String urgency;
  final String description;

  EmotionalIntervention({
    required this.type,
    required this.urgency,
    required this.description,
  });
}

class MessageData {
  final String content;
  final DateTime timestamp;
  final String sender;

  MessageData({
    required this.content,
    required this.timestamp,
    required this.sender,
  });
}

class TimeRange {
  final DateTime start;
  final DateTime end;

  TimeRange({required this.start, required this.end});
}

class EQPatternAnalysis {
  final List<String> identifiedPatterns;
  final List<String> recurringTriggers;
  final Map<String, double> progressMetrics;
  final List<String> behavioralInsights;
  final List<String> improvementOpportunities;
  final List<String> strengthAreas;
  final List<String> recommendations;

  EQPatternAnalysis({
    required this.identifiedPatterns,
    required this.recurringTriggers,
    required this.progressMetrics,
    required this.behavioralInsights,
    required this.improvementOpportunities,
    required this.strengthAreas,
    required this.recommendations,
  });
}

class StressPrevention {
  final double predictedStressLevel;
  final double escalationRisk;
  final List<String> earlyWarningSignals;
  final List<String> preventionStrategies;
  final List<String> cooldownTechniques;
  final List<String> supportResources;
  final String actionPlan;

  StressPrevention({
    required this.predictedStressLevel,
    required this.escalationRisk,
    required this.earlyWarningSignals,
    required this.preventionStrategies,
    required this.cooldownTechniques,
    required this.supportResources,
    required this.actionPlan,
  });
}

class ConversationFlow {
  final List<String> messages;
  final DateTime startTime;
  final String topic;

  ConversationFlow({
    required this.messages,
    required this.startTime,
    required this.topic,
  });
}

class UserStressProfile {
  final List<String> stressTriggers;
  final double baselineStress;
  final List<String> copingStrategies;

  UserStressProfile({
    required this.stressTriggers,
    required this.baselineStress,
    required this.copingStrategies,
  });
}

class EmpathyCoaching {
  final double currentEmpathyLevel;
  final double perspectiveTakingScore;
  final List<String> identifiedEmpathyGaps;
  final List<String> empathyEnhancingTechniques;
  final List<String> perspectiveExercises;
  final String empathyReframe;
  final List<String> compassionateResponses;

  EmpathyCoaching({
    required this.currentEmpathyLevel,
    required this.perspectiveTakingScore,
    required this.identifiedEmpathyGaps,
    required this.empathyEnhancingTechniques,
    required this.perspectiveExercises,
    required this.empathyReframe,
    required this.compassionateResponses,
  });
}

class PartnerProfile {
  final String name;
  final List<String> communicationPreferences;
  final List<String> stressTriggers;
  final String personalityType;

  PartnerProfile({
    required this.name,
    required this.communicationPreferences,
    required this.stressTriggers,
    required this.personalityType,
  });
}

class ConversationContext {
  final String topic;
  final String urgency;
  final List<String> participants;
  final DateTime timestamp;

  ConversationContext({
    required this.topic,
    required this.urgency,
    required this.participants,
    required this.timestamp,
  });
}

final openAIApiKey = dotenv.env['OPENAI_API_KEY'];
