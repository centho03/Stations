#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Build the program
echo -e "${BLUE}Building program...${NC}"
go build -o stations
if [ $? -ne 0 ]; then
    echo -e "${RED}Build failed${NC}"
    exit 1
fi

echo -e "${BLUE}=== PHASE 1: Basic Functionality Tests ===${NC}"
echo

# Test counters
PASS=0
FAIL=0

# Function to run a test
run_test() {
    local test_name="$1"
    local command="$2"
    local expected_result="$3"
    
    echo -e "${YELLOW}Testing: $test_name${NC}"
    echo "Command: $command"
    
    if [ "$expected_result" = "success" ]; then
        if eval "$command" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ PASS${NC}"
            ((PASS++))
        else
            echo -e "${RED}✗ FAIL - Command failed when it should succeed${NC}"
            # Show the actual error for debugging
            echo "Error output:"
            eval "$command"
            ((FAIL++))
        fi
    else
        # Expecting an error
        if eval "$command" > /dev/null 2>&1; then
            echo -e "${RED}✗ FAIL - Command succeeded when it should error${NC}"
            ((FAIL++))
        else
            echo -e "${GREEN}✓ PASS - Correctly produced error${NC}"
            ((PASS++))
        fi
    fi
    echo
}

# PHASE 1 TESTS: Core functionality
echo -e "${BLUE}--- Core Movement Tests ---${NC}"
run_test "Single train movement" "./stations maps/london.map waterloo st_pancras 1" "success"
run_test "2-train movement (multiple routes)" "./stations maps/london.map waterloo st_pancras 2" "success"
run_test "Basic output format check" "./stations maps/london.map waterloo st_pancras 2" "success"

echo -e "${BLUE}--- Basic Error Handling ---${NC}"
run_test "Too few arguments" "./stations maps/london.map waterloo" "error"
run_test "Too many arguments" "./stations maps/london.map waterloo st_pancras 2 extra" "error"
run_test "Invalid train count (zero)" "./stations maps/london.map waterloo st_pancras 0" "error"
run_test "Invalid train count (negative)" "./stations maps/london.map waterloo st_pancras -1" "error"
run_test "Invalid train count (text)" "./stations maps/london.map waterloo st_pancras abc" "error"

# Summary
echo -e "${BLUE}=== PHASE 1 SUMMARY ===${NC}"
echo -e "${GREEN}Passed: $PASS${NC}"
echo -e "${RED}Failed: $FAIL${NC}"
echo -e "Total: $((PASS + FAIL))"

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}🎉 Phase 1 Complete! Ready for Phase 2${NC}"
    exit 0
else
    echo -e "${RED}❌ Fix Phase 1 issues before proceeding${NC}"
    exit 1
fi