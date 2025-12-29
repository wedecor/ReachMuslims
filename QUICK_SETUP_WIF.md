# Quick Setup: Workload Identity Federation (No Installation Required)

Since you have limited storage, we'll use the **Google Cloud Console** (web interface) - no local installation needed!

## Step-by-Step Setup (15 minutes)

### Step 1: Enable Required APIs

1. Open: https://console.cloud.google.com/apis/library?project=reach-muslim-leads
2. Search for and enable these APIs (click each, then "Enable"):
   - **IAM Service Account Credentials API**
   - **Cloud Storage API**
   - **Cloud Storage JSON API**

### Step 2: Create Service Account

1. Open: https://console.cloud.google.com/iam-admin/serviceaccounts?project=reach-muslim-leads
2. Click **+ CREATE SERVICE ACCOUNT**
3. **Service account name:** `github-actions-apk-deployer`
4. Click **CREATE AND CONTINUE**
5. **Grant this service account access to project:**
   - Role: Search for "Storage Admin" → Select it
6. Click **CONTINUE** → **DONE**

### Step 3: Create Workload Identity Pool

1. Open: https://console.cloud.google.com/iam-admin/workload-identity-pools?project=reach-muslim-leads
2. Click **+ CREATE POOL**
3. **Pool name:** `github-actions-pool`
4. **Display name:** `GitHub Actions Pool`
5. Click **CONTINUE**
6. Click **CONTINUE** again (skip provider for now)
7. Click **CREATE POOL**

### Step 4: Create Workload Identity Provider

1. In the pool you just created, click **ADD PROVIDER**
2. **Provider type:** Select **OpenID Connect (OIDC)**
3. **Provider name:** `github-provider`
4. **Display name:** `GitHub Provider`
5. **Issuer URL:** `https://token.actions.githubusercontent.com`
6. Click **CONTINUE**
7. **Attribute mapping** (add these 3 mappings):
   - `google.subject` = `assertion.sub`
   - `attribute.actor` = `assertion.actor`
   - `attribute.repository` = `assertion.repository`
8. Click **SAVE**

### Step 5: Get Your Project Number

1. Open: https://console.cloud.google.com/iam-admin/settings?project=reach-muslim-leads
2. Copy the **Project number** (it's a long number like `123456789012`)
3. **Save this number** - you'll need it in the next step

### Step 6: Link GitHub Repository to Service Account

1. Open: https://console.cloud.google.com/iam-admin/serviceaccounts?project=reach-muslim-leads
2. Click on **github-actions-apk-deployer**
3. Go to **PERMISSIONS** tab
4. Click **GRANT ACCESS**
5. In **New principals**, paste this (replace `PROJECT_NUMBER` with your number from Step 5):
   ```
   principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-actions-pool/attribute.repository/wedecor/ReachMuslims
   ```
   **Example:** If your project number is `123456789012`, it would be:
   ```
   principalSet://iam.googleapis.com/projects/123456789012/locations/global/workloadIdentityPools/github-actions-pool/attribute.repository/wedecor/ReachMuslims
   ```
6. **Select a role:** Search for "Workload Identity User" → Select `Workload Identity User`
7. Click **SAVE**

### Step 7: Get Provider Resource Name

1. Go back to: https://console.cloud.google.com/iam-admin/workload-identity-pools?project=reach-muslim-leads
2. Click on **github-actions-pool**
3. Click on **github-provider**
4. Copy the **Resource name** (it looks like):
   ```
   projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-actions-pool/providers/github-provider
   ```
5. **Save this** - you'll need it for GitHub secrets

### Step 8: Add Secrets to GitHub

1. Open: https://github.com/wedecor/ReachMuslims/settings/secrets/actions
2. Click **New repository secret**

**Secret 1:**
- **Name:** `WIF_PROVIDER`
- **Secret:** Paste the Resource name from Step 7
- Click **Add secret**

**Secret 2:**
- Click **New repository secret** again
- **Name:** `WIF_SERVICE_ACCOUNT`
- **Secret:** `github-actions-apk-deployer@reach-muslim-leads.iam.gserviceaccount.com`
- Click **Add secret**

### Step 9: Test It! 🎉

1. Open: https://github.com/wedecor/ReachMuslims/actions
2. Click **Build and Deploy APK (Simple)**
3. Click **Run workflow** → **Run workflow**
4. Watch it build and deploy your APK automatically!

## Quick Links Checklist

- [ ] Enable APIs (Step 1)
- [ ] Create Service Account (Step 2)
- [ ] Create Workload Identity Pool (Step 3)
- [ ] Create Provider (Step 4)
- [ ] Get Project Number (Step 5)
- [ ] Link GitHub Repository (Step 6)
- [ ] Get Provider Resource Name (Step 7)
- [ ] Add GitHub Secrets (Step 8)
- [ ] Test Workflow (Step 9)

## Need Help?

If you get stuck at any step, let me know which step and I'll help you through it!

