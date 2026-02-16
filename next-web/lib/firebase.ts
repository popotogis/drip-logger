import { initializeApp, getApps } from 'firebase/app'
import { getAuth } from 'firebase/auth'
import firebase from 'firebase/compat/app'
import { getFirestore } from 'firebase/firestore'

const firebaseConfig = {
    apiKey: 'AIzaSyC23NVZRNsTQByecyemOc_ZrFpjUwWrwC8',
    authDomain: 'drip-logger.firebaseapp.com',
    projectId: 'drip-logger',
    storageBucket: 'drip-logger.firebasestorage.app',
    messagingSenderId: '875381770447',
    appId: '1:875381770447:web:4fb7b0968497a166a68fba',
    measurementId: 'G-82B1VGCCYF'
}

const app = getApps().length === 0 ? initializeApp(firebaseConfig) : getApps()[0]
const auth = getAuth(app)
const db = getFirestore(app)

export { auth, db }