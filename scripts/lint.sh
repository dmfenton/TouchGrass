#!/bin/bash

# Touch Grass Linting Script
# Runs SwiftLint to check code style

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "🔍 Running SwiftLint..."
echo "========================"

# Check if SwiftLint is installed
if ! command -v swiftlint &> /dev/null; then
    echo -e "${RED}❌ SwiftLint is not installed${NC}"
    echo "Install with: brew install swiftlint"
    exit 1
fi

# Run SwiftLint
if [ "$1" == "--fix" ]; then
    echo "Auto-fixing violations..."
    swiftlint --fix
    echo -e "${GREEN}✅ Auto-fix complete${NC}"
else
    if swiftlint; then
        echo -e "${GREEN}✅ No style violations found${NC}"
    else
        echo -e "${YELLOW}⚠️  Style violations found${NC}"
        echo "Run 'make lint-fix' to auto-fix some violations"
        exit 1
    fi
fi