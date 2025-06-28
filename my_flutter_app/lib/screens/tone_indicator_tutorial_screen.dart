import 'package:flutter/material.dart';
import '../widgets/tone_indicator.dart';

class ToneIndicatorTutorialScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const ToneIndicatorTutorialScreen({super.key, this.onComplete});

  @override
  State<ToneIndicatorTutorialScreen> createState() =>
      _ToneIndicatorTutorialScreenState();
}

class _ToneIndicatorTutorialScreenState
    extends State<ToneIndicatorTutorialScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _typingController;
  late AnimationController _pulseController;

  // Tutorial content for each page
  final List<TutorialPage> _pages = [
    TutorialPage(
      title: "Meet Your Tone Assistant",
      subtitle: "The Unsaid logo helps you communicate better",
      description:
          "Our smart tone indicator appears when you're typing messages, giving you real-time feedback about how your words might be perceived.",
      messageExample: "",
      toneStatus: ToneStatus.neutral,
      showPhone: false,
    ),
    TutorialPage(
      title: "Green Means Go!",
      subtitle: "Your message sounds positive and friendly",
      description:
          "When the logo is green, your message has a warm, supportive tone that's likely to be well-received.",
      messageExample:
          "Thanks so much for your help! I really appreciate you taking the time to explain this to me.",
      toneStatus: ToneStatus.clear,
      showPhone: true,
    ),
    TutorialPage(
      title: "Yellow Says Caution",
      subtitle: "Your message might come across as direct",
      description:
          "Yellow indicates your message could be perceived as urgent or demanding. Consider softening your approach.",
      messageExample:
          "You need to fix this issue immediately. It should have been done yesterday.",
      toneStatus: ToneStatus.caution,
      showPhone: true,
    ),
    TutorialPage(
      title: "Red Means Stop & Think",
      subtitle: "Your message might sound harsh or aggressive",
      description:
          "When the logo turns red and pulses, it's warning you that your message could hurt someone's feelings or damage your relationship.",
      messageExample:
          "This is completely ridiculous! How could you make such a stupid mistake?",
      toneStatus: ToneStatus.alert,
      showPhone: true,
    ),
    TutorialPage(
      title: "You're All Set!",
      subtitle: "Start typing with confidence",
      description:
          "The tone indicator will appear in your keyboard and messaging apps, helping you communicate more effectively in all your conversations.",
      messageExample: "",
      toneStatus: ToneStatus.neutral,
      showPhone: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _typingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onComplete?.call();
    }
  }

  void _skipTutorial() {
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with skip button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo
                  Image.asset('assets/logo_icon.png', width: 32, height: 32),
                  // Skip button
                  TextButton(
                    onPressed: _skipTutorial,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });

                  // Start animations for pages with examples
                  if (_pages[index].showPhone &&
                      _pages[index].messageExample.isNotEmpty) {
                    _typingController.reset();
                    _typingController.forward();

                    if (_pages[index].toneStatus == ToneStatus.alert) {
                      _pulseController.repeat(reverse: true);
                    } else {
                      _pulseController.stop();
                    }
                  } else {
                    _pulseController.stop();
                  }
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildTutorialPage(_pages[index]);
                },
              ),
            ),

            // Page indicators and navigation
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: index == _currentPage ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: index == _currentPage
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Next/Complete button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? 'Get Started'
                            : 'Next',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  Widget _buildTutorialPage(TutorialPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 10), // Minimal top spacing
          // Title and subtitle
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 4), // Minimal spacing

          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
          ),

          const SizedBox(height: 16), // Minimal spacing
          // Main content area
          Expanded(
            child: page.showPhone
                ? _buildPhoneExample(page)
                : _buildIntroContent(page),
          ),

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8), // Minimal padding
            child: Text(
              page.description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroContent(TutorialPage page) {
    if (_currentPage == 0) {
      // First page - show all tone states and a legend/info card
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildToneExample(ToneStatus.clear, 'Good', semanticLabel: 'Clear tone'),
              _buildToneExample(ToneStatus.caution, 'Caution', semanticLabel: 'Caution tone'),
              _buildToneExample(ToneStatus.alert, 'Alert', semanticLabel: 'Alert tone'),
            ],
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.psychology, size: 48, color: Colors.blue.shade600),
                const SizedBox(height: 16),
                Text(
                  'Smart Tone Detection',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Our AI analyzes your words in real-time to help you communicate more effectively',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.blue.shade700),
                ),
                const SizedBox(height: 16),
                // Legend/info card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendRow(ToneStatus.clear, 'Green: Positive, friendly tone', 'Clear tone'),
                      _buildLegendRow(ToneStatus.caution, 'Yellow: Direct or urgent tone', 'Caution tone'),
                      _buildLegendRow(ToneStatus.alert, 'Red: Potentially harsh tone (with pulse)', 'Alert tone'),
                      _buildLegendRow(ToneStatus.neutral, 'Gray: Neutral tone', 'Neutral tone'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      // Last page - completion
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 80,
              color: Colors.green.shade500,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Tutorial Complete!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildLegendRow(ToneStatus status, String text, String semanticLabel) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          ToneIndicator(
            status: status,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildToneExample(ToneStatus status, String label, {String? semanticLabel}) {
    return Column(
      children: [
        ToneIndicator(
          status: status,
          size: 48,
          showPulse: status == ToneStatus.alert,
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildPhoneExample(TutorialPage page) {
    return Center(
      child: SizedBox(
        width: 300,
        height: 580,
        child: Stack(
          children: [
            // iPhone mockup
            Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  children: [
                    // Status bar
                    Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '9:41',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(Icons.signal_cellular_4_bar, size: 16),
                              const SizedBox(width: 4),
                              Icon(Icons.wifi, size: 16),
                              const SizedBox(width: 4),
                              Icon(Icons.battery_full, size: 16),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // App header
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.blue.shade100,
                            child: Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Sarah',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Messages area
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            // Received message
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(
                                  bottom: 16,
                                  right: 40,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  'Hey! How\'s the project coming along?',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ),

                            const Spacer(),

                            // Typing indicator
                            if (page.messageExample.isNotEmpty)
                              _buildTypingMessage(page),
                          ],
                        ),
                      ),
                    ),

                    // Keyboard area with tone indicator
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Message input area
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Tone indicator
                                AnimatedBuilder(
                                  animation: _pulseController,
                                  builder: (context, child) {
                                    final scale =
                                        page.toneStatus == ToneStatus.alert
                                            ? 1.0 + (_pulseController.value * 0.2)
                                            : 1.0;
                                    return Transform.scale(
                                      scale: scale,
                                      child: ToneIndicator(
                                        status: page.toneStatus,
                                        size: 28,
                                      ),
                                    );
                                  },
                                ),

                                const SizedBox(width: 12),

                                // Text input
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: _buildAnimatedText(
                                      page.messageExample,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Simplified keyboard
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildKey('Q'),
                                  _buildKey('W'),
                                  _buildKey('E'),
                                  _buildKey('R'),
                                  _buildKey('T'),
                                  _buildKey('Y'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKey(String letter) {
    return Container(
      width: 28,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildTypingMessage(TutorialPage page) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 16, left: 40),
        decoration: BoxDecoration(
          color: Colors.blue.shade500,
          borderRadius: BorderRadius.circular(16),
        ),
        child: _buildAnimatedText(page.messageExample, isOutgoing: true),
      ),
    );
  }

  Widget _buildAnimatedText(String text, {bool isOutgoing = false}) {
    return AnimatedBuilder(
      animation: _typingController,
      builder: (context, child) {
        final progress = _typingController.value;
        final visibleLength = (text.length * progress).round();
        final visibleText = text.substring(0, visibleLength);

        return Text(
          visibleText +
              (progress < 1.0 && visibleLength < text.length ? '|' : ''),
          style: TextStyle(
            fontSize: 14,
            color: isOutgoing ? Colors.white : Colors.black,
          ),
        );
      },
    );
  }

  String _getToneSemanticLabel(ToneStatus status) {
    switch (status) {
      case ToneStatus.clear:
        return 'Clear tone';
      case ToneStatus.caution:
        return 'Caution tone';
      case ToneStatus.alert:
        return 'Alert tone';
      case ToneStatus.neutral:
      default:
        return 'Neutral tone';
    }
  }
}

class TutorialPage {
  final String title;
  final String subtitle;
  final String description;
  final String messageExample;
  final ToneStatus toneStatus;
  final bool showPhone;

  TutorialPage({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.messageExample,
    required this.toneStatus,
    required this.showPhone,
  });
}
