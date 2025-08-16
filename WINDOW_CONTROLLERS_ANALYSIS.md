# Window Controllers Analysis

## Current State: 8 Window Controllers with Duplicated Patterns

### Active Controllers (Used in App)

1. **TouchGrassModeController** (TouchGrassApp.swift:9)
   - Type: NSObject with NSPanel
   - Purpose: Main reminder floating panel
   - Size: 500x600
   - Features: Floating, joins all spaces, non-activating panel
   - Pattern: Manual window creation and management

2. **CustomizationWindowController** (TouchGrassApp.swift:41)
   - Type: NSWindowController  
   - Purpose: Settings/customization window
   - Size: 480x720
   - Features: Floating, modal-like behavior
   - Pattern: Convenience init with completion callback

3. **TouchGrassOnboardingController** (TouchGrassApp.swift:8)
   - Type: NSWindowController
   - Purpose: Initial onboarding flow
   - Size: 520x600
   - Features: Floating, transparent titlebar
   - Pattern: Convenience init, static shouldShow method

4. **ExerciseWindowController** (ReminderManager.swift:37)
   - Type: NSObject with NSPanel
   - Purpose: Exercise coaching window
   - Size: 520x750
   - Features: Floating panel, joins all spaces
   - Pattern: Manual window creation, content updates

### Inactive Controllers (Not Used)

5. **ExerciseSelectionController** - Minimal implementation, appears unused
6. **OnboardingWindowController** - Replaced by TouchGrassOnboardingController
7. **SimpleOnboardingWindowController** - Replaced by TouchGrassOnboardingController
8. **WindowManager** (newly created) - Base class, not yet integrated

## Common Patterns Identified

### Window Creation Pattern
```swift
// Pattern 1: NSWindowController with convenience init
convenience init(reminderManager: ReminderManager) {
    let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: WIDTH, height: HEIGHT),
        styleMask: [.titled, .closable],
        backing: .buffered,
        defer: false
    )
    // Configure window...
    self.init(window: window)
}

// Pattern 2: NSObject with lazy NSPanel creation
private var window: NSPanel?
func show() {
    if window == nil {
        window = createPanel()
    }
    // Set content and show...
}
```

### Duplicated Code Blocks

1. **Window Configuration** (duplicated 8x)
   - center()
   - level = .floating
   - makeKeyAndOrderFront(nil)
   - NSApp.activate(ignoringOtherApps: true)

2. **Panel Configuration** (duplicated 3x)
   - collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
   - styleMask with .nonactivatingPanel
   - isMovableByWindowBackground = true

3. **Content Setting** (duplicated 8x)
   - NSHostingController creation
   - contentViewController assignment
   - OR NSHostingView for panels

## Problems with Current Architecture

1. **No Consistent Base Pattern**
   - Some inherit NSWindowController
   - Some inherit NSObject
   - Some use NSWindow, others NSPanel
   - Inconsistent initialization patterns

2. **Memory Management Issues**
   - Some controllers recreate windows on each show
   - Others maintain singleton windows
   - No consistent cleanup pattern

3. **Code Duplication**
   - 8 different implementations of window centering
   - 8 different implementations of show/hide
   - Multiple implementations of floating behavior

4. **Maintenance Burden**
   - Changes to window behavior require 8 edits
   - No shared configuration management
   - Inconsistent naming and patterns

## Refactoring Strategy

### Phase 1: Identify Controller Types
Based on usage patterns, we have 3 distinct types:

1. **Modal Windows** (one-time use, close on complete)
   - CustomizationWindowController
   - TouchGrassOnboardingController

2. **Persistent Panels** (reusable, floating)
   - TouchGrassModeController
   - ExerciseWindowController

3. **Unused/Legacy** (can be deleted)
   - ExerciseSelectionController
   - OnboardingWindowController
   - SimpleOnboardingWindowController

### Phase 2: Refactoring Approach

#### Option A: Use WindowManager Base Class
- Pro: Single inheritance model
- Pro: Consistent API
- Con: Need to refactor all existing controllers
- Con: Breaking changes to initialization

#### Option B: Protocol-Based Approach
- Pro: Can mix with existing NSWindowController
- Pro: Gradual migration possible
- Con: Less code reuse
- Con: Still some duplication

#### Option C: Composition Pattern
- Pro: Keep existing controllers
- Pro: Add WindowManager as property
- Con: More complex architecture
- Con: Potential for inconsistent usage

### Recommendation: Option C (Composition)

Keep existing controllers but extract window management into a helper:

```swift
class CustomizationWindowController: NSWindowController {
    private let windowManager = ModalWindowManager(
        title: "Customize Touch Grass",
        size: NSSize(width: 480, height: 720)
    )
    
    convenience init(reminderManager: ReminderManager, onComplete: @escaping () -> Void) {
        self.init(window: windowManager.window)
        // Set content...
    }
}
```

This allows:
1. Gradual migration without breaking changes
2. Reuse of window management logic
3. Maintaining existing NSWindowController benefits
4. Testing new pattern before full commitment

## Implementation Priority

1. **Delete unused controllers** (saves 120+ lines)
   - ExerciseSelectionController
   - OnboardingWindowController  
   - SimpleOnboardingWindowController

2. **Refactor TouchGrassModeController** (most complex)
   - Extract panel management to FloatingPanelManager
   - Keep controller logic separate

3. **Refactor ExerciseWindowController** (similar to #2)
   - Share FloatingPanelManager pattern
   - Reduce duplication

4. **Update modal controllers** (simpler pattern)
   - CustomizationWindowController
   - TouchGrassOnboardingController

## Metrics

- Current: ~500 lines across 8 controllers
- After cleanup: ~300 lines across 4 controllers
- Code reduction: 40%
- Duplication eliminated: ~150 lines