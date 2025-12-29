#!/bin/bash
# Firebase Deployment Commands for reach-muslim-leads
# Run these commands in order

set -e  # Exit on error

echo "=========================================="
echo "Firebase Deployment Script"
echo "Project: reach-muslim-leads"
echo "=========================================="
echo ""

# Verify we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: Must run from project root directory"
    exit 1
fi

# Step 1: Verify Firebase project
echo "Step 1: Verifying Firebase project configuration..."
if grep -q "reach-muslim-leads" .firebaserc && grep -q "reach-muslim-leads" lib/firebase_options.dart; then
    echo "✓ Firebase project ID verified: reach-muslim-leads"
else
    echo "❌ Error: Firebase project ID mismatch"
    exit 1
fi

# Step 2: Verify Android setup
echo ""
echo "Step 2: Verifying Android configuration..."
if [ -f "android/app/google-services.json" ]; then
    echo "✓ google-services.json exists"
else
    echo "❌ Error: google-services.json not found"
    exit 1
fi

if grep -q "google-services" android/settings.gradle.kts && grep -q "google-services" android/app/build.gradle.kts; then
    echo "✓ Google Services plugin configured"
else
    echo "❌ Error: Google Services plugin not configured"
    exit 1
fi

# Step 3: Install Functions dependencies
echo ""
echo "Step 3: Installing Cloud Functions dependencies..."
cd functions
if [ ! -d "node_modules" ]; then
    npm install
    echo "✓ Dependencies installed"
else
    echo "✓ Dependencies already installed (skipping)"
fi

# Step 4: Build Functions
echo ""
echo "Step 4: Building Cloud Functions..."
npm run build
if [ -d "lib" ]; then
    echo "✓ Functions built successfully"
else
    echo "❌ Error: Functions build failed"
    exit 1
fi
cd ..

# Step 5: Deploy Firestore Rules
echo ""
echo "Step 5: Deploying Firestore Security Rules..."
echo "Command: firebase deploy --only firestore:rules"
echo ""
read -p "Press Enter to deploy Firestore rules, or Ctrl+C to cancel..."
firebase deploy --only firestore:rules

# Step 6: Deploy Cloud Functions
echo ""
echo "Step 6: Deploying Cloud Functions..."
echo "Command: firebase deploy --only functions"
echo ""
read -p "Press Enter to deploy Functions, or Ctrl+C to cancel..."
firebase deploy --only functions

echo ""
echo "=========================================="
echo "✅ Deployment Complete!"
echo "=========================================="
echo ""
echo "Next Steps:"
echo "1. Enable FCM in Firebase Console:"
echo "   https://console.firebase.google.com/project/reach-muslim-leads/settings/cloudmessaging"
echo ""
echo "2. Test your app:"
echo "   flutter run"
echo ""
echo "3. Verify functions are running:"
echo "   firebase functions:log"
echo ""

