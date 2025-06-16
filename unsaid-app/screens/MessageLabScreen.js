import React, { useState, useContext } from 'react';
import { View, TextInput, Button, Text, StyleSheet, TouchableOpacity, Image } from 'react-native';
import axios from 'axios';
import { useRoute } from '@react-navigation/native';
import { MessageSettingsContext } from '../context/MessageSettingsContext';
import colors from '../theme/colors';

export default function MessageLabScreen({ navigation }) {
  const route = useRoute();
  const { sensitivity: contextSensitivity, tone: contextTone } = useContext(MessageSettingsContext);

  // Get sensitivity and tone from route params or context
  const { sensitivity = contextSensitivity || 0.5, tone = contextTone || 'Reassuring' } = route.params || {};

  const [message, setMessage] = useState('');
  const [result, setResult] = useState(null);
  const [loading, setLoading] = useState(false);

  const analyzeMessage = async () => {
    setLoading(true);
    try {
      const res = await axios.post(
        'https://us-central1-unsaid-3bc7c.cloudfunctions.net/analyzeTone',
        {
          message,
          sensitivity,
          tone,
        }
      );
      setResult(res.data.result);
    } catch (error) {
      console.error('Error analyzing tone:', error);
      setResult('Error analyzing message');
    }
    setLoading(false);
  };

  return (
    <View style={styles.container} accessible accessibilityLabel="Message Lab screen">
      <Image
        source={require('../assets/logo-icon.PNG')}
        style={{ width: 48, height: 48, alignSelf: 'center', marginBottom: 16 }}
        accessible
        accessibilityLabel="Unsaid logo"
      />
      <TextInput
        placeholder="Type your message here..."
        value={message}
        onChangeText={setMessage}
        style={styles.input}
        multiline
        accessible
        accessibilityLabel="Message input"
        accessibilityHint="Type your message to analyze its tone"
      />
      <Button
        title="Analyze Tone"
        onPress={analyzeMessage}
        disabled={loading}
        accessibilityLabel="Analyze message tone"
        accessibilityRole="button"
        accessibilityState={{ disabled: loading }}
      />
      {result !== null && (
        <Text
          style={styles.tone}
          accessible
          accessibilityLabel={`Detected tone: ${result}`}
        >
          Detected tone: {result}
        </Text>
      )}
      <TouchableOpacity
        style={styles.labBtn}
        onPress={() =>
          navigation.navigate('MessageLab', {
            sensitivity,
            tone: contextTone,
          })
        }
        accessible
        accessibilityRole="button"
        accessibilityLabel="Go to Message Lab"
      >
        <Text style={styles.labBtnText}>Message Lab</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    padding: 24,
    backgroundColor: colors.background,
    flex: 1,
    justifyContent: 'center'
  },
  input: {
    backgroundColor: '#fff',
    padding: 12,
    borderRadius: 8,
    marginBottom: 16,
    minHeight: 100
  },
  tone: {
    color: '#fff',
    marginTop: 20,
    fontSize: 18,
    fontWeight: 'bold'
  },
  labBtn: {
    backgroundColor: '#6C63FF',
    padding: 12,
    borderRadius: 8,
    alignItems: 'center',
    marginTop: 16
  },
  labBtnText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: 'bold'
  }
});
