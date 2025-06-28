import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'relationship_insights_dashboard.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool loading = false;
  String message = '';
  String analysis = '';
  bool loadingAnalysis = false;
  String userName = 'User';
  double sensitivity = 0.5;
  String selectedTone = 'neutral';
  List<Map<String, dynamic>> savedProfiles = [];

  // Mock personality data - in real app this would come from user's test results
  Map<String, int> mockPersonalityData = {
    'A': 3, // Anxious Connector
    'B': 7, // Secure Communicator (dominant)
    'C': 2, // Avoidant Thinker
    'D': 3, // Disorganized
  };

  String get dominantPersonalityType {
    String dominant = 'B';
    int maxCount = 0;
    mockPersonalityData.forEach((key, value) {
      if (value > maxCount) {
        dominant = key;
        maxCount = value;
      }
    });
    return dominant;
  }

  String get personalityTypeLabel {
    const typeLabels = {
      'A': "Anxious Connector",
      'B': "Secure Communicator",
      'C': "Avoidant Thinker",
      'D': "Disorganized",
    };
    return typeLabels[dominantPersonalityType] ?? "Unknown";
  }

  List<Map<String, dynamic>> toneOptions = [
    {'name': 'gentle', 'color': Colors.green, 'icon': Icons.favorite},
    {'name': 'direct', 'color': Colors.blue, 'icon': Icons.message},
    {'name': 'neutral', 'color': Colors.grey, 'icon': Icons.balance},
  ];

  // Partner profile state
  Map<String, dynamic>? partnerProfile;
  bool hasPartner =
      false; // This would be determined by checking if partner exists in database

  @override
  void initState() {
    super.initState();
    _loadPartnerProfile();
  }

  void _loadPartnerProfile() {
    // Mock partner data - in real app this would come from database
    setState(() {
      hasPartner = true; // Toggle this to test both states
      partnerProfile = {
        'name': 'Sarah Johnson',
        'email': 'sarah.j@example.com',
        'phone': '+1 (555) 123-4567',
        'personality_type': 'A',
        'personality_label': 'Anxious Connector',
        'relationship_duration': '2 years, 3 months',
        'communication_style': 'Thoughtful and caring',
        'last_analysis': DateTime.now().subtract(const Duration(hours: 3)),
        'profile_image': null,
        'test_completed': true,
        'joined_date': DateTime.now().subtract(const Duration(days: 45)),
      };
    });
  }

  void _invitePartner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildInvitePartnerSheet(),
    );
  }

  void handleEdit(String id) {
    // Edit implementation
  }

  void handleDelete(String id) {
    // Delete implementation
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF7B61FF)),
        ),
      );
    }

    var children = [
      // Header
      Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF7B61FF).withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.favorite,
              size: 24,
              color: Color(0xFF7B61FF),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, $userName',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your relationship insights',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          // Premium Button
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/premium');
            },
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF7B61FF),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.star, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Premium',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      const SizedBox(height: 32),

      // Partner Profile Section
      _buildPartnerProfileSection(),

      const SizedBox(height: 32),

      // Professional Cards Layout
      Row(
        children: [
          Expanded(child: _buildPersonalityCard()),
          const SizedBox(width: 16),
          Expanded(child: _buildToneIndicatorCard()),
          const SizedBox(width: 16),
          Expanded(child: _buildKeyboardSetupCard()),
        ],
      ),

      const SizedBox(height: 32),

      // Quick Tips Section
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Tips',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            _buildQuickTip('Emotionally stable'),
            _buildQuickTip('Practice active listening'),
            _buildQuickTip('Acknowledge your partner\'s feelings'),
            _buildQuickTip('Use gentle tone in difficult conversations'),
          ],
        ),
      ),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(children: children),
        ),
      ),
    );
  }

  // Partner Profile Section Builder
  Widget _buildPartnerProfileSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, color: const Color(0xFF7B61FF), size: 24),
              const SizedBox(width: 12),
              Text(
                'Relationship Partner',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (!hasPartner)
            _buildInvitePartnerCard()
          else
            _buildPartnerProfileCard(),
        ],
      ),
    );
  }

  Widget _buildInvitePartnerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF7B61FF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF7B61FF).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.person_add, color: const Color(0xFF7B61FF), size: 48),
          const SizedBox(height: 16),
          Text(
            'Invite Your Partner',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect with your partner to get personalized communication insights based on both your personalities.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.black.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _invitePartner,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B61FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Send Invitation',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerProfileCard() {
    if (partnerProfile == null) return const SizedBox();

    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, '/relationshipPartner');
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7B61FF), Color(0xFF9C27B0)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7B61FF).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Partner avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),

                // Partner info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partnerProfile!['name'],
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Personality label
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                // Color dot for attachment style
                                Container(
                                  width: 10,
                                  height: 10,
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: _getAttachmentColor(
                                      partnerProfile!['personality_type'],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Text(
                                  partnerProfile!['personality_label'],
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ],
                            ),
                          ),

                          // Communication style
                          if (partnerProfile!['communication_style'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                _mapCommunicationStyle(
                                  partnerProfile!['communication_style'],
                                ),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Colors.white.withOpacity(0.8),
                                      fontStyle: FontStyle.italic,
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status indicator
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.link, color: Colors.white, size: 20),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Relationship Link/Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const RelationshipInsightsDashboard(),
                    ),
                  );
                },
                icon: Icon(Icons.link, color: Colors.white),
                label: Text(
                  'Open Relationship Dashboard',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.15),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Quick stats
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${partnerProfile!['relationship_duration']}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Together',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: Colors.white.withOpacity(0.3),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '87%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Compatibility',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openRelationshipHub() {
    // Navigate to relationship hub with shared insights
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildRelationshipHubSheet(),
    );
  }

  Widget _buildRelationshipHubSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Relationship Hub',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Compatibility overview
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7B61FF), Color(0xFF9C27B0)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '87%',
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'Communication Compatibility',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'You and ${partnerProfile!['name']} have excellent communication synergy!',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.white.withOpacity(0.9)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quick actions
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildHubAction(
                          'Shared Insights',
                          Icons.insights,
                          Colors.blue,
                          () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const RelationshipInsightsDashboard(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildHubAction(
                          'Couple Goals',
                          Icons.favorite,
                          Colors.red,
                          () {
                            Navigator.pop(context);
                            // Replace with your actual Couple Goals page
                            Navigator.pushNamed(context, '/coupleGoals');
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildHubAction(
                          'Message Together',
                          Icons.chat_bubble_outline,
                          Colors.green,
                          () {
                            Navigator.pop(context);
                            // Replace with your actual Message Lab page
                            Navigator.pushNamed(context, '/messageLab');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildHubAction(
                          'Coaching Tips',
                          Icons.psychology,
                          Colors.orange,
                          () {
                            Navigator.pop(context);
                            // Navigate to coaching tab
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHubAction(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitePartnerSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Header
            Text(
              'Invite Your Partner',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Send an invitation to your partner so they can take the personality test and you can get personalized communication insights.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black.withOpacity(0.7),
              ),
            ),

            const SizedBox(height: 32),

            // Invite Options
            _buildInviteOption(
              icon: Icons.sms,
              title: 'Send via Text Message',
              subtitle: 'Send invitation link through SMS',
              onTap: () => _sendInviteViaSMS(),
            ),

            const SizedBox(height: 16),

            _buildInviteOption(
              icon: Icons.email,
              title: 'Send via Email',
              subtitle: 'Send invitation link through email',
              onTap: () => _sendInviteViaEmail(),
            ),

            const SizedBox(height: 16),

            _buildInviteOption(
              icon: Icons.share,
              title: 'Share Link',
              subtitle: 'Copy invitation link to share anywhere',
              onTap: () => _shareInviteLink(),
            ),

            const SizedBox(height: 32),

            // Preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preview Message:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hi! I\'ve been using Unsaid to improve our communication. Join me by taking a quick personality test so we can understand each other better: [invitation-link]',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black.withOpacity(0.8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF7B61FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, color: const Color(0xFF7B61FF), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _sendInviteViaSMS() {
    // In real app, this would open SMS app with pre-filled message
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening SMS app with invitation...'),
        backgroundColor: Color(0xFF7B61FF),
      ),
    );
  }

  void _sendInviteViaEmail() {
    // In real app, this would open email app with pre-filled message
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening email app with invitation...'),
        backgroundColor: Color(0xFF7B61FF),
      ),
    );
  }

  void _shareInviteLink() {
    // In real app, this would use share API
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invitation link copied to clipboard!'),
        backgroundColor: Color(0xFF7B61FF),
      ),
    );
  }

  Widget _buildToneIndicatorCard() {
    return _buildProfessionalCard(
      title: 'Tone Indicator',
      subtitle: 'Live feedback',
      icon: Icons.psychology_outlined,
      iconColor: const Color(0xFF4CAF50),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE8F5E8), Color(0xFFF1F8E9)],
      ),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildToneColorDot(const Color(0xFF00E676), 'Good', true),
          const SizedBox(width: 8),
          _buildToneColorDot(const Color(0xFFFFD600), 'Caution', false),
          const SizedBox(width: 8),
          _buildToneColorDot(const Color(0xFFFF1744), 'Alert', false),
        ],
      ),
      onTap: () => Navigator.pushNamed(context, '/tone_test'),
    );
  }

  Widget _buildToneColorDot(Color color, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalityCard() {
    return _buildProfessionalCard(
      title: 'Personality',
      subtitle: personalityTypeLabel.split(' ').first,
      icon: Icons.account_circle_outlined,
      iconColor: const Color(0xFFFF6B6B),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF5F5), Color(0xFFFEF7F7)],
      ),
      content: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade200, width: 2),
        ),
        child: CustomPaint(painter: MiniPieChartPainter(mockPersonalityData)),
      ),
      onTap: () {
        List<String> mockAnswers = [];
        mockPersonalityData.forEach((type, count) {
          for (int i = 0; i < count; i++) {
            mockAnswers.add(type);
          }
        });
        Navigator.pushNamed(
          context,
          '/personality_results',
          arguments: mockAnswers,
        );
      },
    );
  }

  Widget _buildKeyboardSetupCard() {
    return _buildProfessionalCard(
      title: 'Keyboard',
      subtitle: 'Setup & sync',
      icon: Icons.keyboard_outlined,
      iconColor: const Color(0xFF9C27B0),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF8F5FF), Color(0xFFFAF7FF)],
      ),
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF9C27B0).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 14,
              color: const Color(0xFF9C27B0),
            ),
            const SizedBox(width: 4),
            Text(
              'Ready',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF9C27B0),
              ),
            ),
          ],
        ),
      ),
      onTap: () => Navigator.pushNamed(context, '/keyboard_setup'),
    );
  }

  Widget _buildProfessionalCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required LinearGradient gradient,
    required Widget content,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 260,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.8), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with icon
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 16, color: iconColor),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),

              const SizedBox(height: 25),
              SizedBox(height: 70, child: Center(child: content)),

              const SizedBox(height: 25),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for quick tips
  Widget _buildQuickTip(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(Icons.circle, color: Color(0xFF7B61FF), size: 8),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Color _getAttachmentColor(String? type) {
    switch (type) {
      case 'A':
        return const Color(0xFFFF6B6B); // Red for Anxious
      case 'B':
        return const Color(0xFF4CAF50); // Green for Secure
      case 'C':
        return const Color(0xFF2196F3); // Blue for Avoidant
      case 'D':
        return const Color(0xFFFF9800); // Orange for Disorganized
      default:
        return Colors.grey;
    }
  }

  String _mapCommunicationStyle(String? style) {
    if (style == null) return '';
    final s = style.toLowerCase();
    if (s.contains('assertive')) return 'Assertive';
    if (s.contains('passive-aggressive')) return 'Passive-Aggressive';
    if (s.contains('aggressive')) return 'Aggressive';
    if (s.contains('passive')) return 'Passive';
    // Fallback for legacy/custom labels
    if (s.contains('thoughtful') || s.contains('caring')) return 'Passive';
    if (s.contains('direct')) return 'Assertive';
    return style;
  }
}

class MiniPieChartPainter extends CustomPainter {
  final Map<String, int> data;

  MiniPieChartPainter(this.data);

  static const Map<String, Color> typeColors = {
    'A': Color(0xFFFF6B6B), // Red for Anxious
    'B': Color(0xFF4CAF50), // Green for Secure
    'C': Color(0xFF2196F3), // Blue for Avoidant
    'D': Color(0xFFFF9800), // Orange for Disorganized
  };

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    final total = data.values.fold(0, (sum, value) => sum + value);
    if (total == 0) return;

    double startAngle = -math.pi / 2;

    data.forEach((key, value) {
      if (value > 0) {
        final sweepAngle = (value / total) * 2 * math.pi;
        final paint = Paint()
          ..color = typeColors[key] ?? Colors.grey
          ..style = PaintingStyle.fill;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
          true,
          paint,
        );

        startAngle += sweepAngle;
      }
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
