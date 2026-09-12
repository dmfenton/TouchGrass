import UserNotifications
import XCTest
@testable import TouchGrassMobile

@MainActor
private final class FakeNotifications: NotificationScheduling {
    var status: UNAuthorizationStatus = .notDetermined
    var grant = true
    var requests = 0
    var pending: [UNNotificationRequest] = []
    func authorizationStatus() async -> UNAuthorizationStatus { status }
    func requestAuthorization() async throws -> Bool {
        requests += 1
        status = grant ? .authorized : .denied
        return grant
    }
    func removeAllPending() { pending.removeAll() }
    func add(_ request: UNNotificationRequest) async throws { pending.append(request) }
}

final class NotificationPermissionTests: XCTestCase {
    @MainActor
    func testEnablingRequestsPermissionAndDisablingClearsQueue() async {
        let name = UUID().uuidString
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let notifications = FakeNotifications()
        let store = WellnessStore(defaults: defaults, notifications: notifications)
        XCTAssertFalse(store.remindersActive)
        await store.setRemindersEnabled(true)
        XCTAssertEqual(notifications.requests, 1)
        XCTAssertTrue(store.remindersActive)
        XCTAssertFalse(notifications.pending.isEmpty)
        await store.setRemindersEnabled(false)
        XCTAssertFalse(store.remindersActive)
        XCTAssertTrue(notifications.pending.isEmpty)
    }

    @MainActor
    func testDeniedPermissionCannotAppearEnabled() async {
        let name = UUID().uuidString
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let notifications = FakeNotifications()
        notifications.grant = false
        let store = WellnessStore(defaults: defaults, notifications: notifications)
        await store.setRemindersEnabled(true)
        XCTAssertFalse(store.remindersActive)
        XCTAssertFalse(store.preferences.remindersEnabled)
        XCTAssertTrue(notifications.pending.isEmpty)
        XCTAssertNotNil(store.message)
    }

    @MainActor
    func testCompletionAndSnoozeSurviveRelaunch() async {
        let name = UUID().uuidString
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let notifications = FakeNotifications()
        let store = WellnessStore(defaults: defaults, notifications: notifications)
        store.record(breaks: 1)
        XCTAssertNotNil(store.resumeAt)
        XCTAssertGreaterThan(store.resumeAt!.timeIntervalSinceNow, 29 * 60)
        let now = Date()
        store.snooze(now: now)
        XCTAssertEqual(store.resumeAt, now.addingTimeInterval(600))
        await store.refresh()
        let restored = WellnessStore(defaults: defaults, notifications: notifications)
        XCTAssertEqual(restored.resumeAt, store.resumeAt)
        XCTAssertEqual(restored.today.breaks, 1)
    }

    func testPauseTodayUsesLocalMidnightAcrossDaylightSaving() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        let day = calendar.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 0))!
        let next = BreakPlan.nextDay(after: day, calendar: calendar)!
        XCTAssertEqual(next.timeIntervalSince(day), 23 * 3600)
        XCTAssertEqual(calendar.component(.hour, from: next), 0)
        let afternoon = calendar.date(from: DateComponents(year: 2026, month: 9, day: 14, hour: 15))!
        XCTAssertEqual(BreakPlan.nextDay(after: afternoon, calendar: calendar)!.timeIntervalSince(afternoon), 9 * 3600)
    }
}
