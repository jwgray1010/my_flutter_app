import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_button.dart';

class ShareProfileScreenProfessional extends StatefulWidget {
  const ShareProfileScreenProfessional({super.key});

  @override
  State<ShareProfileScreenProfessional> createState() =>
      _ShareProfileScreenProfessionalState();
}

class _ShareProfileScreenProfessionalState
    extends State<ShareProfileScreenProfessional>
    with TickerProviderStateMixin {
  bool includeTriggers = false;
  bool includeStrengths = true;
  bool includeInsights = true;
  bool sharing = false;

  // Demo data - replace with actual user data
  final String yourType = 'Anxious Connector';
  final String yourComm = 'Assertive'; // Communication style
  final String partnerType = 'Avoidant Thinker';
  final String partnerComm = 'Passive'; // Communication style
  final String compatibility = 'Challenging but transformative';
  final String insight =
      'This dynamic can create push-pull patterns. The anxious partner seeks closeness while the avoidant withdraws under pressure. With emotional awareness and gentle boundaries, trust can grow.';

  final List<String> triggers = [
    'Feeling ignored or left on read',
    'Sudden distance or silence',
    'Fear of abandonment',
    'Mixed signals',
  ];

  final List<String> strengths = [
    'Deep emotional awareness',
    'Strong desire for connection',
    'Intuitive understanding of emotions',
    'Passionate communication style',
  ];

  late AnimationController _shareController;
  late Animation<double> _shareAnimation;

  @override
  void initState() {
    super.initState();
    _shareController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _shareAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shareController, curve: Curves.easeOutCubic),
    );
    _shareController.forward();
  }

  @override
  void dispose() {
    _shareController.dispose();
    super.dispose();
  }

  Future<void> handleShare() async {
    setState(() => sharing = true);

    final message = _buildShareMessage();

    try {
      await Share.share(message);
      _showSnackBar('Profile shared successfully!', isSuccess: true);
    } catch (e) {
      _showSnackBar('Error sharing profile. Please try again.', isError: true);
    } finally {
      setState(() => sharing = false);
    }
  }

  String _buildShareMessage() {
    return '''
🌟 *Unsaid Relationship Profile*

👤 You: $yourType ($yourComm)
💕 Partner: $partnerType ($partnerComm)
🔗 Compatibility: $compatibility

${includeInsights ? '''
💡 Insight:
$insight
''' : ''}

${includeStrengths ? '''
✨ Your Strengths:
${strengths.map((s) => '• $s').join('\n')}
''' : ''}

${includeTriggers ? '''
⚠️ Potential Triggers:
${triggers.map((t) => '• $t').join('\n')}
''' : ''}

🚀 Discover your communication style with Unsaid
Available on the App Store & Google Play
''';
  }

  void _showSnackBar(
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    final theme = AppTheme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? theme.error
            : isSuccess
                ? theme.success
                : theme.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme.borderRadius.md),
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    if (type.toLowerCase().contains('anxious')) return Colors.red;
    if (type.toLowerCase().contains('avoidant')) return Colors.blue;
    if (type.toLowerCase().contains('secure')) return Colors.green;
    return Colors.purple;
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
                          semanticLabel: 'Back',
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Share Profile',
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
                child: FadeTransition(
                  opacity: _shareAnimation,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: theme.spacing.lg),
                    child: Column(
                      children: [
                        // Header card
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
                                  Icons.share_rounded,
                                  color: Colors.white,
                                  size: 40,
                                  semanticLabel: 'Share',
                                ),
                              ),
                              SizedBox(height: theme.spacing.lg),
                              Text(
                                'Share Your Profile',
                                style: theme.typography.headingMedium.copyWith(
                                  color: theme.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: theme.spacing.sm),
                              Text(
                                'Help others understand your communication style',
                                style: theme.typography.bodyMedium.copyWith(
                                  color: theme.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: theme.spacing.xl),

                        // Profile preview
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.preview_rounded,
                                    color: theme.primary,
                                    size: 24,
                                    semanticLabel: 'Profile Preview',
                                  ),
                                  SizedBox(width: theme.spacing.sm),
                                  Text(
                                    'Profile Preview',
                                    style: theme.typography.headingSmall
                                        .copyWith(color: theme.textPrimary),
                                  ),
                                ],
                              ),
                              SizedBox(height: theme.spacing.lg),

                              // Profile info
                              _buildProfileItem(
                                'You',
                                yourType,
                                Icons.person_rounded,
                                theme.primary,
                                theme,
                                comm: yourComm,
                              ),
                              SizedBox(height: theme.spacing.md),
                              _buildProfileItem(
                                'Partner',
                                partnerType,
                                Icons.favorite_rounded,
                                theme.secondary,
                                theme,
                                comm: partnerComm,
                              ),
                              SizedBox(height: theme.spacing.md),
                              _buildProfileItem(
                                'Compatibility',
                                compatibility,
                                Icons.psychology_rounded,
                                theme.success,
                                theme,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: theme.spacing.xl),

                        // Share options
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(theme.spacing.xl),
                          decoration: BoxDecoration(
                            color: theme.surfacePrimary,
                            borderRadius: BorderRadius.circular(
                              theme.borderRadius.lg,
                            ),
                            boxShadow: theme.shadows.small,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Customize Your Share',
                                style: theme.typography.headingSmall.copyWith(
                                  color: theme.textPrimary,
                                ),
                              ),
                              SizedBox(height: theme.spacing.lg),

                              // Include insights toggle
                              _buildToggleOption(
                                'Include Insights',
                                'Share relationship insights and compatibility analysis',
                                Icons.lightbulb_rounded,
                                includeInsights,
                                (value) =>
                                    setState(() => includeInsights = value),
                                theme,
                              ),

                              SizedBox(height: theme.spacing.md),

                              // Include strengths toggle
                              _buildToggleOption(
                                'Include Strengths',
                                'Highlight your communication strengths',
                                Icons.star_rounded,
                                includeStrengths,
                                (value) =>
                                    setState(() => includeStrengths = value),
                                theme,
                              ),

                              SizedBox(height: theme.spacing.md),

                              // Include triggers toggle
                              _buildToggleOption(
                                'Include Triggers',
                                'Share potential communication triggers (sensitive)',
                                Icons.warning_rounded,
                                includeTriggers,
                                (value) =>
                                    setState(() => includeTriggers = value),
                                theme,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: theme.spacing.xl),

                        // Share buttons
                        Row(
                          children: [
                            Expanded(
                              child: PremiumButton(
                                text: 'Preview',
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) =>
                                        _buildPreviewDialog(theme),
                                  );
                                },
                                variant: PremiumButtonVariant.outline,
                                icon: Icons.visibility_rounded,
                              ),
                            ),
                            SizedBox(width: theme.spacing.md),
                            Expanded(
                              flex: 2,
                              child: PremiumButton(
                                text: sharing ? 'Sharing...' : 'Share Profile',
                                onPressed: sharing ? null : handleShare,
                                icon: sharing ? null : Icons.share_rounded,
                                isLoading: sharing,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: theme.spacing.xl),
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

  Widget _buildProfileItem(
    String label,
    String value,
    IconData icon,
    Color color,
    AppThemeData theme, {
    String? comm,
  }) {
    return Container(
      padding: EdgeInsets.all(theme.spacing.md),
      decoration: BoxDecoration(
        color: theme.surfacePrimary,
        borderRadius: BorderRadius.circular(theme.borderRadius.md),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Color dot for type/compatibility
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          Container(
            padding: EdgeInsets.all(theme.spacing.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(theme.borderRadius.sm),
            ),
            child: Icon(icon, color: color, size: 18, semanticLabel: label),
          ),
          SizedBox(width: theme.spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.typography.labelMedium.copyWith(
                    color: theme.textSecondary,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      value,
                      style: theme.typography.bodyMedium.copyWith(
                        color: theme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (comm != null) ...[
                      SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getCommColor(comm).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: _getCommColor(comm).withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble,
                                color: _getCommColor(comm),
                                size: 14,
                                semanticLabel: 'Communication Style'),
                            SizedBox(width: 4),
                            Text(
                              comm,
                              style: TextStyle(
                                color: _getCommColor(comm),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(
    String title,
    String description,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
    AppThemeData theme,
  ) {
    return Container(
      padding: EdgeInsets.all(theme.spacing.md),
      decoration: BoxDecoration(
        color: theme.backgroundPrimary,
        borderRadius: BorderRadius.circular(theme.borderRadius.md),
        border: Border.all(
          color: value ? theme.primary.withOpacity(0.3) : theme.borderColor,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: value ? theme.primary : theme.textSecondary,
            size: 20,
            semanticLabel: title,
          ),
          SizedBox(width: theme.spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.typography.bodyMedium.copyWith(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: theme.typography.bodySmall.copyWith(
                    color: theme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: theme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewDialog(AppThemeData theme) {
    return Dialog(
      backgroundColor: theme.surfacePrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.borderRadius.lg),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: EdgeInsets.all(theme.spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.preview_rounded,
                    color: theme.primary, size: 24, semanticLabel: 'Preview'),
                SizedBox(width: theme.spacing.sm),
                Text(
                  'Share Preview',
                  style: theme.typography.headingMedium.copyWith(
                    color: theme.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded,
                      color: theme.textSecondary, semanticLabel: 'Close'),
                ),
              ],
            ),
            SizedBox(height: theme.spacing.lg),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(theme.spacing.md),
              decoration: BoxDecoration(
                color: theme.backgroundPrimary,
                borderRadius: BorderRadius.circular(theme.borderRadius.md),
                border: Border.all(color: theme.borderColor),
              ),
              child: Text(
                _buildShareMessage(),
                style: theme.typography.bodySmall.copyWith(
                  color: theme.textPrimary,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            SizedBox(height: theme.spacing.lg),
            SizedBox(
              width: double.infinity,
              child: PremiumButton(
                text: 'Close',
                onPressed: () => Navigator.of(context).pop(),
                variant: PremiumButtonVariant.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
