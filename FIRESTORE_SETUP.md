# Firestore Database Setup Guide

## Project: reach-muslim-leads

---

## Required Collections

The app uses the following Firestore collections:

### 1. `users` Collection
**Path:** `users/{userId}`

**Document Structure:**
```json
{
  "name": "User Name",
  "email": "user@example.com",
  "role": "admin" or "sales",
  "region": "india" or "usa",
  "active": true or false
}
```

**Required Fields:**
- `name` (string)
- `email` (string)
- `role` (string: "admin" or "sales")
- `region` (string: "india" or "usa")
- `active` (boolean)

---

### 2. `leads` Collection
**Path:** `leads/{leadId}`

**Document Structure:**
```json
{
  "name": "Lead Name",
  "phone": "1234567890",
  "location": "Location" (optional),
  "region": "india" or "usa",
  "status": "newLead" | "inTalk" | "notInterested" | "converted",
  "assignedTo": "user-uid" (optional),
  "assignedToName": "User Name" (optional),
  "createdAt": Timestamp,
  "updatedAt": Timestamp
}
```

**Required Fields:**
- `name` (string)
- `phone` (string)
- `region` (string)
- `status` (string)
- `createdAt` (Timestamp)
- `updatedAt` (Timestamp)

**Optional Fields:**
- `location` (string)
- `assignedTo` (string)
- `assignedToName` (string)

---

### 3. `leads/{leadId}/followUps` Subcollection
**Path:** `leads/{leadId}/followUps/{followUpId}`

**Document Structure:**
```json
{
  "note": "Follow-up note text",
  "createdBy": "user-uid",
  "createdByName": "User Name",
  "createdAt": Timestamp
}
```

**Required Fields:**
- `note` (string)
- `createdBy` (string)
- `createdByName` (string)
- `createdAt` (Timestamp)

---

### 4. `notifications` Collection
**Path:** `notifications/{notificationId}`

**Document Structure:**
```json
{
  "userId": "user-uid",
  "leadId": "lead-id",
  "type": "leadAssigned" | "leadReassigned" | "leadStatusChanged" | "followUpAdded",
  "title": "Notification Title",
  "body": "Notification body text",
  "read": false,
  "createdAt": Timestamp
}
```

**Required Fields:**
- `userId` (string)
- `leadId` (string)
- `type` (string)
- `title` (string)
- `body` (string)
- `read` (boolean)
- `createdAt` (Timestamp)

---

## How to Check/Create Firestore Database

### Option 1: Firebase Console (Recommended)

1. **Go to Firebase Console:**
   ```
   https://console.firebase.google.com/project/reach-muslim-leads/firestore
   ```

2. **Check if Firestore is enabled:**
   - If you see "Create database" button → Firestore is NOT created
   - If you see collections/data → Firestore IS created

3. **Create Firestore (if needed):**
   - Click "Create database"
   - Choose "Start in production mode" (rules will be deployed separately)
   - Select location (e.g., us-central1)
   - Click "Enable"

4. **Verify Collections:**
   - Check if collections exist: `users`, `leads`, `notifications`
   - Collections are created automatically when first document is added
   - No need to create empty collections

---

### Option 2: Firebase CLI (After Authentication)

```bash
# Authenticate first
firebase login

# Set project
firebase use reach-muslim-leads

# Check Firestore status
firebase firestore:databases:list

# Deploy rules (this will create database if it doesn't exist)
firebase deploy --only firestore:rules
```

---

## Required Indexes

The app requires these Firestore indexes:

### 1. Notifications Index
**Collection:** `notifications`
**Fields:**
- `userId` (Ascending)
- `createdAt` (Descending)

**Command to create:**
```bash
# This will be created automatically when you deploy rules
# Or create in Firebase Console → Firestore → Indexes
```

---

## Initial Data Setup

### Create Test Users

You need at least one user document to test login:

**Admin User:**
```json
Collection: users
Document ID: [any-uid]
{
  "name": "Admin User",
  "email": "admin@example.com",
  "role": "admin",
  "region": "india",
  "active": true
}
```

**Sales User:**
```json
Collection: users
Document ID: [any-uid]
{
  "name": "Sales User",
  "email": "sales@example.com",
  "role": "sales",
  "region": "india",
  "active": true
}
```

**Note:** The document ID should match the Firebase Auth UID after user signs up.

---

## Verification Checklist

- [ ] Firestore database created in Firebase Console
- [ ] Firestore rules deployed (from `firestore.rules`)
- [ ] At least one user document exists in `users` collection
- [ ] User document has correct structure (name, email, role, region, active)
- [ ] User document ID matches Firebase Auth UID

---

## Quick Status Check

### In Firebase Console:
1. Go to: https://console.firebase.google.com/project/reach-muslim-leads/firestore
2. Check if database exists
3. Check if `users` collection has documents
4. Verify rules are deployed (should show custom rules, not default)

### Expected Status:
- ✅ Database exists
- ✅ Rules deployed (custom rules visible)
- ✅ At least one user document exists
- ✅ Collections will be created automatically when needed

---

## Important Notes

1. **Collections are created automatically** - You don't need to create empty collections. They're created when the first document is added.

2. **User documents must match Auth UIDs** - When a user logs in via Firebase Auth, their UID must match a document ID in the `users` collection.

3. **Rules must be deployed** - Even if database exists, rules must be deployed for the app to work correctly.

4. **Indexes are auto-created** - Firestore will prompt you to create indexes when needed, or you can create them manually in Console.

---

## Troubleshooting

### "Permission denied" errors:
- Check if Firestore rules are deployed
- Verify user document exists and `active: true`
- Check user role and region match rules

### "Collection not found" errors:
- Collections are created automatically - this shouldn't happen
- Check if database is created
- Verify project ID is correct

### "Index not found" errors:
- Create the required index in Firebase Console
- Or wait for Firestore to auto-create it

