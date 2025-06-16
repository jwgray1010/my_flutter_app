// MessageInputWithToneGlow.js
import React, { useState, useEffect } from 'react';
import { TextInput, View, Animated, StyleSheet, Image } from 'react-native';
import colors from '../theme/colors';

const getToneColor = (tone) => {
  switch (tone) {
    case 'calm': return '#7FDBFF';    // Blue
    case 'warm': return '#2ECC40';    // Green
    case 'tense': return '#FF851B';   // Orange
    case 'harsh': return '#FF4136';   // Red
    default: return '#AAAAAA';        // Neutral gray
  }
};

export default function MessageInputWithToneGlow({ analyzeTone }) {
  const [message, setMessage] = useState('');
  const [tone, setTone] = useState(null);
  const borderColorAnim = useState(new Animated.Value(0))[0];

  useEffect(() => {
    if (!message) return;

    // Fake real-time tone detection (replace with OpenAI or backend later)
    const fakeTone = message.includes('sorry') ? 'warm'
                  : message.includes('mad') ? 'tense'
                  : message.includes('love') ? 'calm'
                  : 'neutral';

    setTone(fakeTone);

    Animated.timing(borderColorAnim, {
      toValue: 1,
      duration: 300,
      useNativeDriver: false
    }).start(() => {
      borderColorAnim.setValue(0); // Reset for re-trigger
    });
  }, [message]);

  const borderGlow = borderColorAnim.interpolate({
    inputRange: [0, 1],
    outputRange: ['#ccc', getToneColor(tone)]
  });

  return (
    <View
      accessible
      accessibilityLabel="Message input with tone glow"
    >
      <Image
        source={require('../assets/logo-icon.PNG')}
        style={{ width: 48, height: 48, alignSelf: 'center', marginBottom: 16 }}
        accessible
        accessibilityLabel="Unsaid logo"
      />
      <Animated.View style={[styles.container, { borderColor: borderGlow }]}>
        <TextInput
          value={message}
          onChangeText={setMessage}
          placeholder="Type your message..."
          placeholderTextColor="#999"
          style={styles.input}
          multiline
          accessible
          accessibilityLabel="Message input"
          accessibilityHint="Type your message to see tone feedback"
        />
      </Animated.View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { 
    borderWidth: 2,
    borderRadius: 10,
    margin: 16,
    padding: 12,
    backgroundColor: colors.background,
  },
  input: {
    fontSize: 16,
    color: '#333',
    minHeight: 80,
  },
  title: {
    color: colors.text,
  },
});
