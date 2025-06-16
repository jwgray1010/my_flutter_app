import React, { useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, FlatList, Alert, Image } from 'react-native';
import { db } from '../firebaseConfig';
import { doc, setDoc } from 'firebase/firestore';
import { generateInviteCode } from '../utils/generateCode';
import colors from '../theme/colors';

const attachmentTypes = [
  { type: 'Secure', description: 'Comfortable with closeness, emotionally available' },
  { type: 'Dismissive Avoidant', description: 'Values independence, avoids emotional intimacy' },
  { type: 'Anxious', description: 'Seeks reassurance, fears abandonment' },
  { type: 'Fearful Avoidant', description: 'Wants intimacy but fears rejection' }
];

export default function PartnerProfileScreen({ route }) {
  const userId = route?.params?.userId || "demoUserId";
  const [partnerName, setPartnerName] = useState('');
  const [selectedAttachment, setSelectedAttachment] = useState('');
  const [generatedCode, setGeneratedCode] = useState(null);

  const handleSave = async () => {
    if (!partnerName || !selectedAttachment) {
      Alert.alert("Missing Info", "Please enter a name and select an attachment type.");
      return;
    }

    try {
      await setDoc(doc(db, 'users', userId, 'relationships', 'partnerProfile'), {
        partnerName,
        attachmentType: selectedAttachment
      });
      Alert.alert("Saved", "Your partner's profile has been saved.");
    } catch (error) {
      Alert.alert("Error", error.message);
    }
  };

  const handleShare = async () => {
    if (!partnerName || !selectedAttachment) {
      Alert.alert("Missing Info", "Please enter a name and select an attachment type.");
      return;
    }

    const profile = {
      partnerName,
      explanation: `This person may pull away during conflict to feel safe. They aren’t pushing you away — they’re protecting themselves.`,
      personalityMatch: selectedAttachment,
    };

    try {
      const code = await generateInviteCode(profile);
      setGeneratedCode(code);
      Alert.alert("Invite Code", `Share this code: ${code}`);
    } catch (error) {
      Alert.alert("Error", "Could not generate invite code.");
    }
  };

  return (
    <View style={styles.container} accessible accessibilityLabel="Partner profile screen">
      <Image
        source={require('../assets/logo-icon.PNG')}
        style={{ width: 48, height: 48, alignSelf: 'center', marginBottom: 16 }}
        accessible
        accessibilityLabel="Unsaid logo"
      />
      <Text style={styles.header} accessibilityRole="header">
        Partner Profile
      </Text>

      <Text style={styles.label}>Partner's Name</Text>
      <TextInput
        style={styles.input}
        value={partnerName}
        onChangeText={setPartnerName}
        placeholder="e.g. Jamie"
        accessible
        accessibilityLabel="Partner's name input"
        accessibilityHint="Enter your partner's name"
      />

      <Text style={styles.label}>Attachment Style</Text>
      <FlatList
        data={attachmentTypes}
        keyExtractor={item => item.type}
        renderItem={({ item }) => (
          <TouchableOpacity
            style={[
              styles.option,
              selectedAttachment === item.type && styles.selectedOption
            ]}
            onPress={() => setSelectedAttachment(item.type)}
            accessible
            accessibilityRole="button"
            accessibilityLabel={`Select ${item.type} attachment style`}
            accessibilityState={{ selected: selectedAttachment === item.type }}
          >
            <Text style={styles.optionText}>{item.type}</Text>
            <Text style={styles.optionDesc}>{item.description}</Text>
          </TouchableOpacity>
        )}
      />

      <TouchableOpacity
        style={styles.saveButton}
        onPress={handleSave}
        accessible
        accessibilityRole="button"
        accessibilityLabel="Save partner profile"
      >
        <Text style={styles.saveText}>Save</Text>
      </TouchableOpacity>

      <TouchableOpacity
        style={styles.saveButton}
        onPress={handleShare}
        accessible
        accessibilityRole="button"
        accessibilityLabel="Generate invite code"
      >
        <Text style={styles.saveText}>Generate Invite Code</Text>
      </TouchableOpacity>

      {generatedCode && (
        <View style={{ marginTop: 20 }}>
          <Text style={{ color: '#fff', fontWeight: 'bold' }}>
            Invite Code: {generatedCode}
          </Text>
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { backgroundColor: colors.background, flex: 1, padding: 20 },
  header: { fontSize: 28, fontWeight: 'bold', color: '#fff', marginBottom: 20 },
  label: { color: '#fff', marginTop: 10, fontWeight: '600' },
  input: {
    backgroundColor: '#fff',
    borderRadius: 10,
    padding: 10,
    marginTop: 6,
    marginBottom: 10
  },
  option: {
    backgroundColor: '#eee',
    borderRadius: 8,
    padding: 10,
    marginTop: 10
  },
  selectedOption: {
    backgroundColor: '#dcd0f7'
  },
  optionText: {
    fontWeight: '600',
    fontSize: 16
  },
  optionDesc: {
    fontSize: 12,
    color: '#333'
  },
  saveButton: {
    marginTop: 20,
    backgroundColor: '#5a3bb4',
    padding: 12,
    borderRadius: 10,
    alignItems: 'center'
  },
  saveText: {
    color: '#fff',
    fontWeight: 'bold'
  }
});
