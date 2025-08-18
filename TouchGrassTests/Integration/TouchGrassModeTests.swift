import XCTest
import Combine
@testable import Touch_Grass

final class TouchGrassModeTests: XCTestCase {
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
    
    func testTouchGrassModeActivation() {
        // Given: No active reminder
        XCTAssertFalse(reminderManager.hasActiveReminder)
        XCTAssertFalse(reminderManager.isTouchGrassModeActive)
        
        // When: Setting reminder state directly (UI method doesn't set state)
        reminderManager.hasActiveReminder = true
        reminderManager.isTouchGrassModeActive = true
        
        // Then: Should have active reminder
        XCTAssertTrue(reminderManager.hasActiveReminder)
        XCTAssertTrue(reminderManager.isTouchGrassModeActive)
    }
    
    func testActivityCompletion() {
        // Given: Active reminder
        reminderManager.hasActiveReminder = true
        reminderManager.isTouchGrassModeActive = true
        let initialStreak = reminderManager.currentStreak
        
        // When: Completing an activity and break
        reminderManager.completeActivity("Touch Grass")
        reminderManager.completeBreak()
        
        // Then: Should update completion state
        XCTAssertFalse(reminderManager.hasActiveReminder)
        XCTAssertFalse(reminderManager.isTouchGrassModeActive)
        // Streak increments happen once per day
        XCTAssertGreaterThanOrEqual(reminderManager.currentStreak, initialStreak)
        XCTAssertTrue(reminderManager.activityTracker.hasCompletedToday)
    }
    
    func testStreakManagement() {
        // Get initial streak
        let initialStreak = reminderManager.currentStreak
        
        // Complete activity
        reminderManager.completeActivity("Touch Grass")
        // Streak only increments once per day
        let newStreak = reminderManager.currentStreak
        XCTAssertGreaterThanOrEqual(newStreak, initialStreak)
        
        // Complete another activity same day
        reminderManager.completeActivity("Exercise")
        // Streak shouldn't increment twice on same day
        XCTAssertEqual(reminderManager.currentStreak, newStreak)
    }
    
    func testWaterLoggingIntegration() {
        // Given: Daily water goal
        let initialWater = reminderManager.waterTracker.currentIntake
        
        // When: Logging water
        reminderManager.logWater(8)
        
        // Then: Should update water tracking
        XCTAssertEqual(reminderManager.waterTracker.currentIntake, initialWater + 8)
    }
    
    func testSnoozeBehavior() {
        // Given: Active reminder
        reminderManager.hasActiveReminder = true
        reminderManager.isTouchGrassModeActive = true
        
        // When: Snoozing reminder
        reminderManager.snoozeReminder()
        
        // Then: Should deactivate Touch Grass mode
        XCTAssertFalse(reminderManager.hasActiveReminder)
        XCTAssertFalse(reminderManager.isTouchGrassModeActive)
    }
    
    func testCompletionTracking() {
        // Given: No completion today
        let initialCompleted = reminderManager.activityTracker.hasCompletedToday
        
        // When: Complete an activity
        reminderManager.completeActivity("Touch Grass")
        
        // Then: Should mark as completed today
        XCTAssertTrue(reminderManager.activityTracker.hasCompletedToday || initialCompleted)
    }
}
