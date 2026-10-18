# H2Go: Water Tracker (Flutter + Firebase)

H2Go lets you log a drink with one tap, track progress toward a daily goal in ml, browse past weeks, and get daily reminder notifications.

- **Splash**: bubbly logo, winking glass, waves with rising bubbles
- **Today**: percentage, a winking glass that fills up, cup presets, "Add Glass" with undo
- **History**: week-by-week bar chart with goal line, daily average, goal card, timeline of each day's drinks (swipe to delete)
- **Settings**: daily goal (500-5000 ml), reminder times, cup choice, cloud backup, feedback

Data saved by the older glasses-based version is converted to ml on first launch.

Data is stored on the phone first (SharedPreferences). Firebase (anonymous Auth + Firestore) is an optional backup layer: if Firebase isn't configured, the app still runs and the Cloud backup row says "Unavailable".

Built and tested with Flutter 3.38.3 (Dart 3.10). Android only for now.

---

## 1. Run it

```bash
flutter pub get
flutter test          # unit + widget tests
flutter run           # on a connected phone or emulator
```

- **Application ID:** `com.sachinprabuditha.h2go` (set in `android/app/build.gradle.kts`). It **cannot** be changed after the app is published on Google Play, so change it now if you want a different one (also update `namespace` and the `MainActivity.kt` package/folder).
- **Design:** playful blue and white (Blue `#2196F3` to `#1976D2`, Sky `#90CAF9`, Mist `#E3F2FD`, a little Coral `#FF7043` for the goal line and highlights) in `lib/theme/app_theme.dart`, with a dark variant. Fredoka and Nunito are bundled, not downloaded, so the app looks the same offline. The mascot glass, splash and illustrations are drawn in code (no image assets). Wave and splash animations stop when the phone's "remove animations" accessibility setting is on.
- **Launcher icon:** the winking mascot glass on the splash-screen blue (with a white silhouette for Android 13+ themed icons), generated from `tool/make_icon.py`. To change it: `python tool/make_icon.py assets/icon` (needs Pillow), then `dart run flutter_launcher_icons`.

## 2. Android configuration (already done)

These are in place; listed so you know where they live.

- `android/app/build.gradle.kts`: core library desugaring (required by `flutter_local_notifications`), release signing from `android/key.properties` (falls back to the debug key if that file is missing).
- `android/app/src/main/AndroidManifest.xml`: app label `H2Go`, `POST_NOTIFICATIONS` and `RECEIVE_BOOT_COMPLETED` permissions, and the notification receivers so reminders survive a reboot.
- `android/app/src/main/res/drawable/ic_notification.xml`: monochrome status-bar icon, kept in release builds by `res/raw/keep.xml`.

### Local SDK workarounds (remove when you can)

This machine's Android SDK is missing two components Flutter 3.38 expects, so the build is pinned to what is installed:

| Pin | Where | Remove it after installing (Android Studio → SDK Manager) |
| --- | --- | --- |
| `ndkVersion = "27.0.12077973"` | `android/app/build.gradle.kts` | NDK `28.2.13676358`, then set `ndkVersion = flutter.ndkVersion` |
| Build Tools `36.1.0` for all modules | `android/build.gradle.kts` | Build Tools `35.0.0`, then delete that `subprojects` block |

A CI runner (GitHub Actions) downloads missing SDK parts on its own, so these pins don't hurt there.

## 3. Firebase setup

1. Create a project at <https://console.firebase.google.com>.
2. **Authentication → Sign-in method → Anonymous → Enable.**
3. **Firestore Database → Create database** (production mode), then paste `firestore.rules` from this folder into the Rules tab and publish.
4. Connect the app. Easiest route:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --platforms=android
   ```
   Check that `android/app/google-services.json` now exists and that the `com.google.gms.google-services` Gradle plugin is applied. If not, add it manually following the Firebase console's "Add Firebase to your Android app" instructions. `main.dart` calls `Firebase.initializeApp()` without options, which works on Android once `google-services.json` and the plugin are in place.
5. Add your **debug and release SHA-1** fingerprints later if you add Google sign-in (not needed for anonymous auth).

Run it: `flutter run`.

### Known limitation of anonymous auth

An anonymous account lives only on that install. If the user reinstalls or clears data, they get a new anonymous ID and can't see the old cloud data. To make backup truly restorable, add "Sign in with Google" and link it to the anonymous user (`linkWithCredential`). The Firestore layout (`users/{uid}/days/{date}`) already supports this.

---

## 4. Release build

### Create an upload key (once, keep it safe and backed up)

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -storetype JKS \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

`android/key.properties` (never commit this):

```properties
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=/home/you/upload-keystore.jks
```

`android/app/build.gradle.kts` already loads this file and signs release builds with it. On Windows, write `storeFile` with forward slashes, e.g. `C:/Users/you/upload-keystore.jks`.

### Build

```bash
flutter build appbundle --release
# output: build/app/outputs/bundle/release/app-release.aab
```

Before uploading, make sure you're targeting the API level Play currently requires (new Flutter versions normally satisfy this; Play Console will warn you if not).

---

## 5. Publishing on Google Play

1. Create a Play Console developer account (one-time registration fee).
2. **Create app** → fill in name, language, free/paid.
3. **Upload** the `.aab` to an Internal or Closed testing track first. Enroll in **Play App Signing** when prompted.
4. **Store listing**: short description (80 chars), full description, 512x512 icon, 1024x500 feature graphic, at least 2 phone screenshots.
5. **Privacy policy URL**: host `PRIVACY_POLICY.md` (e.g. GitHub Pages) and paste the link.
6. **Data safety form** (because of Firebase, answer honestly):
   - Data collected: *Device or other IDs* (Firebase anonymous user ID) and *App activity* (daily water log), both used for app functionality / backup.
   - Data is encrypted in transit.
   - Users can request deletion: Settings → Cloud backup off deletes the cloud copy (also say so in the policy).
   - Not shared with third parties for advertising.
7. **Content rating** questionnaire, **target audience** (choose 18+ / general, not children), and the **Health apps declaration** if the console asks. Describe this as a general wellness / hydration tracker, not medical.
8. **Notifications**: the app asks for `POST_NOTIFICATIONS` at runtime on Android 13+. No exact-alarm permission is used.
9. If your developer account is a new *personal* account, Google may require a closed test with a minimum number of testers for a minimum period before production access. Check the current requirement in Play Console and start the closed test early.

---

## Project layout

```
lib/
  main.dart                      app entry, theme
  data/water_store.dart          state (ml per day + timed drinks) + persistence + sync
  data/cups.dart                 cup presets (200 / 240 / 350 / 500 ml)
  data/cloud_sync.dart           Firebase anonymous auth + Firestore
  services/notification_service.dart  daily reminders
  screens/                       splash, today, history, settings, floating-nav shell
  theme/app_theme.dart           blue/white palette, light/dark Palette, fonts
  widgets/water_glass.dart       the winking mascot glass with animated water
  widgets/sporty_girl_illustration.dart  History goal card art (drawn in code)
  widgets/cup_icon.dart          small cup drawings for presets and the cup grid
  widgets/ui.dart                cards, badges, gradient button, blue header, bounce
  widgets/empty_glass_illustration.dart  History empty state (drawn in code)
test/                            WaterStore unit tests, WaterGlass widget test, API tests
android/                         Android project (app ID com.sachinprabuditha.h2go)
assets/icon/                     launcher icon sources
assets/fonts/                    Fredoka (headings, numbers) + Nunito (UI), with OFL licences
tool/make_icon.py                draws the launcher icon
firestore.rules                  security rules (user can only access own data)
PRIVACY_POLICY.md                template, edit before publishing
```
