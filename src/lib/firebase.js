// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";
import { getStorage } from "firebase/storage";

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional

export const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: "lecasa-105ab.firebaseapp.com",
  projectId: "lecasa-105ab",
  storageBucket: "lecasa-105ab.appspot.com",
  messagingSenderId: "557730361894",
  appId: "1:557730361894:web:6dcefedbdbba0aaee6ace7",
  measurementId: "G-1464DBQL6S",
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);

export const auth = getAuth();
export const db = getFirestore();
export const storage = getStorage();
