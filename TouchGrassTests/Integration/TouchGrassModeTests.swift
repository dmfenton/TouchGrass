import XCTest
import Combine
@testable import Touch_Grass

final class TouchGrassModeTests: XCTestCase {
    var reminderManager: ReminderManager!
    var mockCalendarManager: MockCalendarManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        
        mockCalendarManager = MockCalendarManager()
        reminderManager = ReminderManager()
        reminderManager.calendarManager = mockCalendarManager
        cancellables = []
    }
    
    override func tearDown() {
        cancellables = nil
        reminderManager = nil
        mockCalendarManager = nil
        
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
        reminderManager.completeActivity(type: .touchGrass)
        
        // Then: Should update completion state
        XCTAssertFalse(reminderManager.hasActiveReminder)
        XCTAssertFalse(reminderManager.isTouchGrassModeActive)
        XCTAssertEqual(reminderManager.currentStreak, initialStreak + 1)
        XCTAssertTrue(reminderManager.activityTracker.hasCompletedActivityToday())
    }
    
    func testStreakManagement() {
        // Reset streak for clean test
        reminderManager.activityTracker.resetStreak()
        
        // Day 1: Complete activity
        reminderManager.completeActivity(type: .touchGrass)
        XCTAssertEqual(reminderManager.currentStreak, 1)
        
        // Day 2: Complete activity (simulate next day)
        simulateNextDay()
        reminderManager.completeActivity(type: .exercise)
        XCTAssertEqual(reminderManager.currentStreak, 2)
        
        // Day 3: Skip activity
        simulateNextDay()
        reminderManager.skipActivity()
        XCTAssertEqual(reminderManager.currentStreak, 0)
    }
    
    func testWaterLoggingIntegration() {
        // Given: Daily water goal of 64 oz
        reminderManager.waterTracker.dailyGoal = 64
        reminderManager.waterTracker.selectedUnit = .ounces
        
        // When: Logging water during Touch Grass mode
        reminderManager.showTouchGrassMode()
        reminderManager.waterTracker.addWater(amount: 8)
        
        // Then: Should update water tracking
        XCTAssertEqual(reminderManager.waterTracker.todayTotal, 8)
        XCTAssertEqual(reminderManager.waterTracker.progressPercentage, 0.125)
    }
    
    func testExerciseRecommendations() {
        // Test 1: Limited time before meeting - should recommend quick exercises
        mockCalendarManager.scheduleUpcomingMeeting(
            title: "Client Call",
            startTime: Date().addingTimeInterval(2 * 60), // 2 minutes
            endTime: Date().addingTimeInterval(32 * 60)
        )
        
        let quickExercises = reminderManager.getRecommendedExercises(availableTime: 2 * 60)
        XCTAssertTrue(quickExercises.allSatisfy { $0.duration <= 60 }) // All quick exercises
        
        // Test 2: Plenty of time - should include longer exercises
        mockCalendarManager.mockNextEvent = nil
        mockCalendarManager.mockTimeUntilNextMeeting = nil
        
        let allExercises = reminderManager.getRecommendedExercises(availableTime: 10 * 60)
        XCTAssertTrue(allExercises.contains { $0.duration > 60 }) // Includes longer exercises
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
        
        // And: Next reminder should be scheduled
        XCTAssertNotNil(reminderManager.nextReminderTime)
        
        let timeUntilNext = reminderManager.nextReminderTime?.timeIntervalSinceNow ?? 0
        XCTAssertEqual(timeUntilNext, 10 * 60, accuracy: 5.0)
    }
    
    func testSkipBehavior() {
        // Given: Active reminder with existing streak
        reminderManager.activityTracker.incrementStreak()
        reminderManager.activityTracker.incrementStreak()
        XCTAssertEqual(reminderManager.currentStreak, 2)
        
        reminderManager.showTouchGrassMode()
        
        // When: Skipping activity
        reminderManager.skipActivity()
        
        // Then: Should reset streak and schedule next reminder
        XCTAssertEqual(reminderManager.currentStreak, 0)
        XCTAssertFalse(reminderManager.hasActiveReminder)
        XCTAssertFalse(reminderManager.isTouchGrassModeActive)
        XCTAssertNotNil(reminderManager.nextReminderTime)
    }
    
    // MARK: - Helper Methods
    
    private func simulateNextDay() {
        // Simulate moving to next day by manipulating activity tracker's last completion date
        reminderManager.activityTracker.simulateNewDay()
    }
}

// Extension to help with testing
extension ActivityTracker {
    func simulateNewDay() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        UserDefaults.standard.set(yesterday, forKey: "lastActivityDate")
    }
}
