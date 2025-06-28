import 'dart:math';

class PersonalityQuestionOption {
  final String text;
  final String type;

  const PersonalityQuestionOption({required this.text, required this.type});
}

class PersonalityQuestion {
  final String question;
  final List<PersonalityQuestionOption> options;

  const PersonalityQuestion({required this.question, required this.options});

  toJson() {}
}

class RandomizedPersonalityTest {
  static final Random _random = Random();

  // Get randomized questions with shuffled answer options
  static List<PersonalityQuestion> getRandomizedQuestions() {
    // Create a copy of the original questions
    List<PersonalityQuestion> shuffledQuestions = personalityQuestions.map((
      question,
    ) {
      // Shuffle the options for each question
      List<PersonalityQuestionOption> shuffledOptions = List.from(
        question.options,
      );
      shuffledOptions.shuffle(_random);

      return PersonalityQuestion(
        question: question.question,
        options: shuffledOptions,
      );
    }).toList();

    // Shuffle the order of questions themselves
    shuffledQuestions.shuffle(_random);

    return shuffledQuestions;
  }

  // Get randomized questions but maintain original question order (only shuffle answers)
  static List<PersonalityQuestion> getQuestionsWithShuffledAnswers() {
    return personalityQuestions.map((question) {
      List<PersonalityQuestionOption> shuffledOptions = List.from(
        question.options,
      );
      shuffledOptions.shuffle(_random);

      return PersonalityQuestion(
        question: question.question,
        options: shuffledOptions,
      );
    }).toList();
  }

  // Seed the random generator for consistent randomization per user session
  static void setSeed(int seed) {
    // This could be based on user ID or session ID to ensure consistency
    // across the test session but randomness between different users
  }
}

const List<PersonalityQuestion> personalityQuestions = [
  // Section 1: Attachment Style (5)
  PersonalityQuestion(
    question: "When I don't get a text back, I usually:",
    options: [
      PersonalityQuestionOption(text: "Assume the worst", type: "A"),
      PersonalityQuestionOption(text: "Figure they're just busy", type: "B"),
      PersonalityQuestionOption(text: "Get annoyed and ignore them", type: "C"),
      PersonalityQuestionOption(
        text: "Feel fine and do my own thing",
        type: "D",
      ),
    ],
  ),
  PersonalityQuestion(
    question: "I feel most secure in relationships when:",
    options: [
      PersonalityQuestionOption(
        text: "I get regular check-ins and verbal reassurance",
        type: "A",
      ),
      PersonalityQuestionOption(
        text: "We trust each other to do our own thing",
        type: "B",
      ),
      PersonalityQuestionOption(
        text: "I have control of the emotional pace",
        type: "C",
      ),
      PersonalityQuestionOption(
        text: "Conflict is rare or minimized",
        type: "D",
      ),
    ],
  ),
  PersonalityQuestion(
    question: "If my partner is upset with me, I tend to:",
    options: [
      PersonalityQuestionOption(
        text: "Worry and try to fix it right away",
        type: "A",
      ),
      PersonalityQuestionOption(
        text: "Respect their space and wait",
        type: "B",
      ),
      PersonalityQuestionOption(
        text: "Shut down and avoid confrontation",
        type: "C",
      ),
      PersonalityQuestionOption(
        text: "Feel anxious but pretend I'm fine",
        type: "D",
      ),
    ],
  ),
  PersonalityQuestion(
    question: "When I think about long-term commitment, I feel:",
    options: [
      PersonalityQuestionOption(
        text: "Excited but scared of losing them",
        type: "A",
      ),
      PersonalityQuestionOption(text: "Stable and comfortable", type: "B"),
      PersonalityQuestionOption(
        text: "Worried about loss of independence",
        type: "C",
      ),
      PersonalityQuestionOption(text: "Unsure and overwhelmed", type: "D"),
    ],
  ),
  PersonalityQuestion(
    question: "In arguments, I:",
    options: [
      PersonalityQuestionOption(
        text: "Get emotional and need reassurance",
        type: "A",
      ),
      PersonalityQuestionOption(
        text: "Stay calm and work through it",
        type: "B",
      ),
      PersonalityQuestionOption(text: "Withdraw and need space", type: "C"),
      PersonalityQuestionOption(
        text: "Feel torn between fighting and fleeing",
        type: "D",
      ),
    ],
  ),

  // Section 2: Communication Style (5)
  PersonalityQuestion(
    question: "When expressing my feelings, I prefer to:",
    options: [
      PersonalityQuestionOption(
        text: "Share everything immediately and openly",
        type: "A",
      ),
      PersonalityQuestionOption(
        text: "Communicate clearly but thoughtfully",
        type: "B",
      ),
      PersonalityQuestionOption(
        text: "Keep things to myself initially",
        type: "C",
      ),
      PersonalityQuestionOption(
        text: "Express myself inconsistently",
        type: "D",
      ),
    ],
  ),
  PersonalityQuestion(
    question: "If someone misunderstands my message, I:",
    options: [
      PersonalityQuestionOption(
        text: "Feel hurt and need to clarify right away",
        type: "A",
      ),
      PersonalityQuestionOption(text: "Calmly explain what I meant", type: "B"),
      PersonalityQuestionOption(
        text: "Feel frustrated but don't always address it",
        type: "C",
      ),
      PersonalityQuestionOption(
        text: "React unpredictably depending on my mood",
        type: "D",
      ),
    ],
  ),
  PersonalityQuestion(
    question: "When giving feedback to others, I:",
    options: [
      PersonalityQuestionOption(
        text: "Worry about hurting their feelings",
        type: "A",
      ),
      PersonalityQuestionOption(
        text: "Give honest, constructive feedback",
        type: "B",
      ),
      PersonalityQuestionOption(
        text: "Prefer to avoid giving negative feedback",
        type: "C",
      ),
      PersonalityQuestionOption(
        text: "Struggle to find the right approach",
        type: "D",
      ),
    ],
  ),
  PersonalityQuestion(
    question: "In difficult conversations, I:",
    options: [
      PersonalityQuestionOption(
        text: "Need lots of emotional support",
        type: "A",
      ),
      PersonalityQuestionOption(text: "Stay focused on resolution", type: "B"),
      PersonalityQuestionOption(
        text: "Want to end the conversation quickly",
        type: "C",
      ),
      PersonalityQuestionOption(text: "Feel overwhelmed and unsure", type: "D"),
    ],
  ),
  PersonalityQuestion(
    question: "My communication style is best described as:",
    options: [
      PersonalityQuestionOption(
        text: "Emotionally expressive and seeking connection",
        type: "A",
      ),
      PersonalityQuestionOption(
        text: "Direct, honest, and balanced",
        type: "B",
      ),
      PersonalityQuestionOption(text: "Reserved and independent", type: "C"),
      PersonalityQuestionOption(
        text: "Variable and hard to predict",
        type: "D",
      ),
    ],
  ),

  // Section 3: Emotional Regulation (5)
  PersonalityQuestion(
    question: "When I'm stressed, I typically:",
    options: [
      PersonalityQuestionOption(
        text: "Seek comfort and reassurance from others",
        type: "A",
      ),
      PersonalityQuestionOption(
        text: "Use healthy coping strategies",
        type: "B",
      ),
      PersonalityQuestionOption(text: "Prefer to handle it alone", type: "C"),
      PersonalityQuestionOption(
        text: "Feel overwhelmed and struggle to cope",
        type: "D",
      ),
    ],
  ),
  PersonalityQuestion(
    question: "I handle jealousy by:",
    options: [
      PersonalityQuestionOption(
        text: "Expressing my concerns and seeking reassurance",
        type: "A",
      ),
      PersonalityQuestionOption(
        text: "Trusting my partner and communicating openly",
        type: "B",
      ),
      PersonalityQuestionOption(
        text: "Keeping my feelings to myself",
        type: "C",
      ),
      PersonalityQuestionOption(
        text: "Feeling confused about what I need",
        type: "D",
      ),
    ],
  ),
  PersonalityQuestion(
    question: "When my mood changes, others:",
    options: [
      PersonalityQuestionOption(
        text: "Usually know because I express it clearly",
        type: "A",
      ),
      PersonalityQuestionOption(
        text: "Can tell, but I maintain emotional stability",
        type: "B",
      ),
      PersonalityQuestionOption(
        text: "Often don't notice because I hide it",
        type: "C",
      ),
      PersonalityQuestionOption(
        text: "Find it hard to predict or understand",
        type: "D",
      ),
    ],
  ),
  PersonalityQuestion(
    question: "I deal with anxiety by:",
    options: [
      PersonalityQuestionOption(
        text: "Talking it through with someone I trust",
        type: "A",
      ),
      PersonalityQuestionOption(
        text: "Using practical problem-solving",
        type: "B",
      ),
      PersonalityQuestionOption(
        text: "Distracting myself or avoiding the issue",
        type: "C",
      ),
      PersonalityQuestionOption(
        text: "Feeling stuck and unsure what helps",
        type: "D",
      ),
    ],
  ),
  PersonalityQuestion(
    question: "My emotional patterns are:",
    options: [
      PersonalityQuestionOption(
        text: "Intense but seeking connection",
        type: "A",
      ),
      PersonalityQuestionOption(text: "Stable and well-regulated", type: "B"),
      PersonalityQuestionOption(
        text: "Controlled and self-contained",
        type: "C",
      ),
      PersonalityQuestionOption(text: "Unpredictable and confusing", type: "D"),
    ],
  ),
];

enum AttachmentStyle { anxious, secure, avoidant, disorganized }

AttachmentStyle getDominantAttachmentStyle(List<String> selectedTypes) {
  final counts = <String, int>{"A": 0, "B": 0, "C": 0, "D": 0};
  for (final type in selectedTypes) {
    if (counts.containsKey(type)) counts[type] = counts[type]! + 1;
  }
  final maxType = counts.entries
      .reduce((a, b) => a.value >= b.value ? a : b)
      .key;
  switch (maxType) {
    case "A":
      return AttachmentStyle.anxious;
    case "B":
      return AttachmentStyle.secure;
    case "C":
      return AttachmentStyle.avoidant;
    case "D":
      return AttachmentStyle.disorganized;
    default:
      return AttachmentStyle.secure; // fallback
  }
}

// Optional: Get a breakdown for UI feedback
Map<AttachmentStyle, int> getAttachmentStyleBreakdown(
  List<String> selectedTypes,
) {
  final counts = <AttachmentStyle, int>{
    AttachmentStyle.anxious: 0,
    AttachmentStyle.secure: 0,
    AttachmentStyle.avoidant: 0,
    AttachmentStyle.disorganized: 0,
  };
  for (final type in selectedTypes) {
    switch (type) {
      case "A":
        counts[AttachmentStyle.anxious] = counts[AttachmentStyle.anxious]! + 1;
        break;
      case "B":
        counts[AttachmentStyle.secure] = counts[AttachmentStyle.secure]! + 1;
        break;
      case "C":
        counts[AttachmentStyle.avoidant] =
            counts[AttachmentStyle.avoidant]! + 1;
        break;
      case "D":
        counts[AttachmentStyle.disorganized] =
            counts[AttachmentStyle.disorganized]! + 1;
        break;
    }
  }
  return counts;
}
