# Manual APK Upload to Firebase Storage

Since Android SDK needs to be configured, here are two options:

## Option 1: Upload via Firebase Console (Easiest)

1. **Build APK on another machine** (or after configuring Android SDK):
   ```bash
   flutter build apk --release
   ```
   The APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

2. **Upload via Firebase Console:**
   - Go to [Firebase Storage Console](https://console.firebase.google.com/project/reach-muslim-leads/storage)
   - Click on the **apk** folder (or create it if it doesn't exist)
   - Click **Upload file**
   - Select your `app-release.apk` file
   - After upload, right-click the file → **Get download URL**
   - Share this URL with your team

## Option 2: Use gsutil (Command Line)

If you have `gsutil` installed:

```bash
# Upload APK
gsutil cp build/app/outputs/flutter-apk/app-release.apk gs://reach-muslim-leads.appspot.com/apk/reachmuslim.apk

# Make it publicly accessible
gsutil acl ch -u AllUsers:R gs://reach-muslim-leads.appspot.com/apk/reachmuslim.apk

# Get the URL
echo "Download URL: https://storage.googleapis.com/reach-muslim-leads.appspot.com/apk/reachmuslim.apk"
```

## Option 3: Configure Android SDK (For Future Builds)

To build APKs on this machine:

1. **Install Android Studio:**
   - Download from: https://developer.android.com/studio
   - Install it

2. **Install Android SDK:**
   - Open Android Studio
   - Go to **Tools → SDK Manager**
   - Install Android SDK Platform (API 33 or higher)
   - Install Android SDK Build-Tools

3. **Set Environment Variables:**
   ```bash
   export ANDROID_HOME=$HOME/Android/Sdk
   export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
   ```
   
   Add to `~/.bashrc` or `~/.zshrc` to make it permanent.

4. **Accept Android Licenses:**
   ```bash
   flutter doctor --android-licenses
   ```

5. **Verify:**
   ```bash
   flutter doctor
   ```

6. **Then build:**
   ```bash
   flutter build apk --release
   ```

## Current Status

✅ Firebase Storage enabled
✅ Storage rules deployed (public read access for APK files)
⏳ Android SDK needs configuration for building APK

Once you have an APK file (from any source), you can upload it using Option 1 or 2 above.

