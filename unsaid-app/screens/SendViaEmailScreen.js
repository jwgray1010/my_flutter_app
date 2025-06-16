// SendViaEmailScreen.js
import React from 'react';
import { View, Text, Button, StyleSheet, Clipboard, Share, Image } from 'react-native';
import colors from '../theme/colors';

export default function SendViaEmailScreen({ route }) {
  const { inviteCode, partnerName } = route.params;

  const emailText = `Hey — I’ve been using an app that helps with relationship communication.\n\nUse this code to unlock our insight: ${inviteCode}\nJust go to unsaid.app and enter it.`;

  const handleCopy = () => {
    Clipboard.setString(inviteCode);
    alert("Code copied to clipboard!");
  };

  const handleEmail = () => {
    Share.share({
      message: emailText,
      title: "Unsaid Relationship Insight",
    });
  };

  return (
    <View style={styles.container} accessible accessibilityLabel="Send via email screen">
      <Image
        source={require('../assets/logo-icon.PNG')}
        style={{ width: 48, height: 48, alignSelf: 'center', marginBottom: 16 }}
        accessible
        accessibilityLabel="Unsaid logo"
      />
      <Text style={styles.header} accessibilityRole="header">Your Code:</Text>
      <Text style={styles.code} accessible accessibilityLabel={`Your code is ${inviteCode}`}>{inviteCode}</Text>
      <Text style={styles.label} accessible accessibilityLabel={`Partner: ${partnerName}`}>Partner: {partnerName}</Text>
      <Button title="Copy Code" onPress={handleCopy} accessibilityLabel="Copy code to clipboard" accessibilityRole="button" />
      <Button title="Send via Email" onPress={handleEmail} accessibilityLabel="Send code via email" accessibilityRole="button" />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { backgroundColor: colors.background },
  header: { color: 'white', fontSize: 20, marginBottom: 10 },
  code: { fontSize: 28, color: '#D3A1FF', marginBottom: 10 },
  label: { fontSize: 16, color: '#CCC', marginBottom: 20 }
});
