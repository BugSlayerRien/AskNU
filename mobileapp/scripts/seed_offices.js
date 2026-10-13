import admin from 'firebase-admin';
import fs from 'fs';

const credential = process.env.GOOGLE_APPLICATION_CREDENTIALS
  ? admin.credential.cert(JSON.parse(fs.readFileSync(process.env.GOOGLE_APPLICATION_CREDENTIALS, 'utf8')))
  : admin.credential.applicationDefault();

admin.initializeApp({ credential });
const db = admin.firestore();

const offices = [
  {
    name: 'ITSO',
    role: 'Information Technology Services Office — manages campus IT systems, accounts and support.',
    description:
      'Supports student and staff technology needs, including account provisioning, Wi‑Fi access, email setup, NUIS access, lab resources, and troubleshooting for campus systems. Handles ID card activation and IT policy concerns.',
    services: 'NUIS/Email access, Wi‑Fi support, device troubleshooting, ID validation, lab scheduling, software access',
    location: 'IT Building, 2nd Floor',
    hours: 'Mon–Fri 8:00 AM–5:00 PM',
    email: 'itso@nu.edu',
    phone: '+63 2 1234 0001',
  },
  {
    name: 'SDAO',
    role: 'Student Affairs Office — student support, activities and welfare.',
    description:
      'Oversees student engagement, co‑curricular activities, student welfare, and student leadership opportunities. Guides students on conduct and discipline processes.',
    services: 'Student orgs, activities, conduct concerns, student welfare',
    location: 'Student Center, Ground Floor',
    hours: 'Mon–Fri 8:00 AM–5:00 PM',
    email: 'sdao@nu.edu',
    phone: '+63 2 1234 0002',
  },
  {
    name: 'Registrar',
    role: 'Handles enrollment records, transcripts and academic scheduling.',
    description:
      'Manages student records, enrollment validation, certificates of registration, transcript requests, graduation processing, and academic records inquiries.',
    services: 'Enrollment validation, TOR requests, COR issuance, graduation processing',
    location: 'Admin Building, 1st Floor',
    hours: 'Mon–Fri 8:00 AM–5:00 PM',
    email: 'registrar@nu.edu',
    phone: '+63 2 1234 0003',
  },
  {
    name: 'Treasury',
    role: 'Manages student billing, payments, and financial inquiries.',
    description:
      'Handles assessment of fees, payment confirmation, billing concerns, refunds, and student ledger questions. Coordinates payment channels and installment arrangements.',
    services: 'Billing concerns, payment posting, refunds, installment plans',
    location: 'Admin Building, 1st Floor',
    hours: 'Mon–Fri 8:00 AM–5:00 PM',
    email: 'treasury@nu.edu',
    phone: '+63 2 1234 0004',
  },
  {
    name: 'FMO',
    role: 'Facilities Management Office — oversees campus facilities and maintenance.',
    description:
      'Ensures campus facilities are safe, clean, and functional. Handles maintenance requests, room reservations support, and facility-related concerns.',
    services: 'Maintenance requests, facility concerns, room support',
    location: 'Maintenance Wing, Ground Floor',
    hours: 'Mon–Fri 8:00 AM–5:00 PM',
    email: 'fmo@nu.edu',
    phone: '+63 2 1234 0005',
  },
];

async function run() {
  const col = db.collection('offices');
  for (const office of offices) {
    const snap = await col.where('name', '==', office.name).limit(1).get();
    const now = admin.firestore.FieldValue.serverTimestamp();
    if (!snap.empty) {
      const doc = snap.docs[0];
      await doc.ref.set({ ...office, updatedAt: now }, { merge: true });
      console.log(`Updated: ${office.name}`);
    } else {
      await col.add({ ...office, createdAt: now, updatedAt: now });
      console.log(`Created: ${office.name}`);
    }
  }
  console.log('Office seed complete.');
}

run().catch((e) => {
  console.error('Seed failed:', e);
  process.exitCode = 1;
});
