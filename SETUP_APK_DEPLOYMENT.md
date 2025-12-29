# Setup APK Deployment to Firebase Storage

## Step 1: Enable Firebase Storage

1. Go to [Firebase Console](https://console.firebase.google.com/project/reach-muslim-leads/storage)
2. Click **Get Started**
3. Choose **Start in production mode** (we'll set custom rules)
4. Select a location (choose the same region as your Firestore)
5. Click **Done**

## Step 2: Deploy Storage Rules

After enabling Storage, deploy the security rules:

```bash
firebase deploy --only storage
```

This will allow:
- **Public read access** to APK files (anyone can download)
- **Admin-only write access** (only admins can upload APKs)

## Step 3: Install Google Cloud SDK (for gsutil)

If you don't have `gsutil` installed:

### On Linux:
```bash
# Download and install Google Cloud SDK
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
gcloud init
```

### Or use Firebase CLI (alternative):
You can also upload via Firebase Console manually.

## Step 4: Build and Deploy APK

### Option A: Automated Script (Recommended)

```bash
./deploy_apk.sh
```

This script will:
1. Build the release APK
2. Upload it to Firebase Storage with version name
3. Make it publicly accessible
4. Provide you with the download URL

### Option B: Manual Steps

1. **Build APK:**
   ```bash
   flutter build apk --release
   ```

2. **Upload via Firebase Console:**
   - Go to [Firebase Storage Console](https://console.firebase.google.com/project/reach-muslim-leads/storage)
   - Create a folder named `apk`
   - Upload `build/app/outputs/flutter-apk/app-release.apk`
   - Right-click the file → **Get download URL**

3. **Or upload via gsutil:**
   ```bash
   gsutil cp build/app/outputs/flutter-apk/app-release.apk gs://reach-muslim-leads.appspot.com/apk/reachmuslim.apk
   gsutil acl ch -u AllUsers:R gs://reach-muslim-leads.appspot.com/apk/reachmuslim.apk
   ```

## Step 5: Share Download URL

Once uploaded, the APK will be available at:
```
https://storage.googleapis.com/reach-muslim-leads.appspot.com/apk/[filename].apk
```

Share this URL with your team members. They can:
1. Open the URL on their Android device
2. Download the APK
3. Install it (enable "Install from unknown sources" if needed)

## Troubleshooting

### Android SDK not found
If you see "No Android SDK found":
1. Install Android Studio
2. Set `ANDROID_HOME` environment variable:
   ```bash
   export ANDROID_HOME=$HOME/Android/Sdk
   export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
   ```

### gsutil not found
Install Google Cloud SDK or use Firebase Console to upload manually.

### Permission denied
Make sure you're logged in:
```bash
firebase login
gcloud auth login
```

