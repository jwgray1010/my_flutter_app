import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/advanced_components.dart';

class CoParentingCoachScreen extends StatefulWidget {
  final String userAttachmentStyle;
  final String userCommunicationStyle;

  const CoParentingCoachScreen({
    super.key,
    required this.userAttachmentStyle,
    required this.userCommunicationStyle,
  });

  @override
  State<CoParentingCoachScreen> createState() => _CoParentingCoachScreenState();
}

class _CoParentingCoachScreenState extends State<CoParentingCoachScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final bool _isAnalyzing = false;
  final String _currentTone = 'neutral';
  final double _toneConfidence = 0.0;
  final List<String> _realTimeSuggestions = [];
  dynamic _liveAnalysis;
  bool _coachVisible = false;
  late AnimationController _coachController;
  late Animation<Offset> _coachSlideAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final String _coachMessage = '';
  final String _coachEmotion = 'neutral';

  @override
  void initState() {
    super.initState();
    _coachController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _coachSlideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _coachController,
      curve: Curves.easeOut,
    ));

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: 0.95,
      upperBound: 1.05,
    )..repeat(reverse: true);
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _coachController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Communication Coach'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Real-time tone indicator
                _buildToneIndicator(theme),
                const SizedBox(height: AppTheme.spaceLG),

                // Message input with live analysis
                _buildLiveMessageInput(theme),
                const SizedBox(height: AppTheme.spaceLG),

                // Real-time suggestions
                if (_realTimeSuggestions.isNotEmpty) ...[
                  _buildRealTimeSuggestions(theme),
                  const SizedBox(height: AppTheme.spaceLG),
                ],

                // Live analysis details
                if (_liveAnalysis != null) _buildLiveAnalysisDetails(theme),
              ],
            ),
          ),

          // AI Coach overlay
          if (_coachVisible) _buildCoachOverlay(theme),
        ],
      ),
    );
  }

  Widget _buildToneIndicator(ThemeData theme) {
    return PremiumCard(
      child: Row(
        children: [
          // Animated pulse indicator
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isAnalyzing ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _getToneColor().withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: _getToneColor(), width: 2),
                  ),
                  child: Icon(_getToneIcon(), color: _getToneColor(), size: 28, semanticLabel: 'Tone'),
                ),
              );
            },
          ),

          const SizedBox(width: AppTheme.spaceLG),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Color dot for tone
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: _getToneColor(),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      _isAnalyzing ? 'Analyzing...' : 'Current Tone',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceXS),
                Text(
                  _isAnalyzing ? 'Processing' : _currentTone.toUpperCase(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getToneColor(),
                  ),
                ),
                if (_toneConfidence > 0) ...[
                  const SizedBox(height: AppTheme.spaceXS),
                  LinearProgressIndicator(
                    value: _toneConfidence,
                    backgroundColor: theme.colorScheme.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(_getToneColor()),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveMessageInput(ThemeData theme) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Compose Message',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMD),

          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              border: Border.all(
                color: _isAnalyzing
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
                width: _isAnalyzing ? 2 : 1,
              ),
            ),
            child: TextField(
              controller: _messageController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Start typing to get real-time feedback...',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(AppTheme.spaceLG),
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
          ),

          if (_isAnalyzing) ...[
            const SizedBox(height: AppTheme.spaceSM),
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceXS),
                Text(
                  'Analyzing tone and clarity...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRealTimeSuggestions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Live Suggestions',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMD),

        ..._realTimeSuggestions.map(
          (suggestion) => Container(
            margin: const EdgeInsets.only(bottom: AppTheme.spaceSM),
            padding: const EdgeInsets.all(AppTheme.spaceMD),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Text(suggestion, style: theme.textTheme.bodyMedium),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveAnalysisDetails(ThemeData theme) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Live Analysis',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMD),

          // Emotional indicators
          Wrap(
            spacing: AppTheme.spaceSM,
            runSpacing: AppTheme.spaceSM,
            children: [
              _buildEmotionChip(theme, 'Clarity', _toneConfidence, Colors.blue),
              _buildEmotionChip(theme, 'Positivity', 0.7, Colors.green),
              _buildEmotionChip(theme, 'Empathy', 0.6, Colors.purple),
              // Communication style chip
              _buildCommStyleChip(theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionChip(
    ThemeData theme,
    String label,
    double value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMD,
        vertical: AppTheme.spaceXS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppTheme.spaceXS),
          Text(
            '${(value * 100).round()}%',
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommStyleChip(ThemeData theme) {
    final color = _getCommStyleColor();
    final label = _getCommStyleLabel();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMD,
        vertical: AppTheme.spaceXS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble, color: color, size: 16, semanticLabel: 'Communication Style'),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachOverlay(ThemeData theme) {
    return Positioned(
      right: AppTheme.spaceLG,
      bottom: AppTheme.spaceLG,
      child: SlideTransition(
        position: _coachSlideAnimation,
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(AppTheme.spaceLG),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            boxShadow: AppTheme.primaryShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_getCoachIcon(), color: Colors.white, size: 20, semanticLabel: 'Coach'),
                  ),
                  const SizedBox(width: AppTheme.spaceMD),
                  Expanded(
                    child: Text(
                      'AI Coach',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _coachVisible = false;
                      });
                      _coachController.reverse();
                    },
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                      semanticLabel: 'Close',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceMD),
              Text(
                _coachMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getToneColor() {
    switch (_currentTone) {
      case 'happy':
      case 'excited':
        return Colors.green;
      case 'frustrated':
      case 'angry':
        return Colors.red;
      case 'sad':
      case 'disappointed':
        return Colors.blue;
      case 'anxious':
      case 'worried':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getToneIcon() {
    switch (_currentTone) {
      case 'happy':
        return Icons.sentiment_very_satisfied;
      case 'excited':
        return Icons.star;
      case 'frustrated':
        return Icons.sentiment_dissatisfied;
      case 'angry':
        return Icons.warning;
      case 'sad':
        return Icons.sentiment_very_dissatisfied;
      case 'anxious':
        return Icons.psychology;
      default:
        return Icons.sentiment_neutral;
    }
  }

  IconData _getCoachIcon() {
    switch (_coachEmotion) {
      case 'concerned':
        return Icons.psychology;
      case 'empathetic':
        return Icons.favorite;
      case 'pleased':
        return Icons.thumb_up;
      default:
        return Icons.lightbulb;
    }
  }

  Color _getCommStyleColor() {
    switch (widget.userCommunicationStyle.toLowerCase()) {
      case 'assertive':
        return Colors.green;
      case 'passive':
        return Colors.blue;
      case 'aggressive':
        return Colors.red;
      case 'passive-aggressive':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getCommStyleLabel() {
    switch (widget.userCommunicationStyle.toLowerCase()) {
      case 'assertive':
        return 'Assertive';
      case 'passive':
        return 'Passive';
      case 'aggressive':
        return 'Aggressive';
      case 'passive-aggressive':
        return 'Passive-Aggressive';
      default:
        return widget.userCommunicationStyle;
    }
  }
}

class RealTimeCommunicationCoach extends StatelessWidget {
  final String userAttachmentStyle;
  final String userCommunicationStyle;

  const RealTimeCommunicationCoach({
    super.key,
    required this.userAttachmentStyle,
    required this.userCommunicationStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Real-Time Communication Coach')),
      body: Center(
        child: Text(
          'Real-Time Communication Coach\nAttachment: '
          '[1m$userAttachmentStyle\n[0mCommunication: $userCommunicationStyle',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
