#!/bin/bash

# Generate audio files for exercise instructions using OpenAI TTS API
# Uses curl to make direct HTTP requests - no Python required

set -e

# Check for API key
if [ -z "$OPENAI_API_KEY" ]; then
    echo "❌ Error: OPENAI_API_KEY environment variable not set"
    echo "   Please set your OpenAI API key:"
    echo "   export OPENAI_API_KEY='your-key-here'"
    exit 1
fi

# Configuration
VOICE="nova"
MODEL="tts-1-hd"
ASSETS_DIR="Assets/Audio/Exercises"

# Create assets directory
mkdir -p "$ASSETS_DIR"

echo "🎙️  Generating exercise audio files using OpenAI TTS..."
echo "   Voice: $VOICE"
echo "   Model: $MODEL"
echo "   Output directory: $ASSETS_DIR"
echo ""

# Function to generate audio file
generate_audio() {
    local text="$1"
    local output_file="$2"
    local instructions="${3:-}"
    
    # Create JSON payload
    local json_payload=$(cat <<EOF
{
    "model": "$MODEL",
    "input": "$text",
    "voice": "$VOICE"
}
EOF
    )
    
    # Make API call and save audio
    curl -s https://api.openai.com/v1/audio/speech \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$json_payload" \
        --output "$output_file"
    
    if [ $? -eq 0 ] && [ -f "$output_file" ]; then
        echo "   ✓ Generated: $(basename $output_file)"
        return 0
    else
        echo "   ✗ Failed: $(basename $output_file)"
        return 1
    fi
}

# Let's start with just a few exercises as a test
echo "📝 Processing Chin Tuck..."
mkdir -p "$ASSETS_DIR/chin_tuck"

generate_audio \
    "Starting Chin Tuck. Strengthens neck muscles and improves posture" \
    "$ASSETS_DIR/chin_tuck/intro.mp3"

generate_audio \
    "Step 1: Keep your shoulders back and spine straight" \
    "$ASSETS_DIR/chin_tuck/step_1.mp3"

generate_audio \
    "Step 2: Without tilting your head, gently draw your chin backward" \
    "$ASSETS_DIR/chin_tuck/step_2.mp3"

generate_audio \
    "Step 3: Hold for 5 seconds, feeling a gentle stretch at the base of your skull" \
    "$ASSETS_DIR/chin_tuck/step_3.mp3"

generate_audio \
    "Step 4: Slowly release back to neutral position" \
    "$ASSETS_DIR/chin_tuck/step_4.mp3"

generate_audio \
    "Step 5: Repeat 3 to 5 times" \
    "$ASSETS_DIR/chin_tuck/step_5.mp3"

generate_audio \
    "Great job! Exercise complete." \
    "$ASSETS_DIR/chin_tuck/complete.mp3"

echo ""
echo "📝 Processing Quick Shoulder Reset..."
mkdir -p "$ASSETS_DIR/shoulder_reset"

generate_audio \
    "Starting Quick Shoulder Reset. Instant shoulder alignment fix" \
    "$ASSETS_DIR/shoulder_reset/intro.mp3"

generate_audio \
    "Step 1: Squeeze shoulder blades together" \
    "$ASSETS_DIR/shoulder_reset/step_1.mp3"

generate_audio \
    "Step 2: Hold for 5 seconds" \
    "$ASSETS_DIR/shoulder_reset/step_2.mp3"

generate_audio \
    "Step 3: Release" \
    "$ASSETS_DIR/shoulder_reset/step_3.mp3"

generate_audio \
    "Step 4: Repeat 3 times" \
    "$ASSETS_DIR/shoulder_reset/step_4.mp3"

generate_audio \
    "Great job! Exercise complete." \
    "$ASSETS_DIR/shoulder_reset/complete.mp3"

echo ""
echo "📝 Processing Deep Breathing..."
mkdir -p "$ASSETS_DIR/deep_breathing"

generate_audio \
    "Starting Deep Breathing. Reduces stress and improves focus" \
    "$ASSETS_DIR/deep_breathing/intro.mp3"

generate_audio \
    "Step 1: Sit comfortably with spine straight" \
    "$ASSETS_DIR/deep_breathing/step_1.mp3"

generate_audio \
    "Step 2: Breathe in slowly through nose for 4 counts" \
    "$ASSETS_DIR/deep_breathing/step_2.mp3"

generate_audio \
    "Step 3: Hold breath for 4 counts" \
    "$ASSETS_DIR/deep_breathing/step_3.mp3"

generate_audio \
    "Step 4: Exhale slowly through mouth for 6 counts" \
    "$ASSETS_DIR/deep_breathing/step_4.mp3"

generate_audio \
    "Step 5: Repeat 5 to 10 times" \
    "$ASSETS_DIR/deep_breathing/step_5.mp3"

generate_audio \
    "Excellent! You've completed the breathing exercise." \
    "$ASSETS_DIR/deep_breathing/complete.mp3"

echo ""
echo "✅ Audio generation complete!"
echo "   Generated files in: $ASSETS_DIR"
echo ""
echo "🎵 Playing sample audio file..."
echo ""

# Play a sample audio file
SAMPLE_FILE="$ASSETS_DIR/chin_tuck/intro.mp3"
if [ -f "$SAMPLE_FILE" ]; then
    echo "Playing: $SAMPLE_FILE"
    afplay "$SAMPLE_FILE"
else
    echo "Sample file not found: $SAMPLE_FILE"
fi