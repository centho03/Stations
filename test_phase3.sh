#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Testing Specific Problem Cases ===${NC}"

# Test 1: Simple linear path efficiency
echo -e "\n${YELLOW}Test 1: Linear path with 4 trains${NC}"
echo "Map: A->B->C->D (linear)"
cat > test_linear.map << EOF
stations:
A,0,0
B,1,0
C,2,0
D,3,0

connections:
A-B
B-C
C-D
EOF

echo "Running: ./stations test_linear.map A D 4"
output=$(./stations test_linear.map A D 6 2>/dev/null | wc -l)
echo "Turns taken: $output"
echo "Expected: ≤ 6 turns"

# Test 2: Complex path with multiple routes
echo -e "\n${YELLOW}Test 2: Multiple routes test${NC}"
echo "Testing London map with different train counts..."

for trains in 1 2 3 4 10 20 50 100; do
    echo -n "Trains: $trains - "
    output=$(./stations maps/london.map waterloo st_pancras $trains 2>/dev/null)
    turns=$(echo "$output" | wc -l)
    routes=$(echo "$output" | head -1 | grep -o "T[0-9]*-" | wc -l)
    echo "Turns: $turns, Trains in first turn: $routes"
done

# Test 3: Verify specific test cases from requirements
echo -e "\n${YELLOW}Test 3: Specific requirement tests${NC}"

# Function to test and report
test_case() {
    local name="$1"
    local map="$2"
    local start="$3"
    local end="$4"
    local trains="$5"
    local max_turns="$6"
    
    echo -n "$name: "
    output=$(./stations "$map" "$start" "$end" "$trains" 2>/dev/null)
    actual_turns=$(echo "$output" | wc -l)
    
    if [ "$actual_turns" -le "$max_turns" ]; then
        echo -e "${GREEN}PASS${NC} ($actual_turns ≤ $max_turns turns)"
    else
        echo -e "${RED}FAIL${NC} ($actual_turns > $max_turns turns)"
        echo "First 3 turns:"
        echo "$output" | head -3
    fi
}

# Run the specific test cases if maps exist
if [ -f "maps/space_port.map" ]; then
    test_case "Space Port (4 trains)" "maps/space_port.map" "bond_square" "space_port" "4" "6"
fi

if [ -f "maps/desert.map" ]; then
    test_case "Desert (10 trains)" "maps/desert.map" "jungle" "desert" "10" "8"
fi

if [ -f "maps/terminus.map" ]; then
    test_case "Terminus (20 trains)" "maps/terminus.map" "beginning" "terminus" "20" "11"
fi

if [ -f "maps/network.map" ]; then
    test_case "Network (4 trains)" "maps/network.map" "two" "four" "4" "6"
fi

if [ -f "maps/beethoven.map" ]; then
    test_case "Beethoven (9 trains)" "maps/beethoven.map" "beethoven" "part" "9" "6"
fi

if [ -f "maps/large.map" ]; then
    test_case "Large (9 trains)" "maps/large.map" "small" "large" "9" "8"
fi

# Cleanup
rm -f test_linear.map

echo -e "\n${BLUE}=== Test Complete ===${NC}"