import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Image } from 'react-native';
import colors from '../theme/colors';

export default function OnboardingIntroScreen({ navigation }) {
  return (
    <View style={styles.container} accessible accessibilityLabel="Onboarding introduction screen">
      <Image
        source={require('../assets/logo-icon.PNG')}
        style={{ width: 48, height: 48, alignSelf: 'center', marginBottom: 16 }}
        accessible
        accessibilityLabel="Unsaid logo"
      />
      <Text style={styles.heading} accessibilityRole="header">
        What is Unsaid?
      </Text>
      <Text style={styles.subheading}>
        We help you send messages that protect your connection.
      </Text>

      <TouchableOpacity
        style={styles.button}
        onPress={() => navigation.navigate('OnboardingAccount')}
        accessible
        accessibilityRole="button"
        accessibilityLabel="Continue to account setup"
      >
        <Text style={styles.buttonText}>Continue</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 30,
  },
  heading: {
    fontSize: 32,
    color: colors.text,
    fontWeight: 'bold',
    textAlign: 'center',
    marginBottom: 20,
  },
  subheading: {
    fontSize: 18,
    color: colors.text,
    textAlign: 'center',
    marginBottom: 50,
  },
  button: {
    backgroundColor: 'white',
    paddingVertical: 12,
    paddingHorizontal: 30,
    borderRadius: 8,
  },
  buttonText: {
    color: '#6C47FF',
    fontWeight: '600',
    fontSize: 16,
  },
});
