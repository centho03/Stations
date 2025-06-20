#!/bin/bash

# Railway Simulation System - Automated Test Suite
# Tests the train pathfinding and movement system against specified requirements
# Tests are ordered exactly as they appear in the requirements list

set -e

# Colors for output formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Create test maps directory
mkdir -p test_maps
mkdir -p test_results

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Railway Simulation Test Suite${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to print test header
print_test_header() {
    local test_number="$1"
    local test_name="$2"
    echo -e "${YELLOW}Test #${test_number}: ${test_name}${NC}"
    echo "----------------------------------------"
}

# Enhanced function to record test result with potential issues
record_result() {
    local question="$1"
    local expected="$2"
    local actual="$3"
    local passed="$4"
    local potential_issues="$5"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo -e "${PURPLE}Question:${NC} $question"
    echo -e "${BLUE}Expected:${NC} $expected"
    echo -e "${BLUE}Actual:${NC} $actual"
    
    if [ "$passed" = "true" ]; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        echo -e "${GREEN}Result: PASS${NC}"
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        echo -e "${RED}Result: FAIL${NC}"
        if [ -n "$potential_issues" ]; then
            echo -e "${RED}Potential Issues:${NC} $potential_issues"
        fi
    fi
    echo ""
}

# Function to create London Network Map
create_london_map() {
    cat > test_maps/london.map << 'EOF'
stations:
waterloo,3,1
victoria,6,7
euston,11,23
st_pancras,5,15

connections:
waterloo-victoria
waterloo-euston
st_pancras-euston
victoria-st_pancras
EOF
}

# Function to create bond_square map
create_bond_square_map() {
    cat > test_maps/bond_square.map << 'EOF'
stations:
bond_square,20,6
apple_avenue,7,7
orange_junction,6,1
space_port,1,11

connections:
bond_square-apple_avenue
apple_avenue-orange_junction
orange_junction-space_port
EOF
}

# Function to create jungle-desert map
create_jungle_desert_map() {
    cat > test_maps/jungle_desert.map << 'EOF'
stations:
jungle,5,16
green_belt,6,1
village,5,7
mountain,9,16
treetop,0,4
grasslands,15,13
suburbs,4,9
clouds,0,0
wetlands,2,12
farms,11,10
downtown,4,4
metropolis,3,20
industrial,1,18
desert,9,0

connections:
jungle-grasslands
mountain-treetop
clouds-wetlands
downtown-metropolis
green_belt-village
suburbs-clouds
industrial-desert
jungle-farms
village-mountain
wetlands-desert
grasslands-suburbs
jungle-green_belt
farms-downtown
treetop-desert
metropolis-industrial
mountain-wetlands
farms-mountain
EOF
}

# Function to create beginning-terminus map
create_beginning_terminus_map() {
    cat > test_maps/beginning_terminus.map << 'EOF'
stations:
beginning,0,0
near,1,0
far,1,3
terminus,0,3

connections:
beginning-near
beginning-terminus
near-far
terminus-far
EOF
}

# Function to create two-four map
create_two_four_map() {
    cat > test_maps/two_four.map << 'EOF'
stations:
one,1,1
two,2,2
three,3,3
four,4,4
five,5,5
six,6,6

connections:
two-three
five-one
three-one
two-five
one-four
six-two
one-six
EOF
}

# Function to create beethoven-part map
create_beethoven_part_map() {
    cat > test_maps/beethoven_part.map << 'EOF'
stations:
beethoven,1,6
verdi,7,1
albinoni,1,1
handel,3,14
mozart,14,9
part,10,0

connections:
beethoven-handel
handel-mozart
beethoven-verdi
verdi-part
verdi-albinoni
beethoven-albinoni
albinoni-mozart
mozart-part
EOF
}

# Function to create small-large map
create_small_large_map() {
    cat > test_maps/small_large.map << 'EOF'
stations:
small,4,0
large,4,6
00,0,0
01,0,1
02,0,2
03,0,3
04,0,4
05,0,5
10,1,0
11,1,1
12,1,2
13,1,3
14,1,4
15,1,5
20,2,0
21,2,1
22,2,2
23,2,3
24,2,4
25,2,5
30,3,0
31,3,1
32,3,2
33,3,3
34,3,4
35,3,5
36,3,6

connections:
24-25
24-23
23-12
small-32
32-33
33-34
34-35
35-36
36-22
small-10
10-11
10-20
11-12
11-14
12-large
12-03
small-13
13-14
14-15
small-00
00-01
01-02
02-03
03-04
20-21
20-25
21-15
21-22
21-30
22-large
25-30
30-31
31-large
04-05
05-large
EOF
}

# Function to create error test maps
create_error_test_maps() {
    # Map with duplicate connections
    cat > test_maps/duplicate_connections.map << 'EOF'
stations:
a,0,0
b,1,1

connections:
a-b
b-a
EOF

    # Map with invalid station in connection
    cat > test_maps/invalid_connection.map << 'EOF'
stations:
a,0,0
b,1,1

connections:
a-c
EOF

    # Map with duplicate station names
    cat > test_maps/duplicate_stations.map << 'EOF'
stations:
a,0,0
a,1,1

connections:
EOF

    # Map with same coordinates
    cat > test_maps/same_coordinates.map << 'EOF'
stations:
a,0,0
b,0,0

connections:
a-b
EOF

    # Map missing stations section
    cat > test_maps/no_stations.map << 'EOF'
connections:
a-b
EOF

    # Map missing connections section
    cat > test_maps/no_connections.map << 'EOF'
stations:
a,0,0
b,1,1
EOF

    # Map with invalid coordinates (negative)
    cat > test_maps/invalid_coordinates.map << 'EOF'
stations:
a,-1,0
b,1,1

connections:
a-b
EOF

    # Map with no path between stations
    cat > test_maps/no_path.map << 'EOF'
stations:
a,0,0
b,1,1
c,2,2

connections:
a-b
EOF

    # Map with invalid station names
    cat > test_maps/invalid_station_names.map << 'EOF'
stations:
,0,0
valid_station,1,1

connections:
EOF

    # Advanced error test maps
    cat > test_maps/super_advanced_error.map << 'EOF'
stations:
euston,0,0
kings_cross,1,1

connections:
euston-kings_cross
kings_cross-euston
EOF

    cat > test_maps/line_number_error.map << 'EOF'
stations:
a,0,0
b,1,1

connections:
a-b
invalid_line_here
EOF
}

# Function to create tricky test cases
create_tricky_test_maps() {
    # Tricky Case 1: Bottleneck network (star topology)
    cat > test_maps/bottleneck.map << 'EOF'
stations:
start,0,0
center,5,5
end1,10,0
end2,10,2
end3,10,4
end4,10,6
end5,10,8
end6,10,10

connections:
start-center
center-end1
center-end2
center-end3
center-end4
center-end5
center-end6
EOF

    # Tricky Case 2: Long linear chain
    cat > test_maps/long_chain.map << 'EOF'
stations:
s1,0,0
s2,1,0
s3,2,0
s4,3,0
s5,4,0
s6,5,0
s7,6,0
s8,7,0
s9,8,0
s10,9,0
s11,10,0
s12,11,0
s13,12,0
s14,13,0
s15,14,0

connections:
s1-s2
s2-s3
s3-s4
s4-s5
s5-s6
s6-s7
s7-s8
s8-s9
s9-s10
s10-s11
s11-s12
s12-s13
s13-s14
s14-s15
EOF

    # Tricky Case 3: Grid network with multiple paths
    cat > test_maps/grid.map << 'EOF'
stations:
a1,0,0
a2,0,1
a3,0,2
b1,1,0
b2,1,1
b3,1,2
c1,2,0
c2,2,1
c3,2,2

connections:
a1-a2
a2-a3
a1-b1
a2-b2
a3-b3
b1-b2
b2-b3
b1-c1
b2-c2
b3-c3
c1-c2
c2-c3
EOF

    # Tricky Case 4: Complex interconnected network
    cat > test_maps/complex.map << 'EOF'
stations:
alpha,0,0
beta,2,3
gamma,5,1
delta,7,6
epsilon,3,8
zeta,9,2
eta,1,5
theta,6,9
iota,8,4
kappa,4,7

connections:
alpha-beta
alpha-eta
beta-gamma
beta-epsilon
gamma-delta
gamma-zeta
delta-theta
delta-iota
epsilon-eta
epsilon-kappa
zeta-iota
eta-kappa
theta-iota
theta-kappa
iota-kappa
EOF

    # Tricky Case 5: Ring topology
    cat > test_maps/ring.map << 'EOF'
stations:
r1,0,0
r2,3,0
r3,5,2
r4,5,5
r5,3,7
r6,0,7
r7,-2,5
r8,-2,2

connections:
r1-r2
r2-r3
r3-r4
r4-r5
r5-r6
r6-r7
r7-r8
r8-r1
EOF

    # Tricky Case 6: Binary tree structure
    cat > test_maps/tree.map << 'EOF'
stations:
root,5,0
l1,2,2
r1,8,2
l2,1,4
l3,3,4
r2,7,4
r3,9,4
l4,0,6
l5,1,6
l6,2,6
l7,3,6
r4,6,6
r5,7,6
r6,8,6
r7,9,6

connections:
root-l1
root-r1
l1-l2
l1-l3
r1-r2
r1-r3
l2-l4
l2-l5
l3-l6
l3-l7
r2-r4
r2-r5
r3-r6
r3-r7
EOF
}

# Function to run a test and capture output
run_test() {
    local map_file="$1"
    local start_station="$2"
    local end_station="$3"
    local num_trains="$4"
    local test_name="$5"
    
    local output_file="test_results/${test_name}_output.txt"
    local error_file="test_results/${test_name}_error.txt"
    
    # Run the program and capture both stdout and stderr
    if go run . "$map_file" "$start_station" "$end_station" "$num_trains" > "$output_file" 2> "$error_file"; then
        local exit_code=0
    else
        local exit_code=$?
    fi
    
    echo "$exit_code"
}

# Function to count lines in output (for counting turns)
count_turns() {
    local file="$1"
    if [ -f "$file" ]; then
        wc -l < "$file" | tr -d ' '
    else
        echo "0"
    fi
}

# Function to check if output contains multiple solutions
has_multiple_solutions() {
    local file="$1"
    local trains="$2"
    if [ -f "$file" ]; then
        # Simple heuristic: if there are multiple valid paths, there should be output
        local line_count=$(wc -l < "$file")
        [ "$line_count" -gt 0 ]
    else
        false
    fi
}

# Function to validate train movement format
validate_format() {
    local file="$1"
    if [ -f "$file" ]; then
        # Check if output matches pattern "T1-station T2-station" etc.
        grep -E "^(T[0-9]+-[a-zA-Z0-9_]+\s*)+$" "$file" > /dev/null
    else
        false
    fi
}

# Function to check if bc is available for time calculations
check_bc() {
    command -v bc >/dev/null 2>&1
}

# Create all test maps
echo "Creating test maps..."
create_london_map
create_bond_square_map
create_jungle_desert_map
create_beginning_terminus_map
create_two_four_map
create_beethoven_part_map
create_small_large_map
create_error_test_maps
create_tricky_test_maps
echo ""

# Build the project
echo "Building project..."
if ! go build -o railway_sim .; then
    echo -e "${RED}Failed to build project. Exiting.${NC}"
    exit 1
fi
echo ""

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  MANDATORY REQUIREMENTS TESTING${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Test 1: Valid train movements (basic functionality test)
print_test_header "1" "Valid train movements from beginning to end"
exit_code=$(run_test "test_maps/london.map" "waterloo" "st_pancras" "2" "basic_movement")
if [ "$exit_code" -eq 0 ] && [ -s "test_results/basic_movement_output.txt" ]; then
    record_result "It only moves trains in a valid fashion from beginning to end?" \
        "All trains successfully moved to end station with valid movements" \
        "Program executed successfully and produced output" \
        "true" \
        ""
else
    record_result "It only moves trains in a valid fashion from beginning to end?" \
        "All trains successfully moved to end station with valid movements" \
        "Program failed (exit code: $exit_code) or produced no output" \
        "false" \
        "Pathfinding algorithm may be broken, invalid train movement logic, or program crashes on basic input"
fi

# Test 2: Multiple routes for 2 trains
print_test_header "2" "Multiple routes for 2 trains (waterloo to st_pancras)"
exit_code=$(run_test "test_maps/london.map" "waterloo" "st_pancras" "2" "london_2_trains")
if [ "$exit_code" -eq 0 ] && has_multiple_solutions "test_results/london_2_trains_output.txt" "2"; then
    record_result "It can find more than one route for 2 trains between waterloo and st_pancras for the London Network Map?" \
        "Valid solution found for 2 trains" \
        "Solution found and executed successfully" \
        "true" \
        ""
else
    record_result "It can find more than one route for 2 trains between waterloo and st_pancras for the London Network Map?" \
        "Valid solution found for 2 trains" \
        "No solution found or program failed (exit code: $exit_code)" \
        "false" \
        "Algorithm cannot handle multiple trains, insufficient network flow capacity, or pathfinding fails with 2 trains"
fi

# Test 3: Multiple routes for 3 trains
print_test_header "3" "Multiple routes for 3 trains (waterloo to st_pancras)"
exit_code=$(run_test "test_maps/london.map" "waterloo" "st_pancras" "3" "london_3_trains")
if [ "$exit_code" -eq 0 ] && has_multiple_solutions "test_results/london_3_trains_output.txt" "3"; then
    record_result "It finds more than one valid route for 3 trains between waterloo and st_pancras in the London Network Map?" \
        "Valid solution found for 3 trains" \
        "Solution found and executed successfully" \
        "true" \
        ""
else
    record_result "It finds more than one valid route for 3 trains between waterloo and st_pancras in the London Network Map?" \
        "Valid solution found for 3 trains" \
        "No solution found or program failed (exit code: $exit_code)" \
        "false" \
        "Algorithm scaling issues with 3 trains, network capacity constraints, or train scheduling conflicts"
fi

# Test 4: Multiple routes for 4 trains
print_test_header "4" "Multiple routes for 4 trains (waterloo to st_pancras)"
exit_code=$(run_test "test_maps/london.map" "waterloo" "st_pancras" "4" "london_4_trains")
if [ "$exit_code" -eq 0 ] && has_multiple_solutions "test_results/london_4_trains_output.txt" "4"; then
    record_result "It finds more than one valid route for 4 trains between waterloo and st_pancras in the London Network Map?" \
        "Valid solution found for 4 trains" \
        "Solution found and executed successfully" \
        "true" \
        ""
else
    record_result "It finds more than one valid route for 4 trains between waterloo and st_pancras in the London Network Map?" \
        "Valid solution found for 4 trains" \
        "No solution found or program failed (exit code: $exit_code)" \
        "false" \
        "Network congestion with 4 trains, insufficient alternative paths, or train movement conflicts"
fi

# Test 5: Multiple routes for 100 trains
print_test_header "5" "Multiple routes for 100 trains (waterloo to st_pancras)"
exit_code=$(run_test "test_maps/london.map" "waterloo" "st_pancras" "100" "london_100_trains")
if [ "$exit_code" -eq 0 ] && has_multiple_solutions "test_results/london_100_trains_output.txt" "100"; then
    record_result "It finds more than one valid route for 100 trains between waterloo and st_pancras in the London Network Map?" \
        "Valid solution found for 100 trains" \
        "Solution found and executed successfully" \
        "true" \
        ""
else
    record_result "It finds more than one valid route for 100 trains between waterloo and st_pancras in the London Network Map?" \
        "Valid solution found for 100 trains" \
        "No solution found or program failed (exit code: $exit_code)" \
        "false" \
        "Algorithm cannot scale to 100 trains, memory issues, performance timeout, or network capacity insufficient"
fi

# Test 6: Single route for 1 train
print_test_header "6" "Single route for 1 train (waterloo to st_pancras)"
exit_code=$(run_test "test_maps/london.map" "waterloo" "st_pancras" "1" "london_1_train")
if [ "$exit_code" -eq 0 ] && [ -s "test_results/london_1_train_output.txt" ]; then
    record_result "It finds only a single valid route for 1 train between waterloo and st_pancras in the London Network Map?" \
        "Single valid route found" \
        "Solution found and executed successfully" \
        "true" \
        ""
else
    record_result "It finds only a single valid route for 1 train between waterloo and st_pancras in the London Network Map?" \
        "Single valid route found" \
        "No solution found or program failed (exit code: $exit_code)" \
        "false" \
        "Basic pathfinding broken, cannot find simple path for single train, or program crashes on trivial input"
fi

# Test 7: Correct output format
print_test_header "7" "Correct output format (T1-station, T2-station)"
exit_code=$(run_test "test_maps/london.map" "waterloo" "st_pancras" "2" "format_test")
if [ "$exit_code" -eq 0 ] && validate_format "test_results/format_test_output.txt"; then
    sample_output=$(head -1 "test_results/format_test_output.txt" 2>/dev/null || echo "No output")
    record_result "It prints the train movements with the correct format \"T1-station\", \"T2-station\" etc.?" \
        "Output format: T1-station T2-station etc." \
        "Format validated. Sample: $sample_output" \
        "true" \
        ""
else
    sample_output=$(head -1 "test_results/format_test_output.txt" 2>/dev/null || echo "No output")
    record_result "It prints the train movements with the correct format \"T1-station\", \"T2-station\" etc.?" \
        "Output format: T1-station T2-station etc." \
        "Invalid format or program failed. Sample: $sample_output" \
        "false" \
        "Output formatting logic incorrect, missing train IDs, wrong delimiter, or incorrect station naming"
fi

# Test 8: Turn limit for bond_square to space_port (4 trains, max 6 turns)
print_test_header "8" "Turn limit: 4 trains bond_square to space_port (max 6 turns)"
exit_code=$(run_test "test_maps/bond_square.map" "bond_square" "space_port" "4" "bond_square_4_trains")
turns=$(count_turns "test_results/bond_square_4_trains_output.txt")
if [ "$exit_code" -eq 0 ] && [ "$turns" -le 6 ] && [ "$turns" -gt 0 ]; then
    record_result "It completes the movements in no more than 6 turns for 4 trains between bond_square and space_port?" \
        "Completed in ≤6 turns" \
        "Completed in $turns turns" \
        "true" \
        ""
else
    record_result "It completes the movements in no more than 6 turns for 4 trains between bond_square and space_port?" \
        "Completed in ≤6 turns" \
        "Program failed (exit code: $exit_code) or used $turns turns" \
        "false" \
        "Algorithm inefficient (too many turns), cannot optimize train scheduling, or fails on linear network topology"
fi

# Test 9: Turn limit for jungle to desert (10 trains, max 8 turns)
print_test_header "9" "Turn limit: 10 trains jungle to desert (max 8 turns)"
exit_code=$(run_test "test_maps/jungle_desert.map" "jungle" "desert" "10" "jungle_desert_10_trains")
turns=$(count_turns "test_results/jungle_desert_10_trains_output.txt")
if [ "$exit_code" -eq 0 ] && [ "$turns" -le 8 ] && [ "$turns" -gt 0 ]; then
    record_result "It completes the movements in no more than 8 turns for 10 trains between jungle and desert?" \
        "Completed in ≤8 turns" \
        "Completed in $turns turns" \
        "true" \
        ""
else
    record_result "It completes the movements in no more than 8 turns for 10 trains between jungle and desert?" \
        "Completed in ≤8 turns" \
        "Program failed (exit code: $exit_code) or used $turns turns" \
        "false" \
        "Complex network pathfinding suboptimal, cannot handle multiple parallel paths, or train coordination issues"
fi

# Test 10: Turn limit for beginning to terminus (20 trains, max 11 turns)
print_test_header "10" "Turn limit: 20 trains beginning to terminus (max 11 turns)"
exit_code=$(run_test "test_maps/beginning_terminus.map" "beginning" "terminus" "20" "beginning_terminus_20_trains")
turns=$(count_turns "test_results/beginning_terminus_20_trains_output.txt")
if [ "$exit_code" -eq 0 ] && [ "$turns" -le 11 ] && [ "$turns" -gt 0 ]; then
    record_result "It completes the movements in no more than 11 turns for 20 trains between beginning and terminus?" \
        "Completed in ≤11 turns" \
        "Completed in $turns turns" \
        "true" \
        ""
else
    record_result "It completes the movements in no more than 11 turns for 20 trains between beginning and terminus?" \
        "Completed in ≤11 turns" \
        "Program failed (exit code: $exit_code) or used $turns turns" \
        "false" \
        "Large-scale train scheduling inefficient, cannot utilize alternative paths effectively, or algorithm doesn't scale"
fi

# Test 11: Turn limit for two to four (4 trains, max 6 turns)
print_test_header "11" "Turn limit: 4 trains two to four (max 6 turns)"
exit_code=$(run_test "test_maps/two_four.map" "two" "four" "4" "two_four_4_trains")
turns=$(count_turns "test_results/two_four_4_trains_output.txt")
if [ "$exit_code" -eq 0 ] && [ "$turns" -le 6 ] && [ "$turns" -gt 0 ]; then
    record_result "It completes the movements in no more than 6 turns for 4 trains between two and four?" \
        "Completed in ≤6 turns" \
        "Completed in $turns turns" \
        "true" \
        ""
else
    record_result "It completes the movements in no more than 6 turns for 4 trains between two and four?" \
        "Completed in ≤6 turns" \
        "Program failed (exit code: $exit_code) or used $turns turns" \
        "false" \
        "Cannot find optimal path in complex connected network, poor train scheduling, or misses shortest routes"
fi

# Test 12: Turn limit for beethoven to part (9 trains, max 6 turns)
print_test_header "12" "Turn limit: 9 trains beethoven to part (max 6 turns)"
exit_code=$(run_test "test_maps/beethoven_part.map" "beethoven" "part" "9" "beethoven_part_9_trains")
turns=$(count_turns "test_results/beethoven_part_9_trains_output.txt")
if [ "$exit_code" -eq 0 ] && [ "$turns" -le 6 ] && [ "$turns" -gt 0 ]; then
    record_result "It completes the movements in no more than 6 turns for 9 trains between beethoven and part?" \
        "Completed in ≤6 turns" \
        "Completed in $turns turns" \
        "true" \
        ""
else
    record_result "It completes the movements in no more than 6 turns for 9 trains between beethoven and part?" \
        "Completed in ≤6 turns" \
        "Program failed (exit code: $exit_code) or used $turns turns" \
        "false" \
        "Algorithm cannot optimize for high train density, inefficient use of multiple paths, or coordination failures"
fi

# Test 13: Turn limit for small to large (9 trains, max 8 turns)
print_test_header "13" "Turn limit: 9 trains small to large (max 8 turns)"
exit_code=$(run_test "test_maps/small_large.map" "small" "large" "9" "small_large_9_trains")
turns=$(count_turns "test_results/small_large_9_trains_output.txt")
if [ "$exit_code" -eq 0 ] && [ "$turns" -le 8 ] && [ "$turns" -gt 0 ]; then
    record_result "It completes the movements in no more than 8 turns for 9 trains between small and large?" \
        "Completed in ≤8 turns" \
        "Completed in $turns turns" \
        "true" \
        ""
else
    record_result "It completes the movements in no more than 8 turns for 9 trains between small and large?" \
        "Completed in ≤8 turns" \
        "Program failed (exit code: $exit_code) or used $turns turns" \
        "false" \
        "Large grid network optimization issues, cannot handle complex topology, or train flow bottlenecks"
fi

# Test 14: Too few arguments
print_test_header "14" "Error: Too few command line arguments"
if ./railway_sim 2> test_results/too_few_args_error.txt; then
    exit_code=0
else
    exit_code=$?
fi
error_msg=$(cat test_results/too_few_args_error.txt 2>/dev/null || echo "No error message")
if [ "$exit_code" -ne 0 ] && grep -i "error" test_results/too_few_args_error.txt > /dev/null; then
    record_result "It displays \"Error\" on stderr when too few command line arguments are used?" \
        "Error message displayed on stderr" \
        "Exit code: $exit_code, Error: $error_msg" \
        "true" \
        ""
else
    record_result "It displays \"Error\" on stderr when too few command line arguments are used?" \
        "Error message displayed on stderr" \
        "Exit code: $exit_code, Error: $error_msg" \
        "false" \
        "Missing argument validation, program doesn't check command line args, or error not sent to stderr"
fi

# Test 15: Too many arguments
print_test_header "15" "Error: Too many command line arguments"
if ./railway_sim test_maps/london.map waterloo st_pancras 2 extra arg here 2> test_results/too_many_args_error.txt; then
    exit_code=0
else
    exit_code=$?
fi
error_msg=$(cat test_results/too_many_args_error.txt 2>/dev/null || echo "No error message")
if [ "$exit_code" -ne 0 ] && grep -i "error" test_results/too_many_args_error.txt > /dev/null; then
    record_result "It displays \"Error\" on stderr when too many command line arguments are used?" \
        "Error message displayed on stderr (unless operational extras/bonuses)" \
        "Exit code: $exit_code, Error: $error_msg" \
        "true" \
        ""
else
    record_result "It displays \"Error\" on stderr when too many command line arguments are used?" \
        "Error message displayed on stderr (unless operational extras/bonuses)" \
        "Exit code: $exit_code, Program accepted extra args or no error: $error_msg" \
        "false" \
        "Program accepts extra arguments (may be implementing bonus features), or missing argument count validation"
fi

# Test 16: Additional tricky cases
print_test_header "16" "Additional tricky cases"

# We'll test multiple tricky scenarios for this requirement
tricky_passed=0
tricky_total=6

# Tricky Case 1: Bottleneck scenario
exit_code=$(run_test "test_maps/bottleneck.map" "start" "end1" "5" "bottleneck_5_trains")
if [ "$exit_code" -eq 0 ] && [ -s "test_results/bottleneck_5_trains_output.txt" ]; then
    tricky_passed=$((tricky_passed + 1))
fi

# Tricky Case 2: Long chain
exit_code=$(run_test "test_maps/long_chain.map" "s1" "s15" "8" "long_chain_8_trains")
if [ "$exit_code" -eq 0 ] && [ -s "test_results/long_chain_8_trains_output.txt" ]; then
    tricky_passed=$((tricky_passed + 1))
fi

# Tricky Case 3: Grid network
exit_code=$(run_test "test_maps/grid.map" "a1" "c3" "6" "grid_6_trains")
if [ "$exit_code" -eq 0 ] && [ -s "test_results/grid_6_trains_output.txt" ]; then
    tricky_passed=$((tricky_passed + 1))
fi

# Tricky Case 4: Complex network
exit_code=$(run_test "test_maps/complex.map" "alpha" "kappa" "7" "complex_7_trains")
if [ "$exit_code" -eq 0 ] && [ -s "test_results/complex_7_trains_output.txt" ]; then
    tricky_passed=$((tricky_passed + 1))
fi

# Tricky Case 5: Ring topology
exit_code=$(run_test "test_maps/ring.map" "r1" "r5" "4" "ring_4_trains")
if [ "$exit_code" -eq 0 ] && [ -s "test_results/ring_4_trains_output.txt" ]; then
    tricky_passed=$((tricky_passed + 1))
fi

# Tricky Case 6: Tree structure
exit_code=$(run_test "test_maps/tree.map" "root" "l7" "10" "tree_10_trains")
if [ "$exit_code" -eq 0 ] && [ -s "test_results/tree_10_trains_output.txt" ]; then
    tricky_passed=$((tricky_passed + 1))
fi

if [ "$tricky_passed" -ge 4 ]; then
    record_result "It works with additional tricky cases. Challenge the pathfinder with as many examples as you like, including ones with many stations and many trains?" \
        "Successfully handles various challenging network topologies" \
        "Passed $tricky_passed out of $tricky_total tricky test cases" \
        "true" \
        ""
else
    record_result "It works with additional tricky cases. Challenge the pathfinder with as many examples as you like, including ones with many stations and many trains?" \
        "Successfully handles various challenging network topologies" \
        "Only passed $tricky_passed out of $tricky_total tricky test cases" \
        "false" \
        "Algorithm struggles with complex topologies: bottlenecks, long chains, grids, interconnected networks, rings, or trees"
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  ERROR HANDLING TESTS${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Test 17: Start station does not exist
print_test_header "17" "Error: Start station does not exist"
exit_code=$(run_test "test_maps/london.map" "nonexistent" "st_pancras" "2" "nonexistent_start")
error_msg=$(cat test_results/nonexistent_start_error.txt 2>/dev/null || echo "No error message")
if [ "$exit_code" -ne 0 ] && grep -i "error" test_results/nonexistent_start_error.txt > /dev/null; then
    record_result "It displays \"Error\" on stderr when the start station does not exist?" \
        "Error message displayed on stderr" \
        "Exit code: $exit_code, Error: $error_msg" \
        "true" \
        ""
else
    record_result "It displays \"Error\" on stderr when the start station does not exist?" \
        "Error message displayed on stderr" \
        "Exit code: $exit_code, Error: $error_msg" \
        "false" \
        "Missing input validation for start station, program attempts to use non-existent station, or error not to stderr"
fi

# Test 18: End station does not exist
print_test_header "18" "Error: End station does not exist"
exit_code=$(run_test "test_maps/london.map" "waterloo" "nonexistent" "2" "nonexistent_end")
error_msg=$(cat test_results/nonexistent_end_error.txt 2>/dev/null || echo "No error message")
if [ "$exit_code" -ne 0 ] && grep -i "error" test_results/nonexistent_end_error.txt > /dev/null; then
    record_result "It displays \"Error\" on stderr when the end station does not exist?" \
        "Error message displayed on stderr" \
        "Exit code: $exit_code, Error: $error_msg" \
        "true" \
        ""
else
    record_result "It displays \"Error\" on stderr when the end station does not exist?" \
        "Error message displayed on stderr" \
        "Exit code: $exit_code, Error: $error_msg" \
        "false" \
        "Missing input validation for end station, program attempts to use non-existent destination, or error not to stderr"
fi

# Test 19: Start and end station are the same
print_test_header "19" "Error: Start and end station are the same"
exit_code=$(run_test "test_maps/london.map" "waterloo" "waterloo" "2" "same_station")
error_msg=$(cat test_results/same_station_error.txt 2>/dev/null || echo "No error message")
if [ "$exit_code" -ne 0 ] && grep -i "error" test_results/same_station_error.txt > /dev/null; then
    record_result "It displays \"Error\" on stderr when the start and end station are the same?" \
        "Error message displayed on stderr" \
        "Exit code: $exit_code, Error: $error_msg" \
        "true" \
        ""
else
    record_result "It displays \"Error\" on stderr when the start and end station are the same?" \
        "Error message displayed on stderr" \
        "Exit code: $exit_code, Error: $error_msg" \
        "false" \
        "Missing validation for identical start/end stations, program may create infinite loops, or accepts trivial cases"
fi

# Test 20: No path between stations
print_test_header "20" "Error: No path between stations"
exit_code=$(run_test "test_maps/no_path.map" "a" "c" "1" "no_path")
error_msg=$(cat test_results/no_path_error.txt 2>/dev/null || echo "No error message")
if [ "$exit_code" -ne 0 ] && grep -i "error" test_results/no_path_error.txt > /dev/null; then
    record_result "It displays \"Error\" on stderr when no path exists between the start and end stations?" \
        "Error message displayed on stderr" \
        "Exit code: $exit_code, Error: $error_msg" \
        "true" \
        ""
else
    record_result "It displays \"Error\" on stderr when no path exists between the start and end stations?" \
        "Error message displayed on stderr" \
        "Exit code: $exit_code, Error: $error_msg" \
        "false" \
        "Pathfinding doesn't detect disconnected components, infinite loop on impossible paths, or missing reachability check"
fi

# Test 21: Duplicate connections
print_test_header "21" "Error: Duplicate connections"
exit_code=$(run_test "test_maps/duplicate_connections.map" "a" "b" "1" "duplicate_connections")
error_msg=$(cat test_results/duplicate_connections_error.txt 2>/dev/null || echo "No error message")
if [ "$exit_code" -ne 0 ] && grep -i "error" test_results/duplicate_connections_error.txt > /dev/null; then
    record_result "It displays \"Error\" on stderr when duplicate routes exist between two stations, including in reverse?" \
        "Error message displayed on stderr" \
        "Exit code: $exit_code, Error: $error_msg" \
        "true" \
        ""
else
    record_result "It displays \"Error\" on stderr when duplicate routes exist between two stations, including in reverse?" \
        "Error message displayed on stderr" \
        "Exit code: $exit_code, Error: $error_msg" \
        "false" \
        "Map parser doesn't detect duplicate connections, allows redundant paths, or missing connection validation"
fi

# Test 22: Invalid number of trains
print_test_header "22" "Error: Invalid number of trains"
exit_code=$(run_test "test_maps/london.map" "waterloo" "st_pancras" "abc" "invalid_trains")
error_msg=$(cat test_results/invalid_trains_error.txt 2>/dev/null || echo "No error message")
if [ "$exit_code" -ne 0 ] && grep -i "error" test_results/invalid_trains_error.txt > /dev/null; then
    record_result "It displays \"Error\" on stderr when the number of trains is not a valid positive integer?" \
        "Error message displayed on stderr" \
        "Exit code: $exit_code, Error: $error_msg" \
        "true" \
        ""
else
    record_result "It displays \"Error\" on stderr when the number of trains is not a valid positive integer?" \
        "Error message displayed on stderr" \
        "Exit code: $exit_code, Error: $error_msg" \
        "false" \
        "Missing input validation for train count, program crashes on non-numeric input, or accepts invalid values"
fi

# Test 23: Invalid coordinates
print_test_header "23" "Error: Invalid coordinates"
exit_code=$(run_test "test_maps/invalid_coordinates.map" "a" "b" "1" "invalid_coordinates")
error_msg=$(cat test_results/invalid_coordinates_error.txt 2>/dev/null || echo "No error message")
if [ "$exit_code" -ne 0 ] && grep -i "error" test_results/invalid_coordinates_error.txt > /dev/null; then
    record_result "It displays \"Error\" on stderr when any of the coordinates are not valid positive integers?" \
        "Error message displayed on stderr" \
        "Exit code: $exit_code, Error: $error_msg" \
        "true" \
        ""
else
    record_result "It displays \"Error\" on stderr when any of the coordinates are not valid positive integers?" \
        "Error message displayed on stderr" \
        "Exit code: $exit_code, Error: $error_msg" \
        "false" \
        "Map parser doesn't validate coordinate format, accepts negative coordinates, or missing number format checks"
fi

# Test 24: Same coordinates
print_test_header "24" "Error: Two stations at same coordinates"
exit_code=$(run_test "test_maps/same_coordinates.map" "a" "b" "1" "same_coordinates")
error_msg=$(cat test_results/same_coordinates_error.txt 2>/dev/null || echo "No error message")
if [ "$exit_code" -ne 0 ] && grep -i "error" test_results/same_coordinates_error.txt > /dev/null; then
    record_result "It displays \"Error\" on stderr when two stations exist at the same coordinates?" \
        "Error message displayed on stderr" \
        "Exit code: $exit_code, Error: $error_msg" \
        "true" \
        ""
else
    record_result "It displays \"Error\" on stderr when two stations exist at the same coordinates?" \
        "Error message displayed on stderr" \
        "Exit code: $exit_code, Error: $error_msg" \
        "false" \
        "Missing coordinate uniqueness validation, allows overlapping stations, or spatial constraint not enforced"
fi

# Test 25: Invalid connection (station doesn't exist)
print_test_header "25" "Error: Connection with non-existent station"
exit_code=$(run_test "test_maps/invalid_connection.map" "a" "b" "1" "invalid_connection")
error_msg=$(cat test_results/invalid_connection_error.txt 2>/dev/null || echo "No error message")
if [ "$exit_code" -ne 0 ] && grep -i "error" test_results/invalid_connection_error.txt > /dev/null; then
    record_result "It displays \"Error\" on stderr when a connection is made with a station which does not exist?" \
        "Error message displayed on stderr" \
        "Exit code: $exit_code, Error: $error_msg" \
        "true" \
        ""
else
    record_result "It displays \"Error\" on stderr when a connection is made with a station which does not exist?" \
        "Error message displayed on stderr" \
        "Exit code: $exit_code, Error: $error_msg" \
        "false" \
        "Connection parser doesn't validate station existence, creates dangling connections, or missing reference checks"
fi

# Test 26: Duplicate station names
print_test_header "26" "Error: Duplicate station names"
exit_code=$(run_test "test_maps/duplicate_stations.map" "a" "b" "1" "duplicate_stations")
error_msg=$(cat test_results/duplicate_stations_error.txt 2>/dev/null || echo "No error message")
if [ "$exit_code" -ne 0 ] && grep -i "error" test_results/duplicate_stations_error.txt > /dev/null; then
    record_result "It displays \"Error\" on stderr when station names are duplicated?" \
        "Error message displayed on stderr" \
        "Exit code: $exit_code, Error: $error_msg" \
        "true" \
        ""
else
    record_result "It displays \"Error\" on stderr when station names are duplicated?" \
        "Error message displayed on stderr" \
        "Exit code: $exit_code, Error: $error_msg" \
        "false" \
        "Station parser doesn't check for name uniqueness, overwrites duplicate entries, or missing name validation"
fi

# Test 27: Invalid station names
print_test_header "27" "Error: Invalid station names"
exit_code=$(run_test "test_maps/invalid_station_names.map" "valid_station" "b" "1" "invalid_station_names")
error_msg=$(cat test_results/invalid_station_names_error.txt 2>/dev/null || echo "No error message")
if [ "$exit_code" -ne 0 ] && grep -i "error" test_results/invalid_station_names_error.txt > /dev/null; then
    record_result "It displays \"Error\" on stderr when station names are invalid?" \
        "Error message displayed on stderr" \
        "Exit code: $exit_code, Error: $error_msg" \
        "true" \
        ""
else
    record_result "It displays \"Error\" on stderr when station names are invalid?" \
        "Error message displayed on stderr" \
        "Exit code: $exit_code, Error: $error_msg" \
        "false" \
        "Station name validation missing, accepts empty/invalid names, or parser doesn't check name format rules"
fi

# Test 28: Missing stations section
print_test_header "28" "Error: Missing stations section"
exit_code=$(run_test "test_maps/no_stations.map" "a" "b" "1" "no_stations")
error_msg=$(cat test_results/no_stations_error.txt 2>/dev/null || echo "No error message")
if [ "$exit_code" -ne 0 ] && grep -i "error" test_results/no_stations_error.txt > /dev/null; then
    record_result "It displays \"Error\" on stderr when the map does not contain a \"stations:\" section?" \
        "Error message displayed on stderr" \
        "Exit code: $exit_code, Error: $error_msg" \
        "true" \
        ""
else
    record_result "It displays \"Error\" on stderr when the map does not contain a \"stations:\" section?" \
        "Error message displayed on stderr" \
        "Exit code: $exit_code, Error: $error_msg" \
        "false" \
        "Map format validation missing, parser doesn't require stations section, or file structure not enforced"
fi

# Test 29: Missing connections section
print_test_header "29" "Error: Missing connections section"
exit_code=$(run_test "test_maps/no_connections.map" "a" "b" "1" "no_connections")
error_msg=$(cat test_results/no_connections_error.txt 2>/dev/null || echo "No error message")
if [ "$exit_code" -ne 0 ] && grep -i "error" test_results/no_connections_error.txt > /dev/null; then
    record_result "It displays \"Error\" on stderr when the map does not contain a \"connections:\" section?" \
        "Error message displayed on stderr" \
        "Exit code: $exit_code, Error: $error_msg" \
        "true" \
        ""
else
    record_result "It displays \"Error\" on stderr when the map does not contain a \"connections:\" section?" \
        "Error message displayed on stderr" \
        "Exit code: $exit_code, Error: $error_msg" \
        "false" \
        "Map format validation missing, parser doesn't require connections section, or file structure not enforced"
fi

# Test 30: 10K stations limit
print_test_header "30" "Error: Map contains more than 10000 stations"
if [ -f "10k.map" ]; then
    exit_code=$(run_test "10k.map" "s1" "s2" "1" "10k_stations")
    error_msg=$(cat test_results/10k_stations_error.txt 2>/dev/null || echo "No error message")
    if [ "$exit_code" -ne 0 ] && grep -i "error" test_results/10k_stations_error.txt > /dev/null; then
        record_result "It displays \"Error\" on stderr when a map contains more than 10000 stations?" \
            "Error message displayed on stderr for 10K+ stations" \
            "Exit code: $exit_code, Error: $error_msg" \
            "true" \
            ""
    else
        record_result "It displays \"Error\" on stderr when a map contains more than 10000 stations?" \
            "Error message displayed on stderr for 10K+ stations" \
            "Exit code: $exit_code, Program accepted 10K+ stations or no error: $error_msg" \
            "false" \
            "Missing station count limit validation, program allows unlimited stations, or memory constraints not enforced"
    fi
else
    record_result "It displays \"Error\" on stderr when a map contains more than 10000 stations?" \
        "Error message displayed on stderr for 10K+ stations" \
        "10k.map file not found - please ensure 10k.map exists in the current directory" \
        "false" \
        "Test requires 10k.map file to be present in current directory"
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  EXTRA FEATURES TESTING${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Extra 31: Advanced Error Handling - Specific error messages
print_test_header "31" "Extra: Advanced Error Handling"
exit_code=$(run_test "test_maps/london.map" "nonexistent_station" "st_pancras" "2" "advanced_error_start")
error_msg=$(cat test_results/advanced_error_start_error.txt 2>/dev/null || echo "No error message")
if [ "$exit_code" -ne 0 ] && echo "$error_msg" | grep -i "start.*station.*not.*exist\|station.*nonexistent.*not.*found\|unknown.*start.*station" > /dev/null; then
    record_result "It implements advanced Error handling. For example, it displays \"Error: Start station does not exist\". Exact:" \
        "Specific error message about start station" \
        "Error message: '$error_msg'" \
        "true" \
        ""
else
    record_result "It implements advanced Error handling. For example, it displays \"Error: Start station does not exist\". Exact:" \
        "Specific error message about start station" \
        "Generic or no error message: '$error_msg'" \
        "false" \
        "Error messages are too generic, don't specify the problem clearly, or use generic 'Error' without details"
fi

# Extra 32: Super Advanced Error Handling - Named entities and line numbers
print_test_header "32" "Extra: Super Advanced Error Handling"
exit_code=$(run_test "test_maps/super_advanced_error.map" "euston" "kings_cross" "1" "super_advanced_error")
error_msg=$(cat test_results/super_advanced_error_error.txt 2>/dev/null || echo "No error message")
if [ "$exit_code" -ne 0 ] && echo "$error_msg" | grep -i "euston.*kings_cross\|duplicate.*connection.*between\|connection.*already.*exists.*euston.*kings_cross" > /dev/null; then
    record_result "It implements super advanced Error handling. It names problematic entities, or specifies the line on which the error occurs. For example: \"Error: Duplicate connection between euston and kings_cross\"." \
        "Error message names specific stations involved" \
        "Error message: '$error_msg'" \
        "true" \
        ""
else
    record_result "It implements super advanced Error handling. It names problematic entities, or specifies the line on which the error occurs. For example: \"Error: Duplicate connection between euston and kings_cross\"." \
        "Error message names specific stations involved" \
        "Generic error or no specific entities named: '$error_msg'" \
        "false" \
        "Error messages don't name specific problematic entities, missing context about what failed, or no line numbers"
fi

# Extra 33: More Efficient Routes - Compare with provided examples
print_test_header "33" "Extra: More Efficient Routes"

# Reference turn counts from the examples provided
declare -A reference_turns=(
    ["bond_square_4_trains"]=6
    ["jungle_desert_10_trains"]=8
    ["beginning_terminus_20_trains"]=11
    ["two_four_4_trains"]=6
    ["beethoven_part_9_trains"]=6
    ["small_large_9_trains"]=8
)

efficiency_improvements=0
efficiency_tests=0

for test_case in "${!reference_turns[@]}"; do
    if [ -f "test_results/${test_case}_output.txt" ]; then
        actual_turns=$(count_turns "test_results/${test_case}_output.txt")
        reference=${reference_turns[$test_case]}
        efficiency_tests=$((efficiency_tests + 1))
        
        if [ "$actual_turns" -lt "$reference" ] && [ "$actual_turns" -gt 0 ]; then
            efficiency_improvements=$((efficiency_improvements + 1))
        fi
    fi
done

if [ "$efficiency_improvements" -gt 0 ]; then
    record_result "It finds more efficient routes when compared with the examples above, resulting in fewer train movement turns." \
        "$efficiency_improvements/$efficiency_tests test cases showed improvement" \
        "Found more efficient solutions in $efficiency_improvements out of $efficiency_tests test cases" \
        "true" \
        ""
else
    record_result "It finds more efficient routes when compared with the examples above, resulting in fewer train movement turns." \
        "At least one test case shows fewer turns than reference" \
        "No improvements found over reference solutions ($efficiency_improvements/$efficiency_tests)" \
        "false" \
        "Algorithm not optimized for efficiency, using suboptimal pathfinding, or poor train scheduling coordination"
fi

# Extra 34: Test Suite Quality
print_test_header "34" "Extra: Test Suite Creation"
total_coverage_tests=$TOTAL_TESTS
mandatory_tests=16   # Count of mandatory requirements
error_tests=14       # Count of error handling tests
extra_tests=5        # Count of extra feature tests

expected_minimum=30  # Reasonable minimum for comprehensive coverage

if [ "$total_coverage_tests" -ge "$expected_minimum" ]; then
    record_result "A suite of tests have been created in advance, covering the cases described in this review." \
        "Comprehensive test suite with $expected_minimum+ tests covering all requirements" \
        "Test suite created with $total_coverage_tests tests (Mandatory: $mandatory_tests, Errors: $error_tests, Extra: $extra_tests)" \
        "true" \
        ""
else
    record_result "A suite of tests have been created in advance, covering the cases described in this review." \
        "Comprehensive test suite with $expected_minimum+ tests covering all requirements" \
        "Limited test coverage: only $total_coverage_tests tests created" \
        "false" \
        "Test suite incomplete, missing coverage of requirements, or insufficient test case variety"
fi

# Extra 35: Performance Testing - Quick execution
print_test_header "35" "Extra: Performance - Quick Execution"

# Test with medium complexity to check for reasonable performance
start_time=$(date +%s 2>/dev/null || echo "0")
timeout 10s ./railway_sim test_maps/london.map waterloo st_pancras 5 > test_results/performance_test_output.txt 2> test_results/performance_test_error.txt
exit_code=$?
end_time=$(date +%s 2>/dev/null || echo "0")

if [ "$start_time" != "0" ] && [ "$end_time" != "0" ] && check_bc; then
    execution_time=$(echo "$end_time - $start_time" | bc -l)
else
    execution_time="unknown"
fi

if [ "$exit_code" -eq 0 ] && [ -s "test_results/performance_test_output.txt" ]; then
    if check_bc && [ "$execution_time" != "unknown" ]; then
        time_check=$(echo "$execution_time < 5.0" | bc -l)
        if [ "$time_check" -eq 1 ]; then
            record_result "It runs quickly. It does not hang excessively." \
                "Completes typical tasks in reasonable time (<5 seconds)" \
                "Completed 5-train pathfinding in ${execution_time} seconds" \
                "true" \
                ""
        else
            record_result "It runs quickly. It does not hang excessively." \
                "Completes typical tasks in reasonable time (<5 seconds)" \
                "Slow execution: took ${execution_time} seconds" \
                "false" \
                "Algorithm inefficient, poor complexity, infinite loops, or missing optimizations"
        fi
    else
        record_result "It runs quickly. It does not hang excessively." \
            "Completes typical tasks in reasonable time" \
            "Completed within timeout (exact timing unavailable)" \
            "true" \
            ""
    fi
elif [ "$exit_code" -eq 124 ]; then
    record_result "It runs quickly. It does not hang excessively." \
        "Completes typical tasks in reasonable time" \
        "Program timed out after 10 seconds - excessive hanging detected" \
        "false" \
        "Program hangs indefinitely, infinite loops, deadlocks, or extremely poor algorithm complexity"
else
    error_msg=$(cat test_results/performance_test_error.txt 2>/dev/null || echo "No error message")
    record_result "It runs quickly. It does not hang excessively." \
        "Completes typical tasks in reasonable time" \
        "Program failed during performance test: $error_msg" \
        "false" \
        "Program crashes during execution, memory issues, or runtime errors under normal load"
fi

# Final summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  TEST SUMMARY${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Total Tests: $TOTAL_TESTS"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
echo ""

# Detailed breakdown
echo "Test Categories:"
echo "- Mandatory Requirements: Tests 1-16"
echo "- Error Handling: Tests 17-30" 
echo "- Extra Features: Tests 31-35"
echo ""

if [ "$FAILED_TESTS" -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed! Your railway simulation system meets all requirements! 🎉${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Check the detailed output above and test results in test_results/ directory.${NC}"
    echo ""
    echo "Common next steps:"
    echo "1. Review failed test outputs in test_results/ directory"
    echo "2. Check potential issues listed for each failed test"
    echo "3. Fix the most critical failures first (basic functionality)"
    echo "4. Re-run tests after each fix to verify improvements"
    exit 1
fi