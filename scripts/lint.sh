#!/bin/bash

# Touch Grass linting script
# Runs SwiftLint with project configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🧹 Running SwiftLint..."

# Check if SwiftLint is installed
if ! command -v swiftlint &> /dev/null; then
    echo -e "${RED}❌ SwiftLint is not installed${NC}"
    echo ""
    echo "Install with Homebrew:"
    echo "  brew install swiftlint"
    echo ""
    echo "Or download from:"
    echo "  https://github.com/realm/SwiftLint"
    exit 1
fi

# Check for config file
if [ ! -f ".swiftlint.yml" ]; then
    echo -e "${YELLOW}⚠️  No .swiftlint.yml config found${NC}"
    echo "Using SwiftLint defaults..."
    echo ""
fi

# Run SwiftLint
if [ "$1" == "--fix" ] || [ "$1" == "fix" ]; then
    echo "🔧 Auto-fixing violations..."
    swiftlint --fix --config .swiftlint.yml
    echo ""
    echo "🧹 Running lint check after fixes..."
fi

# Run the actual lint
OUTPUT=$(swiftlint lint --config .swiftlint.yml 2>&1)
EXIT_CODE=$?

# Parse the output
if [ $EXIT_CODE -eq 0 ]; then
    # Check if there are any violations in the output
    if echo "$OUTPUT" | grep -q "warning\|error"; then
        echo "$OUTPUT"
        echo ""
        echo -e "${YELLOW}⚠️  Violations found${NC}"
        echo ""
        echo "To auto-fix some violations, run:"
        echo "  ./lint.sh --fix"
        exit 1
    else
        echo -e "${GREEN}✅ No violations found!${NC}"
        echo ""
        
        # Show summary if verbose flag is set
        if [ "$1" == "--verbose" ] || [ "$1" == "-v" ]; then
            echo "$OUTPUT" | tail -5
        fi
    fi
else
    echo "$OUTPUT"
    echo ""
    echo -e "${RED}❌ Linting failed${NC}"
    echo ""
    echo "To auto-fix some violations, run:"
    echo "  ./lint.sh --fix"
    exit $EXIT_CODE
fi

# Optional: Run specific checks
if [ "$1" == "--strict" ]; then
    echo ""
    echo "🔍 Running strict checks..."
    
    # Check for TODOs
    TODO_COUNT=$(grep -r "TODO\|FIXME\|HACK" --include="*.swift" . 2>/dev/null | wc -l | tr -d ' ')
    if [ "$TODO_COUNT" -gt 0 ]; then
        echo -e "${YELLOW}📝 Found $TODO_COUNT TODO/FIXME/HACK comments${NC}"
    fi
    
    # Check for force unwraps
    FORCE_UNWRAP=$(grep -r "!" --include="*.swift" . 2>/dev/null | grep -v "!=" | grep -v "//" | wc -l | tr -d ' ')
    if [ "$FORCE_UNWRAP" -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Found potential force unwraps (manual review needed)${NC}"
    fi
    
    # Check for print statements
    PRINT_COUNT=$(grep -r "print(" --include="*.swift" . 2>/dev/null | grep -v "//" | wc -l | tr -d ' ')
    if [ "$PRINT_COUNT" -gt 0 ]; then
        echo -e "${YELLOW}🖨  Found $PRINT_COUNT print statements${NC}"
    fi
fi