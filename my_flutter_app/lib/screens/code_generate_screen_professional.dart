import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_button.dart';

class CodeGenerateScreenProfessional extends StatefulWidget {
  final String code;

  const CodeGenerateScreenProfessional({super.key, required this.code});

  @override
  State<CodeGenerateScreenProfessional> createState() =>
      _CodeGenerateScreenProfessionalState();
}

class _CodeGenerateScreenProfessionalState
    extends State<CodeGenerateScreenProfessional>
    with TickerProviderStateMixin {
  late AnimationController _codeController;
  late AnimationController _bounceController;
  late Animation<double> _codeAnimation;
  late Animation<double> _bounceAnimation;

  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _codeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _codeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _codeController, curve: Curves.easeOutCubic),
    );

    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    _codeController.forward();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void handleCopy(BuildContext context) async {
    try {
      await Clipboard.setData(ClipboardData(text: widget.code));
      setState(() => _copied = true);
      _bounceController.forward().then((_) => _bounceController.reverse());

      _showSnackBar('Code copied to clipboard!', isSuccess: true);

      // Reset copied state after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _copied = false);
      });
    } catch (e) {
      _showSnackBar('Failed to copy code', isError: true);
    }
  }

  void handleEmail(BuildContext context) async {
    final subject = 'Join me on Unsaid - Unlock My Relationship Profile';
    final body =
        '''Hey! 👋

I wanted to share something that might help us understand each other better.

I've been using Unsaid to learn about my communication style in relationships, and I'd love for you to see my profile and create yours too.

Use this code in the Unsaid app:

🔐 Code: ${widget.code}

Download Unsaid:
📱 App Store: https://apps.apple.com/app/unsaid
🤖 Google Play: https://play.google.com/store/apps/details?id=com.unsaid

Looking forward to better understanding each other! ❤️
''';

    final url =
        'mailto:?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';
    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showSnackBar('Could not open email app', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error opening email app', isError: true);
    }
  }

  void handleShare() async {
    final shareText = '''🔐 Join me on Unsaid with code: ${widget.code}

Discover your relationship communication style and unlock deeper connection.

Download: https://unsaid.app
''';

    try {
      // Using basic sharing - you might want to add share_plus package
      await Clipboard.setData(ClipboardData(text: shareText));
      _showSnackBar('Share text copied to clipboard!', isSuccess: true);
    } catch (e) {
      _showSnackBar('Error preparing share content', isError: true);
    }
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
                        'Invite Code',
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
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: theme.spacing.lg),
                    child: FadeTransition(
                      opacity: _codeAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                                  width: 100,
                                  height: 100,
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
                                    Icons.key_rounded,
                                    color: Colors.white,
                                    size: 50,
                                  ),
                                ),
                                SizedBox(height: theme.spacing.lg),
                                Text(
                                  'Your Invite Code',
                                  style: theme.typography.headingLarge.copyWith(
                                    color: theme.textPrimary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: theme.spacing.sm),
                                Text(
                                  'Share this code with your partner to connect profiles',
                                  style: theme.typography.bodyMedium.copyWith(
                                    color: theme.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: theme.spacing.xl * 2),

                          // Code display
                          ScaleTransition(
                            scale: _bounceAnimation,
                            child: Container(
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
                                  color: theme.primary.withOpacity(0.3),
                                  width: 2,
                                ),
                                boxShadow: theme.shadows.large,
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    widget.code,
                                    style: theme.typography.displaySmall
                                        .copyWith(
                                          color: theme.primary,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 4,
                                          fontFamily: 'monospace',
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: theme.spacing.lg),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: theme.spacing.md,
                                      vertical: theme.spacing.sm,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _copied
                                          ? theme.success.withOpacity(0.1)
                                          : theme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(
                                        theme.borderRadius.sm,
                                      ),
                                      border: Border.all(
                                        color: _copied
                                            ? theme.success.withOpacity(0.3)
                                            : theme.primary.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      _copied ? '✓ Copied!' : 'Tap to copy',
                                      style: theme.typography.labelMedium
                                          .copyWith(
                                            color: _copied
                                                ? theme.success
                                                : theme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: theme.spacing.xl * 2),

                          // Action buttons
                          Column(
                            children: [
                              // Copy button
                              PremiumButton(
                                text: _copied ? 'Copied!' : 'Copy Code',
                                onPressed: () => handleCopy(context),
                                width: double.infinity,
                                icon: _copied
                                    ? Icons.check_rounded
                                    : Icons.copy_rounded,
                                backgroundColor: _copied ? theme.success : null,
                              ),

                              SizedBox(height: theme.spacing.lg),

                              // Action buttons row
                              Row(
                                children: [
                                  Expanded(
                                    child: PremiumButton(
                                      text: 'Send Email',
                                      onPressed: () => handleEmail(context),
                                      variant: PremiumButtonVariant.outline,
                                      icon: Icons.email_rounded,
                                    ),
                                  ),
                                  SizedBox(width: theme.spacing.md),
                                  Expanded(
                                    child: PremiumButton(
                                      text: 'Share',
                                      onPressed: handleShare,
                                      variant: PremiumButtonVariant.outline,
                                      icon: Icons.share_rounded,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          SizedBox(height: theme.spacing.xl * 2),

                          // Instructions card
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
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_rounded,
                                      color: theme.info,
                                      size: 24,
                                    ),
                                    SizedBox(width: theme.spacing.sm),
                                    Text(
                                      'How it works',
                                      style: theme.typography.headingSmall
                                          .copyWith(color: theme.textPrimary),
                                    ),
                                  ],
                                ),
                                SizedBox(height: theme.spacing.lg),

                                _buildInstructionStep(
                                  '1',
                                  'Share this code',
                                  'Send the code to your partner via email or message',
                                  theme,
                                ),
                                SizedBox(height: theme.spacing.md),
                                _buildInstructionStep(
                                  '2',
                                  'Partner enters code',
                                  'They input the code in their Unsaid app',
                                  theme,
                                ),
                                SizedBox(height: theme.spacing.md),
                                _buildInstructionStep(
                                  '3',
                                  'Profiles connect',
                                  'Your relationship profiles link and insights unlock',
                                  theme,
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: theme.spacing.xl),
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

  Widget _buildInstructionStep(
    String number,
    String title,
    String description,
    AppThemeData theme,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: theme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: theme.typography.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        SizedBox(width: theme.spacing.md),
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
      ],
    );
  }
}
