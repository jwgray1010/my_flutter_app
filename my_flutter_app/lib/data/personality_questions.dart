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

const List<PersonalityQuestion> personalityQuestions = [
  // Section 1: Attachment Style (5)
  PersonalityQuestion(
    question: "When I don’t get a text back, I usually:",
    options: [
      PersonalityQuestionOption(text: "Assume the worst", type: "A"),
      PersonalityQuestionOption(text: "Figure they’re just busy", type: "B"),
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
        text: "Feel anxious but pretend I’m fine",
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
      PersonalityQuestionOption(text: "Claustrophobic or nervous", type: "C"),
      PersonalityQuestionOption(
        text: "Unsure — it depends on the partner",
        type: "D",
      ),
    ],
  ),
  PersonalityQuestion(
    question: "In my past relationships, I’ve often:",
    options: [
      PersonalityQuestionOption(
        text: "Tried harder than my partner",
        type: "A",
      ),
      PersonalityQuestionOption(
        text: "Had healthy, balanced communication",
        type: "B",
      ),
      PersonalityQuestionOption(
        text: "Been accused of being distant",
        type: "C",
      ),
      PersonalityQuestionOption(
        text: "Stayed too long even when I was unhappy",
        type: "D",
      ),
    ],
  ),
  // Section 2: Emotional Communication Type (5)
  PersonalityQuestion(
    question: "When my partner is going through something hard, I usually:",
    options: [
      PersonalityQuestionOption(
        text: "Take on their emotions as my own",
        type: "A",
      ),
      PersonalityQuestionOption(
        text: "Give them room but offer support",
        type: "B",
      ),
      PersonalityQuestionOption(
        text: "Avoid the topic unless they bring it up",
        type: "C",
      ),
      PersonalityQuestionOption(text: "Struggle to know what to do", type: "D"),
    ],
  ),
  PersonalityQuestion(
    question: "Expressing my emotions in a relationship feels:",
    options: [
      PersonalityQuestionOption(
        text: "Natural but I worry I’m too much",
        type: "A",
      ),
      PersonalityQuestionOption(text: "Comfortable and easy", type: "B"),
      PersonalityQuestionOption(
        text: "Uncomfortable — I’d rather not",
        type: "C",
      ),
      PersonalityQuestionOption(text: "Difficult but necessary", type: "D"),
    ],
  ),
  PersonalityQuestion(
    question: "If my partner needs constant reassurance, I:",
    options: [
      PersonalityQuestionOption(
        text: "Feel responsible for their feelings",
        type: "A",
      ),
      PersonalityQuestionOption(text: "Can handle it to a point", type: "B"),
      PersonalityQuestionOption(text: "Feel smothered", type: "C"),
      PersonalityQuestionOption(text: "Need to pull away sometimes", type: "D"),
    ],
  ),
  PersonalityQuestion(
    question: "In a typical week, I reach out:",
    options: [
      PersonalityQuestionOption(
        text: "Constantly — I like frequent contact",
        type: "A",
      ),
      PersonalityQuestionOption(
        text: "A few times, depending on the flow",
        type: "B",
      ),
      PersonalityQuestionOption(
        text: "Rarely — I prefer less communication",
        type: "C",
      ),
      PersonalityQuestionOption(text: "Mostly when they text first", type: "D"),
    ],
  ),
  PersonalityQuestion(
    question: "When I feel misunderstood, I usually:",
    options: [
      PersonalityQuestionOption(
        text: "Get louder or try to explain harder",
        type: "A",
      ),
      PersonalityQuestionOption(
        text: "Try to calmly explain or clarify",
        type: "B",
      ),
      PersonalityQuestionOption(text: "Stay quiet and shut down", type: "C"),
      PersonalityQuestionOption(
        text: "Pull away and replay it in my head",
        type: "D",
      ),
    ],
  ),
  // Section 3: Conflict Response + Repair Style (5)
  PersonalityQuestion(
    question: "During arguments, I’m most likely to:",
    options: [
      PersonalityQuestionOption(text: "Get emotional or cry", type: "A"),
      PersonalityQuestionOption(text: "Stay calm and talk it out", type: "B"),
      PersonalityQuestionOption(text: "Shut down completely", type: "C"),
      PersonalityQuestionOption(
        text: "Leave or walk away until I cool off",
        type: "D",
      ),
    ],
  ),
  PersonalityQuestion(
    question: "After a fight, I want:",
    options: [
      PersonalityQuestionOption(
        text: "Immediate closeness and reassurance",
        type: "A",
      ),
      PersonalityQuestionOption(text: "Time and space to process", type: "B"),
      PersonalityQuestionOption(
        text: "Silence — I don’t want to talk about it",
        type: "C",
      ),
      PersonalityQuestionOption(
        text: "A distraction or something to take my mind off it",
        type: "D",
      ),
    ],
  ),
  PersonalityQuestion(
    question: "If my partner needs to talk through everything, I:",
    options: [
      PersonalityQuestionOption(text: "Feel overwhelmed but try", type: "A"),
      PersonalityQuestionOption(text: "Appreciate the clarity", type: "B"),
      PersonalityQuestionOption(text: "Feel like it's dragging on", type: "C"),
      PersonalityQuestionOption(
        text: "Avoid deep emotional conversations",
        type: "D",
      ),
    ],
  ),
  PersonalityQuestion(
    question: "The worst part of conflict for me is:",
    options: [
      PersonalityQuestionOption(text: "Feeling disconnected", type: "A"),
      PersonalityQuestionOption(
        text: "Losing peace and emotional balance",
        type: "B",
      ),
      PersonalityQuestionOption(text: "Not being in control", type: "C"),
      PersonalityQuestionOption(
        text: "Feeling judged or criticized",
        type: "D",
      ),
    ],
  ),
  PersonalityQuestion(
    question: "When conflict is over, I usually:",
    options: [
      PersonalityQuestionOption(
        text: "Still carry emotional tension",
        type: "A",
      ),
      PersonalityQuestionOption(text: "Feel closure and move on", type: "B"),
      PersonalityQuestionOption(
        text: "Stay quiet, even if I’m not okay",
        type: "C",
      ),
      PersonalityQuestionOption(
        text: "Try to act normal even if I’m hurt",
        type: "D",
      ),
    ],
  ),
  // Section 4: New Section (4)
  PersonalityQuestion(
    question: "When I disagree with someone, I usually:",
    options: [
      PersonalityQuestionOption(
        text: "Stay quiet to avoid conflict",
        type: "P",
      ), // Passive
      PersonalityQuestionOption(
        text: "Express my view respectfully",
        type: "AS",
      ), // Assertive
      PersonalityQuestionOption(
        text: "Raise my voice or get angry",
        type: "AG",
      ), // Aggressive
      PersonalityQuestionOption(
        text: "Use sarcasm or indirect comments",
        type: "PA",
      ), // Passive-Aggressive
    ],
  ),
  // --- More Attachment Style Questions ---
  PersonalityQuestion(
    question: "When someone cancels plans last minute, I:",
    options: [
      PersonalityQuestionOption(text: "Worry they don’t value me", type: "A"),
      PersonalityQuestionOption(text: "Understand and reschedule", type: "B"),
      PersonalityQuestionOption(text: "Feel relieved to have space", type: "C"),
      PersonalityQuestionOption(
        text: "Act like it’s fine but feel hurt",
        type: "D",
      ),
    ],
  ),
  PersonalityQuestion(
    question: "If my partner doesn’t reply for hours, I:",
    options: [
      PersonalityQuestionOption(text: "Check my phone constantly", type: "A"),
      PersonalityQuestionOption(
        text: "Trust they’ll reply when they can",
        type: "B",
      ),
      PersonalityQuestionOption(
        text: "Distract myself and don’t reach out",
        type: "C",
      ),
      PersonalityQuestionOption(
        text: "Feel upset but don’t say anything",
        type: "D",
      ),
    ],
  ),
  PersonalityQuestion(
    question: "When I feel disconnected, I:",
    options: [
      PersonalityQuestionOption(text: "Reach out repeatedly", type: "A"),
      PersonalityQuestionOption(
        text: "Communicate my feelings calmly",
        type: "B",
      ),
      PersonalityQuestionOption(text: "Withdraw and become distant", type: "C"),
      PersonalityQuestionOption(
        text: "Act normal but feel chaotic inside",
        type: "D",
      ),
    ],
  ),
  // --- More Communication Style Questions ---
  PersonalityQuestion(
    question: "If a friend upsets me, I:",
    options: [
      PersonalityQuestionOption(
        text: "Say nothing and hope it passes",
        type: "P",
      ),
      PersonalityQuestionOption(
        text: "Tell them honestly how I feel",
        type: "AS",
      ),
      PersonalityQuestionOption(
        text: "Confront them directly and forcefully",
        type: "AG",
      ),
      PersonalityQuestionOption(
        text: "Drop hints or make jokes about it",
        type: "PA",
      ),
    ],
  ),
  PersonalityQuestion(
    question: "When giving feedback, I:",
    options: [
      PersonalityQuestionOption(
        text: "Soften my words to avoid hurting them",
        type: "P",
      ),
      PersonalityQuestionOption(
        text: "Share my thoughts clearly and kindly",
        type: "AS",
      ),
      PersonalityQuestionOption(text: "Point out flaws bluntly", type: "AG"),
      PersonalityQuestionOption(
        text: "Use sarcasm or backhanded compliments",
        type: "PA",
      ),
    ],
  ),
  PersonalityQuestion(
    question: "If someone disagrees with me, I:",
    options: [
      PersonalityQuestionOption(
        text: "Let them have their way to keep peace",
        type: "P",
      ),
      PersonalityQuestionOption(
        text: "Listen and explain my view respectfully",
        type: "AS",
      ),
      PersonalityQuestionOption(
        text: "Insist I’m right and push my point",
        type: "AG",
      ),
      PersonalityQuestionOption(
        text: "Agree outwardly but resent it",
        type: "PA",
      ),
    ],
  ),
  PersonalityQuestion(
    question: "When I want something in a relationship, I:",
    options: [
      PersonalityQuestionOption(text: "Hope my partner will notice", type: "P"),
      PersonalityQuestionOption(
        text: "Ask directly for what I need",
        type: "AS",
      ),
      PersonalityQuestionOption(text: "Demand or expect it", type: "AG"),
      PersonalityQuestionOption(text: "Complain or guilt-trip", type: "PA"),
    ],
  ),
];

enum AttachmentStyle { anxious, secure, avoidant, disorganized }

enum CommunicationStyle { passive, assertive, aggressive, passiveAggressive }

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

CommunicationStyle getDominantCommunicationStyle(List<String> selectedTypes) {
  final counts = <String, int>{"P": 0, "AS": 0, "AG": 0, "PA": 0};
  for (final type in selectedTypes) {
    if (counts.containsKey(type)) counts[type] = counts[type]! + 1;
  }
  final maxType = counts.entries
      .reduce((a, b) => a.value >= b.value ? a : b)
      .key;
  switch (maxType) {
    case "P":
      return CommunicationStyle.passive;
    case "AS":
      return CommunicationStyle.assertive;
    case "AG":
      return CommunicationStyle.aggressive;
    case "PA":
      return CommunicationStyle.passiveAggressive;
    default:
      return CommunicationStyle.assertive; // fallback
  }
}
