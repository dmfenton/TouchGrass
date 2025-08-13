#!/bin/bash

# Touch Grass Release Script - Local Build Version
# This script builds, signs, and releases the app entirely locally

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
if [ -n "$(git status --porcelain)" ]; then
    print_warning "You have uncommitted changes. Please commit or stash them first."
    echo "Uncommitted files:"
    git status --short
    exit 1
fi

# 2. Check for required tools
if ! command -v create-dmg &> /dev/null; then
    print_error "create-dmg is not installed. Install it with: brew install create-dmg"
    exit 1
fi

if ! command -v gh &> /dev/null; then
    print_error "GitHub CLI is not installed. Install it with: brew install gh"
    exit 1
fi

# 3. Update Info.plist with version
print_status "Updating version in Info.plist..."
if [ -f "Info.plist" ]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "Info.plist"
    # Also increment build number
    BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "Info.plist")
    NEW_BUILD_NUMBER=$((BUILD_NUMBER + 1))
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $NEW_BUILD_NUMBER" "Info.plist"
    print_status "Updated to version $VERSION (build $NEW_BUILD_NUMBER)"
else
    print_error "Could not find Info.plist"
    exit 1
fi

# Update VERSION file
echo "$VERSION" > VERSION

# 4. Build the app with code signing
print_status "Building and signing the app..."
if [ -f "Local.xcconfig" ]; then
    # Build with local code signing configuration
    xcodebuild -project TouchGrass.xcodeproj \
               -scheme TouchGrass \
               -configuration Release \
               -xcconfig Local.xcconfig \
               clean build \
               SYMROOT=build \
               -quiet
    print_status "App built with code signing"
else
    print_warning "Local.xcconfig not found. Building without code signing."
    print_warning "The app will not be properly signed for distribution."
    xcodebuild -project TouchGrass.xcodeproj \
               -scheme TouchGrass \
               -configuration Release \
               clean build \
               SYMROOT=build \
               -quiet
fi

# 5. Verify the app was built
if [ ! -d "build/Release/Touch Grass.app" ]; then
    print_error "Build failed. App not found at build/Release/Touch Grass.app"
    exit 1
fi

# 6. Create DMG installer
print_status "Creating DMG installer..."
DMG_NAME="Touch-Grass-v${VERSION}.dmg"
rm -f "$DMG_NAME"  # Remove old DMG if exists

# Create a temporary directory for DMG contents
TEMP_DMG_DIR=$(mktemp -d)
cp -R "build/Release/Touch Grass.app" "$TEMP_DMG_DIR/"

create-dmg \
    --volname "Touch Grass v${VERSION}" \
    --volicon "AppIcon.icns" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "Touch Grass.app" 150 185 \
    --app-drop-link 450 185 \
    --hide-extension "Touch Grass.app" \
    "$DMG_NAME" \
    "$TEMP_DMG_DIR"

# Clean up temp directory
rm -rf "$TEMP_DMG_DIR"

if [ ! -f "$DMG_NAME" ]; then
    print_error "Failed to create DMG"
    exit 1
fi

print_status "DMG created: $DMG_NAME"

# 7. Generate checksums
print_status "Generating checksums..."
shasum -a 256 "$DMG_NAME" > SHA256SUMS.txt

# 8. Get release notes
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

# 9. Commit version changes
print_status "Committing version changes..."
git add Info.plist VERSION
git commit -m "Release version $VERSION" || {
    print_warning "No version changes to commit"
}

# 10. Create git tag
print_status "Creating git tag v$VERSION..."
git tag -a "v$VERSION" -m "Release version $VERSION

$RELEASE_MESSAGE"

# 11. Push changes and tag
print_status "Pushing changes and tag to GitHub..."
git push origin main
git push origin "v$VERSION"

# 12. Create GitHub release with DMG
print_status "Creating GitHub release..."

RELEASE_BODY="## Installation

1. Download \`Touch-Grass-v${VERSION}.dmg\`
2. Open the DMG file
3. Drag \`Touch Grass.app\` to the Applications folder
4. Eject the DMG
5. Open Touch Grass from your Applications folder (you may need to right-click and select \"Open\" the first time)

## What's New

$RELEASE_MESSAGE

## Requirements
- macOS 11.0 or later

## Features
- Customizable break reminders
- Calendar awareness for meeting schedules
- Water tracking
- Exercise suggestions
- Work hours configuration"

# Create the release and upload the DMG
gh release create "v$VERSION" \
    --title "Touch Grass v$VERSION" \
    --notes "$RELEASE_BODY" \
    "$DMG_NAME" \
    "SHA256SUMS.txt"

# 13. Clean up
print_status "Cleaning up build artifacts..."
rm -rf build/

# 14. Success!
echo ""
print_status "🎉 Release v$VERSION completed successfully!"
echo ""
echo "Release published at:"
echo "  https://github.com/dmfenton/TouchGrass/releases/tag/v$VERSION"
echo ""
print_status "Done!"