# Fix: Add Workload Identity User Role

You need to add the "Workload Identity User" role to the principal you just added.

## Option 1: Edit the Existing Permission

1. On the **Principals with access** tab, find the principal you just added:
   ```
   principalSet://iam.googleapis.com/projects/586386636592/locations/global/workloadIdentityPools/github-actions-pool/attribute.repository/wedecor/ReachMuslims
   ```

2. Click the **pencil/edit icon** next to it (or click on the principal)

3. Click **ADD ANOTHER ROLE**

4. Search for: `Workload Identity User`

5. Select **Workload Identity User** (`roles/iam.workloadIdentityUser`)

6. Click **SAVE**

## Option 2: Remove and Re-add (If Edit Doesn't Work)

1. Find the principal in the list
2. Click the **trash/delete icon** to remove it
3. Click **Grant Access** again
4. Paste the principal:
   ```
   principalSet://iam.googleapis.com/projects/586386636592/locations/global/workloadIdentityPools/github-actions-pool/attribute.repository/wedecor/ReachMuslims
   ```
5. **Select a role:** Search for `Workload Identity User`
6. Select **Workload Identity User** (`roles/iam.workloadIdentityUser`)
7. Click **SAVE**

## Verify

After saving, you should see:
- The principal listed
- Role: **Workload Identity User** (or `roles/iam.workloadIdentityUser`)

Once you see this role assigned, you're good to go!

