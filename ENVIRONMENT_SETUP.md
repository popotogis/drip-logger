# Environment Setup Guide

This project uses environment variables to manage sensitive configuration like Firebase API keys.

## 1. Firebase Configuration Keys

You will need the following keys from your Firebase Console (Project Settings > General).

- `FIREBASE_API_KEY`
- `FIREBASE_AUTH_DOMAIN`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_STORAGE_BUCKET`
- `FIREBASE_MESSAGING_SENDER_ID`
- `FIREBASE_APP_ID`
- `FIREBASE_MEASUREMENT_ID`

## 2. Running Flutter App

The Flutter app expects these keys to be passed via `--dart-define` at build/runtime.

### VS Code Launch Configuration (Recommended)

Add a configuration to your `.vscode/launch.json`:

```json
{
    "name": "drip-logger (Dev)",
    "request": "launch",
    "type": "dart",
    "args": [
        "--dart-define=FIREBASE_API_KEY=YOUR_KEY_HERE",
        "--dart-define=FIREBASE_AUTH_DOMAIN=YOUR_PROJECT.firebaseapp.com",
        "--dart-define=FIREBASE_PROJECT_ID=YOUR_PROJECT_ID",
        "--dart-define=FIREBASE_STORAGE_BUCKET=YOUR_PROJECT.firebasestorage.app",
        "--dart-define=FIREBASE_MESSAGING_SENDER_ID=YOUR_SENDER_ID",
        "--dart-define=FIREBASE_APP_ID=YOUR_APP_ID",
        "--dart-define=FIREBASE_MEASUREMENT_ID=YOUR_MEASUREMENT_ID"
    ]
}
```

### Command Line

```bash
flutter run --dart-define=FIREBASE_API_KEY=... [other keys]
```

## 3. Running Next.js App

The Next.js app uses a `.env.local` file.

1.  Navigate to `next-web/`.
2.  Copy `.env.example` to `.env.local`.
    ```bash
    cp .env.example .env.local
    ```
3.  Fill in the values in `.env.local`.

```ini
NEXT_PUBLIC_FIREBASE_API_KEY=YOUR_KEY_HERE
...
```

4.  Run the server:
    ```bash
    npm run dev
    ```
