# Manual Workload Identity Federation Setup

Since `gcloud` CLI is not installed, here are the steps to set up Workload Identity Federation via the Google Cloud Console:

## Step 1: Enable Required APIs

1. Go to [Google Cloud APIs & Services](https://console.cloud.google.com/apis/library?project=reach-muslim-leads)
2. Enable these APIs:
   - **IAM Service Account Credentials API** (`iamcredentials.googleapis.com`)
   - **Cloud Storage API** (`storage-api.googleapis.com`)
   - **Cloud Storage JSON API** (`storage-component.googleapis.com`)

## Step 2: Create Service Account

1. Go to [Service Accounts](https://console.cloud.google.com/iam-admin/serviceaccounts?project=reach-muslim-leads)
2. Click **Create Service Account**
3. Name: `github-actions-apk-deployer`
4. Click **Create and Continue**
5. Grant role: **Storage Admin**
6. Click **Continue** → **Done**

## Step 3: Create Workload Identity Pool

1. Go to [Workload Identity Pools](https://console.cloud.google.com/iam-admin/workload-identity-pools?project=reach-muslim-leads)
2. Click **Create Pool**
3. Pool name: `github-actions-pool`
4. Display name: `GitHub Actions Pool`
5. Click **Continue**
6. Leave provider settings for now, click **Continue**
7. Click **Create**

## Step 4: Create Workload Identity Provider

1. In the pool you just created, click **Add Provider**
2. Provider type: **OpenID Connect (OIDC)**
3. Provider name: `github-provider`
4. Display name: `GitHub Provider`
5. Issuer URL: `https://token.actions.githubusercontent.com`
6. Click **Continue**
7. **Attribute mapping:**
   - `google.subject` = `assertion.sub`
   - `attribute.actor` = `assertion.actor`
   - `attribute.repository` = `assertion.repository`
8. Click **Save**

## Step 5: Get Provider Resource Name

After creating the provider, you'll see the provider details. Copy the **Resource name** which looks like:
```
projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-actions-pool/providers/github-provider
```

**To find PROJECT_NUMBER:**
- Go to [Project Settings](https://console.cloud.google.com/iam-admin/settings?project=reach-muslim-leads)
- Look for "Project number"

## Step 6: Allow GitHub Repository Access

1. Go to [Service Accounts](https://console.cloud.google.com/iam-admin/serviceaccounts?project=reach-muslim-leads)
2. Click on `github-actions-apk-deployer@reach-muslim-leads.iam.gserviceaccount.com`
3. Go to **Permissions** tab
4. Click **Grant Access**
5. In **New principals**, enter:
   ```
   principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-actions-pool/attribute.repository/wedecor/ReachMuslims
   ```
   (Replace `PROJECT_NUMBER` with your actual project number)
6. Role: **Workload Identity User** (`roles/iam.workloadIdentityUser`)
7. Click **Save**

## Step 7: Add Secrets to GitHub

1. Go to: https://github.com/wedecor/ReachMuslims/settings/secrets/actions
2. Click **New repository secret**

**Secret 1:**
- Name: `WIF_PROVIDER`
- Value: The full provider resource name from Step 5
  Example: `projects/123456789/locations/global/workloadIdentityPools/github-actions-pool/providers/github-provider`

**Secret 2:**
- Name: `WIF_SERVICE_ACCOUNT`
- Value: `github-actions-apk-deployer@reach-muslim-leads.iam.gserviceaccount.com`

## Step 8: Test the Workflow

1. Go to: https://github.com/wedecor/ReachMuslims/actions
2. Click **Build and Deploy APK (Simple)**
3. Click **Run workflow** → **Run workflow**

## Quick Reference URLs

- **APIs & Services**: https://console.cloud.google.com/apis/library?project=reach-muslim-leads
- **Service Accounts**: https://console.cloud.google.com/iam-admin/serviceaccounts?project=reach-muslim-leads
- **Workload Identity Pools**: https://console.cloud.google.com/iam-admin/workload-identity-pools?project=reach-muslim-leads
- **Project Settings**: https://console.cloud.google.com/iam-admin/settings?project=reach-muslim-leads

