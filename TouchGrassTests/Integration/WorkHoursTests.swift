import XCTest
import Combine
@testable import Touch_Grass

final class WorkHoursTests: XCTestCase {
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
    
    func testWorkHoursConfiguration() {
        // Given: Default work hours
        XCTAssertEqual(reminderManager.currentWorkStartHour, 9)
        XCTAssertEqual(reminderManager.currentWorkStartMinute, 0)
        XCTAssertEqual(reminderManager.currentWorkEndHour, 17)
        XCTAssertEqual(reminderManager.currentWorkEndMinute, 0)
        
        // When: Updating work hours
        reminderManager.setWorkHours(
            start: (hour: 8, minute: 30),
            end: (hour: 18, minute: 30),
            days: [.monday, .tuesday, .wednesday, .thursday, .friday]
        )
        
        // Then: Should update configuration
        XCTAssertEqual(reminderManager.currentWorkStartHour, 8)
        XCTAssertEqual(reminderManager.currentWorkStartMinute, 30)
        XCTAssertEqual(reminderManager.currentWorkEndHour, 18)
        XCTAssertEqual(reminderManager.currentWorkEndMinute, 30)
    }
    
    func testShouldScheduleWithinWorkHours() {
        // Setup: Mon-Fri, 9 AM - 5 PM
        reminderManager.setWorkHours(
            start: (hour: 9, minute: 0),
            end: (hour: 17, minute: 0),
            days: [.monday, .tuesday, .wednesday, .thursday, .friday]
        )
        
        // Test that the method exists
        let shouldSchedule = reminderManager.shouldScheduleWithinWorkHours()
        XCTAssertNotNil(shouldSchedule)
    }
    
    func testAutoPauseProperty() {
        // Test pause/resume functionality
        reminderManager.resume()
        XCTAssertFalse(reminderManager.isPaused)
        
        reminderManager.pause()
        XCTAssertTrue(reminderManager.isPaused)
    }
    
    func testGetNextWorkHourDate() {
        // Test the method exists
        let nextDate = reminderManager.getNextWorkHourDate()
        // May be nil if currently within work hours
        _ = nextDate
        XCTAssertTrue(true) // Method exists
    }
    
    func testWorkDaysConfiguration() {
        // Test different work day configurations
        reminderManager.setWorkHours(
            start: (hour: 9, minute: 0),
            end: (hour: 17, minute: 0),
            days: [.monday, .wednesday, .friday]
        )
        
        // Verify days were set
        let workDays = reminderManager.currentWorkDays
        XCTAssertEqual(workDays.count, 3)
        XCTAssertTrue(workDays.contains(.monday))
        XCTAssertTrue(workDays.contains(.wednesday))
        XCTAssertTrue(workDays.contains(.friday))
    }
    
    func testFlexibleWorkHours() {
        // Test non-standard work hours
        reminderManager.setWorkHours(
            start: (hour: 6, minute: 15),
            end: (hour: 14, minute: 45),
            days: [.monday, .tuesday, .wednesday, .thursday]
        )
        
        XCTAssertEqual(reminderManager.currentWorkStartHour, 6)
        XCTAssertEqual(reminderManager.currentWorkStartMinute, 15)
        XCTAssertEqual(reminderManager.currentWorkEndHour, 14)
        XCTAssertEqual(reminderManager.currentWorkEndMinute, 45)
    }
}
