# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Setup & Commands

### Code Signing Configuration

For proper code signing and persistent calendar permissions during development, create a `Local.xcconfig` file:

```xcconfig
// Local.xcconfig (this file is gitignored)
DEVELOPMENT_TEAM = YOUR_TEAM_ID_HERE
PRODUCT_BUNDLE_IDENTIFIER = com.yourname.touchgrass
CODE_SIGN_STYLE = Automatic
CODE_SIGN_IDENTITY = Apple Development
```

To find your Team ID:
- Xcode → Settings → Accounts → Select your Apple ID → View Details
- Or: developer.apple.com → Account → Membership → Team ID

### Build Commands

```bash
# Build with proper code signing (recommended - uses Local.xcconfig)
./build.sh

# Manual build with signing
xcodebuild -project TouchGrass.xcodeproj -scheme TouchGrass -configuration Release -xcconfig Local.xcconfig build SYMROOT=build -quiet

# Build without signing (calendar permissions will reset each build)
xcodebuild -project TouchGrass.xcodeproj -scheme TouchGrass -configuration Release build SYMROOT=build -quiet

# Clean build
xcodebuild -project TouchGrass.xcodeproj -scheme TouchGrass -configuration Release clean build SYMROOT=build

# Restart app after changes
killall "Touch Grass" 2>/dev/null || true && open "build/Release/Touch Grass.app"
```

Note: With proper code signing via `Local.xcconfig`, calendar permissions will persist across rebuilds.

## Architecture Overview

Touch Grass is a SwiftUI-based macOS menu bar application with a clear separation of concerns:

### Core Flow
1. **TouchGrassApp.swift** - Entry point, creates MenuBarExtra with ReminderManager instance
2. **ReminderManager.swift** - Central state management using Combine, handles:
   - Fixed-interval scheduling aligned to clock time (e.g., :00, :45)
   - Timer management with separate timers for scheduling and countdown display
   - Pause/resume/snooze logic
   - Window presentation coordination
3. **ReminderWindowController.swift** - NSPanel management for the reminder popup:
   - Creates borderless floating window
   - Handles window lifecycle and animations
   - Centers window on screen for visibility
4. **ReminderWindow.swift** - SwiftUI view for reminder content, minimal design with system colors

### Key Design Decisions

**Fixed Interval Scheduling**: Reminders align to clock time rather than relative to app start. The `scheduleAtFixedInterval()` method calculates the next reminder based on minutes since the hour, ensuring predictable timing (e.g., if interval is 45 minutes, reminders happen at :00, :45).

**Window Presentation**: Uses NSPanel with `.floating` level and `borderless` style mask for a clean, non-intrusive appearance. The window is created fresh for each reminder to avoid state issues.

**State Management**: ReminderManager is the single source of truth, using @Published properties for UI updates. The countdown timer updates every second independently of the main scheduling timer.

## UI/UX Principles

- Keep the design minimal and professional - avoid bright colors, gradients, or animations
- Use system colors (NSColor.windowBackgroundColor, NSColor.controlBackgroundColor) for native appearance
- Menu bar shows live countdown in MM:SS format as the primary element
- Reminder window uses subtle borders and system fonts

## Testing Reminders

To test reminder functionality without waiting:
1. Click "Check Posture Now" in menu bar
2. Or temporarily set `intervalMinutes` to 1 in ReminderManager initialization
3. Use Console.app to check for any runtime warnings

## Release Process

Touch Grass uses semantic versioning (MAJOR.MINOR.PATCH) and an automated release process.

### Creating a Release

The entire release process is automated through a single command:

```bash
# With release notes as argument
./release.sh 0.3.0 "- Added awesome new feature
- Fixed critical bug
- Improved performance"

# Or interactive (will prompt for release notes)
./release.sh 0.3.0
```

The release script automatically:
1. Updates version in Info.plist and VERSION file
2. Builds the app with code signing (if configured)
3. Creates a DMG installer
4. Generates SHA256 checksums
5. Creates release notes (with your input)
6. Commits version changes
7. Creates and pushes git tag
8. Pushes to GitHub
9. Creates GitHub release
10. Uploads the DMG to the release

### Requirements

- `create-dmg` installed via Homebrew: `brew install create-dmg`
- GitHub CLI authenticated: `gh auth login`
- Write access to the repository

### Version Guidelines

- **PATCH** (0.0.X): Bug fixes, minor tweaks
- **MINOR** (0.X.0): New features, backwards compatible
- **MAJOR** (X.0.0): Breaking changes, major redesigns