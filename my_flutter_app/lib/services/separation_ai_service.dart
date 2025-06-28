import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SeparationAIService {
  static final openAIApiKey = dotenv.env['OPENAI_API_KEY'];

  static Future<List<String>> suggestGoals({
    required String yourAttachment,
    required String partnerAttachment,
    required String yourComm,
    required String partnerComm,
  }) async {
    final prompt =
        '''
You are an expert relationship coach.
A couple is going through a separation.
Their attachment styles are:
- Person 1: $yourAttachment
- Person 2: $partnerAttachment

Their communication styles are:
- Person 1: $yourComm
- Person 2: $partnerComm

Based on the latest research in relationship psychology, generate a numbered list of 8-12 actionable, practical, and emotionally supportive goals to help them cope with separation.
Include goals for:
- Emotional processing and support
- Self-care
- Communication and boundaries
- Legal/practical steps
- Focusing on the future
- Reconciliation (if appropriate)
- Healthy coping mechanisms

Tailor each goal to their unique attachment and communication styles.
Respond with a numbered list of goals only.
''';

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $openAIApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "gpt-4",
          "messages": [
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": prompt},
          ],
          "max_tokens": 600,
          "temperature": 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;

        // Parse numbered list from LLM response
        final goals = content
            .split(RegExp(r'\n\d+\.\s')) // Split on newlines and numbers
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

        // If the first item still has a number, remove it
        if (goals.isNotEmpty && goals[0].startsWith('1.')) {
          goals[0] = goals[0].substring(2).trim();
        }

        return goals;
      } else {
        // API error, fallback
        return _fallbackGoals(
          yourAttachment,
          partnerAttachment,
          yourComm,
          partnerComm,
        );
      }
    } catch (e) {
      // Network or parsing error, fallback
      return _fallbackGoals(
        yourAttachment,
        partnerAttachment,
        yourComm,
        partnerComm,
      );
    }
  }

  static List<String> _fallbackGoals(
    String yourAttachment,
    String partnerAttachment,
    String yourComm,
    String partnerComm,
  ) {
    // Your existing rule-based logic here (see previous examples)
    return [
      "Allow yourself to grieve and process emotions—consider journaling or talking with a trusted friend or therapist.",
      "Join a support group for people going through separation or divorce.",
      "Prioritize your physical health: eat well, exercise, and get enough sleep.",
      "Engage in activities and hobbies that bring you joy and a sense of normalcy.",
      "Set clear boundaries with your ex-partner, especially regarding communication and shared responsibilities.",
      "Communicate respectfully and focus on clarity, especially about parenting and finances.",
      "Avoid involving children in adult matters related to the separation.",
      "Consult a legal professional to understand your rights and obligations.",
      "Define personal and professional goals for your next chapter.",
      "Visualize a positive future and take small steps toward it.",
      "Build a support system of friends, family, or community resources.",
      "If both parties are open, consider a period of reflection before making final decisions.",
      "If reconciliation is desired, prioritize open and honest communication.",
      "Avoid unhealthy coping mechanisms such as substance use; seek healthy outlets for stress.",
    ];
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
