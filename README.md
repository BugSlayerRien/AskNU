# AskNU

A Flutter app that analyzes images with Google Gemini AI. Pick a photo from your gallery or camera, send it to Gemini, and get a text description of what’s in the image.
------------------
## Features
------------------
- Pick images from gallery or camera
- Analyze images with Gemini (`gemini-1.5-flash-latest`)
- View AI-generated descriptions in the app
- API key loaded from a local `.env` file (not committed to Git)
consistency II :)

## Project structure

```--------
AskNU/
├── asknu/                 # Flutter app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── pages/         # Image analyzer UI
│   │   ├── services/      # Gemini API client
│   │   └── models/        # Response models
│   ├── .env.example       # Template for your API key
│   └── pubspec.yaml
└── README.md
```

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x)
- A [Google AI Studio](https://aistudio.google.com/apikey) API key

## Setup

1. Clone the repository:

```bash
git clone https://github.com/BugSlayerRien/AskNU.git
cd AskNU/asknu
```

2. Install dependencies:

```bash
flutter pub get
```

3. Create your local env file (do **not** commit this):

```bash
cp .env.example .env
```

4. Open `.env` and add your key:

```
GEMINI_API_KEY=your_api_key_here
```

5. Make sure `.env` is listed as an asset in `pubspec.yaml`:

```yaml
flutter:
  uses-material-design: true
  assets:
    - .env
```

6. Run the app:

```bash
flutter run
```

## Environment variables

| Variable         | Required | Description              |
|------------------|----------|--------------------------|
| `GEMINI_API_KEY` | Yes      | Google Gemini API key    |

`.env` is ignored by Git. Only `.env.example` is tracked as a template.

## Tech stack

- Flutter / Dart
- [http](https://pub.dev/packages/http) — Gemini API requests
- [image_picker](https://pub.dev/packages/image_picker) — gallery / camera
- [flutter_dotenv](https://pub.dev/packages/flutter_dotenv) — local secrets

## Security notes
.

- Never commit `.env` or real API keys
- If a key is exposed, revoke it in [Google AI Studio](https://aistudio.google.com/apikey) and create a new one

## License

This project is for personal / educational use.
