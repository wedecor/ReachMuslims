#!/bin/bash
# GO/NO-GO Validation Script
# Project: reach-muslim-leads

set -e

echo "=========================================="
echo "GO / NO-GO Production Validation"
echo "Project: reach-muslim-leads"
echo "=========================================="
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PASS_COUNT=0
FAIL_COUNT=0
CRITICAL_FAIL=0

# Function to check result
check_result() {
    local description=$1
    local is_critical=${2:-false}
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC} - $description"
        ((PASS_COUNT++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC} - $description"
        ((FAIL_COUNT++))
        if [ "$is_critical" = true ]; then
            ((CRITICAL_FAIL++))
        fi
        return 1
    fi
}

# Critical check function
critical_check() {
    local description=$1
    if ! check_result "$description" true; then
        echo -e "${RED}CRITICAL FAILURE - STOP VALIDATION${NC}"
        exit 1
    fi
}

echo -e "${BLUE}=== AUTOMATED CHECKS ===${NC}"
echo ""

# 1. Firebase Project
echo "1. Firebase Project Configuration"
firebase use reach-muslim-leads > /dev/null 2>&1
critical_check "Firebase project set to reach-muslim-leads"

# 2. Functions Deployed
echo ""
echo "2. Cloud Functions Deployment"
FUNCTIONS=$(firebase functions:list 2>/dev/null | grep -E "(onLeadAssigned|onLeadReassigned|onLeadStatusChanged|onFollowUpAdded)" | wc -l)
if [ "$FUNCTIONS" -eq 4 ]; then
    echo -e "${GREEN}✓ PASS${NC} - All 4 functions deployed"
    ((PASS_COUNT++))
else
    echo -e "${RED}✗ FAIL${NC} - Expected 4 functions, found $FUNCTIONS"
    ((FAIL_COUNT++))
    ((CRITICAL_FAIL++))
fi

# 3. Firestore Rules
echo ""
echo "3. Firestore Rules"
firebase firestore:rules:get > /dev/null 2>&1
check_result "Firestore rules deployed" true

# 4. Configuration Files
echo ""
echo "4. Configuration Files"
test -f .firebaserc && grep -q "reach-muslim-leads" .firebaserc
check_result ".firebaserc configured"

test -f firebase.json
check_result "firebase.json exists"

test -f firestore.rules
check_result "firestore.rules exists"

test -f lib/firebase_options.dart && grep -q "reach-muslim-leads" lib/firebase_options.dart
check_result "firebase_options.dart has correct projectId"

test -f android/app/google-services.json
check_result "google-services.json exists"

# 5. Flutter Setup
echo ""
echo "5. Flutter Environment"
flutter doctor --version > /dev/null 2>&1
check_result "Flutter installed"

# Summary
echo ""
echo "=========================================="
echo -e "${BLUE}Automated Validation Summary${NC}"
echo "=========================================="
echo -e "${GREEN}Passed: $PASS_COUNT${NC}"
echo -e "${RED}Failed: $FAIL_COUNT${NC}"
if [ $CRITICAL_FAIL -gt 0 ]; then
    echo -e "${RED}Critical Failures: $CRITICAL_FAIL${NC}"
fi
echo ""

if [ $CRITICAL_FAIL -gt 0 ]; then
    echo -e "${RED}❌ NO-GO - CRITICAL FAILURES DETECTED${NC}"
    echo ""
    echo "Please fix critical issues before proceeding with manual validation."
    exit 1
fi

echo -e "${GREEN}✓ Automated checks passed${NC}"
echo ""
echo "=========================================="
echo -e "${YELLOW}NEXT STEPS:${NC}"
echo "=========================================="
echo ""
echo "1. Run Flutter app:"
echo "   ${BLUE}flutter run${NC}"
echo ""
echo "2. Follow manual validation steps in:"
echo "   ${BLUE}GO_NOGO_VALIDATION.md${NC}"
echo ""
echo "3. Complete all 12 validation steps"
echo ""
echo "4. Fill out final GO/NO-GO decision form"
echo ""
echo "=========================================="

