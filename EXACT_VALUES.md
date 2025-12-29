# Exact Values for Your Setup

Based on your project settings, here are the exact values you need:

## Your Project Details
- **Project ID:** `reach-muslim-leads`
- **Project Number:** `586386636592`

## Step 1: Provider Resource Name

Your provider resource name is:
```
projects/586386636592/locations/global/workloadIdentityPools/github-actions-pool/providers/github-provider
```

**Copy this entire line** - you'll use it for the `WIF_PROVIDER` GitHub secret.

## Step 2: Service Account Principal

When granting access to the service account, use this principal:
```
principalSet://iam.googleapis.com/projects/586386636592/locations/global/workloadIdentityPools/github-actions-pool/attribute.repository/wedecor/ReachMuslims
```

## Step 3: GitHub Secrets

Add these two secrets to GitHub:

### Secret 1:
- **Name:** `WIF_PROVIDER`
- **Value:** 
  ```
  projects/586386636592/locations/global/workloadIdentityPools/github-actions-pool/providers/github-provider
  ```

### Secret 2:
- **Name:** `WIF_SERVICE_ACCOUNT`
- **Value:** 
  ```
  github-actions-apk-deployer@reach-muslim-leads.iam.gserviceaccount.com
  ```

## Quick Links

- **Add GitHub Secrets:** https://github.com/wedecor/ReachMuslims/settings/secrets/actions
- **Service Account:** https://console.cloud.google.com/iam-admin/serviceaccounts?project=reach-muslim-leads
- **Test Workflow:** https://github.com/wedecor/ReachMuslims/actions

