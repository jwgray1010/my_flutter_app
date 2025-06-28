import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/advanced_components.dart';
import 'relationship_couple_goals.dart';

class RelationshipInsightsDashboard extends StatefulWidget {
  const RelationshipInsightsDashboard({super.key});

  @override
  State<RelationshipInsightsDashboard> createState() =>
      _RelationshipInsightsDashboardState();
}

class _RelationshipInsightsDashboardState
    extends State<RelationshipInsightsDashboard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Mock data - in real app this would come from analytics
  final Map<String, dynamic> _insights = {
    'compatibility_score': 0.87,
    'communication_trend': 'improving',
    'weekly_messages': 127,
    'positive_sentiment': 0.84,
    'growth_areas': [
      'Active listening',
      'Expressing needs clearly',
      'Managing stress together',
    ],
    'strengths': ['Emotional support', 'Shared humor', 'Conflict resolution'],
    'weekly_analysis': [
      {'day': 'Mon', 'score': 0.82},
      {'day': 'Tue', 'score': 0.85},
      {'day': 'Wed', 'score': 0.79},
      {'day': 'Thu', 'score': 0.91},
      {'day': 'Fri', 'score': 0.88},
      {'day': 'Sat', 'score': 0.94},
      {'day': 'Sun', 'score': 0.87},
    ],
    // New: Communication/attachment styles (mocked)
    'your_style': 'Secure',
    'partner_style': 'Anxious',
    'your_comm': 'Assertive',
    'partner_comm': 'Passive',
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'improving':
        return Colors.green;
      case 'steady':
        return Colors.orange;
      case 'declining':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom Polished Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  top: 48,
                  left: 0,
                  right: 0,
                  bottom: 24,
                ),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Centered logo and title
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/logo_icon.png',
                          height: 48,
                          width: 48,
                          fit: BoxFit.contain,
                          semanticLabel: 'Unsaid Logo',
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Relationship Insights',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    // Settings icon (top right)
                    Positioned(
                      right: 24,
                      top: 8,
                      child: IconButton(
                        icon: Icon(
                          Icons.settings,
                          color: Colors.white,
                          size: 28,
                        ),
                        tooltip: 'Settings',
                        onPressed: () {
                          Navigator.pushNamed(context, '/settings');
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppTheme.spaceLG),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Communication/Attachment Styles Chip
                    Row(
                      children: [
                        _buildStyleChip(
                          theme,
                          'You',
                          _insights['your_style'],
                          _insights['your_comm'],
                          Colors.green,
                        ),
                        const SizedBox(width: AppTheme.spaceMD),
                        _buildStyleChip(
                          theme,
                          'Partner',
                          _insights['partner_style'],
                          _insights['partner_comm'],
                          Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceLG),

                    // Compatibility Score Card
                    _buildCompatibilityCard(theme),
                    const SizedBox(height: AppTheme.spaceLG),

                    // Weekly Trend Chart
                    _buildWeeklyTrendCard(theme),
                    const SizedBox(height: AppTheme.spaceLG),

                    // Communication Stats
                    _buildCommunicationStats(theme),
                    const SizedBox(height: AppTheme.spaceLG),

                    // Growth Areas & Strengths
                    Row(
                      children: [
                        Expanded(child: _buildGrowthAreas(theme)),
                        const SizedBox(width: AppTheme.spaceMD),
                        Expanded(child: _buildStrengths(theme)),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceLG),

                    // AI Recommendations
                    _buildAIRecommendations(theme),
                    const SizedBox(height: AppTheme.spaceLG),

                    // Couple Goals Tab - New Section
                    RelationshipCoupleGoals(
                      yourAttachment: _insights['your_style'],
                      partnerAttachment: _insights['partner_style'],
                      yourComm: _insights['your_comm'],
                      partnerComm: _insights['partner_comm'],
                      context:
                          "marriage", // or "separation", "co-parenting" based on user data
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

  Widget _buildStyleChip(
    ThemeData theme,
    String label,
    String? attachment,
    String? comm,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMD,
        vertical: AppTheme.spaceXS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person, color: color, size: 16, semanticLabel: label),
          const SizedBox(width: 4),
          Text(
            '$label:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            attachment ?? '',
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (comm != null) ...[
            const SizedBox(width: 4),
            Text(
              '($comm)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompatibilityCard(ThemeData theme) {
    final score = _insights['compatibility_score'] as double;

    return PremiumCard(
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.favorite,
                color: theme.colorScheme.primary,
                semanticLabel: 'Compatibility',
              ),
              const SizedBox(width: AppTheme.spaceXS),
              Text(
                'Compatibility Score',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLG),

          // Circular Progress Indicator
          SizedBox(
            height: 120,
            width: 120,
            child: Stack(
              children: [
                Center(
                  child: SizedBox(
                    height: 120,
                    width: 120,
                    child: CircularProgressIndicator(
                      value: score,
                      strokeWidth: 8,
                      backgroundColor: theme.colorScheme.surface,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getScoreColor(score),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${(score * 100).round()}%',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getScoreColor(score),
                        ),
                      ),
                      Text(
                        _getScoreLabel(score),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spaceLG),

          Text(
            'Your relationship shows strong compatibility with room for growth in emotional awareness.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTrendCard(ThemeData theme) {
    final trend = _insights['communication_trend'] as String;
    final trendColor = _getTrendColor(trend);

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: trendColor,
                semanticLabel: 'Trend',
              ),
              const SizedBox(width: AppTheme.spaceXS),
              Text(
                'Weekly Communication Trend',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              // Color dot for trend
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: trendColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                trend[0].toUpperCase() + trend.substring(1),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: trendColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLG),

          // Simple bar chart
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: (_insights['weekly_analysis'] as List).map<Widget>((
                data,
              ) {
                final score = data['score'] as double;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 30,
                      height: score * 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [trendColor, trendColor.withOpacity(0.6)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceXS),
                    Text(data['day'], style: theme.textTheme.bodySmall),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunicationStats(ThemeData theme) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Week\'s Activity',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spaceLG),

          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  theme,
                  Icons.message,
                  '${_insights['weekly_messages']}',
                  'Messages',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  theme,
                  Icons.sentiment_satisfied,
                  '${(_insights['positive_sentiment'] * 100).round()}%',
                  'Positive',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  theme,
                  Icons.psychology,
                  'Growing',
                  'Connection',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spaceMD),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 24,
            semanticLabel: label,
          ),
        ),
        const SizedBox(height: AppTheme.spaceXS),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildGrowthAreas(ThemeData theme) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: Colors.orange,
                semanticLabel: 'Growth Areas',
              ),
              const SizedBox(width: AppTheme.spaceXS),
              Text(
                'Growth Areas',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMD),

          ...(_insights['growth_areas'] as List<String>).map(
            (area) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spaceXS),
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 6,
                    color: Colors.orange,
                    semanticLabel: 'Growth',
                  ),
                  const SizedBox(width: AppTheme.spaceXS),
                  Expanded(child: Text(area, style: theme.textTheme.bodySmall)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengths(ThemeData theme) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: Colors.green, semanticLabel: 'Strengths'),
              const SizedBox(width: AppTheme.spaceXS),
              Text(
                'Strengths',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMD),

          ...(_insights['strengths'] as List<String>).map(
            (strength) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spaceXS),
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 6,
                    color: Colors.green,
                    semanticLabel: 'Strength',
                  ),
                  const SizedBox(width: AppTheme.spaceXS),
                  Expanded(
                    child: Text(strength, style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIRecommendations(ThemeData theme) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: theme.colorScheme.primary,
                semanticLabel: 'AI Recommendations',
              ),
              const SizedBox(width: AppTheme.spaceXS),
              Text(
                'AI Recommendations',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMD),

          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMD),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 Today\'s Insight',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXS),
                Text(
                  'Your partner responds most positively to messages that acknowledge their feelings first. Try starting with "I understand..." or "I can see that..."',
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }

  String _getScoreLabel(double score) {
    if (score >= 0.8) return 'Excellent';
    if (score >= 0.6) return 'Good';
    return 'Needs Work';
  }
}
