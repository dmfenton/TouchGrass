#!/bin/bash
# Script to add Swift files to Xcode project with proper group organization

PROJECT_FILE="TouchGrass.xcodeproj/project.pbxproj"

# Group IDs - these need to match what's in your project file
MAIN_GROUP_ID="B71234521234567812345678"  # The main "." group ID
MANAGERS_GROUP_ID="A1B2C3D4E5F67890MANAGERS"
MODELS_GROUP_ID="A1B2C3D4E5F67890MODELS00"
VIEWS_GROUP_ID="A1B2C3D4E5F67890VIEWS000"
TOUCHGRASS_GROUP_ID="A1B2C3D4E5F67890TOUCHGR"
DESIGN_GROUP_ID="A1B2C3D4E5F67890DESIGN00"
COMPONENTS_GROUP_ID="A1B2C3D4E5F67890COMPONEN"

# Generate a UUID-like ID (24 chars)
generate_id() {
    echo $(uuidgen | tr -d '-' | tr '[:lower:]' '[:upper:]' | cut -c1-24)
}

# Ensure groups exist in the project
ensure_groups_exist() {
    local needs_update=false
    
    # Check if Managers group exists
    if ! grep -q "$MANAGERS_GROUP_ID /\* Managers \*/" "$PROJECT_FILE"; then
        echo "Creating Managers group..."
        needs_update=true
        # Add Managers group
        sed -i '' "/\/\* End PBXGroup section \*\//i\\
		$MANAGERS_GROUP_ID /* Managers */ = {\\
			isa = PBXGroup;\\
			children = (\\
			);\\
			name = Managers;\\
			path = Managers;\\
			sourceTree = \"<group>\";\\
		};
" "$PROJECT_FILE"
    fi
    
    # Check if Models group exists
    if ! grep -q "$MODELS_GROUP_ID /\* Models \*/" "$PROJECT_FILE"; then
        echo "Creating Models group..."
        needs_update=true
        sed -i '' "/\/\* End PBXGroup section \*\//i\\
		$MODELS_GROUP_ID /* Models */ = {\\
			isa = PBXGroup;\\
			children = (\\
			);\\
			name = Models;\\
			path = Models;\\
			sourceTree = \"<group>\";\\
		};
" "$PROJECT_FILE"
    fi
    
    # Check if Views group exists
    if ! grep -q "$VIEWS_GROUP_ID /\* Views \*/" "$PROJECT_FILE"; then
        echo "Creating Views group..."
        needs_update=true
        sed -i '' "/\/\* End PBXGroup section \*\//i\\
		$VIEWS_GROUP_ID /* Views */ = {\\
			isa = PBXGroup;\\
			children = (\\
			);\\
			name = Views;\\
			path = Views;\\
			sourceTree = \"<group>\";\\
		};
" "$PROJECT_FILE"
    fi
    
    # Check if TouchGrass group exists
    if ! grep -q "$TOUCHGRASS_GROUP_ID /\* TouchGrass \*/" "$PROJECT_FILE"; then
        echo "Creating TouchGrass group..."
        needs_update=true
        sed -i '' "/\/\* End PBXGroup section \*\//i\\
		$TOUCHGRASS_GROUP_ID /* TouchGrass */ = {\\
			isa = PBXGroup;\\
			children = (\\
				$DESIGN_GROUP_ID /* Design */,\\
				$COMPONENTS_GROUP_ID /* Components */,\\
			);\\
			name = TouchGrass;\\
			path = TouchGrass;\\
			sourceTree = \"<group>\";\\
		};
" "$PROJECT_FILE"
    fi
    
    # Check if Design group exists
    if ! grep -q "$DESIGN_GROUP_ID /\* Design \*/" "$PROJECT_FILE"; then
        echo "Creating Design group..."
        needs_update=true
        sed -i '' "/\/\* End PBXGroup section \*\//i\\
		$DESIGN_GROUP_ID /* Design */ = {\\
			isa = PBXGroup;\\
			children = (\\
			);\\
			name = Design;\\
			path = Design;\\
			sourceTree = \"<group>\";\\
		};
" "$PROJECT_FILE"
    fi
    
    # Check if Components group exists
    if ! grep -q "$COMPONENTS_GROUP_ID /\* Components \*/" "$PROJECT_FILE"; then
        echo "Creating Components group..."
        needs_update=true
        sed -i '' "/\/\* End PBXGroup section \*\//i\\
		$COMPONENTS_GROUP_ID /* Components */ = {\\
			isa = PBXGroup;\\
			children = (\\
			);\\
			name = Components;\\
			path = \"Views/Components\";\\
			sourceTree = \"<group>\";\\
		};
" "$PROJECT_FILE"
    fi
    
    # If we added groups, ensure they're in the main group
    if [ "$needs_update" = true ]; then
        # Check if groups are already in main group children
        if ! grep -q "$MANAGERS_GROUP_ID /\* Managers \*/" "$PROJECT_FILE" | grep -A5 "$MAIN_GROUP_ID"; then
            # Add groups to main group children
            sed -i '' "/$MAIN_GROUP_ID \/\* \. \*\/ = {/,/};/{
                /children = (/a\\
				$MANAGERS_GROUP_ID /* Managers */,\\
				$MODELS_GROUP_ID /* Models */,\\
				$VIEWS_GROUP_ID /* Views */,\\
				$TOUCHGRASS_GROUP_ID /* TouchGrass */,
            }" "$PROJECT_FILE"
        fi
    fi
}

# Determine which group a file should belong to based on its path
get_target_group() {
    local file_path="$1"
    
    if [[ "$file_path" == Managers/* ]]; then
        echo "$MANAGERS_GROUP_ID"
    elif [[ "$file_path" == Models/* ]]; then
        echo "$MODELS_GROUP_ID"
    elif [[ "$file_path" == Views/* ]]; then
        echo "$VIEWS_GROUP_ID"
    elif [[ "$file_path" == TouchGrass/Design/* ]]; then
        echo "$DESIGN_GROUP_ID"
    elif [[ "$file_path" == TouchGrass/Views/Components/* ]]; then
        echo "$COMPONENTS_GROUP_ID"
    elif [[ "$file_path" == TouchGrass/* ]]; then
        echo "$TOUCHGRASS_GROUP_ID"
    else
        # Default to main group for root level files
        echo "$MAIN_GROUP_ID"
    fi
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
    
    # Determine target group
    local target_group=$(get_target_group "$file_path")
    local group_name=""
    
    case "$target_group" in
        "$MANAGERS_GROUP_ID") group_name="Managers" ;;
        "$MODELS_GROUP_ID") group_name="Models" ;;
        "$VIEWS_GROUP_ID") group_name="Views" ;;
        "$DESIGN_GROUP_ID") group_name="Design" ;;
        "$COMPONENTS_GROUP_ID") group_name="Components" ;;
        "$TOUCHGRASS_GROUP_ID") group_name="TouchGrass" ;;
        *) group_name="root" ;;
    esac
    
    # Add file reference to PBXFileReference section
    sed -i '' "/\/\* End PBXFileReference section \*\//i\\
		$file_ref /* $file_name */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; name = $file_name; path = $file_path; sourceTree = \"<group>\"; };
" "$PROJECT_FILE"
    
    # Add build file reference to PBXBuildFile section
    sed -i '' "/\/\* End PBXBuildFile section \*\//i\\
		$build_ref /* $file_name in Sources */ = {isa = PBXBuildFile; fileRef = $file_ref /* $file_name */; };
" "$PROJECT_FILE"
    
    # Add to appropriate group
    if [ "$target_group" = "$MAIN_GROUP_ID" ]; then
        # Add to main group after Info.plist
        sed -i '' "/$MAIN_GROUP_ID \/\* \. \*\/ = {/,/};/{
            /B712345F1234567812345678 \/\* Info.plist \*\/,/a\\
				$file_ref /* $file_name */,
        }" "$PROJECT_FILE"
    else
        # Add to specific group
        sed -i '' "/$target_group \/\* .* \*\/ = {/,/};/{
            /children = (/a\\
				$file_ref /* $file_name */,
        }" "$PROJECT_FILE"
    fi
    
    # Add to sources build phase
    sed -i '' "/B712344C1234567812345678 \/\* Sources \*\/ = {/,/};/{
        /files = (/a\\
				$build_ref /* $file_name in Sources */,
    }" "$PROJECT_FILE"
    
    echo "✓ Added $file_name to $group_name group"
}

# Main script
if [ $# -eq 0 ]; then
    echo "Usage: $0 <file1.swift> [file2.swift ...]"
    echo "Example: $0 Views/NewView.swift Models/NewModel.swift"
    echo ""
    echo "Files will be automatically added to the correct group based on their path:"
    echo "  - Managers/*.swift -> Managers group"
    echo "  - Models/*.swift -> Models group"
    echo "  - Views/*.swift -> Views group"
    echo "  - TouchGrass/Design/*.swift -> Design group"
    echo "  - TouchGrass/Views/Components/*.swift -> Components group"
    exit 1
fi

# Verify project file exists
if [ ! -f "$PROJECT_FILE" ]; then
    echo "Error: Xcode project file not found at $PROJECT_FILE"
    echo "Make sure you're running this script from the project root directory."
    exit 1
fi

# Ensure all groups exist
ensure_groups_exist

# Add each file passed as argument
for file in "$@"; do
    if [ -f "$file" ]; then
        add_file "$file"
    else
        echo "Warning: File not found: $file"
    fi
done

echo "Done! Files added to their appropriate groups."
echo "Note: You may need to rebuild the project in Xcode."