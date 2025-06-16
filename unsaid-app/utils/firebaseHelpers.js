import firestore from '@react-native-firebase/firestore';

/**
 * Save an explanation to Firestore.
 * @param {string} code - The invite code.
 * @param {string} partnerName - The partner's name.
 * @param {string} explanationText - The explanation text.
 * @returns {Promise<boolean>}
 */
export const saveExplanation = async (code, partnerName, explanationText) => {
  if (!code || !partnerName || !explanationText) {
    console.error("Missing required parameters for saveExplanation");
    return false;
  }
  try {
    await firestore().collection('explainedProfiles').doc(code).set({
      partnerName,
      explanation: explanationText,
      createdAt: new Date().toISOString(),
    });
    return true;
  } catch (error) {
    console.error("Error saving to Firestore:", error);
    return false;
  }
};
