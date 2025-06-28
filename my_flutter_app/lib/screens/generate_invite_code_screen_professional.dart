import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:share_plus/share_plus.dart';

class GenerateInviteCodeScreenProfessional extends StatefulWidget {
  final int codeLength;

  const GenerateInviteCodeScreenProfessional({super.key, this.codeLength = 6});

  @override
  State<GenerateInviteCodeScreenProfessional> createState() =>
      _GenerateInviteCodeScreenProfessionalState();
}

class _GenerateInviteCodeScreenProfessionalState
    extends State<GenerateInviteCodeScreenProfessional>
    with TickerProviderStateMixin {
  String? inviteCode;
  bool _isGenerating = false;
  bool _copied = false;

  late AnimationController _bounceController;
  late AnimationController _slideController;
  late Animation<double> _bounceAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _slideController.forward();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  String _generateCode(int length) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(
      length,
      (index) => chars[rand.nextInt(chars.length)],
    ).join();
  }

  void _onGeneratePressed() async {
    setState(() {
      _isGenerating = true;
      _copied = false;
    });

    // Add some delay for better UX
    await Future.delayed(const Duration(milliseconds: 1000));

    setState(() {
      inviteCode = _generateCode(widget.codeLength);
      _isGenerating = false;
    });

    _bounceController.forward().then((_) => _bounceController.reverse());
  }

  void _onCopyPressed() async {
    if (inviteCode != null) {
      await Clipboard.setData(ClipboardData(text: inviteCode!));
      setState(() => _copied = true);

      _showSnackBar('Invite code copied to clipboard!', isSuccess: true);

      // Reset copied state after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _copied = false);
      });
    } else {
      _showSnackBar('Generate a code first!', isError: true);
    }
  }

  void _onSharePressed() async {
    if (inviteCode != null) {
      try {
        await Share.share(
          'Join me on Unsaid! Use this invite code: $inviteCode\n\nDownload Unsaid: https://unsaid.app',
        );
      } catch (e) {
        _showSnackBar('Error sharing code', isError: true);
      }
    } else {
      _showSnackBar('Generate a code first!', isError: true);
    }
  }

  void _showSnackBar(
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Colors.red
            : isSuccess
            ? Colors.green
            : Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8F9FA), Color(0xFFE8E1FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Color(0xFF2D3748),
                          size: 20,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Generate Invite Code',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: const Color(0xFF2D3748),
                          fontWeight: FontWeight.w700,
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
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Header card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF6C47FF,
                                  ).withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF6C47FF),
                                        Color(0xFF00D2FF),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF6C47FF,
                                        ).withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.group_add_rounded,
                                    color: Colors.white,
                                    size: 50,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Invite Your Partner',
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                        color: const Color(0xFF2D3748),
                                        fontWeight: FontWeight.w600,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Generate a unique invite code to share with your partner and connect your profiles',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF4A5568),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Generate button or code display
                          if (inviteCode == null) ...[
                            // Generate button
                            SizedBox(
                              width: double.infinity,
                              height: 64,
                              child: ElevatedButton(
                                onPressed: _isGenerating
                                    ? null
                                    : _onGeneratePressed,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6C47FF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isGenerating
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Generating...',
                                            style: theme.textTheme.labelLarge
                                                ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.auto_awesome_rounded,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Generate Invite Code',
                                            style: theme.textTheme.labelLarge
                                                ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ] else ...[
                            // Code display
                            ScaleTransition(
                              scale: _bounceAnimation,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF6C47FF).withOpacity(0.1),
                                      const Color(0xFF00D2FF).withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF6C47FF,
                                    ).withOpacity(0.3),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF6C47FF,
                                      ).withOpacity(0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.key_rounded,
                                      color: Color(0xFF6C47FF),
                                      size: 32,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Your Invite Code',
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            color: const Color(0xFF4A5568),
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    SelectableText(
                                      inviteCode!,
                                      style: theme.textTheme.displayMedium
                                          ?.copyWith(
                                            color: const Color(0xFF6C47FF),
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 4,
                                            fontFamily: 'monospace',
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _copied
                                            ? Colors.green.withOpacity(0.1)
                                            : const Color(
                                                0xFF6C47FF,
                                              ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: _copied
                                              ? Colors.green.withOpacity(0.3)
                                              : const Color(
                                                  0xFF6C47FF,
                                                ).withOpacity(0.3),
                                        ),
                                      ),
                                      child: Text(
                                        _copied
                                            ? '✓ Copied to clipboard!'
                                            : 'Tap actions below to share',
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                              color: _copied
                                                  ? Colors.green
                                                  : const Color(0xFF6C47FF),
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Action buttons
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: _onCopyPressed,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _copied
                                            ? Colors.green
                                            : Colors.white,
                                        foregroundColor: _copied
                                            ? Colors.white
                                            : const Color(0xFF6C47FF),
                                        side: BorderSide(
                                          color: _copied
                                              ? Colors.green
                                              : const Color(0xFF6C47FF),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            _copied
                                                ? Icons.check_rounded
                                                : Icons.copy_rounded,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _copied ? 'Copied!' : 'Copy',
                                            style: theme.textTheme.labelMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: SizedBox(
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: _onSharePressed,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: const Color(
                                          0xFF6C47FF,
                                        ),
                                        side: const BorderSide(
                                          color: Color(0xFF6C47FF),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.share_rounded,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Share',
                                            style: theme.textTheme.labelMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Generate new code button
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    inviteCode = null;
                                    _copied = false;
                                  });
                                },
                                child: Text(
                                  'Generate New Code',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: const Color(0xFF6C47FF),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 32),

                          // Instructions
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.info_rounded,
                                      color: Color(0xFF6C47FF),
                                      size: 24,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'How to use',
                                      style: TextStyle(
                                        color: Color(0xFF2D3748),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildInstructionStep(
                                  '1',
                                  'Generate your unique code',
                                  'Create a secure invite code',
                                ),
                                const SizedBox(height: 12),
                                _buildInstructionStep(
                                  '2',
                                  'Share with your partner',
                                  'Send via message, email, or copy to clipboard',
                                ),
                                const SizedBox(height: 12),
                                _buildInstructionStep(
                                  '3',
                                  'Partner enters code',
                                  'They input the code in their Unsaid app',
                                ),
                                const SizedBox(height: 12),
                                _buildInstructionStep(
                                  '4',
                                  'Profiles connect',
                                  'Your relationship insights unlock automatically',
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

  Widget _buildInstructionStep(
    String number,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFF6C47FF),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF2D3748),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: const TextStyle(color: Color(0xFF4A5568), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
