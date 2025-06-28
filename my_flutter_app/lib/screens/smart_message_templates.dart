import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/advanced_components.dart';
import '../widgets/gradient_button.dart';

class SmartMessageTemplates extends StatefulWidget {
  const SmartMessageTemplates({super.key});

  @override
  State<SmartMessageTemplates> createState() => _SmartMessageTemplatesState();
}

class _SmartMessageTemplatesState extends State<SmartMessageTemplates>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _selectedCategory = 'All';
  String _selectedPersonality = 'Secure Communicator';
  String _relationshipContext = 'Dating';

  final List<String> _categories = [
    'All',
    'Apology',
    'Appreciation',
    'Conflict Resolution',
    'Check-in',
    'Planning',
    'Emotional Support',
    'Boundaries',
    'Intimacy',
  ];

  final List<String> _personalities = [
    'Anxious Connector',
    'Secure Communicator',
    'Avoidant Thinker',
    'Disorganized',
  ];

  final List<String> _contexts = [
    'Dating',
    'New Relationship',
    'Long-term',
    'Married',
    'Friends',
    'Family',
  ];

  // Smart templates with AI personalization
  final Map<String, List<Map<String, dynamic>>> _templates = {
    'Apology': [
      {
        'title': 'Sincere Apology',
        'template':
            "I realize I {action} and I want to sincerely apologize. I understand how that might have made you feel {emotion}. I'm committed to {improvement}. Can we talk about how to move forward?",
        'variables': ['action', 'emotion', 'improvement'],
        'personality_adaptations': {
          'Anxious Connector':
              'I\'ve been thinking about what happened and I feel terrible about {action}. I know I hurt you and I\'m so sorry. I really need you to know that {reassurance}. Please tell me how I can make this right?',
          'Secure Communicator':
              'I want to apologize for {action}. I can see how that affected you, and I take full responsibility. Let\'s discuss how I can do better and how we can prevent this in the future.',
          'Avoidant Thinker':
              'I realize {action} wasn\'t appropriate. I apologize for any confusion or hurt this may have caused. I\'d like to clarify my intentions and find a way to move forward constructively.',
          'Disorganized':
              'I\'m sorry about {action}. I know my behavior was confusing and I\'m working on understanding my own reactions better. Can you help me understand how this affected you?',
        },
        'context_adaptations': {
          'Dating': 'more cautious and exploratory',
          'New Relationship': 'building trust focused',
          'Long-term': 'maintenance and growth focused',
          'Married': 'deep commitment emphasized',
        },
      },
      {
        'title': 'Quick Acknowledgment',
        'template':
            "You're right about {situation}. I should have {better_action}. Thank you for bringing this up.",
        'variables': ['situation', 'better_action'],
        'personality_adaptations': {
          'Anxious Connector':
              'You\'re absolutely right and I feel awful about {situation}. I should have {better_action} and I promise I\'ll be more mindful. Are we okay?',
          'Secure Communicator':
              'I agree with your perspective on {situation}. I should have {better_action}. I appreciate you speaking up about this.',
          'Avoidant Thinker':
              'I understand your point about {situation}. You\'re correct that I should have {better_action}. I\'ll keep this in mind going forward.',
          'Disorganized':
              'I can see you\'re right about {situation}. I get confused sometimes about the right way to handle things, but I should have {better_action}.',
        },
      },
    ],
    'Appreciation': [
      {
        'title': 'Deep Gratitude',
        'template':
            "I wanted to take a moment to tell you how much I appreciate {specific_action}. It means so much to me because {personal_impact}. You have such a gift for {quality}.",
        'variables': ['specific_action', 'personal_impact', 'quality'],
        'personality_adaptations': {
          'Anxious Connector':
              'I\'ve been thinking about how amazing you are and I just had to tell you! When you {specific_action}, it made me feel so loved and secure. I\'m so grateful to have someone who {quality}.',
          'Secure Communicator':
              'I really appreciate {specific_action}. It shows your thoughtfulness and I don\'t want it to go unnoticed. Your {quality} is something I truly value about you.',
          'Avoidant Thinker':
              'I noticed {specific_action} and wanted to acknowledge it. It was helpful and showed good judgment. I respect your {quality}.',
          'Disorganized':
              'Thank you for {specific_action}. Sometimes I don\'t express it well, but things like this really matter to me. I\'m learning to appreciate your {quality} more and more.',
        },
      },
    ],
    'Conflict Resolution': [
      {
        'title': 'De-escalation',
        'template':
            "I can see we're both feeling {emotion} about this. Can we take a step back? I want to understand your perspective on {issue}. What matters most to you here?",
        'variables': ['emotion', 'issue'],
        'personality_adaptations': {
          'Anxious Connector':
              'I\'m feeling really {emotion} right now and I can see you are too. I\'m scared we\'re pulling apart and I want to fix this. Can you help me understand what you need from me about {issue}?',
          'Secure Communicator':
              'I notice we\'re both {emotion} about {issue}. Let\'s pause and make sure we\'re hearing each other. Can you share what\'s most important to you in this situation?',
          'Avoidant Thinker':
              'This conversation about {issue} seems to be causing some {emotion}. Perhaps we should approach this more systematically. What are the key points you\'d like me to understand?',
          'Disorganized':
              'I\'m feeling {emotion} and I can see you are too about {issue}. I\'m not always good at handling conflict, but I want to try. Can you help me understand what you need?',
        },
      },
    ],
    'Check-in': [
      {
        'title': 'Emotional Check-in',
        'template':
            "How are you feeling today? I've been thinking about {recent_event} and wanted to check in. Is there anything on your mind?",
        'variables': ['recent_event'],
        'personality_adaptations': {
          'Anxious Connector':
              'Hi love! I\'ve been thinking about you all day, especially after {recent_event}. How are you feeling? I just want to make sure you\'re okay and that we\'re good. I love you!',
          'Secure Communicator':
              'Hey, I wanted to check in about how you\'re doing, especially with {recent_event}. How are you processing everything? I\'m here if you want to talk.',
          'Avoidant Thinker':
              'I hope you\'re doing well today. I\'ve been considering {recent_event} and wanted to see how you\'re managing. Let me know if you need anything.',
          'Disorganized':
              'Hey, how are you? I keep thinking about {recent_event} and I\'m not sure how to ask, but are you okay? Sometimes I worry I\'m not supporting you the right way.',
        },
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Apology':
        return Colors.red;
      case 'Appreciation':
        return Colors.green;
      case 'Conflict Resolution':
        return Colors.orange;
      case 'Check-in':
        return Colors.blue;
      case 'Planning':
        return Colors.purple;
      case 'Emotional Support':
        return Colors.teal;
      case 'Boundaries':
        return Colors.deepPurple;
      case 'Intimacy':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Smart Message Templates'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Filters
            _buildFilters(theme),

            // Templates List
            Expanded(child: _buildTemplatesList(theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personalization settings
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: theme.colorScheme.primary, semanticLabel: 'AI Personalization'),
                    const SizedBox(width: AppTheme.spaceXS),
                    Text(
                      'AI Personalization',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceMD),

                // Personality selector
                Text(
                  'Your Communication Style:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXS),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _personalities.map((personality) {
                      final isSelected = _selectedPersonality == personality;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppTheme.spaceSM),
                        child: FilterChip(
                          label: Text(personality),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedPersonality = personality;
                            });
                          },
                          selectedColor: theme.colorScheme.primary.withOpacity(
                            0.2,
                          ),
                          checkmarkColor: theme.colorScheme.primary,
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: AppTheme.spaceMD),

                // Context selector
                Text(
                  'Relationship Context:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXS),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _contexts.map((context) {
                      final isSelected = _relationshipContext == context;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppTheme.spaceSM),
                        child: FilterChip(
                          label: Text(context),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _relationshipContext = context;
                            });
                          },
                          selectedColor: theme.colorScheme.secondary
                              .withOpacity(0.2),
                          checkmarkColor: theme.colorScheme.secondary,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spaceMD),

          // Category filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: AppTheme.spaceSM),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedCategory = category),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceLG,
                        vertical: AppTheme.spaceMD,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppTheme.primaryGradient : null,
                        color: isSelected ? null : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusFull,
                        ),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : theme.colorScheme.outline,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Color dot for category
                          if (category != 'All')
                            Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(category),
                                shape: BoxShape.circle,
                              ),
                            ),
                          Text(
                            category,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : theme.colorScheme.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatesList(ThemeData theme) {
    final templates = _getFilteredTemplates();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        final category = _getTemplateCategory(template);
        return _buildTemplateCard(theme, template, category);
      },
    );
  }

  String _getTemplateCategory(Map<String, dynamic> template) {
    for (final entry in _templates.entries) {
      if (entry.value.contains(template)) {
        return entry.key;
      }
    }
    return 'Other';
  }

  List<Map<String, dynamic>> _getFilteredTemplates() {
    if (_selectedCategory == 'All') {
      return _templates.values.expand((templates) => templates).toList();
    }
    return _templates[_selectedCategory] ?? [];
  }

  Widget _buildTemplateCard(ThemeData theme, Map<String, dynamic> template, String category) {
    final personalizedText = _getPersonalizedTemplate(template);

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceLG),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        side: BorderSide(color: theme.colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                // Color dot for category
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template['title'],
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceXS),
                      Row(
                        children: [
                          Icon(
                            Icons.psychology,
                            size: 16,
                            color: theme.colorScheme.primary,
                            semanticLabel: 'Adapted for $_selectedPersonality',
                          ),
                          const SizedBox(width: AppTheme.spaceXS),
                          Text(
                            'Adapted for $_selectedPersonality',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, semanticLabel: 'More actions'),
                  onSelected: (action) =>
                      _handleTemplateAction(action, template),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'customize',
                      child: Text('Customize'),
                    ),
                    const PopupMenuItem(value: 'copy', child: Text('Copy')),
                    const PopupMenuItem(
                      value: 'save',
                      child: Text('Save to Favorites'),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spaceLG),

            // Communication style chip
            Row(
              children: [
                Icon(Icons.chat_bubble, color: theme.colorScheme.primary, size: 16, semanticLabel: 'Communication Style'),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _selectedPersonality,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spaceMD),

            // Template preview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spaceLG),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.spaceMD),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Text(
                personalizedText,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ),

            const SizedBox(height: AppTheme.spaceLG),

            // Variables to customize
            if (template['variables'] != null &&
                template['variables'].isNotEmpty) ...[
              Text(
                'Customize these parts:',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: AppTheme.spaceXS),
              Wrap(
                spacing: AppTheme.spaceXS,
                runSpacing: AppTheme.spaceXS,
                children: (template['variables'] as List<String>)
                    .map(
                      (variable) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spaceSM,
                          vertical: AppTheme.spaceXS,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSM,
                          ),
                        ),
                        child: Text(
                          '{$variable}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: AppTheme.spaceLG),
            ],

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _customizeTemplate(template),
                    icon: const Icon(Icons.edit, semanticLabel: 'Customize'),
                    label: const Text('Customize'),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMD),
                Expanded(
                  child: GradientButton(
                    onPressed: () => _useTemplate(template),
                    text: 'Use Template',
                    gradient: AppTheme.primaryGradient,
                    icon: Icons.send,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getPersonalizedTemplate(Map<String, dynamic> template) {
    final adaptations =
        template['personality_adaptations'] as Map<String, dynamic>?;
    if (adaptations != null && adaptations.containsKey(_selectedPersonality)) {
      return adaptations[_selectedPersonality] as String;
    }
    return template['template'] as String;
  }

  void _handleTemplateAction(String action, Map<String, dynamic> template) {
    switch (action) {
      case 'copy':
        _copyTemplate(template);
        break;
      case 'customize':
        _customizeTemplate(template);
        break;
      case 'save':
        _saveTemplate(template);
        break;
    }
  }

  void _copyTemplate(Map<String, dynamic> template) {
    final text = _getPersonalizedTemplate(template);
    Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Template copied to clipboard'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _customizeTemplate(Map<String, dynamic> template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCustomizationSheet(template),
    );
  }

  Widget _buildCustomizationSheet(Map<String, dynamic> template) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLG),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Customize: ${template['title']}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, semanticLabel: 'Close'),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spaceLG),

            // Variable inputs
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: (template['variables'] as List<String>? ?? [])
                      .map(
                        (variable) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppTheme.spaceLG,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                variable.replaceAll('_', ' ').toUpperCase(),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spaceXS),
                              TextField(
                                decoration: InputDecoration(
                                  hintText:
                                      'Enter ${variable.replaceAll('_', ' ')}...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusMD,
                                    ),
                                  ),
                                ),
                                maxLines:
                                    variable.contains('action') ||
                                            variable.contains('improvement')
                                        ? 2
                                        : 1,
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),

            // Preview and send
            GradientButton(
              onPressed: () {
                Navigator.pop(context);
                // Handle sending customized template
              },
              text: 'Preview & Send',
              gradient: AppTheme.primaryGradient,
              icon: Icons.preview,
            ),
          ],
        ),
      ),
    );
  }

  void _useTemplate(Map<String, dynamic> template) {
    // Navigate to compose screen with template
    Navigator.pushNamed(
      context,
      '/compose',
      arguments: {
        'template': _getPersonalizedTemplate(template),
        'title': template['title'],
      },
    );
  }

  void _saveTemplate(Map<String, dynamic> template) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Template saved to favorites'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
