import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum ToneStatus {
  clear, // Green - good tone
  caution, // Yellow - moderate concern
  alert, // Red - problematic tone
  neutral, // Default gray
}

class ToneIndicator extends StatefulWidget {
  final ToneStatus status;
  final double size;
  final VoidCallback? onTap;
  final String? tooltipMessage;
  final bool showPulse;

  const ToneIndicator({
    super.key,
    this.status = ToneStatus.neutral,
    this.size = 24.0,
    this.onTap,
    this.tooltipMessage,
    this.showPulse = false,
  });

  @override
  State<ToneIndicator> createState() => _ToneIndicatorState();
}

class _ToneIndicatorState extends State<ToneIndicator>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _colorTransitionController;
  late Animation<Color?> _colorAnimation;

  Color _previousColor = Colors.grey;

  @override
  void initState() {
    super.initState();

    // Pulse animation for alerts
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Color transition animation
    _colorTransitionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Initialize with current color
    final currentColor = _getColorForStatus(widget.status);
    _previousColor = currentColor;
    _colorAnimation = ColorTween(
      begin: currentColor,
      end: currentColor,
    ).animate(_colorTransitionController);

    if (widget.showPulse && widget.status == ToneStatus.alert) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ToneIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newColor = _getColorForStatus(widget.status);
    if (newColor != _previousColor) {
      _updateColorAnimation(newColor);
      _colorTransitionController.forward();
    }

    // Handle pulse animation
    if (widget.showPulse && widget.status == ToneStatus.alert) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  void _updateColorAnimation(Color newColor) {
    _colorAnimation = ColorTween(begin: _previousColor, end: newColor).animate(
      CurvedAnimation(
        parent: _colorTransitionController,
        curve: Curves.easeInOut,
      ),
    );
    _previousColor = newColor;
    _colorTransitionController.reset();
  }

  Color _getColorForStatus(ToneStatus status) {
    switch (status) {
      case ToneStatus.clear:
        return const Color(0xFF00E676); // Bright Green
      case ToneStatus.caution:
        return const Color(0xFFFFD600); // Bright Yellow
      case ToneStatus.alert:
        return const Color(0xFFFF1744); // Bright Red
      case ToneStatus.neutral:
        return const Color(0xFF757575); // Darker Gray
    }
  }

  String _getTooltipForStatus(ToneStatus status) {
    if (widget.tooltipMessage != null) {
      return widget.tooltipMessage!;
    }

    switch (status) {
      case ToneStatus.clear:
        return 'Tone is positive and clear';
      case ToneStatus.caution:
        return 'Tone may need adjustment';
      case ToneStatus.alert:
        return 'Tone appears problematic';
      case ToneStatus.neutral:
        return 'Tone analysis';
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _colorTransitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = _getColorForStatus(widget.status);

    return Tooltip(
      message: _getTooltipForStatus(widget.status),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulseAnimation, _colorAnimation]),
          builder: (context, child) {
            final scale = widget.showPulse && widget.status == ToneStatus.alert
                ? _pulseAnimation.value
                : 1.0;

            return Transform.scale(
              scale: scale,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: currentColor, width: 4.0),
                  boxShadow: [
                    BoxShadow(
                      color: currentColor.withOpacity(0.6),
                      blurRadius: 12,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: SvgPicture.asset(
                    'assets/logo_icon.svg',
                    width: widget.size - 12,
                    height: widget.size - 12,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Helper class for tone analysis results
class ToneAnalysisResult {
  final String dominantTone;
  final double confidence;
  final Map<String, double> toneScores;
  final String message;

  const ToneAnalysisResult({
    required this.dominantTone,
    required this.confidence,
    required this.toneScores,
    required this.message,
  });

  ToneStatus get status {
    // Determine status based on tone analysis
    if (confidence < 0.3) return ToneStatus.neutral;

    // Check for problematic tones (high confidence)
    if (confidence > 0.7) {
      final problematicTones = ['aggressive', 'angry', 'rude', 'hostile'];
      if (problematicTones.contains(dominantTone.toLowerCase())) {
        return ToneStatus.alert;
      }
    }

    // Check for cautionary tones (moderate confidence)
    if (confidence > 0.5) {
      final cautiousTones = ['direct', 'stern', 'impatient', 'critical'];
      if (cautiousTones.contains(dominantTone.toLowerCase())) {
        return ToneStatus.caution;
      }
    }

    // Positive tones
    final positiveTones = [
      'gentle',
      'friendly',
      'supportive',
      'kind',
      'balanced',
    ];
    if (positiveTones.contains(dominantTone.toLowerCase()) &&
        confidence > 0.4) {
      return ToneStatus.clear;
    }

    return ToneStatus.neutral;
  }

  factory ToneAnalysisResult.fromJson(Map<String, dynamic> json) {
    return ToneAnalysisResult(
      dominantTone: json['dominant_tone'] ?? 'neutral',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      toneScores: Map<String, double>.from(json['tone_scores'] ?? {}),
      message: json['message'] ?? '',
    );
  }
}
