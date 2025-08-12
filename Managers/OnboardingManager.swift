import Foundation
import SwiftUI

final class OnboardingManager: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var workStartHour: Int = 9
    @Published var workStartMinute: Int = 0
    @Published var workEndHour: Int = 17
    @Published var workEndMinute: Int = 0
    @Published var reminderInterval: Double = 45
    @Published var enableSmartTiming: Bool = true
    @Published var startAtLogin: Bool = false
    
    private let hasCompletedOnboardingKey = "TouchGrass.hasCompletedOnboarding"
    private let workStartTimeKey = "TouchGrass.workStartTime"
    private let workEndTimeKey = "TouchGrass.workEndTime"
    private let workDaysKey = "TouchGrass.workDays"
    
    @Published var workDays: Set<WorkDay> = [.monday, .tuesday, .wednesday, .thursday, .friday]
    
    enum OnboardingStep: Int, CaseIterable {
        case welcome = 0
        case workHours
        case reminderSettings
        case permissions
        case complete
        
        var title: String {
            switch self {
            case .welcome: return "Welcome to Touch Grass"
            case .workHours: return "Set Your Work Hours"
            case .reminderSettings: return "Configure Reminders"
            case .permissions: return "Enable Notifications"
            case .complete: return "You're All Set!"
            }
        }
        
        var systemIcon: String {
            switch self {
            case .welcome: return "figure.walk"
            case .workHours: return "clock"
            case .reminderSettings: return "bell"
            case .permissions: return "checkmark.shield"
            case .complete: return "sparkles"
            }
        }
    }
    
    enum WorkDay: String, CaseIterable {
        case sunday, monday, tuesday, wednesday, thursday, friday, saturday
        
        var displayName: String {
            switch self {
            case .sunday: return "Sun"
            case .monday: return "Mon"
            case .tuesday: return "Tue"
            case .wednesday: return "Wed"
            case .thursday: return "Thu"
            case .friday: return "Fri"
            case .saturday: return "Sat"
            }
        }
    }
    
    init() {
        setIntelligentDefaults()
    }
    
    var hasCompletedOnboarding: Bool {
        UserDefaults.standard.bool(forKey: hasCompletedOnboardingKey)
    }
    
    func nextStep() {
        if let nextIndex = OnboardingStep.allCases.firstIndex(of: currentStep).map({ $0 + 1 }),
           nextIndex < OnboardingStep.allCases.count {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = OnboardingStep.allCases[nextIndex]
            }
        }
    }
    
    func previousStep() {
        if let prevIndex = OnboardingStep.allCases.firstIndex(of: currentStep).map({ $0 - 1 }),
           prevIndex >= 0 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = OnboardingStep.allCases[prevIndex]
            }
        }
    }
    
    func completeOnboarding() {
        saveSettings()
        UserDefaults.standard.set(true, forKey: hasCompletedOnboardingKey)
    }
    
    private func setIntelligentDefaults() {
        let timeZone = TimeZone.current
        let locale = Locale.current
        
        // Adjust work hours based on time zone offset from UTC
        // Most western time zones tend to start work at 9am
        // Some eastern time zones might start earlier
        let hoursFromUTC = timeZone.secondsFromGMT() / 3600
        
        if hoursFromUTC >= 5 && hoursFromUTC <= 10 {
            // Asian time zones (often start earlier)
            workStartHour = 8
            workEndHour = 17
        } else if hoursFromUTC >= -1 && hoursFromUTC <= 3 {
            // European time zones
            workStartHour = 9
            workEndHour = 18
        } else {
            // Americas and others
            workStartHour = 9
            workEndHour = 17
        }
        
        // Check if locale suggests different work week
        if locale.identifier.contains("IL") || locale.identifier.contains("SA") {
            // Israel, Saudi Arabia - Sunday to Thursday
            workDays = [.sunday, .monday, .tuesday, .wednesday, .thursday]
        } else if locale.identifier.contains("AE") || locale.identifier.contains("EG") {
            // UAE, Egypt - Sunday to Thursday is common
            workDays = [.sunday, .monday, .tuesday, .wednesday, .thursday]
        } else {
            // Default to Monday-Friday
            workDays = [.monday, .tuesday, .wednesday, .thursday, .friday]
        }
    }
    
    private func saveSettings() {
        let defaults = UserDefaults.standard
        
        // Save work hours as date components
        var startComponents = DateComponents()
        startComponents.hour = workStartHour
        startComponents.minute = workStartMinute
        defaults.set(try? JSONEncoder().encode(startComponents), forKey: workStartTimeKey)
        
        var endComponents = DateComponents()
        endComponents.hour = workEndHour
        endComponents.minute = workEndMinute
        defaults.set(try? JSONEncoder().encode(endComponents), forKey: workEndTimeKey)
        
        // Save work days
        let workDayStrings = workDays.map { $0.rawValue }
        defaults.set(workDayStrings, forKey: workDaysKey)
        
        // Save reminder settings
        defaults.set(reminderInterval, forKey: "TouchGrass.intervalMinutes")
        defaults.set(enableSmartTiming, forKey: "TouchGrass.adaptiveEnabled")
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
        let currentMinutes = currentHour * 60 + currentMinute
        let startMinutes = workStartHour * 60 + workStartMinute
        let endMinutes = workEndHour * 60 + workEndMinute
        
        return currentMinutes >= startMinutes && currentMinutes <= endMinutes
    }
    
    private func workDayFromWeekday(_ weekday: Int) -> WorkDay? {
        // Calendar weekday: 1 = Sunday, 2 = Monday, etc.
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