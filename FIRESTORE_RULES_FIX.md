# Firestore Rules Fix - Custom Claims Implementation

## Problem Identified

The Firestore rules were using `get()` to read user documents for authorization. This fails in complex queries because:
1. Firestore rules can't reliably read documents during list query evaluation
2. Creates circular dependencies (reading user doc to check permissions)
3. Fails silently when user document doesn't exist or can't be read

## Solution

**Use Firebase Auth Custom Claims** - Role and status are now stored in the ID token, accessible directly in rules via `request.auth.token`.

## What Changed

### 1. Firestore Rules (`firestore.rules`)
- **Primary**: Uses `request.auth.token.role`, `request.auth.token.status`, `request.auth.token.active`
- **Fallback**: Falls back to Firestore document read if custom claims not set (for backward compatibility)
- **Admin Access**: Admin users can now list ALL leads regardless of filters

### 2. Cloud Functions (`functions/src/index.ts`)
- Added `onUserCreated` - Sets custom claims when user document is created
- Added `onUserApproved` - Updates custom claims when user is approved/updated

## Deployment Steps

### Step 1: Deploy Cloud Functions
```bash
cd functions
npm install  # If not already done
firebase deploy --only functions
```

This will:
- Set custom claims for existing users
- Automatically set claims for new users
- Update claims when users are approved/updated

### Step 2: Deploy Firestore Rules
```bash
firebase deploy --only firestore:rules
```

### Step 3: Force Token Refresh for Existing Users

**Option A: Sign out and sign in again** (Recommended)
- Users need to sign out and sign back in to get new token with custom claims

**Option B: Programmatic refresh** (For testing)
Add this to your auth provider after login:
```dart
await FirebaseAuth.instance.currentUser?.getIdToken(true); // Force refresh
```

### Step 4: Verify Custom Claims

Check in Firebase Console:
1. Go to Authentication → Users
2. Click on a user
3. Check "Custom claims" section
4. Should see: `role`, `status`, `active`, `region`

## How It Works

### Before (BROKEN)
```
Rule checks permission → Reads user document from Firestore → Fails in complex queries
```

### After (FIXED)
```
Rule checks permission → Reads from request.auth.token (FAST, RELIABLE) → Works always
```

## Security Model

### Admin Users
- ✅ Can list ALL leads (any filters work)
- ✅ Can read leads in their region
- ✅ Can read all users
- ✅ Can create/update/delete leads in their region

### Sales Users
- ✅ Can list leads (query filters by assignedTo)
- ✅ Can read only assigned or unassigned leads
- ✅ Can update only assigned leads

### Pending Users
- ❌ Cannot access leads
- ❌ Cannot access protected collections

## Testing

1. **Admin Login Test**
   - Login as admin
   - Navigate to Leads screen
   - Apply filters (status, date, assigned user)
   - Should work without permission errors

2. **Dashboard Test**
   - Login as admin
   - View dashboard
   - All metrics should load

3. **Users Screen Test**
   - Login as admin
   - View pending users
   - Should load without errors

## Troubleshooting

### Issue: Still getting permission errors
**Solution**: 
1. Verify custom claims are set (check Firebase Console)
2. Force token refresh (sign out/in)
3. Check Cloud Functions logs for errors

### Issue: Custom claims not updating
**Solution**:
1. Check Cloud Functions are deployed
2. Check function logs: `firebase functions:log`
3. Manually trigger by updating user document

### Issue: Rules still failing
**Solution**:
1. Verify rules are deployed: `firebase firestore:rules:get`
2. Check user document exists in Firestore
3. Verify user is authenticated: `request.auth != null`

## Important Notes

1. **Custom claims are cached** - Users need to refresh token after claims are set
2. **Claims update via Cloud Functions** - Not instant, but usually < 1 second
3. **Fallback to Firestore reads** - Rules will work even if claims aren't set yet (slower, less reliable)

## Next Steps

After deployment:
1. Test admin access to all screens
2. Test sales user restrictions
3. Test pending user blocking
4. Monitor Cloud Functions logs for any errors

