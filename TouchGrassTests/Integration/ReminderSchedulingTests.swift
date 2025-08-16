import XCTest
import Combine
@testable import Touch_Grass

final class ReminderSchedulingTests: XCTestCase {
    var reminderManager: ReminderManager!
    var testScheduler: TestScheduler!
    var mockCalendarManager: MockCalendarManager!
    var preferencesStore: TestPreferencesStore!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        
        testScheduler = TestScheduler()
        preferencesStore = TestPreferencesStore()
        mockCalendarManager = MockCalendarManager()
        reminderManager = ReminderManager()
        reminderManager.calendarManager = mockCalendarManager
        cancellables = []
    }
    
    override func tearDown() {
        cancellables = nil
        reminderManager = nil
        mockCalendarManager = nil
        preferencesStore = nil
        testScheduler = nil
        
        super.tearDown()
    }
    
    func testFixedIntervalScheduling() {
        // Given: 45-minute interval setting
        reminderManager.intervalMinutes = 45
        reminderManager.isPaused = false
        
        // When: Starting the scheduler at 10:15
        let startTime = createDate(hour: 10, minute: 15)
        testScheduler.setCurrentTime(startTime)
        
        // Then: Next reminder should be at 11:00 (aligned to clock)
        let expectedTime = createDate(hour: 11, minute: 0)
        XCTAssertEqual(reminderManager.nextReminderTime?.timeIntervalSince1970,
                      expectedTime.timeIntervalSince1970,
                      accuracy: 1.0)
    }
    
    func testWorkHoursBoundary() {
        // Given: Work hours 9 AM to 5 PM
        reminderManager.updateWorkHours(
            startHour: 9, startMinute: 0,
            endHour: 17, endMinute: 0,
            workDays: [.monday, .tuesday, .wednesday, .thursday, .friday]
        )
        
        // When: Current time is 4:45 PM with 45-minute intervals
        let currentTime = createDate(hour: 16, minute: 45)
        testScheduler.setCurrentTime(currentTime)
        reminderManager.intervalMinutes = 45
        
        // Then: Should not schedule reminder past 5 PM
        reminderManager.scheduleNextReminderIfNeeded()
        
        if let nextReminder = reminderManager.nextReminderTime {
            let components = Calendar.current.dateComponents([.hour, .minute], from: nextReminder)
            XCTAssertTrue(components.hour! < 17 || (components.hour! == 17 && components.minute! == 0))
        }
    }
    
    func testMeetingAwareScheduling() {
        // Given: Smart scheduling enabled and upcoming meeting
        reminderManager.smartSchedulingEnabled = true
        
        let meetingStart = Date().addingTimeInterval(5 * 60) // 5 minutes from now
        let meetingEnd = meetingStart.addingTimeInterval(30 * 60) // 30-minute meeting
        
        mockCalendarManager.scheduleUpcomingMeeting(
            title: "Team Standup",
            startTime: meetingStart,
            endTime: meetingEnd
        )
        
        // When: Scheduling next reminder
        reminderManager.scheduleNextReminderIfNeeded()
        
        // Then: Should not schedule during the meeting
        if let nextReminder = reminderManager.nextReminderTime {
            XCTAssertTrue(nextReminder > meetingEnd || nextReminder < meetingStart)
        }
    }
    
    func testPauseResumeFlow() {
        var stateChanges: [Bool] = []
        
        reminderManager.$isPaused
            .sink { isPaused in
                stateChanges.append(isPaused)
            }
            .store(in: &cancellables)
        
        // When: Pausing
        reminderManager.pause()
        
        // Then: Should be paused
        XCTAssertTrue(reminderManager.isPaused)
        
        // When: Resuming
        reminderManager.resume()
        
        // Then: Should not be paused and timer should be scheduled
        XCTAssertFalse(reminderManager.isPaused)
        XCTAssertNotNil(reminderManager.nextReminderTime)
    }
    
    func testSnoozeFunction() {
        // Given: Active reminder
        reminderManager.hasActiveReminder = true
        let originalNextTime = reminderManager.nextReminderTime
        
        // When: Snoozing for 5 minutes
        reminderManager.snooze(minutes: 5)
        
        // Then: Should schedule reminder 5 minutes later
        XCTAssertFalse(reminderManager.hasActiveReminder)
        
        if let nextTime = reminderManager.nextReminderTime,
           let originalTime = originalNextTime {
            let difference = nextTime.timeIntervalSince(originalTime)
            XCTAssertEqual(difference, 5 * 60, accuracy: 2.0)
        }
    }
    
    func testMeetingEndTrigger() {
        // Given: Currently in a meeting
        mockCalendarManager.simulateMeetingStart(
            title: "Product Review",
            endTime: Date().addingTimeInterval(30 * 60)
        )
        
        var reminderTriggered = false
        reminderManager.$hasActiveReminder
            .sink { hasReminder in
                if hasReminder {
                    reminderTriggered = true
                }
            }
            .store(in: &cancellables)
        
        // When: Meeting ends
        testScheduler.advance(by: 30 * 60)
        mockCalendarManager.simulateMeetingEnd()
        reminderManager.checkForMeetingTransition()
        
        // Then: Should trigger reminder after meeting
        XCTAssertTrue(reminderTriggered)
    }
    
    // MARK: - Helper Methods
    
    private func createDate(hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        components.second = 0
        
        return Calendar.current.date(from: components) ?? Date()
    }
}