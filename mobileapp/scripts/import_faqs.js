import admin from 'firebase-admin';
import fs from 'fs';
import path from 'path';

const args = process.argv.slice(2);
if (args.length === 0) {
  console.error('Usage: node scripts/import_faqs.js <path-to-json> [collection]');
  process.exit(1);
}

const [fileArg, collectionArg = 'faqs'] = args;
const filePath = path.resolve(fileArg);
if (!fs.existsSync(filePath)) {
  console.error(`File not found: ${filePath}`);
  process.exit(1);
}

let serviceAccount;
if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  serviceAccount = JSON.parse(fs.readFileSync(process.env.GOOGLE_APPLICATION_CREDENTIALS, 'utf8'));
}

const credential = serviceAccount
  ? admin.credential.cert(serviceAccount)
  : admin.credential.applicationDefault();

admin.initializeApp({
  credential,
});

const db = admin.firestore();

async function run() {
  const raw = fs.readFileSync(filePath, 'utf8');
  const docs = JSON.parse(raw);
  if (!Array.isArray(docs)) {
    throw new Error('JSON payload must be an array of documents.');
  }

  console.log(`Importing ${docs.length} documents into '${collectionArg}'...`);
  for (const doc of docs) {
    const docId = doc.id ? String(doc.id) : undefined;
    const writeData = { ...doc };
    if (docId) {
      delete writeData.id;
    }
    const ref = docId ? db.collection(collectionArg).doc(docId) : db.collection(collectionArg).doc();
    await ref.set(writeData, { merge: true });
  }
  console.log('Import complete.');
}

run().catch((error) => {
  console.error('Import failed:', error);
  process.exitCode = 1;
});
