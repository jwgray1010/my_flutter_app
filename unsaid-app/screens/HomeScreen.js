import React, { useContext, useEffect, useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView, ActivityIndicator, Alert, TextInput, Slider, Image } from 'react-native';
import { getFirestore, collection, getDocs, doc, deleteDoc } from 'firebase/firestore';
import { getAuth, onAuthStateChanged } from 'firebase/auth';
import axios from 'axios';
import { MessageSettingsContext } from '../context/MessageSettingsContext';
import colors from '../theme/colors';

const db = getFirestore();
const auth = getAuth();

const TONE_OPTIONS = ['Polite', 'Reassuring', 'Neutral'];

export default function HomeScreen({ navigation }) {
  const { sensitivity, setSensitivity, tone, setTone } = useContext(MessageSettingsContext);

  const [savedProfiles, setSavedProfiles] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [user, setUser] = useState(null);
  const [message, setMessage] = useState('');
  const [analysis, setAnalysis] = useState('');
  const [loadingAnalysis, setLoadingAnalysis] = useState(false);
  const [selectedTone, setSelectedTone] = useState('Reassuring');

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, (firebaseUser) => {
      setUser(firebaseUser);
    });
    return unsubscribe;
  }, []);

  useEffect(() => {
    if (!user) {
      setLoading(false);
      return;
    }
    const fetchProfiles = async () => {
      setLoading(true);
      setError('');
      try {
        const snap = await getDocs(collection(db, 'users', user.uid, 'savedProfiles'));
        const data = snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        setSavedProfiles(data);
      } catch (e) {
        setError('Failed to load profiles.');
      }
      setLoading(false);
    };
    fetchProfiles();
  }, [user]);

  const handleEdit = (id, partnerName) => {
    Alert.alert('Edit', `Edit profile: ${partnerName}`);
  };

  const handleDelete = async (id) => {
    if (!user) return;
    try {
      await deleteDoc(doc(db, 'users', user.uid, 'savedProfiles', id));
      setSavedProfiles(prev => prev.filter(profile => profile.id !== id));
    } catch (e) {
      Alert.alert('Error', 'Failed to delete profile.');
    }
  };

  const handleAnalyze = async () => {
    setLoadingAnalysis(true);
    const partnerAttachmentType = 'Dismissive Avoidant'; // Example
    const systemPrompt = `You are a relationship communication expert. Analyze the message using emotional intelligence and the partner’s attachment style: ${partnerAttachmentType}. Provide:
    1. Emotional tone
    2. Possible emotional triggers (for this attachment type)
    3. Suggestions for improvement that feel safe and connective.`;

    try {
      const res = await axios.post(
        'https://us-central1-unsaid-3bc7c.cloudfunctions.net/analyzeTone',
        { message }
      );
      setAnalysis(res.data.result);
    } catch (error) {
      setAnalysis('An error occurred during analysis. Please try again.');
    }
    setLoadingAnalysis(false);
  };

  if (loading) {
    return (
      <View style={styles.center} accessible accessibilityLabel="Loading screen">
        <ActivityIndicator size="large" color="#7B61FF" />
      </View>
    );
  }

  if (!user) {
    return (
      <View style={styles.center} accessible accessibilityLabel="Not logged in screen">
        <Text style={{ fontSize: 16 }}>Please log in to view your saved profiles.</Text>
      </View>
    );
  }

  if (error) {
    return (
      <View style={styles.center} accessible accessibilityLabel="Error screen">
        <Text style={{ color: 'red' }}>{error}</Text>
      </View>
    );
  }

  return (
    <View style={styles.container} accessible accessibilityLabel="Home screen">
      <Image
        source={require('../assets/logo-icon.PNG')}
        style={{ width: 48, height: 48, alignSelf: 'center', marginBottom: 16 }}
        accessible
        accessibilityLabel="Unsaid logo"
      />
      <Text style={styles.title} accessibilityRole="header">
        Welcome to Unsaid
      </Text>
      <Text style={styles.subtitle}>
        Your emotional clarity hub
      </Text>

      <ScrollView contentContainerStyle={styles.cardContainer}>
        <TouchableOpacity
          style={styles.card}
          onPress={() => navigation.navigate('MessageLab')}
          accessible
          accessibilityRole="button"
          accessibilityLabel="Go to Message Lab. Practice sending clearer messages."
        >
          <Text style={styles.cardTitle}>🧪 Message Lab</Text>
          <Text style={styles.cardText}>Practice sending clearer messages</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.card}
          onPress={() => navigation.navigate('ToneFilter')}
          accessible
          accessibilityRole="button"
          accessibilityLabel="Go to Tone Sensitivity. Adjust emotional tone filters."
        >
          <Text style={styles.cardTitle}>🎛️ Tone Sensitivity</Text>
          <Text style={styles.cardText}>Adjust emotional tone filters</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.card}
          onPress={() => navigation.navigate('RelationshipQuestionnaire')}
          accessible
          accessibilityRole="button"
          accessibilityLabel="Go to Relationship Profile. View and edit compatibility insights."
        >
          <Text style={styles.cardTitle}> Relationship Profile</Text>
          <Text style={styles.cardText}>View and edit compatibility insights</Text>
        </TouchableOpacity>
      </ScrollView>

      <TouchableOpacity
        style={styles.settingsButton}
        onPress={() => navigation.navigate('Settings')}
        accessible
        accessibilityRole="button"
        accessibilityLabel="Go to Settings"
      >
        <Text style={styles.settingsText}>⚙️ Settings</Text>
      </TouchableOpacity>

      <ScrollView style={{ backgroundColor: '#EFEAFE', padding: 20 }}>
        <View style={styles.promptContainer} accessible accessibilityLabel="Saved profiles prompt">
          <Text style={styles.promptText}>
            Welcome! Here you can view all the profiles you've saved. Tap a profile to see more details or save new ones from the results screen.
          </Text>
        </View>
        <Text style={{ fontSize: 20, fontWeight: '600' }} accessibilityRole="header">
          🧠 Saved Profiles
        </Text>
        {savedProfiles.length === 0 ? (
          <Text style={{ marginTop: 20 }}>No profiles saved yet.</Text>
        ) : (
          savedProfiles.map(profile => (
            <View key={profile.id} style={styles.card} accessible accessibilityLabel={`Saved profile for ${profile.partnerName}`}>
              <Text style={styles.name}>{profile.partnerName}</Text>
              <Text style={styles.match}>{profile.personalityMatch}</Text>
              <Text style={styles.explanation}>{profile.explanation}</Text>
              <View style={styles.buttonRow}>
                <TouchableOpacity
                  onPress={() => handleEdit(profile.id, profile.partnerName)}
                  accessible
                  accessibilityRole="button"
                  accessibilityLabel={`Edit profile for ${profile.partnerName}`}
                >
                  <Text style={styles.edit}>✏️ Edit</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  onPress={() =>
                    Alert.alert('Delete?', 'Are you sure you want to remove this profile?', [
                      { text: 'Cancel' },
                      { text: 'Delete', onPress: () => handleDelete(profile.id), style: 'destructive' }
                    ])
                  }
                  accessible
                  accessibilityRole="button"
                  accessibilityLabel={`Delete profile for ${profile.partnerName}`}
                >
                  <Text style={styles.delete}>🗑 Delete</Text>
                </TouchableOpacity>
              </View>
            </View>
          ))
        )}
      </ScrollView>

      <View style={styles.analysisContainer} accessible accessibilityLabel="Message analysis section">
        <Text style={styles.analysisTitle} accessibilityRole="header">Message Analysis</Text>
        <TextInput
          style={styles.messageInput}
          placeholder="Enter your message here..."
          value={message}
          onChangeText={setMessage}
          accessible
          accessibilityLabel="Message input"
          accessibilityHint="Enter your message to analyze its tone"
        />
        <TouchableOpacity
          style={styles.analyzeButton}
          onPress={handleAnalyze}
          disabled={loadingAnalysis}
          accessible
          accessibilityRole="button"
          accessibilityLabel="Analyze message"
          accessibilityState={{ disabled: loadingAnalysis }}
        >
          <Text style={styles.analyzeButtonText}>
            {loadingAnalysis ? 'Analyzing...' : 'Analyze Message'}
          </Text>
        </TouchableOpacity>
        {analysis ? (
          <View style={styles.analysisResult} accessible accessibilityLabel={`Analysis result: ${analysis}`}>
            <Text style={styles.analysisText}>{analysis}</Text>
          </View>
        ) : null}
      </View>

      <View style={styles.section} accessible accessibilityLabel="Personality match section">
        <View style={styles.rowBetween}>
          <Text style={styles.label}>Personality match</Text>
          <TouchableOpacity
            onPress={() => {/* Show breakdown modal or screen */}}
            accessible
            accessibilityRole="button"
            accessibilityLabel="View personality match breakdown"
          >
            <Text style={styles.breakdownText}>View breakdown</Text>
          </TouchableOpacity>
        </View>
        <Text style={styles.matchResult}>{user ? `${user.displayName}'s Personality` : ''}</Text>
      </View>

      <View style={styles.section} accessible accessibilityLabel="Sensitivity section">
        <Text style={styles.label}>Sensitivity</Text>
        <View style={styles.sliderRow}>
          <Text style={styles.sliderLabel}>Less</Text>
          <Slider
            style={styles.slider}
            minimumValue={0}
            maximumValue={1}
            value={sensitivity}
            onValueChange={setSensitivity}
            minimumTrackTintColor="#b39ddb"
            maximumTrackTintColor="#fff"
            thumbTintColor="#a98ae7"
            accessible
            accessibilityLabel="Sensitivity slider"
            accessibilityHint="Adjust sensitivity from less to more"
          />
          <Text style={styles.sliderLabel}>More</Text>
        </View>
      </View>

      <View style={styles.section} accessible accessibilityLabel="Tone filter section">
        <Text style={styles.label}>Tone filter</Text>
        <View style={styles.toneRow}>
          {TONE_OPTIONS.map(option => (
            <TouchableOpacity
              key={option}
              style={[
                styles.toneBtn,
                selectedTone === option && styles.toneBtnSelected
              ]}
              onPress={() => setSelectedTone(option)}
              accessible
              accessibilityRole="button"
              accessibilityLabel={`Set tone filter to ${option}`}
              accessibilityState={{ selected: selectedTone === option }}
            >
              <Text style={[
                styles.toneBtnText,
                selectedTone === option && styles.toneBtnTextSelected
              ]}>
                {option}
              </Text>
            </TouchableOpacity>
          ))}
        </View>
      </View>

      <TouchableOpacity
        style={styles.partnerButton}
        onPress={() => navigation.navigate('PartnerDisclaimer')}
        accessible
        accessibilityRole="button"
        accessibilityLabel="Go to Partner Relationship Type"
      >
        <Text style={styles.partnerButtonText}> Partner Relationship Type</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
    paddingTop: 60,
    paddingHorizontal: 20,
  },
  title: {
    color: colors.text,
    fontSize: 26,
    fontWeight: 'bold',
    marginBottom: 8,
  },
  subtitle: {
    color: 'white',
    fontSize: 16,
    marginBottom: 20,
  },
  cardContainer: {
    paddingBottom: 30,
  },
  card: {
    backgroundColor: '#fff',
    borderRadius: 10,
    padding: 16,
    marginVertical: 10,
    shadowColor: '#000',
    shadowOpacity: 0.1,
    shadowRadius: 6,
    elevation: 2,
  },
  cardTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#6C47FF',
    marginBottom: 6,
  },
  cardText: {
    fontSize: 14,
    color: '#444',
  },
  settingsButton: {
    marginTop: 'auto',
    marginBottom: 30,
    alignItems: 'center',
  },
  settingsText: {
    color: 'white',
    fontSize: 16,
    textDecorationLine: 'underline',
  },
  name: {
    fontSize: 18,
    fontWeight: 'bold',
  },
  match: {
    fontSize: 16,
    color: '#7B61FF',
    marginVertical: 4,
  },
  explanation: {
    fontSize: 14,
    color: '#333',
  },
  center: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
    backgroundColor: '#EFEAFE',
  },
  promptContainer: {
    backgroundColor: '#D6CFFF',
    borderRadius: 8,
    padding: 12,
    marginBottom: 16,
  },
  promptText: {
    fontSize: 15,
    color: '#4B3F72',
  },
  buttonRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 10,
  },
  edit: {
    color: '#4c2c72',
    fontWeight: '500',
  },
  delete: {
    color: 'red',
    fontWeight: '500',
  },
  analysisContainer: {
    backgroundColor: '#EFEAFE',
    borderRadius: 10,
    padding: 16,
    marginTop: 20,
    shadowColor: '#000',
    shadowOpacity: 0.1,
    shadowRadius: 6,
    elevation: 2,
  },
  analysisTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#6C47FF',
    marginBottom: 12,
  },
  messageInput: {
    height: 100,
    borderColor: '#ccc',
    borderWidth: 1,
    borderRadius: 8,
    padding: 10,
    fontSize: 16,
    marginBottom: 12,
  },
  analyzeButton: {
    backgroundColor: '#6C47FF',
    borderRadius: 8,
    paddingVertical: 12,
    alignItems: 'center',
    marginBottom: 12,
  },
  analyzeButtonText: {
    color: 'white',
    fontSize: 16,
    fontWeight: 'bold',
  },
  analysisResult: {
    padding: 12,
    borderRadius: 8,
    backgroundColor: '#D6EFFF',
  },
  analysisText: {
    fontSize: 14,
    color: '#333',
  },
  section: {
    backgroundColor: 'rgba(255,255,255,0.07)',
    borderRadius: 18,
    padding: 18,
    marginBottom: 24,
  },
  label: {
    color: '#fff',
    fontSize: 18,
    fontWeight: '600',
    marginBottom: 8,
  },
  rowBetween: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  breakdownText: {
    color: '#d1c4e9',
    fontSize: 15,
  },
  matchResult: {
    color: '#fff',
    fontSize: 20,
    marginTop: 8,
    fontWeight: '500',
  },
  sliderRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 8,
  },
  sliderLabel: {
    color: '#fff',
    fontSize: 14,
    width: 40,
    textAlign: 'center',
  },
  slider: {
    flex: 1,
    marginHorizontal: 10,
  },
  toneRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 8,
  },
  toneBtn: {
    backgroundColor: '#7e57c2',
    borderRadius: 10,
    paddingVertical: 10,
    paddingHorizontal: 18,
    marginHorizontal: 4,
  },
  toneBtnSelected: {
    backgroundColor: '#b39ddb',
  },
  toneBtnText: {
    color: '#fff',
    fontWeight: '600',
    fontSize: 16,
  },
  toneBtnTextSelected: {
    color: '#4c2c72',
  },
  partnerButton: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 18,
    alignItems: 'center',
    marginVertical: 16,
  },
  partnerButtonText: {
    color: '#6C47FF',
    fontWeight: 'bold',
    fontSize: 18,
  },
});