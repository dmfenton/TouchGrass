# Touch Grass State Architecture Analysis

## Current State Ownership

### 1. ReminderManager (Central State Hub - 769 lines, 20 @Published)
**Core Responsibilities:**
- Timer management (`isPaused`, `timeUntilNextReminder`)
- Reminder scheduling (`intervalMinutes`, `hasActiveReminder`)
- User preferences (`startsAtLogin`, `adaptiveIntervalEnabled`)
- Water tracking (6 properties: `waterTrackingEnabled`, `dailyWaterGoal`, etc.)
- Activity tracking (`completedActivities`, `currentStreak`, `bestStreak`)
- Work hours integration (via `WorkHoursManager`)
- Calendar integration (owns `CalendarManager` instance)
- UI state (`isTouchGrassModeActive`)

**Problem:** Too many responsibilities - violates Single Responsibility Principle

### 2. CalendarManager (7 @Published properties)
**Responsibilities:**
- Calendar permissions (`hasCalendarAccess`)
- Calendar selection (`availableCalendars`, `selectedCalendarIdentifiers`)
- Event monitoring (`currentEvent`, `nextEvent`, `isInMeeting`)
- Time calculations (`timeUntilNextEvent`)

**Issue:** Owned by ReminderManager but also created independently in views

### 3. UpdateManager (Singleton - 6 @Published)
**Responsibilities:**
- Update checking (`updateAvailable`, `latestVersion`)
- Download management (`isDownloading`, `downloadProgress`)
- Update preferences (via UserDefaults)

**Good:** Clear single responsibility, proper singleton pattern

### 4. WorkHoursManager (No @Published - uses UserDefaults)
**Responsibilities:**
- Work schedule configuration
- Work time validation

**Issue:** No observable properties, tightly coupled to ReminderManager

### 5. OnboardingManager (10 @Published)
**Responsibilities:**
- Onboarding flow state
- Initial configuration values

**Issue:** Duplicates state that exists in ReminderManager

## State Storage Chaos

### UserDefaults Usage (3 different approaches!)
1. **Standard UserDefaults:** Most managers
2. **Shared Suite:** `com.touchgrass.shared` (ReminderManager, CalendarManager)
3. **Direct keys:** `TouchGrass.hasCompletedOnboarding` (multiple places)

### Persistent State Keys Found:
- Water tracking settings
- Work hours configuration  
- Calendar selections
- Reminder intervals
- Onboarding completion
- Update preferences
- Launch at login

## State Flow Issues

### 1. Circular Dependencies
- ReminderManager owns CalendarManager
- Views create their own CalendarManager instances
- Multiple sources of truth for calendar state

### 2. State Duplication
- Work hours exist in OnboardingManager and ReminderManager
- Calendar permissions checked in multiple places
- Water settings duplicated during onboarding

### 3. Window Controllers (8 separate controllers)
- Each maintains its own window reference
- No shared window management logic
- Duplicate show/hide patterns

## Recommended Refactoring

### Phase 1: Extract Domains
```
ReminderManager → Split into:
├── TimerService (scheduling, countdown)
├── ActivityTracker (streaks, completed activities)
├── WaterTracker (water goals, intake)
└── PreferencesStore (user settings)
```

### Phase 2: Establish Clear Ownership
```
App State
├── AppEnvironment (singleton)
│   ├── TimerService
│   ├── CalendarService (singleton)
│   ├── UpdateService (already singleton)
│   └── PreferencesStore
│
├── Feature States (view-specific)
│   ├── OnboardingState
│   ├── ExerciseState
│   └── TouchGrassState
```

### Phase 3: Unify Window Management
```
WindowManager (base class)
├── OnboardingWindow
├── TouchGrassWindow
├── SettingsWindow
└── ExerciseWindow
```

### Phase 4: Standardize Persistence
- Use single UserDefaults suite
- Create Settings struct with Codable
- Single source of truth for each setting

## Priority Refactoring Order

1. **Extract WaterTracker** from ReminderManager (easiest, most isolated)
2. **Extract ActivityTracker** from ReminderManager (clear boundaries)
3. **Create WindowManager base class** (reduce duplication)
4. **Unify CalendarManager usage** (fix circular deps)
5. **Split remaining ReminderManager** into TimerService + Preferences
6. **Standardize UserDefaults** usage

This refactoring will:
- Reduce ReminderManager from 769 to ~200 lines
- Eliminate state duplication
- Fix memory management issues
- Make testing possible
- Improve code maintainability