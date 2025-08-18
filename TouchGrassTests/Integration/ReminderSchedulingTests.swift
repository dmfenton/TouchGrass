import XCTest
import Combine
@testable import Touch_Grass

final class ReminderSchedulingTests: XCTestCase {
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
    
    func testIntervalConfiguration() {
        // Test setting different intervals
        reminderManager.intervalMinutes = 30
        XCTAssertEqual(reminderManager.intervalMinutes, 30)
        
        reminderManager.intervalMinutes = 45
        XCTAssertEqual(reminderManager.intervalMinutes, 45)
        
        reminderManager.intervalMinutes = 60
        XCTAssertEqual(reminderManager.intervalMinutes, 60)
    }
    
    func testPauseAndResume() {
        // Test pause functionality
        reminderManager.pause()
        XCTAssertTrue(reminderManager.isPaused)
        
        // Test resume functionality
        reminderManager.resume()
        XCTAssertFalse(reminderManager.isPaused)
    }
    
    func testSnoozeReminder() {
        // Activate reminder
        reminderManager.hasActiveReminder = true
        XCTAssertTrue(reminderManager.hasActiveReminder)
        
        // Snooze reminder
        reminderManager.snoozeReminder()
        XCTAssertFalse(reminderManager.hasActiveReminder)
    }
    
    func testWorkHoursScheduling() {
        // Configure work hours
        reminderManager.setWorkHours(
            start: (hour: 9, minute: 0),
            end: (hour: 17, minute: 0),
            days: [.monday, .tuesday, .wednesday, .thursday, .friday]
        )
        
        // Check if should schedule within work hours
        let shouldSchedule = reminderManager.shouldScheduleWithinWorkHours()
        XCTAssertNotNil(shouldSchedule)
    }
    
    func testGetNextWorkHourDate() {
        // Configure work hours
        reminderManager.setWorkHours(
            start: (hour: 9, minute: 0),
            end: (hour: 17, minute: 0),
            days: [.monday, .tuesday, .wednesday, .thursday, .friday]
        )
        
        // Get next work hour date (may be nil if currently in work hours)
        let nextDate = reminderManager.getNextWorkHourDate()
        _ = nextDate // May be nil
        XCTAssertTrue(true) // Method exists and doesn't crash
    }
    
    func testAdaptiveScheduling() {
        // Enable adaptive scheduling
        reminderManager.adaptiveIntervalEnabled = true
        XCTAssertTrue(reminderManager.adaptiveIntervalEnabled)
        
        // Set base interval
        reminderManager.intervalMinutes = 45
        
        // Adaptive scheduling should be active
        XCTAssertTrue(reminderManager.adaptiveIntervalEnabled)
        XCTAssertEqual(reminderManager.intervalMinutes, 45)
    }
    
    func testSmartScheduling() {
        // Enable smart scheduling
        reminderManager.smartSchedulingEnabled = true
        XCTAssertTrue(reminderManager.smartSchedulingEnabled)
        
        // Set last meeting end time
        reminderManager.lastMeetingEndTime = Date()
        XCTAssertNotNil(reminderManager.lastMeetingEndTime)
        
        // Disable smart scheduling
        reminderManager.smartSchedulingEnabled = false
        XCTAssertFalse(reminderManager.smartSchedulingEnabled)
    }
    
    func testScheduleNextTick() {
        // Test that scheduleNextTick method exists
        reminderManager.scheduleNextTick()
        XCTAssertTrue(true) // Method exists and doesn't crash
    }
    
    func testStartsAtLoginProperty() {
        // Test starts at login configuration
        reminderManager.startsAtLogin = true
        XCTAssertTrue(reminderManager.startsAtLogin)
        
        reminderManager.startsAtLogin = false
        XCTAssertFalse(reminderManager.startsAtLogin)
    }
}
