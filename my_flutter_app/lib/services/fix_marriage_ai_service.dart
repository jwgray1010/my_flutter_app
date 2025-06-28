import 'package:flutter_dotenv/flutter_dotenv.dart';

final openAIApiKey = dotenv.env['OPENAI_API_KEY'];

class FixMarriageAIService {
  /// Suggests actionable, research-based goals for couples working to repair their marriage.
  /// Considers both partners' attachment and communication styles.
  static Future<List<String>> suggestGoals({
    required String yourAttachment,
    required String partnerAttachment,
    required String yourComm,
    required String partnerComm,
  }) async {
    List<String> goals = [];

    // 1. Communication
    goals.add(
      "Schedule weekly conversations to openly discuss feelings, needs, and concerns.",
    );
    goals.add(
      "Practice active listening: reflect back what your partner says before responding.",
    );
    goals.add("Use 'I' statements to express your feelings and avoid blame.");

    // 2. Address Underlying Issues
    goals.add(
      "Identify and discuss the root causes of recurring conflicts or emotional distance.",
    );
    goals.add(
      "Work together to resolve unresolved issues, possibly with the help of a therapist.",
    );

    // 3. Build Trust
    goals.add("Be consistent and reliable in your actions to rebuild trust.");
    goals.add(
      "If trust has been broken, set clear agreements and follow through on commitments.",
    );

    // 4. Practice Empathy
    goals.add(
      "Make an effort to understand your partner's perspective, even when you disagree.",
    );
    goals.add(
      "Validate your partner's feelings and show compassion during difficult conversations.",
    );

    // 5. Strengthen Connection
    goals.add(
      "Plan regular date nights or shared activities to nurture your bond.",
    );
    goals.add(
      "Express appreciation for your partner's efforts and positive qualities daily.",
    );
    goals.add("Pursue a shared hobby or interest to reconnect emotionally.");

    // 6. Seek Professional Help
    goals.add(
      "Consider couples therapy to gain new tools and perspectives for your relationship.",
    );

    // 7. Specific Actions
    goals.add("Strive for a 5:1 ratio of positive to negative interactions.");
    goals.add("Practice forgiveness and let go of past resentments.");
    goals.add(
      "Adjust expectations and recognize that ups and downs are normal in marriage.",
    );
    goals.add("Take time for self-care to maintain your own well-being.");

    // 8. Tailoring for Attachment & Communication Styles
    if (yourAttachment == "Anxious" || partnerAttachment == "Anxious") {
      goals.add(
        "Reassure each other regularly and set aside time for emotional check-ins.",
      );
    }
    if (yourAttachment == "Avoidant" || partnerAttachment == "Avoidant") {
      goals.add(
        "Gently encourage open sharing, but respect each other's need for space.",
      );
    }
    if (yourComm == "Aggressive" || partnerComm == "Aggressive") {
      goals.add(
        "Pause before responding in conflict and focus on respectful, non-blaming language.",
      );
    }
    if (yourComm == "Passive" || partnerComm == "Passive") {
      goals.add(
        "Assert your needs clearly and encourage your partner to do the same.",
      );
    }

    // Remove duplicates and return
    return goals.toSet().toList();
  }
}

class ChildDevelopmentAI {
  static Future<List<String>> suggestGoals() async {
    return [
      "Encourage your child's independence by allowing them to make age-appropriate choices.",
      "Spend at least 15 minutes daily in focused play or conversation with your child.",
      "Support your child's emotional expression by validating their feelings.",
    ];
  }
}
