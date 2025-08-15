#!/bin/bash

# Generate ALL audio files for exercise instructions using OpenAI TTS API
# Creates a complete audio library with manifest

set -e

# Check for API key
if [ -z "$OPENAI_API_KEY" ]; then
    echo "❌ Error: OPENAI_API_KEY environment variable not set"
    exit 1
fi

# Configuration
VOICE="nova"
MODEL="tts-1-hd"
ASSETS_DIR="Assets/Audio/Exercises"

# Create assets directory
mkdir -p "$ASSETS_DIR"

echo "🎙️  Generating ALL exercise audio files..."
echo ""

# Function to generate audio file
generate_audio() {
    local text="$1"
    local output_file="$2"
    
    curl -s https://api.openai.com/v1/audio/speech \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"model\": \"$MODEL\", \"input\": \"$text\", \"voice\": \"$VOICE\"}" \
        --output "$output_file"
    
    if [ $? -eq 0 ] && [ -f "$output_file" ]; then
        echo "   ✓ $(basename $output_file)"
        return 0
    else
        echo "   ✗ Failed: $(basename $output_file)"
        return 1
    fi
}

# Generate audio for an exercise
generate_exercise() {
    local key="$1"
    local name="$2"
    local benefits="$3"
    shift 3
    local instructions=("$@")
    
    echo "📝 $name"
    mkdir -p "$ASSETS_DIR/$key"
    
    # Intro
    generate_audio "Starting $name. $benefits" "$ASSETS_DIR/$key/intro.mp3"
    
    # Instructions
    local step=1
    for instruction in "${instructions[@]}"; do
        generate_audio "Step $step: $instruction" "$ASSETS_DIR/$key/step_$step.mp3"
        ((step++))
    done
    
    # Complete
    generate_audio "Great job! Exercise complete." "$ASSETS_DIR/$key/complete.mp3"
    echo ""
}

# Generate all exercises
generate_exercise "chin_tuck" "Chin Tuck" "Strengthens neck muscles and improves posture" \
    "Keep your shoulders back and spine straight" \
    "Without tilting your head, gently draw your chin backward" \
    "Hold for 5 seconds, feeling a gentle stretch at the base of your skull" \
    "Slowly release back to neutral position" \
    "Repeat 3 to 5 times"

generate_exercise "chin_tuck_quick" "Quick Chin Tuck" "Quick posture reset for your neck" \
    "Pull chin straight back, not down" \
    "Hold for 5 seconds" \
    "Release slowly" \
    "Repeat 3 times"

generate_exercise "shoulder_squeeze" "Shoulder Blade Squeeze" "Counteracts rounded shoulders from computer work" \
    "Sit or stand with spine straight" \
    "Pull your shoulder blades back and together" \
    "Imagine trying to hold a pencil between your shoulder blades" \
    "Hold for 5 seconds" \
    "Release slowly" \
    "Repeat 5 to 10 times"

generate_exercise "shoulder_reset" "Quick Shoulder Reset" "Instant shoulder alignment fix" \
    "Squeeze shoulder blades together" \
    "Hold for 5 seconds" \
    "Release" \
    "Repeat 3 times"

generate_exercise "doorway_stretch" "Doorway Chest Stretch" "Opens chest and counteracts forward shoulder position" \
    "Stand in a doorway with arms at 90 degrees" \
    "Place forearms on door frame" \
    "Step forward slowly until you feel a stretch across your chest" \
    "Hold for 30 seconds" \
    "Step back and relax" \
    "Repeat 2 to 3 times"

generate_exercise "upper_trap" "Upper Trap Stretch" "Relieves tension in neck and shoulders" \
    "Sit or stand with good posture" \
    "Tilt your head to one side, bringing ear toward shoulder" \
    "Place hand on opposite side of head for gentle pressure" \
    "Hold for 30 seconds" \
    "Slowly return to center" \
    "Repeat on other side"

generate_exercise "neck_rolls" "Gentle Neck Rolls" "Improves neck mobility and reduces stiffness" \
    "Start with your head centered and shoulders relaxed" \
    "Slowly lower chin to chest" \
    "Gently roll head to the right" \
    "Continue rolling back, look at ceiling" \
    "Roll to the left side" \
    "Return to starting position" \
    "Repeat 2 to 3 times, then reverse direction"

generate_exercise "shoulder_rolls" "Shoulder Rolls" "Releases shoulder tension and improves circulation" \
    "Sit or stand with arms relaxed at your sides" \
    "Lift shoulders up toward your ears" \
    "Roll shoulders back in a circular motion" \
    "Lower shoulders down" \
    "Complete 5 rolls backward" \
    "Reverse and do 5 rolls forward"

generate_exercise "thoracic_extension" "Thoracic Extension" "Improves upper back mobility and reduces hunching" \
    "Sit tall in your chair with feet flat on floor" \
    "Place hands behind your head, elbows wide" \
    "Gently arch your upper back over the chair" \
    "Look slightly upward as you extend" \
    "Hold for 5 seconds" \
    "Return to neutral" \
    "Repeat 5 times"

generate_exercise "hip_flexor" "Standing Hip Flexor Stretch" "Loosens tight hip flexors from prolonged sitting" \
    "Stand with one foot forward in a lunge position" \
    "Keep back leg straight, front knee bent at 90 degrees" \
    "Push hips forward gently" \
    "Hold for 30 seconds" \
    "Switch legs and repeat"

generate_exercise "glute_stretch" "Seated Glute Stretch" "Relieves hip and glute tension" \
    "Sit tall in your chair" \
    "Cross right ankle over left knee" \
    "Gently press down on right knee" \
    "Lean forward slightly for deeper stretch" \
    "Hold for 30 seconds" \
    "Switch sides and repeat"

generate_exercise "calf_stretch" "Calf Stretch" "Stretches calf muscles" \
    "Stand facing a wall, hands against wall" \
    "Step right foot back, keeping heel on ground" \
    "Keep back leg straight" \
    "Lean forward until you feel calf stretch" \
    "Hold for 30 seconds" \
    "Switch legs"

generate_exercise "ankle_circles" "Ankle Circles" "Full range ankle mobility" \
    "Sit with one leg extended" \
    "Make slow circles with your foot" \
    "Complete 10 circles clockwise" \
    "Complete 10 circles counter-clockwise" \
    "Switch feet and repeat"

generate_exercise "eye_20_20_20" "20-20-20 Rule" "Reduces eye strain from screen time" \
    "Look away from your screen" \
    "Focus on something 20 feet away" \
    "Hold your gaze for 20 seconds" \
    "Blink several times to refresh"

generate_exercise "palming" "Eye Palming" "Relaxes eye muscles and reduces strain" \
    "Rub palms together to warm them" \
    "Cup palms over closed eyes" \
    "Don't press on eyeballs" \
    "Breathe deeply and relax" \
    "Hold for 30 seconds"

generate_exercise "deep_breathing" "Deep Breathing" "Reduces stress and improves focus" \
    "Sit comfortably with spine straight" \
    "Breathe in slowly through nose for 4 counts" \
    "Hold breath for 4 counts" \
    "Exhale slowly through mouth for 6 counts" \
    "Repeat 5 to 10 times"

# Create manifest JSON
echo "📄 Creating manifest file..."
cat > "$ASSETS_DIR/manifest.json" <<EOF
{
  "version": "1.0",
  "voice": "$VOICE",
  "model": "$MODEL",
  "exercises": [
    "chin_tuck", "chin_tuck_quick", "shoulder_squeeze", "shoulder_reset",
    "doorway_stretch", "upper_trap", "neck_rolls", "shoulder_rolls",
    "thoracic_extension", "hip_flexor", "glute_stretch", "calf_stretch",
    "ankle_circles", "eye_20_20_20", "palming", "deep_breathing"
  ]
}
EOF

echo "✅ Complete! Generated audio for all exercises"
echo "   Location: $ASSETS_DIR"
echo "   Total exercises: 16"