#!/usr/bin/env python3
import os
import re
import uuid

def generate_uuid():
    """Generate a unique ID for Xcode project"""
    return ''.join(str(uuid.uuid4()).upper().split('-'))[:24]

# Read the current project file
project_file = 'TouchGrass.xcodeproj/project.pbxproj'
with open(project_file, 'r') as f:
    content = f.read()

# Files to add (that aren't already in the project)
files_to_add = [
    ('SimpleOnboardingWindow.swift', 'Views/SimpleOnboardingWindow.swift'),
    ('SimpleOnboardingWindowController.swift', 'Views/SimpleOnboardingWindowController.swift'),
    ('OnboardingManager.swift', 'Managers/OnboardingManager.swift'),
    ('OnboardingWindow.swift', 'Views/OnboardingWindow.swift'),
    ('OnboardingWindowController.swift', 'Views/OnboardingWindowController.swift'),
    ('GrassIcon.swift', 'Views/GrassIcon.swift'),
]

# Generate UUIDs for each file
file_refs = {}
build_refs = {}
for name, path in files_to_add:
    file_refs[name] = generate_uuid()
    build_refs[name] = generate_uuid()

# Add file references
file_ref_section = ""
for name, path in files_to_add:
    file_ref_section += f'\t\t{file_refs[name]} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{path}"; sourceTree = "<group>"; }};\n'

# Add build file references
build_ref_section = ""
for name, path in files_to_add:
    build_ref_section += f'\t\t{build_refs[name]} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[name]} /* {name} */; }};\n'

# Insert file references after existing file references
file_ref_marker = "/* End PBXFileReference section */"
content = content.replace(file_ref_marker, file_ref_section + file_ref_marker)

# Insert build file references after existing build files
build_ref_marker = "/* End PBXBuildFile section */"
content = content.replace(build_ref_marker, build_ref_section + build_ref_marker)

# Add files to the group (file list)
group_addition = ""
for name, path in files_to_add:
    group_addition += f'\t\t\t\t{file_refs[name]} /* {name} */,\n'

# Find the TouchGrass group and add files
group_marker = "B71234671234567812345683 /* ExerciseWindowController.swift */,"
content = content.replace(group_marker, group_marker + "\n" + group_addition)

# Add files to Sources build phase
sources_addition = ""
for name, path in files_to_add:
    sources_addition += f'\t\t\t\t{build_refs[name]} /* {name} in Sources */,\n'

# Find the Sources build phase and add files
sources_marker = "B71234681234567812345683 /* ExerciseWindowController.swift in Sources */,"
content = content.replace(sources_marker, sources_marker + "\n" + sources_addition)

# Write the updated project file
with open(project_file, 'w') as f:
    f.write(content)

print("Updated Xcode project file with new Swift files")