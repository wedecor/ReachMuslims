# Next Steps After Provider Setup

Great! Your Workload Identity Provider is set up. Now complete these final steps:

## Step 1: Get Provider Resource Name

1. Go to: https://console.cloud.google.com/iam-admin/workload-identity-pools?project=reach-muslim-leads
2. Click on **github-actions-pool**
3. Click on **github-provider**
4. Copy the **Resource name** (it looks like):
   ```
   projects/123456789012/locations/global/workloadIdentityPools/github-actions-pool/providers/github-provider
   ```
5. **Save this** - you'll need it for GitHub secrets

## Step 2: Get Your Project Number

1. Go to: https://console.cloud.google.com/iam-admin/settings?project=reach-muslim-leads
2. Copy the **Project number** (long number like `123456789012`)
3. **Save this** - you'll need it for Step 3

## Step 3: Link GitHub Repository to Service Account

1. Go to: https://console.cloud.google.com/iam-admin/serviceaccounts?project=reach-muslim-leads
2. Click on **github-actions-apk-deployer**
3. Go to **PERMISSIONS** tab
4. Click **GRANT ACCESS**
5. In **New principals**, paste this (replace `PROJECT_NUMBER` with your number):
   ```
   principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-actions-pool/attribute.repository/wedecor/ReachMuslims
   ```
   **Example:** If your project number is `123456789012`:
   ```
   principalSet://iam.googleapis.com/projects/123456789012/locations/global/workloadIdentityPools/github-actions-pool/attribute.repository/wedecor/ReachMuslims
   ```
6. **Select a role:** Search for "Workload Identity User" → Select it
7. Click **SAVE**

## Step 4: Add Secrets to GitHub

1. Go to: https://github.com/wedecor/ReachMuslims/settings/secrets/actions
2. Click **New repository secret**

**Secret 1:**
- **Name:** `WIF_PROVIDER`
- **Secret:** Paste the Resource name from Step 1
- Click **Add secret**

**Secret 2:**
- Click **New repository secret** again
- **Name:** `WIF_SERVICE_ACCOUNT`
- **Secret:** `github-actions-apk-deployer@reach-muslim-leads.iam.gserviceaccount.com`
- Click **Add secret**

## Step 5: Test the Workflow! 🎉

1. Go to: https://github.com/wedecor/ReachMuslims/actions
2. Click **Build and Deploy APK (Simple)**
3. Click **Run workflow** → **Run workflow**
4. Watch it build and deploy your APK automatically!

## What Happens Next

Once the workflow runs successfully:
- ✅ APK will be built automatically
- ✅ Uploaded to Firebase Storage
- ✅ Made publicly accessible
- ✅ You'll get download URLs:
  - **Latest:** `https://storage.googleapis.com/reach-muslim-leads.appspot.com/apk/latest.apk`
  - **Versioned:** Check workflow logs for the exact URL

## Share with Team

After the first successful build, share this URL with your team:
```
https://storage.googleapis.com/reach-muslim-leads.appspot.com/apk/latest.apk
```

This URL will always point to the latest APK version!

