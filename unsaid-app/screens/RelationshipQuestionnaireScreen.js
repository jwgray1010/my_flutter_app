import { useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, FlatList, Image } from 'react-native';
import { ProgressBar } from 'react-native-paper';
import colors from '../theme/colors';

const questions = [
  "I value deep emotional connection over surface-level communication.",
  "I tend to shut down when things get emotionally intense.",
  "I prefer space to process my emotions before talking.",
  "I often take responsibility for maintaining harmony in the relationship.",
  "I want to feel safe expressing my needs without judgment.",
];

const options = [
  "Strongly Agree",
  "Agree",
  "Neutral",
  "Disagree",
  "Strongly Disagree",
];

export default function RelationshipQuestionnaireScreen({ navigation, route }) {
  const [currentQuestionIndex, setCurrentQuestionIndex] = useState(0);
  const [answers, setAnswers] = useState([]);
  const { partnerName } = route.params || {};

  const handleAnswer = (selected) => {
    const updatedAnswers = [...answers, { question: questions[currentQuestionIndex], response: selected }];
    setAnswers(updatedAnswers);

    if (currentQuestionIndex + 1 < questions.length) {
      setCurrentQuestionIndex(currentQuestionIndex + 1);
    } else {
      // Done — go to next screen or process answers
      navigation.navigate('KeyboardIntro', { answers: updatedAnswers });
    }
  };

  const progress = (currentQuestionIndex + 1) / questions.length;

  return (
    <View style={styles.container} accessible accessibilityLabel="Relationship questionnaire screen">
      <Image source={require('../assets/logo-icon.PNG')} style={{ width: 48, height: 48, alignSelf: 'center', marginBottom: 16 }} accessible accessibilityLabel="Unsaid logo" />
      <Text style={styles.title} accessibilityRole="header">Relationship Insight</Text>
      <ProgressBar progress={progress} color="white" style={styles.progress} accessible accessibilityLabel={`Progress: ${Math.round(progress * 100)} percent`} />
      <Text style={styles.question} accessible accessibilityLabel={`Question: ${questions[currentQuestionIndex]}`}>{questions[currentQuestionIndex]}</Text>
      <FlatList
        data={options}
        keyExtractor={(item) => item}
        renderItem={({ item }) => (
          <TouchableOpacity
            style={styles.option}
            onPress={() => handleAnswer(item)}
            accessible
            accessibilityRole="button"
            accessibilityLabel={`Answer: ${item}`}
          >
            <Text style={styles.optionText}>{item}</Text>
          </TouchableOpacity>
        )}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { backgroundColor: colors.background },
  title: { color: colors.text },
  progress: {
    height: 10,
    borderRadius: 5,
    marginBottom: 30,
    backgroundColor: '#D1C4FF',
  },
  question: {
    fontSize: 18,
    color: 'white',
    marginBottom: 20,
    textAlign: 'center',
  },
  option: {
    backgroundColor: 'white',
    paddingVertical: 14,
    paddingHorizontal: 20,
    borderRadius: 10,
    marginBottom: 15,
  },
  optionText: {
    fontSize: 16,
    color: '#6C47FF',
    textAlign: 'center',
    fontWeight: '600',
  },
});