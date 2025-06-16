import React, { useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, Alert, ActivityIndicator, Image, Button } from 'react-native';
import { getFirestore, doc, getDoc } from 'firebase/firestore';
import { app } from '../firebaseConfig'; // Make sure this exports your initialized Firebase app
import colors from '../theme/colors';
import firestore from '@react-native-firebase/firestore';

const db = getFirestore(app);

// Main InviteCodeScreen
export default function InviteCodeScreen({ navigation }) {
  const [code, setCode] = useState('');
  const [loading, setLoading] = useState(false);

  const handleUnlock = async () => {
    if (!code.trim()) {
      Alert.alert('Missing Code', 'Please enter your invite code.');
      return;
    }

    setLoading(true);
    try {
      const docRef = doc(db, 'inviteCodes', code.trim().toUpperCase());
      const docSnap = await getDoc(docRef);

      if (docSnap.exists()) {
        const data = docSnap.data();
        navigation.navigate('ExplainProfile', { profile: data });
      } else {
        Alert.alert('Invalid Code', 'We couldn’t find a profile with that code.');
      }
    } catch (error) {
      Alert.alert('Error', 'Something went wrong. Please try again.');
      console.error(error);
    }
    setLoading(false);
  };

  return (
    <View
      style={styles.container}
      accessible
      accessibilityLabel="Invite code entry screen"
    >
      <Image
        source={require('../assets/logo-icon.PNG')}
        style={{ width: 48, height: 48, alignSelf: 'center', marginBottom: 16 }}
        accessible
        accessibilityLabel="Unsaid logo"
      />
      <Text style={styles.title} accessibilityRole="header">
        🔓 Enter Invite Code
      </Text>

      <TextInput
        style={styles.input}
        placeholder="Enter 6-character code"
        autoCapitalize="characters"
        maxLength={6}
        value={code}
        onChangeText={setCode}
        accessible
        accessibilityLabel="Invite code input"
        accessibilityHint="Enter your 6-character invite code"
        returnKeyType="done"
        textContentType="oneTimeCode"
      />

      <TouchableOpacity
        onPress={handleUnlock}
        style={styles.button}
        disabled={loading}
        accessible
        accessibilityRole="button"
        accessibilityLabel="Unlock profile"
        accessibilityHint="Unlock the profile associated with this invite code"
        accessibilityState={{ disabled: loading }}
      >
        {loading ? (
          <ActivityIndicator color="#fff" accessibilityLabel="Loading" />
        ) : (
          <Text style={styles.buttonText}>Unlock Profile</Text>
        )}
      </TouchableOpacity>
    </View>
  );
}

// Alternative EnterCodeScreen (if used elsewhere)
export function EnterCodeScreen() {
  const [code, setCode] = useState('');
  const [explanation, setExplanation] = useState('');

  const fetchExplanation = async () => {
    const docSnap = await firestore().collection('explainedProfiles').doc(code).get();
    if (docSnap.exists) {
      setExplanation(docSnap.data().explanation);
    } else {
      setExplanation("Code not found. Please double-check.");
    }
  };

  return (
    <View style={altStyles.container} accessible accessibilityLabel="Enter code screen">
      <Text style={altStyles.label} accessibilityRole="header">
        Enter Your Code
      </Text>
      <TextInput
        style={altStyles.input}
        placeholder="UNSD-XXXXX"
        value={code}
        onChangeText={setCode}
        accessible
        accessibilityLabel="Profile code input"
        accessibilityHint="Enter your profile code"
        returnKeyType="done"
      />
      <Button
        title="Unlock Explanation"
        onPress={fetchExplanation}
        accessibilityLabel="Unlock explanation"
        accessibilityRole="button"
      />
      <Text
        style={altStyles.output}
        accessible
        accessibilityLabel={`Explanation: ${explanation}`}
      >
        {explanation}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 30,
  },
  title: {
    fontSize: 22,
    color: colors.text,
    marginBottom: 20,
    fontWeight: '600',
  },
  input: {
    backgroundColor: '#fff',
    padding: 12,
    borderRadius: 8,
    width: '100%',
    fontSize: 18,
    marginBottom: 20,
    textAlign: 'center',
    letterSpacing: 2,
  },
  button: {
    backgroundColor: '#4c2c72',
    paddingVertical: 14,
    paddingHorizontal: 40,
    borderRadius: 10,
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
  },
});

const altStyles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#2A145D', padding: 20 },
  label: { color: 'white', fontSize: 18, marginBottom: 10 },
  input: { backgroundColor: 'white', borderRadius: 6, padding: 10, marginBottom: 20 },
  output: { color: 'white', marginTop: 30, fontSize: 16 }
});
