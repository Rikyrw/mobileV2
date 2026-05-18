# Google Sign-In Setup (Android & iOS)

Follow these steps to enable Google Sign-In for Android and iOS.

## Prepare OAuth credentials

1. Go to Google Cloud Console -> APIs & Services -> Credentials.
2. Create OAuth 2.0 Client IDs:
   - Web application: used for Flutter web. Add Authorized JavaScript origins (e.g. http://localhost:9222 or the port used by `flutter run -d chrome`).
   - Android: create an "Android" client ID. Set package name (e.g. `com.example.yourapp`) and add SHA-1 fingerprint.
   - iOS: create an "iOS" client ID. Set Bundle ID equal to your app's bundle identifier (e.g. `com.example.yourapp`).

3. Note values:
   - Web client ID (for `.env` or meta tag)
   - iOS client ID (to obtain reversed client id for Info.plist)
   - Android client details (no file needed for plugin but must exist with SHA-1)

## Web (already supported in code)

- Set `GOOGLE_CLIENT_ID` in `.env` to the Web client ID.
- Or put `<meta name="google-signin-client_id" content="YOUR_WEB_CLIENT_ID" />` in `web/index.html`.

## Android

1. Obtain SHA-1 fingerprint(s):

- For debug keystore (default debug):

```bash
# Windows (PowerShell)
$key = "$env:USERPROFILE\.android\debug.keystore"
& keytool -list -v -keystore $key -storepass android -alias androiddebugkey
```

- Or using Gradle (in project root):

```bash
./gradlew signingReport
```

2. In Google Cloud Console, add an Android OAuth client with your package name and SHA-1.

3. (Optional) If you prefer Firebase-style flow, download `google-services.json` and place it in `android/app/` and add Google Services plugin. For `google_sign_in` plugin alone this is not required.

4. No additional AndroidManifest changes are necessary for `google_sign_in` plugin. Ensure your app's `applicationId` (package name) matches the OAuth client entry.

## iOS

1. In Google Cloud Console create an iOS OAuth client with your app's Bundle ID.
2. In the OAuth client details you'll find a `Client ID` string like `12345-abc.apps.googleusercontent.com`.
   Reverse it to create the URL scheme: `com.googleusercontent.apps.12345-abc` (replace `/` and `:` as necessary). This is the `REVERSED_CLIENT_ID`.
3. Open `ios/Runner/Info.plist` and add a `CFBundleURLTypes` entry with `CFBundleURLSchemes` containing the `REVERSED_CLIENT_ID` (see placeholder in file).
4. Ensure `ios/Runner/Signing & Capabilities` bundle identifier matches the OAuth client bundle id.

## After configuration

- For web, ensure `.env` contains `GOOGLE_CLIENT_ID` and run:

```bash
flutter clean
flutter run -d chrome
```

- For Android/iOS, rebuild the app on device/emulator after configuring OAuth clients. For Android, ensure your SHA-1 matches the one registered.

## Common troubleshooting

- "ClientID not set" on web: make sure `.env` is loaded and contains `GOOGLE_CLIENT_ID`, or the meta tag exists in `web/index.html`.
- Android sign-in fails: check SHA-1 and package name.
- iOS: make sure URL type (reversed client id) is present in `Info.plist` and bundle id matches.

If you want, I can:
- Add the actual `REVERSED_CLIENT_ID` into `ios/Runner/Info.plist` if you paste it here.
- Add `google-services.json` placeholder to `android/app/` if you provide the file.
- Walk through generating SHA-1 on your machine.
