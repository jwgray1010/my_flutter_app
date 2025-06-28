import 'package:flutter/material.dart';

class RelationshipCoupleGoals extends StatefulWidget {
  final String yourAttachment;
  final String partnerAttachment;
  final String yourComm;
  final String partnerComm;
  final String context; // "marriage", "separation", "co-parenting"

  const RelationshipCoupleGoals({
    super.key,
    required this.yourAttachment,
    required this.partnerAttachment,
    required this.yourComm,
    required this.partnerComm,
    required this.context,
  });

  @override
  State<RelationshipCoupleGoals> createState() =>
      _RelationshipCoupleGoalsState();
}

class _RelationshipCoupleGoalsState extends State<RelationshipCoupleGoals> {
  final List<String> _goals = [];
  late List<String> aiSuggestions;
  bool loadingAI = false;

  @override
  void initState() {
    super.initState();
    _fetchAISuggestions();
  }

  Future<void> _fetchAISuggestions() async {
    setState(() => loadingAI = true);
    aiSuggestions = await CoParentingAIService.suggestGoals(
      yourAttachment: widget.yourAttachment,
      partnerAttachment: widget.partnerAttachment,
      yourComm: widget.yourComm,
      partnerComm: widget.partnerComm,
    );
    setState(() => loadingAI = false);
  }

  void _addGoal(String goal) {
    setState(() {
      _goals.add(goal);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Couple Goals",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Your Shared Goals",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_goals.isEmpty)
                    Text(
                      "No goals yet. Add one below!",
                      style: theme.textTheme.bodyMedium,
                    ),
                  ..._goals.map(
                    (g) => ListTile(
                      leading: const Icon(
                        Icons.check_circle,
                        color: Color(0xFF7B61FF),
                      ),
                      title: Text(g),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: "Add a new goal",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) _addGoal(val.trim());
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Color(0xFF7B61FF)),
                      const SizedBox(width: 8),
                      Text(
                        "AI-Recommended Goals",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (loadingAI) Center(child: CircularProgressIndicator()),
                  if (!loadingAI)
                    ...aiSuggestions.map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Color(0xFF7B61FF),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(s)),
                            IconButton(
                              icon: const Icon(
                                Icons.add,
                                color: Color(0xFF7B61FF),
                              ),
                              tooltip: "Add to My Goals",
                              onPressed: () => _addGoal(s),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (!loadingAI && aiSuggestions.isEmpty)
                    Text(
                      "No suggestions available.",
                      style: theme.textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CoParentingAIService {
  static Future<List<String>> suggestGoals({
    required String yourAttachment,
    required String partnerAttachment,
    required String yourComm,
    required String partnerComm,
  }) async {
    // Replace with real AI logic
    return [
      "Maintain a shared calendar for your child's activities.",
      "Agree on consistent routines for your child.",
    ];
  }
}

class ChildDevelopmentAI {
  static Future<List<String>> suggestGoals() async {
    // Replace with real AI logic
    return [
      "Read together with your child every night.",
      "Encourage your child to express their feelings.",
    ];
  }
}

class SeparationAIService {
  static Future<List<String>> suggestGoals({
    required String yourAttachment,
    required String partnerAttachment,
    required String yourComm,
    required String partnerComm,
  }) async {
    // Replace with real AI logic
    return [
      "Establish clear boundaries for communication.",
      "Schedule regular check-ins for co-parenting logistics.",
    ];
  }
}

class FixMarriageAIService {
  static Future<List<String>> suggestGoals({
    required String yourAttachment,
    required String partnerAttachment,
    required String yourComm,
    required String partnerComm,
  }) async {
    // Replace with real AI logic
    return [
      "Plan a monthly date night.",
      "Practice active listening during disagreements.",
    ];
  }
}
