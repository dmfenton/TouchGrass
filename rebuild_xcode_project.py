#!/usr/bin/env python3
"""
Rebuild Xcode project file references by scanning all Swift files.
This ensures all files are properly linked in the build phase.
"""

import os
import re
import uuid
from pathlib import Path

def generate_uuid():
    """Generate a 24-character Xcode project ID"""
    return ''.join(str(uuid.uuid4()).upper().split('-'))[:24]

def find_all_swift_files():
    """Find all Swift files in the project"""
    swift_files = []
    
    # Skip these files
    skip_files = {'GrassIconPreview.swift', 'generate_icon.swift'}
    
    # Search in specific directories
    for directory in ['Views', 'Managers', 'Models']:
        if os.path.exists(directory):
            for file in Path(directory).glob('**/*.swift'):
                filename = file.name
                if filename not in skip_files:
                    swift_files.append((filename, str(file)))
    
    # Add root level app files
    for file in Path('.').glob('*.swift'):
        if not file.is_dir() and file.name not in skip_files:
            swift_files.append((file.name, file.name))
    
    return sorted(swift_files)

def create_project_structure():
    """Create a new project structure with all files"""
    
    files = find_all_swift_files()
    print(f"Found {len(files)} Swift files to include")
    
    # Generate IDs for all files
    file_data = {}
    for name, path in files:
        file_data[name] = {
            'path': path,
            'file_ref': generate_uuid(),
            'build_ref': generate_uuid()
        }
    
    # Read template
    with open('TouchGrass.xcodeproj/project.pbxproj', 'r') as f:
        content = f.read()
    
    # Clear existing Swift file references (except system files)
    # First, extract the structure
    lines = content.split('\n')
    new_lines = []
    in_file_ref = False
    in_build_ref = False
    in_sources = False
    
    for line in lines:
        # Skip Swift file references we're rebuilding
        if '.swift' in line and any(name in line for name, _ in files):
            continue
        new_lines.append(line)
    
    content = '\n'.join(new_lines)
    
    # Build new file references section
    file_refs = []
    for name, data in file_data.items():
        file_refs.append(f'\t\t{data["file_ref"]} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{data["path"]}"; sourceTree = "<group>"; }};')
    
    # Build new build file references
    build_refs = []
    for name, data in file_data.items():
        build_refs.append(f'\t\t{data["build_ref"]} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {data["file_ref"]} /* {name} */; }};')
    
    # Insert file references
    content = content.replace(
        '/* End PBXFileReference section */',
        '\n'.join(file_refs) + '\n/* End PBXFileReference section */'
    )
    
    # Insert build references
    content = content.replace(
        '/* End PBXBuildFile section */',
        '\n'.join(build_refs) + '\n/* End PBXBuildFile section */'
    )
    
    # Add to appropriate groups
    managers_refs = []
    views_refs = []
    models_refs = []
    root_refs = []
    
    for name, data in file_data.items():
        ref_line = f'\t\t\t\t{data["file_ref"]} /* {name} */,'
        if 'Managers/' in data['path']:
            managers_refs.append(ref_line)
        elif 'Views/' in data['path']:
            views_refs.append(ref_line)
        elif 'Models/' in data['path']:
            models_refs.append(ref_line)
        else:
            root_refs.append(ref_line)
    
    # Add to Managers group
    if managers_refs:
        pattern = r'(B71234591234567812345678 /\* Managers \*/ = \{[^}]+children = \([^)]*)'
        replacement = r'\1\n' + '\n'.join(managers_refs)
        content = re.sub(pattern, replacement, content, flags=re.DOTALL)
    
    # Add to Views group
    if views_refs:
        pattern = r'(B71234571234567812345678 /\* Views \*/ = \{[^}]+children = \([^)]*)'
        replacement = r'\1\n' + '\n'.join(views_refs)
        content = re.sub(pattern, replacement, content, flags=re.DOTALL)
    
    # Add to Models group
    if models_refs:
        pattern = r'(B71234581234567812345678 /\* Models \*/ = \{[^}]+children = \([^)]*)'
        replacement = r'\1\n' + '\n'.join(models_refs)
        content = re.sub(pattern, replacement, content, flags=re.DOTALL)
    
    # Add all files to Sources build phase
    sources_refs = []
    for name, data in file_data.items():
        sources_refs.append(f'\t\t\t\t{data["build_ref"]} /* {name} in Sources */,')
    
    pattern = r'(B71234551234567812345678 /\* Sources \*/ = \{[^}]+files = \([^)]*)'
    replacement = r'\1\n' + '\n'.join(sources_refs)
    content = re.sub(pattern, replacement, content, flags=re.DOTALL)
    
    return content

def main():
    project_file = 'TouchGrass.xcodeproj/project.pbxproj'
    
    print("🔨 Rebuilding Xcode project file...")
    
    # Backup current project
    with open(project_file, 'r') as f:
        original = f.read()
    
    with open(project_file + '.backup', 'w') as f:
        f.write(original)
    
    # Create new structure
    new_content = create_project_structure()
    
    # Write new project file
    with open(project_file, 'w') as f:
        f.write(new_content)
    
    print("✅ Project file rebuilt successfully")
    print("   Backup saved as project.pbxproj.backup")

if __name__ == "__main__":
    main()