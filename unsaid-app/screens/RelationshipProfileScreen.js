import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, Image } from 'react-native';
import colors from '../theme/colors';

export default function RelationshipProfileScreen() {
  const yourType = 'Anxious';
  const partnerType = 'Avoidant';
  const compatibility = 'Challenging but transformative';
  const insight = `This dynamic can create push-pull patterns.
The anxious partner seeks closeness while the avoidant withdraws under pressure.
With emotional awareness and gentle boundaries, trust can grow.`;

  const [showTriggers, setShowTriggers] = useState(false);

  const triggers = [
    'Feeling ignored or left on read',
    'Sudden distance or silence',
    'Fear of abandonment',
    'Mixed signals',
  ];

  const heatmap = [
    { area: 'Emotional Intimacy', level: 'Strained' },
    { area: 'Independence', level: 'Strong' },
    { area: 'Trust-Building', level: 'Needs work' },
    { area: 'Verbal Affection', level: 'Compatible' },
  ];

  return (
    <ScrollView contentContainerStyle={styles.container} accessible accessibilityLabel="Relationship profile screen">
      <Image
        source={require('../assets/logo-icon.PNG')}
        style={{ width: 48, height: 48, alignSelf: 'center', marginBottom: 16 }}
        accessible
        accessibilityLabel="Unsaid logo"
      />
      <Text style={styles.title} accessibilityRole="header">Relationship Profile</Text>

      <View style={styles.card} accessible accessibilityLabel={`Your type: ${yourType}`}>
        <Text style={styles.label}>Your Type</Text>
        <Text style={styles.type}>{yourType}</Text>
      </View>

      <View style={styles.card} accessible accessibilityLabel={`Partner's type: ${partnerType}`}>
        <Text style={styles.label}>Partner’s Type</Text>
        <Text style={styles.type}>{partnerType}</Text>
      </View>

      <View style={styles.card} accessible accessibilityLabel={`Compatibility: ${compatibility}`}>
        <Text style={styles.label}>Compatibility</Text>
        <Text style={styles.description}>{compatibility}</Text>
      </View>

      <View style={styles.card} accessible accessibilityLabel={`Insight and tips: ${insight}`}>
        <Text style={styles.label}>Insight & Tips</Text>
        <Text style={styles.description}>{insight}</Text>
      </View>

      <TouchableOpacity
        style={styles.triggerButton}
        onPress={() => setShowTriggers(!showTriggers)}
        accessible
        accessibilityRole="button"
        accessibilityLabel={showTriggers ? "Hide my triggers" : "View my triggers"}
        accessibilityState={{ expanded: showTriggers }}
      >
        <Text style={styles.triggerButtonText}>
          {showTriggers ? 'Hide My Triggers' : 'View My Triggers'}
        </Text>
      </TouchableOpacity>

      {showTriggers && (
        <View style={styles.card} accessible accessibilityLabel="Your triggers">
          <Text style={styles.label}>Your Triggers</Text>
          {triggers.map((item, index) => (
            <Text key={index} style={styles.bullet}>
              • {item}
            </Text>
          ))}
        </View>
      )}

      <View style={styles.card} accessible accessibilityLabel="Strengths and struggles">
        <Text style={styles.label}>Strengths & Struggles</Text>
        {heatmap.map((item, index) => (
          <Text key={index} style={styles.bullet}>
            {item.area}: {item.level}
          </Text>
        ))}
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { backgroundColor: colors.background },
  title: { color: colors.text },
  card: {
    backgroundColor: 'white',
    borderRadius: 12,
    padding: 20,
    marginBottom: 20,
  },
  label: {
    fontSize: 16,
    color: '#6C47FF',
    marginBottom: 8,
    fontWeight: '600',
  },
  type: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#333',
  },
  description: {
    fontSize: 15,
    color: '#444',
    lineHeight: 22,
  },
  bullet: {
    fontSize: 15,
    color: '#333',
    marginTop: 4,
  },
  triggerButton: {
    backgroundColor: '#FFD700',
    paddingVertical: 12,
    borderRadius: 10,
    marginBottom: 20,
  },
  triggerButtonText: {
    color: '#333',
    fontSize: 16,
    fontWeight: '600',
    textAlign: 'center',
  },
});
