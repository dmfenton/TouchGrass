#!/usr/bin/env python3

import re

# Read the project file
with open('TouchGrass.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# 1. Remove Asset Catalog compiler settings
content = re.sub(r'\s*ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;\n', '', content)
content = re.sub(r'\s*ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;\n', '', content)

# 2. Add AppIcon.icns to PBXFileReference section
# Find the last file reference before the end marker
file_ref_pattern = r'(\/\* End PBXFileReference section \*\/)'
new_file_ref = '\t\tABCDEF1234567890ABCDEF12 /* AppIcon.icns */ = {isa = PBXFileReference; lastKnownFileType = image.icns; path = AppIcon.icns; sourceTree = "<group>"; };\n'

if 'AppIcon.icns' not in content:
    content = re.sub(file_ref_pattern, new_file_ref + r'\1', content)

# 3. Add AppIcon.icns to PBXBuildFile section
build_file_pattern = r'(\/\* End PBXBuildFile section \*\/)'
new_build_file = '\t\tABCDEF1234567890ABCDEF13 /* AppIcon.icns in Resources */ = {isa = PBXBuildFile; fileRef = ABCDEF1234567890ABCDEF12 /* AppIcon.icns */; };\n'

if 'AppIcon.icns in Resources' not in content:
    content = re.sub(build_file_pattern, new_build_file + r'\1', content)

# 4. Add to Resources build phase
resources_pattern = r'(B712344E1234567812345678 \/\* Resources \*\/ = \{\s*isa = PBXResourcesBuildPhase;\s*buildActionMask = 2147483647;\s*files = \(\s*)'
new_resource = r'\1\n\t\t\t\tABCDEF1234567890ABCDEF13 /* AppIcon.icns in Resources */,'

content = re.sub(resources_pattern, new_resource, content)

# 5. Add to main group children
# Find the main group and add AppIcon.icns to children
group_pattern = r'(B71234521234567812345678 \/\* Touch Grass \*\/ = \{[^}]*children = \([^)]*)(B712345F1234567812345678 \/\* Info\.plist \*\/,)'
new_group_item = r'\1ABCDEF1234567890ABCDEF12 /* AppIcon.icns */,\n\t\t\t\t\2'

content = re.sub(group_pattern, new_group_item, content)

# Write the updated content back
with open('TouchGrass.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print("✅ Project file updated successfully!")
print("- Removed Asset Catalog references")
print("- Added AppIcon.icns to project resources")