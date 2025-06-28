// Re-export the advanced tone analysis service for backward compatibility
export 'advanced_tone_analysis_service.dart';

class ChildDevelopmentAI {
  static Future<List<String>> suggestGoals() async {
    return [
      "Encourage your child's independence by allowing them to make age-appropriate choices.",
      "Spend at least 15 minutes daily in focused play or conversation with your child.",
      "Support your child's emotional expression by validating their feelings.",
    ];
  }
}
