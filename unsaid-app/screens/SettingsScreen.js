import React, { useContext, useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, Switch, Slider, Image } from 'react-native';
import { MessageSettingsContext } from '../context/MessageSettingsContext';
import colors from '../theme/colors';

export default function SettingsScreen() {
  const { sensitivity, setSensitivity, tone, setTone } = useContext(MessageSettingsContext);
  const [customKeyboard, setCustomKeyboard] = useState(false);
  const [messagingName, setMessagingName] = useState('');
  const [showHelp, setShowHelp] = useState(false);

  return (
    <View style={styles.container} accessible accessibilityLabel="Settings screen">
      <Image
        source={require('../assets/logo-icon.PNG')}
        style={{ width: 48, height: 48, alignSelf: 'center', marginBottom: 16 }}
        accessible
        accessibilityLabel="Unsaid logo"
      />
      <Text style={styles.header} accessibilityRole="header">Settings</Text>

      <Text style={styles.label}>Sensitivity</Text>
      <Slider
        style={{ width: '100%' }}
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

      <Text style={styles.label}>Tone</Text>
      <View style={styles.toneRow}>
        {['Polite', 'Reassuring', 'Neutral'].map(option => (
          <TouchableOpacity
            key={option}
            style={[
              styles.toneBtn,
              tone === option && styles.toneBtnSelected
            ]}
            onPress={() => setTone(option)}
            accessible
            accessibilityRole="button"
            accessibilityLabel={`Set tone to ${option}`}
            accessibilityState={{ selected: tone === option }}
          >
            <Text style={[
              styles.toneBtnText,
              tone === option && styles.toneBtnTextSelected
            ]}>
              {option}
            </Text>
          </TouchableOpacity>
        ))}
      </View>

      <Text style={styles.label}>Custom Keyboard View</Text>
      <Switch
        value={customKeyboard}
        onValueChange={setCustomKeyboard}
        accessible
        accessibilityLabel="Custom keyboard view switch"
        accessibilityHint="Turn custom keyboard on or off"
      />

      <Text style={styles.label}>Name of who you are messaging</Text>
      <TextInput
        style={styles.input}
        value={messagingName}
        onChangeText={setMessagingName}
        placeholder="Enter name"
        accessible
        accessibilityLabel="Name input"
        accessibilityHint="Enter the name of the person you are messaging"
      />

      <TouchableOpacity
        style={styles.button}
        onPress={() => {/* Implement password change flow */}}
        accessible
        accessibilityRole="button"
        accessibilityLabel="Change password"
      >
        <Text style={styles.buttonText}>Change Password</Text>
      </TouchableOpacity>

      <TouchableOpacity
        style={styles.button}
        onPress={() => setShowHelp(!showHelp)}
        accessible
        accessibilityRole="button"
        accessibilityLabel="Help"
        accessibilityState={{ expanded: showHelp }}
      >
        <Text style={styles.buttonText}>Help</Text>
      </TouchableOpacity>

      {showHelp && (
        <Text style={styles.helpText}>
          To enable the custom keyboard, go to your device settings and add "Unsaid" as a keyboard. Toggle above to turn it on/off in the app.
        </Text>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { backgroundColor: colors.background },
  header: { fontSize: 28, fontWeight: 'bold', color: '#6C47FF', marginBottom: 20 },
  label: { color: '#6C47FF', fontSize: 16, fontWeight: '600', marginTop: 18 },
  toneRow: { flexDirection: 'row', marginTop: 8 },
  toneBtn: {
    backgroundColor: '#7e57c2',
    borderRadius: 10,
    paddingVertical: 10,
    paddingHorizontal: 18,
    marginHorizontal: 4,
  },
  toneBtnSelected: { backgroundColor: '#b39ddb' },
  toneBtnText: { color: '#fff', fontWeight: '600', fontSize: 16 },
  toneBtnTextSelected: { color: '#4c2c72' },
  input: {
    backgroundColor: '#fff',
    borderRadius: 10,
    padding: 10,
    marginTop: 6,
    marginBottom: 10
  },
  button: {
    marginTop: 20,
    backgroundColor: '#6C47FF',
    padding: 12,
    borderRadius: 10,
    alignItems: 'center'
  },
  buttonText: { color: '#fff', fontWeight: 'bold' },
  helpText: { color: '#6C47FF', marginTop: 16, fontSize: 15 }
});