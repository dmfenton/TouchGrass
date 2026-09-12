import EventKit
import Foundation
import UserNotifications

@MainActor
final class WellnessStore: ObservableObject {
    @Published var preferences: BreakPreferences
    @Published private(set) var history: ProgressHistory
    @Published private(set) var nextBreak: Date?
    @Published private(set) var notificationStatus = UNAuthorizationStatus.notDetermined
    @Published private(set) var calendars: [EKCalendar] = []
    @Published var message: String?
    @Published var pausedUntil: Date?
    @Published private(set) var resumeAt: Date?
    @Published private(set) var scheduledThrough: Date?
    private let defaults: UserDefaults
    private let events = EKEventStore()
    private let notifications: NotificationScheduling
    private var refreshTask: Task<Void, Never>?

    init(defaults: UserDefaults = .standard, notifications: NotificationScheduling? = nil) {
        self.notifications = notifications ?? DeviceNotifications()
        self.defaults = ProcessInfo.processInfo.arguments.contains("--ui-testing")
            ? UserDefaults(suiteName: "TouchGrass.UITests") ?? defaults : defaults
        if ProcessInfo.processInfo.arguments.contains("--reset-ui-tests") {
            self.defaults.removePersistentDomain(forName: "TouchGrass.UITests")
        }
        preferences = self.defaults.data(forKey: "mobile.preferences")
            .flatMap { try? JSONDecoder().decode(BreakPreferences.self, from: $0) } ?? BreakPreferences()
        history = self.defaults.data(forKey: "mobile.history")
            .flatMap { try? JSONDecoder().decode(ProgressHistory.self, from: $0) } ?? ProgressHistory()
        resumeAt = self.defaults.object(forKey: "mobile.resumeAt") as? Date
        pausedUntil = self.defaults.object(forKey: "mobile.pausedUntil") as? Date
    }

    var remindersActive: Bool {
        preferences.remindersEnabled && (notificationStatus == .authorized || notificationStatus == .provisional)
    }

    var today: DailyProgress { history.today() }
    var streak: Int { history.streak(weekdays: preferences.weekdays) }

    func record(water: Int = 0, breaks: Int = 0) {
        history.record(water: water, breaks: breaks)
        if breaks > 0 {
            resumeAt = Date().addingTimeInterval(Double(preferences.intervalMinutes) * 60)
            scheduleRefresh()
        }
        persist()
    }

    func snooze(now: Date = Date()) {
        pausedUntil = nil
        resumeAt = now.addingTimeInterval(600)
        persist()
        scheduleRefresh()
    }

    func persist() {
        do {
            defaults.set(try JSONEncoder().encode(preferences), forKey: "mobile.preferences")
            defaults.set(try JSONEncoder().encode(history), forKey: "mobile.history")
            defaults.set(resumeAt, forKey: "mobile.resumeAt")
            defaults.set(pausedUntil, forKey: "mobile.pausedUntil")
        } catch { message = "Your changes could not be saved. Please try again." }
    }

    func enableNotifications() async {
        do {
            preferences.remindersEnabled = try await notifications.requestAuthorization()
            if !preferences.remindersEnabled { message = "Allow notifications in Settings to receive break reminders." }
            persist()
            await refresh()
        } catch { message = "Notifications could not be enabled. Please try again." }
    }

    func enableCalendar() async {
        do {
            guard try await events.requestFullAccessToEvents() else {
                message = "Calendar access is off. You can enable it in Settings."
                return
            }
            calendars = events.calendars(for: .event)
            if !defaults.bool(forKey: "mobile.calendarConfigured") {
                preferences.calendarIDs = Set(calendars.map(\.calendarIdentifier))
                defaults.set(true, forKey: "mobile.calendarConfigured")
            }
            persist()
            await refresh()
        } catch { message = "Calendars could not be read. Please try again." }
    }

    func setRemindersEnabled(_ enabled: Bool) async {
        if enabled { await enableNotifications() } else {
            preferences.remindersEnabled = false
            await refresh()
        }
    }

    func pauseToday(now: Date = Date(), calendar: Calendar = .current) {
        resumeAt = nil
        pausedUntil = BreakPlan.nextDay(after: now, calendar: calendar)
        persist()
        scheduleRefresh()
    }

    func pause(minutes: Int?) {
        resumeAt = nil
        pausedUntil = minutes.map { Date().addingTimeInterval(Double($0) * 60) }
        persist()
        scheduleRefresh()
    }

    func scheduleRefresh() {
        Task { await refresh() }
    }

    func refresh() async {
        let previous = refreshTask
        let next = Task {
            await previous?.value
            await rebuildSchedule()
        }
        refreshTask = next
        await next.value
    }

    private func rebuildSchedule() async {
        persist()
        notificationStatus = await notifications.authorizationStatus()
        guard !Task.isCancelled else { return }
        objectWillChange.send()
        let now = Date()
        var busy: [BusyPeriod] = []
        if EKEventStore.authorizationStatus(for: .event) == .fullAccess {
            calendars = events.calendars(for: .event)
            let selected = calendars.filter { preferences.calendarIDs.contains($0.calendarIdentifier) }
            if !selected.isEmpty {
                let end = Calendar.current.date(byAdding: .day, value: 14, to: now) ?? now
                let predicate = events.predicateForEvents(withStart: now, end: end, calendars: selected)
                busy = events.events(matching: predicate)
                    .filter { !$0.isAllDay && $0.availability != .free && $0.status != .canceled }
                    .map { BusyPeriod(start: $0.startDate, end: $0.endDate) }
            }
        }
        let allowed = notificationStatus == .authorized || notificationStatus == .provisional
        let dates = allowed ? BreakPlan.dates(
            after: now, preferences: preferences, busy: busy, pausedUntil: pausedUntil, resumeAt: resumeAt
        ) : []
        notifications.removeAllPending()
        nextBreak = nil
        scheduledThrough = nil
        do {
            for date in dates {
                guard !Task.isCancelled else { return }
                let content = UNMutableNotificationContent()
                content.title = "Time for a little reset"
                content.body = "Step outside, stretch, or take a drink of water."
                content.sound = .default
                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
                let request = UNNotificationRequest(
                    identifier: "break-\(Int(date.timeIntervalSince1970))", content: content,
                    trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                )
                try await notifications.add(request)
                if nextBreak == nil { nextBreak = date }
                scheduledThrough = date
            }
        } catch { message = "Some reminders could not be scheduled. Open the app to try again." }
    }
}
