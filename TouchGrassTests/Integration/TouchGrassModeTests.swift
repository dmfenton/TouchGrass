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
        
        // When: Triggering Touch Grass mode
        reminderManager.showTouchGrassMode()
        
        // Then: Should activate Touch Grass mode
        XCTAssertTrue(reminderManager.hasActiveReminder)
        XCTAssertTrue(reminderManager.isTouchGrassModeActive)
    }
    
    func testActivityCompletion() {
        // Given: Active Touch Grass mode
        reminderManager.showTouchGrassMode()
        let initialStreak = reminderManager.currentStreak
        
        // When: Completing an activity
        reminderManager.completeActivity("Touch Grass")
        
        // Then: Should update completion state
        XCTAssertFalse(reminderManager.hasActiveReminder)
        XCTAssertFalse(reminderManager.isTouchGrassModeActive)
        XCTAssertEqual(reminderManager.currentStreak, initialStreak + 1)
        XCTAssertTrue(reminderManager.activityTracker.hasCompletedToday)
    }
    
    func testStreakManagement() {
        // Get initial streak
        let initialStreak = reminderManager.currentStreak
        
        // Complete activity
        reminderManager.completeActivity("Touch Grass")
        XCTAssertEqual(reminderManager.currentStreak, initialStreak + 1)
        
        // Complete another activity same day
        reminderManager.completeActivity("Exercise")
        // Streak shouldn't increment twice on same day
        XCTAssertEqual(reminderManager.currentStreak, initialStreak + 1)
    }
    
    func testWaterLoggingIntegration() {
        // Given: Daily water goal
        let initialWater = reminderManager.waterTracker.currentIntake
        
        // When: Logging water during Touch Grass mode
        reminderManager.showTouchGrassMode()
        reminderManager.logWater(8)
        
        // Then: Should update water tracking
        XCTAssertEqual(reminderManager.waterTracker.currentIntake, initialWater + 8)
    }
    
    func testSnoozeBehavior() {
        // Given: Active reminder
        reminderManager.showTouchGrassMode()
        
        var stateChanges: [(hasActive: Bool, isMode: Bool)] = []
        Publishers.CombineLatest(
            reminderManager.$hasActiveReminder,
            reminderManager.$isTouchGrassModeActive
        )
        .sink { hasActive, isMode in
            stateChanges.append((hasActive, isMode))
        }
        .store(in: &cancellables)
        
        // When: Snoozing for 10 minutes
        reminderManager.snooze(minutes: 10)
        
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