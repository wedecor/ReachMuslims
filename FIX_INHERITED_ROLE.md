# Fix: Remove and Re-add with Correct Role

Since roles are inherited and can't be edited, you need to remove the principal and add it again with the correct role.

## Steps to Fix

1. **On the "Principals with access" tab**, find the principal:
   ```
   principalSet://iam.googleapis.com/projects/586386636592/locations/global/workloadIdentityPools/github-actions-pool/attribute.repository/wedecor/ReachMuslims
   ```

2. **Click the delete/trash icon** (or three dots menu → Delete) to remove it

3. **Click "Grant Access"** button

4. **In "New principals"**, paste:
   ```
   principalSet://iam.googleapis.com/projects/586386636592/locations/global/workloadIdentityPools/github-actions-pool/attribute.repository/wedecor/ReachMuslims
   ```

5. **IMPORTANT: Select a role** - Click the role dropdown/search box

6. **Search for:** `Workload Identity User`

7. **Select:** `Workload Identity User` (it should show as `roles/iam.workloadIdentityUser`)

8. **Click "SAVE"**

## Verify After Re-adding

You should now see:
- ✅ Principal listed
- ✅ Role: **Workload Identity User** (not inherited, directly assigned)

This role is required for the GitHub Actions workflow to impersonate the service account and upload APKs.

