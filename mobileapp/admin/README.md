# Admin scripts

This folder contains a small Node script to set or clear the `admin` custom claim for Firebase Authentication users.

Setup
- Ensure `firebase-admin` is installed (you already ran `npm install firebase-admin`).
- Place a service account JSON file at `admin/serviceAccountKey.json`, or set the environment variable:

  `GOOGLE_APPLICATION_CREDENTIALS=path/to/serviceAccountKey.json`

Usage

Run the script from the `mobileapp` folder:

```bash
# Set admin by email
node admin/set_admin_claims.js --email user@example.com

# Remove admin (set admin=false)
node admin/set_admin_claims.js --email user@example.com --remove

# Or use UID directly
node admin/set_admin_claims.js --uid <UID>
```

Notes
- The script sets a custom claim `admin: true` or `admin: false`. In your client app you should check the user's custom claims (and enforce via Firestore Rules) before showing admin UI.
