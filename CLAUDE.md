# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build for release
xcodebuild -project TouchGrass.xcodeproj -scheme TouchGrass -configuration Release build SYMROOT=build -quiet

# Build and run the app
xcodebuild -project TouchGrass.xcodeproj -scheme TouchGrass -configuration Release build SYMROOT=build -quiet && open build/Release/TouchGrass.app

# Clean build
xcodebuild -project TouchGrass.xcodeproj -scheme TouchGrass -configuration Release clean build SYMROOT=build

# Restart app after changes
killall TouchGrass 2>/dev/null || true && open build/Release/TouchGrass.app
```

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