# Quick Validation Reference

## Automated Validation
```bash
./validate.sh
```

## Manual Validation Commands

### 1. App Startup
```bash
flutter run
```
**PASS:** App launches, login screen appears, no Firebase errors  
**FAIL:** Crash, errors, blank screen

---

### 2. Firestore Access - Login
```
Manual: Login as admin in app
```
**PASS:** Login succeeds, Admin Home Screen appears  
**FAIL:** Login fails, permission errors

**Verify in Firestore:**
```bash
firebase firestore:get users/[ADMIN_UID]
```

---

### 3. Firestore Access - Load Leads
```
Manual: Tap "View Leads" button
```
**PASS:** Leads load, no permission errors  
**FAIL:** "Permission denied" error, blank screen

**Check logs:**
```bash
flutter logs | grep -i "permission\|error"
```

---

### 4. Firestore Access - Create Lead
```
Manual: Create a new lead
```
**PASS:** Lead created, appears in list  
**FAIL:** Creation fails, permission errors

**Verify:**
```bash
firebase firestore:get leads --limit 1 --order-by createdAt desc
```

---

### 5. Function Triggers - Assign Lead
```
Manual: Assign lead to a user
```
**PASS:** Function executes, notification created  
**FAIL:** No function execution, no notification

**Verify function:**
```bash
firebase functions:log --limit 5 | grep onLeadAssigned
```

**Verify notification:**
```bash
firebase firestore:get notifications --limit 1 --order-by createdAt desc
```

---

### 6. Notification System - Badge
```
Manual: Check notification badge count
```
**PASS:** Badge shows correct unread count  
**FAIL:** Badge missing or wrong count

**Verify count:**
```bash
firebase firestore:query notifications \
  --where userId==[USER_UID] \
  --where read==false \
  --count
```

---

### 7. Notification System - Inbox
```
Manual: Open notification inbox
```
**PASS:** Notifications display, unread highlighted  
**FAIL:** Empty list, not loading, wrong order

---

### 8. Notification System - Navigation
```
Manual: Tap notification
```
**PASS:** Marked as read, navigates to lead detail  
**FAIL:** Not marked, navigation fails

---

## Quick Function Verification
```bash
# List all functions
firebase functions:list

# Check recent logs
firebase functions:log --limit 10

# Check specific function
firebase functions:log | grep onLeadAssigned
```

## Quick Firestore Verification
```bash
# Get recent notification
firebase firestore:get notifications --limit 1 --order-by createdAt desc

# Count unread for user
firebase firestore:query notifications \
  --where userId==[UID] \
  --where read==false \
  --count

# Get lead
firebase firestore:get leads/[LEAD_ID]
```

## GO / NO-GO Decision

### ✅ GO (All must pass)
- App starts
- Login works
- Leads load/create
- Functions execute
- Notifications work
- No critical errors

### ❌ NO-GO (Any failure)
- App crashes
- Permission errors
- Functions not executing
- Critical features broken

