#!/bin/bash

# Script to build APK and deploy to Firebase Storage
# Usage: ./deploy_apk.sh

set -e

echo "🚀 Starting APK build and deployment process..."

# Step 1: Build the APK
echo "📦 Building release APK..."
flutter build apk --release

# Check if APK was built successfully
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
if [ ! -f "$APK_PATH" ]; then
    echo "❌ Error: APK not found at $APK_PATH"
    exit 1
fi

echo "✅ APK built successfully at $APK_PATH"

# Step 2: Get version info for naming
VERSION_NAME=$(grep "version:" pubspec.yaml | sed 's/version: //' | sed 's/\+.*//')
VERSION_CODE=$(grep "version:" pubspec.yaml | sed 's/.*+//')
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
APK_NAME="reachmuslim_v${VERSION_NAME}_${VERSION_CODE}_${TIMESTAMP}.apk"

echo "📝 APK will be named: $APK_NAME"

# Step 3: Copy APK with version name
cp "$APK_PATH" "/tmp/$APK_NAME"
echo "✅ APK copied to /tmp/$APK_NAME"

# Step 4: Upload to Firebase Storage using gsutil
echo "☁️  Uploading to Firebase Storage..."
if command -v gsutil &> /dev/null; then
    gsutil cp /tmp/$APK_NAME gs://reach-muslim-leads.appspot.com/apk/$APK_NAME
    echo "🔓 Making APK publicly accessible..."
    gsutil acl ch -u AllUsers:R gs://reach-muslim-leads.appspot.com/apk/$APK_NAME
else
    echo "⚠️  gsutil not found. Please install Google Cloud SDK or use Firebase Console to upload."
    echo "   File location: /tmp/$APK_NAME"
    echo "   Upload to: gs://reach-muslim-leads.appspot.com/apk/$APK_NAME"
    exit 1
fi

# Step 6: Get public URL
PUBLIC_URL="https://storage.googleapis.com/reach-muslim-leads.appspot.com/apk/$APK_NAME"
echo ""
echo "✅ APK deployed successfully!"
echo "📱 Download URL: $PUBLIC_URL"
echo ""
echo "Share this URL with your team members to download the APK."

# Cleanup
rm "/tmp/$APK_NAME"
echo "🧹 Cleaned up temporary files"

