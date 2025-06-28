import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class PersonalityTestScreenProfessional extends StatefulWidget {
  final List<dynamic> questions;
  final int currentIndex;
  final List<String?> answers;
  final Future<void> Function()? markTestTaken;
  final void Function(List<String> answers)? onComplete;

  const PersonalityTestScreenProfessional({
    super.key,
    required this.questions,
    required this.currentIndex,
    required this.answers,
    this.onComplete,
    this.markTestTaken,
  });

  @override
  State<PersonalityTestScreenProfessional> createState() =>
      _PersonalityTestScreenProfessionalState();
}

class _PersonalityTestScreenProfessionalState
    extends State<PersonalityTestScreenProfessional> {
  String? _selectedAnswer;

  // Color mapping for option types (attachment & communication styles)
  static const Map<String, Color> typeColors = {
    'A': Color(0xFFFF1744), // Anxious - Red
    'B': Color(0xFF4CAF50), // Secure/Assertive - Green
    'C': Color(0xFF2196F3), // Avoidant/Passive - Blue
    'D': Color(0xFFFFD600), // Disorganized/Passive-Aggressive - Yellow
    'assertive': Color(0xFF4CAF50),
    'passive': Color(0xFFFFD600),
    'aggressive': Color(0xFFFF1744),
    'passive-aggressive': Color(0xFF9C27B0),
  };

  @override
  void initState() {
    super.initState();

    if (widget.currentIndex < 0 ||
        widget.currentIndex >= widget.questions.length) {
      print('ERROR: Invalid question index ${widget.currentIndex}');
      return;
    }

    while (widget.answers.length <= widget.currentIndex) {
      widget.answers.add(null);
    }

    _selectedAnswer = widget.answers[widget.currentIndex];
  }

  String getQuestionText(dynamic q) =>
      q is Map ? (q['question'] ?? '') : (q.question ?? '');

  List<dynamic> getOptions(dynamic q) =>
      q is Map ? (q['options'] as List<dynamic>? ?? []) : (q.options ?? []);

  String getOptionType(dynamic opt) =>
      opt is Map ? (opt['type'] ?? '') : (opt.type ?? '');

  String getOptionText(dynamic opt) =>
      opt is Map ? (opt['text'] ?? '') : (opt.text ?? '');

  // Optional: subtitle for communication style questions
  String? getQuestionSubtitle(dynamic q) =>
      q is Map ? (q['subtitle']) : (q.subtitle);

  void _selectAnswer(String type) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedAnswer = type;
      widget.answers[widget.currentIndex] = type;
    });
  }

  Future<void> _goNext() async {
    if (_selectedAnswer == null) {
      _showSelectionRequired();
      return;
    }

    HapticFeedback.mediumImpact();

    if (widget.currentIndex < widget.questions.length - 1) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PersonalityTestScreenProfessional(
              questions: widget.questions,
              currentIndex: widget.currentIndex + 1,
              answers: widget.answers,
              onComplete: widget.onComplete,
              markTestTaken: widget.markTestTaken,
            ),
          ),
        );
      }
    } else {
      _completeTest();
    }
  }

  Future<void> _goPrevious() async {
    if (widget.currentIndex > 0) {
      HapticFeedback.lightImpact();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PersonalityTestScreenProfessional(
              questions: widget.questions,
              currentIndex: widget.currentIndex - 1,
              answers: widget.answers,
              onComplete: widget.onComplete,
              markTestTaken: widget.markTestTaken,
            ),
          ),
        );
      }
    }
  }

  Future<void> _completeTest() async {
    if (widget.markTestTaken != null) {
      await widget.markTestTaken!();
    }

    final nonNullAnswers = widget.answers
        .where((answer) => answer != null)
        .cast<String>()
        .toList();

    if (widget.onComplete != null) {
      try {
        widget.onComplete!(nonNullAnswers);
      } catch (e) {
        print('ERROR in onComplete callback: $e');
      }
    }

    if (mounted) {
      try {
        Navigator.pushReplacementNamed(
          context,
          '/personality_results',
          arguments: nonNullAnswers,
        );
      } catch (e) {
        print('ERROR during navigation: $e');
      }
    }
  }

  void _showSelectionRequired() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20, semanticLabel: 'Warning'),
            const SizedBox(width: 12),
            Text(
              'Please select an answer to continue',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppTheme.spaceMD),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.currentIndex < 0 ||
        widget.currentIndex >= widget.questions.length) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
          child: const Center(
            child: Text(
              'Invalid question index',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
      );
    }

    final q = widget.questions[widget.currentIndex];
    final questionText = getQuestionText(q);
    final options = getOptions(q);
    final progress = (widget.currentIndex + 1) / widget.questions.length;
    final questionSubtitle = getQuestionSubtitle(q);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header with progress
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceLG),
                child: Column(
                  children: [
                    // Progress bar
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusFull,
                        ),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white,
                                Colors.white.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusFull,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppTheme.spaceMD),

                    // Question counter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Question ${widget.currentIndex + 1} of ${widget.questions.length}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${(progress * 100).round()}%',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceLG,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppTheme.spaceLG),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusLG,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6C47FF).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(
                                    AppTheme.spaceSM,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF6C47FF,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusSM,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.psychology_outlined,
                                    color: const Color(0xFF6C47FF),
                                    size: 20,
                                    semanticLabel: 'Personality Assessment',
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spaceMD),
                                Text(
                                  'Personality Assessment',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: const Color(0xFF6C47FF),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.spaceLG),
                            Text(
                              questionText,
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                                shadows: [
                                  Shadow(
                                    color: Colors.white.withOpacity(0.5),
                                    offset: const Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (questionSubtitle != null && questionSubtitle.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child: Text(
                                  questionSubtitle,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.black54,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppTheme.spaceLG),

                      // Options - with color dot for type
                      ...options.asMap().entries.map((entry) {
                        final option = entry.value;
                        final optionType = getOptionType(option);
                        final optionText = getOptionText(option);
                        final isSelected = _selectedAnswer == optionType;
                        final colorDot = typeColors[optionType] ?? Colors.grey;

                        return Container(
                          margin: const EdgeInsets.only(
                            bottom: AppTheme.spaceMD,
                          ),
                          child: GestureDetector(
                            onTap: () => _selectAnswer(optionType),
                            child: Container(
                              padding: const EdgeInsets.all(AppTheme.spaceLG),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusLG,
                                ),
                                border: Border.all(
                                  color: isSelected
                                      ? colorDot
                                      : Colors.white.withOpacity(0.3),
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: colorDot.withOpacity(0.2),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  // Color dot for type
                                  Container(
                                    width: 16,
                                    height: 16,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      color: colorDot,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  // Selection indicator
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? colorDot
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected
                                            ? colorDot
                                            : Colors.white.withOpacity(0.7),
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 16,
                                            semanticLabel: 'Selected',
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: AppTheme.spaceMD),
                                  Expanded(
                                    child: Text(
                                      optionText,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            color: isSelected
                                                ? colorDot
                                                : Colors.white,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            height: 1.3,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: AppTheme.space2XL),
                    ],
                  ),
                ),
              ),

              // Navigation buttons
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceLG),
                child: Row(
                  children: [
                    // Previous button
                    if (widget.currentIndex > 0)
                      Expanded(
                        child: Container(
                          height: 56,
                          margin: const EdgeInsets.only(
                            right: AppTheme.spaceMD,
                          ),
                          child: OutlinedButton.icon(
                            onPressed: _goPrevious,
                            icon: Icon(
                              Icons.arrow_back_ios,
                              color: Colors.white,
                              size: 18,
                              semanticLabel: 'Previous',
                            ),
                            label: Text(
                              'Previous',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.5),
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusLG,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Next button
                    Expanded(
                      flex: widget.currentIndex > 0 ? 1 : 1,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white,
                              Colors.white.withOpacity(0.9),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusLG,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              offset: const Offset(0, 4),
                              blurRadius: 12,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _goNext,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusLG,
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    widget.currentIndex <
                                            widget.questions.length - 1
                                        ? 'Next'
                                        : 'Complete',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.spaceSM),
                                  Icon(
                                    widget.currentIndex <
                                            widget.questions.length - 1
                                        ? Icons.arrow_forward_ios
                                        : Icons.check_circle,
                                    color: theme.colorScheme.primary,
                                    size: 20,
                                    semanticLabel: widget.currentIndex <
                                            widget.questions.length - 1
                                        ? 'Next'
                                        : 'Complete',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
