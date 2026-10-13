# AskNU

A student help app for **National University Baliwag**. Students search the school's FAQs, browse offices and categories, request documents, and ask an AI assistant when the FAQs don't have the answer. Registrar and admin staff manage the content through a built-in admin dashboard.

Built with Flutter and Firebase.

## Features

**Students**
- Sign up and sign in with email or Google, with password reset
- Search and browse FAQs by category, with bookmarks and a short AI-generated summary on each FAQ
- AI chat assistant that answers from the FAQ and handbook content, with saved conversations
- Office directory (ITSO and others) with each office's role and details
- Document request tracking
- Push notifications and an in-app notification center
- Profile and settings

**Admins**
- Manage FAQs, users and notifications
- Analytics, user activity and audit logs
- App settings, including the AI provider configuration

## Tech stack

- Flutter (Dart 3.10+)
- Firebase Auth, Cloud Firestore, Storage, Cloud Messaging, Analytics, Crashlytics
- Google Gemini (or a custom chat endpoint) for AI answers
- Node.js scripts for admin claims and for seeding FAQs and offices

## Project structure

```
AskNU/
└── mobileapp/
    ├── lib/
    │   ├── screens/       # Student screens and admin/ dashboard
    │   ├── services/      # Auth, FAQs, AI chat, analytics, audit
    │   ├── models/
    │   └── widgets/
    ├── assets/            # FAQ data, student handbook text, fonts, logo
    ├── admin/             # Script to grant admin access
    ├── scripts/           # FAQ import and office seeding
    └── firestore.rules
```

## Setup

You need the [Flutter SDK](https://docs.flutter.dev/get-started/install) and your own Firebase project.

1. Clone the repo and install dependencies:

```bash
git clone https://github.com/BugSlayerRien/AskNU.git
cd AskNU/mobileapp
flutter pub get
```

2. Connect your Firebase project. This generates `lib/firebase_options.dart` and `android/app/google-services.json`, which are gitignored:

```bash
flutterfire configure
```

3. Deploy the Firestore rules in `firestore.rules`.

4. Create the AI config document `app_config/ai` in Firestore with `provider`, `model` and `apiKey` (or `chatEndpoint`).

5. Run the app:

```bash
flutter run
```

## Admin access

Grant admin rights with a Firebase service account key stored **outside the repo**:

```bash
GOOGLE_APPLICATION_CREDENTIALS=path/to/serviceAccountKey.json node admin/set_admin_claims.js --email user@example.com
```

## Security notes

- Service account keys, `google-services.json`, `firebase_options.dart` and `.env` files are gitignored. Never commit them.
- If a key is exposed, revoke it in the Firebase or Google Cloud console and create a new one.
