# Setup Automated APK Build and Deployment

This guide will help you set up automatic APK building and deployment to Firebase Storage using GitHub Actions.

## How It Works

When you push code to the `main` branch (or manually trigger), GitHub Actions will:
1. ✅ Build the release APK automatically
2. ✅ Upload it to Firebase Storage
3. ✅ Make it publicly accessible
4. ✅ Create a versioned APK and a "latest.apk" file

## Setup Steps

### Step 1: Create Google Cloud Service Account

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select project: `reach-muslim-leads`
3. Go to **IAM & Admin → Service Accounts**
4. Click **Create Service Account**
5. Name: `github-actions-apk-deployer`
6. Click **Create and Continue**
7. Grant role: **Storage Admin** (or **Storage Object Admin**)
8. Click **Done**

### Step 2: Create and Download Service Account Key

1. Click on the service account you just created
2. Go to **Keys** tab
3. Click **Add Key → Create new key**
4. Choose **JSON** format
5. Download the JSON file (keep it secure!)

### Step 3: Add Secret to GitHub

1. Go to your GitHub repository: https://github.com/wedecor/ReachMuslims
2. Go to **Settings → Secrets and variables → Actions**
3. Click **New repository secret**
4. Name: `GCP_SA_KEY`
5. Value: Paste the entire contents of the JSON file you downloaded
6. Click **Add secret**

### Step 4: Enable Required APIs

Make sure these APIs are enabled in Google Cloud:
- Cloud Storage API
- Cloud Storage JSON API

You can enable them via:
```bash
gcloud services enable storage-api.googleapis.com storage-component.googleapis.com
```

Or via [Google Cloud Console](https://console.cloud.google.com/apis/library)

### Step 5: Test the Workflow

1. **Option A: Push to main branch**
   ```bash
   git add .
   git commit -m "Add automated APK build workflow"
   git push origin main
   ```

2. **Option B: Manual trigger**
   - Go to GitHub repository
   - Click **Actions** tab
   - Select **Build and Deploy APK (Simple)**
   - Click **Run workflow**
   - Click **Run workflow** button

### Step 6: Check Results

1. Go to **Actions** tab in GitHub
2. Click on the workflow run
3. Check the logs for the download URL
4. Or go to [Firebase Storage Console](https://console.firebase.google.com/project/reach-muslim-leads/storage/apk) to see uploaded files

## Download URLs

After deployment, you'll have two URLs:

1. **Versioned APK** (keeps all versions):
   ```
   https://storage.googleapis.com/reach-muslim-leads.appspot.com/apk/reachmuslim_v1.0.0_1_20241229_123456.apk
   ```

2. **Latest APK** (always points to newest):
   ```
   https://storage.googleapis.com/reach-muslim-leads.appspot.com/apk/latest.apk
   ```

Share the **latest.apk** URL with your team - it will always have the newest version!

## Troubleshooting

### Workflow fails with permission error
- Check that service account has **Storage Admin** role
- Verify the `GCP_SA_KEY` secret is correctly set

### Build fails
- Check Flutter version in workflow matches your project
- Verify all dependencies are in `pubspec.yaml`

### Upload fails
- Ensure Firebase Storage is enabled
- Check storage rules are deployed: `firebase deploy --only storage`

## Manual Override

If you need to build locally and upload manually:
```bash
./deploy_apk.sh
```

Or use the manual upload guide: `UPLOAD_APK_MANUAL.md`

