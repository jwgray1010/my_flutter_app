import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Image } from 'react-native';
import colors from '../theme/colors';

export default function PremiumScreen({ navigation }) {
  const handleSubscribe = () => {
    navigation.navigate('KeyboardIntro'); // or trigger purchase logic first
  };

  return (
    <View style={styles.container} accessible accessibilityLabel="Premium screen">
      <Image
        source={require('../assets/logo-icon.PNG')}
        style={{ width: 48, height: 48, alignSelf: 'center', marginBottom: 16 }}
        accessible
        accessibilityLabel="Unsaid logo"
      />
      <Text style={styles.title} accessibilityRole="header">Get More Out of Unsaid</Text>

      <View style={styles.card} accessible accessibilityLabel="Premium features list">
        <Text style={styles.bullet}> Advanced compatibility insights</Text>
        <Text style={styles.bullet}> Message Lab practice mode</Text>
        <Text style={styles.bullet}> Real-time tone filter</Text>
        <Text style={styles.bullet}> Early access to new features</Text>
      </View>

      <Text style={styles.price}>Start your 7-day free trial • Then $2.99/month</Text>

      <TouchableOpacity
        style={styles.button}
        onPress={handleSubscribe}
        accessible
        accessibilityRole="button"
        accessibilityLabel="Start free trial"
      >
        <Text style={styles.buttonText}>Start Free Trial</Text>
      </TouchableOpacity>

      <TouchableOpacity
        onPress={() => navigation.navigate('KeyboardIntro')}
        accessible
        accessibilityRole="button"
        accessibilityLabel="Maybe later"
      >
        <Text style={styles.skip}>Maybe later</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { backgroundColor: colors.background },
  title: { color: colors.text },
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
  price: {
    color: 'white',
    fontSize: 14,
    marginBottom: 25,
    textAlign: 'center',
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
