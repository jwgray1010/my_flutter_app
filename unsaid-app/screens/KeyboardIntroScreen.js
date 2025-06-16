import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Linking, Image } from 'react-native';
import colors from '../theme/colors';

export default function KeyboardIntroScreen({ navigation }) {
  const openKeyboardSettings = () => {
    // For demo purposes – in production, link to actual settings
    Linking.openURL('app-settings:');
  };

  return (
    <View
      style={styles.container}
      accessible
      accessibilityLabel="Keyboard introduction screen"
    >
      <Image
        source={require('../assets/logo-icon.PNG')}
        style={{ width: 48, height: 48, alignSelf: 'center', marginBottom: 16 }}
        accessible
        accessibilityLabel="Unsaid logo"
      />
      <Text style={styles.title} accessibilityRole="header">
        Unlock the Unsaid Keyboard
      </Text>
      <Text style={styles.description}>
        Our smart keyboard gives you live insights as you type — helping you connect better and avoid misfires.
      </Text>

      <View
        style={styles.card}
        accessible
        accessibilityLabel="Keyboard features: real-time emotional cues, tone filters, personality-aware suggestions, works across all your apps"
      >
        <Text style={styles.bullet}>🔍 Real-time emotional cues</Text>
        <Text style={styles.bullet}>🌡️ Tone filters based on your relationship</Text>
        <Text style={styles.bullet}>🧠 Personality-aware suggestions</Text>
        <Text style={styles.bullet}>🧪 Works across all your apps</Text>
      </View>

      <TouchableOpacity
        style={styles.button}
        onPress={openKeyboardSettings}
        accessible
        accessibilityRole="button"
        accessibilityLabel="Enable Unsaid Keyboard. Opens device settings."
      >
        <Text style={styles.buttonText}>Enable Unsaid Keyboard</Text>
      </TouchableOpacity>

      <TouchableOpacity
        onPress={() => navigation.navigate('HomeScreen')}
        accessible
        accessibilityRole="button"
        accessibilityLabel="Skip keyboard setup and go to home"
      >
        <Text style={styles.skip}>Skip for now</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { backgroundColor: colors.background, flex: 1, justifyContent: 'center', alignItems: 'center', padding: 24 },
  title: { color: colors.text, fontSize: 24, fontWeight: 'bold', marginBottom: 16, textAlign: 'center' },
  description: {
    fontSize: 16,
    color: 'white',
    marginBottom: 30,
    textAlign: 'center',
  },
  card: {
    backgroundColor: 'white',
    borderRadius: 12,
    padding: 25,
    width: '100%',
    marginBottom: 25,
  },
  bullet: {
    fontSize: 16,
    color: '#333',
    marginBottom: 12,
  },
  button: {
    backgroundColor: 'white',
    paddingVertical: 14,
    paddingHorizontal: 40,
    borderRadius: 10,
    marginBottom: 15,
  },
  buttonText: {
    color: '#6C47FF',
    fontSize: 16,
    fontWeight: '600',
  },
  skip: {
    color: 'white',
    textDecorationLine: 'underline',
    fontSize: 14,
  },
});
