import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';

class PremiumScreenProfessional extends StatefulWidget {
  final VoidCallback? onContinue;

  const PremiumScreenProfessional({super.key, this.onContinue});

  @override
  State<PremiumScreenProfessional> createState() =>
      _PremiumScreenProfessionalState();
}

class _PremiumScreenProfessionalState extends State<PremiumScreenProfessional>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _sparkleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _sparkleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _sparkleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.bounceOut),
    );

    _sparkleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 200), () {
      _scaleController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _fadeController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  void _handleSubscribe() {
    HapticFeedback.mediumImpact();
    if (widget.onContinue != null) {
      widget.onContinue!();
    } else {
      Navigator.pushReplacementNamed(context, '/tone_tutorial');
    }
  }

  void _handleMaybeLater() {
    HapticFeedback.lightImpact();
    Navigator.pushReplacementNamed(context, '/tone_tutorial');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF6C47FF),
                  const Color(0xFF9C88FF),
                  const Color(0xFFB39DDB),
                ],
              ),
            ),
            child: SafeArea(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _fadeController,
                  _slideController,
                  _scaleController,
                  _sparkleController,
                ]),
                builder: (context, child) {
                  return CustomScrollView(
                    slivers: [
                      // Header with animated logo
                      SliverToBoxAdapter(
                        child: Container(
                          padding: EdgeInsets.all(AppTheme.spacing.xl),
                          child: Column(
                            children: [
                              // Premium badge with sparkle effect
                              Stack(
                                children: [
                                  ScaleTransition(
                                    scale: _scaleAnimation,
                                    child: Container(
                                      padding: EdgeInsets.all(AppTheme.spacing.lg),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.white.withOpacity(0.3),
                                            blurRadius: 20,
                                            spreadRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: Image.asset(
                                        'assets/logo_icon.png',
                                        width: 100,
                                        height: 100,
                                        semanticLabel: 'Unsaid Premium logo',
                                      ),
                                    ),
                                  ),
                                  // Sparkle effects
                                  ...List.generate(6, (index) {
                                    final angle = (index * 60.0) * (3.14159 / 180);
                                    final radius = 80.0;
                                    return Positioned(
                                      left:
                                          75 +
                                          radius *
                                              math.cos(
                                                angle +
                                                    _sparkleAnimation.value *
                                                        2 *
                                                        3.14159,
                                              ),
                                      top:
                                          75 +
                                          radius *
                                              math.sin(
                                                angle +
                                                    _sparkleAnimation.value *
                                                        2 *
                                                        3.14159,
                                              ),
                                      child: FadeTransition(
                                        opacity: _sparkleAnimation,
                                        child: Icon(
                                          Icons.star,
                                          color: Colors.white.withOpacity(0.7),
                                          size: 12,
                                          semanticLabel: 'Sparkle',
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),

                              SizedBox(height: AppTheme.spacing.lg),

                              // Premium title
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: Text(
                                  'Unsaid Premium',
                                  style: theme.textTheme.displayMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        offset: const Offset(0, 2),
                                        blurRadius: 4,
                                        color: Colors.black.withOpacity(0.3),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                              SizedBox(height: AppTheme.spacing.sm),

                              // Subtitle
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: Text(
                                  'Unlock the full power of relationship insights',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(height: AppTheme.spacing.xs),
                              // Research-backed badge
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: Container(
                                  margin: EdgeInsets.only(top: AppTheme.spacing.sm),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacing.md,
                                    vertical: AppTheme.spacing.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified, color: Colors.white, size: 18, semanticLabel: 'Research-backed'),
                                      SizedBox(width: 6),
                                      Text(
                                        'Research-backed insights',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Features list
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing.lg,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            SlideTransition(
                              position: _slideAnimation,
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: Container(
                                  padding: EdgeInsets.all(AppTheme.spacing.lg),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF6C47FF),
                                        Color(0xFF4A2FE7),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusLG,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 20,
                                        offset: Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Premium Features',
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      SizedBox(height: AppTheme.spacing.lg),
                                      ..._buildFeaturesList(),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: AppTheme.spacing.xl),

                            // Pricing section
                            SlideTransition(
                              position: _slideAnimation,
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: _buildPricingSection(),
                              ),
                            ),

                            SizedBox(height: AppTheme.spacing.xl),

                            // Action buttons
                            SlideTransition(
                              position: _slideAnimation,
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: Column(
                                  children: [
                                    // Subscribe button
                                    GradientButton(
                                      onPressed: _handleSubscribe,
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white,
                                          Colors.white.withOpacity(0.95),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radius.lg,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: AppTheme.spacing.xl,
                                        vertical: AppTheme.spacing.md,
                                      ),
                                      elevation: 12,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.rocket_launch,
                                            color: theme.colorScheme.primary,
                                            size: 24,
                                            semanticLabel: 'Start Free Trial',
                                          ),
                                          SizedBox(width: AppTheme.spacing.sm),
                                          Text(
                                            'Start Free Trial',
                                            style: theme.textTheme.titleLarge
                                                ?.copyWith(
                                                  color: theme.colorScheme.primary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    SizedBox(height: AppTheme.spacing.md),

                                    // Maybe later button
                                    TextButton(
                                      onPressed: _handleMaybeLater,
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: AppTheme.spacing.lg,
                                          vertical: AppTheme.spacing.sm,
                                        ),
                                      ),
                                      child: Text(
                                        'Maybe later',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              color: Colors.white.withOpacity(0.8),
                                              decoration: TextDecoration.underline,
                                              decorationColor: Colors.white
                                                  .withOpacity(0.8),
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: AppTheme.spacing.lg),
                          ]),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          // Home button overlay (always on top)
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 8),
                child: IconButton(
                  icon: Icon(Icons.home, color: Colors.white, size: 28),
                  tooltip: 'Home',
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/home', (route) => false);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFeaturesList() {
    final features = [
      {
        'icon': Icons.psychology_outlined,
        'title': 'Advanced Compatibility Insights',
        'description':
            'Deep AI analysis of relationship patterns and communication styles',
        'semantic': 'Advanced Compatibility Insights',
      },
      {
        'icon': Icons.science_outlined,
        'title': 'Message Lab Practice Mode',
        'description':
            'Practice difficult conversations in a safe, AI-powered environment',
        'semantic': 'Message Lab Practice Mode',
      },
      {
        'icon': Icons.trending_up_outlined,
        'title': 'Relationship Health Tracking',
        'description':
            'Monitor and improve your connection over time with detailed metrics',
        'semantic': 'Relationship Health Tracking',
      },
      {
        'icon': Icons.lightbulb_outline,
        'title': 'Personalized Recommendations',
        'description':
            'Custom suggestions based on your unique communication patterns',
        'semantic': 'Personalized Recommendations',
      },
      {
        'icon': Icons.shield_outlined,
        'title': 'Priority Support',
        'description':
            'Get help when you need it most with premium customer support',
        'semantic': 'Priority Support',
      },
      {
        'icon': Icons.favorite,
        'title': 'Attachment & Communication Style Analysis',
        'description':
            'Personalized insights based on your attachment and communication styles',
        'semantic': 'Attachment & Communication Style Analysis',
      },
    ];

    return features.asMap().entries.map<Widget>((entry) {
      final index = entry.key;
      final feature = entry.value;
      return TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 600 + (index * 100)),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, (1 - value) * 20),
            child: Opacity(
              opacity: value,
              child: Container(
                margin: EdgeInsets.only(bottom: AppTheme.spacing.md),
                padding: EdgeInsets.all(AppTheme.spacing.md),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radius.md),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(AppTheme.spacing.sm),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppTheme.radius.sm),
                      ),
                      child: Icon(
                        feature['icon'] as IconData,
                        color: Colors.white,
                        size: 24,
                        semanticLabel: feature['semantic'] as String,
                      ),
                    ),
                    SizedBox(width: AppTheme.spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            feature['title'] as String,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: AppTheme.spacing.xs),
                          Text(
                            feature['description'] as String,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.8),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.check_circle, color: Colors.white, size: 20, semanticLabel: 'Included'),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  Widget _buildPricingSection() {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C47FF), Color(0xFF4A2FE7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Flexible Pricing',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppTheme.spacing.lg),

          // Free trial highlight
          Container(
            padding: EdgeInsets.all(AppTheme.spacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppTheme.radius.lg),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, color: Colors.white, size: 24, semanticLabel: 'Free Trial'),
                    SizedBox(width: AppTheme.spacing.sm),
                    Text(
                      '7-Day Free Trial',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppTheme.spacing.sm),
                Text(
                  'Then \$9.99/month',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                SizedBox(height: AppTheme.spacing.xs),
                Text(
                  'Cancel anytime',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
