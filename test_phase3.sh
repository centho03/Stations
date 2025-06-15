#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Build the program
echo -e "${BLUE}Building program...${NC}"
go build -o stations
if [ $? -ne 0 ]; then
    echo -e "${RED}Build failed${NC}"
    exit 1
fi

echo -e "${BLUE}=== PHASE 3: Efficiency & Turn Limit Tests ===${NC}"
echo

# Test counters
PASS=0
FAIL=0

# Function to test turn limits
test_turn_limit() {
    local test_name="$1"
    local command="$2"
    local max_turns="$3"
    local description="$4"
    
    echo -e "${YELLOW}Testing: $test_name${NC}"
    echo "Command: $command"
    echo "Expected: ≤ $max_turns turns"
    echo "Description: $description"
    
    # Run the command and capture output
    local output
    output=$(eval "$command" 2>&1)
    local exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        echo -e "${RED}✗ FAIL - Command failed with error${NC}"
        echo "Error: $output"
        ((FAIL++))
        echo
        return
    fi
    
    # Extract the number of turns from output
    # Look for patterns like "turn XX" or "Turn XX" 
    local actual_turns
    actual_turns=$(echo "$output" | grep -i "turn" | tail -1 | grep -o '[0-9]\+' | tail -1)
    
    if [ -z "$actual_turns" ]; then
        echo -e "${RED}✗ FAIL - Could not determine number of turns from output${NC}"
        echo "Output:"
        echo "$output"
        ((FAIL++))
        echo
        return
    fi
    
    echo "Actual turns: $actual_turns"
    
    if [ "$actual_turns" -le "$max_turns" ]; then
        echo -e "${GREEN}✓ PASS - Completed in $actual_turns turns (≤ $max_turns)${NC}"
        ((PASS++))
    else
        echo -e "${RED}✗ FAIL - Took $actual_turns turns (> $max_turns maximum)${NC}"
        echo "Output:"
        echo "$output"
        ((FAIL++))
    fi
    echo
}

# Function to test basic functionality (should work)
test_basic() {
    local test_name="$1"
    local command="$2"
    
    echo -e "${YELLOW}Testing: $test_name${NC}"
    echo "Command: $command"
    
    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((PASS++))
    else
        echo -e "${RED}✗ FAIL - Command failed${NC}"
        echo "Error output:"
        eval "$command"
        ((FAIL++))
    fi
    echo
}

echo -e "${BLUE}--- London Map Efficiency Tests ---${NC}"
test_turn_limit "London: 1 train (waterloo → st_pancras)" \
    "./stations maps/london.map waterloo st_pancras 1" \
    "4" \
    "Single train should find optimal path quickly"

test_turn_limit "London: 2 trains (waterloo → st_pancras)" \
    "./stations maps/london.map waterloo st_pancras 2" \
    "4" \
    "Two trains should coordinate efficiently"

test_turn_limit "London: 3 trains (waterloo → st_pancras)" \
    "./stations maps/london.map waterloo st_pancras 3" \
    "4" \
    "Three trains require multiple routes"

test_turn_limit "London: 4 trains (waterloo → st_pancras)" \
    "./stations maps/london.map waterloo st_pancras 4" \
    "4" \
    "Four trains push the routing algorithm"

echo -e "${BLUE}--- Space Port Map Efficiency Tests ---${NC}"
test_turn_limit "Space Port: 1 train" \
    "./stations maps/space_port.map bond_square space_port 1" \
    "5" \
    "Single train on space port map"

test_turn_limit "Space Port: 2 trains" \
    "./stations maps/space_port.map bond_square space_port 2" \
    "5" \
    "Two trains on space port map"

echo -e "${BLUE}--- Large Map Efficiency Tests ---${NC}"
test_turn_limit "Large Map: 1 train" \
    "./stations maps/large.map start end 1" \
    "6" \
    "Single train on larger network"

test_turn_limit "Large Map: 2 trains" \
    "./stations maps/large.map start end 2" \
    "6" \
    "Two trains on larger network"

echo -e "${BLUE}--- Edge Case Efficiency Tests ---${NC}"
test_turn_limit "High train count (10 trains)" \
    "./stations maps/london.map waterloo st_pancras 10" \
    "8" \
    "Many trains should still be efficient"

test_turn_limit "Maximum reasonable (50 trains)" \
    "./stations maps/london.map waterloo st_pancras 50" \
    "15" \
    "Stress test with many trains"

echo -e "${BLUE}--- Different Route Tests ---${NC}"
test_basic "Beethoven map basic functionality" \
    "./stations maps/beethoven.map beethoven part 1"

test_basic "Desert map basic functionality" \
    "./stations maps/desert.map jungle desert 1"

# Summary
echo -e "${BLUE}=== PHASE 3 SUMMARY ===${NC}"
echo -e "${GREEN}Passed: $PASS${NC}"
echo -e "${RED}Failed: $FAIL${NC}"
echo -e "Total: $((PASS + FAIL))"

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}🎉 Phase 3 Complete! All efficiency tests passed!${NC}"
    echo -e "${PURPLE}🏆 Your stations program meets all performance requirements!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some efficiency tests failed${NC}"
    echo -e "${YELLOW}Debug tips:${NC}"
    echo "1. Check if your algorithm finds optimal routes"
    echo "2. Verify turn counting is accurate"
    echo "3. Look for inefficient pathfinding or train coordination"
    echo "4. Consider if trains are waiting unnecessarily"
    exit 1
fi