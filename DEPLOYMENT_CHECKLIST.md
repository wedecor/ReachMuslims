# Firebase Deployment Checklist

## Project Details
- **Firebase Project ID**: `reach-muslim-leads`
- **Android Package**: `com.example.reachmuslim`
- **Platforms**: Android + Web
- **Environment**: Production

---

## ✅ Pre-Deployment Verification

### Step 1: Verify Firebase Initialization
- [x] `lib/main.dart` uses `Firebase.initializeApp()` with `DefaultFirebaseOptions.currentPlatform`
- [x] `lib/firebase_options.dart` contains `projectId: 'reach-muslim-leads'` for Android and Web
- [x] `android/app/google-services.json` exists (DO NOT regenerate)

**Verification Command:**
```bash
grep -q "projectId.*reach-muslim-leads" lib/firebase_options.dart && echo "✓ Correct projectId" || echo "✗ projectId mismatch"
```

### Step 2: Verify Android Gradle Setup
- [x] `android/settings.gradle.kts` has `id("com.google.gms.google-services")` plugin
- [x] `android/app/build.gradle.kts` applies `com.google.gms.google-services` plugin
- [x] `android/app/google-services.json` exists

**Verification Commands:**
```bash
# Check settings.gradle.kts
grep -q "google-services" android/settings.gradle.kts && echo "✓ Plugin configured" || echo "✗ Missing plugin"

# Check app/build.gradle.kts
grep -q "google-services" android/app/build.gradle.kts && echo "✓ Plugin applied" || echo "✗ Plugin not applied"

# Check google-services.json
test -f android/app/google-services.json && echo "✓ google-services.json exists" || echo "✗ File missing"
```

### Step 3: Verify Firebase Configuration Files
- [x] `.firebaserc` exists with project: `reach-muslim-leads`
- [x] `firebase.json` configured for Firestore rules and Functions
- [x] `firestore.rules` file created

**Verification Commands:**
```bash
# Check .firebaserc
cat .firebaserc | grep -q "reach-muslim-leads" && echo "✓ .firebaserc correct" || echo "✗ .firebaserc incorrect"

# Check firebase.json
test -f firebase.json && echo "✓ firebase.json exists" || echo "✗ firebase.json missing"

# Check firestore.rules
test -f firestore.rules && echo "✓ firestore.rules exists" || echo "✗ firestore.rules missing"
```

### Step 4: Verify Cloud Functions Setup
- [x] `functions/package.json` has correct dependencies
- [x] `functions/src/index.ts` contains all Cloud Functions
- [x] `functions/tsconfig.json` configured

**Verification Commands:**
```bash
cd functions
npm list firebase-admin firebase-functions 2>/dev/null | grep -E "(firebase-admin|firebase-functions)" && echo "✓ Dependencies installed" || echo "✗ Dependencies missing"
cd ..
```

---

## 🚀 Deployment Commands

### Step 5: Install Cloud Functions Dependencies
```bash
cd functions
npm install
cd ..
```

**Success Indicator:** No errors, `node_modules/` directory created

### Step 6: Build Cloud Functions
```bash
cd functions
npm run build
cd ..
```

**Success Indicator:** `functions/lib/` directory created with compiled JavaScript

**Failure Indicator:** TypeScript compilation errors (fix before proceeding)

### Step 7: Deploy Firestore Security Rules
```bash
firebase deploy --only firestore:rules
```

**Success Indicator:** 
```
✔  firestore: released rules firestore.rules to firestore.default
```

**Failure Indicator:** 
- Rules syntax errors (test with `firebase emulators:start`)
- Authentication errors (run `firebase login`)

### Step 8: Deploy Cloud Functions
```bash
firebase deploy --only functions
```

**Success Indicator:**
```
✔  functions[onLeadAssigned(us-central1)] Successful create operation.
✔  functions[onLeadReassigned(us-central1)] Successful create operation.
✔  functions[onLeadStatusChanged(us-central1)] Successful create operation.
✔  functions[onFollowUpAdded(us-central1)] Successful create operation.
```

**Failure Indicator:**
- Build errors (fix TypeScript issues)
- Quota errors (check Firebase billing)
- Permission errors (verify Firebase CLI authentication)

### Step 9: Enable FCM for Android (Firebase Console)
**Note:** This must be done in Firebase Console, not via CLI.

1. Go to: https://console.firebase.google.com/project/reach-muslim-leads/settings/cloudmessaging
2. Under "Cloud Messaging API (Legacy)", click "Enable"
3. Under "Cloud Messaging API (V1)", click "Enable"
4. Verify Android app is registered with package: `com.example.reachmuslim`

**Alternative CLI Check (if API enabled):**
```bash
# This will show if FCM is accessible (may require gcloud CLI)
# Note: FCM enablement is primarily done via Console
```

---

## 🔍 Post-Deployment Verification

### Step 10: Verify Firestore Rules
```bash
# Test rules with emulator (optional)
firebase emulators:start --only firestore
# Then test your app against emulator
```

### Step 11: Verify Cloud Functions
```bash
# Check function logs
firebase functions:log

# List deployed functions
firebase functions:list
```

**Expected Functions:**
- `onLeadAssigned`
- `onLeadReassigned`
- `onLeadStatusChanged`
- `onFollowUpAdded`

### Step 12: Test App Connection
1. Run Flutter app: `flutter run`
2. Attempt login
3. Verify Firestore reads/writes work
4. Create a lead and verify notification triggers

---

## ⚠️ Important Notes

1. **DO NOT** regenerate `google-services.json` - it's already configured
2. **DO NOT** change Android package name
3. **DO NOT** deploy iOS configuration (not set up yet)
4. **DO NOT** commit `node_modules/` or `functions/lib/` to git
5. FCM enablement requires Firebase Console access (not CLI)

---

## 🐛 Troubleshooting

### Firestore Rules Deployment Fails
- Check syntax: `firebase deploy --only firestore:rules --debug`
- Test locally: `firebase emulators:start --only firestore`

### Cloud Functions Deployment Fails
- Check TypeScript errors: `cd functions && npm run build`
- Verify Node version: `node --version` (should be 18+)
- Check Firebase CLI auth: `firebase login:list`

### FCM Not Working
- Verify API enabled in Console
- Check Android app registration
- Verify `google-services.json` is in `android/app/`
- Check app logs for FCM token generation

---

## 📋 Quick Reference

**Firebase Console:** https://console.firebase.google.com/project/reach-muslim-leads

**Project ID:** `reach-muslim-leads`

**Android App ID:** `1:586386636592:android:f16b3f846aa31d534592f5`

**Web App ID:** `1:586386636592:web:4be4cb2af65c78e74592f5`

