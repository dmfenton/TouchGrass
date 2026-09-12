import Foundation

struct BreakPreferences: Codable, Equatable {
    var intervalMinutes = 30
    var startHour = 9
    var endHour = 17
    var weekdays: Set<Int> = [2, 3, 4, 5, 6]
    var waterGoal = 8
    var remindersEnabled = false
    var calendarIDs: Set<String> = []
}

struct BusyPeriod: Equatable {
    let start: Date
    let end: Date
}

enum BreakPlan {
    static func nextDay(after date: Date, calendar: Calendar = .current) -> Date? {
        calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date))
    }

    /// A bounded rolling schedule. Refresh on foreground and calendar changes.
    static func dates(
        after now: Date, preferences: BreakPreferences, busy: [BusyPeriod],
        pausedUntil: Date? = nil, resumeAt: Date? = nil, calendar: Calendar = .current, limit: Int = 60
    ) -> [Date] {
        guard preferences.remindersEnabled, preferences.intervalMinutes > 0,
              preferences.startHour < preferences.endHour, limit > 0 else { return [] }
        var result: [Date] = []
        for offset in 0..<14 {
            if result.count == limit { break }
            guard let day = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: now)),
                  preferences.weekdays.contains(calendar.component(.weekday, from: day)) else { continue }
            for minute in stride(
                from: preferences.startHour * 60,
                to: preferences.endHour * 60,
                by: preferences.intervalMinutes
            ) {
                guard let date = calendar.date(bySettingHour: minute / 60, minute: minute % 60, second: 0, of: day),
                      date > now, date >= (pausedUntil ?? now),
                      !busy.contains(where: { $0.start < date.addingTimeInterval(180) && $0.end > date })
                else { continue }
                result.append(date)
                if result.count == limit { break }
            }
        }
        if let resumeAt, resumeAt > now {
            let earliest = max(resumeAt, pausedUntil ?? resumeAt)
            let end = calendar.date(byAdding: .day, value: 14, to: now) ?? earliest
            var candidate = earliest
            while candidate < end {
                let hour = calendar.component(.hour, from: candidate)
                if preferences.weekdays.contains(calendar.component(.weekday, from: candidate)),
                   hour >= preferences.startHour, hour < preferences.endHour,
                   !busy.contains(where: { $0.start < candidate.addingTimeInterval(180) && $0.end > candidate }) {
                    result = result.filter { $0 >= candidate.addingTimeInterval(Double(preferences.intervalMinutes) * 60) }
                    return Array(([candidate] + result).prefix(limit))
                }
                candidate = candidate.addingTimeInterval(60)
            }
            return []
        }
        return result
    }
}

struct DailyProgress: Codable, Equatable {
    var day: Date
    var glasses = 0
    var breaks = 0
}

struct ProgressHistory: Codable {
    var days: [DailyProgress] = []

    func today(now: Date = Date(), calendar: Calendar = .current) -> DailyProgress {
        days.first { calendar.isDate($0.day, inSameDayAs: now) }
            ?? DailyProgress(day: calendar.startOfDay(for: now))
    }

    mutating func record(water: Int = 0, breaks: Int = 0, now: Date = Date(), calendar: Calendar = .current) {
        var entry = today(now: now, calendar: calendar)
        entry.glasses = max(0, entry.glasses + water)
        entry.breaks = max(0, entry.breaks + breaks)
        days.removeAll { calendar.isDate($0.day, inSameDayAs: now) }
        days.append(entry)
        days.sort { $0.day > $1.day }
        days = Array(days.prefix(366))
    }

    func streak(now: Date = Date(), calendar: Calendar = .current,
                weekdays: Set<Int> = Set(1...7)) -> Int {
        var count = 0
        let start = today(now: now, calendar: calendar).breaks > 0 ? 0 : 1
        for offset in start..<367 {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: now) else { break }
            guard weekdays.contains(calendar.component(.weekday, from: date)) else { continue }
            guard days.contains(where: { calendar.isDate($0.day, inSameDayAs: date) && $0.breaks > 0 })
            else { break }
            count += 1
        }
        return count
    }
}
