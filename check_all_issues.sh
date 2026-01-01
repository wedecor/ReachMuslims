#!/bin/bash
# Comprehensive Issue Checker for Reach Muslim App
# This script checks for various types of issues in the application

set -e

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

ISSUE_COUNT=0
WARNING_COUNT=0
ERROR_COUNT=0

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Reach Muslim - Issue Checker${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Function to count issues
count_issues() {
    local output="$1"
    local errors=$(echo "$output" | grep -c "error •" || true)
    local warnings=$(echo "$output" | grep -c "warning •" || true)
    local infos=$(echo "$output" | grep -c "info •" || true)
    
    ERROR_COUNT=$((ERROR_COUNT + errors))
    WARNING_COUNT=$((WARNING_COUNT + warnings))
    ISSUE_COUNT=$((ISSUE_COUNT + errors + warnings + infos))
}

# 1. Flutter Analyze
echo -e "${BLUE}[1/6] Running Flutter Analyze...${NC}"
ANALYZE_OUTPUT=$(flutter analyze 2>&1 || true)
count_issues "$ANALYZE_OUTPUT"
echo "$ANALYZE_OUTPUT" | tail -20
echo ""

# 2. Check for Linter Errors
echo -e "${BLUE}[2/6] Checking Linter Errors...${NC}"
LINT_OUTPUT=$(flutter analyze --no-fatal-infos 2>&1 | grep -E "(error|warning)" || echo "No critical linter errors found")
if [ -n "$LINT_OUTPUT" ] && [ "$LINT_OUTPUT" != "No critical linter errors found" ]; then
    echo -e "${YELLOW}$LINT_OUTPUT${NC}"
else
    echo -e "${GREEN}✓ No critical linter errors${NC}"
fi
echo ""

# 3. Check Dependencies
echo -e "${BLUE}[3/6] Checking Dependencies...${NC}"
OUTDATED=$(flutter pub outdated 2>&1 | grep -E "outdated|upgrade" || echo "All dependencies up to date")
if echo "$OUTDATED" | grep -q "outdated"; then
    echo -e "${YELLOW}Some dependencies may be outdated:${NC}"
    flutter pub outdated 2>&1 | head -30
    WARNING_COUNT=$((WARNING_COUNT + 1))
else
    echo -e "${GREEN}✓ Dependencies check passed${NC}"
fi
echo ""

# 4. Check for Unused Imports/Variables
echo -e "${BLUE}[4/6] Checking for Unused Code...${NC}"
UNUSED=$(echo "$ANALYZE_OUTPUT" | grep -E "unused" || echo "No unused code found")
if [ "$UNUSED" != "No unused code found" ]; then
    echo -e "${YELLOW}Unused code detected:${NC}"
    echo "$UNUSED"
    WARNING_COUNT=$((WARNING_COUNT + 1))
else
    echo -e "${GREEN}✓ No unused code detected${NC}"
fi
echo ""

# 5. Check for Deprecated APIs
echo -e "${BLUE}[5/6] Checking for Deprecated APIs...${NC}"
DEPRECATED=$(echo "$ANALYZE_OUTPUT" | grep -E "deprecated" || echo "No deprecated APIs found")
if [ "$DEPRECATED" != "No deprecated APIs found" ]; then
    DEPRECATED_COUNT=$(echo "$DEPRECATED" | wc -l)
    echo -e "${YELLOW}Found $DEPRECATED_COUNT deprecated API usage(s):${NC}"
    echo "$DEPRECATED" | head -10
    if [ "$DEPRECATED_COUNT" -gt 10 ]; then
        echo -e "${YELLOW}... and $((DEPRECATED_COUNT - 10)) more${NC}"
    fi
    WARNING_COUNT=$((WARNING_COUNT + 1))
else
    echo -e "${GREEN}✓ No deprecated APIs found${NC}"
fi
echo ""

# 6. Check Build
echo -e "${BLUE}[6/6] Checking if App Builds...${NC}"
if flutter build apk --debug --no-tree-shake-icons 2>&1 | grep -q "Built build"; then
    echo -e "${GREEN}✓ App builds successfully${NC}"
else
    echo -e "${RED}✗ Build check failed or incomplete${NC}"
    ERROR_COUNT=$((ERROR_COUNT + 1))
fi
echo ""

# Summary
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Summary${NC}"
echo -e "${CYAN}========================================${NC}"
echo -e "Total Issues Found: ${YELLOW}$ISSUE_COUNT${NC}"
echo -e "Errors: ${RED}$ERROR_COUNT${NC}"
echo -e "Warnings: ${YELLOW}$WARNING_COUNT${NC}"
echo ""

if [ $ERROR_COUNT -eq 0 ] && [ $WARNING_COUNT -eq 0 ]; then
    echo -e "${GREEN}✓ No critical issues found!${NC}"
    exit 0
elif [ $ERROR_COUNT -eq 0 ]; then
    echo -e "${YELLOW}⚠ Some warnings found, but no errors${NC}"
    exit 0
else
    echo -e "${RED}✗ Critical issues found!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Review the errors above"
    echo "2. Run 'flutter analyze' for detailed information"
    echo "3. Fix errors before committing"
    exit 1
fi

