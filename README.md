# Touch Grass

[![CI](https://github.com/dmfenton/touchgrass/actions/workflows/ci.yml/badge.svg)](https://github.com/dmfenton/touchgrass/actions/workflows/ci.yml)
[![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange)](https://swift.org)
[![License](https://img.shields.io/github/license/dmfenton/touchgrass)](LICENSE)

A smart macOS menu bar app that reminds you to take breaks, maintain good posture, stay hydrated, and literally touch grass. With calendar-aware scheduling and evidence-based exercises.

<img width="286" alt="Touch Grass Menu" src="https://github.com/user-attachments/assets/placeholder-menu.png">
<img width="380" alt="Touch Grass Reminder" src="https://github.com/user-attachments/assets/placeholder-reminder.png">

## Features

### Core Functionality
- 🌱 **Touch Grass Mode** - Transform your menu bar into a break reminder interface
- 📅 **Calendar Integration** - Smart scheduling that respects your meetings
- 💧 **Water Tracking** - Built-in hydration tracking with daily goals and streaks
- 🏃 **Evidence-Based Exercises** - Curated posture and wellness exercises with audio coaching
- ⏰ **Work Hours Aware** - Only reminds you during configured work hours
- 🔥 **Streak Tracking** - Motivation through completion streaks

### Smart Scheduling
- Fixed-interval reminders aligned to clock time (e.g., :00, :30, :45)
- Automatic meeting detection and smart reminder timing
- Adapts suggestions based on available time before next meeting
- Pause/resume/snooze with intelligent meeting awareness

### Exercise Library
- **Quick Resets** (30s): Chin tucks, shoulder blade squeezes
- **Focused Routines** (1-2min): Stretches, eye exercises, desk yoga
- **Comprehensive Sets** (3min): Full posture reset routines
- **Breathing & Meditation**: Stress relief and mindfulness exercises
- **Audio Coaching**: Professional TTS guidance for all exercises

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 14.0 or later (to build from source)

## Installation

### Option 1: Build from Source

1. Clone the repository:
```bash
git clone https://github.com/dmfenton/touchgrass.git
cd touchgrass
```

2. Open in Xcode:
```bash
open TouchGrass.xcodeproj
```

3. Build and run (⌘R)

### Option 2: Using Make (Recommended)

```bash
make setup   # Set up development environment
make build   # Build the app
make run     # Build and run
```

### Option 3: Command Line Build

```bash
xcodebuild -project TouchGrass.xcodeproj -scheme TouchGrass -configuration Release build SYMROOT=build
open build/Release/Touch\ Grass.app
```

### Option 4: Download Release

Download the latest DMG from the [Releases](https://github.com/dmfenton/touchgrass/releases) page.

## Usage

1. **Launch** - Touch Grass appears as a forest green icon in your menu bar
2. **First Run** - Complete onboarding to set up your preferences
3. **Check Timer** - Menu shows live countdown to next reminder
4. **Take Breaks** - When reminder appears:
   - 🌱 **Touch Grass** - Go outside for fresh air
   - 🏃 **Exercises** - Choose from posture, stretching, or breathing exercises
   - 💧 **Log Water** - Quick +8oz button to track hydration
   - ⏰ **Snooze** - Delay for 5, 10, or 20 minutes
5. **Track Progress** - View your completion streak and water intake

## Start at Login

To have TouchGrass start automatically:

1. Open **System Settings** → **General** → **Login Items**
2. Click **+** under "Open at Login"
3. Navigate to and select `TouchGrass.app`

## Settings & Customization

- **Break Frequency**: 15-90 minute intervals with fixed-time alignment
- **Work Hours**: Configure start/end times and work days
- **Calendar Selection**: Choose which calendars to monitor
- **Water Goals**: Set daily targets (glasses, ounces, or milliliters)
- **Smart Features**: Toggle meeting awareness and adaptive timing
- **Launch at Login**: Start automatically when you log in


## Development

### Quick Start

```bash
make            # Show all available commands
make setup      # Set up development environment
make build      # Build the app
make run        # Build and run
make test       # Run tests (21 integration tests)
make lint       # Check code style
make check      # Pre-commit checks (lint + build + test)
```

### Essential Commands

```bash
# Development Workflow
make setup      # Complete development setup
make build      # Build the app
make run        # Build and run the app
make clean      # Clean build artifacts
make rebuild    # Clean, build, and run

# Code Quality
make lint       # Run SwiftLint checks
make lint-fix   # Auto-fix SwiftLint violations
make test       # Run comprehensive test suite

# Xcode Project Management
make xcode-organize         # Organize files into proper Xcode groups
make xcode-add FILES='...'  # Add files to Xcode project in correct groups
make xcode-check           # Check current Xcode organization

# Release Management
make release VERSION=1.0.0  # Create and publish release
make audio      # Generate exercise audio files
make version    # Show current app version
```

### Architecture

```
Touch Grass/
├── Models/              # Data models and business logic
│   ├── ReminderManager.swift    # Core state management
│   ├── CalendarManager.swift    # Calendar integration
│   ├── WorkHoursManager.swift   # Work schedule logic
│   └── Exercise.swift           # Exercise definitions
├── Views/               # SwiftUI views
│   ├── MenuView.swift           # Main menu interface
│   ├── TouchGrassMode.swift     # Break reminder UI
│   ├── ExerciseView.swift       # Exercise interface
│   └── Settings/                # Settings views
├── TouchGrassTests/     # Integration test suite
│   ├── TestRunner.swift         # Standalone test runner
│   └── Integration/             # E2E test scenarios
└── scripts/             # Build and automation
    ├── build.sh                 # Build with code signing
    ├── test.sh                  # Run tests
    └── release.sh               # Create releases
```

### Testing

Touch Grass includes comprehensive integration tests covering:
- Complete user workflows (menu → exercise → completion)
- Calendar-aware scheduling
- Water tracking and streaks
- Work hours boundaries
- Timer accuracy and state management

Run tests without Xcode:
```bash
make test  # Runs 21 integration tests
```

## Privacy

TouchGrass is completely offline and private:
- No network connections
- No data collection
- No analytics
- All preferences stored locally

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

Quick tips:
- Run `make check` before committing
- Tests must pass (`make test`)
- Follow existing code patterns
- Keep UI native and clean

## License

MIT License - see LICENSE file for details

## Acknowledgments

Built to promote wellness in the digital age - one break at a time.

---

*Native macOS app built with Swift and SwiftUI*