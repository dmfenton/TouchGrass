#!/usr/bin/env python3

import sys
import uuid
import re
import os

def generate_id():
    """Generate a 24-character Xcode ID"""
    return uuid.uuid4().hex[:24].upper()

def add_file_to_project(project_path, file_path):
    """Add a Swift file to the Xcode project"""
    file_name = os.path.basename(file_path)
    
    with open(project_path, 'r') as f:
        content = f.read()
    
    # Check if file already exists
    if f"/* {file_name} */" in content:
        print(f"✓ {file_name} already in project")
        return
    
    print(f"Adding {file_name}...")
    
    # Generate IDs
    file_ref = generate_id()
    build_ref = generate_id()
    
    # Add file reference
    file_ref_line = f'\t\t{file_ref} /* {file_name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{file_path}"; sourceTree = "<group>"; }};'
    content = content.replace(
        '/* End PBXFileReference section */',
        f'{file_ref_line}\n/* End PBXFileReference section */'
    )
    
    # Add build file reference
    build_ref_line = f'\t\t{build_ref} /* {file_name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref} /* {file_name} */; }};'
    content = content.replace(
        '/* End PBXBuildFile section */',
        f'{build_ref_line}\n/* End PBXBuildFile section */'
    )
    
    # Add to appropriate group based on path
    if 'Managers/' in file_path:
        # Add to Managers group
        pattern = r'(B71234591234567812345678 /\* Managers \*/ = \{[^}]+children = \([^)]+)'
        replacement = rf'\1\n\t\t\t\t{file_ref} /* {file_name} */,'
        content = re.sub(pattern, replacement, content)
    elif 'Views/' in file_path:
        # Add to Views group
        pattern = r'(B71234571234567812345678 /\* Views \*/ = \{[^}]+children = \([^)]+)'
        replacement = rf'\1\n\t\t\t\t{file_ref} /* {file_name} */,'
        content = re.sub(pattern, replacement, content)
    elif 'Models/' in file_path:
        # Add to Models group
        pattern = r'(B71234581234567812345678 /\* Models \*/ = \{[^}]+children = \([^)]+)'
        replacement = rf'\1\n\t\t\t\t{file_ref} /* {file_name} */,'
        content = re.sub(pattern, replacement, content)
    
    # Add to sources build phase
    pattern = r'(B71234551234567812345678 /\* Sources \*/ = \{[^}]+files = \([^)]+)'
    replacement = rf'\1\n\t\t\t\t{build_ref} /* {file_name} in Sources */,'
    content = re.sub(pattern, replacement, content)
    
    # Write back
    with open(project_path, 'w') as f:
        f.write(content)
    
    print(f"✅ Added {file_name} to project")

if __name__ == "__main__":
    project_file = "TouchGrass.xcodeproj/project.pbxproj"
    
    if len(sys.argv) < 2:
        print("Usage: python3 add_files_to_xcode.py <file1> [file2] ...")
        sys.exit(1)
    
    for file_path in sys.argv[1:]:
        if os.path.exists(file_path):
            add_file_to_project(project_file, file_path)
        else:
            print(f"❌ File not found: {file_path}")