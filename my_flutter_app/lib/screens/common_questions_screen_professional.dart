import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_button.dart';

class CommonQuestionsScreenProfessional extends StatefulWidget {
  const CommonQuestionsScreenProfessional({super.key});

  @override
  State<CommonQuestionsScreenProfessional> createState() =>
      _CommonQuestionsScreenProfessionalState();
}

class _CommonQuestionsScreenProfessionalState
    extends State<CommonQuestionsScreenProfessional>
    with TickerProviderStateMixin {
  int? openIndex;
  late AnimationController _headerController;
  late Animation<double> _headerAnimation;

  static const faqs = [
    {
      "question": "What is Unsaid?",
      "answer":
          "Unsaid is a relationship communication app that helps you understand your own and your partner's communication styles, attachment patterns, and emotional needs.",
      "icon": Icons.favorite_rounded,
      "category": "About",
    },
    {
      "question": "How does the personality test work?",
      "answer":
          "The test uses research-backed questions to identify both your relationship communication style (passive, assertive, aggressive, or passive-aggressive) and your attachment style (secure, anxious, avoidant, or disorganized). Your answers are private and help personalize your experience in the app.",
      "icon": Icons.psychology_rounded,
      "category": "Personality",
    },
    {
      "question": "Can I retake the personality test?",
      "answer":
          "For accuracy, the test can only be taken once per account. If you believe you made a mistake, please contact support.",
      "icon": Icons.replay_rounded,
      "category": "Personality",
    },
    {
      "question": "How do I invite my partner?",
      "answer":
          "You can generate an invite code from the Partner Profile section and share it with your partner so they can join and connect with you in the app.",
      "icon": Icons.person_add_rounded,
      "category": "Partnership",
    },
    {
      "question": "Is my data private?",
      "answer":
          "Yes. Your responses and results are private and never shared without your permission. Please see our Privacy Policy for more details.",
      "icon": Icons.security_rounded,
      "category": "Privacy",
    },
    {
      "question": "What is the Message Lab?",
      "answer":
          "Message Lab helps you craft messages with the right tone and sensitivity, tailored to both your and your partner's communication and attachment styles.",
      "icon": Icons.science_rounded,
      "category": "Features",
    },
    {
      "question": "How do I change my sensitivity or tone settings?",
      "answer": "You can adjust these settings anytime in the Settings tab.",
      "icon": Icons.tune_rounded,
      "category": "Settings",
    },
    {
      "question": "How do I enable the custom keyboard?",
      "answer":
          "Go to your device's settings, add 'Unsaid' as a keyboard, and enable it. You can turn it on or off in the app's Settings tab.",
      "icon": Icons.keyboard_rounded,
      "category": "Features",
    },
    {
      "question": "What if I need relationship advice?",
      "answer":
          "Unsaid is for informational and personal growth purposes only. For professional advice, please consult a licensed therapist or counselor.",
      "icon": Icons.info_rounded,
      "category": "Support",
    },
    {
      "question": "How do I upgrade to premium?",
      "answer": "Tap the Premium tab to see features and subscription options.",
      "icon": Icons.star_rounded,
      "category": "Premium",
    },
    {
      "question": "What do the color indicators mean?",
      "answer":
          "Green means healthy/assertive communication, yellow means caution/passive, red means high risk/aggressive or passive-aggressive, and gray means neutral or unclear. These are based on your communication and attachment styles.",
      "icon": Icons.circle,
      "category": "Features",
    },
  ];

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );
    _headerController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  Map<String, Color> get categoryColors => {
    'About': AppTheme.of(context).primary,
    'Personality': AppTheme.of(context).secondary,
    'Partnership': AppTheme.of(context).success,
    'Privacy': AppTheme.of(context).info,
    'Features': AppTheme.of(context).warning,
    'Settings': AppTheme.of(context).error,
    'Support': Colors.teal,
    'Premium': Colors.amber,
  };

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

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
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: EdgeInsets.all(theme.spacing.sm),
                        decoration: BoxDecoration(
                          color: theme.surfacePrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            theme.borderRadius.md,
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: theme.textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Common Questions',
                        style: theme.typography.headingLarge.copyWith(
                          color: theme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 44), // Balance the back button
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: theme.spacing.lg),
                  child: Column(
                    children: [
                      // Header card
                      FadeTransition(
                        opacity: _headerAnimation,
                        child: Container(
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
                                  Icons.help_center_rounded,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                              SizedBox(height: theme.spacing.lg),
                              Text(
                                'Frequently Asked Questions',
                                style: theme.typography.headingMedium.copyWith(
                                  color: theme.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: theme.spacing.sm),
                              Text(
                                'Find answers to common questions about Unsaid',
                                style: theme.typography.bodyMedium.copyWith(
                                  color: theme.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: theme.spacing.xl),

                      // FAQ Items
                      ...faqs.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final faq = entry.value;
                        final isOpen = openIndex == idx;
                        final categoryColor =
                            categoryColors[faq["category"]] ?? theme.primary;

                        return Padding(
                          padding: EdgeInsets.only(bottom: theme.spacing.md),
                          child: _buildFAQItem(
                            faq: faq,
                            isOpen: isOpen,
                            categoryColor: categoryColor,
                            theme: theme,
                            onTap: () {
                              setState(() {
                                openIndex = isOpen ? null : idx;
                              });
                            },
                          ),
                        );
                      }),

                      SizedBox(height: theme.spacing.xl),

                      // Contact support card
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(theme.spacing.xl),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.primary.withOpacity(0.1),
                              theme.secondary.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(
                            theme.borderRadius.lg,
                          ),
                          border: Border.all(
                            color: theme.primary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.support_agent_rounded,
                              color: theme.primary,
                              size: 32,
                            ),
                            SizedBox(height: theme.spacing.md),
                            Text(
                              'Still have questions?',
                              style: theme.typography.headingSmall.copyWith(
                                color: theme.textPrimary,
                              ),
                            ),
                            SizedBox(height: theme.spacing.sm),
                            Text(
                              'Contact our support team for personalized assistance',
                              style: theme.typography.bodyMedium.copyWith(
                                color: theme.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: theme.spacing.lg),
                            PremiumButton(
                              text: 'Contact Support',
                              onPressed: () {
                                // Handle contact support
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Support feature coming soon!',
                                    ),
                                    backgroundColor: theme.info,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        theme.borderRadius.md,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              variant: PremiumButtonVariant.outline,
                              icon: Icons.email_rounded,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: theme.spacing.xl),
                    ],
                  ),
                ),
              ),
            ], // End of Column children
          ), // End of Column
        ), // End of SafeArea
      ), // End of Container
    ); // End of build
  }

  Widget _buildFAQItem({
    required Map<String, Object> faq,
    required bool isOpen,
    required Color categoryColor,
    required AppThemeData theme,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      decoration: BoxDecoration(
        color: theme.surfacePrimary,
        borderRadius: BorderRadius.circular(theme.borderRadius.lg),
        boxShadow: isOpen ? theme.shadows.medium : theme.shadows.small,
        border: Border.all(
          color: isOpen ? categoryColor.withOpacity(0.3) : theme.borderColor,
          width: isOpen ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(theme.borderRadius.lg),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(theme.spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(theme.spacing.sm),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          theme.borderRadius.sm,
                        ),
                      ),
                      child: Icon(
                        faq["icon"] as IconData,
                        color: categoryColor,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: theme.spacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: theme.spacing.sm,
                              vertical: theme.spacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: categoryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                theme.borderRadius.xs,
                              ),
                            ),
                            child: Text(
                              faq["category"]! as String,
                              style: theme.typography.labelSmall.copyWith(
                                color: categoryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(height: theme.spacing.xs),
                          Text(
                            faq["question"]! as String,
                            style: theme.typography.bodyLarge.copyWith(
                              color: theme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: isOpen ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: categoryColor,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  child: isOpen
                      ? Column(
                          children: [
                            SizedBox(height: theme.spacing.lg),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(theme.spacing.md),
                              decoration: BoxDecoration(
                                color: theme.backgroundPrimary,
                                borderRadius: BorderRadius.circular(
                                  theme.borderRadius.md,
                                ),
                                border: Border.all(
                                  color: categoryColor.withOpacity(0.1),
                                ),
                              ),
                              child: Text(
                                faq["answer"]! as String,
                                style: theme.typography.bodyMedium.copyWith(
                                  color: theme.textPrimary,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ), // End of AnimatedSize
              ], // End of Column children
            ), // End of Column
          ), // End of Padding
        ), // End of InkWell
      ), // End of Material
    ); // End of AnimatedContainer
  }
}