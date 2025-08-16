#!/usr/bin/env python3

import sys
import re
import os

def remove_file_from_project(project_path, file_name):
    """Remove all references to a file from the Xcode project"""
    
    with open(project_path, 'r') as f:
        lines = f.readlines()
    
    # Filter out lines containing the file
    filtered_lines = []
    skip_next = False
    removed_count = 0
    
    for i, line in enumerate(lines):
        # Skip lines that reference the file
        if file_name in line:
            removed_count += 1
            # Check if this is a multi-line entry that needs continuation removal
            if '{' in line and '}' not in line:
                skip_next = True
            continue
        
        # Skip continuation of multi-line entries
        if skip_next:
            if '}' in line:
                skip_next = False
            continue
            
        filtered_lines.append(line)
    
    if removed_count > 0:
        print(f"✅ Removed {removed_count} references to {file_name}")
        
        # Write back
        with open(project_path, 'w') as f:
            f.writelines(filtered_lines)
    else:
        print(f"ℹ️  No references found for {file_name}")

if __name__ == "__main__":
    project_file = "TouchGrass.xcodeproj/project.pbxproj"
    
    if len(sys.argv) < 2:
        # Default to removing the known deleted files
        files_to_remove = [
            "OnboardingWindowController.swift",
            "SimpleOnboardingWindowController.swift", 
            "ExerciseSelectionController.swift"
        ]
    else:
        files_to_remove = sys.argv[1:]
    
    for file_name in files_to_remove:
        remove_file_from_project(project_file, file_name)