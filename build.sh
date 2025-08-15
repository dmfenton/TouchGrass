#!/bin/bash

# Generic build script that uses Local.xcconfig for signing
# Make sure Local.xcconfig exists with your DEVELOPMENT_TEAM

if [ ! -f "Local.xcconfig" ]; then
    echo "❌ Local.xcconfig not found!"
    echo "Create Local.xcconfig with your DEVELOPMENT_TEAM ID"
    echo "See CLAUDE.md for instructions"
    exit 1
fi

echo "Building Touch Grass..."

xcodebuild -project TouchGrass.xcodeproj \
    -scheme TouchGrass \
    -configuration Release \
    -xcconfig Local.xcconfig \
    build \
    SYMROOT=build \
    CODE_SIGN_ENTITLEMENTS=TouchGrass.entitlements \
    -quiet

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    
    # Copy audio files into app bundle with flattened names
    APP_RESOURCES="build/Release/Touch Grass.app/Contents/Resources"
    if [ -d "Assets/Audio/Exercises" ]; then
        echo "📦 Copying audio files into app bundle..."
        AUDIO_COUNT=0
        # Copy each audio file with a flattened name
        for exercise_dir in Assets/Audio/Exercises/*/; do
            if [ -d "$exercise_dir" ]; then
                exercise_name=$(basename "$exercise_dir")
                for audio_file in "$exercise_dir"*.mp3; do
                    if [ -f "$audio_file" ]; then
                        base_name=$(basename "$audio_file" .mp3)
                        # Create flattened name: exercise_audiofile.mp3
                        flat_name="${exercise_name}_${base_name}.mp3"
                        cp "$audio_file" "$APP_RESOURCES/$flat_name"
                        ((AUDIO_COUNT++))
                    fi
                done
            fi
        done
        echo "✅ Copied $AUDIO_COUNT audio files"
    else
        echo "⚠️  No audio files found to copy"
    fi
    
    # Kill existing app if running
    killall "Touch Grass" 2>/dev/null || true
    
    # Open the newly built app
    open "build/Release/Touch Grass.app"
    echo "🌱 Touch Grass launched!"
else
    echo "❌ Build failed"
    exit 1
fi