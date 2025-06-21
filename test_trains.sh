#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Test results array for summary
declare -a TEST_RESULTS

# Function to print test header
print_test_header() {
    echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
}

# Function to print individual test
print_test_result() {
    local test_num="$1"
    local test_name="$2"
    local expected="$3"
    local actual="$4"
    local status="$5"
    local details="$6"
    
    echo -e "\n${CYAN}[$test_num] Test:${NC} $test_name"
    echo -e "${YELLOW}Expected:${NC} $expected"
    echo -e "${YELLOW}Actual:${NC} $actual"
    
    if [ "$status" = "PASS" ]; then
        echo -e "${GREEN}✅ Result: PASS${NC}"
        if [ -n "$details" ]; then
            echo -e "${GREEN}   Details: $details${NC}"
        fi
        ((PASSED_TESTS++))
        TEST_RESULTS+=("✅ [$test_num] $test_name")
    else
        echo -e "${RED}❌ Result: FAIL${NC}"
        if [ -n "$details" ]; then
            echo -e "${RED}   Details: $details${NC}"
        fi
        ((FAILED_TESTS++))
        TEST_RESULTS+=("❌ [$test_num] $test_name")
    fi
    ((TOTAL_TESTS++))
}

# Function to count lines
count_lines() {
    if [ -z "$1" ]; then
        echo "0"
    else
        echo "$1" | wc -l | tr -d ' '
    fi
}

# Function to validate train movement format
validate_train_movements() {
    local output="$1"
    
    if [ -z "$output" ]; then
        echo "empty"
        return
    fi
    
    # Check if each line matches the format: T1-station T2-station etc.
    while IFS= read -r line; do
        if ! echo "$line" | grep -qE '^T[0-9]+-[a-zA-Z_][a-zA-Z0-9_]*( T[0-9]+-[a-zA-Z_][a-zA-Z0-9_]*)*$'; then
            echo "invalid_format"
            return
        fi
    done <<< "$output"
    
    echo "valid"
}

# Function to check if all trains reach destination
check_completion() {
    local output="$1"
    local num_trains="$2"
    local end_station="$3"
    
    if [ -z "$output" ]; then
        echo "incomplete"
        return
    fi
    
    # Extract all train movements and track final positions
    declare -A train_positions
    
    # Initialize all trains at start
    for ((i=1; i<=num_trains; i++)); do
        train_positions["T$i"]="start"
    done
    
    # Process each turn
    while IFS= read -r line; do
        # Extract moves from line (T1-station T2-station format)
        while [[ $line =~ T([0-9]+)-([a-zA-Z_][a-zA-Z0-9_]*) ]]; do
            local train="T${BASH_REMATCH[1]}"
            local station="${BASH_REMATCH[2]}"
            train_positions["$train"]="$station"
            line=${line/${BASH_REMATCH[0]}/}
        done
    done <<< "$output"
    
    # Check if all trains reached destination
    for ((i=1; i<=num_trains; i++)); do
        if [ "${train_positions["T$i"]}" != "$end_station" ]; then
            echo "incomplete"
            return
        fi
    done
    
    echo "complete"
}

# Function to run a test command and capture both stdout and stderr
run_test_command() {
    local cmd="$1"
    local temp_file=$(mktemp)
    local temp_err=$(mktemp)
    
    eval "$cmd" > "$temp_file" 2> "$temp_err"
    local exit_code=$?
    
    local stdout_content=$(cat "$temp_file")
    local stderr_content=$(cat "$temp_err")
    
    rm -f "$temp_file" "$temp_err"
    
    echo "$exit_code|$stdout_content|$stderr_content"
}

# Build the project
build_project() {
    echo -e "${BLUE}Building project...${NC}"
    if go build -o stations .; then
        echo -e "${GREEN}✅ Build successful${NC}"
        return 0
    else
        echo -e "${RED}❌ Build failed${NC}"
        return 1
    fi
}

# MANDATORY TESTS FROM REVIEW CRITERIA

test_valid_movements() {
    print_test_header "1. VALID TRAIN MOVEMENTS"
    
    # Test 1: Basic movement validation
    local result=$(run_test_command "./stations test_maps/london.map waterloo st_pancras 2")
    IFS='|' read -r exit_code stdout stderr <<< "$result"
    
    local format_check=$(validate_train_movements "$stdout")
    local completion_check=$(check_completion "$stdout" 2 "st_pancras")
    
    if [ "$format_check" = "valid" ] && [ "$completion_check" = "complete" ] && [ "$exit_code" -eq 0 ]; then
        print_test_result "1" "Valid train movements (2 trains)" "Valid format, all trains reach destination" "Format: $format_check, Completion: $completion_check" "PASS" "Exit code: $exit_code"
    else
        print_test_result "1" "Valid train movements (2 trains)" "Valid format, all trains reach destination" "Format: $format_check, Completion: $completion_check" "FAIL" "Exit code: $exit_code, stderr: $stderr"
    fi
}

test_multiple_routes() {
    print_test_header "2. MULTIPLE ROUTES CAPABILITY"
    
    # Test 2: Multiple routes for 2 trains
    local result=$(run_test_command "./stations test_maps/london.map waterloo st_pancras 2")
    IFS='|' read -r exit_code stdout stderr <<< "$result"
    local turns_2=$(count_lines "$stdout")
    
    if [ "$turns_2" -gt 0 ] && [ "$exit_code" -eq 0 ]; then
        print_test_result "2a" "Multiple routes for 2 trains" "Valid route found" "Found route with $turns_2 turns" "PASS"
    else
        print_test_result "2a" "Multiple routes for 2 trains" "Valid route found" "No valid route or error" "FAIL" "stderr: $stderr"
    fi
    
    # Test 3: Multiple routes for 3 trains
    local result=$(run_test_command "./stations test_maps/london.map waterloo st_pancras 3")
    IFS='|' read -r exit_code stdout stderr <<< "$result"
    local turns_3=$(count_lines "$stdout")
    
    if [ "$turns_3" -gt 0 ] && [ "$exit_code" -eq 0 ]; then
        print_test_result "2b" "Multiple routes for 3 trains" "Valid route found" "Found route with $turns_3 turns" "PASS"
    else
        print_test_result "2b" "Multiple routes for 3 trains" "Valid route found" "No valid route or error" "FAIL" "stderr: $stderr"
    fi
    
    # Test 4: Multiple routes for 4 trains
    local result=$(run_test_command "./stations test_maps/london.map waterloo st_pancras 4")
    IFS='|' read -r exit_code stdout stderr <<< "$result"
    local turns_4=$(count_lines "$stdout")
    
    if [ "$turns_4" -gt 0 ] && [ "$exit_code" -eq 0 ]; then
        print_test_result "2c" "Multiple routes for 4 trains" "Valid route found" "Found route with $turns_4 turns" "PASS"
    else
        print_test_result "2c" "Multiple routes for 4 trains" "Valid route found" "No valid route or error" "FAIL" "stderr: $stderr"
    fi
    
    # Test 5: Multiple routes for 100 trains
    local result=$(run_test_command "./stations test_maps/london.map waterloo st_pancras 100")
    IFS='|' read -r exit_code stdout stderr <<< "$result"
    local turns_100=$(count_lines "$stdout")
    
    if [ "$turns_100" -gt 0 ] && [ "$exit_code" -eq 0 ]; then
        print_test_result "2d" "Multiple routes for 100 trains" "Valid route found" "Found route with $turns_100 turns" "PASS"
    else
        print_test_result "2d" "Multiple routes for 100 trains" "Valid route found" "No valid route or error" "FAIL" "stderr: $stderr"
    fi
    
    # Test 6: Single route for 1 train
    local result=$(run_test_command "./stations test_maps/london.map waterloo st_pancras 1")
    IFS='|' read -r exit_code stdout stderr <<< "$result"
    local turns_1=$(count_lines "$stdout")
    
    if [ "$turns_1" -gt 0 ] && [ "$exit_code" -eq 0 ]; then
        print_test_result "2e" "Single route for 1 train" "Valid single route" "Found route with $turns_1 turns" "PASS"
    else
        print_test_result "2e" "Single route for 1 train" "Valid single route" "No valid route or error" "FAIL" "stderr: $stderr"
    fi
}

test_output_format() {
    print_test_header "3. OUTPUT FORMAT VALIDATION"
    
    # Test 7: Correct train movement format
    local result=$(run_test_command "./stations test_maps/london.map waterloo st_pancras 2")
    IFS='|' read -r exit_code stdout stderr <<< "$result"
    
    local format_check=$(validate_train_movements "$stdout")
    
    if [ "$format_check" = "valid" ]; then
        print_test_result "3" "Train movement format" "T1-station T2-station format" "Correct format validated" "PASS"
    else
        print_test_result "3" "Train movement format" "T1-station T2-station format" "Format: $format_check" "FAIL" "Output: $stdout"
    fi
}

test_performance_requirements() {
    print_test_header "4. PERFORMANCE REQUIREMENTS"
    
    # Test 8: Bond Square to Space Port (4 trains, ≤6 turns)
    local result=$(run_test_command "./stations test_maps/bond_square.map bond_square space_port 4")
    IFS='|' read -r exit_code stdout stderr <<< "$result"
    local turns=$(count_lines "$stdout")
    
    if [ "$turns" -le 6 ] && [ "$turns" -gt 0 ] && [ "$exit_code" -eq 0 ]; then
        print_test_result "4a" "4 trains bond_square→space_port" "≤ 6 turns" "$turns turns" "PASS"
    else
        print_test_result "4a" "4 trains bond_square→space_port" "≤ 6 turns" "$turns turns" "FAIL" "Exit: $exit_code, stderr: $stderr"
    fi
    
    # Test 9: Jungle to Desert (10 trains, ≤8 turns)
    local result=$(run_test_command "./stations test_maps/jungle_desert.map jungle desert 10")
    IFS='|' read -r exit_code stdout stderr <<< "$result"
    local turns=$(count_lines "$stdout")
    
    if [ "$turns" -le 8 ] && [ "$turns" -gt 0 ] && [ "$exit_code" -eq 0 ]; then
        print_test_result "4b" "10 trains jungle→desert" "≤ 8 turns" "$turns turns" "PASS"
    else
        print_test_result "4b" "10 trains jungle→desert" "≤ 8 turns" "$turns turns" "FAIL" "Exit: $exit_code, stderr: $stderr"
    fi
    
    # Test 10: Beginning to Terminus (20 trains, ≤11 turns)
    local result=$(run_test_command "./stations test_maps/beginning_terminus.map beginning terminus 20")
    IFS='|' read -r exit_code stdout stderr <<< "$result"
    local turns=$(count_lines "$stdout")
    
    if [ "$turns" -le 11 ] && [ "$turns" -gt 0 ] && [ "$exit_code" -eq 0 ]; then
        print_test_result "4c" "20 trains beginning→terminus" "≤ 11 turns" "$turns turns" "PASS"
    else
        print_test_result "4c" "20 trains beginning→terminus" "≤ 11 turns" "$turns turns" "FAIL" "Exit: $exit_code, stderr: $stderr"
    fi
    
    # Test 11: Two to Four (4 trains, ≤6 turns)
    local result=$(run_test_command "./stations test_maps/two_four.map two four 4")
    IFS='|' read -r exit_code stdout stderr <<< "$result"
    local turns=$(count_lines "$stdout")
    
    if [ "$turns" -le 6 ] && [ "$turns" -gt 0 ] && [ "$exit_code" -eq 0 ]; then
        print_test_result "4d" "4 trains two→four" "≤ 6 turns" "$turns turns" "PASS"
    else
        print_test_result "4d" "4 trains two→four" "≤ 6 turns" "$turns turns" "FAIL" "Exit: $exit_code, stderr: $stderr"
    fi
    
    # Test 12: Beethoven to Part (9 trains, ≤6 turns)
    local result=$(run_test_command "./stations test_maps/beethoven_part.map beethoven part 9")
    IFS='|' read -r exit_code stdout stderr <<< "$result"
    local turns=$(count_lines "$stdout")
    
    if [ "$turns" -le 6 ] && [ "$turns" -gt 0 ] && [ "$exit_code" -eq 0 ]; then
        print_test_result "4e" "9 trains beethoven→part" "≤ 6 turns" "$turns turns" "PASS"
    else
        print_test_result "4e" "9 trains beethoven→part" "≤ 6 turns" "$turns turns" "FAIL" "Exit: $exit_code, stderr: $stderr"
    fi
    
    # Test 13: Small to Large (9 trains, ≤8 turns)
    local result=$(run_test_command "./stations test_maps/small_large.map small large 9")
    IFS='|' read -r exit_code stdout stderr <<< "$result"
    local turns=$(count_lines "$stdout")
    
    if [ "$turns" -le 8 ] && [ "$turns" -gt 0 ] && [ "$exit_code" -eq 0 ]; then
        print_test_result "4f" "9 trains small→large" "≤ 8 turns" "$turns turns" "PASS"
    else
        print_test_result "4f" "9 trains small→large" "≤ 8 turns" "$turns turns" "FAIL" "Exit: $exit_code, stderr: $stderr"
    fi
}

test_error_handling() {
    print_test_header "5. ERROR HANDLING"
    
    # Test 14: Too few arguments
    local result=$(run_test_command "./stations")
    IFS='|' read -r exit_code stdout stderr <<< "$result"
    
    if echo "$stderr" | grep -q "Error" && [ "$exit_code" -ne 0 ]; then
        print_test_result "5a" "Too few command line arguments" "Error to stderr" "Error displayed" "PASS"
    else
        print_test_result "5a" "Too few command line arguments" "Error to stderr" "No error or wrong output" "FAIL" "Exit: $exit_code, stderr: $stderr"
    fi
    
    # Test 15: Too many arguments
    local result=$(run_test_command "./stations test_maps/london.map waterloo st_pancras 4 extra")
    IFS='|' read -r exit_code stdout stderr <<< "$result"
    
    if echo "$stderr" | grep -q "Error" && [ "$exit_code" -ne 0 ]; then
        print_test_result "5b" "Too many command line arguments" "Error to stderr" "Error displayed" "PASS"
    else
        print_test_result "5b" "Too many command line arguments" "Error to stderr" "No error or wrong output" "FAIL" "Exit: $exit_code, stderr: $stderr"
    fi
    
    # Test 16: Start station does not exist
    local result=$(run_test_command "./stations test_maps/london.map invalid_station st_pancras 2")
    IFS='|' read -r exit_code stdout stderr <<< "$result"
    
    if echo "$stderr" | grep -q "Error" && [ "$exit_code" -ne 0 ]; then
        print_test_result "5c" "Start station does not exist" "Error to stderr" "Error displayed" "PASS"
    else
        print_test_result "5c" "Start station does not exist" "Error to stderr" "No error or wrong output" "FAIL" "Exit: $exit_code, stderr: $stderr"
    fi
    
    # Test 17: End station does not exist
    local result=$(run_test_command "./stations test_maps/london.map waterloo invalid_station 2")
    IFS='|' read -r exit_code stdout stderr <<< "$result"
    
    if echo "$stderr" | grep -q "Error" && [ "$exit_code" -ne 0 ]; then
        print_test_result "5d" "End station does not exist" "Error to stderr" "Error displayed" "PASS"
    else
        print_test_result "5d" "End station does not exist" "Error to stderr" "No error or wrong output" "FAIL" "Exit: $exit_code, stderr: $stderr"
    fi
    
    # Test 18: Same start and end station
    local result=$(run_test_command "./stations test_maps/london.map waterloo waterloo 2")
    IFS='|' read -r exit_code stdout stderr <<< "$result"
    
    if echo "$stderr" | grep -q "Error" && [ "$exit_code" -ne 0 ]; then
        print_test_result "5e" "Same start and end station" "Error to stderr" "Error displayed" "PASS"
    else
        print_test_result "5e" "Same start and end station" "Error to stderr" "No error or wrong output" "FAIL" "Exit: $exit_code, stderr: $stderr"
    fi
    
    # Test 19: No path exists
    local result=$(run_test_command "./stations test_maps/no_path.map a b 1")
    IFS='|' read -r exit_code stdout stderr <<< "$result"
    
    if echo "$stderr" | grep -q "Error" && [ "$exit_code" -ne 0 ]; then
        print_test_result "5f" "No path between start and end" "Error to stderr" "Error displayed" "PASS"
    else
        print_test_result "5f" "No path between start and end" "Error to stderr" "No error or wrong output" "FAIL" "Exit: $exit_code, stderr: $stderr"
    fi
    
    # Test 20: Duplicate connections
    local result=$(run_test_command "./stations test_maps/duplicate_connections.map a b 1")
    IFS='|' read -r exit_code stdout stderr <<< "$result"
    
    if echo "$stderr" | grep -q "Error" && [ "$exit_code" -ne 0 ]; then
        print_test_result "5g" "Duplicate connections" "Error to stderr" "Error displayed" "PASS"
    else
        print_test_result "5g" "Duplicate connections" "Error to stderr" "No error or wrong output" "FAIL" "Exit: $exit_code, stderr: $stderr"
    fi
    
    # Test 21: Invalid number of trains
    local result=$(run_test_command "./stations test_maps/london.map waterloo st_pancras invalid")
    IFS='|' read -r exit_code stdout stderr <<< "$result"
    
    if echo "$stderr" | grep -q "Error" && [ "$exit_code" -ne 0 ]; then
        print_test_result "5h" "Invalid number of trains" "Error to stderr" "Error displayed" "PASS"
    else
        print_test_result "5h" "Invalid number of trains" "Error to stderr" "No error or wrong output" "FAIL" "Exit: $exit_code, stderr: $stderr"
    fi
    
    # Test 22: Invalid coordinates
    local result=$(run_test_command "./stations test_maps/invalid_coordinates.map a b 1")
    IFS='|' read -r exit_code stdout stderr <<< "$result"
    
    if echo "$stderr" | grep -q "Error" && [ "$exit_code" -ne 0 ]; then
        print_test_result "5i" "Invalid coordinates" "Error to stderr" "Error displayed" "PASS"
    else
        print_test_result "5i" "Invalid coordinates" "Error to stderr" "No error or wrong output" "FAIL" "Exit: $exit_code, stderr: $stderr"
    fi
    
    # Test 23: Same coordinates
    local result=$(run_test_command "./stations test_maps/same_coordinates.map a b 1")
    IFS='|' read -r exit_code stdout stderr <<< "$result"
    
    if echo "$stderr" | grep -q "Error" && [ "$exit_code" -ne 0 ]; then
        print_test_result "5j" "Same coordinates for stations" "Error to stderr" "Error displayed" "PASS"
    else
        print_test_result "5j" "Same coordinates for stations" "Error to stderr" "No error or wrong output" "FAIL" "Exit: $exit_code, stderr: $stderr"
    fi
    
    # Test 24: Invalid connection (non-existent station)
    local result=$(run_test_command "./stations test_maps/invalid_connection.map a b 1")
    IFS='|' read -r exit_code stdout stderr <<< "$result"
    
    if echo "$stderr" | grep -q "Error" && [ "$exit_code" -ne 0 ]; then
        print_test_result "5k" "Connection with non-existent station" "Error to stderr" "Error displayed" "PASS"
    else
        print_test_result "5k" "Connection with non-existent station" "Error to stderr" "No error or wrong output" "FAIL" "Exit: $exit_code, stderr: $stderr"
    fi
    
    # Test 25: Duplicate station names
    local result=$(run_test_command "./stations test_maps/duplicate_stations.map a b 1")
    IFS='|' read -r exit_code stdout stderr <<< "$result"
    
    if echo "$stderr" | grep -q "Error" && [ "$exit_code" -ne 0 ]; then
        print_test_result "5l" "Duplicate station names" "Error to stderr" "Error displayed" "PASS"
    else
        print_test_result "5l" "Duplicate station names" "Error to stderr" "No error or wrong output" "FAIL" "Exit: $exit_code, stderr: $stderr"
    fi
    
    # Test 26: Invalid station names
    local result=$(run_test_command "./stations test_maps/invalid_station_names.map a b 1")
    IFS='|' read -r exit_code stdout stderr <<< "$result"
    
    if echo "$stderr" | grep -q "Error" && [ "$exit_code" -ne 0 ]; then
        print_test_result "5m" "Invalid station names" "Error to stderr" "Error displayed" "PASS"
    else
        print_test_result "5m" "Invalid station names" "Error to stderr" "No error or wrong output" "FAIL" "Exit: $exit_code, stderr: $stderr"
    fi
    
    # Test 27: Missing stations section
    local result=$(run_test_command "./stations test_maps/no_stations.map a b 1")
    IFS='|' read -r exit_code stdout stderr <<< "$result"
    
    if echo "$stderr" | grep -q "Error" && [ "$exit_code" -ne 0 ]; then
        print_test_result "5n" "Missing stations section" "Error to stderr" "Error displayed" "PASS"
    else
        print_test_result "5n" "Missing stations section" "Error to stderr" "No error or wrong output" "FAIL" "Exit: $exit_code, stderr: $stderr"
    fi
    
    # Test 28: Missing connections section
    local result=$(run_test_command "./stations test_maps/no_connections.map a b 1")
    IFS='|' read -r exit_code stdout stderr <<< "$result"
    
    if echo "$stderr" | grep -q "Error" && [ "$exit_code" -ne 0 ]; then
        print_test_result "5o" "Missing connections section" "Error to stderr" "Error displayed" "PASS"
    else
        print_test_result "5o" "Missing connections section" "Error to stderr" "No error or wrong output" "FAIL" "Exit: $exit_code, stderr: $stderr"
    fi
}

test_additional_cases() {
    print_test_header "6. ADDITIONAL CHALLENGING CASES"
    
    # Test 29: Complex network
    local result=$(run_test_command "./stations test_maps/complex.map a z 5")
    IFS='|' read -r exit_code stdout stderr <<< "$result"
    
    if [ "$exit_code" -eq 0 ] && [ -n "$stdout" ]; then
        local turns=$(count_lines "$stdout")
        print_test_result "6a" "Complex network pathfinding" "Valid solution" "Found route with $turns turns" "PASS"
    else
        print_test_result "6a" "Complex network pathfinding" "Valid solution" "Failed or no output" "FAIL" "Exit: $exit_code, stderr: $stderr"
    fi
    
    # Test 30: Long chain
    local result=$(run_test_command "./stations test_maps/long_chain.map a j 3")
    IFS='|' read -r exit_code stdout stderr <<< "$result"
    
    if [ "$exit_code" -eq 0 ] && [ -n "$stdout" ]; then
        local turns=$(count_lines "$stdout")
        print_test_result "6b" "Long chain network" "Valid solution" "Found route with $turns turns" "PASS"
    else
        print_test_result "6b" "Long chain network" "Valid solution" "Failed or no output" "FAIL" "Exit: $exit_code, stderr: $stderr"
    fi
}

print_summary() {
    echo -e "\n${PURPLE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}                        TEST SUMMARY${NC}"
    echo -e "${PURPLE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}Date:${NC} $(date)"
    echo -e "${YELLOW}User:${NC} centho03"
    echo -e "${YELLOW}Total Tests:${NC} $TOTAL_TESTS"
    echo -e "${GREEN}Passed:${NC} $PASSED_TESTS"
    echo -e "${RED}Failed:${NC} $FAILED_TESTS"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "\n${GREEN}🎉🎉🎉 ALL TESTS PASSED! 🎉🎉🎉${NC}"
        echo -e "${GREEN}Your implementation meets ALL mandatory requirements!${NC}"
        echo -e "${GREEN}Ready for submission! 🚀${NC}"
    else
        local success_rate=$(( PASSED_TESTS * 100 / TOTAL_TESTS ))
        echo -e "\n${YELLOW}Success Rate: ${success_rate}%${NC}"
        
        if [ $success_rate -ge 80 ]; then
            echo -e "${YELLOW}Good progress! Almost there! 💪${NC}"
        elif [ $success_rate -ge 60 ]; then
            echo -e "${YELLOW}Making progress! Keep going! 🔧${NC}"
        else
            echo -e "${RED}Needs significant work. Focus on failed tests. 🛠️${NC}"
        fi
    fi
    
    echo -e "\n${CYAN}Detailed Results:${NC}"
    for result in "${TEST_RESULTS[@]}"; do
        echo -e "  $result"
    done
}

# Main execution
main() {
    echo -e "${PURPLE}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}                    STATIONS PATHFINDER AUTOMATED TEST SUITE${NC}"
    echo -e "${PURPLE}                           Review Criteria Validation${NC}"
    echo -e "${PURPLE}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}Date: $(date)${NC}"
    echo -e "${CYAN}User: centho03${NC}"
    echo -e "${CYAN}Testing against your test_maps/ directory${NC}"
    
    # Build project
    if ! build_project; then
        echo -e "${RED}❌ Cannot proceed with tests - build failed${NC}"
        exit 1
    fi
    
    # Run all test categories in order
    test_valid_movements
    test_multiple_routes
    test_output_format
    test_performance_requirements
    test_error_handling
    test_additional_cases
    
    # Print final summary
    print_summary
    
    # Cleanup
    echo -e "\n${BLUE}Cleaning up...${NC}"
    rm -f stations
    
    echo -e "\n${BLUE}Test suite completed! 🏁${NC}"
    
    # Exit with appropriate code
    if [ $FAILED_TESTS -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"
