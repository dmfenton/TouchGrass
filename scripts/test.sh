#!/bin/bash

# Touch Grass Integration Test Runner
# Runs all integration tests

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🧪 Running Touch Grass Integration Tests"
echo "========================================"

# Check if we're in the right directory
if [ ! -f "TouchGrass.xcodeproj/project.pbxproj" ]; then
    echo -e "${RED}Error: Must run from project root directory${NC}"
    exit 1
fi

# Parse command line arguments
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --verbose          Show detailed test output"
            echo "  --help             Show this help message"
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

# Run the test suite
if [ "$VERBOSE" = true ]; then
    swift TouchGrassTests/TestRunner.swift
else
    swift TouchGrassTests/TestRunner.swift 2>&1 | grep -E "(Running|Test Results|passed|failed|Total)" || swift TouchGrassTests/TestRunner.swift
fi

# Check test results
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
else
    echo -e "${RED}❌ Tests failed!${NC}"
    exit 1
fi