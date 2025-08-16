#!/usr/bin/env python3
"""Add WaterTracker.swift to Xcode project"""

import uuid
import re

def generate_uuid():
    """Generate a 24-character hex UUID for Xcode"""
    return uuid.uuid4().hex[:24].upper()

# Read project file
with open('TouchGrass.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# Generate UUIDs for WaterTracker
file_ref_id = generate_uuid()
build_file_id = generate_uuid()

# Add file reference
file_ref = f'\t\t{file_ref_id} /* WaterTracker.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "Managers/WaterTracker.swift"; sourceTree = "<group>"; }};'

# Find location to insert file reference (after other manager files)
pattern = r'(588BED2B819F48D5A350290D /\* CalendarManager\.swift \*/[^;]+;)'
content = re.sub(pattern, r'\1\n' + file_ref, content)

# Add build file
build_file = f'\t\t{build_file_id} /* WaterTracker.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* WaterTracker.swift */; }};'

# Find location to insert build file (after CalendarManager in build files)
pattern = r'(04BC7CF9F32E43918D489AC8 /\* CalendarManager\.swift in Sources \*/[^;]+;)'
content = re.sub(pattern, r'\1\n' + build_file, content)

# Add to group (find TouchGrass group and add after CalendarManager)
pattern = r'(588BED2B819F48D5A350290D /\* CalendarManager\.swift \*/,)'
content = re.sub(pattern, r'\1\n\t\t\t\t' + file_ref_id + ' /* WaterTracker.swift */,', content)

# Add to Sources build phase
pattern = r'(04BC7CF9F32E43918D489AC8 /\* CalendarManager\.swift in Sources \*/,)'
content = re.sub(pattern, r'\1\n\t\t\t\t' + build_file_id + ' /* WaterTracker.swift in Sources */,', content)

# Write back
with open('TouchGrass.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print(f"Added WaterTracker.swift with file ref {file_ref_id} and build file {build_file_id}")