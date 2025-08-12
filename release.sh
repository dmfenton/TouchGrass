#!/bin/bash

# Touch Grass Release Script - GitHub Actions Version
# This script updates version, commits, tags, and triggers GitHub Actions

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check if version argument is provided
if [ $# -eq 0 ]; then
    echo "Usage: ./release.sh <version> [release notes]"
    echo "Example: ./release.sh 1.0.0 \"New features and bug fixes\""
    echo ""
    echo "Semantic Versioning:"
    echo "  MAJOR.MINOR.PATCH"
    echo "  - MAJOR: Breaking changes"
    echo "  - MINOR: New features (backwards compatible)"
    echo "  - PATCH: Bug fixes"
    exit 1
fi

VERSION=$1

# Validate version format (basic semver)
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    print_error "Invalid version format. Please use semantic versioning (e.g., 1.0.0)"
    exit 1
fi

print_status "Starting release process for version $VERSION"

# 1. Check for uncommitted changes
if [ -n "$(git status --porcelain | grep -v '^?? releases/')" ]; then
    print_warning "You have uncommitted changes. Please commit or stash them first."
    echo "Uncommitted files:"
    git status --short | grep -v '^?? releases/'
    exit 1
fi

# 2. Update Info.plist with version
print_status "Updating version in Info.plist..."
if [ -f "Info.plist" ]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "Info.plist"
    # Also increment build number
    BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "Info.plist")
    NEW_BUILD_NUMBER=$((BUILD_NUMBER + 1))
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $NEW_BUILD_NUMBER" "Info.plist"
    print_status "Updated to version $VERSION (build $NEW_BUILD_NUMBER)"
else
    print_warning "Could not find Info.plist to update version. Continuing..."
fi

# Update VERSION file
echo "$VERSION" > VERSION

# 3. Get release notes
if [ $# -ge 2 ]; then
    RELEASE_MESSAGE="$2"
else
    # Prompt for release notes
    echo ""
    echo "Enter release notes (what changed in this version):"
    echo "Press Enter twice when done:"
    RELEASE_MESSAGE=""
    while IFS= read -r line; do
        [ -z "$line" ] && break
        RELEASE_MESSAGE="${RELEASE_MESSAGE}${line}
"
    done
    
    if [ -z "$RELEASE_MESSAGE" ]; then
        RELEASE_MESSAGE="- Bug fixes and improvements"
    fi
fi

# 4. Commit version changes
print_status "Committing version changes..."
git add Info.plist VERSION
git commit -m "Release version $VERSION" || {
    print_warning "No version changes to commit"
}

# 5. Create git tag with release notes
print_status "Creating git tag v$VERSION..."
git tag -a "v$VERSION" -m "Release version $VERSION

$RELEASE_MESSAGE"

# 6. Push everything to GitHub
print_status "Pushing changes and tag to GitHub..."
git push origin main
git push origin "v$VERSION"

# 7. Success!
echo ""
print_status "🎉 Release v$VERSION pushed successfully!"
echo ""
echo "GitHub Actions will now:"
echo "  1. Build the app"
echo "  2. Create a DMG installer"
echo "  3. Create a draft release"
echo ""
echo "Next steps:"
echo "  1. Wait for GitHub Actions to complete"
echo "  2. Go to https://github.com/dmfenton/TouchGrass/releases"
echo "  3. Review and publish the draft release"
echo ""
print_status "Done!"