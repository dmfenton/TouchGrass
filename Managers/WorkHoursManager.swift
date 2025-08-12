import Foundation

public enum WorkDay: String, CaseIterable {
    case sunday, monday, tuesday, wednesday, thursday, friday, saturday
}

/// Manages work hours configuration and scheduling
final class WorkHoursManager {
    // Work hours configuration
    private var workStartHour = 9
    private var workStartMinute = 0
    private var workEndHour = 17
    private var workEndMinute = 0
    private var workDays: Set<WorkDay> = [.monday, .tuesday, .wednesday, .thursday, .friday]
    
    // UserDefaults keys
    private let workStartTimeKey = "TouchGrass.workStartTime"
    private let workEndTimeKey = "TouchGrass.workEndTime"
    private let workDaysKey = "TouchGrass.workDays"
    
    // Public getters for work hours
    var currentWorkStartHour: Int { workStartHour }
    var currentWorkStartMinute: Int { workStartMinute }
    var currentWorkEndHour: Int { workEndHour }
    var currentWorkEndMinute: Int { workEndMinute }
    var currentWorkDays: Set<WorkDay> { workDays }
    
    init() {
        loadWorkHours()
    }
    
    func setWorkHours(start: (hour: Int, minute: Int), end: (hour: Int, minute: Int), days: Set<WorkDay>) {
        workStartHour = start.hour
        workStartMinute = start.minute
        workEndHour = end.hour
        workEndMinute = end.minute
        workDays = days
        saveWorkHours()
    }
    
    func isWithinWorkHours() -> Bool {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentWeekday = calendar.component(.weekday, from: now)
        
        // Check if today is a work day
        let todayWorkDay = workDayFromWeekday(currentWeekday)
        guard let todayWorkDay = todayWorkDay, workDays.contains(todayWorkDay) else {
            return false
        }
        
        // Check if current time is within work hours
        let currentTimeInMinutes = currentHour * 60 + currentMinute
        let workStartInMinutes = workStartHour * 60 + workStartMinute
        let workEndInMinutes = workEndHour * 60 + workEndMinute
        
        return currentTimeInMinutes >= workStartInMinutes && currentTimeInMinutes < workEndInMinutes
    }
    
    func nextWorkHourDate() -> Date? {
        let calendar = Calendar.current
        let now = Date()
        
        // Start checking from tomorrow to find the next work day
        for dayOffset in 1...7 {
            let checkDate = calendar.date(byAdding: .day, value: dayOffset, to: now) ?? now
            let weekday = calendar.component(.weekday, from: checkDate)
            
            if let workDay = workDayFromWeekday(weekday), workDays.contains(workDay) {
                var components = calendar.dateComponents([.year, .month, .day], from: checkDate)
                components.hour = workStartHour
                components.minute = workStartMinute
                return calendar.date(from: components)
            }
        }
        
        return nil
    }
    
    private func loadWorkHours() {
        let defaults = UserDefaults.standard
        
        // Load work start time
        if let startData = defaults.data(forKey: workStartTimeKey),
           let startComponents = try? JSONDecoder().decode(DateComponents.self, from: startData) {
            workStartHour = startComponents.hour ?? 9
            workStartMinute = startComponents.minute ?? 0
        }
        
        // Load work end time
        if let endData = defaults.data(forKey: workEndTimeKey),
           let endComponents = try? JSONDecoder().decode(DateComponents.self, from: endData) {
            workEndHour = endComponents.hour ?? 17
            workEndMinute = endComponents.minute ?? 0
        }
        
        // Load work days
        if let workDayStrings = defaults.array(forKey: workDaysKey) as? [String] {
            workDays = Set(workDayStrings.compactMap { WorkDay(rawValue: $0) })
        }
    }
    
    private func saveWorkHours() {
        let defaults = UserDefaults.standard
        
        // Save work start time
        var startComponents = DateComponents()
        startComponents.hour = workStartHour
        startComponents.minute = workStartMinute
        defaults.set(try? JSONEncoder().encode(startComponents), forKey: workStartTimeKey)
        
        // Save work end time
        var endComponents = DateComponents()
        endComponents.hour = workEndHour
        endComponents.minute = workEndMinute
        defaults.set(try? JSONEncoder().encode(endComponents), forKey: workEndTimeKey)
        
        // Save work days
        let workDayStrings = workDays.map { $0.rawValue }
        defaults.set(workDayStrings, forKey: workDaysKey)
    }
    
    private func workDayFromWeekday(_ weekday: Int) -> WorkDay? {
        switch weekday {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return nil
        }
    }
}
