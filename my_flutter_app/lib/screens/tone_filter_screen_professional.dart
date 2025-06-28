import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';

class ToneFilterScreenProfessional extends StatefulWidget {
  final String selectedTone;
  final ValueChanged<String>? onToneSelected;

  const ToneFilterScreenProfessional({
    super.key,
    this.selectedTone = 'Balanced',
    this.onToneSelected,
  });

  @override
  State<ToneFilterScreenProfessional> createState() =>
      _ToneFilterScreenProfessionalState();
}

class _ToneFilterScreenProfessionalState
    extends State<ToneFilterScreenProfessional> with TickerProviderStateMixin {
  late String _currentTone;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _tones = [
    {
      'label': 'Balanced',
      'description': 'Empathetic, clear, and constructive.',
      'icon': Icons.balance,
      'color': Colors.deepPurple,
    },
    {
      'label': 'Supportive',
      'description': 'Warm, validating, and encouraging.',
      'icon': Icons.volunteer_activism,
      'color': Colors.green,
    },
    {
      'label': 'Direct',
      'description': 'Clear, honest, and to the point.',
      'icon': Icons.bolt,
      'color': Colors.orange,
    },
    {
      'label': 'Gentle',
      'description': 'Soft, kind, and non-confrontational.',
      'icon': Icons.spa,
      'color': Colors.blue,
    },
    {
      'label': 'Curious',
      'description': 'Open, inquisitive, and non-judgmental.',
      'icon': Icons.psychology_alt,
      'color': Colors.teal,
    },
    {
      'label': 'Affirming',
      'description': 'Positive, appreciative, and validating.',
      'icon': Icons.thumb_up_alt,
      'color': Colors.purple,
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentTone = widget.selectedTone;
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _selectTone(String tone) {
    setState(() {
      _currentTone = tone;
    });
    if (widget.onToneSelected != null) {
      widget.onToneSelected!(tone);
    }
    Navigator.of(context).pop(tone);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Choose Tone Filter'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select the tone you want your messages to reflect. This helps tailor your communication for clarity, empathy, and effectiveness.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: AppTheme.spaceLG),
              Expanded(
                child: ListView.separated(
                  itemCount: _tones.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, i) {
                    final tone = _tones[i];
                    final isSelected = _currentTone == tone['label'];
                    return GestureDetector(
                      onTap: () => _selectTone(tone['label']),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(AppTheme.spaceLG),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? tone['color'].withOpacity(0.08)
                              : theme.colorScheme.surface,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLG),
                          border: Border.all(
                            color: isSelected
                                ? tone['color']
                                : theme.colorScheme.outline,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: tone['color'].withOpacity(0.12),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: tone['color'].withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                tone['icon'],
                                color: tone['color'],
                                size: 28,
                                semanticLabel: tone['label'],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tone['label'],
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? tone['color']
                                          : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    tone['description'],
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle,
                                  color: tone['color'],
                                  size: 28,
                                  semanticLabel: 'Selected'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppTheme.spaceLG),
              GradientButton(
                text: 'Use Selected Tone',
                icon: Icons.check,
                onPressed: () => _selectTone(_currentTone),
                gradient: AppTheme.primaryGradient,
              ),
            ],
          ),
        ),
      ),
    );
  }
}