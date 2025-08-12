import Foundation
import EventKit
import Combine
import SwiftUI

final class CalendarManager: ObservableObject {
    @Published var hasCalendarAccess = false
    @Published var availableCalendars: [EKCalendar] = []
    @Published var selectedCalendarIdentifiers: Set<String> = []
    @Published var currentEvent: EKEvent?
    @Published var nextEvent: EKEvent?
    @Published var isInMeeting = false
    @Published var timeUntilNextEvent: TimeInterval?
    
    private let eventStore = EKEventStore()
    private var eventUpdateTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // Work hours for filtering
    var workStartHour: Int = 9
    var workStartMinute: Int = 0
    var workEndHour: Int = 17
    var workEndMinute: Int = 0
    
    // UserDefaults keys
    private let selectedCalendarsKey = "TouchGrass.selectedCalendars"
    
    init() {
        loadSelectedCalendars()
        checkCalendarAccess()
        startEventMonitoring()
        // Force initial update
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.updateCurrentAndNextEvents()
        }
    }
    
    func requestCalendarAccess(completion: @escaping (Bool) -> Void) {
        eventStore.requestAccess(to: .event) { [weak self] granted, _ in
            DispatchQueue.main.async {
                self?.hasCalendarAccess = granted
                if granted {
                    self?.loadCalendars()
                    self?.updateCurrentAndNextEvents()
                }
                completion(granted)
            }
        }
    }
    
    private func checkCalendarAccess() {
        let status = EKEventStore.authorizationStatus(for: .event)
        hasCalendarAccess = status == .authorized
        
        if hasCalendarAccess {
            loadCalendars()
            updateCurrentAndNextEvents()
        }
    }
    
    private func loadCalendars() {
        availableCalendars = eventStore.calendars(for: .event)
            .filter { !$0.isSubscribed } // Exclude subscribed calendars like holidays
            .sorted { $0.title < $1.title }
    }
    
    private func loadSelectedCalendars() {
        if let saved = UserDefaults.standard.array(forKey: selectedCalendarsKey) as? [String] {
            selectedCalendarIdentifiers = Set(saved)
        }
    }
    
    func saveSelectedCalendars() {
        UserDefaults.standard.set(Array(selectedCalendarIdentifiers), forKey: selectedCalendarsKey)
    }
    
    func toggleCalendar(_ calendar: EKCalendar) {
        if selectedCalendarIdentifiers.contains(calendar.calendarIdentifier) {
            selectedCalendarIdentifiers.remove(calendar.calendarIdentifier)
        } else {
            selectedCalendarIdentifiers.insert(calendar.calendarIdentifier)
        }
        saveSelectedCalendars()
        updateCurrentAndNextEvents()
    }
    
    func isCalendarSelected(_ calendar: EKCalendar) -> Bool {
        selectedCalendarIdentifiers.contains(calendar.calendarIdentifier)
    }
    
    private func startEventMonitoring() {
        // Update events every minute
        eventUpdateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateCurrentAndNextEvents()
        }
    }
    
    func updateCurrentAndNextEvents() {
        guard hasCalendarAccess, !selectedCalendarIdentifiers.isEmpty else {
            currentEvent = nil
            nextEvent = nil
            isInMeeting = false
            timeUntilNextEvent = nil
            return
        }
        
        let now = Date()
        let calendar = Calendar.current
        
        // Calculate end of work day (not end of calendar day)
        var endComponents = calendar.dateComponents([.year, .month, .day], from: now)
        endComponents.hour = workEndHour
        endComponents.minute = workEndMinute
        guard let endOfWorkDay = calendar.date(from: endComponents) else {
            return
        }
        
        // If we're past work hours, no events to show
        if now > endOfWorkDay {
            currentEvent = nil
            nextEvent = nil
            isInMeeting = false
            timeUntilNextEvent = nil
            return
        }
        
        // Get selected calendars
        let selectedCalendars = availableCalendars.filter { 
            selectedCalendarIdentifiers.contains($0.calendarIdentifier) 
        }
        
        guard !selectedCalendars.isEmpty else {
            currentEvent = nil
            nextEvent = nil
            isInMeeting = false
            timeUntilNextEvent = nil
            return
        }
        
        // Create predicate for events - only check until end of work day
        let predicate = eventStore.predicateForEvents(
            withStart: now.addingTimeInterval(-7200), // Check 2 hours back for ongoing events
            end: endOfWorkDay,
            calendars: selectedCalendars
        )
        
        let events = eventStore.events(matching: predicate)
            .filter { event in
                // Exclude all-day events
                if event.isAllDay { return false }
                
                // Only include events within work hours
                if !isWithinWorkHours(event) { return false }
                
                // Only include real meetings (not personal time blocks)
                return isRealMeeting(event)
            }
            .sorted { ($0.startDate ?? Date.distantPast) < ($1.startDate ?? Date.distantPast) }
        
        // Find current event (happening now)
        currentEvent = events.first { event in
            guard let startDate = event.startDate,
                  let endDate = event.endDate else { return false }
            return startDate <= now && endDate > now
        }
        
        isInMeeting = currentEvent != nil
        
        // Find next event (after current time or after current event)
        let searchAfter = currentEvent?.endDate ?? now
        nextEvent = events.first { event in
            guard let startDate = event.startDate else { return false }
            return startDate > searchAfter
        }
        
        // Calculate time until next event
        if let next = nextEvent {
            timeUntilNextEvent = next.startDate.timeIntervalSince(now)
        } else {
            timeUntilNextEvent = nil
        }
    }
    
    func formatTimeUntilEvent(_ interval: TimeInterval) -> String {
        if interval < 60 {
            return "< 1 min"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) min"
        } else {
            let hours = Int(interval / 3600)
            let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(hours) hour\(hours == 1 ? "" : "s")"
            }
        }
    }
    
    func formatEventTime(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter.string(from: date)
    }
    
    // Get all meetings for today
    func getTodaysMeetings() -> [EKEvent] {
        guard hasCalendarAccess else { return [] }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Use work hours for start and end
        var startComponents = calendar.dateComponents([.year, .month, .day], from: now)
        startComponents.hour = workStartHour
        startComponents.minute = workStartMinute
        guard let startOfWorkDay = calendar.date(from: startComponents) else { return [] }
        
        var endComponents = calendar.dateComponents([.year, .month, .day], from: now)
        endComponents.hour = workEndHour
        endComponents.minute = workEndMinute
        guard let endOfWorkDay = calendar.date(from: endComponents) else { return [] }
        
        let selectedCals = availableCalendars.filter { 
            selectedCalendarIdentifiers.contains($0.calendarIdentifier) 
        }
        
        guard !selectedCals.isEmpty else { return [] }
        
        let predicate = eventStore.predicateForEvents(
            withStart: startOfWorkDay,
            end: endOfWorkDay,
            calendars: selectedCals
        )
        
        return eventStore.events(matching: predicate)
            .filter { event in
                // Exclude all-day events
                if event.isAllDay { return false }
                
                // Only include events within work hours
                if !isWithinWorkHours(event) { return false }
                
                // Only include real meetings
                return isRealMeeting(event)
            }
            .sorted { ($0.startDate ?? Date.distantPast) < ($1.startDate ?? Date.distantPast) }
    }
    
    // Calculate total meeting time remaining today (from now onwards)
    func totalMeetingTimeToday() -> TimeInterval {
        let now = Date()
        let meetings = getTodaysMeetings()
        
        var totalTime: TimeInterval = 0
        
        for meeting in meetings {
            guard let startDate = meeting.startDate,
                  let endDate = meeting.endDate else { continue }
            if endDate > now {
                let meetingStart = max(startDate, now)
                totalTime += endDate.timeIntervalSince(meetingStart)
            }
        }
        
        return totalTime
    }
    
    // Calculate total meeting time for the entire day (past and future)
    func totalMeetingTimeEntireDay() -> TimeInterval {
        let meetings = getTodaysMeetings()
        
        var totalTime: TimeInterval = 0
        
        for meeting in meetings {
            guard let startDate = meeting.startDate,
                  let endDate = meeting.endDate else { continue }
            totalTime += endDate.timeIntervalSince(startDate)
        }
        
        return totalTime
    }
    
    // Find next free time slot of at least specified duration
    func nextFreeSlot(minimumDuration: TimeInterval = 900) -> (start: Date, duration: TimeInterval)? {
        let now = Date()
        let meetings = getTodaysMeetings().filter { $0.endDate > now }
        
        if meetings.isEmpty {
            // No more meetings today - free now!
            return (now, 28800) // 8 hours until end of workday assumption
        }
        
        // Check if we're free right now
        if let firstMeeting = meetings.first,
           let startDate = firstMeeting.startDate,
           startDate.timeIntervalSince(now) >= minimumDuration {
            return (now, startDate.timeIntervalSince(now))
        }
        
        // Check gaps between meetings
        if meetings.count > 1 {
            for i in 0..<meetings.count - 1 {
                guard let gapStart = meetings[i].endDate,
                      let gapEnd = meetings[i + 1].startDate else { continue }
                let gapDuration = gapEnd.timeIntervalSince(gapStart)
                
                if gapDuration >= minimumDuration {
                    return (gapStart, gapDuration)
                }
            }
        }
        
        // After last meeting
        if let lastMeeting = meetings.last,
           let endDate = lastMeeting.endDate {
            return (endDate, 28800) // Until end of day
        }
        
        return nil
    }
    
    // Analyze meeting load for smart suggestions
    func getMeetingLoad() -> MeetingLoad {
        let meetings = getTodaysMeetings()
        let now = Date()
        
        // Calculate meetings in next 2 hours
        let twoHoursFromNow = now.addingTimeInterval(7200)
        let upcomingMeetings = meetings.filter {
            guard let startDate = $0.startDate else { return false }
            return startDate >= now && startDate <= twoHoursFromNow
        }
        
        // Check if currently in back-to-back meetings
        var hasBackToBack = false
        if meetings.count > 1 {
            for i in 0..<meetings.count - 1 {
                guard let endDate = meetings[i].endDate,
                      let nextStartDate = meetings[i + 1].startDate else { continue }
                if endDate >= now && 
                   nextStartDate <= endDate.addingTimeInterval(300) {
                    hasBackToBack = true
                    break
                }
            }
        }
        
        // Calculate total meeting hours for the ENTIRE day (past + future)
        let totalHours = totalMeetingTimeEntireDay() / 3600
        
        // Also consider total number of meetings
        let meetingCount = meetings.count
        
        if totalHours > 6 || meetingCount >= 8 {
            return .heavy
        } else if totalHours > 4 || meetingCount >= 5 || hasBackToBack {
            return .moderate
        } else if upcomingMeetings.count > 2 || meetingCount >= 3 {
            return .moderate
        } else {
            return .light
        }
    }
    
    // Check if event is within work hours
    private func isWithinWorkHours(_ event: EKEvent) -> Bool {
        guard let startDate = event.startDate else { return false }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: startDate)
        guard let hour = components.hour, let minute = components.minute else { return false }
        
        let eventMinutes = hour * 60 + minute
        let workStartMinutes = workStartHour * 60 + workStartMinute
        let workEndMinutes = workEndHour * 60 + workEndMinute
        
        return eventMinutes >= workStartMinutes && eventMinutes < workEndMinutes
    }
    
    // Helper to determine if an event is a real meeting vs personal time
    private func isRealMeeting(_ event: EKEvent) -> Bool {
        // Skip all-day events
        if event.isAllDay { return false }
        
        let title = event.title?.lowercased() ?? ""
        let location = event.location?.lowercased() ?? ""
        
        // Special case: Focus Time or personal blocks - not real meetings
        let personalBlocks = ["focus time", "focus", "lunch", "break", "personal", "block", "busy", "hold"]
        let isPersonalBlock = personalBlocks.contains { title.contains($0) }
        if isPersonalBlock { return false }
        
        // Check for other participants (more than just yourself)
        // Note: Some calendar systems show yourself as an attendee, so > 1 means others are invited
        let hasOtherParticipants = (event.attendees?.count ?? 0) > 1
        
        // Check for meeting URL in URL field or notes
        let hasURL = event.url != nil || 
                     (event.notes?.range(of: "https?://", options: .regularExpression) != nil)
        
        // Check for common meeting platforms in title or location
        let hasMeetingPlatform = ["zoom", "meet", "teams", "webex", "call", "standup", "sync", "1:1", "one-on-one"]
            .contains { title.contains($0) || location.contains($0) }
        
        // It's a real meeting if it has participants, a URL, or mentions a meeting platform
        return hasOtherParticipants || hasURL || hasMeetingPlatform
    }
    
    deinit {
        eventUpdateTimer?.invalidate()
    }
}

enum MeetingLoad {
    case light
    case moderate
    case heavy
    
    var suggestion: String {
        switch self {
        case .light:
            return "Light meeting day - perfect for a walk!"
        case .moderate:
            return "Busy schedule - grab fresh air between meetings"
        case .heavy:
            return "Meeting heavy - prioritize micro-breaks"
        }
    }
    
    var color: Color {
        switch self {
        case .light:
            return .green
        case .moderate:
            return .orange
        case .heavy:
            return .red
        }
    }
}
