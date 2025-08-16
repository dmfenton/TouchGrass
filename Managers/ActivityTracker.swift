import Foundation
import Combine

/// Manages activity completion tracking and streak management
class ActivityTracker: ObservableObject {
    // MARK: - Published Properties
    @Published var currentStreak: Int = 0
    @Published var bestStreak: Int = 0
    @Published var completedActivities: [String] = []
    @Published var todayCompleted: Bool = false
    
    // MARK: - Private Properties
    private let defaults: UserDefaults
    private let calendar = Calendar.current
    
    // UserDefaults keys
    private let streakKey = "TouchGrass.currentStreak"
    private let bestStreakKey = "TouchGrass.bestStreak"
    private let lastActivityDateKey = "TouchGrass.lastActivityDate"
    private let todayActivitiesKey = "TouchGrass.todayActivities"
    private let activityHistoryKey = "TouchGrass.activityHistory"
    
    // MARK: - Computed Properties
    var hasCompletedToday: Bool {
        guard let lastDate = defaults.object(forKey: lastActivityDateKey) as? Date else {
            return false
        }
        return calendar.isDateInToday(lastDate)
    }
    
    var streakMessage: String {
        if currentStreak == 0 {
            return "Start your streak today!"
        } else if currentStreak == 1 {
            return "1 day streak 🔥"
        } else {
            return "\(currentStreak) day streak 🔥"
        }
    }
    
    // MARK: - Initialization
    init(userDefaults: UserDefaults? = nil) {
        // Use shared suite for persistence across builds
        if let suite = userDefaults ?? UserDefaults(suiteName: "com.touchgrass.shared") {
            self.defaults = suite
        } else {
            self.defaults = UserDefaults.standard
        }
        
        loadSettings()
        checkStreakStatus()
    }
    
    // MARK: - Public Methods
    
    /// Log a completed activity
    func completeActivity(_ activity: String) {
        // Add to today's activities
        completedActivities.append(activity)
        
        // Save to history
        saveActivityToHistory(activity)
        
        // Update streak
        updateStreak(completed: true)
        
        // Mark today as completed
        todayCompleted = true
        defaults.set(Date(), forKey: lastActivityDateKey)
        
        saveSettings()
    }
    
    /// Mark a break as completed (generic completion)
    func completeBreak() {
        updateStreak(completed: true)
        todayCompleted = true
        defaults.set(Date(), forKey: lastActivityDateKey)
        saveSettings()
    }
    
    /// Reset daily tracking (call at start of day)
    func resetDailyTracking() {
        if !calendar.isDateInToday(defaults.object(forKey: lastActivityDateKey) as? Date ?? Date.distantPast) {
            completedActivities.removeAll()
            todayCompleted = false
        }
    }
    
    /// Get activity history for analytics
    func getActivityHistory(days: Int = 30) -> [Date: [String]] {
        guard let history = defaults.dictionary(forKey: activityHistoryKey) as? [String: [String]] else {
            return [:]
        }
        
        var result: [Date: [String]] = [:]
        let formatter = ISO8601DateFormatter()
        
        for (dateString, activities) in history {
            if let date = formatter.date(from: dateString) {
                // Only include recent history
                if calendar.dateComponents([.day], from: date, to: Date()).day ?? 0 <= days {
                    result[date] = activities
                }
            }
        }
        
        return result
    }
    
    // MARK: - Private Methods
    
    private func updateStreak(completed: Bool) {
        let now = Date()
        
        if let lastActivityDate = defaults.object(forKey: lastActivityDateKey) as? Date {
            if calendar.isDateInToday(lastActivityDate) {
                // Already updated today - maintain streak
                return
            } else if calendar.isDateInYesterday(lastActivityDate) && completed {
                // Continuing streak from yesterday
                currentStreak += 1
            } else if completed {
                // Streak was broken, starting new
                currentStreak = 1
            } else {
                // Missed activity
                currentStreak = 0
            }
        } else if completed {
            // First activity
            currentStreak = 1
        }
        
        // Update best streak if needed
        if currentStreak > bestStreak {
            bestStreak = currentStreak
        }
        
        saveSettings()
    }
    
    private func checkStreakStatus() {
        // Check if streak should be reset (missed a day)
        if let lastDate = defaults.object(forKey: lastActivityDateKey) as? Date {
            if !calendar.isDateInToday(lastDate) && !calendar.isDateInYesterday(lastDate) {
                // More than a day has passed - reset streak
                currentStreak = 0
                saveSettings()
            }
        }
        
        // Load today's activities if they exist
        if hasCompletedToday {
            if let activities = defaults.stringArray(forKey: todayActivitiesKey) {
                completedActivities = activities
            }
            todayCompleted = true
        }
    }
    
    private func saveActivityToHistory(_ activity: String) {
        let formatter = ISO8601DateFormatter()
        let dateKey = formatter.string(from: Date())
        
        var history = defaults.dictionary(forKey: activityHistoryKey) as? [String: [String]] ?? [:]
        
        if var todayActivities = history[dateKey] {
            todayActivities.append(activity)
            history[dateKey] = todayActivities
        } else {
            history[dateKey] = [activity]
        }
        
        // Keep only last 90 days of history
        let cutoffDate = calendar.date(byAdding: .day, value: -90, to: Date())!
        history = history.filter { key, _ in
            if let date = formatter.date(from: key) {
                return date > cutoffDate
            }
            return false
        }
        
        defaults.set(history, forKey: activityHistoryKey)
    }
    
    private func loadSettings() {
        currentStreak = defaults.integer(forKey: streakKey)
        bestStreak = defaults.integer(forKey: bestStreakKey)
        
        // Load today's activities if applicable
        if hasCompletedToday,
           let activities = defaults.stringArray(forKey: todayActivitiesKey) {
            completedActivities = activities
            todayCompleted = true
        }
    }
    
    private func saveSettings() {
        defaults.set(currentStreak, forKey: streakKey)
        defaults.set(bestStreak, forKey: bestStreakKey)
        defaults.set(completedActivities, forKey: todayActivitiesKey)
    }
}