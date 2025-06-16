import { getFirestore, doc, setDoc } from 'firebase/firestore';
import { app } from '../firebaseConfig';
import { Image, StyleSheet } from 'react-native';
import colors from '../theme/colors';

const db = getFirestore(app);

function generateRandomCode(length = 6) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890';
  let code = '';
  for (let i = 0; i < length; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
}

export async function generateInviteCode(profileData) {
  let code;
  let docRef;

  do {
    code = generateRandomCode();
    docRef = doc(db, 'inviteCodes', code);
    const exists = (await docRef.get()).exists;
    if (!exists) break;
  } while (true);

  await setDoc(docRef, profileData);

  return code;
}

const styles = StyleSheet.create({
  container: { backgroundColor: colors.background },
  title: { color: colors.text },
  // ...and so on
});

// In your component's render/return:
<Image
  source={require('../assets/logo-icon.PNG')}
  style={{ width: 48, height: 48, alignSelf: 'center', marginBottom: 16 }}
  accessible
  accessibilityLabel="Unsaid logo"
/>
