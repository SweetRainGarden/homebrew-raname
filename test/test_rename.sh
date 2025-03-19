#!/usr/bin/env bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Helper function to create test directories
setup_test_dir() {
    local dir="$1"
    rm -rf "$dir" "$dir"_zoo
    mkdir -p "$dir"
    echo "foo test content" > "$dir/foo.txt"
    mkdir -p "$dir/foobar"
    echo "foo in subdir" > "$dir/foobar/foo.txt"
    mkdir -p "$dir/foobar/foobarcat"
    echo "foo in nested dir" > "$dir/foobar/foobarcat/foo.txt"
}

# Helper function to verify directory structure
verify_structure() {
    local dir="$1"
    local expected="$2"
    local actual=$(find "$dir" -type f | sort)
    local expected_sorted=$(echo "$expected" | sort)
    if [ "$actual" = "$expected_sorted" ]; then
        return 0
    else
        echo "Expected:"
        echo "$expected_sorted"
        echo "Got:"
        echo "$actual"
        return 1
    fi
}

# Helper function to verify file content
verify_content() {
    local file="$1"
    local expected="$2"
    if [ ! -f "$file" ]; then
        echo "File not found: $file"
        return 1
    fi
    local actual=$(cat "$file")
    if [ "$actual" = "$expected" ]; then
        return 0
    else
        echo "Expected:"
        echo "$expected"
        echo "Got:"
        echo "$actual"
        return 1
    fi
}

# Test function
run_test() {
    local name="$1"
    local cmd="$2"
    local expected_structure="$3"
    local expected_content="$4"
    
    echo -n "Running test: $name ... "
    
    # Run the command
    eval "$cmd"
    
    # Verify structure
    if verify_structure "$TEST_DIR" "$expected_structure"; then
        # Verify content if specified
        if [ -n "$expected_content" ]; then
            if verify_content "$expected_content" "zoo test content"; then
                echo -e "${GREEN}PASSED${NC}"
                ((TESTS_PASSED++))
            else
                echo -e "${RED}FAILED${NC} (content mismatch)"
                ((TESTS_FAILED++))
            fi
        else
            echo -e "${GREEN}PASSED${NC}"
            ((TESTS_PASSED++))
        fi
    else
        echo -e "${RED}FAILED${NC} (structure mismatch)"
        ((TESTS_FAILED++))
    fi
    
    # Cleanup after each test
    rm -rf "$TEST_DIR" "$TEST_DIR"_zoo
}

# Create test directory
TEST_DIR="test_dir"
setup_test_dir "$TEST_DIR"

# Test 1: Basic rename
echo "Test 1: Basic rename"
run_test "Basic rename" \
    "bash bin/rename foo zoo $TEST_DIR" \
    "$TEST_DIR/zoobar/zoobarcat/zoo.txt
$TEST_DIR/zoobar/zoobar/zoo.txt
$TEST_DIR/zoo.txt" \
    "$TEST_DIR/zoo.txt"

# Test 2: Case-insensitive rename
echo "Test 2: Case-insensitive rename"
setup_test_dir "$TEST_DIR"
run_test "Case-insensitive rename" \
    "bash bin/rename -i Foo zoo $TEST_DIR" \
    "$TEST_DIR/zoobar/zoobarcat/zoo.txt
$TEST_DIR/zoobar/zoobar/zoo.txt
$TEST_DIR/zoo.txt" \
    "$TEST_DIR/zoo.txt"

# Test 3: Dry run
echo "Test 3: Dry run"
setup_test_dir "$TEST_DIR"
run_test "Dry run" \
    "bash bin/rename --dry-run foo zoo $TEST_DIR" \
    "$TEST_DIR/foobar/foobarcat/foo.txt
$TEST_DIR/foobar/foo.txt
$TEST_DIR/foo.txt" \
    "$TEST_DIR/foo.txt"

# Test 4: Copy mode
echo "Test 4: Copy mode"
setup_test_dir "$TEST_DIR"
run_test "Copy mode" \
    "bash bin/rename --copy foo zoo $TEST_DIR" \
    "$TEST_DIR/foobar/foobarcat/foo.txt
$TEST_DIR/foobar/foo.txt
$TEST_DIR/foo.txt
$TEST_DIR_zoo/zoobar/zoobarcat/zoo.txt
$TEST_DIR_zoo/zoobar/zoobar/zoo.txt
$TEST_DIR_zoo/zoo.txt" \
    "$TEST_DIR_zoo/zoo.txt"

# Test 5: Exclude directories
echo "Test 5: Exclude directories"
setup_test_dir "$TEST_DIR"
mkdir -p "$TEST_DIR/exclude_me"
echo "foo in excluded dir" > "$TEST_DIR/exclude_me/foo.txt"
run_test "Exclude directories" \
    "bash bin/rename -e exclude_me foo zoo $TEST_DIR" \
    "$TEST_DIR/exclude_me/foo.txt
$TEST_DIR/zoobar/zoobarcat/zoo.txt
$TEST_DIR/zoobar/zoobar/zoo.txt
$TEST_DIR/zoo.txt" \
    "$TEST_DIR/zoo.txt"

# Test 6: Rename with spaces
echo "Test 6: Rename with spaces"
setup_test_dir "$TEST_DIR"
mkdir -p "$TEST_DIR/foo bar"
echo "foo in spaced dir" > "$TEST_DIR/foo bar/foo.txt"
run_test "Rename with spaces" \
    "bash bin/rename 'foo bar' 'zoo bar' $TEST_DIR" \
    "$TEST_DIR/zoo bar/zoo.txt
$TEST_DIR/zoobar/zoobarcat/zoo.txt
$TEST_DIR/zoobar/zoobar/zoo.txt
$TEST_DIR/zoo.txt" \
    "$TEST_DIR/zoo.txt"

# Test 7: Special characters
echo "Test 7: Special characters"
setup_test_dir "$TEST_DIR"
mkdir -p "$TEST_DIR/foo*bar"
echo "foo in special dir" > "$TEST_DIR/foo*bar/foo.txt"
run_test "Special characters" \
    "bash bin/rename 'foo*bar' 'zoo*bar' $TEST_DIR" \
    "$TEST_DIR/zoo*bar/zoo.txt
$TEST_DIR/zoobar/zoobarcat/zoo.txt
$TEST_DIR/zoobar/zoobar/zoo.txt
$TEST_DIR/zoo.txt" \
    "$TEST_DIR/zoo.txt"

# Test 8: Multiple occurrences in same file
echo "Test 8: Multiple occurrences"
setup_test_dir "$TEST_DIR"
echo "foo foo foo" > "$TEST_DIR/multiple_foo.txt"
run_test "Multiple occurrences" \
    "bash bin/rename foo zoo $TEST_DIR" \
    "$TEST_DIR/multiple_zoo.txt
$TEST_DIR/zoobar/zoobarcat/zoo.txt
$TEST_DIR/zoobar/zoobar/zoo.txt
$TEST_DIR/zoo.txt" \
    "$TEST_DIR/multiple_zoo.txt"

# Test 9: Empty directory
echo "Test 9: Empty directory"
setup_test_dir "$TEST_DIR"
mkdir -p "$TEST_DIR/empty_dir"
run_test "Empty directory" \
    "bash bin/rename foo zoo $TEST_DIR" \
    "$TEST_DIR/zoobar/zoobarcat/zoo.txt
$TEST_DIR/zoobar/zoobar/zoo.txt
$TEST_DIR/zoo.txt" \
    "$TEST_DIR/zoo.txt"

# Test 10: Hidden files
echo "Test 10: Hidden files"
setup_test_dir "$TEST_DIR"
echo "foo in hidden file" > "$TEST_DIR/.foo.txt"
run_test "Hidden files" \
    "bash bin/rename foo zoo $TEST_DIR" \
    "$TEST_DIR/.zoo.txt
$TEST_DIR/zoobar/zoobarcat/zoo.txt
$TEST_DIR/zoobar/zoobar/zoo.txt
$TEST_DIR/zoo.txt" \
    "$TEST_DIR/zoo.txt"

# Print summary
echo "----------------------------------------"
echo "Test Summary:"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"
echo "----------------------------------------"

# Exit with error if any tests failed
if [ $TESTS_FAILED -gt 0 ]; then
    exit 1
fi 