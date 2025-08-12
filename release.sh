#!/bin/bash

# Touch Grass Release Script
# This script creates a repeatable release process with semantic versioning

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
    echo "Usage: ./release.sh <version>"
    echo "Example: ./release.sh 1.0.0"
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

# 3. Build the app
print_status "Building Touch Grass v$VERSION..."
if [ -f "Local.xcconfig" ]; then
    xcodebuild -project TouchGrass.xcodeproj \
               -scheme TouchGrass \
               -configuration Release \
               -xcconfig Local.xcconfig \
               build \
               SYMROOT=build \
               -quiet
else
    print_warning "No Local.xcconfig found. Building without code signing..."
    xcodebuild -project TouchGrass.xcodeproj \
               -scheme TouchGrass \
               -configuration Release \
               build \
               SYMROOT=build \
               CODE_SIGN_IDENTITY="" \
               CODE_SIGNING_REQUIRED=NO \
               -quiet
fi

# 4. Create release directory
RELEASE_DIR="releases/v$VERSION"
mkdir -p "$RELEASE_DIR"

# 5. Create DMG installer
print_status "Creating DMG installer..."

# Create a temporary directory for DMG contents
DMG_TEMP="$RELEASE_DIR/dmg-temp"
mkdir -p "$DMG_TEMP"

# Copy the app to temp directory
cp -R "build/Release/Touch Grass.app" "$DMG_TEMP/"

# Create DMG with create-dmg tool
DMG_NAME="Touch-Grass-v$VERSION.dmg"
create-dmg \
  --volname "Touch Grass $VERSION" \
  --volicon "build/Release/Touch Grass.app/Contents/Resources/AppIcon.icns" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "Touch Grass.app" 150 160 \
  --hide-extension "Touch Grass.app" \
  --app-drop-link 450 160 \
  --no-internet-enable \
  "$RELEASE_DIR/$DMG_NAME" \
  "$DMG_TEMP" 2>/dev/null || {
    print_warning "create-dmg failed, falling back to simple DMG creation..."
    hdiutil create -volname "Touch Grass $VERSION" \
                   -srcfolder "$DMG_TEMP" \
                   -ov \
                   -format UDZO \
                   "$RELEASE_DIR/$DMG_NAME"
}

# Clean up temp directory
rm -rf "$DMG_TEMP"

# 6. Generate checksums
print_status "Generating checksums..."
cd "$RELEASE_DIR"
shasum -a 256 "$DMG_NAME" > "SHA256SUMS.txt"
cd ../..

# 7. Create release notes
print_status "Creating release notes..."

# Check if release notes were provided as second argument
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

cat > "$RELEASE_DIR/RELEASE_NOTES.md" << EOF
# Touch Grass v$VERSION

## What's Changed
$RELEASE_MESSAGE

## Installation

1. Download \`Touch-Grass-v$VERSION.dmg\`
2. Open the DMG file
3. Drag \`Touch Grass.app\` to the Applications folder
4. Eject the DMG
5. Open Touch Grass from your Applications folder

**Note:** You may need to right-click and select "Open" the first time to bypass Gatekeeper

## Notes
- macOS 11.0 or later required
- The app will request calendar permissions if you want meeting awareness features

## Checksums
\`\`\`
$(cat "$RELEASE_DIR/SHA256SUMS.txt")
\`\`\`
EOF

# 8. Commit version changes
print_status "Committing version changes..."
git add Info.plist VERSION
git commit -m "Release version $VERSION" || {
    print_warning "No version changes to commit"
}

# 9. Create git tag
print_status "Creating git tag v$VERSION..."
git tag -a "v$VERSION" -m "Release version $VERSION"

# 10. Push everything to GitHub
print_status "Pushing changes and tag to GitHub..."
git push origin main
git push origin "v$VERSION"

# 11. Create GitHub release
print_status "Creating GitHub release..."
gh release create "v$VERSION" \
  --title "Touch Grass v$VERSION" \
  --notes-file "$RELEASE_DIR/RELEASE_NOTES.md" \
  "$RELEASE_DIR/$DMG_NAME" || {
    print_error "Failed to create GitHub release"
    print_warning "You can manually create it at: https://github.com/dmfenton/TouchGrass/releases/new"
    exit 1
}

# 12. Success!
echo ""
print_status "🎉 Release v$VERSION published successfully!"
echo ""
echo "📦 Release artifacts:"
echo "   - $DMG_NAME"
echo "   - SHA256SUMS.txt"
echo ""
echo "🔗 View release: https://github.com/dmfenton/TouchGrass/releases/tag/v$VERSION"
echo ""
print_status "Done!"