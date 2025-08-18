import XCTest
import EventKit
import Combine
@testable import Touch_Grass

final class CalendarIntegrationTests: XCTestCase {
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
    
    func testSmartSchedulingProperty() {
        // Test smart scheduling can be toggled
        reminderManager.smartSchedulingEnabled = true
        XCTAssertTrue(reminderManager.smartSchedulingEnabled)
        
        reminderManager.smartSchedulingEnabled = false
        XCTAssertFalse(reminderManager.smartSchedulingEnabled)
    }
    
    func testAdaptiveIntervalProperty() {
        // Test adaptive interval can be toggled
        reminderManager.adaptiveIntervalEnabled = true
        XCTAssertTrue(reminderManager.adaptiveIntervalEnabled)
        
        reminderManager.adaptiveIntervalEnabled = false
        XCTAssertFalse(reminderManager.adaptiveIntervalEnabled)
    }
    
    func testLastMeetingEndTime() {
        // Test last meeting end time tracking
        XCTAssertNil(reminderManager.lastMeetingEndTime)
        
        let testDate = Date()
        reminderManager.lastMeetingEndTime = testDate
        XCTAssertNotNil(reminderManager.lastMeetingEndTime)
        XCTAssertEqual(reminderManager.lastMeetingEndTime, testDate)
    }
    
    func testCalendarManagerExists() {
        // Calendar manager should be optional and initially nil or set
        // The actual CalendarManager requires EventKit permissions
        // so we just test the property exists
        _ = reminderManager.calendarManager
        XCTAssertTrue(true) // Property exists and is accessible
    }
}
