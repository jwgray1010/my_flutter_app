import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Linking, Image } from 'react-native';

export default function PersonalityTestDisclaimerScreen({ navigation }) {
  return (
    <View style={styles.container} accessible accessibilityLabel="Personality test disclaimer screen">
      <Image
        source={require('../assets/logo-icon.PNG')}
        style={{ width: 48, height: 48, alignSelf: 'center', marginBottom: 16 }}
        accessible
        accessibilityLabel="Unsaid logo"
      />
      <Text style={styles.title} accessibilityRole="header">
        Before You Begin
      </Text>
      <Text style={styles.text}>
        This test is for informational and personal growth purposes only. It is not a substitute for professional advice, diagnosis, or treatment. Unsaid is not responsible for any decisions or outcomes based on your results.
        {"\n\n"}
        By continuing, you agree to our{' '}
        <Text
          style={styles.link}
          onPress={() => Linking.openURL('https://your-privacy-policy-url.com')}
          accessible
          accessibilityRole="link"
          accessibilityLabel="Privacy Policy"
        >
          Privacy Policy
        </Text>
        {' '}and{' '}
        <Text
          style={styles.link}
          onPress={() => Linking.openURL('https://your-terms-url.com')}
          accessible
          accessibilityRole="link"
          accessibilityLabel="Terms of Service"
        >
          Terms of Service
        </Text>
        .
      </Text>
      <TouchableOpacity
        style={styles.button}
        onPress={() => navigation.replace('PersonalityTest')}
        accessible
        accessibilityRole="button"
        accessibilityLabel="I Understand and Agree"
      >
        <Text style={styles.buttonText}>I Understand & Agree</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#6C47FF', justifyContent: 'center', alignItems: 'center', padding: 30 },
  title: { color: '#fff', fontSize: 24, fontWeight: 'bold', marginBottom: 20 },
  text: { color: '#fff', fontSize: 16, marginBottom: 40, textAlign: 'center' },
  link: { color: '#FFD700', textDecorationLine: 'underline' },
  button: { backgroundColor: '#fff', padding: 16, borderRadius: 10 },
  buttonText: { color: '#6C47FF', fontWeight: 'bold', fontSize: 16 },
});