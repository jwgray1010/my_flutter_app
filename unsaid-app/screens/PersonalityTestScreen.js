import React, { useState, useEffect } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ProgressBarAndroid, Image } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { personalityQuestions } from '../utils/personalityQuestions';
import colors from '../theme/colors';

export default function PersonalityTestScreen({ navigation }) {
  const [current, setCurrent] = useState(0);
  const [answers, setAnswers] = useState([]);
  const [alreadyTaken, setAlreadyTaken] = useState(false);

  useEffect(() => {
    AsyncStorage.getItem('personalityTestTaken').then(val => {
      if (val === 'true') setAlreadyTaken(true);
    });
  }, []);

  const handleSelect = async (type) => {
    const updated = [...answers, type];
    if (current + 1 < personalityQuestions.length) {
      setAnswers(updated);
      setCurrent(current + 1);
    } else {
      await AsyncStorage.setItem('personalityTestTaken', 'true');
      navigation.replace('PersonalityResults', { answers: updated });
    }
  };

  if (alreadyTaken) {
    return (
      <View style={styles.container} accessible accessibilityLabel="Test already taken screen">
        <Text style={{ color: '#fff', fontSize: 18, textAlign: 'center' }}>
          You have already taken the Unsaid Relationship Personality Test. For best results, you can only take it once.
        </Text>
      </View>
    );
  }

  const q = personalityQuestions[current];

  return (
    <View style={styles.container} accessible accessibilityLabel="Personality test screen">
      <Image source={require('../assets/logo-icon.PNG')} style={{ width: 48, height: 48, alignSelf: 'center', marginBottom: 16 }} accessible accessibilityLabel="Unsaid logo" />
      <Text style={styles.progress} accessibilityLabel={`Question ${current + 1} of ${personalityQuestions.length}`}>
        {current + 1} / {personalityQuestions.length}
      </Text>
      <Text style={styles.question} accessibilityLabel={`Question: ${q.question}`}>{q.question}</Text>
      {q.options.map((opt, idx) => (
        <TouchableOpacity
          key={idx}
          style={styles.option}
          onPress={() => handleSelect(opt.type)}
          accessible
          accessibilityRole="button"
          accessibilityLabel={`Answer: ${opt.text}`}
        >
          <Text style={styles.optionText}>{opt.text}</Text>
        </TouchableOpacity>
      ))}
      <ProgressBarAndroid
        styleAttr="Horizontal"
        indeterminate={false}
        progress={(current + 1) / personalityQuestions.length}
        color="#6C47FF"
        accessible
        accessibilityLabel={`Progress: ${Math.round(((current + 1) / personalityQuestions.length) * 100)} percent`}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { backgroundColor: colors.background },
  progress: { color: '#fff', fontSize: 16, marginBottom: 10, textAlign: 'center' },
  question: { color: '#fff', fontSize: 20, fontWeight: 'bold', marginBottom: 30, textAlign: 'center' },
  option: { backgroundColor: '#fff', borderRadius: 10, padding: 18, marginBottom: 18 },
  optionText: { color: '#6C47FF', fontSize: 16, textAlign: 'center', fontWeight: '600' },
});