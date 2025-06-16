import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Clipboard, Alert, Linking, Image } from 'react-native';
import colors from '../theme/colors';

export default function CodeGeneratedScreen({ route }) {
  const { code } = route.params;

  const handleCopy = () => {
    Clipboard.setString(code);
    Alert.alert('Copied!', 'Invite code copied to clipboard');
  };

  const handleEmail = () => {
    const subject = 'Unlock My Relationship Profile';
    const body = `Hey — I wanted to share something that might help us understand each other better.\n\nUse this code in the Unsaid app:\n\n🔐 Code: ${code}`;
    const url = `mailto:?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`;
    Linking.openURL(url);
  };

  return (
    <View style={styles.container} accessible accessibilityLabel="Invite code screen">
      <Image
        source={require('../assets/logo-icon.PNG')}
        style={{ width: 48, height: 48, alignSelf: 'center', marginBottom: 16 }}
        accessible
        accessibilityLabel="Unsaid logo"
      />
      <Text style={styles.title} accessibilityRole="header">
        Your Invite Code
      </Text>
      <Text
        style={styles.code}
        accessible
        accessibilityLabel={`Your invite code is ${code}`}
        accessibilityRole="text"
      >
        {code}
      </Text>

      <TouchableOpacity
        onPress={handleCopy}
        style={styles.button}
        accessible
        accessibilityRole="button"
        accessibilityLabel="Copy invite code to clipboard"
      >
        <Text style={styles.buttonText}>📋 Copy Code</Text>
      </TouchableOpacity>

      <TouchableOpacity
        onPress={handleEmail}
        style={styles.buttonSecondary}
        accessible
        accessibilityRole="button"
        accessibilityLabel="Send invite code via email"
      >
        <Text style={styles.buttonText}>📧 Send via Email</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  title: {
    fontSize: 22,
    fontWeight: '600',
    color: colors.text,
    marginBottom: 20,
  },
  code: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#000',
    marginBottom: 30,
    backgroundColor: '#fff',
    padding: 10,
    borderRadius: 8,
    letterSpacing: 2,
  },
  button: {
    backgroundColor: '#4c2c72',
    padding: 12,
    borderRadius: 8,
    marginBottom: 12,
  },
  buttonSecondary: {
    backgroundColor: '#715694',
    padding: 12,
    borderRadius: 8,
    marginBottom: 30,
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
  },
});
