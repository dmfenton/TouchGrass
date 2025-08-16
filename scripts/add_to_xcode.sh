#!/bin/bash
# Script to add Swift files to Xcode project properly

PROJECT_FILE="TouchGrass.xcodeproj/project.pbxproj"
MAIN_GROUP_ID="B71234521234567812345678"  # The main "." group ID

# Generate a UUID-like ID (24 chars)
generate_id() {
    echo $(uuidgen | tr -d '-' | tr '[:lower:]' '[:upper:]' | cut -c1-24)
}

add_file() {
    local file_path="$1"
    local file_name=$(basename "$file_path")
    
    # Check if file already exists in project
    if grep -q "/* $file_name */" "$PROJECT_FILE"; then
        echo "✓ $file_name already in project"
        return
    fi
    
    echo "Adding $file_name..."
    
    # Generate IDs
    local file_ref=$(generate_id)
    local build_ref=$(generate_id)
    
    # Create backup
    cp "$PROJECT_FILE" "${PROJECT_FILE}.backup"
    
    # Determine the proper name attribute based on path
    # If the file is in a subdirectory, use just the filename as name
    # and the full path as the path attribute
    local name_attr="$file_name"
    local path_attr="$file_path"
    
    # If the path contains directories, adjust the name to be relative
    if [[ "$file_path" == *"/"* ]]; then
        name_attr="$file_name"
        path_attr="$file_path"
    fi
    
    # Add file reference to PBXFileReference section
    # Using 'name' for display and 'path' for actual location
    sed -i '' "/\/\* End PBXFileReference section \*\//i\\
		$file_ref /* $file_name */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; name = $name_attr; path = $path_attr; sourceTree = \"<group>\"; };
" "$PROJECT_FILE"
    
    # Add build file reference to PBXBuildFile section
    sed -i '' "/\/\* End PBXBuildFile section \*\//i\\
		$build_ref /* $file_name in Sources */ = {isa = PBXBuildFile; fileRef = $file_ref /* $file_name */; };
" "$PROJECT_FILE"
    
    # Add to main group - find the main group and add after Info.plist
    # This ensures files go into the main project group, not Recovered References
    sed -i '' "/$MAIN_GROUP_ID \/\* \. \*\/ = {/,/};/{
        /B712345F1234567812345678 \/\* Info.plist \*\/,/a\\
				$file_ref /* $file_name */,
    }" "$PROJECT_FILE"
    
    # Add to sources build phase
    # Find the Sources build phase and add the new file
    sed -i '' "/B712344C1234567812345678 \/\* Sources \*\/ = {/,/};/{
        /files = (/a\\
				$build_ref /* $file_name in Sources */,
    }" "$PROJECT_FILE"
    
    echo "✓ Added $file_name to main project group"
}

# Process command line arguments
if [ $# -eq 0 ]; then
    echo "Usage: $0 <file1.swift> [file2.swift ...]"
    echo "Example: $0 Views/NewView.swift Models/NewModel.swift"
    echo ""
    echo "This script adds Swift files to the Xcode project."
    echo "Files will be added to the main project group, not Recovered References."
    exit 1
fi

# Verify project file exists
if [ ! -f "$PROJECT_FILE" ]; then
    echo "Error: Xcode project file not found at $PROJECT_FILE"
    echo "Make sure you're running this script from the project root directory."
    exit 1
fi

# Add each file passed as argument
for file in "$@"; do
    if [ -f "$file" ]; then
        add_file "$file"
    else
        echo "Warning: File not found: $file"
    fi
done

echo "Done! Files added to main project group."
echo "Note: You may need to rebuild the project in Xcode."