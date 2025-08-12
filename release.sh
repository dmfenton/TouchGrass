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

# Also create a ZIP as fallback
print_status "Creating ZIP archive as fallback..."
cd build/Release
zip -r -q "../../$RELEASE_DIR/Touch-Grass-v$VERSION.zip" "Touch Grass.app"
cd ../..

# 6. Generate checksums
print_status "Generating checksums..."
cd "$RELEASE_DIR"
shasum -a 256 "$DMG_NAME" > "SHA256SUMS.txt"
shasum -a 256 "Touch-Grass-v$VERSION.zip" >> "SHA256SUMS.txt"
cd ../..

# 7. Create release notes template
print_status "Creating release notes template..."
cat > "$RELEASE_DIR/RELEASE_NOTES.md" << EOF
# Touch Grass v$VERSION

## What's Changed
- 

## Installation

### Option 1: DMG Installer (Recommended)
1. Download \`Touch-Grass-v$VERSION.dmg\`
2. Open the DMG file
3. Drag \`Touch Grass.app\` to the Applications folder
4. Eject the DMG
5. Open Touch Grass from your Applications folder

### Option 2: ZIP Archive
1. Download \`Touch-Grass-v$VERSION.zip\`
2. Unzip the file
3. Move \`Touch Grass.app\` to your Applications folder
4. Open the app

**Note:** You may need to right-click and select "Open" the first time to bypass Gatekeeper

## Notes
- macOS 11.0 or later required
- The app will request calendar permissions if you want meeting awareness features

## Checksums
\`\`\`
$(cat "$RELEASE_DIR/SHA256SUMS.txt")
\`\`\`
EOF

# 8. Create git tag
print_status "Creating git tag v$VERSION..."
git tag -a "v$VERSION" -m "Release version $VERSION"

# 9. Print next steps
echo ""
print_status "Release preparation complete!"
echo ""
echo "📦 Release artifacts created in: $RELEASE_DIR/"
echo "   - $DMG_NAME (DMG installer)"
echo "   - Touch-Grass-v$VERSION.zip (ZIP archive)"
echo "   - SHA256SUMS.txt"
echo "   - RELEASE_NOTES.md"
echo ""
echo "Next steps:"
echo "1. Edit $RELEASE_DIR/RELEASE_NOTES.md with actual release notes"
echo "2. Push the tag: git push origin v$VERSION"
echo "3. Create GitHub release:"
echo "   gh release create v$VERSION \\"
echo "     --title \"Touch Grass v$VERSION\" \\"
echo "     --notes-file \"$RELEASE_DIR/RELEASE_NOTES.md\" \\"
echo "     \"$RELEASE_DIR/$DMG_NAME\" \\"
echo "     \"$RELEASE_DIR/Touch-Grass-v$VERSION.zip\""
echo ""
echo "Or manually create release at: https://github.com/YOUR_USERNAME/touchgrass/releases/new"