# Touch Grass Integration Tests

## Overview

This test suite provides comprehensive integration testing for Touch Grass, focusing on critical user workflows and system interactions rather than unit-level testing.

## Test Philosophy

> "Integration tests are what help me sleep at night" - @dmfenton

We prioritize integration tests because they:
- Verify actual user workflows end-to-end
- Catch real-world interaction bugs
- Ensure components work together correctly
- Provide confidence in system behavior

## Test Structure

```
TouchGrassTests/
├── Integration/          # Integration test suites
│   ├── ReminderSchedulingTests.swift
│   ├── TouchGrassModeTests.swift
│   ├── CalendarIntegrationTests.swift
│   ├── WaterTrackingTests.swift
│   └── WorkHoursTests.swift
├── Helpers/             # Test utilities
│   ├── TestScheduler.swift
│   └── TestPreferencesStore.swift
└── Mocks/              # Mock objects
    ├── MockCalendarManager.swift
    └── MockNotificationCenter.swift
```

## Running Tests

### Quick Start
```bash
# Run all tests
make test

# Run with coverage report
make test-coverage

# Run specific test class
make test-filter FILTER=ReminderSchedulingTests

# Run with verbose output
make test-verbose
```

### Using the Test Script Directly
```bash
# Run all tests
./scripts/test.sh

# Filter tests
./scripts/test.sh --filter TouchGrassModeTests

# Generate coverage
./scripts/test.sh --coverage

# Verbose output
./scripts/test.sh --verbose
```

## Test Coverage Areas

### 1. Reminder Scheduling (`ReminderSchedulingTests`)
- Fixed interval scheduling aligned to clock time
- Work hours boundary conditions
- Meeting-aware scheduling
- Pause/resume functionality
- Snooze behavior
- Meeting end triggers

### 2. Touch Grass Mode (`TouchGrassModeTests`)
- Mode activation and deactivation
- Activity completion tracking
- Streak management
- Water logging integration
- Exercise recommendations based on available time
- Snooze and skip behaviors

### 3. Calendar Integration (`CalendarIntegrationTests`)
- Calendar permission handling
- Meeting detection
- Meeting end reminder triggers
- Back-to-back meeting handling
- Meeting load analysis
- Adaptive scheduling based on calendar

### 4. Water Tracking (`WaterTrackingTests`)
- Daily goal tracking
- Unit conversions (glasses/ounces/ml)
- Daily reset at midnight
- Streak tracking
- Data persistence
- Quick-add buttons
- Progress notifications

### 5. Work Hours Management (`WorkHoursTests`)
- Work hours configuration
- In/out of hours detection
- Auto-pause outside work hours
- Auto-resume at work start
- Next work period calculation
- Flexible work days
- Lunch break handling

## Key Test Utilities

### TestScheduler
Controls time flow in tests, allowing precise timing verification:
```swift
testScheduler.setCurrentTime(date)
testScheduler.advance(by: 30 * 60) // Advance 30 minutes
```

### MockCalendarManager
Simulates calendar events and meeting transitions:
```swift
mockCalendarManager.simulateMeetingStart(title: "Standup", endTime: Date())
mockCalendarManager.simulateMeetingEnd()
```

### TestPreferencesStore
Provides isolated preferences storage for testing:
```swift
preferencesStore.setValue(45, forKey: "intervalMinutes")
```

## Writing New Tests

### Integration Test Template
```swift
final class NewFeatureTests: XCTestCase {
    var reminderManager: ReminderManager!
    var mockCalendarManager: MockCalendarManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        // Setup test environment
    }
    
    override func tearDown() {
        // Clean up
        super.tearDown()
    }
    
    func testCriticalUserFlow() {
        // Given: Initial state
        // When: User action
        // Then: Expected outcome
    }
}
```

### Best Practices

1. **Test User Workflows**: Focus on complete user journeys, not isolated functions
2. **Use Time Control**: Leverage TestScheduler for deterministic timing
3. **Mock External Dependencies**: Use mocks for calendar, notifications, etc.
4. **Test State Transitions**: Verify state changes through the full lifecycle
5. **Include Edge Cases**: Test boundaries, error conditions, and recovery

## Coverage Goals

Current coverage targets:
- Core scheduling logic: 90%+
- User workflows: 85%+
- Calendar integration: 80%+
- Data persistence: 75%+

## CI/CD Integration

Tests run automatically on:
- Pull request creation
- Push to main branch
- Release builds

## Troubleshooting

### Common Issues

**Tests fail with "Scheme not found"**
```bash
# Add test scheme to Xcode project
./scripts/add_tests_to_xcode.sh
```

**Calendar tests fail**
```bash
# Ensure calendar permissions are granted in System Settings
```

**Time-based tests are flaky**
```bash
# Always use TestScheduler instead of real timers
# Never use Date() directly in tests
```

## Future Improvements

- [ ] UI automation tests for menu bar interactions
- [ ] Performance testing for large calendar datasets
- [ ] Stress testing for notification handling
- [ ] Accessibility testing
- [ ] Memory leak detection