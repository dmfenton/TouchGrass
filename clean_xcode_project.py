#!/usr/bin/env python3
"""
Clean up duplicate entries in Xcode project file
"""

import re
from collections import defaultdict

def clean_project_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Track seen entries to remove duplicates
    seen_file_refs = {}  # filename -> (first_id, file_path)
    seen_build_refs = {}  # filename -> first_id
    
    # Parse file references
    file_ref_pattern = r'(\t\t([A-F0-9]{24}) /\* ([^*]+) \*/ = \{isa = PBXFileReference;[^}]+\};)'
    for match in re.finditer(file_ref_pattern, content):
        full_line = match.group(1)
        ref_id = match.group(2)
        filename = match.group(3)
        
        if filename not in seen_file_refs:
            seen_file_refs[filename] = (ref_id, full_line)
        else:
            # Remove duplicate
            print(f"Removing duplicate file reference: {filename}")
            content = content.replace(full_line + '\n', '')
    
    # Parse build references
    build_ref_pattern = r'(\t\t([A-F0-9]{24}) /\* ([^*]+) in Sources \*/ = \{isa = PBXBuildFile; fileRef = ([A-F0-9]{24})[^}]+\};)'
    for match in re.finditer(build_ref_pattern, content):
        full_line = match.group(1)
        build_id = match.group(2)
        filename = match.group(3)
        file_ref = match.group(4)
        
        if filename not in seen_build_refs:
            seen_build_refs[filename] = (build_id, file_ref, full_line)
        else:
            # Remove duplicate
            print(f"Removing duplicate build reference: {filename} in Sources")
            content = content.replace(full_line + '\n', '')
    
    # Clean up group children (file list) - remove duplicate references
    children_pattern = r'children = \(([\s\S]*?)\);'
    for match in re.finditer(children_pattern, content):
        children_content = match.group(1)
        original_children = children_content
        
        # Track seen file IDs in this group
        seen_in_group = set()
        lines = children_content.split('\n')
        cleaned_lines = []
        
        for line in lines:
            # Extract file ID from line like: 				B71234551234567812345678 /* TouchGrassApp.swift */,
            id_match = re.search(r'([A-F0-9]{24})', line)
            if id_match:
                file_id = id_match.group(1)
                if file_id not in seen_in_group:
                    seen_in_group.add(file_id)
                    cleaned_lines.append(line)
                else:
                    print(f"Removing duplicate from group: {line.strip()}")
            else:
                cleaned_lines.append(line)
        
        cleaned_children = '\n'.join(cleaned_lines)
        if cleaned_children != original_children:
            content = content.replace(original_children, cleaned_children)
    
    # Clean up sources build phase - remove duplicate source entries
    sources_pattern = r'/\* Sources \*/[^}]+files = \(([\s\S]*?)\);'
    for match in re.finditer(sources_pattern, content):
        sources_content = match.group(1)
        original_sources = sources_content
        
        # Track seen build IDs in sources
        seen_in_sources = set()
        lines = sources_content.split('\n')
        cleaned_lines = []
        
        for line in lines:
            # Extract build ID from line
            id_match = re.search(r'([A-F0-9]{24})', line)
            if id_match:
                build_id = id_match.group(1)
                if build_id not in seen_in_sources:
                    seen_in_sources.add(build_id)
                    cleaned_lines.append(line)
                else:
                    print(f"Removing duplicate from sources: {line.strip()}")
            else:
                cleaned_lines.append(line)
        
        cleaned_sources = '\n'.join(cleaned_lines)
        if cleaned_sources != original_sources:
            content = content.replace(original_sources, cleaned_sources)
    
    # Write back
    with open(filepath, 'w') as f:
        f.write(content)
    
    print("✅ Project file cleaned")

if __name__ == '__main__':
    clean_project_file('TouchGrass.xcodeproj/project.pbxproj')