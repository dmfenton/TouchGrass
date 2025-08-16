import Foundation
import Combine

enum WaterUnit: String, CaseIterable, Codable {
    case glasses = "glasses"
    case ounces = "oz"
    case milliliters = "ml"
    
    var displayName: String {
        switch self {
        case .glasses: return "Glasses"
        case .ounces: return "Ounces"
        case .milliliters: return "Milliliters"
        }
    }
    
    func toGlasses(_ amount: Int) -> Double {
        switch self {
        case .glasses: return Double(amount)
        case .ounces: return Double(amount) / 8.0
        case .milliliters: return Double(amount) / 237.0
        }
    }
    
    func fromGlasses(_ glasses: Int) -> Int {
        switch self {
        case .glasses: return glasses
        case .ounces: return glasses * 8
        case .milliliters: return Int(Double(glasses) * 237.0)
        }
    }
}

class WaterTracker: ObservableObject {
    // MARK: - Published Properties
    @Published var isEnabled: Bool = true { didSet { saveSettings() } }
    @Published var dailyGoal: Int = 8 { didSet { saveSettings() } }
    @Published var currentIntake: Int = 0 { didSet { saveSettings() } }
    @Published var unit: WaterUnit = .glasses { didSet { saveSettings() } }
    @Published var streak: Int = 0
    
    // MARK: - Private Properties
    private let defaults: UserDefaults
    private let calendar = Calendar.current
    
    // UserDefaults keys
    private let enabledKey = "TouchGrass.waterEnabled"
    private let goalKey = "TouchGrass.waterGoal"
    private let intakeKey = "TouchGrass.waterIntake"
    private let unitKey = "TouchGrass.waterUnit"
    private let streakKey = "TouchGrass.waterStreak"
    private let lastDateKey = "TouchGrass.lastWaterDate"
    private let yesterdayIntakeKey = "TouchGrass.yesterdayWaterIntake"
    
    // MARK: - Computed Properties
    var dailyOz: Int {
        unit.fromGlasses(currentIntake)
    }
    
    var progressPercentage: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(Double(currentIntake) / Double(dailyGoal), 1.0)
    }
    
    var hasMetDailyGoal: Bool {
        currentIntake >= dailyGoal
    }
    
    var displayText: String {
        let current = unit.fromGlasses(currentIntake)
        let goal = unit.fromGlasses(dailyGoal)
        return "\(current) / \(goal) \(unit.rawValue)"
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
        resetIfNewDay()
    }
    
    // MARK: - Public Methods
    func logWater(_ glasses: Int = 1) {
        currentIntake += glasses
        
        if hasMetDailyGoal {
            updateStreak()
        }
    }
    
    func logWaterInCurrentUnit(_ amount: Int) {
        let glasses = Int(unit.toGlasses(amount))
        logWater(glasses)
    }
    
    func reset() {
        currentIntake = 0
        saveSettings()
    }
    
    // MARK: - Private Methods
    private func resetIfNewDay() {
        let now = Date()
        
        if let lastDate = defaults.object(forKey: lastDateKey) as? Date {
            if !calendar.isDateInToday(lastDate) {
                // Save yesterday's intake
                defaults.set(currentIntake, forKey: yesterdayIntakeKey)
                
                // Check if streak should continue or reset
                if calendar.isDateInYesterday(lastDate) {
                    // Yesterday - check if goal was met
                    if currentIntake < dailyGoal {
                        streak = 0
                        defaults.set(0, forKey: streakKey)
                    }
                } else {
                    // More than a day ago - reset streak
                    streak = 0
                    defaults.set(0, forKey: streakKey)
                }
                
                // Reset for new day
                currentIntake = 0
                defaults.set(0, forKey: intakeKey)
                defaults.set(now, forKey: lastDateKey)
            }
        } else {
            // First run
            defaults.set(now, forKey: lastDateKey)
        }
    }
    
    private func updateStreak() {
        let now = Date()
        
        if let lastDate = defaults.object(forKey: lastDateKey) as? Date {
            if calendar.isDateInToday(lastDate) {
                // Already updated today
                return
            } else if calendar.isDateInYesterday(lastDate) {
                // Continue streak
                streak += 1
            } else {
                // Reset streak
                streak = 1
            }
        } else {
            // First time
            streak = 1
        }
        
        defaults.set(now, forKey: lastDateKey)
        defaults.set(streak, forKey: streakKey)
    }
    
    private func loadSettings() {
        isEnabled = defaults.object(forKey: enabledKey) as? Bool ?? true
        dailyGoal = defaults.object(forKey: goalKey) as? Int ?? 8
        currentIntake = defaults.integer(forKey: intakeKey)
        
        if let unitString = defaults.string(forKey: unitKey),
           let loadedUnit = WaterUnit(rawValue: unitString) {
            unit = loadedUnit
        }
        
        streak = defaults.integer(forKey: streakKey)
    }
    
    private func saveSettings() {
        defaults.set(isEnabled, forKey: enabledKey)
        defaults.set(dailyGoal, forKey: goalKey)
        defaults.set(currentIntake, forKey: intakeKey)
        defaults.set(unit.rawValue, forKey: unitKey)
        defaults.set(streak, forKey: streakKey)
    }
}