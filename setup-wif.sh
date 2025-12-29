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
    --project=$PROJECT_ID 2>/dev/null || echo "Service account may already exist"

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
    --display-name="GitHub Actions Pool" 2>/dev/null || echo "Pool may already exist"

# Create workload identity provider
echo "🔌 Creating workload identity provider..."
gcloud iam workload-identity-pools providers create-oidc $PROVIDER_NAME \
    --project=$PROJECT_ID \
    --location="global" \
    --workload-identity-pool=$POOL_NAME \
    --display-name="GitHub Provider" \
    --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
    --issuer-uri="https://token.actions.githubusercontent.com" 2>/dev/null || echo "Provider may already exist"

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

