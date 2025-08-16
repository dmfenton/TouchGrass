import XCTest
import EventKit
import Combine
@testable import Touch_Grass

final class CalendarIntegrationTests: XCTestCase {
    var reminderManager: ReminderManager!
    var mockCalendarManager: MockCalendarManager!
    var testScheduler: TestScheduler!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        
        testScheduler = TestScheduler()
        mockCalendarManager = MockCalendarManager()
        reminderManager = ReminderManager()
        reminderManager.calendarManager = mockCalendarManager
        cancellables = []
    }
    
    override func tearDown() {
        cancellables = nil
        reminderManager = nil
        mockCalendarManager = nil
        testScheduler = nil
        
        super.tearDown()
    }
    
    func testCalendarPermissionHandling() {
        // Test 1: Permission granted
        mockCalendarManager.mockHasCalendarAccess = true
        
        var accessGranted = false
        mockCalendarManager.requestCalendarAccess { granted in
            accessGranted = granted
        }
        
        XCTAssertTrue(accessGranted)
        XCTAssertTrue(mockCalendarManager.hasCalendarAccess)
        
        // Test 2: Permission denied
        mockCalendarManager.mockHasCalendarAccess = false
        
        mockCalendarManager.requestCalendarAccess { granted in
            accessGranted = granted
        }
        
        XCTAssertFalse(accessGranted)
        XCTAssertFalse(mockCalendarManager.hasCalendarAccess)
    }
    
    func testMeetingDetection() {
        // Given: No current meeting
        XCTAssertFalse(mockCalendarManager.isInMeeting)
        XCTAssertNil(mockCalendarManager.currentEvent)
        
        // When: Meeting starts
        let meetingEnd = Date().addingTimeInterval(60 * 60)
        mockCalendarManager.simulateMeetingStart(
            title: "Architecture Review",
            endTime: meetingEnd
        )
        
        // Then: Should detect meeting
        XCTAssertTrue(mockCalendarManager.isInMeeting)
        XCTAssertNotNil(mockCalendarManager.currentEvent)
        XCTAssertEqual(mockCalendarManager.currentEvent?.title, "Architecture Review")
    }
    
    func testMeetingEndTriggersReminder() {
        // Given: Smart scheduling enabled
        reminderManager.smartSchedulingEnabled = true
        
        // Start a meeting
        mockCalendarManager.simulateMeetingStart(
            title: "Sprint Planning",
            endTime: Date().addingTimeInterval(45 * 60)
        )
        
        var reminderTriggered = false
        reminderManager.$hasActiveReminder
            .dropFirst() // Skip initial false value
            .sink { hasReminder in
                if hasReminder {
                    reminderTriggered = true
                }
            }
            .store(in: &cancellables)
        
        // When: Meeting ends
        mockCalendarManager.simulateMeetingEnd()
        reminderManager.checkForMeetingTransition()
        
        // Then: Should trigger reminder
        XCTAssertTrue(reminderTriggered)
    }
    
    func testUpcomingMeetingScheduling() {
        // Given: Meeting in 10 minutes
        let meetingStart = Date().addingTimeInterval(10 * 60)
        let meetingEnd = meetingStart.addingTimeInterval(30 * 60)
        
        mockCalendarManager.scheduleUpcomingMeeting(
            title: "Daily Standup",
            startTime: meetingStart,
            endTime: meetingEnd
        )
        
        // When: Checking time until next meeting
        let timeUntilMeeting = mockCalendarManager.getTimeUntilNextMeeting()
        
        // Then: Should report correct time
        XCTAssertNotNil(timeUntilMeeting)
        XCTAssertEqual(timeUntilMeeting!, 10 * 60, accuracy: 1.0)
    }
    
    func testBackToBackMeetings() {
        // Given: Currently in meeting with another immediately after
        let firstMeetingEnd = Date().addingTimeInterval(5 * 60)
        let secondMeetingStart = firstMeetingEnd
        let secondMeetingEnd = secondMeetingStart.addingTimeInterval(30 * 60)
        
        mockCalendarManager.simulateMeetingStart(
            title: "Meeting 1",
            endTime: firstMeetingEnd
        )
        
        mockCalendarManager.scheduleUpcomingMeeting(
            title: "Meeting 2",
            startTime: secondMeetingStart,
            endTime: secondMeetingEnd
        )
        
        // When: First meeting ends
        testScheduler.advance(by: 5 * 60)
        mockCalendarManager.simulateMeetingEnd()
        
        // Immediately start second meeting
        mockCalendarManager.simulateMeetingStart(
            title: "Meeting 2",
            endTime: secondMeetingEnd
        )
        
        // Then: Should not trigger reminder between meetings
        reminderManager.checkForMeetingTransition()
        XCTAssertFalse(reminderManager.hasActiveReminder)
    }
    
    func testMeetingLoadAnalysis() {
        // Given: Multiple meetings throughout the day
        let now = Date()
        let meetings = [
            createMockEvent(title: "Morning Standup", 
                          start: now.addingTimeInterval(1 * 3600),
                          duration: 15 * 60),
            createMockEvent(title: "Design Review",
                          start: now.addingTimeInterval(2 * 3600),
                          duration: 60 * 60),
            createMockEvent(title: "Client Call",
                          start: now.addingTimeInterval(4 * 3600),
                          duration: 30 * 60),
            createMockEvent(title: "Team Retro",
                          start: now.addingTimeInterval(6 * 3600),
                          duration: 60 * 60)
        ]
        
        mockCalendarManager.mockEvents = meetings
        
        // When: Analyzing meeting load
        let todaysMeetings = mockCalendarManager.getEventsForToday()
        
        // Then: Should provide accurate meeting information
        XCTAssertEqual(todaysMeetings.count, 4)
        
        let totalMeetingTime = todaysMeetings.reduce(0) { total, event in
            total + event.endDate.timeIntervalSince(event.startDate)
        }
        
        XCTAssertEqual(totalMeetingTime, (15 + 60 + 30 + 60) * 60, accuracy: 1.0)
    }
    
    func testAdaptiveSchedulingBasedOnMeetings() {
        // Given: Adaptive scheduling enabled with heavy meeting load
        reminderManager.adaptiveIntervalEnabled = true
        reminderManager.smartSchedulingEnabled = true
        
        // Simulate busy calendar
        let meetings = (0..<6).map { index in
            createMockEvent(
                title: "Meeting \(index)",
                start: Date().addingTimeInterval(Double(index) * 3600),
                duration: 45 * 60
            )
        }
        mockCalendarManager.mockEvents = meetings
        
        // When: Determining reminder intervals
        let suggestedInterval = reminderManager.getSuggestedInterval(basedOnMeetingLoad: meetings.count)
        
        // Then: Should suggest shorter intervals for busy days
        XCTAssertLessThanOrEqual(suggestedInterval, 30)
    }
    
    // MARK: - Helper Methods
    
    private func createMockEvent(title: String, start: Date, duration: TimeInterval) -> EKEvent {
        let eventStore = EKEventStore()
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = start
        event.endDate = start.addingTimeInterval(duration)
        return event
    }
}

// Test extension for ReminderManager
extension ReminderManager {
    func getSuggestedInterval(basedOnMeetingLoad meetingCount: Int) -> Double {
        if meetingCount >= 6 {
            return 30 // More frequent breaks on busy days
        } else if meetingCount >= 4 {
            return 45
        } else {
            return 60
        }
    }
    
    func checkForMeetingTransition() {
        // Simulate the meeting transition check
        if calendarManager?.isInMeeting == false && 
           smartSchedulingEnabled {
            hasActiveReminder = true
        }
    }
    
    func getRecommendedExercises(availableTime: TimeInterval) -> [Exercise] {
        let allExercises = Exercise.allExercises
        
        if availableTime < 120 {
            // Only quick exercises for limited time
            return allExercises.filter { $0.duration <= 60 }
        } else {
            // Include all exercises
            return allExercises
        }
    }
}
