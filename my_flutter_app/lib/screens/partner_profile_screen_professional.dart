import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/advanced_components.dart';
import '../widgets/gradient_button.dart';
import 'code_generate_screen_professional.dart';

class PartnerProfileScreen extends StatefulWidget {
  final String userId;
  final Future<String> Function(Map<String, dynamic> profile)?
  generateInviteCode;
  final Future<void> Function(
    String userId,
    String partnerName,
    String attachmentType,
  )?
  saveProfile;

  const PartnerProfileScreen({
    super.key,
    this.userId = "demoUserId",
    this.generateInviteCode,
    this.saveProfile,
  });

  @override
  State<PartnerProfileScreen> createState() => _PartnerProfileScreenState();
}

class _PartnerProfileScreenState extends State<PartnerProfileScreen>
    with TickerProviderStateMixin {
  final TextEditingController _partnerNameController = TextEditingController();
  String? _selectedAttachment;
  String? _selectedCommunicationStyle;
  bool _loading = false;
  String? _generatedCode;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  final List<Map<String, dynamic>> attachmentTypes = [
    {
      'type': 'Secure',
      'description': 'Comfortable with closeness, emotionally available',
      'icon': Icons.shield_outlined,
      'color': const Color(0xFF4CAF50),
      'traits': ['Emotionally stable', 'Good communication', 'Trust building'],
    },
    {
      'type': 'Dismissive Avoidant',
      'description': 'Values independence, avoids emotional intimacy',
      'icon': Icons.trending_down_outlined,
      'color': const Color(0xFF2196F3),
      'traits': ['Self-reliant', 'Needs space', 'Logical approach'],
    },
    {
      'type': 'Anxious',
      'description': 'Seeks reassurance, fears abandonment',
      'icon': Icons.favorite_border_outlined,
      'color': const Color(0xFFFF9800),
      'traits': ['Seeks closeness', 'Needs reassurance', 'Emotional depth'],
    },
    {
      'type': 'Fearful Avoidant',
      'description': 'Wants intimacy but fears rejection',
      'icon': Icons.psychology_outlined,
      'color': const Color(0xFF9C27B0),
      'traits': ['Complex needs', 'Push-pull dynamics', 'Deep emotions'],
    },
  ];

  final List<Map<String, dynamic>> communicationStyles = [
    {
      'type': 'Assertive',
      'description': 'Clear, direct, respectful communication',
      'color': Color(0xFF4CAF50), // Green
    },
    {
      'type': 'Passive',
      'description': 'Avoids conflict, may not express needs',
      'color': Color(0xFFFFD600), // Yellow
    },
    {
      'type': 'Aggressive',
      'description': 'Forceful, dominating, may disregard others',
      'color': Color(0xFFFF1744), // Red
    },
    {
      'type': 'Passive-Aggressive',
      'description': 'Indirect, may express anger subtly',
      'color': Color(0xFF9C27B0), // Purple
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );

    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _partnerNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final partnerName = _partnerNameController.text.trim();
    if (partnerName.isEmpty || _selectedAttachment == null) {
      _showValidationError(
        "Please enter a name and select an attachment type.",
      );
      return;
    }

    setState(() => _loading = true);
    HapticFeedback.mediumImpact();

    try {
      if (widget.saveProfile != null) {
        await widget.saveProfile!(
          widget.userId,
          partnerName,
          _selectedAttachment!,
        );
      }
      _showSuccessMessage("Your partner's profile has been saved.");
    } catch (e) {
      _showErrorMessage("Error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _handleGenerateAndGoToCodeScreen() async {
    final partnerName = _partnerNameController.text.trim();
    if (partnerName.isEmpty || _selectedAttachment == null) {
      _showValidationError(
        "Please enter a name and select an attachment type.",
      );
      return;
    }

    setState(() => _loading = true);
    HapticFeedback.mediumImpact();

    final profile = {
      'partnerName': partnerName,
      'explanation': _getAttachmentExplanation(_selectedAttachment!),
      'personalityMatch': _selectedAttachment!,
    };

    try {
      String code;
      if (widget.generateInviteCode != null) {
        code = await widget.generateInviteCode!(profile);
      } else {
        code =
            'DEMO${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
      }

      setState(() {
        _generatedCode = code;
        _loading = false;
      });

      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              CodeGenerateScreenProfessional(code: code),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            );
          },
        ),
      );
    } catch (e) {
      setState(() => _loading = false);
      _showErrorMessage("Error generating code: $e");
    }
  }

  String _getAttachmentExplanation(String type) {
    switch (type) {
      case 'Secure':
        return "This person feels comfortable with emotional closeness and communication. They're likely to be supportive and understanding.";
      case 'Dismissive Avoidant':
        return "This person may pull away during conflict to feel safe. They aren't pushing you away — they're protecting themselves.";
      case 'Anxious':
        return "This person deeply values connection and may need extra reassurance. Their emotions run deep and they care immensely.";
      case 'Fearful Avoidant':
        return "This person wants closeness but may fear getting hurt. They need patience and consistent emotional safety.";
      default:
        return "Understanding your partner's attachment style helps build stronger communication.";
    }
  }

  void _showValidationError(String message) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
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

  void _showSuccessMessage(String message) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppTheme.spaceMD),
      ),
    );
  }

  void _showErrorMessage(String message) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
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

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _fadeController,
              _slideController,
              _pulseController,
            ]),
            builder: (context, child) {
              return CustomScrollView(
                slivers: [
                  // App Bar
                  SliverAppBar(
                    expandedHeight: 120,
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: GestureDetector(
                      onTap: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/home',
                        (route) => false,
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.asset(
                          'assets/logo_icon.png',
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: true,
                      title: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          'Partner Profile',
                          style: theme.textTheme.headlineMedium?.copyWith(
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
                        ),
                      ),
                      background: Center(
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(AppTheme.spaceMD),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.2),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.people_outline,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Content
                  SliverPadding(
                    padding: const EdgeInsets.all(AppTheme.spaceLG),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Introduction
                        SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: PremiumCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(
                                          AppTheme.spaceSM,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            AppTheme.radiusSM,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.psychology_outlined,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: AppTheme.spaceMD),
                                      Text(
                                        'Understanding Your Partner',
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppTheme.spaceMD),
                                  Text(
                                    'Help us understand your partner\'s communication style to provide better relationship insights and suggestions.',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: AppTheme.spaceLG),

                        // Partner Name Input
                        SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: PremiumCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Partner\'s Name',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: AppTheme.spaceMD),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusMD,
                                      ),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: TextField(
                                      controller: _partnerNameController,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                      decoration: InputDecoration(
                                        hintText: 'Enter their name',
                                        hintStyle: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              color: Colors.white.withOpacity(
                                                0.6,
                                              ),
                                            ),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.all(
                                          AppTheme.spaceLG,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.person_outline,
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                      ),
                                      onChanged: (value) => setState(() {}),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: AppTheme.spaceLG),

                        // Attachment Types
                        SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: PremiumCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Attachment Style',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.spaceSM),
                                  Text(
                                    'Select the style that best describes your partner:',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.spaceLG),
                                  ...attachmentTypes.asMap().entries.map((
                                    entry,
                                  ) {
                                    final index = entry.key;
                                    final attachment = entry.value;
                                    final isSelected =
                                        _selectedAttachment ==
                                        attachment['type'];

                                    return TweenAnimationBuilder<double>(
                                      duration: Duration(
                                        milliseconds: 400 + (index * 100),
                                      ),
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      curve: Curves.easeOutBack,
                                      builder: (context, value, child) {
                                        return Transform.translate(
                                          offset: Offset(0, (1 - value) * 30),
                                          child: Opacity(
                                            opacity: value,
                                            child: Container(
                                              margin: const EdgeInsets.only(
                                                bottom: AppTheme.spaceMD,
                                              ),
                                              child: AnimatedScale(
                                                scale: isSelected
                                                    ? _pulseAnimation.value
                                                    : 1.0,
                                                duration: const Duration(
                                                  milliseconds: 200,
                                                ),
                                                child: GestureDetector(
                                                  onTap: () {
                                                    HapticFeedback.selectionClick();
                                                    setState(() {
                                                      _selectedAttachment =
                                                          attachment['type'];
                                                    });
                                                  },
                                                  child: AnimatedContainer(
                                                    duration: const Duration(
                                                      milliseconds: 300,
                                                    ),
                                                    curve: Curves.easeOutCubic,
                                                    padding:
                                                        const EdgeInsets.all(
                                                          AppTheme.spaceLG,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: isSelected
                                                          ? Colors.white
                                                          : Colors.white
                                                                .withOpacity(
                                                                  0.1,
                                                                ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            AppTheme.radiusLG,
                                                          ),
                                                      border: Border.all(
                                                        color: isSelected
                                                            ? attachment['color']
                                                            : Colors.white
                                                                  .withOpacity(
                                                                    0.3,
                                                                  ),
                                                        width: isSelected
                                                            ? 2
                                                            : 1,
                                                      ),
                                                      boxShadow: isSelected
                                                          ? [
                                                              BoxShadow(
                                                                color: attachment['color']
                                                                    .withOpacity(
                                                                      0.3,
                                                                    ),
                                                                blurRadius: 20,
                                                                spreadRadius: 2,
                                                              ),
                                                            ]
                                                          : null,
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets.all(
                                                                    AppTheme
                                                                        .spaceSM,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color:
                                                                    isSelected
                                                                    ? attachment['color']
                                                                          .withOpacity(
                                                                            0.1,
                                                                          )
                                                                    : Colors
                                                                          .white
                                                                          .withOpacity(
                                                                            0.2,
                                                                          ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      AppTheme
                                                                          .radiusSM,
                                                                    ),
                                                              ),
                                                              child: Icon(
                                                                attachment['icon'],
                                                                color:
                                                                    isSelected
                                                                    ? attachment['color']
                                                                    : Colors
                                                                          .white,
                                                                size: 20,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: AppTheme
                                                                  .spaceMD,
                                                            ),
                                                            Expanded(
                                                              child: Text(
                                                                attachment['type'],
                                                                style: theme
                                                                    .textTheme
                                                                    .titleMedium
                                                                    ?.copyWith(
                                                                      color:
                                                                          isSelected
                                                                          ? attachment['color']
                                                                          : Colors.white,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                              ),
                                                            ),
                                                            if (isSelected)
                                                              Icon(
                                                                Icons
                                                                    .check_circle,
                                                                color:
                                                                    attachment['color'],
                                                                size: 24,
                                                              ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                          height:
                                                              AppTheme.spaceMD,
                                                        ),
                                                        Text(
                                                          attachment['description'],
                                                          style: theme
                                                              .textTheme
                                                              .bodyMedium
                                                              ?.copyWith(
                                                                color:
                                                                    isSelected
                                                                    ? attachment['color']
                                                                          .withOpacity(
                                                                            0.8,
                                                                          )
                                                                    : Colors
                                                                          .white
                                                                          .withOpacity(
                                                                            0.8,
                                                                          ),
                                                                height: 1.3,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          height:
                                                              AppTheme.spaceMD,
                                                        ),
                                                        Wrap(
                                                          spacing:
                                                              AppTheme.spaceSM,
                                                          runSpacing:
                                                              AppTheme.spaceSM,
                                                          children:
                                                              (attachment['traits']
                                                                      as List<
                                                                        String
                                                                      >)
                                                                  .map((trait) {
                                                                    return Container(
                                                                      padding: const EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            AppTheme.spaceSM,
                                                                        vertical:
                                                                            AppTheme.spaceXS,
                                                                      ),
                                                                      decoration: BoxDecoration(
                                                                        color:
                                                                            isSelected
                                                                            ? attachment['color'].withOpacity(
                                                                                0.1,
                                                                              )
                                                                            : Colors.white.withOpacity(
                                                                                0.1,
                                                                              ),
                                                                        borderRadius: BorderRadius.circular(
                                                                          AppTheme
                                                                              .radiusSM,
                                                                        ),
                                                                        border: Border.all(
                                                                          color:
                                                                              isSelected
                                                                              ? attachment['color'].withOpacity(
                                                                                  0.3,
                                                                                )
                                                                              : Colors.white.withOpacity(0.3),
                                                                          width:
                                                                              1,
                                                                        ),
                                                                      ),
                                                                      child: Text(
                                                                        trait,
                                                                        style: theme.textTheme.bodySmall?.copyWith(
                                                                          color:
                                                                              isSelected
                                                                              ? attachment['color']
                                                                              : Colors.white.withOpacity(0.9),
                                                                          fontWeight:
                                                                              FontWeight.w500,
                                                                        ),
                                                                      ),
                                                                    );
                                                                  })
                                                                  .toList(),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: AppTheme.space2XL),

                        // Communication Style
                        SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: PremiumCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Communication Style',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.spaceSM),
                                  Text(
                                    'Select the style that best describes your partner\'s communication approach:',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.spaceLG),
                                  // Communication style options
                                  ...communicationStyles.map((style) {
                                    final isSelected =
                                        _selectedCommunicationStyle == style['type'];

                                    return GestureDetector(
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        setState(() {
                                          _selectedCommunicationStyle =
                                              isSelected ? null : style['type'];
                                        });
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(
                                          bottom: AppTheme.spaceMD,
                                        ),
                                        padding: const EdgeInsets.all(
                                          AppTheme.spaceLG,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.white.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            AppTheme.radiusMD,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? style['color']
                                                : Colors.white.withOpacity(0.3),
                                            width: isSelected ? 2 : 1,
                                          ),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: style['color']
                                                        .withOpacity(0.3),
                                                    blurRadius: 20,
                                                    spreadRadius: 2,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.comment_outlined,
                                              color: isSelected
                                                  ? style['color']
                                                  : Colors.white.withOpacity(0.7),
                                            ),
                                            const SizedBox(width: AppTheme.spaceMD),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    style['type'],
                                                    style: theme.textTheme.titleMedium?.copyWith(
                                                      color: isSelected ? style['color'] : Colors.white,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    style['description'],
                                                    style: theme.textTheme.bodySmall?.copyWith(
                                                      color: isSelected
                                                          ? style['color'].withOpacity(0.8)
                                                          : Colors.white.withOpacity(0.7),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (isSelected)
                                              Icon(
                                                Icons.check_circle,
                                                color: style['color'],
                                                size: 24,
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: AppTheme.spaceLG),

                        // Action Buttons
                        SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Column(
                              children: [
                                // Generate Code Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: GradientButton(
                                    onPressed: _loading
                                        ? null
                                        : _handleGenerateAndGoToCodeScreen,
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white,
                                        Colors.white.withOpacity(0.9),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusLG,
                                    ),
                                    child: _loading
                                        ? SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    theme.colorScheme.primary,
                                                  ),
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.qr_code_2,
                                                color:
                                                    theme.colorScheme.primary,
                                                size: 24,
                                              ),
                                              const SizedBox(
                                                width: AppTheme.spaceMD,
                                              ),
                                              Text(
                                                'Generate Sharing Code',
                                                style: theme
                                                    .textTheme
                                                    .titleLarge
                                                    ?.copyWith(
                                                      color: theme
                                                          .colorScheme
                                                          .primary,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),

                                const SizedBox(height: AppTheme.spaceMD),

                                // Save Profile Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: OutlinedButton.icon(
                                    onPressed: _loading ? null : _handleSave,
                                    icon: Icon(
                                      Icons.bookmark_outline,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    label: Text(
                                      'Save Profile',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
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
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: AppTheme.spaceLG),
                      ]),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
