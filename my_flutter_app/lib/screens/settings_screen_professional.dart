import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../services/keyboard_manager.dart';

class SettingsScreenProfessional extends StatefulWidget {
  final double sensitivity;
  final ValueChanged<double> onSensitivityChanged;
  final String tone;
  final ValueChanged<String> onToneChanged;

  const SettingsScreenProfessional({
    super.key,
    required this.sensitivity,
    required this.onSensitivityChanged,
    required this.tone,
    required this.onToneChanged,
  });

  @override
  State<SettingsScreenProfessional> createState() =>
      _SettingsScreenProfessionalState();
}

class _SettingsScreenProfessionalState extends State<SettingsScreenProfessional>
    with TickerProviderStateMixin {
  final KeyboardManager _keyboardManager = KeyboardManager();

  // UI state variables
  bool showHelp = false;

  // Advanced toggles (load from KeyboardManager in initState)
  bool onDeviceProcessing = true;
  bool voiceFeedback = false;
  bool hapticFeedback = true;
  bool childCenteredMode = false;
  String selectedLanguage = 'English';

  final List<String> _languageOptions = ['English', 'Spanish', 'French'];

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _loadSettingsFromManager();
  }

  Future<void> _loadSettingsFromManager() async {
    await _keyboardManager.initialize();
    setState(() {
      onDeviceProcessing =
          _keyboardManager.keyboardSettings['onDeviceProcessing'] ?? true;
      voiceFeedback =
          _keyboardManager.keyboardSettings['voiceFeedback'] ?? false;
      hapticFeedback =
          _keyboardManager.keyboardSettings['hapticFeedback'] ?? true;
      childCenteredMode =
          _keyboardManager.keyboardSettings['childCenteredMode'] ?? false;
      selectedLanguage =
          _keyboardManager.keyboardSettings['language'] ?? 'English';
    });
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

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _fadeController.forward();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _handleSensitivityChange(double value) {
    HapticFeedback.selectionClick();
    widget.onSensitivityChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.darkGradient : AppTheme.lightGradient,
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: Listenable.merge([_fadeController, _slideController]),
            builder: (context, child) {
              return CustomScrollView(
                slivers: [
                  // App Bar
                  SliverAppBar(
                    expandedHeight: 120,
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    automaticallyImplyLeading: false,
                    leading: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GestureDetector(
                        onTap: () => Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/home',
                          (route) => false,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: true,
                      title: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          'Settings',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.black.withOpacity(
                              0.85,
                            ), // Changed to a darker tone
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Settings Content
                  SliverPadding(
                    padding: EdgeInsets.all(AppTheme.spacing.lg),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Sensitivity Section (optional, not shown in your code)
                        // _buildSensitivitySection(),
                        // SizedBox(height: AppTheme.spacing.lg),

                        // Tone Section
                        _buildToneSection(),
                        SizedBox(height: AppTheme.spacing.lg),

                        // Preferences Section
                        _buildPreferencesSection(),
                        SizedBox(height: AppTheme.spacing.lg),

                        // Conversation History Section
                        _buildConversationHistorySection(),
                        SizedBox(height: AppTheme.spacing.lg),

                        // Actions Section
                        _buildActionsSection(),
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

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppTheme.spacing.sm),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radius.sm),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              SizedBox(width: AppTheme.spacing.md),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacing.md),
          child,
        ],
      ),
    );
  }

  Widget _buildToneSection() {
    final theme = Theme.of(context);
    final tones = ['Gentle', 'Direct', 'Balanced', 'Personal'];

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildSection(
          title: 'Default Tone',
          icon: Icons.chat_bubble_outline,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose your preferred communication style',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              SizedBox(height: AppTheme.spacing.md),
              Wrap(
                spacing: AppTheme.spacing.sm,
                runSpacing: AppTheme.spacing.sm,
                children: tones.map((tone) {
                  final isSelected = widget.tone == tone;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onToneChanged(tone);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing.md,
                        vertical: AppTheme.spacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radius.lg),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        tone,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.white,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreferencesSection() {
    final theme = Theme.of(context);

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildSection(
          title: 'Preferences',
          icon: Icons.settings_outlined,
          child: Column(
            children: [
              _buildToggleItem(
                title: 'Analyze tone on device',
                subtitle: 'Keep all analysis private and fast.',
                value: onDeviceProcessing,
                onChanged: (val) {
                  setState(() => onDeviceProcessing = val);
                  _keyboardManager.updateSetting('onDeviceProcessing', val);
                },
                icon: Icons.security,
              ),
              SizedBox(height: AppTheme.spacing.md),
              _buildDropdownItem(
                title: 'Preferred Language',
                subtitle: 'Choose your preferred language for analysis',
                value: selectedLanguage,
                items: _languageOptions,
                onChanged: (val) {
                  setState(() => selectedLanguage = val);
                  _keyboardManager.updateSetting('language', val);
                },
                icon: Icons.language,
              ),
              SizedBox(height: AppTheme.spacing.md),
              _buildToggleItem(
                title: 'Voice feedback for tone changes',
                subtitle: 'Hear a voice cue when tone changes',
                value: voiceFeedback,
                onChanged: (val) {
                  setState(() => voiceFeedback = val);
                  _keyboardManager.updateSetting('voiceFeedback', val);
                },
                icon: Icons.record_voice_over,
              ),
              _buildToggleItem(
                title: 'Haptic feedback for tone changes',
                subtitle: 'Feel a vibration when tone changes',
                value: hapticFeedback,
                onChanged: (val) {
                  setState(() => hapticFeedback = val);
                  _keyboardManager.updateSetting('hapticFeedback', val);
                },
                icon: Icons.vibration,
              ),
              _buildToggleItem(
                title: 'Enable Child-Centered Mode',
                subtitle: 'Focus messages on your child’s needs',
                value: childCenteredMode,
                onChanged: (val) {
                  setState(() => childCenteredMode = val);
                  _keyboardManager.updateSetting('childCenteredMode', val);
                },
                icon: Icons.child_care,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacing.sm),
      padding: EdgeInsets.all(AppTheme.spacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radius.md),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.8), size: 24),
          SizedBox(width: AppTheme.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppTheme.spacing.xs),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: theme.colorScheme.primary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.white.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownItem({
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radius.md),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.8), size: 24),
          SizedBox(width: AppTheme.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppTheme.spacing.xs),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          DropdownButton<String>(
            value: value,
            dropdownColor: Colors.black87,
            style: TextStyle(color: Colors.white),
            iconEnabledColor: Colors.white,
            underline: SizedBox(),
            items: items
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(item, style: TextStyle(color: Colors.white)),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) onChanged(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    final theme = Theme.of(context);

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildSection(
          title: 'Account Actions',
          icon: Icons.person_outline,
          child: Column(
            children: [
              GradientButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  // Handle change password
                },
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radius.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, color: Colors.white, size: 20),
                    SizedBox(width: AppTheme.spacing.sm),
                    Text(
                      'Change Password',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppTheme.spacing.md),
              GradientButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() => showHelp = !showHelp);
                },
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radius.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      showHelp ? Icons.help : Icons.help_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: AppTheme.spacing.sm),
                    Text(
                      'Help & Support',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (showHelp) ...[
                SizedBox(height: AppTheme.spacing.md),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: EdgeInsets.all(AppTheme.spacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radius.md),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.keyboard, color: Colors.white, size: 20),
                          SizedBox(width: AppTheme.spacing.sm),
                          Text(
                            'Keyboard Setup',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppTheme.spacing.sm),
                      Text(
                        'To enable the custom keyboard, go to your device settings and add "Unsaid" as a keyboard. Toggle above to turn it on/off in the app.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConversationHistorySection() {
    final theme = Theme.of(context);

    // Mock conversation history data
    final List<Map<String, dynamic>> recentAnalyses = [
      {
        'message': 'I love you so much, you mean everything to me.',
        'tone': 'Loving',
        'score': 95,
        'date': 'Today, 2:30 PM',
        'improvements': 2,
      },
      {
        'message': 'Can we talk about what happened earlier?',
        'tone': 'Concerned',
        'score': 72,
        'date': 'Yesterday, 5:45 PM',
        'improvements': 1,
      },
      {
        'message': 'Thank you for being so patient with me.',
        'tone': 'Grateful',
        'score': 88,
        'date': 'Yesterday, 11:20 AM',
        'improvements': 0,
      },
      {
        'message': 'I need some space right now.',
        'tone': 'Direct',
        'score': 65,
        'date': '2 days ago',
        'improvements': 3,
      },
    ];

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildSection(
          title: 'Conversation History',
          icon: Icons.history,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your recent message analyses and improvements',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              SizedBox(height: AppTheme.spacing.lg),

              // Statistics row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(AppTheme.spacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radius.md),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '347',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Total Analyses',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: AppTheme.spacing.md),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(AppTheme.spacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radius.md),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '82%',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Avg. Score',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: AppTheme.spacing.lg),

              // Recent analyses list
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(AppTheme.radius.md),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  children: recentAnalyses.asMap().entries.map((entry) {
                    final index = entry.key;
                    final analysis = entry.value;
                    final isLast = index == recentAnalyses.length - 1;

                    return Container(
                      padding: EdgeInsets.all(AppTheme.spacing.md),
                      decoration: BoxDecoration(
                        border: isLast
                            ? null
                            : Border(
                                bottom: BorderSide(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tone score indicator
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _getToneScoreColor(
                                analysis['score'],
                              ).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Text(
                                '${analysis['score']}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: _getToneScoreColor(analysis['score']),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: AppTheme.spacing.md),

                          // Message details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  analysis['message'],
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: AppTheme.spacing.xs),
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: AppTheme.spacing.xs,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getToneScoreColor(
                                          analysis['score'],
                                        ).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.radius.sm,
                                        ),
                                      ),
                                      child: Text(
                                        analysis['tone'],
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: _getToneScoreColor(
                                                analysis['score'],
                                              ),
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.auto_fix_high,
                                      size: 12,
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                    SizedBox(width: 2),
                                    Text(
                                      '${analysis['improvements']} improvements',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: Colors.white.withOpacity(
                                              0.6,
                                            ),
                                          ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: AppTheme.spacing.xs),
                                Text(
                                  analysis['date'],
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              SizedBox(height: AppTheme.spacing.lg),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: GradientButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        // Show full history
                      },
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.2),
                          Colors.white.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radius.md),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.list_alt, color: Colors.white, size: 18),
                          SizedBox(width: AppTheme.spacing.sm),
                          Text(
                            'View All',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: AppTheme.spacing.md),
                  Expanded(
                    child: GradientButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _showClearHistoryDialog();
                      },
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.withOpacity(0.3),
                          Colors.red.withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radius.md),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: AppTheme.spacing.sm),
                          Text(
                            'Clear',
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
            ],
          ),
        ),
      ),
    );
  }

  Color _getToneScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            'Clear History',
            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to clear all conversation history? This action cannot be undone.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Clear history logic here
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Conversation history cleared'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              child: Text('Clear', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
