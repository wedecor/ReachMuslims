#!/bin/bash
# Post-Deployment Validation Script
# Project: reach-muslim-leads

set -e

echo "=========================================="
echo "Post-Deployment Validation"
echo "Project: reach-muslim-leads"
echo "=========================================="
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASS_COUNT=0
FAIL_COUNT=0

# Function to check pass/fail
check_result() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $1"
        ((PASS_COUNT++))
        return 0
    else
        echo -e "${RED}✗${NC} $1"
        ((FAIL_COUNT++))
        return 1
    fi
}

# 1. Verify Firebase project
echo "1. Verifying Firebase project configuration..."
firebase use reach-muslim-leads > /dev/null 2>&1
check_result "Firebase project set to reach-muslim-leads"

# 2. Check deployed functions
echo ""
echo "2. Checking deployed Cloud Functions..."
FUNCTIONS=$(firebase functions:list 2>/dev/null | grep -E "(onLeadAssigned|onLeadReassigned|onLeadStatusChanged|onFollowUpAdded)" | wc -l)
if [ "$FUNCTIONS" -eq 4 ]; then
    echo -e "${GREEN}✓${NC} All 4 functions deployed"
    ((PASS_COUNT++))
else
    echo -e "${RED}✗${NC} Expected 4 functions, found $FUNCTIONS"
    ((FAIL_COUNT++))
fi

# 3. Check Firestore rules
echo ""
echo "3. Checking Firestore rules deployment..."
firebase firestore:rules:get > /dev/null 2>&1
check_result "Firestore rules deployed"

# 4. Verify configuration files
echo ""
echo "4. Verifying configuration files..."
test -f .firebaserc && grep -q "reach-muslim-leads" .firebaserc
check_result ".firebaserc configured correctly"

test -f firebase.json
check_result "firebase.json exists"

test -f firestore.rules
check_result "firestore.rules exists"

test -f lib/firebase_options.dart && grep -q "reach-muslim-leads" lib/firebase_options.dart
check_result "firebase_options.dart has correct projectId"

test -f android/app/google-services.json
check_result "google-services.json exists"

# 5. Verify Flutter setup
echo ""
echo "5. Verifying Flutter setup..."
flutter doctor --version > /dev/null 2>&1
check_result "Flutter installed"

test -f pubspec.yaml
check_result "pubspec.yaml exists"

# 6. Check documentation
echo ""
echo "6. Checking documentation..."
test -f DEPLOYMENT_EXECUTION.md
check_result "DEPLOYMENT_EXECUTION.md exists"

test -f VALIDATION_GUIDE.md
check_result "VALIDATION_GUIDE.md exists"

# Summary
echo ""
echo "=========================================="
echo "Validation Summary"
echo "=========================================="
echo -e "${GREEN}Passed: $PASS_COUNT${NC}"
echo -e "${RED}Failed: $FAIL_COUNT${NC}"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}✓ All automated checks passed${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Run 'flutter run' to test app startup"
    echo "2. Follow VALIDATION_GUIDE.md for manual testing"
    echo "3. Test all user flows (login, create lead, assign, notifications)"
    exit 0
else
    echo -e "${RED}✗ Some checks failed${NC}"
    echo ""
    echo "Please fix the issues above before proceeding with manual validation."
    exit 1
fi

