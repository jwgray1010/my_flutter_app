import React, { useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Alert, Share, Image } from 'react-native';
import colors from '../theme/colors';

export default function ShareProfileScreen() {
  const [includeTriggers, setIncludeTriggers] = useState(false);

  const yourType = 'Anxious';
  const partnerType = 'Avoidant';
  const compatibility = 'Challenging but transformative';
  const insight = `This dynamic can create push-pull patterns. The anxious partner seeks closeness while the avoidant withdraws under pressure. With emotional awareness and gentle boundaries, trust can grow.`;
  const triggers = [
    'Feeling ignored or left on read',
    'Sudden distance or silence',
    'Fear of abandonment',
    'Mixed signals',
  ];

  const handleShare = async () => {
    const message = `
*Unsaid Relationship Snapshot*

You: ${yourType}
Partner: ${partnerType}
Compatibility: ${compatibility}

Insight:
${insight}

${includeTriggers ? `Triggers:\n${triggers.map(t => `• ${t}`).join('\n')}` : ''}
—
Sent from *Unsaid* 
`;

    try {
      await Share.share({ message });
    } catch (error) {
      Alert.alert('Error sharing profile');
    }
  };

  return (
    <View style={styles.container} accessible accessibilityLabel="Share profile screen">
      <Text style={styles.title} accessibilityRole="header">Share Your Profile</Text>
      <Image
        source={require('../assets/logo-icon.PNG')}
        style={{ width: 48, height: 48, alignSelf: 'center', marginBottom: 16 }}
        accessible
        accessibilityLabel="Unsaid logo"
      />

      <View style={styles.card} accessible accessibilityLabel="Share options card">
        <Text style={styles.text}>
          Share your relationship snapshot with a partner or friend. You control what’s included.
        </Text>

        <TouchableOpacity
          style={includeTriggers ? styles.buttonActive : styles.button}
          onPress={() => setIncludeTriggers(!includeTriggers)}
          accessible
          accessibilityRole="button"
          accessibilityLabel={includeTriggers ? "Remove triggers from share" : "Include triggers in share"}
          accessibilityState={{ selected: includeTriggers }}
        >
          <Text style={styles.buttonText}>
            {includeTriggers ? 'Triggers Included' : 'Include Triggers'}
          </Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.shareButton}
          onPress={handleShare}
          accessible
          accessibilityRole="button"
          accessibilityLabel="Share profile now"
        >
          <Text style={styles.shareButtonText}>📤 Share Now</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
    padding: 30,
    paddingTop: 60,
  },
  title: {
    fontSize: 26,
    fontWeight: 'bold',
    color: 'white',
    marginBottom: 20,
  },
  card: {
    backgroundColor: 'white',
    borderRadius: 12,
    padding: 20,
  },
  text: {
    fontSize: 15,
    color: '#444',
    marginBottom: 20,
  },
  button: {
    backgroundColor: '#ccc',
    paddingVertical: 10,
    borderRadius: 8,
    marginBottom: 15,
  },
  buttonActive: {
    backgroundColor: '#FFD700',
    paddingVertical: 10,
    borderRadius: 8,
    marginBottom: 15,
  },
  buttonText: {
    textAlign: 'center',
    fontWeight: '600',
    color: '#333',
  },
  shareButton: {
    backgroundColor: '#6C47FF',
    paddingVertical: 14,
    borderRadius: 10,
  },
  shareButtonText: {
    color: 'white',
    textAlign: 'center',
    fontWeight: 'bold',
    fontSize: 16,
  },
});
