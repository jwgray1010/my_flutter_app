import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_dotenv/flutter_dotenv.dart';

final openAIApiKey = dotenv.env['OPENAI_API_KEY'];

class AdvancedToneAnalysisService {
  static final AdvancedToneAnalysisService _instance =
      AdvancedToneAnalysisService._internal();
  factory AdvancedToneAnalysisService() => _instance;
  AdvancedToneAnalysisService._internal();

  // Advanced multi-dimensional tone analysis with psychological insights
  final Map<String, Map<String, ToneIndicator>> _advancedToneMapping = {
    // Emotional Intelligence Dimensions
    'emotional_positivity': {
      'elated': ToneIndicator(
        'elated',
        1.0,
        'joy',
        'Extremely happy and excited',
      ),
      'thrilled': ToneIndicator(
        'thrilled',
        0.95,
        'joy',
        'Very excited and pleased',
      ),
      'delighted': ToneIndicator(
        'delighted',
        0.9,
        'joy',
        'Pleasantly surprised and happy',
      ),
      'grateful': ToneIndicator(
        'grateful',
        0.9,
        'appreciation',
        'Shows deep appreciation',
      ),
      'appreciate': ToneIndicator(
        'appreciate',
        0.85,
        'appreciation',
        'Values others\' efforts',
      ),
      'thankful': ToneIndicator(
        'thankful',
        0.8,
        'appreciation',
        'Expresses gratitude',
      ),
      'pleased': ToneIndicator(
        'pleased',
        0.75,
        'satisfaction',
        'Content and satisfied',
      ),
      'wonderful': ToneIndicator(
        'wonderful',
        0.8,
        'admiration',
        'Expresses admiration',
      ),
      'fantastic': ToneIndicator(
        'fantastic',
        0.8,
        'enthusiasm',
        'High enthusiasm',
      ),
      'amazing': ToneIndicator('amazing', 0.8, 'awe', 'Expresses wonder'),
      'brilliant': ToneIndicator(
        'brilliant',
        0.75,
        'admiration',
        'Intellectual appreciation',
      ),
      'excellent': ToneIndicator(
        'excellent',
        0.75,
        'approval',
        'Strong approval',
      ),
      'outstanding': ToneIndicator('outstanding', 0.8, 'praise', 'High praise'),
      'impressive': ToneIndicator(
        'impressive',
        0.7,
        'admiration',
        'Shows being impressed',
      ),
      'thank': ToneIndicator(
        'thank',
        0.7,
        'gratitude',
        'Basic gratitude expression',
      ),
      'thanks': ToneIndicator('thanks', 0.65, 'gratitude', 'Casual thanks'),
    },

    'emotional_negativity': {
      'furious': ToneIndicator(
        'furious',
        1.0,
        'rage',
        'Extreme anger - high conflict risk',
      ),
      'livid': ToneIndicator(
        'livid',
        0.98,
        'rage',
        'Very angry - relationship damage likely',
      ),
      'outraged': ToneIndicator(
        'outraged',
        0.95,
        'indignation',
        'Moral anger - requires immediate attention',
      ),
      'infuriated': ToneIndicator(
        'infuriated',
        0.9,
        'anger',
        'Very angry - de-escalation needed',
      ),
      'disgusted': ToneIndicator(
        'disgusted',
        0.9,
        'revulsion',
        'Strong negative reaction',
      ),
      'appalled': ToneIndicator(
        'appalled',
        0.85,
        'shock',
        'Shocked disapproval',
      ),
      'horrified': ToneIndicator(
        'horrified',
        0.85,
        'horror',
        'Extreme shock and dismay',
      ),
      'devastated': ToneIndicator(
        'devastated',
        0.8,
        'grief',
        'Deep emotional pain',
      ),
      'heartbroken': ToneIndicator(
        'heartbroken',
        0.8,
        'grief',
        'Emotional devastation',
      ),
      'hate': ToneIndicator(
        'hate',
        0.95,
        'hatred',
        'Strong negative emotion - avoid',
      ),
      'stupid': ToneIndicator(
        'stupid',
        0.9,
        'insult',
        'Insulting language - very damaging',
      ),
      'idiot': ToneIndicator(
        'idiot',
        0.95,
        'insult',
        'Personal attack - highly inappropriate',
      ),
      'terrible': ToneIndicator(
        'terrible',
        0.8,
        'strong_negative',
        'Very negative assessment',
      ),
      'awful': ToneIndicator(
        'awful',
        0.8,
        'strong_negative',
        'Extremely negative',
      ),
      'horrible': ToneIndicator(
        'horrible',
        0.8,
        'strong_negative',
        'Highly negative reaction',
      ),
      'disappointed': ToneIndicator(
        'disappointed',
        0.7,
        'disappointment',
        'Unmet expectations',
      ),
      'frustrated': ToneIndicator(
        'frustrated',
        0.65,
        'frustration',
        'Blocked goals or progress',
      ),
      'annoyed': ToneIndicator(
        'annoyed',
        0.6,
        'irritation',
        'Minor irritation',
      ),
      'bothered': ToneIndicator(
        'bothered',
        0.55,
        'mild_irritation',
        'Slight disturbance',
      ),
    },

    // Psychological Control & Power Dynamics
    'dominance_control': {
      'demand': ToneIndicator(
        'demand',
        0.9,
        'dominance',
        'Controlling language - may trigger resistance',
      ),
      'require': ToneIndicator(
        'require',
        0.8,
        'authority',
        'Authoritative but appropriate',
      ),
      'insist': ToneIndicator(
        'insist',
        0.85,
        'assertiveness',
        'Strong insistence - potential pushback',
      ),
      'must': ToneIndicator(
        'must',
        0.7,
        'necessity',
        'Expresses necessity - context dependent',
      ),
      'should': ToneIndicator(
        'should',
        0.6,
        'expectation',
        'Implies obligation',
      ),
      'need to': ToneIndicator(
        'need to',
        0.55,
        'requirement',
        'Expresses necessity',
      ),
      'have to': ToneIndicator(
        'have to',
        0.6,
        'obligation',
        'Indicates obligation',
      ),
      'will': ToneIndicator('will', 0.4, 'determination', 'Shows resolve'),
    },

    'submission_politeness': {
      'if you don\'t mind': ToneIndicator(
        'if you don\'t mind',
        0.9,
        'deference',
        'Very polite request',
      ),
      'when convenient': ToneIndicator(
        'when convenient',
        0.85,
        'consideration',
        'Respectful of others\' time',
      ),
      'if possible': ToneIndicator(
        'if possible',
        0.8,
        'flexibility',
        'Shows flexibility',
      ),
      'could you please': ToneIndicator(
        'could you please',
        0.85,
        'polite_request',
        'Very polite approach',
      ),
      'would you mind': ToneIndicator(
        'would you mind',
        0.8,
        'courteous_request',
        'Courteous language',
      ),
      'may I': ToneIndicator(
        'may I',
        0.75,
        'permission',
        'Asks permission respectfully',
      ),
      'might I suggest': ToneIndicator(
        'might I suggest',
        0.8,
        'diplomatic_suggestion',
        'Diplomatic approach',
      ),
      'please': ToneIndicator(
        'please',
        0.6,
        'politeness',
        'Basic politeness marker',
      ),
    },

    // Urgency & Time Pressure
    'time_pressure': {
      'immediately': ToneIndicator(
        'immediately',
        0.95,
        'urgent_demand',
        'Creates high pressure - use sparingly',
      ),
      'right now': ToneIndicator(
        'right now',
        0.9,
        'immediate_demand',
        'Very demanding - potential stress trigger',
      ),
      'asap': ToneIndicator(
        'asap',
        0.8,
        'urgency',
        'Business urgency - context matters',
      ),
      'urgent': ToneIndicator(
        'urgent',
        0.75,
        'priority',
        'Indicates high priority',
      ),
      'deadline': ToneIndicator(
        'deadline',
        0.7,
        'time_constraint',
        'Time-bound requirement',
      ),
      'soon': ToneIndicator(
        'soon',
        0.4,
        'mild_urgency',
        'Gentle time preference',
      ),
      'eventually': ToneIndicator(
        'eventually',
        0.2,
        'patience',
        'Shows patience',
      ),
    },

    // Cognitive & Intellectual Tone
    'intellectual_confidence': {
      'obviously': ToneIndicator(
        'obviously',
        0.8,
        'condescension',
        'May sound condescending - avoid',
      ),
      'clearly': ToneIndicator(
        'clearly',
        0.6,
        'assumption',
        'Assumes shared understanding',
      ),
      'of course': ToneIndicator(
        'of course',
        0.7,
        'expectation',
        'May invalidate others\' perspective',
      ),
      'naturally': ToneIndicator(
        'naturally',
        0.5,
        'assumption',
        'Assumes agreement',
      ),
      'certainly': ToneIndicator(
        'certainly',
        0.4,
        'confidence',
        'Shows confidence',
      ),
      'perhaps': ToneIndicator(
        'perhaps',
        0.3,
        'openness',
        'Shows openness to other views',
      ),
      'maybe': ToneIndicator(
        'maybe',
        0.25,
        'uncertainty',
        'Expresses uncertainty',
      ),
      'I think': ToneIndicator(
        'I think',
        0.2,
        'opinion',
        'Personal opinion marker',
      ),
      'in my opinion': ToneIndicator(
        'in my opinion',
        0.2,
        'subjective_view',
        'Clearly subjective',
      ),
    },

    // Empathy & Emotional Intelligence
    'empathy_markers': {
      'understand': ToneIndicator(
        'understand',
        0.6,
        'empathy',
        'Shows understanding',
      ),
      'realize': ToneIndicator(
        'realize',
        0.5,
        'awareness',
        'Acknowledges situation',
      ),
      'recognize': ToneIndicator(
        'recognize',
        0.5,
        'acknowledgment',
        'Acknowledges others\' position',
      ),
      'respect': ToneIndicator(
        'respect',
        0.6,
        'respect',
        'Shows respect for others',
      ),
      'sorry': ToneIndicator('sorry', 0.6, 'apology', 'Takes responsibility'),
      'apologize': ToneIndicator(
        'apologize',
        0.7,
        'formal_apology',
        'Formal accountability',
      ),
    },

    // Advanced Neurolinguistic Programming (NLP) Patterns
    'nlp_patterns': {
      'always': ToneIndicator(
        'always',
        0.8,
        'universal_quantifier',
        'Absolute statements can trigger resistance - overgeneralization',
      ),
      'never': ToneIndicator(
        'never',
        0.8,
        'universal_quantifier',
        'Absolute denial - may invalidate experiences',
      ),
      'everyone': ToneIndicator(
        'everyone',
        0.7,
        'universal_quantifier',
        'Assumes universal consensus - pressure tactic',
      ),
      'no one': ToneIndicator(
        'no one',
        0.75,
        'universal_quantifier',
        'Isolating language - can create defensiveness',
      ),
      'all': ToneIndicator(
        'all',
        0.6,
        'universal_quantifier',
        'Blanket statement - consider exceptions',
      ),
      'none': ToneIndicator(
        'none',
        0.6,
        'universal_quantifier',
        'Absolute exclusion - may be inaccurate',
      ),
      'can\'t': ToneIndicator(
        'can\'t',
        0.7,
        'modal_operator',
        'Limitation language - may limit possibilities',
      ),
      'won\'t': ToneIndicator(
        'won\'t',
        0.75,
        'modal_operator',
        'Resistance language - signals unwillingness',
      ),
      'impossible': ToneIndicator(
        'impossible',
        0.8,
        'modal_operator',
        'Absolute limitation - closes down options',
      ),
      'have to': ToneIndicator(
        'have to',
        0.6,
        'modal_operator',
        'Necessity language - implies no choice',
      ),
    },

    // Cultural Intelligence & Bias Detection
    'cultural_sensitivity': {
      'you people': ToneIndicator(
        'you people',
        0.95,
        'othering',
        'Potentially discriminatory language - creates in-group/out-group division',
      ),
      'those people': ToneIndicator(
        'those people',
        0.9,
        'othering',
        'Distancing language - may indicate bias',
      ),
      'typical': ToneIndicator(
        'typical',
        0.7,
        'stereotyping',
        'May reinforce stereotypes - context dependent',
      ),
      'all of you': ToneIndicator(
        'all of you',
        0.6,
        'generalization',
        'Group generalization - may alienate individuals',
      ),
      'your kind': ToneIndicator(
        'your kind',
        0.95,
        'categorization',
        'Highly problematic categorization language',
      ),
      'normal people': ToneIndicator(
        'normal people',
        0.8,
        'normalization',
        'Implies others are abnormal - exclusionary',
      ),
    },

    // Advanced Cognitive Load & Processing Patterns
    'cognitive_load': {
      'basically': ToneIndicator(
        'basically',
        0.6,
        'oversimplification',
        'May oversimplify complex topics',
      ),
      'just': ToneIndicator(
        'just',
        0.5,
        'minimization',
        'May minimize complexity or importance',
      ),
      'simply': ToneIndicator(
        'simply',
        0.6,
        'oversimplification',
        'May underestimate difficulty',
      ),
      'complicated': ToneIndicator(
        'complicated',
        0.4,
        'complexity_acknowledgment',
        'Acknowledges complexity',
      ),
      'complex': ToneIndicator(
        'complex',
        0.3,
        'complexity_acknowledgment',
        'Shows understanding of nuance',
      ),
      'nuanced': ToneIndicator(
        'nuanced',
        0.2,
        'sophistication',
        'Demonstrates sophisticated thinking',
      ),
    },

    // Persuasion & Influence Detection (Robert Cialdini's principles)
    'influence_patterns': {
      'limited time': ToneIndicator(
        'limited time',
        0.8,
        'scarcity',
        'Scarcity principle - creates urgency pressure',
      ),
      'exclusive': ToneIndicator(
        'exclusive',
        0.7,
        'scarcity',
        'Exclusivity appeal - may create FOMO',
      ),
      'everyone else': ToneIndicator(
        'everyone else',
        0.7,
        'social_proof',
        'Social proof appeal - bandwagon effect',
      ),
      'popular choice': ToneIndicator(
        'popular choice',
        0.6,
        'social_proof',
        'Majority influence appeal',
      ),
      'expert': ToneIndicator(
        'expert',
        0.5,
        'authority',
        'Authority appeal - legitimate if accurate',
      ),
      'proven': ToneIndicator(
        'proven',
        0.5,
        'authority',
        'Authority/evidence appeal',
      ),
      'return the favor': ToneIndicator(
        'return the favor',
        0.7,
        'reciprocity',
        'Reciprocity principle - obligation creation',
      ),
      'owe me': ToneIndicator(
        'owe me',
        0.8,
        'reciprocity',
        'Direct reciprocity demand - may create resentment',
      ),
    },

    // Micro-Expression Text Patterns (emotional leakage)
    'micro_expressions': {
      'fine.': ToneIndicator(
        'fine.',
        0.8,
        'suppressed_anger',
        'Period after "fine" suggests irritation',
      ),
      'whatever.': ToneIndicator(
        'whatever.',
        0.85,
        'dismissive_anger',
        'Dismissive resignation with anger undertones',
      ),
      'sure...': ToneIndicator(
        'sure...',
        0.7,
        'passive_resistance',
        'Ellipsis suggests reluctance or sarcasm',
      ),
      'ok...': ToneIndicator(
        'ok...',
        0.6,
        'uncertainty',
        'Trailing dots suggest hesitation or passive agreement',
      ),
      'right.': ToneIndicator(
        'right.',
        0.7,
        'skepticism',
        'Curt agreement may indicate disbelief',
      ),
      'interesting...': ToneIndicator(
        'interesting...',
        0.6,
        'polite_disagreement',
        'Diplomatic way of expressing doubt',
      ),
    },

    // Emotional Contagion Predictors
    'emotional_contagion': {
      'exciting': ToneIndicator(
        'exciting',
        0.8,
        'positive_contagion',
        'Likely to spread enthusiasm',
      ),
      'inspiring': ToneIndicator(
        'inspiring',
        0.85,
        'positive_contagion',
        'High potential for positive influence',
      ),
      'exhausting': ToneIndicator(
        'exhausting',
        0.7,
        'negative_contagion',
        'May spread fatigue or discouragement',
      ),
      'overwhelming': ToneIndicator(
        'overwhelming',
        0.75,
        'negative_contagion',
        'May create anxiety in others',
      ),
      'draining': ToneIndicator(
        'draining',
        0.8,
        'negative_contagion',
        'High risk of spreading negative energy',
      ),
      'energizing': ToneIndicator(
        'energizing',
        0.8,
        'positive_contagion',
        'Likely to boost others\' energy',
      ),
    },

    // Advanced Power Dynamics & Workplace Hierarchy
    'power_dynamics_advanced': {
      'as your': ToneIndicator(
        'as your',
        0.8,
        'hierarchy_assertion',
        'Explicit hierarchy reminder - may create tension',
      ),
      'under my': ToneIndicator(
        'under my',
        0.85,
        'dominance_assertion',
        'Strong dominance language',
      ),
      'above your pay grade': ToneIndicator(
        'above your pay grade',
        0.95,
        'status_dismissal',
        'Highly dismissive status-based put-down',
      ),
      'that\'s not your job': ToneIndicator(
        'that\'s not your job',
        0.8,
        'boundary_assertion',
        'Role boundary enforcement - context dependent',
      ),
      'stay in your lane': ToneIndicator(
        'stay in your lane',
        0.9,
        'territorial',
        'Territorial language - may shut down collaboration',
      ),
      'know your place': ToneIndicator(
        'know your place',
        0.95,
        'status_enforcement',
        'Extremely hierarchical - relationship damaging',
      ),
    },
  };

  // Advanced psychological analysis
  Future<AdvancedToneAnalysisResult> analyzeMessage(
    String message, {
    double sensitivity = 0.7,
    String targetTone = 'balanced',
    String context = 'general',
    String relationship = 'peer',
    String culturalContext = 'western',
  }) async {
    // Simulate advanced processing time
    await Future.delayed(const Duration(milliseconds: 800));

    final analysisResult = _performAdvancedAnalysis(
      message,
      sensitivity,
      targetTone,
      context,
      relationship,
      culturalContext,
    );

    return analysisResult;
  }

  AdvancedToneAnalysisResult _performAdvancedAnalysis(
    String message,
    double sensitivity,
    String targetTone,
    String context,
    String relationship,
    String culturalContext,
  ) {
    final lowerMessage = message.toLowerCase();

    // Multi-dimensional tone scoring
    Map<String, ToneDimension> toneDimensions = {};
    List<ToneFlag> flags = [];
    List<PsychologicalInsight> insights = [];

    // Analyze each dimension
    _advancedToneMapping.forEach((dimension, indicators) {
      double totalScore = 0.0;
      int matchCount = 0;
      List<String> triggeredIndicators = [];

      indicators.forEach((phrase, indicator) {
        if (lowerMessage.contains(phrase)) {
          totalScore += indicator.intensity;
          matchCount++;
          triggeredIndicators.add(phrase);

          // Generate flags for problematic patterns
          if (indicator.intensity > 0.8 &&
              (dimension.contains('negative') ||
                  dimension.contains('dominance'))) {
            flags.add(
              ToneFlag(
                type: 'warning',
                message: indicator.psychologicalImpact,
                suggestion: _generateSuggestionForIndicator(phrase, indicator),
                severity: indicator.intensity,
              ),
            );
          }
        }
      });

      if (matchCount > 0) {
        toneDimensions[dimension] = ToneDimension(
          name: dimension,
          score: totalScore / matchCount,
          confidence: _calculateConfidence(matchCount, message.length),
          triggeredIndicators: triggeredIndicators,
        );
      }
    });

    // Advanced pattern recognition
    final patterns = _detectCommunicationPatterns(message);
    final emotionalIntelligence = _assessEmotionalIntelligence(toneDimensions);
    final conflictRisk = _assessConflictRisk(toneDimensions, patterns);
    final relationshipImpact = _assessRelationshipImpact(
      toneDimensions,
      relationship,
    );

    // Generate psychological insights
    insights.addAll(_generatePsychologicalInsights(toneDimensions, patterns));

    // Create improved versions
    final improvements = _generateImprovedVersions(
      message,
      toneDimensions,
      context,
    );

    // Overall assessment
    final overallTone = _determineOverallTone(toneDimensions);
    final recommendations = _generateStrategicRecommendations(
      toneDimensions,
      patterns,
      context,
    );

    // Advanced neurological and behavioral analysis
    final neurolinguisticPatterns = _detectNeurolinguisticPatterns(message);
    final culturalSensitivity = _assessCulturalSensitivity(toneDimensions);
    final cognitiveLoad = _assessCognitiveLoad(message, toneDimensions);
    final influenceAttempts = _detectInfluenceAttempts(toneDimensions);
    final emotionalContagionRisk = _assessEmotionalContagionRisk(
      toneDimensions,
    );
    final powerDynamicsAdvanced = _analyzePowerDynamicsAdvanced(toneDimensions);
    final communicationEffectiveness = _calculateCommunicationEffectiveness(
      toneDimensions,
      patterns,
      neurolinguisticPatterns,
      cognitiveLoad,
    );

    // Advanced contextual awareness
    final contextualRecommendations = _generateContextualRecommendations(
      message,
      context,
      relationship,
      culturalContext,
      toneDimensions,
    );

    // ML-inspired pattern learning (simulated)
    final adaptiveSuggestions = _generateAdaptiveSuggestions(
      toneDimensions,
      patterns,
      context,
      relationship,
    );

    return AdvancedToneAnalysisResult(
      originalMessage: message,
      overallTone: overallTone,
      toneDimensions: toneDimensions,
      flags: flags,
      psychologicalInsights: insights,
      communicationPatterns: patterns,
      emotionalIntelligenceScore: emotionalIntelligence,
      conflictRiskLevel: conflictRisk,
      relationshipImpactScore: relationshipImpact,
      improvedVersions: improvements,
      strategicRecommendations: recommendations,
      analysisMetadata: AnalysisMetadata(
        sensitivity: sensitivity,
        context: context,
        relationship: relationship,
        culturalContext: culturalContext,
        analysisTimestamp: DateTime.now(),
      ),
      neurolinguisticPatterns: neurolinguisticPatterns,
      culturalSensitivity: culturalSensitivity,
      cognitiveLoad: cognitiveLoad,
      influenceAttempts: influenceAttempts,
      emotionalContagionRisk: emotionalContagionRisk,
      powerDynamicsAdvanced: powerDynamicsAdvanced,
      communicationEffectiveness: communicationEffectiveness,
      contextualRecommendations: contextualRecommendations,
      adaptiveSuggestions: adaptiveSuggestions,
    );
  }

  List<CommunicationPattern> _detectCommunicationPatterns(String message) {
    List<CommunicationPattern> patterns = [];

    // Pattern: Passive-aggressive
    if (message.toLowerCase().contains(
          RegExp(r'\b(fine|whatever|sure|ok)\b'),
        ) &&
        (message.contains('...') || message.contains('!!'))) {
      patterns.add(
        CommunicationPattern(
          'passive_aggressive',
          0.7,
          'May come across as dismissive or sarcastic',
        ),
      );
    }

    // Pattern: Overwhelming information
    if (message.split(' ').length > 50 && message.split('.').length > 3) {
      patterns.add(
        CommunicationPattern(
          'information_overload',
          0.6,
          'Message may be too long and complex',
        ),
      );
    }

    // Pattern: Assumption-heavy
    final assumptionWords = [
      'obviously',
      'clearly',
      'of course',
      'everyone knows',
    ];
    int assumptionCount = 0;
    for (String word in assumptionWords) {
      if (message.toLowerCase().contains(word)) assumptionCount++;
    }
    if (assumptionCount >= 2) {
      patterns.add(
        CommunicationPattern(
          'assumption_heavy',
          0.8,
          'Makes many assumptions about recipient\'s knowledge',
        ),
      );
    }

    return patterns;
  }

  double _assessEmotionalIntelligence(Map<String, ToneDimension> dimensions) {
    double score = 0.5; // Base score

    // Positive: Shows empathy
    if (dimensions.containsKey('empathy_markers')) {
      score += 0.2;
    }

    // Positive: Uses polite language
    if (dimensions.containsKey('submission_politeness')) {
      score += 0.15;
    }

    // Negative: Dominance without empathy
    if (dimensions.containsKey('dominance_control') &&
        !dimensions.containsKey('empathy_markers')) {
      score -= 0.2;
    }

    // Negative: High negativity
    if (dimensions.containsKey('emotional_negativity') &&
        dimensions['emotional_negativity']!.score > 0.7) {
      score -= 0.3;
    }

    return score.clamp(0.0, 1.0);
  }

  double _assessConflictRisk(
    Map<String, ToneDimension> dimensions,
    List<CommunicationPattern> patterns,
  ) {
    double risk = 0.0;

    // High-risk indicators
    if (dimensions.containsKey('emotional_negativity')) {
      risk += dimensions['emotional_negativity']!.score * 0.4;
    }

    if (dimensions.containsKey('dominance_control')) {
      risk += dimensions['dominance_control']!.score * 0.3;
    }

    // Pattern-based risk
    for (var pattern in patterns) {
      if (pattern.type == 'passive_aggressive') risk += 0.3;
      if (pattern.type == 'assumption_heavy') risk += 0.2;
    }

    return risk.clamp(0.0, 1.0);
  }

  double _assessRelationshipImpact(
    Map<String, ToneDimension> dimensions,
    String relationship,
  ) {
    double impact = 0.5; // Neutral base

    // Positive relationship builders
    if (dimensions.containsKey('empathy_markers')) {
      impact += 0.2;
    }
    if (dimensions.containsKey('submission_politeness')) {
      impact += 0.15;
    }
    if (dimensions.containsKey('emotional_positivity')) {
      impact += 0.1;
    }

    // Relationship damagers
    if (dimensions.containsKey('emotional_negativity')) {
      impact -= dimensions['emotional_negativity']!.score * 0.3;
    }
    if (dimensions.containsKey('dominance_control') && relationship == 'peer') {
      impact -= 0.2; // Dominance is worse with peers
    }

    return impact.clamp(0.0, 1.0);
  }

  List<PsychologicalInsight> _generatePsychologicalInsights(
    Map<String, ToneDimension> dimensions,
    List<CommunicationPattern> patterns,
  ) {
    List<PsychologicalInsight> insights = [];

    // Emotional regulation insight
    if (dimensions.containsKey('emotional_negativity') &&
        dimensions['emotional_negativity']!.score > 0.6) {
      insights.add(
        PsychologicalInsight(
          type: 'emotional_regulation',
          title: 'Emotional State Detection',
          description:
              'Your message suggests you may be experiencing strong negative emotions. This is normal, but expressing them directly might affect how your message is received.',
          recommendation:
              'Consider taking a moment to process these emotions before sending, or acknowledge them explicitly: "I\'m frustrated about this situation, and here\'s why..."',
          impactLevel: 'high',
        ),
      );
    }

    // Power dynamics insight
    if (dimensions.containsKey('dominance_control') &&
        dimensions['dominance_control']!.score > 0.7) {
      insights.add(
        PsychologicalInsight(
          type: 'power_dynamics',
          title: 'Authority Language Detected',
          description:
              'Your message uses language that establishes authority or control. While sometimes necessary, this can trigger resistance or defensiveness in others.',
          recommendation:
              'Consider adding collaborative language like "What do you think about..." or "How can we..." to balance authority with partnership.',
          impactLevel: 'medium',
        ),
      );
    }

    // Cognitive empathy insight
    if (!dimensions.containsKey('empathy_markers') &&
        (dimensions.containsKey('dominance_control') ||
            dimensions.containsKey('emotional_negativity'))) {
      insights.add(
        PsychologicalInsight(
          type: 'cognitive_empathy',
          title: 'Perspective-Taking Opportunity',
          description:
              'Your message focuses primarily on your own perspective. Adding acknowledgment of the other person\'s viewpoint can significantly improve communication effectiveness.',
          recommendation:
              'Try adding phrases like "I understand this might be challenging for you" or "I realize you may see this differently".',
          impactLevel: 'medium',
        ),
      );
    }

    return insights;
  }

  Map<String, String> _generateImprovedVersions(
    String message,
    Map<String, ToneDimension> dimensions,
    String context,
  ) {
    Map<String, String> versions = {};

    String improved = message;
    String diplomatic = message;
    String assertive = message;

    // Apply improvements based on detected issues
    if (dimensions.containsKey('emotional_negativity')) {
      improved = _softenNegativeLanguage(improved);
      diplomatic = _addEmpathyMarkers(improved);
    }

    if (dimensions.containsKey('dominance_control')) {
      diplomatic = _addCollaborativeLanguage(diplomatic);
      improved = _softenCommands(improved);
    }

    // Generate assertive version
    assertive = _makeMoreAssertive(message);

    versions['improved'] = improved;
    versions['diplomatic'] = diplomatic;
    versions['assertive'] = assertive;

    return versions;
  }

  List<StrategicRecommendation> _generateStrategicRecommendations(
    Map<String, ToneDimension> dimensions,
    List<CommunicationPattern> patterns,
    String context,
  ) {
    List<StrategicRecommendation> recommendations = [];

    // Context-specific recommendations
    if (context == 'conflict_resolution') {
      recommendations.add(
        StrategicRecommendation(
          category: 'conflict_resolution',
          title: 'De-escalation Strategy',
          description:
              'Focus on understanding the other person\'s perspective before presenting your own.',
          actionItems: [
            'Start with "Help me understand..."',
            'Acknowledge their concerns explicitly',
            'Use "and" instead of "but" when presenting alternatives',
          ],
          priority: 'high',
        ),
      );
    }

    return recommendations;
  }

  // Helper methods for message improvement
  String _softenNegativeLanguage(String message) {
    final replacements = {
      'hate': 'strongly dislike',
      'stupid': 'unclear',
      'ridiculous': 'surprising',
      'terrible': 'challenging',
      'awful': 'difficult',
      'disgusting': 'concerning',
    };

    String result = message;
    replacements.forEach((harsh, gentle) {
      result = result.replaceAll(RegExp(harsh, caseSensitive: false), gentle);
    });

    return result;
  }

  String _addEmpathyMarkers(String message) {
    if (!message.toLowerCase().contains(
      RegExp(r'\b(understand|realize|appreciate)\b'),
    )) {
      return 'I understand this situation may be frustrating. $message';
    }
    return message;
  }

  String _addCollaborativeLanguage(String message) {
    if (message.toLowerCase().startsWith(
      RegExp(r'\b(you must|you should|you need to)\b'),
    )) {
      return message.replaceFirst(
        RegExp(r'^you (must|should|need to)', caseSensitive: false),
        'Could we ',
      );
    }
    return message;
  }

  String _softenCommands(String message) {
    final softeners = {
      r'\bmust\b': 'need to',
      r'\bshould\b': 'could',
      r'\bhave to\b': 'might want to',
    };

    String result = message;
    softeners.forEach((pattern, replacement) {
      result = result.replaceAll(
        RegExp(pattern, caseSensitive: false),
        replacement,
      );
    });

    return result;
  }

  String _makeMoreAssertive(String message) {
    // Add assertive elements if message is too passive
    if (message.toLowerCase().contains(
      RegExp(r'\b(maybe|perhaps|might|possibly)\b'),
    )) {
      return message.replaceAll(
        RegExp(r'\b(maybe|perhaps)\b', caseSensitive: false),
        'I believe',
      );
    }
    return message;
  }

  String _generateSuggestionForIndicator(
    String phrase,
    ToneIndicator indicator,
  ) {
    // Generate contextual suggestions based on the specific indicator
    if (indicator.category == 'rage' || indicator.category == 'anger') {
      return 'Consider expressing your concern without inflammatory language. Try: "I\'m concerned about..." instead.';
    }
    if (indicator.category == 'dominance') {
      return 'Try using collaborative language: "Could we..." or "What if we..." instead of demands.';
    }
    if (indicator.category == 'condescension') {
      return 'Avoid assuming others\' knowledge level. Try "As you may know..." or simply state the information.';
    }
    return 'Consider rephrasing for better communication impact.';
  }

  double _calculateConfidence(int matchCount, int messageLength) {
    // Calculate confidence based on matches relative to message length
    if (messageLength < 10) return 0.3; // Too short for reliable analysis
    if (matchCount == 0) return 0.1;

    double ratio = matchCount / (messageLength / 10);
    return (ratio * 0.7 + 0.3).clamp(0.0, 1.0);
  }

  String _determineOverallTone(Map<String, ToneDimension> dimensions) {
    if (dimensions.isEmpty) return 'neutral';

    // Find the dimension with the highest score
    String dominantDimension = '';
    double highestScore = 0.0;

    dimensions.forEach((dimension, toneDim) {
      if (toneDim.score > highestScore) {
        highestScore = toneDim.score;
        dominantDimension = dimension;
      }
    });

    // Map dimensions to user-friendly tone names
    const dimensionToTone = {
      'emotional_positivity': 'positive',
      'emotional_negativity': 'negative',
      'dominance_control': 'assertive',
      'submission_politeness': 'polite',
      'time_pressure': 'urgent',
      'empathy_markers': 'empathetic',
      'intellectual_confidence': 'confident',
    };

    return dimensionToTone[dominantDimension] ?? 'complex';
  }

  // Advanced Neurolinguistic Pattern Detection
  List<NeurolinguisticPattern> _detectNeurolinguisticPatterns(String message) {
    List<NeurolinguisticPattern> patterns = [];
    final lowerMessage = message.toLowerCase();

    // Universal Quantifier Detection (NLP Meta-Model)
    final universalQuantifiers = [
      'always',
      'never',
      'everyone',
      'no one',
      'all',
      'none',
    ];
    for (String quantifier in universalQuantifiers) {
      if (lowerMessage.contains(quantifier)) {
        patterns.add(
          NeurolinguisticPattern(
            type: 'universal_quantifier',
            trigger: quantifier,
            cognitiveImpact:
                'Creates black-and-white thinking, may trigger counterexamples',
            recommendation:
                'Use qualifying language: "often", "rarely", "most people", "few people"',
            severity: 0.7,
          ),
        );
      }
    }

    // Modal Operator Detection (necessity/possibility)
    final modalOperators = [
      'can\'t',
      'won\'t',
      'impossible',
      'have to',
      'must',
    ];
    for (String modal in modalOperators) {
      if (lowerMessage.contains(modal)) {
        patterns.add(
          NeurolinguisticPattern(
            type: 'modal_operator',
            trigger: modal,
            cognitiveImpact:
                'Limits perceived options, may create psychological reactance',
            recommendation:
                'Expand possibilities: "haven\'t found a way yet", "prefer not to", "one option is"',
            severity: 0.6,
          ),
        );
      }
    }

    // Complex Equivalence Detection (X means Y)
    if (lowerMessage.contains(
      RegExp(r'\bmeans\b|\bequals\b|\bis\s+the\s+same\s+as\b'),
    )) {
      patterns.add(
        NeurolinguisticPattern(
          type: 'complex_equivalence',
          trigger: 'equivalence language',
          cognitiveImpact: 'Creates oversimplified cause-effect relationships',
          recommendation:
              'Use more nuanced language: "might suggest", "could indicate", "one possibility is"',
          severity: 0.5,
        ),
      );
    }

    return patterns;
  }

  // Cultural Sensitivity Assessment
  CulturalSensitivityScore _assessCulturalSensitivity(
    Map<String, ToneDimension> dimensions,
  ) {
    double riskScore = 0.0;
    List<String> risks = [];
    List<String> recommendations = [];

    if (dimensions.containsKey('cultural_sensitivity')) {
      riskScore = dimensions['cultural_sensitivity']!.score;
      risks.addAll(dimensions['cultural_sensitivity']!.triggeredIndicators);

      if (riskScore > 0.7) {
        recommendations.add(
          'Review language for potential cultural insensitivity',
        );
        recommendations.add(
          'Consider how this might be perceived by diverse audiences',
        );
        recommendations.add(
          'Use inclusive language that doesn\'t create in-group/out-group divisions',
        );
      }
    }

    // Assess for Western-centric language patterns
    if (dimensions.containsKey('dominance_control') &&
        !dimensions.containsKey('submission_politeness') &&
        riskScore < 0.3) {
      recommendations.add(
        'Consider that direct communication styles may not be preferred in all cultures',
      );
    }

    return CulturalSensitivityScore(
      riskLevel: riskScore,
      identifiedRisks: risks,
      recommendations: recommendations,
      culturalAdaptability: (1.0 - riskScore).clamp(0.0, 1.0),
    );
  }

  // Cognitive Load Assessment
  CognitiveLoadAnalysis _assessCognitiveLoad(
    String message,
    Map<String, ToneDimension> dimensions,
  ) {
    double loadScore = 0.0;
    List<String> loadFactors = [];

    // Sentence complexity
    final sentences = message
        .split(RegExp(r'[.!?]'))
        .where((s) => s.trim().isNotEmpty)
        .toList();
    final avgWordsPerSentence = sentences.isEmpty
        ? 0
        : message.split(' ').length / sentences.length;

    if (avgWordsPerSentence > 20) {
      loadScore += 0.3;
      loadFactors.add('Long sentences increase cognitive processing time');
    }

    // Information density
    final informationWords = [
      'data',
      'analysis',
      'research',
      'study',
      'statistics',
      'metrics',
    ];
    int infoWordCount = 0;
    for (String word in informationWords) {
      if (message.toLowerCase().contains(word)) infoWordCount++;
    }

    if (infoWordCount > 3) {
      loadScore += 0.2;
      loadFactors.add('High information density may overwhelm recipient');
    }

    // Complexity markers
    if (dimensions.containsKey('cognitive_load')) {
      final cognitiveScore = dimensions['cognitive_load']!.score;
      if (cognitiveScore > 0.5) {
        loadScore += 0.2;
        loadFactors.add(
          'Language complexity may require significant mental processing',
        );
      }
    }

    // Jargon detection
    final jargonPatterns = [
      'leverage',
      'synergy',
      'optimize',
      'streamline',
      'paradigm',
    ];
    int jargonCount = 0;
    for (String jargon in jargonPatterns) {
      if (message.toLowerCase().contains(jargon)) jargonCount++;
    }

    if (jargonCount > 2) {
      loadScore += 0.25;
      loadFactors.add('Business jargon may create comprehension barriers');
    }

    return CognitiveLoadAnalysis(
      loadLevel: loadScore.clamp(0.0, 1.0),
      factors: loadFactors,
      comprehensibilityScore: (1.0 - loadScore).clamp(0.0, 1.0),
      processingTimeEstimate: _estimateProcessingTime(
        message.length,
        loadScore,
      ),
    );
  }

  // Influence Attempt Detection (Cialdini's principles)
  InfluenceAnalysis _detectInfluenceAttempts(
    Map<String, ToneDimension> dimensions,
  ) {
    List<InfluenceAttempt> attempts = [];
    double totalInfluenceScore = 0.0;

    if (dimensions.containsKey('influence_patterns')) {
      final influenceScore = dimensions['influence_patterns']!.score;
      totalInfluenceScore = influenceScore;

      for (String indicator
          in dimensions['influence_patterns']!.triggeredIndicators) {
        InfluenceType type = _categorizeInfluenceAttempt(indicator);
        attempts.add(
          InfluenceAttempt(
            type: type,
            trigger: indicator,
            ethicalRating: _assessInfluenceEthics(type, indicator),
            effectiveness: _predictInfluenceEffectiveness(type),
          ),
        );
      }
    }

    return InfluenceAnalysis(
      overallInfluenceScore: totalInfluenceScore,
      attempts: attempts,
      ethicalityScore: attempts.isEmpty
          ? 1.0
          : attempts.map((a) => a.ethicalRating).reduce((a, b) => a + b) /
                attempts.length,
      resistanceRisk: _calculateResistanceRisk(attempts),
    );
  }

  // Emotional Contagion Risk Assessment
  EmotionalContagionAnalysis _assessEmotionalContagionRisk(
    Map<String, ToneDimension> dimensions,
  ) {
    double positiveContagionRisk = 0.0;
    double negativeContagionRisk = 0.0;
    List<String> contagionTriggers = [];

    if (dimensions.containsKey('emotional_contagion')) {
      final contagionScore = dimensions['emotional_contagion']!.score;

      for (String trigger
          in dimensions['emotional_contagion']!.triggeredIndicators) {
        contagionTriggers.add(trigger);
        if (_isPositiveContagion(trigger)) {
          positiveContagionRisk += contagionScore * 0.3;
        } else {
          negativeContagionRisk += contagionScore * 0.3;
        }
      }
    }

    // Factor in emotional intensity from other dimensions
    if (dimensions.containsKey('emotional_negativity')) {
      negativeContagionRisk += dimensions['emotional_negativity']!.score * 0.4;
    }
    if (dimensions.containsKey('emotional_positivity')) {
      positiveContagionRisk += dimensions['emotional_positivity']!.score * 0.3;
    }

    return EmotionalContagionAnalysis(
      positiveContagionRisk: positiveContagionRisk.clamp(0.0, 1.0),
      negativeContagionRisk: negativeContagionRisk.clamp(0.0, 1.0),
      triggers: contagionTriggers,
      networkImpactPrediction: _predictNetworkImpact(
        positiveContagionRisk,
        negativeContagionRisk,
      ),
    );
  }

  // Advanced Power Dynamics Analysis
  PowerDynamicsAnalysis _analyzePowerDynamicsAdvanced(
    Map<String, ToneDimension> dimensions,
  ) {
    double hierarchyAssertion = 0.0;
    double collaborationScore = 0.5; // Start neutral
    List<String> powerMarkers = [];

    if (dimensions.containsKey('power_dynamics_advanced')) {
      hierarchyAssertion = dimensions['power_dynamics_advanced']!.score;
      powerMarkers.addAll(
        dimensions['power_dynamics_advanced']!.triggeredIndicators,
      );
    }

    if (dimensions.containsKey('dominance_control')) {
      hierarchyAssertion += dimensions['dominance_control']!.score * 0.3;
    }

    if (dimensions.containsKey('submission_politeness')) {
      collaborationScore += dimensions['submission_politeness']!.score * 0.3;
    }

    if (dimensions.containsKey('empathy_markers')) {
      collaborationScore += dimensions['empathy_markers']!.score * 0.2;
    }

    return PowerDynamicsAnalysis(
      hierarchyAssertionLevel: hierarchyAssertion.clamp(0.0, 1.0),
      collaborationLevel: collaborationScore.clamp(0.0, 1.0),
      powerImbalanceRisk: _calculatePowerImbalanceRisk(
        hierarchyAssertion,
        collaborationScore,
      ),
      markers: powerMarkers,
      relationshipThreat: hierarchyAssertion > 0.7
          ? 'high'
          : hierarchyAssertion > 0.4
          ? 'medium'
          : 'low',
    );
  }

  // Communication Effectiveness Calculator (ML-inspired)
  double _calculateCommunicationEffectiveness(
    Map<String, ToneDimension> dimensions,
    List<CommunicationPattern> patterns,
    List<NeurolinguisticPattern> nlpPatterns,
    CognitiveLoadAnalysis cognitiveLoad,
  ) {
    double effectiveness = 0.5; // Baseline

    // Positive factors
    if (dimensions.containsKey('empathy_markers')) {
      effectiveness += dimensions['empathy_markers']!.score * 0.15;
    }
    if (dimensions.containsKey('submission_politeness')) {
      effectiveness += dimensions['submission_politeness']!.score * 0.1;
    }
    if (dimensions.containsKey('emotional_positivity')) {
      effectiveness += dimensions['emotional_positivity']!.score * 0.1;
    }

    // Negative factors
    if (dimensions.containsKey('emotional_negativity')) {
      effectiveness -= dimensions['emotional_negativity']!.score * 0.2;
    }

    // Cognitive load penalty
    effectiveness -= cognitiveLoad.loadLevel * 0.15;

    // NLP pattern penalties
    for (var pattern in nlpPatterns) {
      effectiveness -= pattern.severity * 0.1;
    }

    // Communication pattern adjustments
    for (var pattern in patterns) {
      switch (pattern.type) {
        case 'passive_aggressive':
          effectiveness -= 0.2;
          break;
        case 'information_overload':
          effectiveness -= 0.15;
          break;
        case 'assumption_heavy':
          effectiveness -= 0.1;
          break;
      }
    }

    return effectiveness.clamp(0.0, 1.0);
  }

  // Contextual Recommendations Generator
  List<ContextualRecommendation> _generateContextualRecommendations(
    String message,
    String context,
    String relationship,
    String culturalContext,
    Map<String, ToneDimension> dimensions,
  ) {
    List<ContextualRecommendation> recommendations = [];

    // Time-sensitive contexts
    if (context == 'urgent') {
      recommendations.add(
        ContextualRecommendation(
          context: 'urgency',
          recommendation:
              'When communicating urgency, explain the "why" to prevent resistance',
          rationale:
              'People respond better to urgent requests when they understand the reasoning',
          culturalNote: culturalContext == 'western'
              ? 'Direct urgency is generally acceptable'
              : 'Consider more indirect approaches in high-context cultures',
        ),
      );
    }

    // Relationship-specific advice
    if (relationship == 'superior' &&
        dimensions.containsKey('dominance_control')) {
      recommendations.add(
        ContextualRecommendation(
          context: 'hierarchy',
          recommendation: 'Balance authority with respect for autonomy',
          rationale:
              'Effective leaders provide direction while preserving dignity',
          culturalNote:
              'Power distance expectations vary significantly across cultures',
        ),
      );
    }

    // Cultural context adjustments
    if (culturalContext == 'eastern' &&
        dimensions.containsKey('dominance_control')) {
      recommendations.add(
        ContextualRecommendation(
          context: 'cultural',
          recommendation: 'Consider more indirect communication approaches',
          rationale:
              'High-context cultures often prefer implicit communication',
          culturalNote: 'Face-saving is crucial - avoid direct confrontation',
        ),
      );
    }

    return recommendations;
  }

  // Adaptive Suggestions (simulated ML learning)
  List<AdaptiveSuggestion> _generateAdaptiveSuggestions(
    Map<String, ToneDimension> dimensions,
    List<CommunicationPattern> patterns,
    String context,
    String relationship,
  ) {
    List<AdaptiveSuggestion> suggestions = [];

    // Pattern-based learning simulation
    if (patterns.any((p) => p.type == 'passive_aggressive')) {
      suggestions.add(
        AdaptiveSuggestion(
          type: 'behavioral_pattern',
          suggestion:
              'Your communication style shows indirect patterns. Direct expression might be more effective.',
          confidence: 0.75,
          learningSource: 'pattern_recognition',
          adaptationLevel: 'high',
        ),
      );
    }

    // Relationship learning
    if (relationship == 'peer' && dimensions.containsKey('dominance_control')) {
      suggestions.add(
        AdaptiveSuggestion(
          type: 'relationship_optimization',
          suggestion:
              'With peers, collaborative language often works better than directive language.',
          confidence: 0.8,
          learningSource: 'relationship_analysis',
          adaptationLevel: 'medium',
        ),
      );
    }

    return suggestions;
  }

  // Helper methods for advanced analysis
  int _estimateProcessingTime(int messageLength, double cognitiveLoad) {
    // Base reading time + cognitive load penalty
    int baseTime = (messageLength / 250 * 60).round(); // ~250 words per minute
    int cognitiveLoadPenalty = (cognitiveLoad * 30)
        .round(); // Up to 30 second penalty
    return baseTime + cognitiveLoadPenalty;
  }

  InfluenceType _categorizeInfluenceAttempt(String indicator) {
    if (['limited time', 'exclusive'].contains(indicator)) {
      return InfluenceType.scarcity;
    }
    if (['everyone else', 'popular choice'].contains(indicator)) {
      return InfluenceType.socialProof;
    }
    if (['expert', 'proven'].contains(indicator)) {
      return InfluenceType.authority;
    }
    if (['return the favor', 'owe me'].contains(indicator)) {
      return InfluenceType.reciprocity;
    }
    return InfluenceType.other;
  }

  double _assessInfluenceEthics(InfluenceType type, String indicator) {
    // Ethical scoring based on manipulation potential
    switch (type) {
      case InfluenceType.scarcity:
        return indicator == 'limited time'
            ? 0.6
            : 0.4; // False scarcity is less ethical
      case InfluenceType.authority:
        return 0.8; // Generally ethical if accurate
      case InfluenceType.socialProof:
        return 0.7; // Moderately ethical
      case InfluenceType.reciprocity:
        return indicator == 'owe me'
            ? 0.3
            : 0.6; // Direct obligation demands are less ethical
      default:
        return 0.5;
    }
  }

  double _predictInfluenceEffectiveness(InfluenceType type) {
    // Effectiveness based on psychological research
    switch (type) {
      case InfluenceType.scarcity:
        return 0.8;
      case InfluenceType.socialProof:
        return 0.75;
      case InfluenceType.authority:
        return 0.7;
      case InfluenceType.reciprocity:
        return 0.85;
      default:
        return 0.5;
    }
  }

  double _calculateResistanceRisk(List<InfluenceAttempt> attempts) {
    if (attempts.isEmpty) return 0.0;

    double risk = 0.0;
    for (var attempt in attempts) {
      if (attempt.ethicalRating < 0.5) risk += 0.3;
      if (attempt.effectiveness > 0.8 && attempt.ethicalRating < 0.6) {
        risk += 0.2;
      }
    }

    return risk.clamp(0.0, 1.0);
  }

  bool _isPositiveContagion(String trigger) {
    return ['exciting', 'inspiring', 'energizing'].contains(trigger);
  }

  String _predictNetworkImpact(double positiveRisk, double negativeRisk) {
    if (negativeRisk > 0.7) return 'high_negative_spread';
    if (positiveRisk > 0.7) return 'high_positive_spread';
    if (negativeRisk > 0.4) return 'moderate_negative_spread';
    if (positiveRisk > 0.4) return 'moderate_positive_spread';
    return 'minimal_emotional_spread';
  }

  double _calculatePowerImbalanceRisk(
    double hierarchyAssertion,
    double collaboration,
  ) {
    // High hierarchy + low collaboration = high risk
    if (hierarchyAssertion > 0.7 && collaboration < 0.3) return 0.9;
    if (hierarchyAssertion > 0.5 && collaboration < 0.4) return 0.6;
    return math.max(0.0, (hierarchyAssertion - collaboration) * 0.5);
  }
}

// Advanced data classes
class ToneIndicator {
  final String phrase;
  final double intensity;
  final String category;
  final String psychologicalImpact;

  const ToneIndicator(
    this.phrase,
    this.intensity,
    this.category,
    this.psychologicalImpact,
  );
}

class ToneDimension {
  final String name;
  final double score;
  final double confidence;
  final List<String> triggeredIndicators;

  const ToneDimension({
    required this.name,
    required this.score,
    required this.confidence,
    required this.triggeredIndicators,
  });
}

class ToneFlag {
  final String type;
  final String message;
  final String suggestion;
  final double severity;

  const ToneFlag({
    required this.type,
    required this.message,
    required this.suggestion,
    required this.severity,
  });
}

class PsychologicalInsight {
  final String type;
  final String title;
  final String description;
  final String recommendation;
  final String impactLevel;

  const PsychologicalInsight({
    required this.type,
    required this.title,
    required this.description,
    required this.recommendation,
    required this.impactLevel,
  });
}

class CommunicationPattern {
  final String type;
  final double confidence;
  final String description;

  const CommunicationPattern(this.type, this.confidence, this.description);
}

class StrategicRecommendation {
  final String category;
  final String title;
  final String description;
  final List<String> actionItems;
  final String priority;

  const StrategicRecommendation({
    required this.category,
    required this.title,
    required this.description,
    required this.actionItems,
    required this.priority,
  });
}

class AnalysisMetadata {
  final double sensitivity;
  final String context;
  final String relationship;
  final String culturalContext;
  final DateTime analysisTimestamp;

  const AnalysisMetadata({
    required this.sensitivity,
    required this.context,
    required this.relationship,
    required this.culturalContext,
    required this.analysisTimestamp,
  });
}

class AdvancedToneAnalysisResult {
  final String originalMessage;
  final String overallTone;
  final Map<String, ToneDimension> toneDimensions;
  final List<ToneFlag> flags;
  final List<PsychologicalInsight> psychologicalInsights;
  final List<CommunicationPattern> communicationPatterns;
  final double emotionalIntelligenceScore;
  final double conflictRiskLevel;
  final double relationshipImpactScore;
  final Map<String, String> improvedVersions;
  final List<StrategicRecommendation> strategicRecommendations;
  final AnalysisMetadata analysisMetadata;

  // Advanced AI Analysis Results
  final List<NeurolinguisticPattern> neurolinguisticPatterns;
  final CulturalSensitivityScore culturalSensitivity;
  final CognitiveLoadAnalysis cognitiveLoad;
  final InfluenceAnalysis influenceAttempts;
  final EmotionalContagionAnalysis emotionalContagionRisk;
  final PowerDynamicsAnalysis powerDynamicsAdvanced;
  final double communicationEffectiveness;
  final List<ContextualRecommendation> contextualRecommendations;
  final List<AdaptiveSuggestion> adaptiveSuggestions;

  const AdvancedToneAnalysisResult({
    required this.originalMessage,
    required this.overallTone,
    required this.toneDimensions,
    required this.flags,
    required this.psychologicalInsights,
    required this.communicationPatterns,
    required this.emotionalIntelligenceScore,
    required this.conflictRiskLevel,
    required this.relationshipImpactScore,
    required this.improvedVersions,
    required this.strategicRecommendations,
    required this.analysisMetadata,
    required this.neurolinguisticPatterns,
    required this.culturalSensitivity,
    required this.cognitiveLoad,
    required this.influenceAttempts,
    required this.emotionalContagionRisk,
    required this.powerDynamicsAdvanced,
    required this.communicationEffectiveness,
    required this.contextualRecommendations,
    required this.adaptiveSuggestions,
  });

  // Legacy compatibility for existing code
  String get dominantTone => overallTone;
  double get confidence => toneDimensions.values.isNotEmpty
      ? toneDimensions.values.first.confidence
      : 0.5;
  Map<String, double> get toneScores {
    Map<String, double> scores = {};
    toneDimensions.forEach((key, value) {
      scores[key] = value.score;
    });
    return scores;
  }

  String get message => originalMessage;
  List<String> get suggestions =>
      psychologicalInsights.map((i) => i.recommendation).toList();
  String get improvedMessage => improvedVersions['improved'] ?? originalMessage;
  Map<String, dynamic> get analysisDetails => {
    'score': confidence,
    'tone': overallTone,
    'breakdown': toneScores,
    'emotional_intelligence': emotionalIntelligenceScore,
    'conflict_risk': conflictRiskLevel,
    'relationship_impact': relationshipImpactScore,
  };
}

// Legacy aliases for backward compatibility
typedef ToneAnalysisService = AdvancedToneAnalysisService;
typedef ToneAnalysisResult = AdvancedToneAnalysisResult;

// Advanced AI Analysis Data Classes
class NeurolinguisticPattern {
  final String type;
  final String trigger;
  final String cognitiveImpact;
  final String recommendation;
  final double severity;

  const NeurolinguisticPattern({
    required this.type,
    required this.trigger,
    required this.cognitiveImpact,
    required this.recommendation,
    required this.severity,
  });
}

class CulturalSensitivityScore {
  final double riskLevel;
  final List<String> identifiedRisks;
  final List<String> recommendations;
  final double culturalAdaptability;

  const CulturalSensitivityScore({
    required this.riskLevel,
    required this.identifiedRisks,
    required this.recommendations,
    required this.culturalAdaptability,
  });
}

class CognitiveLoadAnalysis {
  final double loadLevel;
  final List<String> factors;
  final double comprehensibilityScore;
  final int processingTimeEstimate;

  const CognitiveLoadAnalysis({
    required this.loadLevel,
    required this.factors,
    required this.comprehensibilityScore,
    required this.processingTimeEstimate,
  });
}

enum InfluenceType {
  scarcity,
  socialProof,
  authority,
  reciprocity,
  commitment,
  liking,
  other,
}

class InfluenceAttempt {
  final InfluenceType type;
  final String trigger;
  final double ethicalRating;
  final double effectiveness;

  const InfluenceAttempt({
    required this.type,
    required this.trigger,
    required this.ethicalRating,
    required this.effectiveness,
  });
}

class InfluenceAnalysis {
  final double overallInfluenceScore;
  final List<InfluenceAttempt> attempts;
  final double ethicalityScore;
  final double resistanceRisk;

  const InfluenceAnalysis({
    required this.overallInfluenceScore,
    required this.attempts,
    required this.ethicalityScore,
    required this.resistanceRisk,
  });
}

class EmotionalContagionAnalysis {
  final double positiveContagionRisk;
  final double negativeContagionRisk;
  final List<String> triggers;
  final String networkImpactPrediction;

  const EmotionalContagionAnalysis({
    required this.positiveContagionRisk,
    required this.negativeContagionRisk,
    required this.triggers,
    required this.networkImpactPrediction,
  });
}

class PowerDynamicsAnalysis {
  final double hierarchyAssertionLevel;
  final double collaborationLevel;
  final double powerImbalanceRisk;
  final List<String> markers;
  final String relationshipThreat;

  const PowerDynamicsAnalysis({
    required this.hierarchyAssertionLevel,
    required this.collaborationLevel,
    required this.powerImbalanceRisk,
    required this.markers,
    required this.relationshipThreat,
  });
}

class ContextualRecommendation {
  final String context;
  final String recommendation;
  final String rationale;
  final String culturalNote;

  const ContextualRecommendation({
    required this.context,
    required this.recommendation,
    required this.rationale,
    required this.culturalNote,
  });
}

class AdaptiveSuggestion {
  final String type;
  final String suggestion;
  final double confidence;
  final String learningSource;
  final String adaptationLevel;

  const AdaptiveSuggestion({
    required this.type,
    required this.suggestion,
    required this.confidence,
    required this.learningSource,
    required this.adaptationLevel,
  });
}
