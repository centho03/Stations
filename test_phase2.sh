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

echo -e "${BLUE}=== PHASE 2: Station & Map Validation Tests ===${NC}"
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
            echo "Error output:"
            eval "$command"
            ((FAIL++))
        fi
    else
        # Expecting an error
        if eval "$command" > /dev/null 2>&1; then
            echo -e "${RED}✗ FAIL - Command succeeded when it should error${NC}"
            echo "Command output:"
            eval "$command"
            ((FAIL++))
        else
            echo -e "${GREEN}✓ PASS - Correctly produced error${NC}"
            ((PASS++))
        fi
    fi
    echo
}

echo -e "${BLUE}--- Station Existence Tests ---${NC}"
run_test "Nonexistent start station" "./stations maps/london.map notreal st_pancras 2" "error"
run_test "Nonexistent end station" "./stations maps/london.map waterloo notreal 2" "error"
run_test "Same start and end station" "./stations maps/london.map waterloo waterloo 2" "error"

echo -e "${BLUE}--- Path Validation Tests ---${NC}"
run_test "No path exists (disconnected map)" "./stations maps/no_connections.map station1 station2 1" "error"

echo -e "${BLUE}--- Multiple Train Route Tests (London Map) ---${NC}"
run_test "3 trains - multiple routes required" "./stations maps/london.map waterloo st_pancras 3" "success"
run_test "4 trains - multiple routes required" "./stations maps/london.map waterloo st_pancras 4" "success"
run_test "Large number of trains (100)" "./stations maps/london.map waterloo st_pancras 100" "success"

echo -e "${BLUE}--- Additional Map Tests ---${NC}"
run_test "Space port map - basic functionality" "./stations maps/space_port.map bond_square space_port 2" "success"
run_test "Desert map - basic functionality" "./stations maps/desert.map jungle desert 2" "success"
run_test "Beethoven map - basic functionality" "./stations maps/beethoven.map beethoven part 2" "success"

# Summary
echo -e "${BLUE}=== PHASE 2 SUMMARY ===${NC}"
echo -e "${GREEN}Passed: $PASS${NC}"
echo -e "${RED}Failed: $FAIL${NC}"
echo -e "Total: $((PASS + FAIL))"

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}🎉 Phase 2 Complete! Ready for Phase 3${NC}"
    exit 0
else
    echo -e "${RED}❌ Fix Phase 2 issues before proceeding${NC}"
    exit 1
fi