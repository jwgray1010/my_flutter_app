import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CustomKeyboardViewScreenProfessional extends StatefulWidget {
  const CustomKeyboardViewScreenProfessional({super.key});

  @override
  State<CustomKeyboardViewScreenProfessional> createState() =>
      _CustomKeyboardViewScreenProfessionalState();
}

class _CustomKeyboardViewScreenProfessionalState
    extends State<CustomKeyboardViewScreenProfessional>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _analyzeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _analyzeAnimation;

  String? feedback;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _analyzeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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

    _analyzeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _analyzeController, curve: Curves.easeOutBack),
    );

    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _slideController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    _analyzeController.dispose();
    super.dispose();
  }

  Future<void> analyzeText() async {
    final message = _controller.text.trim();
    if (message.isEmpty) {
      _showSnackBar('Please enter a message.', Colors.orange);
      return;
    }

    setState(() {
      loading = true;
      feedback = null;
    });

    try {
      final res = await http.post(
        Uri.parse('https://your-firebase-url/analyzeMessage'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'partnerAttachmentType':
              'avoidant', // Example; pull from user settings
          'partnerCommunicationStyle': 'passive', // Example; add if available
        }),
      );

      final data = jsonDecode(res.body);
      setState(() {
        feedback = data['analysis'] ?? "No analysis returned.";
      });

      if (feedback != null) {
        _analyzeController.forward();
      }
    } catch (err) {
      setState(() {
        feedback = "Couldn't analyze. Please try again.";
      });
      _showSnackBar("Couldn't analyze. Please try again.", Colors.red);
    }

    setState(() {
      loading = false;
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Color _getColorFromTone(String? tone) {
    switch (tone) {
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'red':
        return Colors.red;
      case 'gray':
      default:
        return Colors.grey;
    }
  }

  // Fix: Ensure 'data' is defined and feedback parsing is robust
  // Place this above the build method or inside the State class
  Map<String, dynamic> get _parsedFeedbackData {
    try {
      if (feedback == null) return {};
      // If feedback is a JSON string, parse it; otherwise, return empty map
      final parsed = jsonDecode(feedback!);
      if (parsed is Map<String, dynamic>) return parsed;
      return {};
    } catch (_) {
      return {};
    }
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
            colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
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
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Message Analyzer',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Logo
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Image.asset(
                              'assets/logo_icon.png',
                              width: 48,
                              height: 48,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Instructions
                          Text(
                            'Type your message and get insights',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.7,
                              ),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 24),

                          // Text Input
                          Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.outline.withOpacity(
                                  0.3,
                                ),
                              ),
                            ),
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: "Type your message here...",
                                hintStyle: TextStyle(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(16),
                              ),
                              style: theme.textTheme.bodyLarge,
                              textInputAction: TextInputAction.done,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Analyze Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: loading ? null : analyzeText,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 2,
                                disabledBackgroundColor: Colors.grey
                                    .withOpacity(0.3),
                              ),
                              child: loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.analytics_outlined,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Analyze Message',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Feedback Display
                          if (feedback != null)
                            Expanded(
                              child: ScaleTransition(
                                scale: _analyzeAnimation,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        theme.colorScheme.primary.withOpacity(
                                          0.1,
                                        ),
                                        theme.colorScheme.secondary.withOpacity(
                                          0.1,
                                        ),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.psychology_outlined,
                                            color: theme.colorScheme.primary,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Analysis Result',
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      theme.colorScheme.primary,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Expanded(
                                        child: SingleChildScrollView(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Tone Indicator
                                              Row(
                                                children: [
                                                  // Extract tone from feedback data
                                                  // final tone = data['tone'];
                                                  // final toneColor = _getColorFromTone(tone);
                                                  Container(
                                                    width: 24,
                                                    height: 24,
                                                    decoration: BoxDecoration(
                                                      color: _getColorFromTone(
                                                          _parsedFeedbackData[
                                                              'tone']?.toString()),
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Message Tone',
                                                    style: theme
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: theme
                                                              .colorScheme
                                                              .onSurface,
                                                        ),
                                                  ),
                                                ],
                                              ),

                                              const SizedBox(height: 12),

                                              // Feedback Text
                                              Text(
                                                _parsedFeedbackData['analysis']
                                                        ?.toString() ??
                                                    feedback!,
                                                style: theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      height: 1.5,
                                                      color: theme
                                                          .colorScheme
                                                          .onSurface,
                                                    ),
                                              ),

                                              // Example feedback display
                                              if (_parsedFeedbackData['attachmentStyle'] != null &&
                                                  _parsedFeedbackData['communicationStyle'] != null) ...[
                                                Text(
                                                  'Attachment Style: ${_parsedFeedbackData['attachmentStyle']}',
                                                ),
                                                Text(
                                                  'Communication Style: ${_parsedFeedbackData['communicationStyle']}',
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          // Message icon when no feedback
                          if (feedback == null && !loading)
                            Expanded(
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.message_outlined,
                                      size: 48,
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.3),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Your analysis will appear here',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withOpacity(0.5),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
