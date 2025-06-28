import 'package:flutter/material.dart';

class RelationshipQuestionnaireScreenProfessional extends StatefulWidget {
  final String? partnerName;
  final void Function(List<Map<String, String>> answers)? onComplete;

  const RelationshipQuestionnaireScreenProfessional({
    super.key,
    this.partnerName,
    this.onComplete,
  });

  @override
  State<RelationshipQuestionnaireScreenProfessional> createState() =>
      _RelationshipQuestionnaireScreenProfessionalState();
}

class _RelationshipQuestionnaireScreenProfessionalState
    extends State<RelationshipQuestionnaireScreenProfessional>
    with TickerProviderStateMixin {
  final List<String> questions = [
    "I value deep emotional connection over surface-level communication.",
    "I tend to shut down when things get emotionally intense.",
    "I prefer space to process my emotions before talking.",
    "I often take responsibility for maintaining harmony in the relationship.",
    "I want to feel safe expressing my needs without judgment.",
  ];

  final List<String> options = [
    "Strongly Agree",
    "Agree",
    "Neutral",
    "Disagree",
    "Strongly Disagree",
  ];

  int currentQuestionIndex = 0;
  List<Map<String, String>> answers = [];
  bool _buttonLoading = false;
  String? _selectedAnswer;

  late AnimationController _slideController;
  late AnimationController _progressController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _slideController.forward();
    _progressController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void handleAnswer(String selected) async {
    setState(() {
      _buttonLoading = true;
      _selectedAnswer = selected;
    });

    answers.add({
      'question': questions[currentQuestionIndex],
      'response': selected,
    });

    await Future.delayed(const Duration(milliseconds: 800));

    if (currentQuestionIndex + 1 < questions.length) {
      setState(() {
        currentQuestionIndex++;
        _buttonLoading = false;
        _selectedAnswer = null;
      });

      // Animate transition to next question
      _slideController.reset();
      _progressController.reset();
      _slideController.forward();
      _progressController.forward();
    } else {
      // Complete questionnaire
      if (widget.onComplete != null) {
        widget.onComplete!(answers);
      }
      Navigator.of(context).pop(answers);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (currentQuestionIndex + 1) / questions.length;

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
              // Header with progress
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Color(0xFF2D3748),
                              size: 20,
                              semanticLabel: 'Back',
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            widget.partnerName != null
                                ? 'Relationship with ${widget.partnerName}'
                                : 'Relationship Questionnaire',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: const Color(0xFF2D3748),
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 44), // Balance the back button
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Progress bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Question ${currentQuestionIndex + 1} of ${questions.length}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF4A5568),
                              ),
                            ),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF6C47FF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: AnimatedBuilder(
                            animation: _progressAnimation,
                            builder: (context, child) {
                              return FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor:
                                    progress * _progressAnimation.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF6C47FF),
                                        Color(0xFF00D2FF),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Question content
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Question card
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(32),
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
                                ),
                                child: Text(
                                  questions[currentQuestionIndex],
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                        color: const Color(0xFF2D3748),
                                        height: 1.4,
                                        fontWeight: FontWeight.w600,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Answer options
                              ...options
                                  .map(
                                    (option) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 16,
                                      ),
                                      child: _buildAnswerOption(option, theme),
                                    ),
                                  )
                                  ,
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerOption(String option, ThemeData theme) {
    final isSelected = _selectedAnswer == option;
    final isLoading = _buttonLoading && isSelected;

    return GestureDetector(
      onTap: isLoading ? null : () => handleAnswer(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6C47FF).withOpacity(0.1)
              : Colors.white,
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6C47FF)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6C47FF).withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isSelected
                      ? const Color(0xFF6C47FF)
                      : const Color(0xFF2D3748),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C47FF)),
                  semanticsLabel: 'Loading',
                ),
              )
            else if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF6C47FF),
                size: 24,
                semanticLabel: 'Selected',
              ),
          ],
        ),
      ),
    );
  }
}
