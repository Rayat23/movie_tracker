# Movie Tracker Firebase Setup

Movie Tracker can run in two modes:

- **Local-only mode**: no Firebase configuration is supplied. Profiles stay on the current browser/device.
- **Account + cloud mode**: Firebase configuration is supplied at run/build time. Email/password authentication and Firestore profile backup/restore are enabled.

## Important: Flutter does not need the Firebase CDN script

When Firebase shows the Web SDK setup snippet with `<script type="module">`, do **not** paste that CDN snippet into `web/index.html` for this project. Movie Tracker is a Flutter app and uses the FlutterFire packages (`firebase_core`, `firebase_auth`, and `cloud_firestore`) directly.

Use the values inside Firebase's `firebaseConfig` object as `--dart-define` values when running or building the Flutter app.

## 1. Create a Firebase project

1. Open Firebase Console and create a project for Movie Tracker.
2. Add a **Web app** to the project.
3. Copy the Firebase web configuration values shown by Firebase.

## 2. Enable Authentication

In Firebase Console:

1. Open **Authentication**.
2. Open **Sign-in method**.
3. Enable **Email/Password**.

If local web sign-in reports that the domain is not authorized, add `localhost` under **Authentication → Settings → Authorized domains**.

## 3. Create Firestore

1. Open **Firestore Database**.
2. Create the database.
3. Deploy the repository's `firestore.rules` rules before using real user data.

The rules restrict `/users/{uid}` and its `profiles` collection so only that signed-in Firebase user can read or write the data.

### Firestore database ID

The Firebase SDK normally targets the special database ID `(default)`. If your Firebase project already has a named Firestore database, Movie Tracker can use it directly without creating another database.

Pass its ID with:

```text
--dart-define=FIREBASE_DATABASE_ID=YOUR_DATABASE_ID
```

For the current Movie Tracker Firebase project, the existing Firestore database ID is `default` (without parentheses), so use:

```text
--dart-define=FIREBASE_DATABASE_ID=default
```

This avoids creating another database or changing the billing plan.

## 4. Run with Firebase configuration

Use your Firebase project's values with `--dart-define`:

```powershell
flutter run -d web-server --web-port 8080 `
  --dart-define=FIREBASE_API_KEY=YOUR_API_KEY `
  --dart-define=FIREBASE_APP_ID=YOUR_APP_ID `
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=YOUR_SENDER_ID `
  --dart-define=FIREBASE_PROJECT_ID=YOUR_PROJECT_ID `
  --dart-define=FIREBASE_DATABASE_ID=YOUR_DATABASE_ID `
  --dart-define=FIREBASE_AUTH_DOMAIN=YOUR_PROJECT.firebaseapp.com `
  --dart-define=FIREBASE_STORAGE_BUCKET=YOUR_PROJECT.firebasestorage.app `
  --dart-define=FIREBASE_MEASUREMENT_ID=YOUR_MEASUREMENT_ID
```

For a release web build, use the same values with:

```powershell
flutter build web --release `
  --dart-define=FIREBASE_API_KEY=YOUR_API_KEY `
  --dart-define=FIREBASE_APP_ID=YOUR_APP_ID `
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=YOUR_SENDER_ID `
  --dart-define=FIREBASE_PROJECT_ID=YOUR_PROJECT_ID `
  --dart-define=FIREBASE_DATABASE_ID=YOUR_DATABASE_ID `
  --dart-define=FIREBASE_AUTH_DOMAIN=YOUR_PROJECT.firebaseapp.com `
  --dart-define=FIREBASE_STORAGE_BUCKET=YOUR_PROJECT.firebasestorage.app `
  --dart-define=FIREBASE_MEASUREMENT_ID=YOUR_MEASUREMENT_ID
```

Firebase web configuration is visible to browser users by design. **Firestore Security Rules and Authentication are the security boundary**, not hiding the Firebase web API key.

## 5. Test account isolation

1. Start Movie Tracker with Firebase configured.
2. Open **Profiles → Account & Cloud Sync**.
3. Create Account A and back up its profiles.
4. Sign out.
5. Create Account B with a different email.
6. Confirm Account B cannot restore Account A's data.
7. Sign back into Account A and restore the profiles.

## Current sync behavior

The current account foundation intentionally uses explicit controls:

- **Back Up This Device** uploads all local profiles for the signed-in account.
- **Restore From Cloud** replaces the local profile set with that account's cloud profiles after confirmation.

Automatic conflict-aware background sync will be added after the cloud data model is proven stable.
