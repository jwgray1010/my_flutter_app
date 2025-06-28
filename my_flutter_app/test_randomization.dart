// Quick test to verify question and answer randomization
import 'lib/data/randomized_personality_questions.dart';

void main() {
  print('Testing question and answer randomization...\n');

  // Test 1: Verify questions are shuffled
  print('Test 1: Question order randomization');
  final questions1 = RandomizedPersonalityTest.getRandomizedQuestions();
  final questions2 = RandomizedPersonalityTest.getRandomizedQuestions();

  print('First run - First question: ${questions1[0].question}');
  print('Second run - First question: ${questions2[0].question}');

  bool questionsShuffled = questions1[0].question != questions2[0].question;
  print('Questions shuffled: $questionsShuffled\n');

  // Test 2: Verify answers are shuffled within questions
  print('Test 2: Answer option randomization');
  final originalQuestion = personalityQuestions[0];
  final shuffledQuestion1 = RandomizedPersonalityTest.getRandomizedQuestions()
      .firstWhere((q) => q.question == originalQuestion.question);
  final shuffledQuestion2 = RandomizedPersonalityTest.getRandomizedQuestions()
      .firstWhere((q) => q.question == originalQuestion.question);

  print('Original first answer option: ${originalQuestion.options[0].text}');
  print('Shuffled run 1 first option: ${shuffledQuestion1.options[0].text}');
  print('Shuffled run 2 first option: ${shuffledQuestion2.options[0].text}');

  bool answersShuffled =
      shuffledQuestion1.options[0].text != shuffledQuestion2.options[0].text ||
      originalQuestion.options[0].text != shuffledQuestion1.options[0].text;
  print('Answers shuffled: $answersShuffled\n');

  // Test 3: Verify all answer types are preserved
  print('Test 3: Answer types preservation');
  final originalTypes = originalQuestion.options.map((o) => o.type).toSet();
  final shuffledTypes = shuffledQuestion1.options.map((o) => o.type).toSet();
  bool typesPreserved =
      originalTypes.length == shuffledTypes.length &&
      originalTypes.every((type) => shuffledTypes.contains(type));
  print('Original types: $originalTypes');
  print('Shuffled types: $shuffledTypes');
  print('Types preserved: $typesPreserved\n');

  print('Randomization test complete!');
  print('✓ Questions are randomized: $questionsShuffled');
  print('✓ Answers are randomized: $answersShuffled');
  print('✓ Answer types preserved: $typesPreserved');
}
