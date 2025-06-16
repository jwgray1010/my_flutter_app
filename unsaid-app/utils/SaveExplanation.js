import { db } from './FirebaseConfig';

export async function saveExplanationToDB(code, explanationText) {
  if (!code || !explanationText) {
    console.error("Missing code or explanationText");
    return false;
  }
  try {
    await db.collection('explainedProfiles').doc(code).set({
      explanation: explanationText,
      createdAt: Date.now()
    });
    return true;
  } catch (error) {
    console.error("Error saving explanation:", error);
    return false;
  }
}
