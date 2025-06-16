import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Linking, Image } from 'react-native';

export default function PersonalityTestDisclaimerScreen({ navigation }) {
  return (
    <View style={styles.container}>
      <Image source={require('../assets/logo-icon.PNG')} style={{ width: 48, height: 48, alignSelf: 'center', marginBottom: 16 }} />
      <Text style={styles.title}>Before You Begin</Text>
      <Text style={styles.text}>
        This test is for informational and personal growth purposes only. It is not a substitute for professional advice, diagnosis, or treatment. Unsaid is not responsible for any decisions or outcomes based on your results.
        {"\n\n"}
        By continuing, you agree to our{' '}
        <Text
          style={styles.link}
          onPress={() => Linking.openURL('https://your-privacy-policy-url.com')}
        >
          Privacy Policy
        </Text>
        {' '}and{' '}
        <Text
          style={styles.link}
          onPress={() => Linking.openURL('https://your-terms-url.com')}
        >
          Terms of Service
        </Text>
        .
      </Text>
      <TouchableOpacity
        style={styles.button}
        onPress={() => navigation.replace('PersonalityTest')}
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
});