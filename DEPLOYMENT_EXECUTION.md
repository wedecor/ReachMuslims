# Firebase Deployment Execution Guide

## Pre-Deployment Status
✅ Cloud Functions dependencies installed
✅ Cloud Functions built successfully
✅ All configuration files verified

---

## Step 1: Set Firebase Project (REQUIRED)

```bash
firebase use reach-muslim-leads
```

**Expected Output:**
```
Now using project reach-muslim-leads
```

**STOP Condition:** If authentication error, run:
```bash
# If using FIREBASE_TOKEN:
export FIREBASE_TOKEN="your-token-here"
firebase login:ci --token "$FIREBASE_TOKEN"

# Or interactive login:
firebase login
```

---

## Step 2: Deploy Firestore Security Rules

```bash
firebase deploy --only firestore:rules
```

**Expected Success Output:**
```
=== Deploying to 'reach-muslim-leads'...

i  deploying firestore
i  firestore: checking firestore.rules for compilation errors...
✔  firestore: rules file firestore.rules compiled successfully
i  firestore: uploading rules firestore.rules...
✔  firestore: released rules firestore.rules to firestore.default

✔  Deploy complete!
```

**STOP Condition:** 
- If rules compilation errors appear, fix `firestore.rules` syntax
- If authentication error, complete Step 1 authentication first
- If permission error, verify Firebase project access

---

## Step 3: Deploy Cloud Functions

```bash
firebase deploy --only functions
```

**Expected Success Output:**
```
=== Deploying to 'reach-muslim-leads'...

i  deploying functions
i  functions: ensuring required API cloudfunctions.googleapis.com is enabled...
i  functions: ensuring required API cloudbuild.googleapis.com is enabled...
✔  functions: required API cloudfunctions.googleapis.com is enabled
✔  functions: required API cloudbuild.googleapis.com is enabled
i  functions: preparing functions directory for uploading...
i  functions: packaged functions (XX.XX KB) for uploading...
✔  functions: functions folder uploaded successfully
i  functions: creating Node.js 18 function onLeadAssigned(us-central1)...
i  functions: creating Node.js 18 function onLeadReassigned(us-central1)...
i  functions: creating Node.js 18 function onLeadStatusChanged(us-central1)...
i  functions: creating Node.js 18 function onFollowUpAdded(us-central1)...
✔  functions[onLeadAssigned(us-central1)] Successful create operation.
✔  functions[onLeadReassigned(us-central1)] Successful create operation.
✔  functions[onLeadStatusChanged(us-central1)] Successful create operation.
✔  functions[onFollowUpAdded(us-central1)] Successful create operation.

✔  Deploy complete!
```

**STOP Condition:**
- If build errors, check `functions/lib/` exists and contains compiled JS
- If API not enabled error, enable Cloud Functions API in Firebase Console
- If quota/billing error, verify Firebase project billing is enabled
- If timeout, retry the deployment

---

## Step 4: Verification Commands

### List Deployed Functions
```bash
firebase functions:list
```

**Expected Output:**
```
Functions in project reach-muslim-leads:

onFollowUpAdded(us-central1)
  Runtime: nodejs18
  Trigger: Event Trigger (Firestore)

onLeadAssigned(us-central1)
  Runtime: nodejs18
  Trigger: Event Trigger (Firestore)

onLeadReassigned(us-central1)
  Runtime: nodejs18
  Trigger: Event Trigger (Firestore)

onLeadStatusChanged(us-central1)
  Runtime: nodejs18
  Trigger: Event Trigger (Firestore)
```

### Check Function Logs
```bash
firebase functions:log
```

**Expected Output:** Recent function execution logs (may be empty if no triggers yet)

### Verify Firestore Rules
```bash
firebase firestore:rules:get
```

**Expected Output:** Current deployed rules content

---

## Step 5: Post-Deployment Validation Checklist

### ✅ App Startup Verification
```bash
flutter run
```

**Verify:**
- [ ] App starts without Firebase initialization errors
- [ ] Login screen appears
- [ ] No console errors related to Firebase

### ✅ Firestore Access Verification
1. Login as admin user
2. Navigate to Lead List screen
3. Verify leads load from Firestore
4. Create a new lead
5. Verify lead appears in list

**Expected Behavior:**
- Leads load successfully
- No permission denied errors
- Create/update operations work

### ✅ Function Trigger Verification
1. Assign a lead to a user (as admin)
2. Check Firebase Console → Functions → Logs
3. Verify `onLeadAssigned` function executed
4. Check Firestore → `notifications` collection
5. Verify notification document created

**Expected Behavior:**
- Function logs show execution
- Notification document created with correct `userId`
- No function errors in logs

### ✅ Notification System Verification
1. Login as user who received notification
2. Check notification badge shows unread count
3. Open notification inbox
4. Verify notification appears
5. Tap notification → verify navigation to lead detail

**Expected Behavior:**
- Notifications stream in real-time
- Unread count updates correctly
- Navigation works

---

## Deployment Complete Checklist

- [ ] Step 1: Firebase project set to `reach-muslim-leads`
- [ ] Step 2: Firestore rules deployed successfully
- [ ] Step 3: All 4 Cloud Functions deployed successfully
- [ ] Step 4: Functions listed correctly with `firebase functions:list`
- [ ] Step 5: App starts without errors
- [ ] Step 6: Firestore read/write operations work
- [ ] Step 7: Function triggers execute (check logs)
- [ ] Step 8: Notifications created and displayed

---

## Troubleshooting

### Authentication Issues
```bash
# Check current auth status
firebase login:list

# Re-authenticate if needed
firebase login

# Or use token
export FIREBASE_TOKEN="your-token"
firebase login:ci --token "$FIREBASE_TOKEN"
```

### Function Deployment Fails
```bash
# Rebuild functions
cd functions
npm run build
cd ..

# Retry deployment
firebase deploy --only functions
```

### Rules Deployment Fails
```bash
# Test rules syntax locally
firebase emulators:start --only firestore

# Check rules file syntax
firebase deploy --only firestore:rules --debug
```

---

## Final Status

**Project:** reach-muslim-leads  
**Deployed Components:**
- ✅ Firestore Security Rules
- ✅ Cloud Functions (4 functions)

**Next Steps:**
1. Enable FCM in Firebase Console (manual step)
2. Test app with real Firebase backend
3. Monitor function logs for errors
4. Verify notifications are created correctly

