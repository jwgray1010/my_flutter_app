// Replace this with your actual Firebase config
import { initializeApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';
// import { API_KEY, AUTH_DOMAIN, ... } from '@env'; // if using dotenv

const firebaseConfig = {
  apiKey: process.env.FIREBASE_API_KEY, // or use @env
  authDomain: process.env.FIREBASE_AUTH_DOMAIN,
  projectId: process.env.FIREBASE_PROJECT_ID,
  storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.FIREBASE_APP_ID,
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

export { app, db };
