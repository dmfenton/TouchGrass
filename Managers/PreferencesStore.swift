import Foundation

/**
 * Centralized preferences store for Touch Grass
 * 
 * Provides type-safe access to UserDefaults with consistent key management
 * and support for both shared suite and standard UserDefaults
 */
final class PreferencesStore: ObservableObject {
    
    // MARK: - Singleton
    static let shared = PreferencesStore()
    
    // MARK: - UserDefaults Configuration
    
    /// Shared UserDefaults suite that persists across bundle ID changes
    private let sharedDefaults: UserDefaults = {
        if let suite = UserDefaults(suiteName: "com.touchgrass.shared") {
            return suite
        } else {
            return UserDefaults.standard
        }
    }()
    
    /// Standard UserDefaults for app-specific settings
    private let standardDefaults = UserDefaults.standard
    
    // MARK: - Property Wrapper for Type-Safe Preferences
    
    @propertyWrapper
    struct Preference<T> {
        let key: String
        let defaultValue: T
        let store: UserDefaults
        
        var wrappedValue: T {
            get {
                if let value = store.object(forKey: key) as? T {
                    return value
                } else {
                    return defaultValue
                }
            }
            set {
                store.set(newValue, forKey: key)
            }
        }
    }
    
    @propertyWrapper
    struct OptionalPreference<T> {
        let key: String
        let store: UserDefaults
        
        var wrappedValue: T? {
            get {
                return store.object(forKey: key) as? T
            }
            set {
                if let value = newValue {
                    store.set(value, forKey: key)
                } else {
                    store.removeObject(forKey: key)
                }
            }
        }
    }
    
    // MARK: - Preference Keys
    
    private struct Keys {
        // Reminder Settings (Shared Suite)
        static let intervalMinutes = "TouchGrass.intervalMinutes"
        static let adaptiveEnabled = "TouchGrass.adaptiveEnabled"
        static let smartSchedulingEnabled = "TouchGrass.smartSchedulingEnabled"
        
        // Legacy work hours keys (to be migrated)
        static let workStartHour = "TouchGrass.workStartHour"
        static let workEndHour = "TouchGrass.workEndHour"
        
        // Work Hours Settings (Standard)
        static let workStartTime = "TouchGrass.workStartTime"
        static let workEndTime = "TouchGrass.workEndTime"
        static let workDays = "TouchGrass.workDays"
        
        // App Settings (Standard)
        static let startsAtLogin = "TouchGrass.startsAtLogin"
        static let hasCompletedOnboarding = "TouchGrass.hasCompletedOnboarding"
        
        // Calendar Settings (Shared Suite)
        static let selectedCalendars = "TouchGrass.selectedCalendars"
        
        // Water Tracking (Shared Suite)
        static let waterEnabled = "TouchGrass.waterEnabled"
        static let waterGoal = "TouchGrass.waterGoal"
        static let waterIntake = "TouchGrass.waterIntake"
        static let waterUnit = "TouchGrass.waterUnit"
        static let waterStreak = "TouchGrass.waterStreak"
        static let lastWaterDate = "TouchGrass.lastWaterDate"
        static let yesterdayWaterIntake = "TouchGrass.yesterdayWaterIntake"
        
        // Activity Tracking (Shared Suite)
        static let currentStreak = "TouchGrass.currentStreak"
        static let bestStreak = "TouchGrass.bestStreak"
        static let lastActivityDate = "TouchGrass.lastActivityDate"
        static let todayActivities = "TouchGrass.todayActivities"
        static let activityHistory = "TouchGrass.activityHistory"
        
        // Update Settings (Standard)
        static let autoUpdateEnabled = "TouchGrass.autoUpdateEnabled"
        static let lastUpdateCheck = "TouchGrass.lastUpdateCheck"
        static let skipVersion = "TouchGrass.skipVersion"
    }
    
    // MARK: - Reminder Settings (Shared Suite)
    
    @Preference(key: Keys.intervalMinutes, defaultValue: 45, store: PreferencesStore.shared.sharedDefaults)
    var intervalMinutes: Int
    
    @Preference(key: Keys.adaptiveEnabled, defaultValue: true, store: PreferencesStore.shared.sharedDefaults)
    var adaptiveEnabled: Bool
    
    @Preference(key: Keys.smartSchedulingEnabled, defaultValue: true, store: PreferencesStore.shared.sharedDefaults)
    var smartSchedulingEnabled: Bool
    
    // MARK: - Work Hours Settings (Standard)
    
    @OptionalPreference<Double>(key: Keys.workStartTime, store: PreferencesStore.shared.standardDefaults)
    var workStartTime: Double?
    
    @OptionalPreference<Double>(key: Keys.workEndTime, store: PreferencesStore.shared.standardDefaults)
    var workEndTime: Double?
    
    @OptionalPreference<Data>(key: Keys.workDays, store: PreferencesStore.shared.standardDefaults)
    var workDaysData: Data?
    
    // MARK: - App Settings (Standard)
    
    @Preference(key: Keys.startsAtLogin, defaultValue: false, store: PreferencesStore.shared.standardDefaults)
    var startsAtLogin: Bool
    
    @Preference(key: Keys.hasCompletedOnboarding, defaultValue: false, store: PreferencesStore.shared.standardDefaults)
    var hasCompletedOnboarding: Bool
    
    // MARK: - Calendar Settings (Shared Suite)
    
    @OptionalPreference<Data>(key: Keys.selectedCalendars, store: PreferencesStore.shared.sharedDefaults)
    var selectedCalendarsData: Data?
    
    // MARK: - Water Tracking (Shared Suite)
    
    @Preference(key: Keys.waterEnabled, defaultValue: true, store: PreferencesStore.shared.sharedDefaults)
    var waterEnabled: Bool
    
    @Preference(key: Keys.waterGoal, defaultValue: 8, store: PreferencesStore.shared.sharedDefaults)
    var waterGoal: Int
    
    @Preference(key: Keys.waterIntake, defaultValue: 0, store: PreferencesStore.shared.sharedDefaults)
    var waterIntake: Int
    
    @Preference(key: Keys.waterUnit, defaultValue: "glasses", store: PreferencesStore.shared.sharedDefaults)
    var waterUnit: String
    
    @Preference(key: Keys.waterStreak, defaultValue: 0, store: PreferencesStore.shared.sharedDefaults)
    var waterStreak: Int
    
    @OptionalPreference<String>(key: Keys.lastWaterDate, store: PreferencesStore.shared.sharedDefaults)
    var lastWaterDate: String?
    
    @Preference(key: Keys.yesterdayWaterIntake, defaultValue: 0, store: PreferencesStore.shared.sharedDefaults)
    var yesterdayWaterIntake: Int
    
    // MARK: - Activity Tracking (Shared Suite)
    
    @Preference(key: Keys.currentStreak, defaultValue: 0, store: PreferencesStore.shared.sharedDefaults)
    var currentStreak: Int
    
    @Preference(key: Keys.bestStreak, defaultValue: 0, store: PreferencesStore.shared.sharedDefaults)
    var bestStreak: Int
    
    @OptionalPreference<String>(key: Keys.lastActivityDate, store: PreferencesStore.shared.sharedDefaults)
    var lastActivityDate: String?
    
    @Preference(key: Keys.todayActivities, defaultValue: 0, store: PreferencesStore.shared.sharedDefaults)
    var todayActivities: Int
    
    @OptionalPreference<Data>(key: Keys.activityHistory, store: PreferencesStore.shared.sharedDefaults)
    var activityHistoryData: Data?
    
    // MARK: - Update Settings (Standard)
    
    @Preference(key: Keys.autoUpdateEnabled, defaultValue: true, store: PreferencesStore.shared.standardDefaults)
    var autoUpdateEnabled: Bool
    
    @OptionalPreference<Date>(key: Keys.lastUpdateCheck, store: PreferencesStore.shared.standardDefaults)
    var lastUpdateCheck: Date?
    
    @OptionalPreference<String>(key: Keys.skipVersion, store: PreferencesStore.shared.standardDefaults)
    var skipVersion: String?
    
    // MARK: - Initialization
    
    private init() {
        performMigrations()
    }
    
    // MARK: - Migration Support
    
    private func performMigrations() {
        migrateWorkHoursSettings()
    }
    
    /// Migrate legacy work hours settings from shared to standard defaults
    private func migrateWorkHoursSettings() {
        // Check if we have legacy work hour settings in shared defaults
        if let legacyStartHour = sharedDefaults.object(forKey: Keys.workStartHour) as? Int,
           let legacyEndHour = sharedDefaults.object(forKey: Keys.workEndHour) as? Int {
            
            // Convert hour-only settings to time-based settings
            if workStartTime == nil {
                workStartTime = Double(legacyStartHour * 3600) // Convert hours to seconds from midnight
            }
            
            if workEndTime == nil {
                workEndTime = Double(legacyEndHour * 3600) // Convert hours to seconds from midnight
            }
            
            // Remove legacy keys
            sharedDefaults.removeObject(forKey: Keys.workStartHour)
            sharedDefaults.removeObject(forKey: Keys.workEndHour)
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Get the UserDefaults instance for shared preferences
    func getSharedDefaults() -> UserDefaults {
        return sharedDefaults
    }
    
    /// Get the UserDefaults instance for standard preferences
    func getStandardDefaults() -> UserDefaults {
        return standardDefaults
    }
    
    /// Reset all preferences to defaults
    func resetToDefaults() {
        // Remove all TouchGrass keys from both stores
        removeAllTouchGrassKeys(from: sharedDefaults)
        removeAllTouchGrassKeys(from: standardDefaults)
    }
    
    private func removeAllTouchGrassKeys(from defaults: UserDefaults) {
        let allKeys = [
            Keys.intervalMinutes, Keys.adaptiveEnabled, Keys.smartSchedulingEnabled,
            Keys.workStartHour, Keys.workEndHour, Keys.workStartTime, Keys.workEndTime, Keys.workDays,
            Keys.startsAtLogin, Keys.hasCompletedOnboarding, Keys.selectedCalendars,
            Keys.waterEnabled, Keys.waterGoal, Keys.waterIntake, Keys.waterUnit, 
            Keys.waterStreak, Keys.lastWaterDate, Keys.yesterdayWaterIntake,
            Keys.currentStreak, Keys.bestStreak, Keys.lastActivityDate, 
            Keys.todayActivities, Keys.activityHistory,
            Keys.autoUpdateEnabled, Keys.lastUpdateCheck, Keys.skipVersion
        ]
        
        for key in allKeys {
            defaults.removeObject(forKey: key)
        }
    }
    
    // MARK: - Debug Information
    
    /// Get all current preference values for debugging
    func getAllPreferences() -> [String: Any] {
        var preferences: [String: Any] = [:]
        
        // Shared preferences
        preferences["intervalMinutes"] = intervalMinutes
        preferences["adaptiveEnabled"] = adaptiveEnabled
        preferences["smartSchedulingEnabled"] = smartSchedulingEnabled
        preferences["waterEnabled"] = waterEnabled
        preferences["waterGoal"] = waterGoal
        preferences["waterIntake"] = waterIntake
        preferences["waterUnit"] = waterUnit
        preferences["waterStreak"] = waterStreak
        preferences["lastWaterDate"] = lastWaterDate ?? "nil"
        preferences["yesterdayWaterIntake"] = yesterdayWaterIntake
        preferences["currentStreak"] = currentStreak
        preferences["bestStreak"] = bestStreak
        preferences["lastActivityDate"] = lastActivityDate ?? "nil"
        preferences["todayActivities"] = todayActivities
        
        // Standard preferences
        preferences["workStartTime"] = workStartTime ?? "nil"
        preferences["workEndTime"] = workEndTime ?? "nil"
        preferences["startsAtLogin"] = startsAtLogin
        preferences["hasCompletedOnboarding"] = hasCompletedOnboarding
        preferences["autoUpdateEnabled"] = autoUpdateEnabled
        preferences["lastUpdateCheck"] = lastUpdateCheck?.description ?? "nil"
        preferences["skipVersion"] = skipVersion ?? "nil"
        
        return preferences
    }
}

// MARK: - Type-Safe Extensions

extension PreferencesStore {
    
    /// Get work days as a Set<WorkDay>
    var workDays: Set<WorkDay> {
        get {
            guard let data = workDaysData,
                  let days = try? JSONDecoder().decode(Set<WorkDay>.self, from: data) else {
                return [.monday, .tuesday, .wednesday, .thursday, .friday] // Default work days
            }
            return days
        }
        set {
            workDaysData = try? JSONEncoder().encode(newValue)
        }
    }
    
    /// Get selected calendars as array of strings
    var selectedCalendars: [String] {
        get {
            guard let data = selectedCalendarsData,
                  let calendars = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return calendars
        }
        set {
            selectedCalendarsData = try? JSONEncoder().encode(newValue)
        }
    }
    
    /// Get activity history as dictionary
    var activityHistory: [String: Int] {
        get {
            guard let data = activityHistoryData,
                  let history = try? JSONDecoder().decode([String: Int].self, from: data) else {
                return [:]
            }
            return history
        }
        set {
            activityHistoryData = try? JSONEncoder().encode(newValue)
        }
    }
}

// MARK: - WorkDay Codable Extension

extension WorkDay: Codable {
    // WorkDay enum is defined in WorkHoursManager.swift
    // This extension adds Codable conformance for JSON encoding/decoding
}
