import Foundation
import EventKit
import Combine

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
        
        // Create predicate for events
        let predicate = eventStore.predicateForEvents(
            withStart: now.addingTimeInterval(-3600), // Check 1 hour back for ongoing events
            end: endOfDay,
            calendars: selectedCalendars
        )
        
        let events = eventStore.events(matching: predicate)
            .filter { !$0.isAllDay } // Exclude all-day events
            .sorted { $0.startDate < $1.startDate }
        
        // Find current event (happening now)
        currentEvent = events.first { event in
            event.startDate <= now && event.endDate > now
        }
        
        isInMeeting = currentEvent != nil
        
        // Find next event (after current time or after current event)
        let searchAfter = currentEvent?.endDate ?? now
        nextEvent = events.first { event in
            event.startDate > searchAfter
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
    
    func formatEventTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter.string(from: date)
    }
    
    deinit {
        eventUpdateTimer?.invalidate()
    }
}
