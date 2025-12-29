# Deploy APK to Firebase Storage - Guide

This guide will help you build and deploy the APK to Firebase Storage so team members can download it.

## Prerequisites

1. **Android SDK configured** (for building APK)
2. **Firebase CLI installed and logged in**
3. **Firebase Storage enabled** in your Firebase project

## Step 1: Enable Firebase Storage

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `reach-muslim-leads`
3. Go to **Storage** in the left menu
4. Click **Get Started** if not already enabled
5. Start in **production mode** (we'll set rules below)

## Step 2: Set Firebase Storage Rules

Create or update `storage.rules` file:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Allow public read access to APK files
    match /apk/{fileName} {
      allow read: if true;
      allow write: if request.auth != null && 
                      request.auth.token.role == 'admin';
    }
  }
}
```

Deploy the rules:
```bash
firebase deploy --only storage
```

## Step 3: Build and Deploy APK

### Option A: Using the automated script

```bash
./deploy_apk.sh
```

### Option B: Manual steps

1. **Build the APK:**
   ```bash
   flutter build apk --release
   ```

2. **Upload to Firebase Storage:**
   ```bash
   firebase storage:upload build/app/outputs/flutter-apk/app-release.apk gs://reach-muslim-leads.appspot.com/apk/reachmuslim.apk
   ```

3. **Make it publicly accessible:**
   ```bash
   gsutil acl ch -u AllUsers:R gs://reach-muslim-leads.appspot.com/apk/reachmuslim.apk
   ```

4. **Get the download URL:**
   ```
   https://storage.googleapis.com/reach-muslim-leads.appspot.com/apk/reachmuslim.apk
   ```

## Step 4: Share with Team

Share the download URL with your team members. They can:
1. Open the URL on their Android device
2. Download the APK
3. Install it (may need to enable "Install from unknown sources")

## Alternative: Using Firebase Hosting

If you prefer, you can also host the APK via Firebase Hosting for easier access.

