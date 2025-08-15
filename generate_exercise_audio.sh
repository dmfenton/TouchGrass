#!/bin/bash

# Comprehensive exercise audio generation script
# Extracts exercise data from Swift source and generates audio files
# Compatible with bash 3.2 (macOS default)

set -e

# Configuration
VOICE="nova"
MODEL="tts-1-hd"
ASSETS_DIR="Assets/Audio/Exercises"
CACHE_DIR=".audio_cache"
CACHE_FILE="$CACHE_DIR/exercise_texts.sha256"
EXERCISE_FILE="Models/Exercise.swift"
MAX_PARALLEL=10

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Default options
FORCE_REGENERATE=false
CHECK_ONLY=false
PARALLEL=true
VERBOSE=false

# Usage function
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Generate audio files for exercise instructions using OpenAI TTS API.
Automatically extracts exercise data from Swift source files.

OPTIONS:
    -f, --force         Force regenerate all audio files (ignore cache)
    -c, --check         Check only - show what would be generated
    -s, --sequential    Generate files sequentially (default: parallel)
    -v, --verbose       Verbose output
    -h, --help          Show this help message

ENVIRONMENT:
    OPENAI_API_KEY      Required. Your OpenAI API key.

EXAMPLES:
    $0                  Generate/update audio files as needed
    $0 --force          Regenerate all audio files
    $0 --check          See which files need updating
    $0 --sequential     Generate one file at a time

EOF
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--force)
            FORCE_REGENERATE=true
            shift
            ;;
        -c|--check)
            CHECK_ONLY=true
            shift
            ;;
        -s|--sequential)
            PARALLEL=false
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Check for API key
if [ -z "$OPENAI_API_KEY" ] && [ "$CHECK_ONLY" = false ]; then
    echo -e "${RED}✗${NC} Error: OPENAI_API_KEY environment variable not set"
    echo "   Please set your OpenAI API key:"
    echo "   export OPENAI_API_KEY='your-key-here'"
    exit 1
fi

# Create directories
mkdir -p "$CACHE_DIR"
mkdir -p "$ASSETS_DIR"

# Temp file for extracted exercises
TEMP_EXERCISES="/tmp/exercises_$$.txt"
trap "rm -f $TEMP_EXERCISES" EXIT

# Function to extract exercises from Swift source
extract_exercises() {
    if [ ! -f "$EXERCISE_FILE" ]; then
        echo -e "${RED}✗${NC} Error: $EXERCISE_FILE not found"
        exit 1
    fi
    
    [ "$VERBOSE" = true ] && echo "📖 Extracting exercises from $EXERCISE_FILE..."
    
    # Parse Swift file and output to temp file
    # Format: key|name|category|instruction1|instruction2|...
    # Using simpler AWK for macOS compatibility
    awk '
    BEGIN { count = 0 }
    /static let .* = Exercise\(/ {
        in_exercise = 1
        key = ""
        name = ""
        category = ""
        instructions = ""
        inst_count = 0
        
        # Extract variable name
        split($0, parts, "static let ")
        if (parts[2]) {
            split(parts[2], var_parts, " ")
            key = var_parts[1]
            # Convert camelCase to snake_case
            gsub(/[A-Z]/, "_&", key)
            key = tolower(key)
            gsub(/^_/, "", key)
        }
    }
    
    in_exercise && /name:/ {
        # Extract name value
        split($0, parts, "\"")
        if (parts[2]) name = parts[2]
    }
    
    in_exercise && /category:/ {
        # Extract category value
        gsub(/.*category: *\./, "")
        gsub(/,.*/, "")
        category = $0
    }
    
    in_exercise && /instructions: *\[/ {
        in_instructions = 1
    }
    
    in_instructions && /".*"/ {
        # Extract instruction text
        split($0, parts, "\"")
        if (parts[2]) {
            if (inst_count > 0) instructions = instructions "|"
            instructions = instructions parts[2]
            inst_count++
        }
    }
    
    in_instructions && /\]/ {
        in_instructions = 0
    }
    
    in_exercise && /\),?$/ {
        in_exercise = 0
        if (key && name && instructions) {
            # Generate a benefit string based on category
            benefit = "Helps improve posture and reduce tension"
            if (category == "strengthen") benefit = "Strengthens muscles and improves posture"
            if (category == "stretch") benefit = "Releases tension and improves flexibility"
            if (category == "mobilize") benefit = "Improves mobility and reduces stiffness"
            if (category == "relaxation") benefit = "Reduces stress and promotes relaxation"
            
            print key "|" name "|" benefit "|" instructions
            count++
        }
    }
    
    END {
        print "TOTAL:" count > "/dev/stderr"
    }
    ' "$EXERCISE_FILE" > "$TEMP_EXERCISES" 2>/dev/null
    
    local count=$(grep -c '^[a-z]' "$TEMP_EXERCISES" || echo 0)
    echo -e "${GREEN}✓${NC} Extracted $count exercises"
}

# Function to calculate hash
calculate_hash() {
    echo -n "$1" | shasum -a 256 | cut -d' ' -f1
}

# Function to check if exercise needs update
needs_update() {
    local key="$1"
    local hash="$2"
    
    # Force regenerate flag
    if [ "$FORCE_REGENERATE" = true ]; then
        return 0
    fi
    
    # Check if audio files exist
    if [ ! -f "$ASSETS_DIR/$key/intro.mp3" ]; then
        return 0
    fi
    
    # Check cached hash
    if [ -f "$CACHE_FILE" ]; then
        local cached_hash=$(grep "^$key:" "$CACHE_FILE" 2>/dev/null | cut -d':' -f2)
        if [ "$cached_hash" = "$hash" ]; then
            return 1  # No update needed
        fi
    fi
    
    return 0  # Needs update
}

# Function to save hash
save_hash() {
    local key="$1"
    local hash="$2"
    
    mkdir -p "$CACHE_DIR"
    
    # Remove old hash if exists
    if [ -f "$CACHE_FILE" ]; then
        grep -v "^$key:" "$CACHE_FILE" > "$CACHE_FILE.tmp" 2>/dev/null || true
        mv "$CACHE_FILE.tmp" "$CACHE_FILE"
    fi
    
    echo "$key:$hash" >> "$CACHE_FILE"
}

# Function to generate audio (sequential)
generate_audio() {
    local text="$1"
    local output_file="$2"
    
    if [ "$CHECK_ONLY" = true ]; then
        echo "   Would generate: $(basename $output_file)"
        return 0
    fi
    
    curl -s https://api.openai.com/v1/audio/speech \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"model\": \"$MODEL\", \"input\": \"$text\", \"voice\": \"$VOICE\"}" \
        --output "$output_file" 2>/dev/null
    
    if [ $? -eq 0 ] && [ -f "$output_file" ]; then
        [ "$VERBOSE" = true ] && echo -e "   ${GREEN}✓${NC} $(basename $output_file)"
        return 0
    else
        echo -e "   ${RED}✗${NC} Failed: $(basename $output_file)"
        return 1
    fi
}

# Function to generate audio (parallel)
generate_audio_bg() {
    local text="$1"
    local output_file="$2"
    local job_id="$3"
    
    if [ "$CHECK_ONLY" = true ]; then
        echo "   Would generate: $job_id"
        return 0
    fi
    
    {
        curl -s https://api.openai.com/v1/audio/speech \
            -H "Authorization: Bearer $OPENAI_API_KEY" \
            -H "Content-Type: application/json" \
            -d "{\"model\": \"$MODEL\", \"input\": \"$text\", \"voice\": \"$VOICE\"}" \
            --output "$output_file" 2>/dev/null
        
        if [ $? -eq 0 ] && [ -f "$output_file" ]; then
            echo -e "${GREEN}✓${NC} $job_id"
        else
            echo -e "${RED}✗${NC} $job_id"
        fi
    } &
}

# Function to wait for parallel jobs
wait_for_jobs() {
    while [ $(jobs -r | wc -l) -ge $MAX_PARALLEL ]; do
        sleep 0.1
    done
}

# Main execution
echo "🎙️  Exercise Audio Generator"
echo ""

# Extract exercises from source
extract_exercises

# Process each exercise
UPDATED_COUNT=0
SKIPPED_COUNT=0

# Read exercises from temp file
while IFS='|' read -r key name benefits instructions; do
    # Skip empty lines
    [ -z "$key" ] && continue
    
    # Split instructions into array
    IFS='|' read -ra steps <<< "$instructions"
    
    # Calculate hash
    content="$name|$benefits|$instructions"
    hash=$(calculate_hash "$content")
    
    # Check if update needed
    if needs_update "$key" "$hash"; then
        echo "🔄 Processing: $name"
        ((UPDATED_COUNT++))
        
        if [ "$CHECK_ONLY" = false ]; then
            mkdir -p "$ASSETS_DIR/$key"
            
            if [ "$PARALLEL" = true ]; then
                # Parallel generation
                wait_for_jobs
                generate_audio_bg "Starting $name. $benefits" "$ASSETS_DIR/$key/intro.mp3" "$key/intro"
                
                step_num=1
                for step in "${steps[@]}"; do
                    wait_for_jobs
                    generate_audio_bg "Step $step_num: $step" "$ASSETS_DIR/$key/step_$step_num.mp3" "$key/step_$step_num"
                    ((step_num++))
                done
                
                wait_for_jobs
                generate_audio_bg "Great job! Exercise complete." "$ASSETS_DIR/$key/complete.mp3" "$key/complete"
            else
                # Sequential generation
                generate_audio "Starting $name. $benefits" "$ASSETS_DIR/$key/intro.mp3"
                
                step_num=1
                for step in "${steps[@]}"; do
                    generate_audio "Step $step_num: $step" "$ASSETS_DIR/$key/step_$step_num.mp3"
                    ((step_num++))
                done
                
                generate_audio "Great job! Exercise complete." "$ASSETS_DIR/$key/complete.mp3"
            fi
            
            # Save hash after successful generation
            save_hash "$key" "$hash"
        fi
    else
        [ "$VERBOSE" = true ] && echo "✓ Up to date: $name"
        ((SKIPPED_COUNT++))
    fi
done < "$TEMP_EXERCISES"

# Wait for all parallel jobs to complete
if [ "$PARALLEL" = true ] && [ "$CHECK_ONLY" = false ]; then
    echo ""
    echo "⏳ Waiting for background jobs to complete..."
    wait
fi

# Summary
echo ""
echo "✅ Complete!"
echo "   Updated: $UPDATED_COUNT exercises"
echo "   Skipped: $SKIPPED_COUNT exercises (already up to date)"

if [ "$CHECK_ONLY" = false ] && [ "$UPDATED_COUNT" -gt 0 ]; then
    TOTAL_FILES=$(find "$ASSETS_DIR" -name "*.mp3" 2>/dev/null | wc -l | tr -d ' ')
    echo "   Total audio files: $TOTAL_FILES"
    echo "   Location: $ASSETS_DIR"
fi