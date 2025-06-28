import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../widgets/advanced_components.dart';

class InsightsDashboardEnhanced extends StatefulWidget {
  const InsightsDashboardEnhanced({super.key});

  @override
  State<InsightsDashboardEnhanced> createState() =>
      _InsightsDashboardEnhancedState();
}

class _InsightsDashboardEnhancedState extends State<InsightsDashboardEnhanced>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _selectedMoodToday = '';
  String _selectedTimeframe = 'Week';
  bool _showAdvancedMetrics = false;

  // Example: Replace with actual user style if available
  final String userStyle = 'Secure + Assertive';

  // Enhanced data structures for advanced insights
  final Map<String, Map<String, int>> _timeframedToneData = {
    'Week': {
      'Mon': 85,
      'Tue': 72,
      'Wed': 90,
      'Thu': 68,
      'Fri': 88,
      'Sat': 92,
      'Sun': 85,
    },
    'Month': {'Week 1': 82, 'Week 2': 78, 'Week 3': 85, 'Week 4': 90},
    'Year': {
      'Jan': 75,
      'Feb': 78,
      'Mar': 82,
      'Apr': 85,
      'May': 88,
      'Jun': 92,
      'Jul': 85,
      'Aug': 80,
      'Sep': 87,
      'Oct': 89,
      'Nov': 91,
      'Dec': 88,
    },
  };

  final List<Map<String, dynamic>> _communicationBreakdown = [
    {
      'category': 'Positive',
      'percentage': 68,
      'color': Colors.green,
      'count': 34,
    },
    {
      'category': 'Neutral',
      'percentage': 22,
      'color': Colors.blue,
      'count': 11,
    },
    {
      'category': 'Challenging',
      'percentage': 10,
      'color': Colors.orange,
      'count': 5,
    },
  ];

  final List<Map<String, dynamic>> _detailedMetrics = [
    {
      'category': 'Response Time',
      'current': '2.3 hrs',
      'previous': '3.1 hrs',
      'improvement': true,
      'percentage': 26,
      'icon': Icons.schedule,
      'color': Colors.blue,
    },
    {
      'category': 'Message Length',
      'current': '47 words',
      'previous': '42 words',
      'improvement': true,
      'percentage': 12,
      'icon': Icons.text_fields,
      'color': Colors.green,
    },
    {
      'category': 'Tone Consistency',
      'current': '87%',
      'previous': '81%',
      'improvement': true,
      'percentage': 7,
      'icon': Icons.balance,
      'color': Colors.purple,
    },
    {
      'category': 'Conflict Incidents',
      'current': '2',
      'previous': '5',
      'improvement': true,
      'percentage': 60,
      'icon': Icons.warning_outlined,
      'color': Colors.orange,
    },
  ];

  final List<Map<String, dynamic>> _weeklyGoals = [
    {
      'title': 'Send 10 positive messages',
      'progress': 70,
      'current': 7,
      'target': 10,
      'completed': false,
      'description': 'Spread positivity in your conversations',
      'icon': Icons.favorite,
      'color': Colors.pink,
    },
    {
      'title': 'Maintain calm tone',
      'progress': 85,
      'current': 85,
      'target': 100,
      'completed': false,
      'description': 'Keep a peaceful communication style',
      'icon': Icons.self_improvement,
      'color': Colors.blue,
    },
    {
      'title': 'Quick responses (<2hrs)',
      'progress': 60,
      'current': 12,
      'target': 20,
      'completed': false,
      'description': 'Respond promptly to messages',
      'icon': Icons.speed,
      'color': Colors.orange,
    },
    {
      'title': 'Daily check-in',
      'progress': 100,
      'current': 7,
      'target': 7,
      'completed': true,
      'description': 'Complete daily mood tracking',
      'icon': Icons.check_circle,
      'color': Colors.green,
    },
    {
      'title': 'Conflict resolution',
      'progress': 50,
      'current': 1,
      'target': 2,
      'completed': false,
      'description': 'Practice healthy conflict resolution',
      'icon': Icons.handshake,
      'color': Colors.purple,
    },
    {
      'title': 'Empathy practice',
      'progress': 90,
      'current': 9,
      'target': 10,
      'completed': false,
      'description': 'Show understanding in conversations',
      'icon': Icons.psychology,
      'color': Colors.teal,
    },
  ];

  final List<String> _moodOptions = [
    '😊 Happy',
    '😔 Sad',
    '😠 Angry',
    '😰 Anxious',
    '😌 Calm',
    '🤔 Thoughtful',
    '😴 Tired',
    '🤗 Loved',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
    );
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.elasticOut,
          ),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Enhanced Header with gradient matching relationship partner card
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF7B61FF),
                    Color(0xFF9C27B0),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spaceLG),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.insights, color: Colors.white, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Insights Dashboard',
                                style: theme.textTheme.headlineLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spaceXS),
                        Text(
                          'Track your co-parenting communication growth',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTheme.spaceMD),
                        // User style surfaced in header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_user, color: Colors.green, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Style: $userStyle',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spaceMD),
                        // Enhanced Quick Stats Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickStat(
                                'Messages',
                                '47',
                                Icons.message,
                              ),
                            ),
                            Expanded(
                              child: _buildQuickStat(
                                'Score',
                                '87%',
                                Icons.trending_up,
                              ),
                            ),
                            Expanded(
                              child: _buildQuickStat(
                                'Streak',
                                '15d',
                                Icons.local_fire_department,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Enhanced Tab bar
            Container(
              color: theme.colorScheme.surface,
              child: TabBar(
                controller: _tabController,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(
                  0.6,
                ),
                indicatorColor: theme.colorScheme.primary,
                indicatorWeight: 3.0,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Analytics'),
                  Tab(text: 'Mood'),
                  Tab(text: 'Goals'),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(theme),
                  _buildAnalyticsTab(theme),
                  _buildMoodTrackerTab(theme),
                  _buildGoalsTab(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method to send partner link
  void _sendPartnerLink() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Partner link sent!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Quick stat widget for header
  Widget _buildQuickStat(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // Overview tab with dashboard summary
  Widget _buildOverviewTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Overview',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spaceLG),

            // Today's Quick Actions
            PremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMD),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          theme,
                          'Send Message',
                          Icons.message,
                          Colors.blue,
                          () {
                            // Navigate to message screen
                          },
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceMD),
                      Expanded(
                        child: _buildActionButton(
                          theme,
                          'Log Mood',
                          Icons.mood,
                          Colors.green,
                          () {
                            _tabController.animateTo(2);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spaceLG),

            // Recent Activity Summary
            PremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Activity',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMD),
                  _buildActivityItem(
                    theme,
                    'Message analyzed',
                    '2 hours ago',
                    Icons.analytics,
                    Colors.purple,
                  ),
                  _buildActivityItem(
                    theme,
                    'Mood logged: Happy',
                    '1 day ago',
                    Icons.mood,
                    Colors.green,
                  ),
                  _buildActivityItem(
                    theme,
                    'Weekly goal achieved',
                    '2 days ago',
                    Icons.emoji_events,
                    Colors.orange,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spaceLG),

            // Weekly Summary
            PremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This Week\'s Summary',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMD),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          theme,
                          'Messages',
                          '12',
                          '+3 from last week',
                          Icons.message,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceMD),
                      Expanded(
                        child: _buildSummaryCard(
                          theme,
                          'Avg Score',
                          '87%',
                          '+5% improvement',
                          Icons.trending_up,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab(ThemeData theme) {
    final currentData = _timeframedToneData[_selectedTimeframe]!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeframe selector
            Row(
              children: [
                Text(
                  'Communication Analytics',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedTimeframe,
                      items: _timeframedToneData.keys.map((String timeframe) {
                        return DropdownMenuItem<String>(
                          value: timeframe,
                          child: Text(
                            timeframe,
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedTimeframe = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceLG),

            // Enhanced Tone Chart
            PremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tone Trends - $_selectedTimeframe',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceLG),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final days = currentData.keys.toList();
                                if (value.toInt() < days.length) {
                                  return Text(
                                    days[value.toInt()],
                                    style: theme.textTheme.bodySmall,
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: currentData.entries
                                .map(
                                  (e) => FlSpot(
                                    currentData.keys
                                        .toList()
                                        .indexOf(e.key)
                                        .toDouble(),
                                    e.value.toDouble(),
                                  ),
                                )
                                .toList(),
                            isCurved: true,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  theme.colorScheme.primary.withOpacity(0.3),
                                  theme.colorScheme.primary.withOpacity(0.0),
                                ],
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

            const SizedBox(height: AppTheme.spaceLG),

            // Communication Breakdown Pie Chart + Legend
            PremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Message Sentiment Distribution',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceLG),
                  SizedBox(
                    height: 200,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: PieChart(
                            PieChartData(
                              sections: _communicationBreakdown.map((data) {
                                return PieChartSectionData(
                                  value: data['percentage'].toDouble(),
                                  title: '${data['percentage']}%',
                                  color: data['color'],
                                  radius: 60,
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _communicationBreakdown.map((data) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: data['color'],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${data['category']} (${data['count']})',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Color legend for research-backed mapping
                  Row(
                    children: [
                      _buildLegendDot(Colors.green, 'Positive/Assertive'),
                      _buildLegendDot(Colors.blue, 'Neutral/Passive'),
                      _buildLegendDot(Colors.orange, 'Challenging/Aggressive'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spaceLG),

            // Personalized tip based on user style
            PremiumCard(
              child: Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.amber, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tip: As an assertive communicator, keep using clear “I” statements!',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spaceLG),

            // Detailed Metrics
            PremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Detailed Metrics',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showAdvancedMetrics = !_showAdvancedMetrics;
                          });
                        },
                        child: Row(
                          children: [
                            Text(
                              _showAdvancedMetrics ? 'Hide' : 'Show All',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            Icon(
                              _showAdvancedMetrics
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: theme.colorScheme.primary,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceLG),
                  ..._detailedMetrics
                      .take(_showAdvancedMetrics ? _detailedMetrics.length : 2)
                      .map(
                        (metric) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppTheme.spaceMD,
                          ),
                          child: _buildDetailedMetricCard(theme, metric),
                        ),
                      ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spaceLG),

            // Stats cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    theme,
                    'Avg. Score',
                    '82%',
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMD),
                Expanded(
                  child: _buildStatCard(
                    theme,
                    'Messages',
                    '47',
                    Icons.message,
                    Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spaceMD),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    theme,
                    'Conflicts',
                    '2',
                    Icons.warning_outlined,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMD),
                Expanded(
                  child: _buildStatCard(
                    theme,
                    'Streak Days',
                    '15',
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildMoodTrackerTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Today's mood check-in
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How are you feeling today?',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceLG),
                Wrap(
                  spacing: AppTheme.spaceMD,
                  runSpacing: AppTheme.spaceMD,
                  children: _moodOptions.map((mood) {
                    final isSelected = _selectedMoodToday == mood;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedMoodToday = mood),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spaceMD,
                          vertical: AppTheme.spaceXS,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? theme.colorScheme.primary : null,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusLG,
                          ),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : theme.colorScheme.outline,
                          ),
                        ),
                        child: Text(
                          mood,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isSelected
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                if (_selectedMoodToday.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spaceLG),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spaceMD),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(
                        0.3,
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mood logged: $_selectedMoodToday',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceXS),
                        Text(
                          'Great! We\'ll use this to provide better communication insights.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spaceXL),

          // Mood patterns
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mood Patterns This Week',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceLG),
                SizedBox(
                  height: 150,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 10,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                              return Text(
                                days[value.toInt()],
                                style: theme.textTheme.bodySmall,
                              );
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: [0, 1, 2, 3, 4, 5, 6]
                          .map(
                            (x) => BarChartGroupData(
                              x: x,
                              barRods: [
                                BarChartRodData(
                                  toY: [7, 8, 6, 9, 7, 8, 8][x].toDouble(),
                                  color: theme.colorScheme.primary,
                                  width: 16,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekly Goals Overview
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'This Week\'s Goals',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceMD,
                        vertical: AppTheme.spaceXS,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      ),
                      child: Text(
                        '4/6 Complete',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceLG),

                // Progress indicator
                LinearProgressIndicator(
                  value: 4 / 6,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMD),

                Text(
                  '67% Complete - You\'re doing great!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spaceLG),

          // Individual Goals
          ...List.generate(_weeklyGoals.length, (index) {
            final goal = _weeklyGoals[index];
            return Container(
              margin: const EdgeInsets.only(bottom: AppTheme.spaceMD),
              padding: const EdgeInsets.all(AppTheme.spaceMD),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: goal['completed']
                              ? Colors.green
                              : theme.colorScheme.outline.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: goal['completed']
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              )
                            : null,
                      ),
                      const SizedBox(width: AppTheme.spaceMD),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal['title'],
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                decoration: goal['completed']
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: goal['completed']
                                    ? theme.colorScheme.onSurface.withOpacity(
                                        0.6,
                                      )
                                    : null,
                              ),
                            ),
                            if (goal['description'] != null) ...[
                              const SizedBox(height: AppTheme.spaceXS),
                              Text(
                                goal['description'],
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (!goal['completed'])
                        IconButton(
                          onPressed: () {
                            setState(() {
                              goal['completed'] = true;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Goal "${goal['title']}" completed! 🎉',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.check_circle_outline,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                    ],
                  ),

                  // Progress bar for goals with progress
                  if (goal['progress'] != null) ...[
                    const SizedBox(height: AppTheme.spaceMD),
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: goal['progress'] / 100.0,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              goal['completed']
                                  ? Colors.green
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spaceMD),
                        Text(
                          '${goal['progress']}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),

          const SizedBox(height: AppTheme.spaceLG),

          // Goal Categories & Achievements
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Goal Categories',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceLG),

                Wrap(
                  spacing: AppTheme.spaceMD,
                  runSpacing: AppTheme.spaceMD,
                  children: [
                    _buildGoalCategory(
                      theme,
                      'Communication',
                      Icons.chat,
                      Colors.blue,
                      75,
                    ),
                    _buildGoalCategory(
                      theme,
                      'Quality Time',
                      Icons.favorite,
                      Colors.red,
                      60,
                    ),
                    _buildGoalCategory(
                      theme,
                      'Understanding',
                      Icons.psychology,
                      Colors.purple,
                      85,
                    ),
                    _buildGoalCategory(
                      theme,
                      'Growth',
                      Icons.trending_up,
                      Colors.green,
                      70,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spaceLG),

          // Achievements
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Achievements',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceLG),

                ...List.generate(3, (index) {
                  final achievements = [
                    {
                      'title': 'Week Warrior',
                      'description': 'Completed 5 goals this week',
                      'icon': Icons.star,
                      'color': Colors.amber,
                    },
                    {
                      'title': 'Communication Champion',
                      'description': 'Maintained positive tone for 7 days',
                      'icon': Icons.emoji_events,
                      'color': Colors.blue,
                    },
                    {
                      'title': 'Growth Mindset',
                      'description': 'Reflected on 10 conversations',
                      'icon': Icons.psychology,
                      'color': Colors.purple,
                    },
                  ];

                  final achievement = achievements[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppTheme.spaceMD),
                    padding: const EdgeInsets.all(AppTheme.spaceMD),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          achievement['color'] as Color,
                          (achievement['color'] as Color).withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spaceMD),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSM,
                            ),
                          ),
                          child: Icon(
                            achievement['icon'] as IconData,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spaceMD),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                achievement['title'] as String,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                achievement['description'] as String,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCategory(
    ThemeData theme,
    String title,
    IconData icon,
    Color color,
    double progress,
  ) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: AppTheme.spaceXS),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spaceXS),
          LinearProgressIndicator(
            value: progress / 100,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          const SizedBox(height: AppTheme.spaceXS),
          Text(
            '${progress.toInt()}%',
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceXS),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMD),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for detailed metric cards
  Widget _buildDetailedMetricCard(
    ThemeData theme,
    Map<String, dynamic> metric,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: metric['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(metric['icon'], color: metric['color'], size: 20),
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric['category'],
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Previous: ${metric['previous']}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                metric['current'],
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: metric['color'],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    metric['improvement']
                        ? Icons.trending_up
                        : Icons.trending_down,
                    color: metric['improvement'] ? Colors.green : Colors.red,
                    size: 16,
                  ),
                  Text(
                    '${metric['percentage']}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: metric['improvement'] ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper methods for overview tab
  Widget _buildActionButton(
    ThemeData theme,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMD),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: AppTheme.spaceXS),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    ThemeData theme,
    String title,
    String time,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceXS),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  time,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    ThemeData theme,
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppTheme.spaceXS),
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceXS),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
