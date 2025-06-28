import 'package:flutter/material.dart';

class RelationshipProfileScreenProfessional extends StatefulWidget {
  const RelationshipProfileScreenProfessional({super.key});

  @override
  State<RelationshipProfileScreenProfessional> createState() =>
      _RelationshipProfileScreenProfessionalState();
}

class _RelationshipProfileScreenProfessionalState
    extends State<RelationshipProfileScreenProfessional>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _cardController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _cardAnimation;

  bool showTriggers = false;

  final String yourType = 'Anxious';
  final String partnerType = 'Avoidant';
  final String yourComm = 'Assertive'; // NEW: Communication style
  final String partnerComm = 'Passive'; // NEW: Communication style
  final String compatibility = 'Challenging but transformative';
  final String insight = '''This dynamic can create push-pull patterns.
The anxious partner seeks closeness while the avoidant withdraws under pressure.
With emotional awareness and gentle boundaries, trust can grow.''';

  final List<String> triggers = [
    'Feeling ignored or left on read',
    'Sudden distance or silence',
    'Fear of abandonment',
    'Mixed signals',
  ];

  final List<Map<String, String>> heatmap = [
    {'area': 'Emotional Intimacy', 'level': 'Strained'},
    {'area': 'Independence', 'level': 'Strong'},
    {'area': 'Trust-Building', 'level': 'Needs work'},
    {'area': 'Verbal Affection', 'level': 'Compatible'},
  ];

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'anxious':
        return Colors.red;
      case 'avoidant':
        return Colors.blue;
      case 'secure':
        return Colors.green;
      case 'disorganized':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getCommColor(String comm) {
    switch (comm.toLowerCase()) {
      case 'assertive':
        return Colors.green;
      case 'passive':
        return Colors.yellow[700]!;
      case 'aggressive':
        return Colors.red;
      case 'passive-aggressive':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _cardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.elasticOut),
    );

    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _fadeController.forward();
    _slideController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _cardController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'strong':
      case 'compatible':
        return Colors.green;
      case 'strained':
      case 'needs work':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildCommChip(String comm) {
    final color = _getCommColor(comm);
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble, color: color, size: 14, semanticLabel: 'Communication Style'),
          const SizedBox(width: 4),
          Text(
            comm,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.secondary.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          color: theme.colorScheme.primary,
                          size: 20,
                          semanticLabel: 'Back',
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Relationship Profile',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 44), // Balance the back button
                  ],
                ),
              ),

              // Content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Logo with glow effect
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.3,
                                  ),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/logo_icon.png',
                              width: 80,
                              height: 80,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Profile Cards
                          ScaleTransition(
                            scale: _cardAnimation,
                            child: Column(
                              children: [
                                _buildProfileCard(
                                  context,
                                  'Your Type',
                                  yourType,
                                  Icons.person_outline,
                                  _getTypeColor(yourType),
                                  comm: yourComm,
                                ),
                                const SizedBox(height: 16),
                                _buildProfileCard(
                                  context,
                                  'Partner\'s Type',
                                  partnerType,
                                  Icons.favorite_outline,
                                  _getTypeColor(partnerType),
                                  comm: partnerComm,
                                ),
                                const SizedBox(height: 16),
                                _buildProfileCard(
                                  context,
                                  'Compatibility',
                                  compatibility,
                                  Icons.sync_alt,
                                  Colors.orange,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Insight Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.lightbulb_outline,
                                      color: theme.colorScheme.primary,
                                      size: 24,
                                      semanticLabel: 'Insight',
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Insight & Tips',
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  insight,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    height: 1.6,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Compatibility Heatmap
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.analytics_outlined,
                                      color: theme.colorScheme.primary,
                                      size: 24,
                                      semanticLabel: 'Compatibility Areas',
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Compatibility Areas',
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ...heatmap.map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item['area']!,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getLevelColor(
                                              item['level']!,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: _getLevelColor(
                                                item['level']!,
                                              ).withOpacity(0.3),
                                            ),
                                          ),
                                          child: Text(
                                            item['level']!,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: _getLevelColor(
                                                    item['level']!,
                                                  ),
                                                  fontWeight: FontWeight.w600,
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

                          const SizedBox(height: 24),

                          // Triggers Section
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      showTriggers = !showTriggers;
                                    });
                                  },
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber_outlined,
                                        color: Colors.orange,
                                        size: 24,
                                        semanticLabel: 'Common Triggers',
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Common Triggers',
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ),
                                      Icon(
                                        showTriggers
                                            ? Icons.expand_less
                                            : Icons.expand_more,
                                        color: theme.colorScheme.primary,
                                        semanticLabel: showTriggers
                                            ? 'Collapse'
                                            : 'Expand',
                                      ),
                                    ],
                                  ),
                                ),
                                AnimatedCrossFade(
                                  firstChild: const SizedBox.shrink(),
                                  secondChild: Column(
                                    children: [
                                      const SizedBox(height: 16),
                                      ...triggers.map(
                                        (trigger) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.circle,
                                                size: 6,
                                                color: Colors.orange,
                                                semanticLabel: 'Trigger',
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  trigger,
                                                  style: theme
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        color: theme
                                                            .colorScheme
                                                            .onSurface
                                                            .withOpacity(0.8),
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  crossFadeState: showTriggers
                                      ? CrossFadeState.showSecond
                                      : CrossFadeState.showFirst,
                                  duration: const Duration(milliseconds: 300),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
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

  Widget _buildProfileCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color, {
    String? comm,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24, semanticLabel: label),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Color dot for type
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      value,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    if (comm != null) _buildCommChip(comm),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
