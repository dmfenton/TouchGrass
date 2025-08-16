#!/bin/bash

# Touch Grass Test Runner
# Uses standard xcodebuild test command

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🧪 Running Touch Grass Tests"
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

# Run tests using xcodebuild
if [ "$VERBOSE" = true ]; then
    xcodebuild test \
        -project TouchGrass.xcodeproj \
        -scheme TouchGrassTests \
        -destination 'platform=macOS' \
        -resultBundlePath build/test-results \
        | xcpretty --test --color || true
else
    xcodebuild test \
        -project TouchGrass.xcodeproj \
        -scheme TouchGrassTests \
        -destination 'platform=macOS' \
        -quiet \
        -resultBundlePath build/test-results
fi

# Check test results
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
else
    echo -e "${RED}❌ Tests failed!${NC}"
    exit 1
fi