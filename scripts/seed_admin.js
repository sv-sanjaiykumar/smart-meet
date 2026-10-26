#!/usr/bin/env node
/**
 * seed_admin.js
 * One-time script to create the Smart Meet admin account in Firebase Auth
 * and write the admin profile to Firestore.
 *
 * Usage:
 *   cd scripts
 *   node seed_admin.js
 */

const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const path = require('path');

// ── Config ─────────────────────────────────────────────────────────────────
const PROJECT_ID = 'smart-meet-779bc';
const ADMIN_EMAIL = 'admin@smartmeet.edu';
const ADMIN_PASSWORD = 'Admin@SmartMeet1';
const ADMIN_DISPLAY_NAME = 'Smart Meet Admin';

// ── Init with Service Account Key ──────────────────────────────────────────
const serviceAccount = require(path.join(__dirname, 'serviceAccountKey.json'));
initializeApp({
  credential: cert(serviceAccount),
  projectId: PROJECT_ID,
});
const auth = getAuth();
const db = getFirestore();

// ── Seed ───────────────────────────────────────────────────────────────────
async function seedAdmin() {
  console.log(`Seeding admin account: ${ADMIN_EMAIL}`);

  let uid;
  try {
    const userRecord = await auth.createUser({
      email: ADMIN_EMAIL,
      password: ADMIN_PASSWORD,
      displayName: ADMIN_DISPLAY_NAME,
      emailVerified: true,
    });
    uid = userRecord.uid;
    console.log(`✅ Firebase Auth user created: ${uid}`);
  } catch (err) {
    if (err.code === 'auth/email-already-exists') {
      const existing = await auth.getUserByEmail(ADMIN_EMAIL);
      uid = existing.uid;
      console.log(`ℹ️  Auth user already exists: ${uid}`);
    } else {
      throw err;
    }
  }

  // Write / merge Firestore admin profile
  await db.collection('users').doc(uid).set({
    uid,
    username: 'admin',
    role: 'admin',
    displayName: ADMIN_DISPLAY_NAME,
    email: ADMIN_EMAIL,
    createdAt: FieldValue.serverTimestamp(),
  }, { merge: true });

  console.log(`✅ Firestore admin profile written for uid: ${uid}`);
  console.log('');
  console.log('==============================================');
  console.log('Admin credentials (save these securely):');
  console.log(`  Email   : ${ADMIN_EMAIL}`);
  console.log(`  Password: ${ADMIN_PASSWORD}`);
  console.log('==============================================');
  console.log('IMPORTANT: Change the password after first login!');
}

seedAdmin()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('❌ Error seeding admin:', err.message);
    process.exit(1);
  });
