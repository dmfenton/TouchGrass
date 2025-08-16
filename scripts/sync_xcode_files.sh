#!/bin/bash
# Script to properly add Swift files to Xcode project

echo "⚠️  This script would normally sync files with Xcode project"
echo "However, modifying the Xcode project file directly is complex and risky."
echo ""
echo "Please add these files manually in Xcode:"
echo ""
echo "Files missing from Xcode project:"
echo "================================"

for file in $(find . -name "*.swift" -not -path "./build/*" -not -path "./.git/*" -not -path "./TouchGrassTests/*"); do
  basename_file=$(basename "$file")
  if ! grep -q "$basename_file in Sources" TouchGrass.xcodeproj/project.pbxproj; then
    echo "  - $file"
  fi
done

echo ""
echo "To add files in Xcode:"
echo "1. Open TouchGrass.xcodeproj in Xcode"
echo "2. Right-click on the appropriate folder in the navigator"
echo "3. Select 'Add Files to TouchGrass...'"
echo "4. Select the files listed above"
echo "5. Make sure 'Copy items if needed' is unchecked"
echo "6. Make sure 'TouchGrass' target is checked"
echo "7. Click 'Add'"
echo ""
echo "After adding files, run: make build"