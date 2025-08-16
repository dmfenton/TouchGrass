import Foundation
import EventKit

// Mock implementation of CalendarManager for testing
class MockCalendarManager {
    var mockEvents: [EKEvent] = []
    var mockCurrentEvent: EKEvent?
    var mockNextEvent: EKEvent?
    var mockHasCalendarAccess: Bool = true
    var mockIsInMeeting: Bool = false
    var mockTimeUntilNextMeeting: TimeInterval?
    
    var hasCalendarAccess: Bool {
        return mockHasCalendarAccess
    }
    
    var isInMeeting: Bool {
        return mockIsInMeeting
    }
    
    var currentEvent: EKEvent? {
        return mockCurrentEvent
    }
    
    var nextEvent: EKEvent? {
        return mockNextEvent
    }
    
    func requestCalendarAccess(completion: @escaping (Bool) -> Void) {
        completion(mockHasCalendarAccess)
    }
    
    func updateCurrentAndNextEvents() {
        // Use mock values set by test
    }
    
    func getTimeUntilNextMeeting() -> TimeInterval? {
        return mockTimeUntilNextMeeting
    }
    
    func getEventsForToday() -> [EKEvent] {
        return mockEvents
    }
    
    func simulateMeetingStart(title: String, endTime: Date) {
        let event = createMockEvent(title: title, startDate: Date(), endDate: endTime)
        mockCurrentEvent = event
        mockIsInMeeting = true
    }
    
    func simulateMeetingEnd() {
        mockCurrentEvent = nil
        mockIsInMeeting = false
    }
    
    func scheduleUpcomingMeeting(title: String, startTime: Date, endTime: Date) {
        let event = createMockEvent(title: title, startDate: startTime, endDate: endTime)
        mockNextEvent = event
        mockTimeUntilNextMeeting = startTime.timeIntervalSinceNow
    }
    
    private func createMockEvent(title: String, startDate: Date, endDate: Date) -> EKEvent {
        let eventStore = EKEventStore()
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        return event
    }
}
