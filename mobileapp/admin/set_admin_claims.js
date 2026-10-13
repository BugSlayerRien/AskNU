#!/usr/bin/env node
/**
 * Simple Node script to set or clear the `admin` custom claim for a Firebase user.
 * Usage:
 *   node set_admin_claims.js --email user@example.com        # set admin=true
 *   node set_admin_claims.js --email user@example.com --remove  # set admin=false
 *   node set_admin_claims.js --uid <UID>                    # set admin=true
 *
 * Requirements:
 * - Place a service account JSON at `admin/serviceAccountKey.json`, OR
 * - Set `GOOGLE_APPLICATION_CREDENTIALS` to point at your service account key.
 * - Run `npm install firebase-admin` in the project (you already ran this).
 */

const admin = require('firebase-admin');
const fs = require('fs');

function initFirebase() {
  const keyPath = __dirname + '/serviceAccountKey.json';
  if (fs.existsSync(keyPath)) {
    const serviceAccount = require(keyPath);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
  } else {
    // Fall back to Application Default Credentials (GOOGLE_APPLICATION_CREDENTIALS)
    admin.initializeApp();
  }
}

function usage() {
  console.log('Usage: node set_admin_claims.js --email user@example.com [--remove]  OR  --uid <UID> [--remove]');
  process.exit(1);
}

function parseArgs() {
  const args = process.argv.slice(2);
  const out = { email: null, uid: null, remove: false };
  for (let i = 0; i < args.length; i++) {
    const a = args[i];
    if (a === '--email' && args[i+1]) { out.email = args[++i]; }
    else if (a === '--uid' && args[i+1]) { out.uid = args[++i]; }
    else if (a === '--remove') { out.remove = true; }
    else { usage(); }
  }
  if (!out.email && !out.uid) usage();
  return out;
}

async function setClaimByUid(uid, makeAdmin) {
  const claims = { admin: !!makeAdmin };
  await admin.auth().setCustomUserClaims(uid, claims);
  console.log(`Updated claims for uid=${uid}:`, claims);
}

async function run() {
  initFirebase();
  const { email, uid, remove } = parseArgs();
  try {
    if (email) {
      const user = await admin.auth().getUserByEmail(email);
      await setClaimByUid(user.uid, !remove);
    } else if (uid) {
      await setClaimByUid(uid, !remove);
    }
    console.log('Done.');
    process.exit(0);
  } catch (err) {
    console.error('Error:', err.message || err);
    process.exit(2);
  }
}

run();
