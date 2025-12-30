# APK Installation Fix Guide

## Problem: "Package conflict with an existing package"

This error occurs when:
- An app with the same package name (`com.example.reachmuslim`) is already installed
- The existing app was signed with a different key (e.g., debug vs release, or different developer)

## Solution Options

### Option 1: Uninstall Existing App (Recommended)

**On Android Device:**
1. Go to **Settings** → **Apps** (or **Application Manager**)
2. Find **"Reach Muslim"** in the app list
3. Tap on it → **Uninstall**
4. Install the new APK

**Via ADB (if device is connected):**
```bash
adb uninstall com.example.reachmuslim
```

### Option 2: Use ADB Install with Replace Flag

If you have ADB connected:
```bash
adb install -r app-release.apk
```

The `-r` flag replaces the existing app if the package name matches.

### Option 3: Increment Version Code (Already Done)

The version code has been incremented from `1` to `2` in `pubspec.yaml`:
- **Version**: `1.0.0+2`
- This allows Android to recognize it as an update

## Rebuild APK After Version Change

After incrementing the version, rebuild the APK:

```bash
flutter clean
flutter pub get
flutter build apk --release
```

The new APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

## Prevention for Future

To avoid this issue:
1. **Always uninstall previous versions** before installing a new APK
2. **Use consistent signing keys** for release builds
3. **Increment version code** for each new build (already done: now at `+2`)

## Current Package Info

- **Package Name**: `com.example.reachmuslim`
- **Version Name**: `1.0.0`
- **Version Code**: `2` (incremented)

