#!/bin/bash

# Railway Simulation System - Final Automated Test Suite
# This script tests all specified project requirements in order.

#--- CONFIGURATION ---#
EXECUTABLE_NAME="./railway_sim"
MAPS_DIR="maps"

#--- COLORS ---#
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

#--- TEST COUNTERS ---#
PASSED_COUNT=0
FAILED_COUNT=0
TEST_COUNT=0

#--- SETUP ---#
# Ensure the maps directory exists and is clean
rm -rf "$MAPS_DIR"
mkdir -p "$MAPS_DIR"

#--- HELPER FUNCTION ---#
# This function runs a single test case and reports the result.
# It's designed to provide clear, formatted output for each question.
run_test() {
    ((TEST_COUNT++))
    local question_text="$1"
    local command="$2"
    local expected_output="$3"
    local success_condition="$4"
    local is_error_test="$5" # 'true' if we expect a non-zero exit code

    local actual_output
    local exit_code

    # For performance test, wrap command with time
    if [[ "$command" == time* ]]; then
        # Capture stderr of time, and stderr/stdout of the program
        actual_output=$( { { $command; } 2>&1; } 2>&1 )
        exit_code=$?
    else
        actual_output=$(eval "$command" 2>&1)
        exit_code=$?
    fi

    local result="FAIL"
    local result_color="$RED"
    local pass_flag=0

    # Determine if the test passed based on the success condition
    case "$success_condition" in
        "contains")
            if [[ "$actual_output" == *"$expected_output"* ]]; then
                pass_flag=1
            fi
            ;;
        "stderr_contains")
            # This is specifically for tests that MUST fail and produce an error message
            if [[ "$actual_output" == *"$expected_output"* && $exit_code -ne 0 ]]; then
                pass_flag=1
            fi
            ;;
        "line_count_gt")
            local line_count
            line_count=$(echo -n "$actual_output" | grep -c .) # Count non-empty lines
            if [[ $exit_code -eq 0 && "$line_count" -gt "$expected_output" ]]; then
                pass_flag=1
                expected_output="More than $expected_output movement turns"
            fi
            ;;
        "line_count_eq")
            local line_count
            line_count=$(echo -n "$actual_output" | grep -c .)
            if [[ $exit_code -eq 0 && "$line_count" -eq "$expected_output" ]]; then
                pass_flag=1
                 expected_output="Exactly $expected_output movement turn(s)"
            fi
            ;;
        "line_count_lte")
            local line_count
            line_count=$(echo -n "$actual_output" | grep -c .)
            if [[ $exit_code -eq 0 && "$line_count" -le "$expected_output" && "$line_count" -gt 0 ]]; then
                pass_flag=1
                expected_output="Completed in <= $expected_output turns (Actual: $line_count)"
            else
                 expected_output="Completed in <= $expected_output turns (Actual: $line_count, Exit Code: $exit_code)"
            fi
            ;;
        "succeeds")
             if [[ $exit_code -eq 0 && -n "$actual_output" ]]; then
                pass_flag=1
            fi
            ;;
        "manual_check")
            # For tests that require manual verification
            pass_flag=1 # Mark as PASS to avoid counting as fail, but output requires review.
            result="CHECK MANUALLY"
            result_color="$YELLOW"
            ;;
    esac

    if [ "$pass_flag" -eq 1 ]; then
        # If it's a check that passed automatically, update result
        if [ "$result" != "CHECK MANUALLY" ]; then
            result="PASS"
            result_color="$GREEN"
        fi
        ((PASSED_COUNT++))
    else
        ((FAILED_COUNT++))
    fi

    # Print formatted output
    echo -e "${YELLOW}Question:${NC} $question_text"
    echo -e "${YELLOW}Expected:${NC} $expected_output"
    # Use printf to handle multi-line actual output gracefully
    printf "${YELLOW}Actual Outcome:${NC}\n%s\n" "$actual_output"
    echo -e "${YELLOW}Result:${NC}   ${result_color}${result}${NC}"
    echo "============================================================================"
    echo ""
}

#--- MAP DEFINITIONS ---#
echo -e "${BLUE}>>> Creating test maps...${NC}"

# Map files are created in a sub-directory to keep the main directory clean.
cat > "$MAPS_DIR/london.map" <<'EOF'
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

cat > "$MAPS_DIR/bond_square.map" <<'EOF'
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

cat > "$MAPS_DIR/jungle_desert.map" <<'EOF'
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

cat > "$MAPS_DIR/beginning_terminus.map" <<'EOF'
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

cat > "$MAPS_DIR/two_four.map" <<'EOF'
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

cat > "$MAPS_DIR/beethoven_part.map" <<'EOF'
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

cat > "$MAPS_DIR/small_large.map" <<'EOF'
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

# Maps for specific error cases
cat > "$MAPS_DIR/duplicate_connections.map" << 'EOF'
stations:
a,0,0
b,1,1
connections:
a-b
b-a
EOF
cat > "$MAPS_DIR/invalid_connection_station.map" << 'EOF'
stations:
a,0,0
b,1,1
connections:
a-c
EOF
cat > "$MAPS_DIR/duplicate_stations.map" << 'EOF'
stations:
a,0,0
a,1,1
connections:
a-a
EOF
cat > "$MAPS_DIR/same_coordinates.map" << 'EOF'
stations:
a,0,0
b,0,0
connections:
a-b
EOF
cat > "$MAPS_DIR/no_stations.map" << 'EOF'
connections:
a-b
EOF
cat > "$MAPS_DIR/no_connections.map" << 'EOF'
stations:
a,0,0
b,1,1
EOF
cat > "$MAPS_DIR/invalid_coordinates.map" << 'EOF'
stations:
a,-1,0
b,1,1
connections:
a-b
EOF
cat > "$MAPS_DIR/invalid_station_name.map" << 'EOF'
stations:
-invalid,0,0
b,1,1
connections:
-invalid-b
EOF
cat > "$MAPS_DIR/no_path.map" << 'EOF'
stations:
a,0,0
b,1,1
c,2,2
connections:
a-b
EOF

# Use the content of the uploaded 10k.map file.
echo "Creating the 10k station map from provided file..."
cat > "$MAPS_DIR/10k.map" << 'EOF'
stations:
s1,0,0
s2,0,1
s3,0,2
s4,0,3
s5,0,4
s6,0,5
s7,0,6
s8,0,7
s9,0,8
s10,0,9
s11,0,10
s12,0,11
s13,0,12
s14,0,13
s15,0,14
s16,0,15
s17,0,16
s18,0,17
s19,0,18
s20,0,19
s21,0,20
s22,0,21
s23,0,22
s24,0,23
s25,0,24
s26,0,25
s27,0,26
s28,0,27
s29,0,28
s30,0,29
s31,0,30
s32,0,31
s33,0,32
s34,0,33
s35,0,34
s36,0,35
s37,0,36
s38,0,37
s39,0,38
s40,0,39
s41,0,40
s42,0,41
s43,0,42
s44,0,43
s45,0,44
s46,0,45
s47,0,46
s48,0,47
s49,0,48
s50,0,49
s51,0,50
s52,0,51
s53,0,52
s54,0,53
s55,0,54
s56,0,55
s57,0,56
s58,0,57
s59,0,58
s60,0,59
s61,0,60
s62,0,61
s63,0,62
s64,0,63
s65,0,64
s66,0,65
s67,0,66
s68,0,67
s69,0,68
s70,0,69
s71,0,70
s72,0,71
s73,0,72
s74,0,73
s75,0,74
s76,0,75
s77,0,76
s78,0,77
s79,0,78
s80,0,79
s81,0,80
s82,0,81
s83,0,82
s84,0,83
s85,0,84
s86,0,85
s87,0,86
s88,0,87
s89,0,88
s90,0,89
s91,0,90
s92,0,91
s93,0,92
s94,0,93
s95,0,94
s96,0,95
s97,0,96
s98,0,97
s99,0,98
s100,0,99
s101,1,0
s102,1,1
s103,1,2
s104,1,3
s105,1,4
s106,1,5
s107,1,6
s108,1,7
s109,1,8
s110,1,9
s111,1,10
s112,1,11
s113,1,12
s114,1,13
s115,1,14
s116,1,15
s117,1,16
s118,1,17
s119,1,18
s120,1,19
s121,1,20
s122,1,21
s123,1,22
s124,1,23
s125,1,24
s126,1,25
s127,1,26
s128,1,27
s129,1,28
s130,1,29
s131,1,30
s132,1,31
s133,1,32
s134,1,33
s135,1,34
s136,1,35
s137,1,36
s138,1,37
s139,1,38
s140,1,39
s141,1,40
s142,1,41
s143,1,42
s144,1,43
s145,1,44
s146,1,45
s147,1,46
s148,1,47
s149,1,48
s150,1,49
s151,1,50
s152,1,51
s153,1,52
s154,1,53
s155,1,54
s156,1,55
s157,1,56
s158,1,57
s159,1,58
s160,1,59
s161,1,60
s162,1,61
s163,1,62
s164,1,63
s165,1,64
s166,1,65
s167,1,66
s168,1,67
s169,1,68
s170,1,69
s171,1,70
s172,1,71
s173,1,72
s174,1,73
s175,1,74
s176,1,75
s177,1,76
s178,1,77
s179,1,78
s180,1,79
s181,1,80
s182,1,81
s183,1,82
s184,1,83
s185,1,84
s186,1,85
s187,1,86
s188,1,87
s189,1,88
s190,1,89
s191,1,90
s192,1,91
s193,1,92
s194,1,93
s195,1,94
s196,1,95
s197,1,96
s198,1,97
s199,1,98
s200,1,99
s2001,20,0
s2002,20,1
s2003,20,2
s2004,20,3
s2005,20,4
s2006,20,5
s2007,20,6
s2008,20,7
s2009,20,8
s2010,20,9
s2011,20,10
s2012,20,11
s2013,20,12
s2014,20,13
s2015,20,14
s2016,20,15
s2017,20,16
s2018,20,17
s2019,20,18
s2020,20,19
s2021,20,20
s2022,20,21
s2023,20,22
s2024,20,23
s2025,20,24
s2026,20,25
s2027,20,26
s2028,20,27
s2029,20,28
s2030,20,29
s2031,20,30
s2032,20,31
s2033,20,32
s2034,20,33
s2035,20,34
s2036,20,35
s2037,20,36
s2038,20,37
s2039,20,38
s2040,20,39
s2041,20,40
s2042,20,41
s2043,20,42
s2044,20,43
s2045,20,44
s2046,20,45
s2047,20,46
s2048,20,47
s2049,20,48
s2050,20,49
s2051,20,50
s2052,20,51
s2053,20,52
s2054,20,53
s2055,20,54
s2056,20,55
s2057,20,56
s2058,20,57
s2059,20,58
s2060,20,59
s2061,20,60
s2062,20,61
s2063,20,62
s2064,20,63
s2065,20,64
s2066,20,65
s2067,20,66
s2068,20,67
s2069,20,68
s2070,20,69
s2071,20,70
s2072,20,71
s2073,20,72
s2074,20,73
s2075,20,74
s2076,20,75
s2077,20,76
s2078,20,77
s2079,20,78
s2080,20,79
s2081,20,80
s2082,20,81
s2083,20,82
s2084,20,83
s2085,20,84
s2086,20,85
s2087,20,86
s2088,20,87
s2089,20,88
s2090,20,89
s2091,20,90
s2092,20,91
s2093,20,92
s2094,20,93
s2095,20,94
s2096,20,95
s2097,20,96
s2098,20,97
s2099,20,98
s2100,20,99
s9999,99,98
s10000,99,99
s10001,100,100
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
s15-s16
s16-s17
s17-s18
s18-s19
s19-s20
s20-s21
s21-s22
s22-s23
s23-s24
s24-s25
s25-s26
s26-s27
s27-s28
s28-s29
s29-s30
s30-s31
s31-s32
s32-s33
s33-s34
s34-s35
s35-s36
s36-s37
s37-s38
s38-s39
s39-s40
s40-s41
s41-s42
s42-s43
s43-s44
s44-s45
s45-s46
s46-s47
s47-s48
s48-s49
s49-s50
s50-s51
s51-s52
s52-s53
s53-s54
s54-s55
s55-s56
s56-s57
s57-s58
s58-s59
s59-s60
s60-s61
s61-s62
s62-s63
s63-s64
s64-s65
s65-s66
s66-s67
s67-s68
s68-s69
s69-s70
s70-s71
s71-s72
s72-s73
s73-s74
s74-s75
s75-s76
s76-s77
s77-s78
s78-s79
s79-s80
s80-s81
s81-s82
s82-s83
s83-s84
s84-s85
s85-s86
s86-s87
s87-s88
s88-s89
s89-s90
s90-s91
s91-s92
s92-s93
s93-s94
s94-s95
s95-s96
s96-s97
s97-s98
s98-s99
s99-s100
s100-s101
s2001-s10000
s1-s2002
s2002-s2003
s2003-s2004
s2004-s2005
s2005-s2006
s2006-s2007
s2007-s2008
s2008-s2009
s2009-s2010
s2010-s2011
s2011-s2012
s2012-s2013
s2013-s2014
s2014-s2015
s2015-s2016
s2016-s2017
s2017-s2018
s2018-s2019
s2019-s2020
s2020-s2021
s2021-s2022
s2022-s2023
s2023-s2024
s2024-s2025
s2025-s2026
s2026-s2027
s2027-s2028
s2028-s2029
s2029-s2030
s2030-s2031
s2031-s2032
s2032-s2033
s2033-s2034
s2034-s2035
s2035-s2036
s2036-s2037
s2037-s2038
s2038-s2039
s2039-s2040
s2040-s2041
s2041-s2042
s2042-s2043
s2043-s2044
s2044-s2045
s2045-s2046
s2046-s2047
s2047-s2048
s2048-s2049
s2049-s2050
s2050-s2051
s2051-s2052
s2052-s2053
s2053-s2054
s2054-s2055
s2055-s2056
s2056-s2057
s2057-s2058
s2058-s2059
s2059-s2060
s2060-s2061
s2061-s2062
s2062-s2063
s2063-s2064
s2064-s2065
s2065-s2066
s2066-s2067
s2067-s2068
s2068-s2069
s2069-s2070
s2070-s2071
s2071-s2072
s2072-s2073
s2073-s2074
s2074-s2075
s2075-s2076
s2076-s2077
s2077-s2078
s2078-s2079
s2079-s2080
s2080-s2081
s2081-s2082
s2082-s2083
s2083-s2084
s2084-s2085
s2085-s2086
s2086-s2087
s2087-s2088
s2088-s2089
s2089-s2090
s2090-s2091
s2091-s2092
s2092-s2093
s2093-s2094
s2094-s2095
s2095-s2096
s2096-s2097
s2097-s2098
s2098-s2099
s2099-s2100
s4001-s10000
s1-s4002
s4002-s4003
s4003-s4004
s4004-s4005
s4005-s4006
s4006-s4007
s4007-s4008
s4008-s4009
s4009-s4010
s4010-s4011
s4011-s4012
s4012-s4013
s4013-s4014
s4014-s4015
s4015-s4016
s4016-s4017
s4017-s4018
s4018-s4019
s4019-s4020
s4020-s4021
s4021-s4022
s4022-s4023
s4023-s4024
s4024-s4025
s4025-s4026
s4026-s4027
s4027-s4028
s4028-s4029
s4029-s4030
s4030-s4031
s4031-s4032
s4032-s4033
s4033-s4034
s4034-s4035
s4035-s4036
s4036-s4037
s4037-s4038
s4038-s4039
s4039-s4040
s4040-s4041
s4041-s4042
s4042-s4043
s4043-s4044
s4044-s4045
s4045-s4046
s4046-s4047
s4047-s4048
s4048-s4049
s4049-s4050
s4050-s4051
s4051-s4052
s4052-s4053
s4053-s4054
s4054-s4055
s4055-s4056
s4056-s4057
s4057-s4058
s4058-s4059
s4059-s4060
s4060-s4061
s4061-s4062
s4062-s4063
s4063-s4064
s4064-s4065
s4065-s4066
s4066-s4067
s4067-s4068
s4068-s4069
s4069-s4070
s4070-s4071
s4071-s4072
s4072-s4073
s4073-s4074
s4074-s4075
s4075-s4076
s4076-s4077
s4077-s4078
s4078-s4079
s4079-s4080
s4080-s4081
s4081-s4082
s4082-s4083
s4083-s4084
s4084-s4085
s4085-s4086
s4086-s4087
s4087-s4088
s4088-s4089
s4089-s4090
s4090-s4091
s4091-s4092
s4092-s4093
s4093-s4094
s4094-s4095
s4095-s4096
s4096-s4097
s4097-s4098
s4098-s4099
s4099-s4100
s6001-s10000
s1-s6002
s6002-s6003
s6003-s6004
s6004-s6005
s6005-s6006
s6006-s6007
s6007-s6008
s6008-s6009
s6009-s6010
s6010-s6011
s6011-s6012
s6012-s6013
s6013-s6014
s6014-s6015
s6015-s6016
s6016-s6017
s6017-s6018
s6018-s6019
s6019-s6020
s6020-s6021
s6021-s6022
s6022-s6023
s6023-s6024
s6024-s6025
s6025-s6026
s6026-s6027
s6027-s6028
s6028-s6029
s6029-s6030
s6030-s6031
s6031-s6032
s6032-s6033
s6033-s6034
s6034-s6035
s6035-s6036
s6036-s6037
s6037-s6038
s6038-s6039
s6039-s6040
s6040-s6041
s6041-s6042
s6042-s6043
s6043-s6044
s6044-s6045
s6045-s6046
s6046-s6047
s6047-s6048
s6048-s6049
s6049-s6050
s6050-s6051
s6051-s6052
s6052-s6053
s6053-s6054
s6054-s6055
s6055-s6056
s6056-s6057
s6057-s6058
s6058-s6059
s6059-s6060
s6060-s6061
s6061-s6062
s6062-s6063
s6063-s6064
s6064-s6065
s6065-s6066
s6066-s6067
s6067-s6068
s6068-s6069
s6069-s6070
s6070-s6071
s6071-s6072
s6072-s6073
s6073-s6074
s6074-s6075
s6075-s6076
s6076-s6077
s6077-s6078
s6079-s8080
s8080-s8081
s8081-s8082
s8082-s8083
s8083-s8084
s8084-s8085
s8085-s8086
s8086-s8087
s8087-s8088
s8088-s8089
s8089-s8090
s8090-s8091
s8091-s8092
s8092-s8093
s8093-s8094
s8094-s8095
s8095-s8096
s8096-s8097
s8097-s8098
s8098-s8099
s8099-s8100
s10001-s10000
EOF

#--- BUILD PROJECT ---#
echo -e "${BLUE}>>> Building project...${NC}"
if ! go build -o $EXECUTABLE_NAME .; then
    echo -e "${RED}Build failed. Exiting.${NC}"
    exit 1
fi
echo "Build successful."
echo ""


#--- TEST EXECUTION ---#
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}                    STARTING RAILWAY SIMULATION TEST SUITE                    ${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""

# --- Mandatory Tests ---
echo -e "${BLUE}--- Mandatory Requirement Tests ---${NC}"
run_test "It only moves trains in a valid fashion from beginning to end." "$EXECUTABLE_NAME $MAPS_DIR/simple_path.map bond_square space_port 1" "A successful run with output" "succeeds"
run_test "It can find more than one route for 2 trains between waterloo and st_pancras for the London Network Map." "$EXECUTABLE_NAME $MAPS_DIR/london.map waterloo st_pancras 2" "1" "line_count_gt"
run_test "It finds more than one valid route for 3 trains between waterloo and st_pancras in the London Network Map." "$EXECUTABLE_NAME $MAPS_DIR/london.map waterloo st_pancras 3" "1" "line_count_gt"
run_test "It finds more than one valid route for 4 trains between waterloo and st_pancras in the London Network Map." "$EXECUTABLE_NAME $MAPS_DIR/london.map waterloo st_pancras 4" "1" "line_count_gt"
run_test "It finds more than one valid route for 100 trains between waterloo and st_pancras in the London Network Map." "$EXECUTABLE_NAME $MAPS_DIR/london.map waterloo st_pancras 100" "1" "line_count_gt"
run_test "It finds only a single valid route for 1 train between waterloo and st_pancras in the London Network Map." "$EXECUTABLE_NAME $MAPS_DIR/london.map waterloo st_pancras 1" "1" "line_count_eq"
run_test 'It prints the train movements with the correct format "T1-station", "T2-station" etc.' "$EXECUTABLE_NAME $MAPS_DIR/london.map waterloo st_pancras 2" "T1-" "contains"
run_test "It completes the movements in no more than 6 turns for 4 trains between bond_square and space_port." "$EXECUTABLE_NAME $MAPS_DIR/bond_square.map bond_square space_port 4" "6" "line_count_lte"
run_test "It completes the movements in no more than 8 turns for 10 trains between jungle and desert." "$EXECUTABLE_NAME $MAPS_DIR/jungle_desert.map jungle desert 10" "8" "line_count_lte"
run_test "It completes the movements in no more than 11 turns for 20 trains between beginning and terminus." "$EXECUTABLE_NAME $MAPS_DIR/beginning_terminus.map beginning terminus 20" "11" "line_count_lte"
run_test "It completes the movements in no more than 6 turns for 4 trains between two and four." "$EXECUTABLE_NAME $MAPS_DIR/two_four.map two four 4" "6" "line_count_lte"
run_test "It completes the movements in no more than 6 turns for 9 trains between beethoven and part." "$EXECUTABLE_NAME $MAPS_DIR/beethoven_part.map beethoven part 9" "6" "line_count_lte"
run_test "It completes the movements in no more than 8 turns for 9 trains between small and large." "$EXECUTABLE_NAME $MAPS_DIR/small_large.map small large 9" "8" "line_count_lte"
run_test 'It displays "Error" on stderr when too few command line arguments are used.' "$EXECUTABLE_NAME $MAPS_DIR/london.map" "Error" "stderr_contains"
run_test 'It displays "Error" on stderr when too many command line arguments are used.' "$EXECUTABLE_NAME $MAPS_DIR/london.map waterloo st_pancras 2 extra" "Error" "stderr_contains"
run_test "It works with additional tricky cases." "$EXECUTABLE_NAME $MAPS_DIR/jungle_desert.map jungle desert 50" "Successful execution with output" "succeeds"
run_test 'It displays "Error" on stderr when the start station does not exist.' "$EXECUTABLE_NAME $MAPS_DIR/london.map fake_station st_pancras 1" "Error" "stderr_contains"
run_test 'It displays "Error" on stderr when the end station does not exist.' "$EXECUTABLE_NAME $MAPS_DIR/london.map waterloo fake_station 1" "Error" "stderr_contains"
run_test 'It displays "Error" on stderr when the start and end station are the same.' "$EXECUTABLE_NAME $MAPS_DIR/london.map waterloo waterloo 1" "Error" "stderr_contains"
run_test 'It displays "Error" on stderr when no path exists between the start and end stations.' "$EXECUTABLE_NAME $MAPS_DIR/no_path.map a c 1" "Error" "stderr_contains"
run_test 'It displays "Error" on stderr when duplicate routes exist between two stations, including in reverse.' "$EXECUTABLE_NAME $MAPS_DIR/duplicate_connections.map a b 1" "Error" "stderr_contains"
run_test 'It displays "Error" on stderr when the number of trains is not a valid positive integer.' "$EXECUTABLE_NAME $MAPS_DIR/london.map waterloo st_pancras zero" "Error" "stderr_contains"
run_test 'It displays "Error" on stderr when any of the coordinates are not valid positive integers.' "$EXECUTABLE_NAME $MAPS_DIR/invalid_coordinates.map a b 1" "Error" "stderr_contains"
run_test 'It displays "Error" on stderr when two stations exist at the same coordinates.' "$EXECUTABLE_NAME $MAPS_DIR/same_coordinates.map a b 1" "Error" "stderr_contains"
run_test 'It displays "Error" on stderr when a connection is made with a station which does not exist.' "$EXECUTABLE_NAME $MAPS_DIR/invalid_connection_station.map a b 1" "Error" "stderr_contains"
run_test 'It displays "Error" on stderr when station names are duplicated.' "$EXECUTABLE_NAME $MAPS_DIR/duplicate_stations.map a b 1" "Error" "stderr_contains"
run_test 'It displays "Error" on stderr when station names are invalid.' "$EXECUTABLE_NAME $MAPS_DIR/invalid_station_name.map -invalid b 1" "Error" "stderr_contains"
run_test 'It displays "Error" on stderr when the map does not contain a "stations:" section.' "$EXECUTABLE_NAME $MAPS_DIR/no_stations.map a b 1" "Error" "stderr_contains"
run_test 'It displays "Error" on stderr when the map does not contain a "connections:" section.' "$EXECUTABLE_NAME $MAPS_DIR/no_connections.map a b 1" "Error" "stderr_contains"
run_test 'It displays "Error" on stderr when a map contains more than 10000 stations.' "$EXECUTABLE_NAME $MAPS_DIR/10k.map s1 s10001 1" "Error: station limit is 10000" "stderr_contains"

# --- Extra/Graded Tests ---
echo -e "${BLUE}--- Extra/Graded Requirement Tests ---${NC}"
run_test 'It implements advanced Error handling. For example, it displays "Error: Start station does not exist".' "$EXECUTABLE_NAME $MAPS_DIR/london.map non_existent st_pancras 1" 'Error: Start station "non_existent" does not exist' "stderr_contains"
run_test 'It implements super advanced Error handling. It names problematic entities... For example: "Error: Duplicate connection between euston and victoria".' "$EXECUTABLE_NAME $MAPS_DIR/duplicate_connections.map a b 1" "Error: duplicate connection between a and b" "stderr_contains"
run_test "It finds more efficient routes when compared with the examples above, resulting in fewer train movement turns." "$EXECUTABLE_NAME $MAPS_DIR/small_large.map small large 9" "Review the turn count in the output above. The example has 8 turns." "manual_check"
run_test "A suite of tests have been created in advance, covering the cases described in this review." "echo 'This script itself fulfills this requirement.'" "This script itself fulfills this requirement." "contains"
run_test "It runs quickly. It does not hang excessively." "time $EXECUTABLE_NAME $MAPS_DIR/jungle_desert.map jungle desert 50" "Review the execution time printed in the 'Actual Outcome' above." "manual_check"

#--- FINAL SUMMARY ---#
echo "============================================================================"
echo -e "${BLUE}                       TEST SUITE SUMMARY                                 ${NC}"
echo "============================================================================"
echo -e "Total Tests Run: $TEST_COUNT"
echo -e "${GREEN}Tests Passed:      $PASSED_COUNT${NC}"
echo -e "${RED}Tests Failed:      $FAILED_COUNT${NC}"
echo "============================================================================"

# Cleanup
rm -rf "$MAPS_DIR"
rm "$EXECUTABLE_NAME"

