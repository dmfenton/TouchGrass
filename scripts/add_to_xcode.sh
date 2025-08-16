#!/bin/bash
# Simple script to add Swift files to Xcode project using manual insertion

PROJECT_FILE="TouchGrass.xcodeproj/project.pbxproj"

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
    
    # Add file reference
    sed -i '' "/\/\* End PBXFileReference section \*\//i\\
		$file_ref /* $file_name */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \"$file_path\"; sourceTree = \"<group>\"; };
" "$PROJECT_FILE"
    
    # Add build file reference  
    sed -i '' "/\/\* End PBXBuildFile section \*\//i\\
		$build_ref /* $file_name in Sources */ = {isa = PBXBuildFile; fileRef = $file_ref /* $file_name */; };
" "$PROJECT_FILE"
    
    # Add to main group (after TouchGrassOnboarding.swift)
    sed -i '' "/FD7F061FFE06404F93802258 \/\* TouchGrassOnboarding.swift \*\/,/a\\
				$file_ref /* $file_name */,
" "$PROJECT_FILE"
    
    # Add to sources build phase (after TouchGrassOnboarding.swift in Sources)
    sed -i '' "/27FCEFAFB7E64E6F8BAE5659 \/\* TouchGrassOnboarding.swift in Sources \*\/,/a\\
				$build_ref /* $file_name in Sources */,
" "$PROJECT_FILE"
    
    echo "✓ Added $file_name"
}

# Process command line arguments
if [ $# -eq 0 ]; then
    echo "Usage: $0 <file1.swift> [file2.swift ...]"
    echo "Example: $0 Views/NewView.swift Models/NewModel.swift"
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

echo "Done!"