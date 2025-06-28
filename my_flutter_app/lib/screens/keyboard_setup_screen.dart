import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/keyboard_manager.dart';
import '../widgets/tone_indicator.dart';

class KeyboardSetupScreen extends StatefulWidget {
  const KeyboardSetupScreen({super.key});

  @override
  State<KeyboardSetupScreen> createState() => _KeyboardSetupScreenState();
}

class _KeyboardSetupScreenState extends State<KeyboardSetupScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final KeyboardManager _keyboardManager = KeyboardManager();
  bool _isLoading = false;
  int _currentStep = 0;
  bool _faqExpanded = false;

  // Place these at the top of your widget class (not inside the build method)
  String _selectedContext = 'General';
  String? _aiSuggestion;
  String? _detectedTone;
  final TextEditingController _previewTextController = TextEditingController(
    text: 'I appreciate your help!',
  );

  final List<String> _setupSteps = [
    'Enable Keyboard',
    'Grant Permissions',
    'Configure Settings',
    'Test Keyboard',
  ];

  // Add these fields to your State class:
  bool _adaptiveLearning = true;
  String _selectedLanguage = 'English';
  final List<String> _languageOptions = ['English', 'Spanish', 'French'];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeKeyboard();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    final fadeCurve = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(fadeCurve);

    final slideCurve = CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(slideCurve);

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  Future<void> _initializeKeyboard() async {
    setState(() => _isLoading = true);

    await _keyboardManager.initialize();

    // Determine current step based on keyboard status
    if (_keyboardManager.isKeyboardEnabled) {
      _currentStep = 3; // Already set up
    } else if (_keyboardManager.isKeyboardInstalled) {
      _currentStep = 1; // Need permissions
    } else {
      _currentStep = 0; // Need installation
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _handleInstallKeyboard() async {
    setState(() => _isLoading = true);

    HapticFeedback.mediumImpact();

    try {
      final success = await _keyboardManager.installKeyboard();
      if (success) {
        setState(() => _currentStep = 3);
        _showSuccessMessage('Keyboard installed successfully!');
      } else {
        _showErrorMessage('Please enable the Unsaid keyboard in Settings');
      }
    } catch (e) {
      _showErrorMessage('Failed to install keyboard: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _handleOpenSettings() async {
    HapticFeedback.lightImpact();
    _keyboardManager.openKeyboardSettings();

    // Give user time to enable keyboard
    Future.delayed(const Duration(seconds: 2), () {
      _keyboardManager.refreshStatus();
    });
  }

  Future<void> _handleTestKeyboard() async {
    setState(() => _isLoading = true);

    try {
      final testText = await _keyboardManager.processText('Hello world!');
      // Adaptive learning: update user style from the test message
      await _keyboardManager.adaptUserStyleFromMessage('Hello world!');
      _showSuccessMessage('Keyboard test successful: $testText');
    } catch (e) {
      _showErrorMessage('Keyboard test failed: $e');
    }

    setState(() => _isLoading = false);
  }

  // Move all helper methods above build()
  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildInstallStep();
      case 1:
        return _buildPermissionStep();
      case 2:
        return _buildConfigurationStep();
      case 3:
        return _buildTestStep();
      default:
        return _buildInstallStep();
    }
  }

  Widget _buildInstallStep() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.keyboard, size: 64, color: Colors.white),
          const SizedBox(height: 24),
          Text(
            'Install Unsaid Keyboard',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Enable the Unsaid keyboard to get real-time tone analysis and smart suggestions while you type.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildFeatureList(),
          const SizedBox(height: 24),
          _buildMobileInstructions(context),
        ],
      ),
    );
  }

  Widget _buildPermissionStep() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.security, size: 64, color: Colors.white),
          const SizedBox(height: 24),
          Text(
            'Grant Permissions',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Open Settings and enable "Unsaid Keyboard" under Keyboards. This allows the app to provide tone analysis.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationStep() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.tune, size: 64, color: Colors.white),
          const SizedBox(height: 24),
          Text(
            'Configure Settings',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Customize your keyboard experience with tone detection, smart suggestions, and more.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // --- New configuration options ---
          SwitchListTile(
            value: _adaptiveLearning,
            onChanged: (val) => setState(() => _adaptiveLearning = val),
            title: Text('Adaptive Learning'),
            subtitle: Text('Let Unsaid adapt to your style over time.'),
            activeColor: Theme.of(context).primaryColor,
            inactiveTrackColor: Colors.white30,
            activeTrackColor: Colors.white54,
          ),
        ],
      ),
    );
  }

  Widget _buildTestStep() {
    final List<String> contextOptions = [
      'General',
      'Work',
      'Family',
      'Friend',
      'Partner',
    ];

    Color toneToColor(String? tone) {
      switch (tone?.toLowerCase()) {
        case 'positive':
          return Colors.greenAccent;
        case 'neutral':
        case 'balanced':
          return Colors.blueAccent;
        case 'negative':
          return Colors.redAccent;
        case 'gentle':
          return Colors.purpleAccent;
        case 'direct':
          return Colors.orangeAccent;
        default:
          return Colors.grey;
      }
    }

    String toneLabel(String? tone) {
      if (tone == null) return 'Unknown';
      return tone[0].toUpperCase() + tone.substring(1);
    }

    // --- New state for advanced features ---
    int? empathyScore;
    List<String>? microCoachingTips;
    String? mediationSuggestion;
    List<String>? triggerWords;
    String? perspectiveSwitch;
    String? childRephrase;
    List<Map<String, dynamic>>? toneHistory;
    int? suggestionRating;
    Map<String, dynamic>? toneAnalysis;

    Future<void> analyzeMessage() async {
      final text = _previewTextController.text;
      final context = _selectedContext;
      final analysis = await _keyboardManager.analyzeTone(
        text,
        relationshipContext: context,
        // adaptiveLearning: _adaptiveLearning, // Removed invalid parameter
      );
      final empathy = _keyboardManager.empathyScore(text);
      final tips = _keyboardManager.microCoachingTips(text, context: context);
      final mediation = _keyboardManager.mediateMessage(text);
      final triggers = _keyboardManager.detectTriggerWords(text);
      final perspective = _keyboardManager.perspectiveSwitch(text);
      final child = _keyboardManager.childCenteredRephrase(text);
      final history = _keyboardManager.toneHistory.reversed.take(5).toList();
      setState(() {
        toneAnalysis = analysis;
        _detectedTone = analysis['dominant_tone'];
        empathyScore = empathy;
        microCoachingTips = tips;
        mediationSuggestion = mediation != text ? mediation : null;
        triggerWords = triggers;
        perspectiveSwitch = perspective;
        childRephrase = child;
        toneHistory = history;
      });
    }

    Future<void> getAISuggestion() async {
      setState(() => _isLoading = true);
      final suggestion = await _keyboardManager.getGptSuggestion(
        _previewTextController.text,
        relationshipContext: _selectedContext,
      );
      setState(() {
        _aiSuggestion = suggestion;
        _isLoading = false;
      });
    }

    // Map your detected tone to ToneStatus
    ToneStatus getToneStatus(String? tone) {
      switch (tone?.toLowerCase()) {
        case 'positive':
        case 'gentle':
        case 'supportive':
        case 'child-centered':
          return ToneStatus.clear;
        case 'direct':
        case 'caution':
          return ToneStatus.caution;
        case 'negative':
        case 'conflict':
        case 'alert':
          return ToneStatus.alert;
        case 'neutral':
        case 'balanced':
        default:
          return ToneStatus.neutral;
      }
    }

    // --- UI ---
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 36, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Keyboard Ready!',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(color: Colors.white24),
            Text(
              'Test the advanced features:',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            // Context dropdown
            Row(
              children: [
                Icon(Icons.settings_suggest, color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                Text('Context:', style: TextStyle(color: Colors.white70)),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedContext,
                    dropdownColor: Colors.black87,
                    style: TextStyle(color: Colors.white),
                    iconEnabledColor: Colors.white,
                    items: contextOptions
                        .map<DropdownMenuItem<String>>(
                          (c) => DropdownMenuItem<String>(
                            value: c,
                            child: Text(
                              c,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedContext = val ?? contextOptions[0];
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              color: Colors.white.withOpacity(0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit, color: Colors.white70, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Try a message:',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _previewTextController,
                      decoration: InputDecoration(
                        labelText:
                            'Type here... (e.g. "I appreciate your help!")',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        labelStyle: TextStyle(color: Colors.white54),
                      ),
                      style: TextStyle(color: Colors.white),
                      minLines: 1,
                      maxLines: 3,
                      onChanged: (_) => analyzeMessage(),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Tooltip(
                          message: 'Get an AI-powered suggestion',
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : getAISuggestion,
                            icon: Icon(Icons.auto_fix_high),
                            label: Text('AI Suggestion'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: 'Rewrite from other parent’s view',
                          child: ElevatedButton.icon(
                            onPressed: perspectiveSwitch == null
                                ? null
                                : () {
                                    _previewTextController.text =
                                        perspectiveSwitch!;
                                    analyzeMessage();
                                  },
                            icon: Icon(Icons.switch_account),
                            label: Text('Switch Perspective'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: 'Make message child-centered',
                          child: ElevatedButton.icon(
                            onPressed: childRephrase == null
                                ? null
                                : () {
                                    _previewTextController.text =
                                        childRephrase!;
                                    analyzeMessage();
                                  },
                            icon: Icon(Icons.child_care),
                            label: Text('Child-Centered'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_detectedTone != null)
              Card(
                color: Colors.white.withOpacity(0.10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.emoji_objects,
                            color: toneToColor(_detectedTone),
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tone:',
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: toneToColor(
                                _detectedTone,
                              ).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              toneLabel(_detectedTone),
                              style: TextStyle(
                                color: toneToColor(_detectedTone),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (empathyScore != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Empathy Meter',
                          style: TextStyle(color: Colors.white70),
                        ),
                        Container(
                          height: 16,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              colors: [
                                Colors.redAccent,
                                Colors.blueAccent,
                                Colors.greenAccent,
                              ],
                              stops: [0.0, 0.5, 1.0],
                            ),
                          ),
                          child: Stack(
                            children: [
                              FractionallySizedBox(
                                widthFactor: (empathyScore! / 100.0).clamp(
                                  0.0,
                                  1.0,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              Center(
                                child: Text(
                                  '$empathyScore / 100',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
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
            if (triggerWords != null && triggerWords!.isNotEmpty)
              Card(
                color: Colors.redAccent.withOpacity(0.12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Trigger/conflict words detected: ${triggerWords!.join(", ")}',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Tooltip(
                        message:
                            'These words may escalate conflict or cause distress.',
                        child: Icon(
                          Icons.info_outline,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (microCoachingTips != null && microCoachingTips!.isNotEmpty)
              Card(
                color: Colors.blueAccent.withOpacity(0.10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.psychology,
                            color: Colors.blueAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Micro-Coaching Tips:',
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      ...microCoachingTips!.map(
                        (tip) => Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '• $tip',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (mediationSuggestion != null)
              Card(
                color: Colors.purple.withOpacity(0.10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.handshake, color: Colors.purple, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Mediation Suggestion:',
                            style: TextStyle(
                              color: Colors.purple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mediationSuggestion!,
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            if (_aiSuggestion != null)
              Card(
                color: Colors.teal.withOpacity(0.10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.smart_toy, color: Colors.teal, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'AI Suggestion:',
                            style: TextStyle(
                              color: Colors.teal,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _aiSuggestion!,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Rate this suggestion:',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Row(
                        children: List.generate(
                          5,
                          (i) => IconButton(
                            icon: Icon(
                              suggestionRating != null && suggestionRating! > i
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                            ),
                            onPressed: () {
                              setState(() {
                                suggestionRating = i + 1;
                              });
                              _keyboardManager.addSuggestionFeedback(
                                _previewTextController.text,
                                _aiSuggestion!,
                                i + 1,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (toneHistory != null && toneHistory!.isNotEmpty)
              Card(
                color: Colors.white.withOpacity(0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.history, color: Colors.white70, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Recent Tone/Emotion History:',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      ...toneHistory!.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '${entry['timestamp']?.substring(0, 19) ?? ''}: ${entry['dominant_tone'] ?? ''} (${entry['emotion'] ?? ''})',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Proactive coaching card
            if (getToneStatus(_detectedTone) == ToneStatus.alert)
              Card(
                color: Colors.redAccent.withOpacity(0.15),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(
                    Icons.pause_circle_filled,
                    color: Colors.redAccent,
                  ),
                  title: Text(
                    'Pause and reflect',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'This message may escalate conflict. Consider rephrasing.',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.close, color: Colors.redAccent),
                    onPressed: () => setState(() {
                      /* dismiss card logic */
                    }),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureList() {
    final features = [
      'Real-time tone analysis',
      'Smart message suggestions',
      'Emotional context awareness',
      'Privacy-focused design',
    ];

    return Column(
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  feature,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMobileInstructions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How to Enable the Unsaid Keyboard',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Text(
          'iOS:\n1. Go to Settings > General > Keyboard > Keyboards > Add New Keyboard...\n2. Select "Unsaid Keyboard".\n3. Allow Full Access for advanced features.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Text(
          'Android:\n1. Go to Settings > System > Languages & input > On-screen keyboard > Manage keyboards.\n2. Enable "Unsaid Keyboard".',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    String buttonText;
    VoidCallback? onPressed;

    switch (_currentStep) {
      case 0:
        buttonText = _isLoading ? 'Installing...' : 'Install Keyboard';
        onPressed = _isLoading ? null : _handleInstallKeyboard;
        break;
      case 1:
        buttonText = 'Open Settings';
        onPressed = _handleOpenSettings;
        break;
      case 2:
        buttonText = 'Configure Now';
        onPressed = () => Navigator.pushNamed(context, '/keyboard_settings');
        break;
      case 3:
        buttonText = _isLoading ? 'Testing...' : 'Test Keyboard';
        onPressed = _isLoading ? null : _handleTestKeyboard;
        break;
      default:
        buttonText = 'Continue';
        onPressed = () {};
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Theme.of(context).primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    buttonText,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : Text(
                buttonText,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildRefreshButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: OutlinedButton.icon(
        onPressed: _isLoading
            ? null
            : () async {
                HapticFeedback.selectionClick();
                setState(() => _isLoading = true);
                await _keyboardManager.refreshStatus();
                await _initializeKeyboard();
                setState(() => _isLoading = false);
              },
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh Status'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white70),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildFaqSection() {
    final faqs = [
      {
        'q': 'The keyboard does not appear after enabling. What should I do?',
        'a':
            'Try restarting your device. On iOS, ensure "Allow Full Access" is enabled. On Android, check that the keyboard is selected as the input method.',
      },
      {
        'q': 'Is my data private?',
        'a':
            'Yes. The Unsaid keyboard is privacy-focused and does not store or transmit your keystrokes except for tone analysis (if enabled).',
      },
      {
        'q': 'How do I switch keyboards?',
        'a':
            'On iOS, tap the globe icon. On Android, tap the keyboard icon in the navigation bar.',
      },
    ];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              'FAQ & Troubleshooting',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                _faqExpanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.white,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() => _faqExpanded = !_faqExpanded);
              },
            ),
          ),
          if (_faqExpanded)
            ...faqs.map(
              (faq) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Q: ${faq['q']}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'A: ${faq['a']}',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const Divider(color: Colors.white24),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            animation: Listenable.merge([_fadeController, _slideController]),
            builder: (context, child) {
              return Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/home',
                            (route) => false,
                          ),
                          child: Container(
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
                        const SizedBox(width: 16),
                        Expanded(
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Text(
                              'Keyboard Setup',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48), // Balance the logo
                      ],
                    ),
                  ),

                  // Progress Indicator
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: _setupSteps.asMap().entries.map((entry) {
                          final index = entry.key;
                          final isActive = index <= _currentStep;
                          final isCurrent = index == _currentStep;

                          return Expanded(
                            child: Container(
                              height: 4,
                              margin: EdgeInsets.only(
                                right: index < _setupSteps.length - 1 ? 8 : 0,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: isCurrent
                                    ? [
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.5),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Step Label
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'Step ${_currentStep + 1}: ${_setupSteps[_currentStep]}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Content
                  Expanded(
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildStepContent(),
                      ),
                    ),
                  ),

                  // Action Button
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            child: _buildActionButton(),
                          ),
                          _buildRefreshButton(),
                        ],
                      ),
                    ),
                  ),

                  // FAQ / Troubleshooting
                  _buildFaqSection(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
