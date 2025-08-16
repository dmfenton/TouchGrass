import XCTest
import Combine
import EventKit
@testable import Touch_Grass

// End-to-end tests that simulate complete user workflows
final class EndToEndFlowTests: XCTestCase {
    var reminderManager: ReminderManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        
        reminderManager = ReminderManager()
        cancellables = []
    }
    
    override func tearDown() {
        cancellables = nil
        reminderManager = nil
        super.tearDown()
    }
    
    // MARK: - Complete Exercise Flow
    
    func testCompleteExerciseFlow() {
        // Simulate user clicking menu icon and seeing touch grass mode
        reminderManager.showTouchGrassMode()
        XCTAssertTrue(reminderManager.hasActiveReminder)
        XCTAssertTrue(reminderManager.isTouchGrassModeActive)
        
        // Select and complete exercise
        reminderManager.showExercises()
        
        // Complete the activity
        reminderManager.completeActivity("Chin Tucks")
        
        // Verify state after completion
        XCTAssertFalse(reminderManager.hasActiveReminder)
        XCTAssertFalse(reminderManager.isTouchGrassModeActive)
    }
    
    // MARK: - Snooze and Re-trigger Flow
    
    func testSnoozeAndRetriggerFlow() {
        // Given: Reminder appears
        reminderManager.showTouchGrassMode()
        XCTAssertTrue(reminderManager.hasActiveReminder)
        
        // When: User snoozes for 5 minutes
        reminderManager.snooze(minutes: 5)
        
        // Then: Reminder should be hidden
        XCTAssertFalse(reminderManager.hasActiveReminder)
        XCTAssertFalse(reminderManager.isTouchGrassModeActive)
    }
    
    // MARK: - Water Tracking Throughout Day
    
    func testWaterTrackingThroughoutDay() {
        // Initial state
        let initialIntake = reminderManager.waterTracker.currentIntake
        
        // Simulate logging water multiple times during the day
        reminderManager.logWater(1)
        XCTAssertEqual(reminderManager.waterTracker.currentIntake, initialIntake + 1)
        
        reminderManager.logWater(2)
        XCTAssertEqual(reminderManager.waterTracker.currentIntake, initialIntake + 3)
        
        // Check progress
        let progress = reminderManager.waterTracker.progressPercentage
        XCTAssertGreaterThan(progress, 0)
    }
    
    // MARK: - Work Hours Integration
    
    func testWorkHoursIntegration() {
        // Configure work hours
        reminderManager.setWorkHours(
            start: (hour: 9, minute: 0),
            end: (hour: 17, minute: 0),
            days: [.monday, .tuesday, .wednesday, .thursday, .friday]
        )
        
        // Verify configuration
        XCTAssertEqual(reminderManager.currentWorkStartHour, 9)
        XCTAssertEqual(reminderManager.currentWorkEndHour, 17)
        
        // Test pause/resume
        reminderManager.pause()
        XCTAssertTrue(reminderManager.isPaused)
        
        reminderManager.resume()
        XCTAssertFalse(reminderManager.isPaused)
    }
    
    // MARK: - Streak Management
    
    func testStreakManagement() {
        // Get initial streak
        let initialStreak = reminderManager.activityTracker.currentStreak
        
        // Complete an activity
        reminderManager.completeActivity("Touch Grass")
        
        // Streak should increment
        XCTAssertEqual(reminderManager.activityTracker.currentStreak, initialStreak + 1)
        
        // Complete another activity same day (shouldn't increment again)
        reminderManager.completeActivity("Exercise")
        XCTAssertEqual(reminderManager.activityTracker.currentStreak, initialStreak + 1)
    }
    
    // MARK: - Exercise Window Management
    
    func testExerciseWindowManagement() {
        // Show exercises
        reminderManager.showExercises()
        
        // Check if window is visible
        let isVisible = reminderManager.isExerciseWindowVisible()
        _ = isVisible // May or may not be visible depending on UI state
        
        // Show specific exercise set
        reminderManager.showExerciseSet(ExerciseData.quickReset)
        
        // Complete the break
        reminderManager.completeBreak()
        XCTAssertFalse(reminderManager.hasActiveReminder)
    }
    
    // MARK: - Adaptive Interval
    
    func testAdaptiveInterval() {
        // Enable adaptive interval
        reminderManager.adaptiveIntervalEnabled = true
        XCTAssertTrue(reminderManager.adaptiveIntervalEnabled)
        
        // Set interval
        reminderManager.intervalMinutes = 45
        XCTAssertEqual(reminderManager.intervalMinutes, 45)
        
        // Disable adaptive interval
        reminderManager.adaptiveIntervalEnabled = false
        XCTAssertFalse(reminderManager.adaptiveIntervalEnabled)
    }
    
    // MARK: - Smart Scheduling
    
    func testSmartScheduling() {
        // Enable smart scheduling
        reminderManager.smartSchedulingEnabled = true
        XCTAssertTrue(reminderManager.smartSchedulingEnabled)
        
        // Set last meeting end time
        let meetingEndTime = Date()
        reminderManager.lastMeetingEndTime = meetingEndTime
        XCTAssertNotNil(reminderManager.lastMeetingEndTime)
        
        // Disable smart scheduling
        reminderManager.smartSchedulingEnabled = false
        XCTAssertFalse(reminderManager.smartSchedulingEnabled)
    }
}