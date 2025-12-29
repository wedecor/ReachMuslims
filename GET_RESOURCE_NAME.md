# Get Provider Resource Name

Your provider is created! Now get the resource name:

## Step 1: Get Provider Resource Name

1. **Click on `github-provider`** in the list
2. You'll see the provider details page
3. Look for **Resource name** (it's usually at the top or in the details section)
4. It will look like:
   ```
   projects/123456789012/locations/global/workloadIdentityPools/github-actions-pool/providers/github-provider
   ```
5. **Copy this entire resource name** - you'll need it for GitHub secrets

## Alternative: If you can't find Resource name

The resource name format is:
```
projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-actions-pool/providers/github-provider
```

To get your PROJECT_NUMBER:
1. Go to: https://console.cloud.google.com/iam-admin/settings?project=reach-muslim-leads
2. Copy the **Project number** (long number)
3. Replace `PROJECT_NUMBER` in the format above

## What to do next

Once you have the resource name:
1. Go to GitHub: https://github.com/wedecor/ReachMuslims/settings/secrets/actions
2. Add secret `WIF_PROVIDER` with the resource name
3. Add secret `WIF_SERVICE_ACCOUNT` with: `github-actions-apk-deployer@reach-muslim-leads.iam.gserviceaccount.com`

