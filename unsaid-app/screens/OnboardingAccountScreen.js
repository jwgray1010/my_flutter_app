import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Image } from 'react-native';
import colors from '../theme/colors';

export default function OnboardingAccountScreen({ navigation }) {
  const handleContinue = () => {
    navigation.navigate('QuestionnaireStart'); // Update with your next screen
  };

  return (
    <View style={styles.container} accessible accessibilityLabel="Onboarding account screen">
      <Image
        source={require('../assets/logo-icon.PNG')}
        style={{ width: 48, height: 48, alignSelf: 'center', marginBottom: 16 }}
        accessible
        accessibilityLabel="Unsaid logo"
      />
      <Text style={styles.heading} accessibilityRole="header">
        Create Your Experience
      </Text>
      <Text style={styles.subheading}>
        Choose how you want to begin.
      </Text>

      <TouchableOpacity
        style={styles.buttonWhite}
        onPress={handleContinue}
        accessible
        accessibilityRole="button"
        accessibilityLabel="Continue as guest"
      >
        <Text style={styles.buttonText}>Continue as Guest</Text>
      </TouchableOpacity>

      <TouchableOpacity
        style={styles.buttonDark}
        onPress={() => { /* Apple Auth */ }}
        accessible
        accessibilityRole="button"
        accessibilityLabel="Sign in with Apple"
      >
        <Text style={styles.buttonTextLight}>Sign in with Apple</Text>
      </TouchableOpacity>

      <TouchableOpacity
        style={styles.buttonBlue}
        onPress={() => { /* Google Auth */ }}
        accessible
        accessibilityRole="button"
        accessibilityLabel="Sign in with Google"
      >
        <Text style={styles.buttonTextLight}>Sign in with Google</Text>
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
    fontSize: 28,
    color: 'white',
    fontWeight: 'bold',
    textAlign: 'center',
    marginBottom: 10,
  },
  subheading: {
    fontSize: 16,
    color: 'white',
    textAlign: 'center',
    marginBottom: 40,
  },
  buttonWhite: {
    backgroundColor: 'white',
    paddingVertical: 14,
    paddingHorizontal: 30,
    borderRadius: 10,
    marginBottom: 20,
    width: '100%',
    alignItems: 'center',
  },
  buttonDark: {
    backgroundColor: '#1C1C1E',
    paddingVertical: 14,
    paddingHorizontal: 30,
    borderRadius: 10,
    marginBottom: 20,
    width: '100%',
    alignItems: 'center',
  },
  buttonBlue: {
    backgroundColor: '#4285F4',
    paddingVertical: 14,
    paddingHorizontal: 30,
    borderRadius: 10,
    width: '100%',
    alignItems: 'center',
  },
  buttonText: {
    color: '#6C47FF',
    fontSize: 16,
    fontWeight: '600',
  },
  buttonTextLight: {
    color: 'white',
    fontSize: 16,
    fontWeight: '600',
  },
});