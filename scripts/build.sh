#!/bin/bash

# Generic build script that uses Local.xcconfig for signing
# Make sure Local.xcconfig exists with your DEVELOPMENT_TEAM

if [ ! -f "Local.xcconfig" ]; then
    echo "❌ Local.xcconfig not found!"
    echo "Create Local.xcconfig with your DEVELOPMENT_TEAM ID"
    echo "See CLAUDE.md for instructions"
    exit 1
fi

set -euo pipefail
SIGNING_IDENTITY="Developer ID Application: Daniel Myer Fenton (PG5D259899)"
security find-identity -v -p codesigning | grep -F "$SIGNING_IDENTITY" >/dev/null
echo "Building Touch Grass..."

xcodebuild -project TouchGrass.xcodeproj \
    -target TouchGrass \
    -configuration Release \
    -xcconfig Local.xcconfig \
    build \
    SYMROOT=build \
    CODE_SIGN_ENTITLEMENTS=TouchGrass.entitlements \
    CODE_SIGN_IDENTITY="$SIGNING_IDENTITY" \
    -allowProvisioningUpdates \
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
                        AUDIO_COUNT=$((AUDIO_COUNT + 1))
                    fi
                done
            fi
        done
        echo "✅ Copied $AUDIO_COUNT audio files"
    else
        echo "⚠️  No audio files found to copy"
    fi
    
    codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" \
        --entitlements TouchGrass.entitlements "build/Release/Touch Grass.app"
    python3 scripts/verify_native_signature.py "build/Release/Touch Grass.app" --platform macos

    # Kill existing app if running
    killall "Touch Grass" 2>/dev/null || true
    
    # Wait a moment for the app to fully quit
    sleep 1
    
    # Open the newly built app
    open "build/Release/Touch Grass.app"
    echo "🌱 Touch Grass launched!"
else
    echo "❌ Build failed"
    exit 1
fi