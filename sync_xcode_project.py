#!/usr/bin/env python3
"""
Sync Xcode project file with actual Swift files in the filesystem.
Automatically adds missing files and removes references to deleted files.
"""

import os
import re
import uuid
from pathlib import Path

def generate_uuid():
    """Generate a 24-character Xcode project ID"""
    return ''.join(str(uuid.uuid4()).upper().split('-'))[:24]

def find_swift_files():
    """Find all Swift files in the project directories"""
    swift_files = []
    for directory in ['Views', 'Managers', 'Models', 'Assets']:
        if os.path.exists(directory):
            for file in Path(directory).glob('**/*.swift'):
                relative_path = str(file)
                filename = os.path.basename(relative_path)
                swift_files.append((filename, relative_path))
    
    # Add root level Swift files
    for file in Path('.').glob('*.swift'):
        if not file.is_dir():
            filename = file.name
            swift_files.append((filename, filename))
    
    return swift_files

def get_existing_files(content):
    """Extract existing Swift files from project content"""
    pattern = r'/\* ([\w\s]+\.swift) \*/'
    matches = re.findall(pattern, content)
    return set(matches)

def remove_missing_files(content, filesystem_files):
    """Remove references to files that don't exist in filesystem"""
    filesystem_names = {name for name, _ in filesystem_files}
    existing_in_project = get_existing_files(content)
    
    files_to_remove = existing_in_project - filesystem_names
    
    for filename in files_to_remove:
        print(f"  Removing missing file: {filename}")
        # Remove all lines containing this filename
        pattern = f'.*{re.escape(filename)}.*\n?'
        content = re.sub(pattern, '', content, flags=re.MULTILINE)
    
    return content, len(files_to_remove)

def add_missing_files(content, filesystem_files):
    """Add files that exist in filesystem but not in project"""
    filesystem_dict = {name: path for name, path in filesystem_files}
    existing_in_project = get_existing_files(content)
    
    files_to_add = []
    for name, path in filesystem_dict.items():
        if name not in existing_in_project and name != 'GrassIconPreview.swift':  # Skip preview files
            files_to_add.append((name, path))
    
    if not files_to_add:
        return content, 0
    
    for name, path in files_to_add:
        print(f"  Adding new file: {name}")
        
        file_ref = generate_uuid()
        build_ref = generate_uuid()
        
        # Add file reference
        file_ref_line = f'\t\t{file_ref} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{path}"; sourceTree = "<group>"; }};\n'
        content = content.replace(
            '/* End PBXFileReference section */',
            file_ref_line + '/* End PBXFileReference section */'
        )
        
        # Add build file reference
        build_ref_line = f'\t\t{build_ref} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref} /* {name} */; }};\n'
        content = content.replace(
            '/* End PBXBuildFile section */',
            build_ref_line + '/* End PBXBuildFile section */'
        )
        
        # Determine which group to add to based on path
        if 'Managers/' in path:
            # Add to Managers group
            pattern = r'(B71234591234567812345678 /\* Managers \*/ = \{[^}]+children = \([^)]+)'
            if re.search(pattern, content):
                replacement = rf'\1\n\t\t\t\t{file_ref} /* {name} */,'
                content = re.sub(pattern, replacement, content)
        elif 'Views/' in path:
            # Add to Views group
            pattern = r'(B71234571234567812345678 /\* Views \*/ = \{[^}]+children = \([^)]+)'
            if re.search(pattern, content):
                replacement = rf'\1\n\t\t\t\t{file_ref} /* {name} */,'
                content = re.sub(pattern, replacement, content)
        elif 'Models/' in path:
            # Add to Models group
            pattern = r'(B71234581234567812345678 /\* Models \*/ = \{[^}]+children = \([^)]+)'
            if re.search(pattern, content):
                replacement = rf'\1\n\t\t\t\t{file_ref} /* {name} */,'
                content = re.sub(pattern, replacement, content)
        else:
            # Add to root group
            pattern = r'(B71234561234567812345678 /\* TouchGrass \*/ = \{[^}]+children = \([^)]+)'
            if re.search(pattern, content):
                replacement = rf'\1\n\t\t\t\t{file_ref} /* {name} */,'
                content = re.sub(pattern, replacement, content)
        
        # Add to sources build phase
        pattern = r'(B71234551234567812345678 /\* Sources \*/ = \{[^}]+files = \([^)]+)'
        if re.search(pattern, content):
            replacement = rf'\1\n\t\t\t\t{build_ref} /* {name} in Sources */,'
            content = re.sub(pattern, replacement, content)
    
    return content, len(files_to_add)

def main():
    project_file = 'TouchGrass.xcodeproj/project.pbxproj'
    
    print("🔄 Syncing Xcode project with filesystem...")
    
    # Read current project
    with open(project_file, 'r') as f:
        content = f.read()
    
    # Get filesystem state
    filesystem_files = find_swift_files()
    print(f"📁 Found {len(filesystem_files)} Swift files in filesystem")
    
    # Get project state
    existing_files = get_existing_files(content)
    print(f"📋 Found {len(existing_files)} Swift files in project")
    
    # Remove missing files
    content, removed_count = remove_missing_files(content, filesystem_files)
    
    # Add new files
    content, added_count = add_missing_files(content, filesystem_files)
    
    # Write back if changes were made
    if removed_count > 0 or added_count > 0:
        with open(project_file, 'w') as f:
            f.write(content)
        print(f"✅ Project updated: +{added_count} files, -{removed_count} files")
    else:
        print("✅ Project is already in sync")

if __name__ == "__main__":
    main()