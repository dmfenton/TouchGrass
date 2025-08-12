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
    
    // UserDefaults keys
    private let selectedCalendarsKey = "TouchGrass.selectedCalendars"
    
    init() {
        loadSelectedCalendars()
        checkCalendarAccess()
        startEventMonitoring()
        print("[CalendarManager] Initialized with access: \(hasCalendarAccess), calendars: \(selectedCalendarIdentifiers.count)")
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
        guard let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: now) else {
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
        
        // Create predicate for events - check wider time range
        let predicate = eventStore.predicateForEvents(
            withStart: now.addingTimeInterval(-7200), // Check 2 hours back for ongoing events
            end: endOfDay,
            calendars: selectedCalendars
        )
        
        let allEvents = eventStore.events(matching: predicate)
        print("[CalendarManager] Raw events found: \(allEvents.count) (including all-day)")
        
        let events = allEvents
            .filter { !$0.isAllDay } // Exclude all-day events
            .sorted { ($0.startDate ?? Date.distantPast) < ($1.startDate ?? Date.distantPast) }
        
        print("[CalendarManager] Found \(events.count) events for selected calendars")
        print("[CalendarManager] Selected calendar IDs: \(selectedCalendarIdentifiers)")
        
        // Find current event (happening now)
        currentEvent = events.first { event in
            guard let startDate = event.startDate,
                  let endDate = event.endDate else { return false }
            let isCurrent = startDate <= now && endDate > now
            if isCurrent {
                print("[CalendarManager] Current meeting: \(event.title ?? "Unknown") until \(endDate)")
            }
            return isCurrent
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
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let selectedCals = availableCalendars.filter { 
            selectedCalendarIdentifiers.contains($0.calendarIdentifier) 
        }
        
        guard !selectedCals.isEmpty else { return [] }
        
        let predicate = eventStore.predicateForEvents(
            withStart: startOfDay,
            end: endOfDay,
            calendars: selectedCals
        )
        
        return eventStore.events(matching: predicate)
            .filter { !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }
    }
    
    // Calculate total meeting time remaining today
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
        
        // Calculate total meeting hours today
        let totalHours = totalMeetingTimeToday() / 3600
        
        if totalHours > 6 {
            return .heavy
        } else if totalHours > 4 || hasBackToBack {
            return .moderate
        } else if upcomingMeetings.count > 2 {
            return .moderate
        } else {
            return .light
        }
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
