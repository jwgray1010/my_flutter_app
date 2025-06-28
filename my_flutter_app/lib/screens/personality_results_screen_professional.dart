import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_button.dart';

class PersonalityResultsScreenProfessional extends StatefulWidget {
  final List<String> answers;
  final List<String>? communicationAnswers; // Optional: pass communication answers

  const PersonalityResultsScreenProfessional({
    super.key,
    required this.answers,
    this.communicationAnswers,
  });

  @override
  State<PersonalityResultsScreenProfessional> createState() =>
      _PersonalityResultsScreenProfessionalState();
}

class _PersonalityResultsScreenProfessionalState
    extends State<PersonalityResultsScreenProfessional>
    with TickerProviderStateMixin {
  static const Map<String, String> typeLabels = {
    'A': "Anxious Connector",
    'B': "Secure Communicator",
    'C': "Avoidant Thinker",
    'D': "Disorganized (Mixed Signals)",
  };

  static const Map<String, String> typeDescriptions = {
    'A':
        "You crave deep connection but sometimes worry about your relationships. You're highly empathetic and intuitive about others' emotions.",
    'B':
        "You communicate openly and handle conflicts constructively. You're comfortable with intimacy and independence.",
    'C':
        "You value your independence and prefer to process emotions internally. You're self-reliant and thoughtful in your approach.",
    'D':
        "You have a complex communication style that varies based on the situation. You're adaptable but sometimes unpredictable.",
  };

  static const Map<String, List<String>> typeStrengths = {
    'A': [
      "Highly empathetic",
      "Intuitive about emotions",
      "Seeks deep connection",
      "Passionate communicator",
    ],
    'B': [
      "Balanced approach",
      "Clear communication",
      "Handles conflict well",
      "Emotionally stable",
    ],
    'C': [
      "Independent thinker",
      "Self-reliant",
      "Thoughtful processor",
      "Respects boundaries",
    ],
    'D': [
      "Adaptable",
      "Complex understanding",
      "Situationally aware",
      "Versatile approach",
    ],
  };

  static const Map<String, String> commLabels = {
    'assertive': "Assertive",
    'passive': "Passive",
    'aggressive': "Aggressive",
    'passive-aggressive': "Passive-Aggressive",
  };

  static const Map<String, String> commDescriptions = {
    'assertive': "Clear, direct, respectful communication.",
    'passive': "Avoids conflict, may not express needs.",
    'aggressive': "Forceful, dominating, may disregard others.",
    'passive-aggressive': "Indirect, may express anger subtly.",
  };

  static const Map<String, Color> commColors = {
    'assertive': Color(0xFF4CAF50), // Green
    'passive': Color(0xFFFFD600), // Yellow
    'aggressive': Color(0xFFFF1744), // Red
    'passive-aggressive': Color(0xFF9C27B0), // Purple
  };

  late AnimationController _chartController;
  late AnimationController _contentController;
  late Animation<double> _chartAnimation;
  late Animation<double> _contentAnimation;

  @override
  void initState() {
    super.initState();
    _chartController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _chartAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _chartController, curve: Curves.easeOutCubic),
    );

    _contentAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic),
    );

    _chartController.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      _contentController.forward();
    });
  }

  @override
  void dispose() {
    _chartController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Map<String, Color> get typeColors => {
        'A': AppTheme.of(context).error,
        'B': AppTheme.of(context).success,
        'C': AppTheme.of(context).info,
        'D': AppTheme.of(context).warning,
      };

  // Mock: Determine dominant communication style from answers (replace with real logic)
  String getDominantCommStyle() {
    // If you have communicationAnswers, count them
    final commAnswers = widget.communicationAnswers ?? [];
    if (commAnswers.isEmpty) return 'assertive'; // fallback
    final Map<String, int> counts = {
      'assertive': 0,
      'passive': 0,
      'aggressive': 0,
      'passive-aggressive': 0,
    };
    for (final ans in commAnswers) {
      final key = ans.toLowerCase();
      if (counts.containsKey(key)) counts[key] = counts[key]! + 1;
    }
    String dominant = 'assertive';
    int max = 0;
    counts.forEach((k, v) {
      if (v > max) {
        dominant = k;
        max = v;
      }
    });
    return dominant;
  }

  // Personalized tip based on attachment and communication style
  String getPersonalizedTip(String type, String commStyle) {
    if (type == 'B' && commStyle == 'assertive') {
      return "Tip: As a Secure Communicator, keep using open and honest language.";
    }
    if (type == 'A') {
      return "Tip: Practice self-reassurance and communicate your needs calmly.";
    }
    if (type == 'C') {
      return "Tip: Share your feelings when comfortable—openness builds trust.";
    }
    if (type == 'D') {
      return "Tip: Notice your patterns and try to express your needs directly.";
    }
    if (commStyle == 'passive') {
      return "Tip: Try to express your needs more openly.";
    }
    if (commStyle == 'aggressive') {
      return "Tip: Pause before responding and focus on empathy.";
    }
    if (commStyle == 'passive-aggressive') {
      return "Tip: Practice direct communication for clarity.";
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    // Count each type
    final Map<String, int> counts = {'A': 0, 'B': 0, 'C': 0, 'D': 0};
    for (final type in widget.answers) {
      if (counts.containsKey(type)) counts[type] = counts[type]! + 1;
    }

    // Find the dominant type
    String dominantType = 'A';
    int maxCount = counts['A']!;
    counts.forEach((k, v) {
      if (v > maxCount) {
        dominantType = k;
        maxCount = v;
      }
    });

    // Pie chart data
    final totalAnswers = widget.answers.isNotEmpty
        ? widget.answers.length
        : 15; // fallback to 15 for mock data
    final List<PieChartSectionData> pieSections = counts.entries
        .where((e) => e.value > 0)
        .map(
          (e) => PieChartSectionData(
            color: typeColors[e.key],
            value: e.value.toDouble(),
            title: e.value > 0
                ? '${((e.value / totalAnswers) * 100).toInt()}%'
                : '',
            titleStyle: theme.typography.bodySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            radius: 80,
            titlePositionPercentageOffset: 0.6,
          ),
        )
        .toList();

    // Communication style logic
    final String dominantCommStyle = getDominantCommStyle();
    final Color commColor = commColors[dominantCommStyle] ?? Colors.grey;
    final String commLabel = commLabels[dominantCommStyle] ?? 'Unknown';
    final String commDesc = commDescriptions[dominantCommStyle] ?? '';

    final String tip = getPersonalizedTip(dominantType, dominantCommStyle);

    return Scaffold(
      backgroundColor: theme.backgroundPrimary,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [theme.backgroundPrimary, theme.backgroundSecondary],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(theme.spacing.lg),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/home',
                        (route) => false,
                      ),
                      child: Container(
                        padding: EdgeInsets.all(theme.spacing.sm),
                        decoration: BoxDecoration(
                          color: theme.surfacePrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            theme.borderRadius.md,
                          ),
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
                        'Your Results',
                        style: theme.typography.headingLarge.copyWith(
                          color: theme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 44), // Balance the logo button
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: theme.spacing.lg),
                  child: Column(
                    children: [
                      // Logo and main title
                      Container(
                        padding: EdgeInsets.all(theme.spacing.xl),
                        decoration: BoxDecoration(
                          color: theme.surfacePrimary,
                          borderRadius: BorderRadius.circular(
                            theme.borderRadius.lg,
                          ),
                          boxShadow: theme.shadows.medium,
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [theme.primary, theme.secondary],
                                ),
                                borderRadius: BorderRadius.circular(
                                  theme.borderRadius.lg,
                                ),
                                boxShadow: theme.shadows.small,
                              ),
                              child: Icon(
                                Icons.psychology_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            SizedBox(height: theme.spacing.lg),
                            Text(
                              'Your Communication Type',
                              style: theme.typography.headingMedium.copyWith(
                                color: theme.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: theme.spacing.xl * 2),
                      // Chart section
                      AnimatedBuilder(
                        animation: _chartAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _chartAnimation.value,
                            child: Container(
                              padding: EdgeInsets.all(
                                theme.spacing.xl * 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: theme.surfacePrimary,
                                borderRadius: BorderRadius.circular(
                                  theme.borderRadius.lg,
                                ),
                                boxShadow: theme.shadows.medium,
                              ),
                              child: Column(
                                children: [
                                  SizedBox(height: theme.spacing.lg),
                                  SizedBox(
                                    height: 200,
                                    child: pieSections.isNotEmpty
                                        ? PieChart(
                                            PieChartData(
                                              sections: pieSections,
                                              centerSpaceRadius: 60,
                                              sectionsSpace: 4,
                                              startDegreeOffset: -90,
                                            ),
                                            swapAnimationDuration:
                                                const Duration(
                                                  milliseconds: 800,
                                                ),
                                            swapAnimationCurve:
                                                Curves.easeInOutCubic,
                                          )
                                        : Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.pie_chart_outline,
                                                  size: 48,
                                                  color: theme.textSecondary,
                                                ),
                                                SizedBox(
                                                  height: theme.spacing.sm,
                                                ),
                                                Text(
                                                  'No personality data available',
                                                  style: theme
                                                      .typography
                                                      .bodyMedium
                                                      .copyWith(
                                                        color:
                                                            theme.textSecondary,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                  SizedBox(height: theme.spacing.xl * 2),
                                  // Legend
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: theme.spacing.md,
                                    runSpacing: theme.spacing.sm,
                                    children: typeLabels.entries.map((entry) {
                                      return Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: theme.spacing.md,
                                          vertical: theme.spacing.sm,
                                        ),
                                        decoration: BoxDecoration(
                                          color: typeColors[entry.key]!
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            theme.borderRadius.sm,
                                          ),
                                          border: Border.all(
                                            color: typeColors[entry.key]!
                                                .withOpacity(0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color: typeColors[entry.key],
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            SizedBox(width: theme.spacing.xs),
                                            Text(
                                              entry.value,
                                              style: theme.typography.bodySmall
                                                  .copyWith(
                                                    color: theme.textPrimary,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  SizedBox(height: theme.spacing.lg),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: theme.spacing.xl * 2),
                      // Results content
                      FadeTransition(
                        opacity: _contentAnimation,
                        child: Column(
                          children: [
                            // Dominant type card
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(theme.spacing.xl),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    typeColors[dominantType]!.withOpacity(0.1),
                                    typeColors[dominantType]!.withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(
                                  theme.borderRadius.lg,
                                ),
                                border: Border.all(
                                  color: typeColors[dominantType]!.withOpacity(
                                    0.3,
                                  ),
                                  width: 2,
                                ),
                                boxShadow: theme.shadows.medium,
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(theme.spacing.md),
                                    decoration: BoxDecoration(
                                      color: typeColors[dominantType],
                                      borderRadius: BorderRadius.circular(
                                        theme.borderRadius.md,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.star_rounded,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                  SizedBox(height: theme.spacing.lg),
                                  Text(
                                    'You are most likely:',
                                    style: theme.typography.bodyLarge.copyWith(
                                      color: theme.textSecondary,
                                    ),
                                  ),
                                  SizedBox(height: theme.spacing.sm),
                                  Text(
                                    typeLabels[dominantType]!,
                                    style: theme.typography.headingLarge
                                        .copyWith(
                                          color: typeColors[dominantType],
                                          fontWeight: FontWeight.w700,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: theme.spacing.lg),
                                  Text(
                                    typeDescriptions[dominantType]!,
                                    style: theme.typography.bodyMedium.copyWith(
                                      color: theme.textPrimary,
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: theme.spacing.lg * 2),
                                  // Communication style surfaced here
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 14,
                                        height: 14,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          color: commColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            commLabel,
                                            style: theme.typography.bodyLarge.copyWith(
                                              color: commColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            commDesc,
                                            style: theme.typography.bodySmall.copyWith(
                                              color: theme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (tip.isNotEmpty) ...[
                                    SizedBox(height: theme.spacing.lg),
                                    Container(
                                      padding: EdgeInsets.all(theme.spacing.md),
                                      decoration: BoxDecoration(
                                        color: commColor.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(
                                          theme.borderRadius.md,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.lightbulb, color: commColor, size: 20),
                                          SizedBox(width: theme.spacing.sm),
                                          Expanded(
                                            child: Text(
                                              tip,
                                              style: theme.typography.bodySmall.copyWith(
                                                color: commColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            SizedBox(height: theme.spacing.xl),

                            // Strengths section
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(theme.spacing.xl),
                              decoration: BoxDecoration(
                                color: theme.surfacePrimary,
                                borderRadius: BorderRadius.circular(
                                  theme.borderRadius.lg,
                                ),
                                boxShadow: theme.shadows.medium,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.emoji_events_rounded,
                                        color: theme.primary,
                                        size: 24,
                                      ),
                                      SizedBox(width: theme.spacing.sm),
                                      Text(
                                        'Your Strengths',
                                        style: theme.typography.headingMedium
                                            .copyWith(color: theme.textPrimary),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: theme.spacing.lg),
                                  ...typeStrengths[dominantType]!.map(
                                    (strength) => Padding(
                                      padding: EdgeInsets.only(
                                        bottom: theme.spacing.sm,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: theme.primary,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          SizedBox(width: theme.spacing.sm),
                                          Expanded(
                                            child: Text(
                                              strength,
                                              style: theme.typography.bodyMedium
                                                  .copyWith(
                                                    color: theme.textPrimary,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: theme.spacing.xl),

                      // Next button
                      PremiumButton(
                        text: 'Continue to Premium',
                        onPressed: () {
                          Navigator.pushNamed(context, '/premium');
                        },
                        fullWidth: true,
                      ),

                      SizedBox(height: theme.spacing.xl),
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
