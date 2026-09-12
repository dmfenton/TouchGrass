import XCTest
@testable import TouchGrassMobile

final class BreakPlanTests: XCTestCase {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 0)!
        return value
    }
    private func date(_ day: Int = 14, _ hour: Int = 9, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 9, day: day, hour: hour, minute: minute))!
    }
    private var enabled: BreakPreferences {
        var value = BreakPreferences()
        value.remindersEnabled = true
        return value
    }

    func testDisabledAndInvalidSchedulesAreEmpty() {
        XCTAssertTrue(BreakPlan.dates(after: date(), preferences: BreakPreferences(), busy: []).isEmpty)
        var preferences = enabled
        preferences.intervalMinutes = 0
        XCTAssertTrue(BreakPlan.dates(after: date(), preferences: preferences, busy: []).isEmpty)
        preferences = enabled
        preferences.endHour = preferences.startHour
        XCTAssertTrue(BreakPlan.dates(after: date(), preferences: preferences, busy: []).isEmpty)
        XCTAssertTrue(BreakPlan.dates(after: date(), preferences: enabled, busy: [], limit: 0).isEmpty)
    }
    func testClockAlignmentAndQueueLimit() {
        let dates = BreakPlan.dates(after: date(), preferences: enabled, busy: [], calendar: calendar)
        XCTAssertEqual(dates.count, 60)
        XCTAssertEqual(dates.first, date(14, 9, 30))
        XCTAssertTrue(dates.allSatisfy { calendar.component(.hour, from: $0) < 17 })
        XCTAssertTrue(dates.allSatisfy { [2, 3, 4, 5, 6].contains(calendar.component(.weekday, from: $0)) })
    }
    func testMeetingsIncludeBreakDurationAndExcludeEndedMeetings() {
        let busy = [BusyPeriod(start: date(14, 9, 32), end: date(14, 10))]
        let dates = BreakPlan.dates(after: date(), preferences: enabled, busy: busy, calendar: calendar)
        XCTAssertEqual(dates.first, date(14, 10))
    }
    func testPauseSkipsUntilDeadline() {
        let dates = BreakPlan.dates(after: date(), preferences: enabled, busy: [],
                                   pausedUntil: date(14, 11), calendar: calendar)
        XCTAssertEqual(dates.first, date(14, 11))
    }
    func testNoWeekdaysProducesNoReminders() {
        var preferences = enabled
        preferences.weekdays = []
        XCTAssertTrue(BreakPlan.dates(after: date(), preferences: preferences, busy: [], calendar: calendar).isEmpty)
    }
    func testWeekendRollsForward() {
        let dates = BreakPlan.dates(after: date(12), preferences: enabled, busy: [], calendar: calendar)
        XCTAssertEqual(dates.first, date(14))
    }
    func testHydrationUndoMidnightAndStreak() throws {
        var history = ProgressHistory()
        XCTAssertEqual(history.streak(now: date(), calendar: calendar), 0)
        history.record(water: -1, now: date(), calendar: calendar)
        XCTAssertEqual(history.today(now: date(), calendar: calendar).glasses, 0)
        history.record(water: 2, breaks: 1, now: date(), calendar: calendar)
        history.record(breaks: 1, now: date(15), calendar: calendar)
        XCTAssertEqual(history.today(now: date(15), calendar: calendar).glasses, 0)
        XCTAssertEqual(history.streak(now: date(15), calendar: calendar), 2)
        XCTAssertEqual(history.streak(now: date(16), calendar: calendar), 2)
        XCTAssertEqual(history.streak(now: date(17), calendar: calendar), 0)
        let restored = try JSONDecoder().decode(ProgressHistory.self, from: JSONEncoder().encode(history))
        XCTAssertEqual(restored.days, history.days)
    }
    func testHistoryIsBounded() {
        var history = ProgressHistory()
        for offset in 0..<400 {
            history.record(breaks: 1, now: date().addingTimeInterval(Double(offset) * 86_400), calendar: calendar)
        }
        XCTAssertEqual(history.days.count, 366)
    }
    func testPreferencesRoundTrip() throws {
        XCTAssertEqual(try JSONDecoder().decode(BreakPreferences.self, from: JSONEncoder().encode(enabled)), enabled)
    }
}
