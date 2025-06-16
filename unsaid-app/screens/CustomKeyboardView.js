import React from 'react';
import { View, TextInput, Button, StyleSheet, Text, Image, AccessibilityInfo } from 'react-native';
import { KeyboardRegistry } from 'react-native-keyboard-input';
import { Icon } from 'react-native-vector-icons';
import colors from '../theme/colors';

const CustomKeyboardView = (props) => {
  const [text, setText] = React.useState('');
  const [feedback, setFeedback] = React.useState(null);

  const analyzeText = async () => {
    try {
      const res = await fetch('https://your-firebase-url/analyzeMessage', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          message: text,
          partnerAttachmentType: 'avoidant' // Example; pull from user settings
        }),
      });
      const { analysis } = await res.json();
      setFeedback(analysis);
      // Announce feedback for screen readers
      AccessibilityInfo.announceForAccessibility(analysis);
    } catch (err) {
      setFeedback("Couldn't analyze. Try again.");
      AccessibilityInfo.announceForAccessibility("Couldn't analyze. Try again.");
    }
  };

  return (
    <View
      style={styles.container}
      accessible
      accessibilityLabel="Custom keyboard view"
    >
      <Image
        source={require('../assets/logo-icon.PNG')}
        style={{ width: 48, height: 48, alignSelf: 'center', marginBottom: 16 }}
        accessible
        accessibilityLabel="Unsaid logo"
      />
      <TextInput
        placeholder="Type your message here..."
        style={styles.input}
        value={text}
        onChangeText={setText}
        accessible
        accessibilityLabel="Message input"
        accessibilityHint="Type your message to analyze its tone"
        returnKeyType="done"
      />
      <View
        accessible
        accessibilityRole="button"
        accessibilityLabel="Analyze message"
        style={styles.button}
      >
        <Button
          title="Analyze"
          onPress={analyzeText}
          color={styles.button.backgroundColor}
          accessibilityLabel="Analyze message"
        />
      </View>
      {feedback && (
        <Text
          style={[styles.feedback, { fontFamily: 'UnsaidFont' }]}
          accessible
          accessibilityLiveRegion="polite"
          accessibilityLabel={`Analysis feedback: ${feedback}`}
        >
          {feedback}
        </Text>
      )}
      <Icon
        name="message"
        size={30}
        color="white"
        accessible
        accessibilityLabel="Message icon"
        accessibilityRole="image"
      />
    </View>
  );
};

KeyboardRegistry.registerKeyboard('UnsaidKeyboard', () => CustomKeyboardView);

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 12,
    backgroundColor: colors.background,
    justifyContent: 'center',
    alignItems: 'center',
  },
  input: {
    width: '90%',
    height: 50,
    padding: 10,
    borderColor: '#fff',
    borderWidth: 1,
    borderRadius: 8,
    backgroundColor: '#ffffff',
    color: '#333',
    fontSize: 16,
  },
  button: {
    backgroundColor: '#FEA12A',
    padding: 10,
    borderRadius: 8,
    marginTop: 15,
    width: '90%',
  },
  feedback: {
    marginTop: 15,
    fontSize: 14,
    color: '#FFFFFF',
    textAlign: 'center',
  },
  title: {
    color: colors.text,
  },
});

export default CustomKeyboardView;
