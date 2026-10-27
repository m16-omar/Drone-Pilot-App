# Drone Pilot — App Store & Google Play Publishing Guide

This guide details the complete release process for publishing **Drone Pilot** (`com.dronepilot.app`) to the **Apple App Store** and **Google Play Store**.

---

## 1. Application Identity & Metadata

| Platform | Field | Value |
|---|---|---|
| **All** | App Name | **Drone Pilot** |
| **All** | Version / Build | `1.0.0+1` (Set in `pubspec.yaml`) |
| **Android** | Package / Application ID | `com.dronepilot.app` |
| **Android** | Minimum SDK | `24` (Android 7.0 Nougat) |
| **Android** | Target / Compile SDK | Target `35` (Android 15), Compile `36` |
| **iOS** | Bundle Identifier | `com.dronepilot.app` |
| **iOS** | Minimum iOS Version | `14.0` |
| **iOS** | Export Encryption | `ITSAppUsesNonExemptEncryption = false` |

---

## 2. Privacy & Platform Permissions

Both stores require justifications for network and location capabilities used by the drone hardware link:

### iOS (`ios/Runner/Info.plist`)
- **Local Network (`NSLocalNetworkUsageDescription`)**:
  > *"Drone Pilot requires local network access to communicate with your drone hardware and stream real-time UDP telemetry."*
- **Location (`NSLocationWhenInUseUsageDescription`)**:
  > *"Drone Pilot uses location services for drone return-to-home GPS navigation and local Wi-Fi drone beacon discovery."*
- **Non-Exempt Encryption (`ITSAppUsesNonExemptEncryption`)**:
  > Set to `<false/>` to bypass standard encryption export documentation prompts.

### Android (`android/app/src/main/AndroidManifest.xml`)
- `android.permission.INTERNET`
- `android.permission.ACCESS_NETWORK_STATE`
- `android.permission.ACCESS_WIFI_STATE`
- `android.permission.CHANGE_WIFI_MULTICAST_STATE`
- `android.permission.ACCESS_FINE_LOCATION` (Required on Android 10+ for Wi-Fi SSID detection)
- `android.permission.ACCESS_COARSE_LOCATION`
- `android:usesCleartextTraffic="true"` (Allows local SoftAP UDP/HTTP communication on `192.168.4.1` / `127.0.0.1`)

---

## 3. App Launcher Icons

High-resolution aeronautical icons have been generated and configured across all densities:

- **Master 1024x1024 Icon**: `app/assets/icon/app_icon.png`
- **iOS Asset Catalog**: `app/ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- **Android Mipmap Catalog**: `app/android/app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png`

---

## 4. Google Play Store Release (Android)

### Step 1: Generate Release Keystore
If you haven't already created an upload keystore:
```bash
keytool -genkey -v -keystore app/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```
*Keep your keystore and passwords safe in a password manager. Do NOT commit the `.jks` file to Git.*

### Step 2: Configure `key.properties`
Copy the included template:
```bash
cp app/android/key.properties.example app/android/key.properties
```
Edit `app/android/key.properties` with your credentials:
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=../upload-keystore.jks
```

### Step 3: Build Android App Bundle (AAB)
```bash
cd app
flutter clean
flutter pub get
flutter build appbundle --release
```
The output file will be at:
`app/build/app/outputs/bundle/release/app-release.aab`

### Step 4: Upload to Google Play Console
1. Navigate to [Google Play Console](https://play.google.com/console).
2. Create or select **Drone Pilot**.
3. Go to **Release > Internal testing** (or **Production**).
4. Create a new release and upload `app-release.aab`.
5. Fill out store listing details, content rating, and privacy policy.

---

## 5. Apple App Store Release (iOS)

### Step 1: Open Xcode Project & Configure Signing
```bash
open app/ios/Runner.xcworkspace
```
1. Select the **Runner** project in the navigator.
2. In the **Signing & Capabilities** tab:
   - Check **Automatically manage signing**.
   - Select your registered **Apple Developer Team**.
   - Confirm Bundle Identifier is `com.dronepilot.app`.

### Step 2: Build iOS Archive / IPA
From terminal:
```bash
cd app
flutter build ipa --release
```
*Or directly in Xcode:*
1. Select **Product > Destination > Any iOS Device (arm64)**.
2. Select **Product > Archive**.
3. Once archiving completes, Xcode Organizer will open.

### Step 3: Distribute to TestFlight & App Store
1. In Xcode Organizer, select the latest archive and click **Distribute App**.
2. Select **App Store Connect** > **Upload**.
3. Once processing finishes (5–10 minutes), open [App Store Connect](https://appstoreconnect.apple.com).
4. Assign build to TestFlight internal testers or prepare App Store version submission.

---

## 6. Pre-flight Verification Checklist

- [x] Bundle IDs match on iOS and Android (`com.dronepilot.app`)
- [x] High-resolution app launcher icons installed across all device scales
- [x] Zero static analysis issues (`flutter analyze` exit 0)
- [x] 100% test pass rate (`flutter test` exit 0)
- [x] iOS release build verified (`flutter build ios --release --no-codesign`)
- [x] Android release APK & AAB verified (`flutter build appbundle --release`)
- [x] Network & GPS privacy usage descriptions configured
