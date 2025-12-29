# iOS Firebase Setup Instructions

## Step 2: Add iOS App to Firebase Console

Since this requires manual steps in Firebase Console, follow these instructions:

### 1. Go to Firebase Console
Open: https://console.firebase.google.com/project/reach-muslim-leads

### 2. Add iOS App
1. Click the **Settings gear icon** (⚙️) next to "Project Overview"
2. Scroll down to "Your apps" section
3. Click **"Add app"** button
4. Select **iOS** platform

### 3. Register iOS App
- **iOS bundle ID**: `com.example.reachmuslim`
- **App nickname** (optional): `Reach Muslim iOS`
- **App Store ID** (optional): Leave blank for now
- Click **"Register app"**

### 4. Download GoogleService-Info.plist
1. After registration, you'll see a download button
2. Click **"Download GoogleService-Info.plist"**
3. **Important**: Save this file to: `ios/Runner/GoogleService-Info.plist`

### 5. Verify File Location
The file should be at:
```
ios/Runner/GoogleService-Info.plist
```

### 6. Note the iOS App ID
After downloading, note the iOS App ID from Firebase Console. It will look like:
```
1:586386636592:ios:xxxxxxxxxxxxxxxx
```

You'll need this for Step 3 (FlutterFire configuration).

---

## Step 3: Configure FlutterFire

After adding the iOS app to Firebase, run:

```bash
# Install FlutterFire CLI (if not already installed)
dart pub global activate flutterfire_cli

# Configure Firebase (will detect iOS and update firebase_options.dart)
flutterfire configure
```

**During configuration:**
1. Select your Firebase project: `reach-muslim-leads`
2. Select platforms: **Enable iOS** (and keep Android/Web enabled)
3. For iOS, it will detect `GoogleService-Info.plist` automatically
4. It will update `lib/firebase_options.dart` with real iOS values

**Expected Result:**
- `lib/firebase_options.dart` will have real iOS values (no placeholders)
- `firebase.json` will be updated with iOS app ID

---

## Step 4: Install CocoaPods Dependencies

After FlutterFire configuration:

```bash
cd ios
pod install
cd ..
```

**Expected Output:**
- `Podfile.lock` will be created
- Firebase iOS SDK will be installed
- All dependencies will be resolved

---

## Verification Checklist

After completing all steps:

- [ ] `ios/Runner/GoogleService-Info.plist` exists (real file, not placeholder)
- [ ] `lib/firebase_options.dart` has real iOS values (no "YOUR_IOS_API_KEY" placeholders)
- [ ] `firebase.json` includes iOS configuration with real app ID
- [ ] `ios/Podfile.lock` exists
- [ ] `ios/Runner/Info.plist` has camera and photo library permissions

---

## Next Steps

After setup is complete:

1. **Test iOS Build:**
   ```bash
   flutter build ios
   ```

2. **Run on iOS Simulator** (requires macOS):
   ```bash
   flutter run -d ios
   ```

3. **Fix Signing Issues** (if any):
   - Open `ios/Runner.xcworkspace` in Xcode
   - Go to Signing & Capabilities
   - Enable "Automatically manage signing"
   - Select your development team

---

## Troubleshooting

### "GoogleService-Info.plist not found"
- Ensure file is at `ios/Runner/GoogleService-Info.plist`
- Check file name spelling (case-sensitive)

### "CocoaPods not found"
```bash
sudo gem install cocoapods
pod setup
```

### "FlutterFire CLI not found"
```bash
dart pub global activate flutterfire_cli
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

### "Bundle ID mismatch"
- Ensure bundle ID in Firebase Console matches `com.example.reachmuslim`
- Check `ios/Runner.xcodeproj/project.pbxproj` for `PRODUCT_BUNDLE_IDENTIFIER`

