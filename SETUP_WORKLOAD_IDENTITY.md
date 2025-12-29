# Setup Workload Identity Federation (Secure Method)

This guide uses **Workload Identity Federation** instead of service account keys - this is the **recommended secure method** by Google Cloud.

## Why Workload Identity Federation?

✅ **More Secure** - No keys to download or store  
✅ **No Key Rotation** - Automatically managed  
✅ **Google's Recommended** - Best practice for CI/CD  
✅ **No Secrets to Manage** - Uses OIDC tokens instead

## Setup Steps

### Step 1: Enable Required APIs

```bash
gcloud services enable iamcredentials.googleapis.com \
    storage-api.googleapis.com \
    storage-component.googleapis.com \
    --project=reach-muslim-leads
```

Or enable via [Google Cloud Console](https://console.cloud.google.com/apis/library?project=reach-muslim-leads)

### Step 2: Create Service Account

```bash
gcloud iam service-accounts create github-actions-apk-deployer \
    --display-name="GitHub Actions APK Deployer" \
    --project=reach-muslim-leads
```

Grant Storage Admin role:
```bash
gcloud projects add-iam-policy-binding reach-muslim-leads \
    --member="serviceAccount:github-actions-apk-deployer@reach-muslim-leads.iam.gserviceaccount.com" \
    --role="roles/storage.admin"
```

### Step 3: Create Workload Identity Pool

```bash
gcloud iam workload-identity-pools create github-actions-pool \
    --project=reach-muslim-leads \
    --location="global" \
    --display-name="GitHub Actions Pool"
```

### Step 4: Create Workload Identity Provider

```bash
gcloud iam workload-identity-pools providers create-oidc github-provider \
    --project=reach-muslim-leads \
    --location="global" \
    --workload-identity-pool="github-actions-pool" \
    --display-name="GitHub Provider" \
    --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
    --issuer-uri="https://token.actions.githubusercontent.com"
```

### Step 5: Allow GitHub Repository to Impersonate Service Account

Replace `wedecor/ReachMuslims` with your actual GitHub repository:

```bash
gcloud iam service-accounts add-iam-policy-binding \
    github-actions-apk-deployer@reach-muslim-leads.iam.gserviceaccount.com \
    --project=reach-muslim-leads \
    --role="roles/iam.workloadIdentityUser" \
    --member="principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-actions-pool/attribute.repository/wedecor/ReachMuslims"
```

**To get PROJECT_NUMBER:**
```bash
gcloud projects describe reach-muslim-leads --format="value(projectNumber)"
```

Or find it in [Google Cloud Console](https://console.cloud.google.com/iam-admin/settings?project=reach-muslim-leads)

### Step 6: Get Workload Identity Provider Resource Name

```bash
gcloud iam workload-identity-pools providers describe github-provider \
    --project=reach-muslim-leads \
    --location="global" \
    --workload-identity-pool="github-actions-pool" \
    --format="value(name)"
```

This will output something like:
```
projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-actions-pool/providers/github-provider
```

### Step 7: Add Secrets to GitHub

Go to: https://github.com/wedecor/ReachMuslims/settings/secrets/actions

Add two secrets:

1. **Secret Name:** `WIF_PROVIDER`  
   **Value:** The full provider resource name from Step 6  
   Example: `projects/123456789/locations/global/workloadIdentityPools/github-actions-pool/providers/github-provider`

2. **Secret Name:** `WIF_SERVICE_ACCOUNT`  
   **Value:** `github-actions-apk-deployer@reach-muslim-leads.iam.gserviceaccount.com`

## Quick Setup Script

Save this as `setup-wif.sh` and run it:

```bash
#!/bin/bash
set -e

PROJECT_ID="reach-muslim-leads"
GITHUB_REPO="wedecor/ReachMuslims"
SERVICE_ACCOUNT="github-actions-apk-deployer"
POOL_NAME="github-actions-pool"
PROVIDER_NAME="github-provider"

echo "🚀 Setting up Workload Identity Federation..."

# Get project number
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
echo "📊 Project Number: $PROJECT_NUMBER"

# Enable APIs
echo "📡 Enabling required APIs..."
gcloud services enable iamcredentials.googleapis.com \
    storage-api.googleapis.com \
    storage-component.googleapis.com \
    --project=$PROJECT_ID

# Create service account
echo "👤 Creating service account..."
gcloud iam service-accounts create $SERVICE_ACCOUNT \
    --display-name="GitHub Actions APK Deployer" \
    --project=$PROJECT_ID || echo "Service account may already exist"

# Grant Storage Admin role
echo "🔐 Granting Storage Admin role..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/storage.admin"

# Create workload identity pool
echo "🏊 Creating workload identity pool..."
gcloud iam workload-identity-pools create $POOL_NAME \
    --project=$PROJECT_ID \
    --location="global" \
    --display-name="GitHub Actions Pool" || echo "Pool may already exist"

# Create workload identity provider
echo "🔌 Creating workload identity provider..."
gcloud iam workload-identity-pools providers create-oidc $PROVIDER_NAME \
    --project=$PROJECT_ID \
    --location="global" \
    --workload-identity-pool=$POOL_NAME \
    --display-name="GitHub Provider" \
    --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
    --issuer-uri="https://token.actions.githubusercontent.com" || echo "Provider may already exist"

# Allow GitHub to impersonate service account
echo "🔗 Linking GitHub repository to service account..."
gcloud iam service-accounts add-iam-policy-binding \
    ${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com \
    --project=$PROJECT_ID \
    --role="roles/iam.workloadIdentityUser" \
    --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_NAME}/attribute.repository/${GITHUB_REPO}"

# Get provider resource name
echo ""
echo "✅ Setup complete!"
echo ""
echo "📋 Add these secrets to GitHub:"
echo ""
PROVIDER_RESOURCE=$(gcloud iam workload-identity-pools providers describe $PROVIDER_NAME \
    --project=$PROJECT_ID \
    --location="global" \
    --workload-identity-pool=$POOL_NAME \
    --format="value(name)")

echo "1. Secret Name: WIF_PROVIDER"
echo "   Value: $PROVIDER_RESOURCE"
echo ""
echo "2. Secret Name: WIF_SERVICE_ACCOUNT"
echo "   Value: ${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com"
echo ""
echo "Go to: https://github.com/${GITHUB_REPO}/settings/secrets/actions"
```

## Test the Setup

After adding the secrets:

1. Go to: https://github.com/wedecor/ReachMuslims/actions
2. Click **Build and Deploy APK (Simple)**
3. Click **Run workflow** → **Run workflow**

## Troubleshooting

### "Permission denied" error
- Verify the service account has `roles/storage.admin`
- Check the workload identity binding is correct
- Ensure the GitHub repository path matches exactly

### "Provider not found" error
- Verify `WIF_PROVIDER` secret has the full resource name
- Check the provider exists: `gcloud iam workload-identity-pools providers list`

### "Service account not found" error
- Verify `WIF_SERVICE_ACCOUNT` secret has the correct email format
- Check the service account exists: `gcloud iam service-accounts list`

