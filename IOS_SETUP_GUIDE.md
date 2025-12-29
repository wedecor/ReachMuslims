# iOS Setup Guide

## Current Status: ❌ NOT READY

The app is **not yet configured for iOS**. Here's what's missing and what needs to be done.

---

## What's Missing

### 1. iOS Project Directory
- ❌ No `ios/` directory exists
- ❌ No Xcode project configuration
- ❌ No iOS-specific Firebase configuration file (`GoogleService-Info.plist`)

### 2. Firebase Configuration
- ❌ iOS app not added to Firebase project
- ❌ Placeholder values in `firebase_options.dart`:
  ```dart
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',  // ❌ Placeholder
    appId: 'YOUR_IOS_APP_ID',    // ❌ Placeholder
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',  // ❌ Placeholder
    projectId: 'YOUR_PROJECT_ID',  // ❌ Placeholder
    iosBundleId: 'com.example.reachmuslim',
  );
  ```

### 3. Firebase Project Configuration
- ❌ iOS app not registered in Firebase Console
- ❌ No iOS configuration in `firebase.json`

---

## Prerequisites

Before setting up iOS, you need:

1. **macOS Computer** (required for iOS development)
   - iOS development can only be done on macOS
   - Xcode is macOS-only

2. **Xcode** (latest version recommended)
   - Download from Mac App Store
   - Includes iOS Simulator and development tools

3. **Apple Developer Account** (for App Store distribution)
   - Free account: For development and testing
   - Paid account ($99/year): For App Store distribution

4. **CocoaPods** (iOS dependency manager)
   ```bash
   sudo gem install cocoapods
   ```

---

## Setup Steps

### Step 1: Create iOS Project Directory

If the `ios/` directory doesn't exist, Flutter will create it automatically when you run:

```bash
flutter create --platforms=ios .
```

**Note:** This command will:
- Create `ios/` directory
- Generate Xcode project files
- Set up basic iOS configuration

### Step 2: Add iOS App to Firebase

1. Go to [Firebase Console](https://console.firebase.google.com/project/reach-muslim-leads)
2. Click **Add app** → Select **iOS**
3. Enter iOS bundle ID: `com.example.reachmuslim`
   - **Important:** This must match the bundle ID in your iOS project
4. Download `GoogleService-Info.plist`
5. Place it in `ios/Runner/` directory

### Step 3: Configure Firebase Options

Run FlutterFire CLI to automatically configure iOS:

```bash
# Install FlutterFire CLI (if not already installed)
dart pub global activate flutterfire_cli

# Configure Firebase (will detect iOS and prompt for setup)
flutterfire configure
```

This will:
- Detect your iOS app in Firebase
- Update `lib/firebase_options.dart` with real iOS values
- Configure iOS project automatically

**Or manually update `firebase_options.dart`:**

After downloading `GoogleService-Info.plist`, extract values and update:

```dart
static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'AIza...',  // From GoogleService-Info.plist
  appId: '1:586386636592:ios:...',  // From Firebase Console
  messagingSenderId: '586386636592',
  projectId: 'reach-muslim-leads',
  iosBundleId: 'com.example.reachmuslim',
  iosClientId: '...',  // If using Google Sign-In
  iosBundleId: 'com.example.reachmuslim',
);
```

### Step 4: Install iOS Dependencies

```bash
cd ios
pod install
cd ..
```

This installs Firebase iOS SDK and other dependencies via CocoaPods.

### Step 5: Update firebase.json

Add iOS configuration to `firebase.json`:

```json
{
  "flutter": {
    "platforms": {
      "android": { ... },
      "ios": {
        "default": {
          "projectId": "reach-muslim-leads",
          "appId": "1:586386636592:ios:YOUR_IOS_APP_ID",
          "fileOutput": "ios/Runner/GoogleService-Info.plist"
        }
      },
      "dart": {
        "lib/firebase_options.dart": {
          "projectId": "reach-muslim-leads",
          "configurations": {
            "android": "...",
            "web": "...",
            "ios": "1:586386636592:ios:YOUR_IOS_APP_ID"
          }
        }
      }
    }
  }
}
```

### Step 6: Configure iOS Permissions

Update `ios/Runner/Info.plist` for required permissions:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to photos for lead management</string>

<key>NSCameraUsageDescription</key>
<string>We need camera access for lead management</string>
```

### Step 7: Test iOS Build

```bash
# Run on iOS Simulator (requires macOS)
flutter run -d ios

# Or build for iOS
flutter build ios
```

---

## iOS-Specific Considerations

### 1. Bundle ID
- Current: `com.example.reachmuslim`
- **Recommendation:** Change to your actual domain (e.g., `com.yourcompany.reachmuslim`)
- Must be unique across App Store

### 2. App Signing
- **Development:** Automatic signing (Xcode handles it)
- **Production:** Requires Apple Developer account and certificates
- Configure in Xcode: Project → Signing & Capabilities

### 3. Push Notifications
- Requires additional setup in Firebase Console
- Enable Push Notifications capability in Xcode
- Upload APNs certificate to Firebase

### 4. App Store Distribution
- Requires Apple Developer Program ($99/year)
- App Store review process (1-7 days typically)
- Different from Android Play Store

---

## Platform Comparison

| Feature | Android | iOS | Web |
|---------|---------|-----|-----|
| **Status** | ✅ Ready | ❌ Not Ready | ✅ Ready |
| **Firebase Config** | ✅ Configured | ❌ Missing | ✅ Configured |
| **Project Directory** | ✅ Exists | ❌ Missing | ✅ Exists |
| **Build Command** | `flutter build apk` | `flutter build ios` | `flutter build web` |
| **Distribution** | Play Store / APK | App Store Only | Web Server |
| **Development OS** | Any | macOS Only | Any |

---

## Quick Checklist

- [ ] macOS computer available
- [ ] Xcode installed
- [ ] CocoaPods installed (`pod --version`)
- [ ] iOS app added to Firebase Console
- [ ] `GoogleService-Info.plist` downloaded and placed in `ios/Runner/`
- [ ] `firebase_options.dart` updated with iOS values
- [ ] `ios/` directory created (`flutter create --platforms=ios .`)
- [ ] Dependencies installed (`cd ios && pod install`)
- [ ] iOS build tested (`flutter build ios`)
- [ ] Bundle ID configured correctly
- [ ] App signing configured in Xcode

---

## Troubleshooting

### "No iOS device found"
- Open Xcode → Window → Devices and Simulators
- Create a simulator or connect a physical device

### "CocoaPods not found"
```bash
sudo gem install cocoapods
pod setup
```

### "Firebase configuration error"
- Verify `GoogleService-Info.plist` is in `ios/Runner/`
- Check bundle ID matches Firebase Console
- Run `flutterfire configure` again

### "Signing error"
- Open project in Xcode: `open ios/Runner.xcworkspace`
- Go to Signing & Capabilities
- Enable "Automatically manage signing"
- Select your team

---

## Next Steps After Setup

1. **Test on iOS Simulator**
   ```bash
   flutter run -d ios
   ```

2. **Test on Physical Device**
   - Connect iPhone via USB
   - Trust computer on iPhone
   - Run: `flutter run -d <device-id>`

3. **Build for App Store**
   ```bash
   flutter build ios --release
   ```
   - Then archive in Xcode
   - Upload to App Store Connect

4. **Update Documentation**
   - Add iOS to deployment guides
   - Update `APP_UPDATE_DISTRIBUTION.md`

---

## Estimated Setup Time

- **Basic Setup:** 30-60 minutes
- **Full Configuration:** 1-2 hours
- **App Store Setup:** Additional 2-4 hours (if distributing)

---

## Related Documentation

- `APP_UPDATE_DISTRIBUTION.md` - Update distribution guide
- `DEPLOYMENT_CHECKLIST.md` - Deployment checklist
- [Flutter iOS Setup](https://docs.flutter.dev/deployment/ios)
- [Firebase iOS Setup](https://firebase.google.com/docs/ios/setup)

---

## Summary

**Current Status:** ❌ iOS is **NOT ready**

**To Make It Ready:**
1. Need macOS computer with Xcode
2. Add iOS app to Firebase Console
3. Download and configure `GoogleService-Info.plist`
4. Run `flutterfire configure` or manually update `firebase_options.dart`
5. Install CocoaPods dependencies
6. Test iOS build

**Estimated Time:** 1-2 hours for basic setup

