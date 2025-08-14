# Touch Grass iOS - Mobile Experiment

This is an experimental iOS version of Touch Grass that reuses as much code as possible from the macOS app.

## Architecture

### Code Sharing Strategy

1. **Shared/** - Common code between macOS and iOS
   - `Models/Exercise.swift` - Exercise data structures
   - `Managers/CoreReminderManager.swift` - Core reminder logic

2. **iOS/** - iOS-specific implementations
   - `TouchGrassAppIOS.swift` - iOS app entry point
   - `Views/` - iOS-specific SwiftUI views

### Key Features Ported

✅ **Core Functionality**
- Timer-based reminders with countdown
- Pause/resume functionality
- Snooze reminders
- Water tracking with daily goals
- Streak tracking

✅ **Exercise Library**
- All exercise routines from macOS
- Interactive exercise player with timer
- Progress tracking

✅ **iOS-Specific Features**
- Local notifications when app is in background
- Tab-based navigation
- Touch-optimized UI
- Native iOS design patterns

### How It Works

1. **CoreReminderManager** provides shared business logic
2. **iOSReminderManager** extends it with iOS-specific features:
   - Local notifications
   - Background scheduling
   - Badge updates

3. **Reused Data**:
   - Exercise routines (ExerciseData)
   - Water tracking logic
   - Streak calculations
   - Settings persistence

### Building the iOS App

To build this experimental iOS version:

1. Open Xcode
2. Add a new iOS target to the project
3. Include the Shared and iOS folders
4. Set deployment target to iOS 15.0+
5. Configure bundle identifier and signing

### UI Components

- **Home Tab**: Main timer, quick actions, daily progress
- **Exercises Tab**: Full exercise library with guided routines
- **Water Tab**: Hydration tracking with visual progress
- **Stats Tab**: Streaks, achievements, weekly overview
- **Settings Tab**: Customization options

### What's Different from macOS

- No menu bar (uses tab navigation instead)
- Local notifications instead of popup windows
- Touch-optimized interface
- Background notification scheduling
- Mobile-first layouts

### Future Enhancements

- [ ] Apple Watch companion app
- [ ] HealthKit integration
- [ ] Widgets for home screen
- [ ] Siri shortcuts
- [ ] iCloud sync between devices
- [ ] Calendar integration (EventKit)

## Note

This is a proof-of-concept showing how the Touch Grass codebase can be adapted for iOS with significant code reuse. The core logic remains the same while the UI adapts to mobile patterns.