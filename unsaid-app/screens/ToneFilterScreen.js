import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Image } from 'react-native';
import colors from '../theme/colors';
import GentleIcon from '../assets/gentle.svg';
import BalanceIcon from '../assets/balance.svg';
import DirectIcon from '../assets/direct.svg';

const TONE_LEVELS = [
  { label: 'Gentle', Icon: GentleIcon, description: 'Gentle tone filter' },
  { label: 'Balance', Icon: BalanceIcon, description: 'Balanced tone filter' },
  { label: 'Direct', Icon: DirectIcon, description: 'Direct tone filter' },
];

export default function ToneFilterScreen({ selectedTone, setSelectedTone, navigation }) {
  return (
    <View style={styles.container} accessible accessibilityLabel="Tone filter screen">
      <Image
        source={require('../assets/logo-icon.PNG')}
        style={{ width: 48, height: 48, alignSelf: 'center', marginBottom: 16 }}
        accessible
        accessibilityLabel="Unsaid logo"
      />
      <Text style={styles.title} accessibilityRole="header">
        Adjust Your Tone Filter
      </Text>
      <Text style={styles.subtitle}>
        Choose how you'd like the keyboard to guide your tone.
      </Text>

      <View style={styles.row}>
        {TONE_LEVELS.map(({ label, Icon, description }) => (
          <TouchableOpacity
            key={label}
            style={[
              styles.toneBtn,
              selectedTone === label && styles.toneBtnSelected,
            ]}
            onPress={() => setSelectedTone(label)}
            accessible
            accessibilityRole="button"
            accessibilityLabel={description}
            accessibilityState={{ selected: selectedTone === label }}
          >
            <Icon
              width={36}
              height={36}
              style={{ marginBottom: 8 }}
              accessible
              accessibilityLabel={description}
            />
            <Text
              style={[
                styles.toneLabel,
                selectedTone === label && styles.toneLabelSelected,
              ]}
            >
              {label}
            </Text>
          </TouchableOpacity>
        ))}
      </View>

      <TouchableOpacity
        style={styles.saveButton}
        onPress={() => navigation.navigate('HomeScreen')}
        accessible
        accessibilityRole="button"
        accessibilityLabel="Save and return to home"
      >
        <Text style={styles.saveButtonText}>Save & Return</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#6C47FF', justifyContent: 'center', alignItems: 'center' },
  title: { color: '#fff', fontSize: 24, fontWeight: 'bold', marginBottom: 30 },
  subtitle: {
    fontSize: 15,
    color: colors.text,
    marginBottom: 30,
  },
  row: {
    flexDirection: 'row',
    justifyContent: 'center',
  },
  toneBtn: {
    alignItems: 'center',
    backgroundColor: '#a98ae7',
    borderRadius: 12,
    marginHorizontal: 10,
    padding: 16,
  },
  toneBtnSelected: {
    backgroundColor: '#FFD700',
  },
  toneLabel: {
    color: '#fff',
    fontWeight: '600',
    fontSize: 16,
  },
  toneLabelSelected: {
    color: '#6C47FF',
  },
  saveButton: {
    backgroundColor: 'white',
    paddingVertical: 14,
    borderRadius: 10,
    marginTop: 30,
    alignItems: 'center',
  },
  saveButtonText: {
    color: '#6C47FF',
    fontSize: 16,
    fontWeight: '600',
  },
});
