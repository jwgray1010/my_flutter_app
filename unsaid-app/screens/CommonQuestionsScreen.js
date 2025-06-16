import React, { useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Image, ScrollView } from 'react-native';
import colors from '../theme/colors';

const FAQS = [
  {
    question: "What is Unsaid?",
    answer: "Unsaid is a relationship communication app that helps you understand your own and your partner’s communication styles, attachment patterns, and emotional needs.",
  },
  {
    question: "How does the personality test work?",
    answer: "The test uses research-backed questions to identify your relationship communication style. Your answers are private and help personalize your experience in the app.",
  },
  {
    question: "Can I retake the personality test?",
    answer: "For accuracy, the test can only be taken once per account. If you believe you made a mistake, please contact support.",
  },
  {
    question: "How do I invite my partner?",
    answer: "You can generate an invite code from the Partner Profile section and share it with your partner so they can join and connect with you in the app.",
  },
  {
    question: "Is my data private?",
    answer: "Yes. Your responses and results are private and never shared without your permission. Please see our Privacy Policy for more details.",
  },
  {
    question: "What is the Message Lab?",
    answer: "Message Lab helps you craft messages with the right tone and sensitivity, tailored to your and your partner’s communication styles.",
  },
  {
    question: "How do I change my sensitivity or tone settings?",
    answer: "You can adjust these settings anytime in the Settings tab.",
  },
  {
    question: "How do I enable the custom keyboard?",
    answer: "Go to your device’s settings, add “Unsaid” as a keyboard, and enable it. You can turn it on or off in the app’s Settings tab.",
  },
  {
    question: "What if I need relationship advice?",
    answer: "Unsaid is for informational and personal growth purposes only. For professional advice, please consult a licensed therapist or counselor.",
  },
  {
    question: "How do I upgrade to premium?",
    answer: "Tap the Premium tab to see features and subscription options.",
  },
];

export default function CommonQuestionsScreen() {
  const [openIndex, setOpenIndex] = useState(null);

  return (
    <ScrollView
      style={styles.scroll}
      contentContainerStyle={styles.container}
      accessible
      accessibilityLabel="Common Questions screen"
    >
      <Text style={styles.title} accessibilityRole="header">
        Common Questions
      </Text>
      <Image
        source={require('../assets/logo-icon.PNG')}
        style={{ width: 48, height: 48, alignSelf: 'center', marginBottom: 16 }}
        accessible
        accessibilityLabel="Unsaid logo"
      />
      {FAQS.map((faq, idx) => (
        <TouchableOpacity
          key={idx}
          style={styles.card}
          onPress={() => setOpenIndex(openIndex === idx ? null : idx)}
          accessible
          accessibilityRole="button"
          accessibilityLabel={`${
            openIndex === idx ? 'Hide answer for' : 'Show answer for'
          } ${faq.question}`}
          accessibilityState={{ expanded: openIndex === idx }}
        >
          <Text style={styles.question}>{faq.question}</Text>
          {openIndex === idx && (
            <Text style={styles.answer}>{faq.answer}</Text>
          )}
        </TouchableOpacity>
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  scroll: { backgroundColor: colors.background },
  container: { padding: 24, paddingBottom: 40 },
  title: {
    color: colors.text,
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 20,
    textAlign: 'center',
  },
  card: {
    backgroundColor: colors.accent,
    borderRadius: 12,
    padding: 18,
    marginBottom: 16,
    elevation: 2,
  },
  question: {
    color: colors.text,
    fontWeight: '600',
    fontSize: 17,
    marginBottom: 6,
  },
  answer: {
    color: colors.textDark,
    fontSize: 15,
    marginTop: 8,
  },
});