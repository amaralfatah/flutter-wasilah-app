# Google Drive Backup — Cloud Console Setup

One-time setup required before the Google Drive backup feature will work.
Package name: `com.amar.wasilah`.

## 1. Get the SHA-1 signing fingerprints

Debug (used by `flutter run`):

```bash
cd android
./gradlew signingReport
```

Look for the `SHA1` line under the `debug` variant. Repeat for the `release`
variant once a release keystore exists.

## 2. Google Cloud Console

1. Go to https://console.cloud.google.com/ and select or create a project
   (the existing Firebase project for this app can be reused).
2. **APIs & Services > Library** — enable the **Google Drive API**.
3. **APIs & Services > OAuth consent screen**:
   - User type: External.
   - Scopes: add `.../auth/drive.appdata` (marked non-sensitive by Google —
     no verification review required).
4. **APIs & Services > Credentials > Create Credentials > OAuth client ID**:
   - Application type: Android.
   - Package name: `com.amar.wasilah`.
   - SHA-1 certificate fingerprint: paste the debug SHA-1 from step 1.
   - Repeat this step for the release SHA-1 once available (each
     certificate needs its own OAuth client entry).

No changes to `google-services.json` are needed for sign-in itself — that
file is currently only used for Firebase Crashlytics.

## 3. Verify

Run the app on a device or emulator with Google Play Services, open
**Setelan > Backup**, and tap **Hubungkan akun Google**. If the OAuth client
isn't configured correctly, sign-in will fail immediately with a
`GoogleSignInException` (`ApiException: 10`), which means the SHA-1/package
name pair doesn't match what's registered in Cloud Console.
