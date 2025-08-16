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

### Development Commands

**We use Make for all common tasks.** The Makefile wraps our shell scripts and provides a consistent interface:

```bash
# Essential Commands
make            # Show all available commands
make setup      # Set up development environment
make build      # Build the app
make run        # Build and run the app
make lint       # Check code style
make test       # Run tests
make release VERSION=1.2.0  # Create a release

# Development Workflow
make check      # Pre-commit checks (lint + build + test)
make all        # Run full validation suite
make clean      # Clean build artifacts
make rebuild    # Clean, build, and run

# Code Quality
make lint       # Run SwiftLint checks
make lint-fix   # Auto-fix SwiftLint violations

# Project Maintenance
make xcode-add  # Instructions for adding files to Xcode
make audio      # Generate exercise audio files
make version    # Show current app version
```

### Shell Scripts

All scripts are organized in the `scripts/` directory:

```bash
# Build and Development
scripts/build.sh              # Build with code signing
scripts/lint.sh               # Run SwiftLint with nice output
scripts/lint.sh --fix         # Auto-fix violations

# Release Management
scripts/release.sh 1.2.0      # Create and publish release

# Audio Generation
scripts/generate_exercise_audio.sh  # Generate TTS audio for exercises
scripts/generate_all_audio.sh       # Generate all audio files

# Xcode Project Management
scripts/add_to_xcode.sh Views/NewView.swift  # Add files to Xcode project
```

**Note:** Always use `make` commands when available, as they provide better error handling and consistent output.

### Manual Build Commands (if needed)

```bash
# Build with proper code signing (recommended - uses Local.xcconfig)
xcodebuild -project TouchGrass.xcodeproj -scheme TouchGrass -configuration Release -xcconfig Local.xcconfig build SYMROOT=build -quiet

# Build without signing (calendar permissions will reset each build)
xcodebuild -project TouchGrass.xcodeproj -scheme TouchGrass -configuration Release build SYMROOT=build -quiet

# Restart app after changes
killall "Touch Grass" 2>/dev/null || true && open "build/Release/Touch Grass.app"
```

Note: With proper code signing via `Local.xcconfig`, calendar permissions will persist across rebuilds.

## Architecture Overview

Touch Grass is a SwiftUI-based macOS menu bar application with a clear separation of concerns:

### Core Flow
1. **TouchGrassApp.swift** - Entry point, creates MenuBarExtra with dynamic content:
   - Shows TouchGrassMode when hasActiveReminder is true
   - Shows MenuView for normal menu operations
   - Handles onboarding flow on first launch
2. **ReminderManager.swift** - Central state management using Combine, handles:
   - Fixed-interval scheduling aligned to clock time (e.g., :00, :45)
   - Timer management with separate timers for scheduling and countdown display
   - Pause/resume/snooze logic with smart meeting detection
   - Water tracking with daily goals and streak management
   - Activity completion tracking and streak management
3. **CalendarManager.swift** - Calendar integration for smart scheduling:
   - Monitors current and upcoming events within work hours
   - Detects meeting transitions for smart reminder triggering
   - Provides meeting load analysis and suggestions
4. **WorkHoursManager.swift** - Manages work schedule configuration:
   - Configurable work start/end times and days
   - Ensures reminders only occur during work hours
5. **TouchGrassMode.swift** - Main reminder interface shown in menu bar:
   - Activity selection (Touch Grass, Posture Reset, Exercises, Meditation)
   - Calendar-aware suggestions based on available time
   - Water logging integration
   - Snooze and skip options

### Key Design Decisions

**Smart Menu Bar Integration**: Uses MenuBarExtra with conditional content - when a reminder is active, the entire menu transforms into the TouchGrassMode interface, providing immediate access to break options without opening separate windows.

**Calendar-Aware Scheduling**: Integrates with user calendars to:
- Detect when meetings end and trigger timely reminders
- Show meeting context in the menu and reminder interfaces
- Adapt suggestions based on available time before next meeting
- Provide meeting load analysis for better break planning

**Evidence-Based Exercise Library**: Includes structured exercise sets with different durations:
- 30-second quick resets (chin tucks, shoulder blade squeezes)
- 1-2 minute focused routines (stretches, eye exercises)
- 3-minute comprehensive routines combining multiple exercises
- Breathing and meditation exercises for stress relief

**Water Tracking Integration**: Built-in hydration tracking with:
- Configurable daily goals and units (glasses, ounces, milliliters)
- Quick logging buttons in both menu and reminder interfaces
- Daily and streak tracking with persistence across app restarts

**Fixed Interval Scheduling**: Reminders align to clock time rather than relative to app start. The `scheduleAtFixedInterval()` method calculates the next reminder based on minutes since the hour, ensuring predictable timing (e.g., if interval is 45 minutes, reminders happen at :00, :45).

**Work Hours Awareness**: Only shows reminders during configured work hours and work days, with automatic scheduling to resume at the next work period.

## Current Features

### Core Functionality
- **Break Reminders**: Configurable intervals (15-90 minutes) with fixed-time scheduling
- **Touch Grass Mode**: Primary reminder interface with activity selection
- **Exercise Routines**: Evidence-based posture exercises with guided instructions
- **Water Tracking**: Daily hydration goals with multiple unit options
- **Calendar Integration**: Smart scheduling based on meeting awareness
- **Work Hours**: Configurable work schedule with automatic pause outside hours
- **Onboarding**: First-run experience for setting up preferences

### Menu Bar Interface
- **Dynamic Content**: Menu transforms based on reminder state
- **Live Countdown**: Shows time until next reminder in MM:SS format
- **Meeting Context**: Displays current meeting status and next event
- **Quick Actions**: Touch Grass Now, water logging, pause/resume
- **Streak Display**: Shows current completion streak when active

### Settings & Customization
- **Break Frequency**: 15-90 minute intervals with fixed-time alignment
- **Work Hours**: Configurable start/end times and work days
- **Calendar Selection**: Choose which calendars to monitor
- **Water Goals**: Customizable daily targets and units
- **Smart Features**: Adaptive timing and meeting-aware scheduling
- **Startup Options**: Launch at login configuration

## UI/UX Principles

- **Minimal & Professional**: Clean design using system colors and native macOS styling
- **Context-Aware**: Shows relevant information based on calendar events and time available
- **Non-Intrusive**: Uses menu bar integration instead of popup windows
- **Quick Actions**: Most common actions accessible within 1-2 clicks
- **Visual Hierarchy**: Important information (countdown, active reminders) prominently displayed
- **Consistent Styling**: Uses rounded rectangles, subtle backgrounds, and system fonts throughout

## Testing Reminders

To test reminder functionality without waiting:
1. Click "Touch Grass Now" in menu bar to trigger the reminder interface
2. Temporarily set `intervalMinutes` to 1 in ReminderManager initialization for frequent testing
3. Use Console.app to monitor smart scheduling and meeting detection logs
4. Test calendar integration by creating test events within work hours

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
1. Checks for exercise text changes and regenerates audio if needed (requires OPENAI_API_KEY)
2. Updates version in Info.plist and VERSION file
3. Builds the app with code signing (if configured)
4. Creates a DMG installer
5. Generates SHA256 checksums
6. Creates release notes (with your input)
7. Commits version changes
8. Creates and pushes git tag
9. Pushes to GitHub
10. Creates GitHub release
11. Uploads the DMG to the release

### Requirements

- `create-dmg` installed via Homebrew: `brew install create-dmg`
- GitHub CLI authenticated: `gh auth login`
- Write access to the repository
- Optional: `OPENAI_API_KEY` environment variable for audio regeneration

### Version Guidelines

- **PATCH** (0.0.X): Bug fixes, minor tweaks
- **MINOR** (0.X.0): New features, backwards compatible
- **MAJOR** (X.0.0): Breaking changes, major redesigns

### Example Release Workflow

When ready to release after making changes:

```bash
# 1. Check what's changed since last release
git describe --tags --abbrev=0  # Get last tag (e.g., v0.8.0)
git log v0.8.0..HEAD --oneline  # View commits since last release

# 2. Determine version number based on changes
# For UI improvements and feature enhancements: MINOR bump
# For bug fixes only: PATCH bump
# For breaking changes: MAJOR bump

# 3. Create release with detailed notes
./release.sh 0.9.0 "$(cat <<'EOF'
Major UI improvements and exercise coaching enhancements

### UI Redesign
- Completely redesigned menu bar interface
- Added forest green header button
- Simplified water tracking to single +8oz button
- Added subtle section labels for organization

### Exercise Coaching Improvements  
- Added intelligent text-to-speech coaching
- Instructions read before timer starts
- Automatic progression through exercise sets
- Visual highlighting synchronized with speech

### Other Improvements
- Fixed UI jittering issues
- Better calendar status messages
- Improved visual hierarchy throughout
EOF
)"

# The script handles everything else automatically!
```

## Exercise Audio Generation

Touch Grass includes high-quality TTS audio for all exercise instructions using OpenAI's Text-to-Speech API.

### Audio Generation Script

The `generate_exercise_audio.sh` script automatically:
- Extracts exercise data from `Models/Exercise.swift`
- Generates audio files for intro, steps, and completion
- Uses parallel processing to avoid timeouts
- Implements smart caching to only regenerate changed content

### Usage

```bash
# Generate/update audio files as needed (uses cache)
./generate_exercise_audio.sh

# Force regenerate all audio files
./generate_exercise_audio.sh --force

# Check which files need updating without generating
./generate_exercise_audio.sh --check

# Generate with verbose output
./generate_exercise_audio.sh --verbose

# Generate sequentially instead of parallel
./generate_exercise_audio.sh --sequential
```

### Requirements

- `OPENAI_API_KEY` environment variable set
- macOS with bash 3.2+ (script is compatible with default macOS bash)

### Audio Organization

Audio files are stored in `Assets/Audio/Exercises/` with the following structure:
```
Assets/Audio/Exercises/
├── chin_tuck/
│   ├── intro.mp3      # "Starting Chin Tucks. Strengthens muscles..."
│   ├── step_1.mp3     # "Step 1: Sit or stand with spine tall..."
│   ├── step_2.mp3     # "Step 2: Keep your eyes looking..."
│   └── complete.mp3   # "Great job! Exercise complete."
├── deep_breathing/
│   └── ...
```

### Integration with Release Process

The release script automatically checks for exercise text changes and regenerates audio files if:
1. The `OPENAI_API_KEY` environment variable is set
2. Exercise instruction text has changed since last generation
3. The `update_exercise_audio.sh` script exists

Audio generation adds approximately 2-3 minutes to the release process when updates are needed.