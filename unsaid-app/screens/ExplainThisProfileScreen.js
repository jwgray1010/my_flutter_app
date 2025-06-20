import colors from '../theme/colors';

const generateProfileMessage = (userType, partnerType, partnerName) => {
  if (userType === "anxious" && partnerType === "avoidant") {
    return `
    You seek closeness when anxious. ${partnerName} seeks space when overwhelmed. 
    This can feel like chasing a ghost — but it’s really two people protecting their own hearts differently.
    
    With trust and patience, you can build a rhythm that feels safe for both of you.
    `;
  }

  if (userType === "secure" && partnerType === "anxious") {
    return `
    You offer steadiness. ${partnerName} may fear being abandoned — not because of you, but past experiences.
    
    Your presence can help ${partnerName} build safety, trust, and long-term confidence in love.
    `;
  }

  // Add more combos here...

  return `This is a growing connection. You and ${partnerName} have your own patterns — but those patterns aren’t problems. They’re invitations to understand each other better.`;
};

import React from 'react';
import { View, Text, StyleSheet, ScrollView } from 'react-native';

export default function ExplainProfileScreen({ route }) {
  const { profileData } = route.params;
  const { partnerName, explanation } = profileData;

  return (
    <View style={styles.container}>
      <ScrollView contentContainerStyle={styles.content}>
        <Text style={styles.title}>
          {partnerName ? `${partnerName}'s Relationship Style` : 'Relationship Style'}
        </Text>
        <Text style={styles.explanation}>{explanation}</Text>
      </ScrollView>
    </View>
  );
}

import React from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, Image } from 'react-native';
import { getFirestore, collection, addDoc } from 'firebase/firestore';
import { getAuth } from 'firebase/auth';
import colors from '../theme/colors';

export default function ExplainProfileScreen({ route, navigation }) {
  const { profile } = route.params;
  const {
    partnerName = 'Your Partner',
    personalityMatch = 'Anxious + Avoidant',
    explanation = 'This person may pull away during conflict to feel safe. They aren’t pushing you away — they’re protecting themselves.',
  } = profile;

  const db = getFirestore();
  const auth = getAuth();

  const saveProfileToDashboard = async (profile) => {
    const user = auth.currentUser;
    if (!user) return;

    await addDoc(collection(db, 'users', user.uid, 'savedProfiles'), {
      ...profile,
      savedAt: Date.now(),
    });
    alert('Profile saved to your dashboard!');
  };

  return (
    <ScrollView
      contentContainerStyle={styles.container}
      accessible
      accessibilityLabel="Relationship profile explanation screen"
    >
      <Image
        source={require('../assets/logo-icon.PNG')}
        style={{ width: 48, height: 48, alignSelf: 'center', marginBottom: 16 }}
        accessible
        accessibilityLabel="Unsaid logo"
      />
      <Text style={styles.title} accessibilityRole="header">
        Relationship Snapshot
      </Text>
      <Text
        style={styles.partnerName}
        accessible
        accessibilityLabel={`Partner name: ${partnerName}`}
      >
        {partnerName}
      </Text>
      <Text
        style={styles.match}
        accessible
        accessibilityLabel={`Personality match: ${personalityMatch}`}
      >
        {personalityMatch}
      </Text>
      <View
        style={styles.card}
        accessible
        accessibilityLabel="How they tend to react under stress"
      >
        <Text style={styles.label}>How they tend to react under stress:</Text>
        <Text
          style={styles.explanation}
          accessibilityLabel={`Explanation: ${explanation}`}
        >
          {explanation}
        </Text>
      </View>
      <TouchableOpacity
        onPress={() => navigation.navigate('Home')}
        style={styles.button}
        accessible
        accessibilityRole="button"
        accessibilityLabel="Back to Home"
      >
        <Text style={styles.buttonText}>🏠 Back to Home</Text>
      </TouchableOpacity>
      <TouchableOpacity
        style={styles.saveButton}
        onPress={() => saveProfileToDashboard(profile)}
        accessible
        accessibilityRole="button"
        accessibilityLabel="Save profile to my dashboard"
      >
        <Text style={styles.buttonText}>💾 Save to My Dashboard</Text>
      </TouchableOpacity>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { 
    backgroundColor: colors.background,
    padding: 30,
    alignItems: 'center',
    flexGrow: 1,
  },
  title: {
    fontSize: 22,
    fontWeight: '600',
    color: colors.text,
    marginBottom: 20,
  },
  partnerName: {
    fontSize: 28,
    fontWeight: '700',
    color: '#2f1b4c',
  },
  match: {
    fontSize: 18,
    color: '#6f6292',
    marginBottom: 20,
  },
  card: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 20,
    marginVertical: 20,
    width: '100%',
    shadowColor: '#000',
    shadowOpacity: 0.1,
    shadowRadius: 6,
    elevation: 3,
  },
  label: {
    fontWeight: '600',
    fontSize: 16,
    marginBottom: 8,
    color: '#555',
  },
  explanation: {
    fontSize: 16,
    color: '#333',
    lineHeight: 22,
  },
  button: {
    marginTop: 30,
    backgroundColor: '#4c2c72',
    paddingVertical: 12,
    paddingHorizontal: 30,
    borderRadius: 10,
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
  },
  saveButton: {
    marginTop: 10,
    backgroundColor: '#6f6292',
    paddingVertical: 12,
    paddingHorizontal: 30,
    borderRadius: 10,
  },
});
