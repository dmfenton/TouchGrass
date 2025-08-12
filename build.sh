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
    
    # Kill existing app if running
    killall "Touch Grass" 2>/dev/null || true
    
    # Open the newly built app
    open "build/Release/Touch Grass.app"
    echo "🌱 Touch Grass launched!"
else
    echo "❌ Build failed"
    exit 1
fi