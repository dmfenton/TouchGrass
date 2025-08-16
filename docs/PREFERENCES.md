# Touch Grass Preferences Documentation

This document provides a comprehensive overview of all preferences used by Touch Grass, organized by the new centralized PreferencesStore.

## Architecture Overview

Touch Grass uses two UserDefaults storage mechanisms:

1. **Shared Suite** (`com.touchgrass.shared`) - Persists across bundle ID changes and code signing variations
2. **Standard UserDefaults** - App-specific settings that don't need to persist across bundle changes

## Preference Categories

### Reminder Settings (Shared Suite)

These settings control the core reminder functionality and use the shared suite to persist across different builds.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `TouchGrass.intervalMinutes` | `Int` | `45` | Minutes between reminders (15-90) |
| `TouchGrass.adaptiveEnabled` | `Bool` | `true` | Enable adaptive timing based on calendar |
| `TouchGrass.smartSchedulingEnabled` | `Bool` | `true` | Enable meeting-aware scheduling |

### Work Hours Settings (Standard)

Work schedule configuration uses standard UserDefaults as these are app-specific settings.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `TouchGrass.workStartTime` | `Double?` | `nil` | Work start time (seconds from midnight) |
| `TouchGrass.workEndTime` | `Double?` | `nil` | Work end time (seconds from midnight) |
| `TouchGrass.workDays` | `Data?` | `nil` | JSON-encoded Set&lt;WorkDay&gt; |

**Default Work Days:** Monday, Tuesday, Wednesday, Thursday, Friday  
**Default Work Hours:** 9:00 AM - 5:00 PM

### App Settings (Standard)

General application settings stored in standard UserDefaults.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `TouchGrass.startsAtLogin` | `Bool` | `false` | Launch app automatically at login |
| `TouchGrass.hasCompletedOnboarding` | `Bool` | `false` | First-run onboarding completion flag |

### Calendar Settings (Shared Suite)

Calendar integration settings use shared suite to persist across builds.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `TouchGrass.selectedCalendars` | `Data?` | `nil` | JSON-encoded array of calendar identifiers |

### Water Tracking (Shared Suite)

Hydration tracking data uses shared suite to maintain continuity across builds.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `TouchGrass.waterEnabled` | `Bool` | `true` | Enable water tracking feature |
| `TouchGrass.waterGoal` | `Int` | `8` | Daily water intake goal |
| `TouchGrass.waterIntake` | `Int` | `0` | Current day water intake |
| `TouchGrass.waterUnit` | `String` | `"glasses"` | Unit for water measurement |
| `TouchGrass.waterStreak` | `Int` | `0` | Consecutive days meeting goal |
| `TouchGrass.lastWaterDate` | `String?` | `nil` | Last date water was logged (ISO 8601) |
| `TouchGrass.yesterdayWaterIntake` | `Int` | `0` | Previous day's water intake |

### Activity Tracking (Shared Suite)

Break activity tracking and streak management using shared suite.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `TouchGrass.currentStreak` | `Int` | `0` | Current consecutive days with activities |
| `TouchGrass.bestStreak` | `Int` | `0` | Best ever streak record |
| `TouchGrass.lastActivityDate` | `String?` | `nil` | Last date activity was completed |
| `TouchGrass.todayActivities` | `Int` | `0` | Number of activities completed today |
| `TouchGrass.activityHistory` | `Data?` | `nil` | JSON-encoded daily activity history |

### Update Settings (Standard)

Auto-update configuration stored in standard UserDefaults.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `TouchGrass.autoUpdateEnabled` | `Bool` | `true` | Enable automatic update checking |
| `TouchGrass.lastUpdateCheck` | `Date?` | `nil` | Timestamp of last update check |
| `TouchGrass.skipVersion` | `String?` | `nil` | Version number to skip updating to |

## Migration Support

### Legacy Work Hours Migration

The PreferencesStore automatically migrates legacy work hour settings:

**Old Keys (Shared Suite):**
- `TouchGrass.workStartHour` (Int) → Migrated to `TouchGrass.workStartTime` (Double, Standard)
- `TouchGrass.workEndHour` (Int) → Migrated to `TouchGrass.workEndTime` (Double, Standard)

This migration runs once during PreferencesStore initialization and removes the legacy keys after successful migration.

## Usage Examples

### Basic Property Access

```swift
let prefs = PreferencesStore.shared

// Reading preferences
let interval = prefs.intervalMinutes
let isAdaptive = prefs.adaptiveEnabled

// Writing preferences
prefs.intervalMinutes = 60
prefs.adaptiveEnabled = false
```

### Complex Data Types

```swift
// Work days
prefs.workDays = [.monday, .tuesday, .wednesday, .thursday, .friday]
let selectedDays = prefs.workDays

// Selected calendars
prefs.selectedCalendars = ["Work Calendar", "Personal Calendar"]
let calendars = prefs.selectedCalendars

// Activity history
prefs.activityHistory = ["2024-01-01": 3, "2024-01-02": 2]
let history = prefs.activityHistory
```

### Direct UserDefaults Access

```swift
// For advanced usage, you can access the underlying UserDefaults
let sharedDefaults = prefs.getSharedDefaults()
let standardDefaults = prefs.getStandardDefaults()
```

## Type Safety

The PreferencesStore uses property wrappers to provide type-safe access to preferences:

- `@Preference<T>` - For non-optional values with defaults
- `@OptionalPreference<T>` - For optional values that may be nil

This eliminates the need for manual type casting and provides compile-time safety for preference access.

## Storage Strategy

### Shared Suite Usage
Use the shared suite (`com.touchgrass.shared`) for:
- User data that should persist across app updates
- Settings that affect core functionality
- Tracking data (streaks, history, progress)

### Standard UserDefaults Usage
Use standard UserDefaults for:
- App-specific configuration
- Settings that can reset without user impact
- Development/debugging preferences

## Debugging

### Get All Preferences

```swift
let allPrefs = PreferencesStore.shared.getAllPreferences()
print("Current preferences: \\(allPrefs)")
```

### Reset All Preferences

```swift
PreferencesStore.shared.resetToDefaults()
```

This removes all TouchGrass-related keys from both shared and standard UserDefaults.