# Post-Deployment Validation Guide

## Project: reach-muslim-leads
## Purpose: Validate Firebase backend deployment and app functionality

---

## Prerequisites

- [ ] Firebase CLI authenticated: `firebase login:list` shows account
- [ ] Flutter app dependencies installed: `flutter pub get`
- [ ] Test user accounts created in Firestore:
  - Admin user (role: admin, active: true)
  - Sales user (role: sales, active: true)
- [ ] Physical device or emulator ready for testing

---

## VALIDATION 1: APP STARTUP

### Command
```bash
flutter run
```

### Expected Output
```
Launching lib/main.dart on [device] in debug mode...
Running Gradle task 'assembleDebug'...
✓ Built build/app/outputs/flutter-apk/app-debug.apk (XX.XMB).
Flutter run key commands.
```

### Expected App Behavior
1. App launches without crash
2. No Firebase initialization errors in console
3. Login screen appears with:
   - Email input field
   - Password input field
   - Login button

### PASS Criteria
- ✅ App launches successfully
- ✅ No console errors containing "Firebase", "Firestore", or "Authentication"
- ✅ Login screen UI renders correctly

### FAIL Conditions
- ❌ App crashes on startup
- ❌ Console shows: "FirebaseException", "PlatformException", or initialization errors
- ❌ Blank screen or error screen appears

### Troubleshooting (if FAIL)
```bash
# Check Firebase initialization
grep -A 5 "Firebase.initializeApp" lib/main.dart

# Verify firebase_options.dart exists
test -f lib/firebase_options.dart && echo "✓ File exists" || echo "✗ Missing"

# Check for compilation errors
flutter analyze lib/

# Verify google-services.json
test -f android/app/google-services.json && echo "✓ File exists" || echo "✗ Missing"
```

---

## VALIDATION 2: FIRESTORE ACCESS

### Step 2.1: Login as Admin User

#### Command
```
Manual: Enter admin credentials in app
```

#### Expected Behavior
1. Enter admin email and password
2. Tap "Login" button
3. Loading indicator appears briefly
4. Admin Home Screen appears showing:
   - Welcome message with admin name
   - User details (email, role, region)
   - "View Leads" button

#### PASS Criteria
- ✅ Login succeeds without errors
- ✅ Admin Home Screen appears
- ✅ User information displays correctly

#### FAIL Conditions
- ❌ "Login failed" error message
- ❌ "User document not found" error
- ❌ "User account is inactive" error
- ❌ Stuck on loading screen

#### Troubleshooting (if FAIL)
```bash
# Verify user exists in Firestore
firebase firestore:get users/[ADMIN_UID]

# Check Firestore rules allow read
firebase firestore:rules:get | grep -A 5 "users"

# Verify user document structure
# Should have: name, email, role: "admin", region, active: true
```

---

### Step 2.2: Load Leads from Firestore

#### Command
```
Manual: Tap "View Leads" button in Admin Home Screen
```

#### Expected Behavior
1. Lead List Screen appears
2. Loading indicator shows briefly
3. Leads list displays (may be empty if no leads exist)
4. No error messages

#### Console Check
```bash
# Monitor Flutter logs while navigating
flutter logs
```

#### Expected Console Output
```
No errors containing:
- "Permission denied"
- "FirestoreException"
- "Missing or insufficient permissions"
```

#### PASS Criteria
- ✅ Lead List Screen appears
- ✅ No "permission denied" errors
- ✅ Leads load successfully (empty list is OK)
- ✅ Screen shows filters and search bar

#### FAIL Conditions
- ❌ "Permission denied" error
- ❌ "Missing or insufficient permissions" error
- ❌ Blank screen with error message
- ❌ Infinite loading spinner

#### Troubleshooting (if FAIL)
```bash
# Check Firestore rules for leads collection
firebase firestore:rules:get | grep -A 10 "leads"

# Verify admin user region matches lead region
# Admin can only read leads in their region

# Test rules with emulator
firebase emulators:start --only firestore
# Then test app against emulator
```

---

### Step 2.3: Create Lead

#### Command
```
Manual: 
1. Tap "Create Lead" button (admin only)
2. Fill form:
   - Name: "Test Lead Validation"
   - Phone: "1234567890"
   - Location: "Test Location" (optional)
   - Region: Select admin's region
   - Status: New
   - Assigned To: Optional
3. Tap "Create Lead" button
```

#### Expected Behavior
1. Form validates successfully
2. Loading indicator appears
3. Success message: "Lead created successfully!"
4. Navigates back to Lead List
5. New lead appears in list

#### Console Check
```bash
flutter logs | grep -i "lead\|firestore\|error"
```

#### Expected Console Output
```
No errors. May show:
- "Lead created successfully"
- Firestore write confirmation (if debug logging enabled)
```

#### PASS Criteria
- ✅ Lead creation succeeds
- ✅ Success message appears
- ✅ Lead appears in list
- ✅ No Firestore write errors

#### FAIL Conditions
- ❌ "Failed to create lead" error
- ❌ "Permission denied" error
- ❌ Form validation errors (check phone format)
- ❌ Lead doesn't appear in list

#### Troubleshooting (if FAIL)
```bash
# Check Firestore rules for create permission
firebase firestore:rules:get | grep -A 5 "allow create"

# Verify lead document structure
firebase firestore:get leads/[LEAD_ID]

# Check function logs for errors
firebase functions:log | grep -i error
```

---

## VALIDATION 3: FUNCTION TRIGGERS

### Step 3.1: Assign Lead and Verify Function Execution

#### Command
```
Manual:
1. Open Lead Detail Screen (tap on a lead)
2. As admin, select user from "Assigned To" dropdown
3. Wait 5-10 seconds
```

#### Expected Behavior
1. Assignment dropdown updates
2. Success message: "Lead assigned successfully"
3. Lead detail shows updated assignment

#### Verify Function Execution
```bash
# Check Cloud Function logs
firebase functions:log --limit 10
```

#### Expected Log Output
```
Function execution logs showing:
onLeadAssigned
  Execution: [timestamp]
  Status: success
  Duration: [X]ms
```

#### Verify Notification Creation
```bash
# Check Firestore for notification
firebase firestore:get notifications --limit 1 --order-by createdAt desc
```

#### Expected Notification Document
```json
{
  "userId": "[ASSIGNED_USER_UID]",
  "leadId": "[LEAD_ID]",
  "type": "leadAssigned",
  "title": "New Lead Assigned",
  "body": "You have been assigned to lead: [LEAD_NAME]",
  "read": false,
  "createdAt": "[TIMESTAMP]"
}
```

#### PASS Criteria
- ✅ Function `onLeadAssigned` executes (check logs)
- ✅ Notification document created in Firestore
- ✅ Notification has correct `userId` (assigned user)
- ✅ No function execution errors in logs

#### FAIL Conditions
- ❌ Function doesn't appear in logs
- ❌ Function shows error status
- ❌ Notification document not created
- ❌ Notification has wrong `userId`

#### Troubleshooting (if FAIL)
```bash
# Check if function is deployed
firebase functions:list | grep onLeadAssigned

# Check function logs for errors
firebase functions:log | grep -i "error\|exception"

# Verify function code
firebase functions:source:get onLeadAssigned

# Test function manually (if possible)
# Check Firestore trigger configuration
```

---

### Step 3.2: Verify All Function Triggers

#### Commands to Test Each Function

**Test onLeadReassigned:**
```
Manual: Change assignment from User A to User B
```
```bash
firebase functions:log | grep onLeadReassigned
```

**Test onLeadStatusChanged:**
```
Manual: Change lead status (e.g., New → In Talk)
```
```bash
firebase functions:log | grep onLeadStatusChanged
```

**Test onFollowUpAdded:**
```
Manual: Add a follow-up note to an assigned lead
```
```bash
firebase functions:log | grep onFollowUpAdded
```

#### PASS Criteria
- ✅ All 4 functions appear in logs when triggered
- ✅ No function execution errors
- ✅ Notifications created for each trigger

#### FAIL Conditions
- ❌ Function missing from logs
- ❌ Function errors in execution
- ❌ Missing notifications

---

## VALIDATION 4: NOTIFICATION SYSTEM

### Step 4.1: Verify Notification Appears

#### Command
```
Manual:
1. Login as user who received notification (from Step 3.1)
2. Check notification badge in app bar
```

#### Expected Behavior
1. Notification badge shows unread count (red circle with number)
2. Badge number matches unread notifications

#### Verify in Firestore
```bash
# Count unread notifications for user
firebase firestore:query notifications \
  --where userId==[USER_UID] \
  --where read==false \
  --count
```

#### PASS Criteria
- ✅ Badge shows correct unread count
- ✅ Badge updates in real-time when notification created

#### FAIL Conditions
- ❌ Badge doesn't appear
- ❌ Badge shows wrong count
- ❌ Badge doesn't update

---

### Step 4.2: Open Notification Inbox

#### Command
```
Manual: Tap notification badge icon
```

#### Expected Behavior
1. Notification Inbox Screen opens
2. List of notifications displays
3. Unread notifications highlighted (blue background, bold text)
4. Read notifications in normal style
5. Each notification shows:
   - Icon (based on type)
   - Title
   - Body
   - Timestamp
   - Unread indicator (blue dot) if unread

#### PASS Criteria
- ✅ Inbox screen opens
- ✅ Notifications list displays
- ✅ Unread notifications visually distinct
- ✅ Notifications ordered by createdAt DESC (newest first)

#### FAIL Conditions
- ❌ Screen doesn't open
- ❌ Empty list when notifications exist
- ❌ Notifications not loading
- ❌ Wrong order (oldest first)

---

### Step 4.3: Mark Notification as Read

#### Command
```
Manual: Tap on an unread notification
```

#### Expected Behavior
1. Notification marked as read immediately
2. Visual style changes (no longer highlighted)
3. Unread indicator disappears
4. Badge count decreases
5. Navigates to Lead Detail Screen

#### Verify in Firestore
```bash
# Check notification read status
firebase firestore:get notifications/[NOTIFICATION_ID]
```

#### Expected Document
```json
{
  "read": true,
  // ... other fields
}
```

#### PASS Criteria
- ✅ Notification marked as read
- ✅ UI updates immediately
- ✅ Badge count decreases
- ✅ Firestore document updated

#### FAIL Conditions
- ❌ Notification remains unread
- ❌ UI doesn't update
- ❌ Badge count incorrect
- ❌ Firestore not updated

---

### Step 4.4: Navigate to Lead Detail

#### Command
```
Manual: Tap notification (already done in Step 4.3)
```

#### Expected Behavior
1. Navigates to Lead Detail Screen
2. Shows lead information:
   - Lead name
   - Phone
   - Location
   - Status
   - Region
   - Assigned user
3. Follow-up timeline visible
4. Assignment dropdown visible (admin only)

#### PASS Criteria
- ✅ Navigation succeeds
- ✅ Lead detail displays correctly
- ✅ All lead information visible
- ✅ No "Lead not found" errors

#### FAIL Conditions
- ❌ Navigation fails
- ❌ Blank screen
- ❌ "Lead not found" error
- ❌ Wrong lead displayed

---

## VALIDATION 5: FILES & DOCUMENTATION

### Step 5.1: Verify Documentation Exists

#### Commands
```bash
# Check deployment guide exists
test -f DEPLOYMENT_EXECUTION.md && echo "✓ DEPLOYMENT_EXECUTION.md exists" || echo "✗ Missing"

# Check validation guide exists
test -f VALIDATION_GUIDE.md && echo "✓ VALIDATION_GUIDE.md exists" || echo "✗ Missing"

# Check deployment checklist exists
test -f DEPLOYMENT_CHECKLIST.md && echo "✓ DEPLOYMENT_CHECKLIST.md exists" || echo "✗ Missing"
```

#### PASS Criteria
- ✅ All documentation files exist
- ✅ Files contain relevant information

---

### Step 5.2: Verify Deployment Reproducibility

#### Command
```bash
# Verify Firebase configuration
cat .firebaserc
cat firebase.json | head -20
```

#### Expected Output
```
.firebaserc:
{
  "projects": {
    "default": "reach-muslim-leads"
  }
}

firebase.json:
{
  "firestore": {
    "rules": "firestore.rules"
  },
  "functions": [...]
}
```

#### PASS Criteria
- ✅ Configuration files present and correct
- ✅ Project ID matches: reach-muslim-leads

---

## FINAL GO / NO-GO CHECKLIST

### Production Ready Criteria

#### ✅ GO (Production Ready)
- [ ] App starts without errors
- [ ] Login works for admin and sales users
- [ ] Leads load from Firestore
- [ ] Lead creation succeeds
- [ ] All 4 Cloud Functions execute without errors
- [ ] Notifications created correctly
- [ ] Notification inbox displays correctly
- [ ] Notification navigation works
- [ ] No Firestore permission errors
- [ ] No function runtime errors
- [ ] Real-time updates work (notifications, leads)

#### ❌ NO-GO (Do Not Launch)
- [ ] App crashes on startup
- [ ] Firebase initialization fails
- [ ] Login fails consistently
- [ ] Firestore permission denied errors
- [ ] Cloud Functions not executing
- [ ] Notifications not being created
- [ ] Critical features not working
- [ ] Data loss or corruption observed

---

## Quick Validation Script

```bash
#!/bin/bash
# Quick validation checks

echo "=== Firebase Backend Validation ==="
echo ""

# Check functions deployed
echo "1. Checking deployed functions..."
firebase functions:list | grep -E "(onLeadAssigned|onLeadReassigned|onLeadStatusChanged|onFollowUpAdded)" && echo "✓ All functions deployed" || echo "✗ Functions missing"

# Check Firestore rules deployed
echo ""
echo "2. Checking Firestore rules..."
firebase firestore:rules:get > /dev/null 2>&1 && echo "✓ Rules deployed" || echo "✗ Rules not deployed"

# Check project configuration
echo ""
echo "3. Checking project configuration..."
grep -q "reach-muslim-leads" .firebaserc && echo "✓ Project ID correct" || echo "✗ Project ID incorrect"

echo ""
echo "=== Validation Complete ==="
```

---

## Troubleshooting Quick Reference

### App Won't Start
1. Check `flutter doctor`
2. Verify `google-services.json` exists
3. Check `firebase_options.dart` has correct projectId
4. Review console logs for specific errors

### Firestore Permission Errors
1. Verify Firestore rules deployed: `firebase firestore:rules:get`
2. Check user role and region match rules
3. Verify user document has `active: true`
4. Test with Firestore emulator

### Functions Not Executing
1. Check functions deployed: `firebase functions:list`
2. Review function logs: `firebase functions:log`
3. Verify trigger configuration in function code
4. Check Firestore document structure matches function expectations

### Notifications Not Appearing
1. Verify notification document created in Firestore
2. Check user `userId` matches notification `userId`
3. Verify notification stream provider is active
4. Check for Firestore read permission errors

---

## Validation Report Template

```
Validation Date: [DATE]
Validated By: [NAME]
Project: reach-muslim-leads

APP STARTUP: [PASS/FAIL]
FIRESTORE ACCESS: [PASS/FAIL]
FUNCTION TRIGGERS: [PASS/FAIL]
NOTIFICATION SYSTEM: [PASS/FAIL]
DOCUMENTATION: [PASS/FAIL]

OVERALL STATUS: [GO/NO-GO]

Issues Found:
- [List any issues]

Notes:
- [Additional notes]
```

---

## Next Steps After Validation

If **GO**:
1. Monitor function logs for 24 hours
2. Test with multiple users
3. Verify performance under load
4. Document any known limitations

If **NO-GO**:
1. Document all failures
2. Fix critical issues
3. Re-run validation
4. Do not proceed to production until all critical issues resolved

