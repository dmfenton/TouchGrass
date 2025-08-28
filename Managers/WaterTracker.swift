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

// MARK: - Water Data Model
struct WaterData: Codable {
    var isEnabled: Bool = true
    var dailyGoal: Int = 8
    var currentIntake: Int = 0
    var unit: WaterUnit = .glasses
    var streak: Int = 0
    var lastDate = Date()
    var yesterdayIntake: Int = 0
}

class WaterTracker: ObservableObject {
    // MARK: - Published Properties
    @Published var isEnabled: Bool = true { didSet { saveData() } }
    @Published var dailyGoal: Int = 8 { didSet { saveData() } }
    @Published var currentIntake: Int = 0 { didSet { saveData() } }
    @Published var unit: WaterUnit = .glasses { didSet { saveData() } }
    @Published var streak: Int = 0 { didSet { saveData() } }
    
    // MARK: - Private Properties
    private let storage = StorageManager.shared
    private let calendar = Calendar.current
    private let filename = "water_tracking.json"
    private var waterData = WaterData()
    
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
    init() {
        loadData()
        migrateFromUserDefaults()
        resetIfNewDay()
    }
    
    // MARK: - Public Methods
    func checkForNewDay() {
        resetIfNewDay()
    }
    
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
        saveData()
    }
    
    // MARK: - Private Methods
    private func resetIfNewDay() {
        let now = Date()
        
        if !calendar.isDateInToday(waterData.lastDate) {
            // Save yesterday's intake
            waterData.yesterdayIntake = currentIntake
            
            // Check if streak should continue or reset
            if calendar.isDateInYesterday(waterData.lastDate) {
                // Yesterday - check if goal was met
                if currentIntake < dailyGoal {
                    streak = 0
                }
            } else {
                // More than a day ago - reset streak
                streak = 0
            }
            
            // Reset for new day
            currentIntake = 0
            waterData.lastDate = now
            saveData()
        }
    }
    
    private func updateStreak() {
        let now = Date()
        
        if calendar.isDateInToday(waterData.lastDate) {
            // Already updated today
            return
        } else if calendar.isDateInYesterday(waterData.lastDate) {
            // Continue streak
            streak += 1
        } else {
            // Reset streak
            streak = 1
        }
        
        waterData.lastDate = now
        saveData()
    }
    
    private func loadData() {
        do {
            waterData = try storage.load(WaterData.self, from: filename)
            
            // Update published properties
            isEnabled = waterData.isEnabled
            dailyGoal = waterData.dailyGoal
            currentIntake = waterData.currentIntake
            unit = waterData.unit
            streak = waterData.streak
        } catch {
            // File doesn't exist or is corrupted, use defaults
            saveData() // Save initial data
        }
    }
    
    private func saveData() {
        // Update data model
        waterData.isEnabled = isEnabled
        waterData.dailyGoal = dailyGoal
        waterData.currentIntake = currentIntake
        waterData.unit = unit
        waterData.streak = streak
        
        // Save to file
        do {
            try storage.save(waterData, to: filename)
        } catch {
            // Silent fail - data will be recreated on next launch
        }
    }
    
    private func migrateFromUserDefaults() {
        // Only migrate if we don't have data yet
        if storage.fileExists(filename) { return }
        
        // UserDefaults keys
        let enabledKey = "TouchGrass.waterEnabled"
        let goalKey = "TouchGrass.waterGoal"
        let intakeKey = "TouchGrass.waterIntake"
        let unitKey = "TouchGrass.waterUnit"
        let streakKey = "TouchGrass.waterStreak"
        let lastDateKey = "TouchGrass.lastWaterDate"
        let yesterdayIntakeKey = "TouchGrass.yesterdayWaterIntake"
        
        // Check if there's data to migrate
        let defaults = UserDefaults.standard
        
        if defaults.object(forKey: goalKey) != nil {
            
            // Migrate values
            waterData.isEnabled = defaults.object(forKey: enabledKey) as? Bool ?? true
            waterData.dailyGoal = defaults.object(forKey: goalKey) as? Int ?? 8
            waterData.currentIntake = defaults.integer(forKey: intakeKey)
            waterData.streak = defaults.integer(forKey: streakKey)
            waterData.yesterdayIntake = defaults.integer(forKey: yesterdayIntakeKey)
            
            if let unitString = defaults.string(forKey: unitKey),
               let loadedUnit = WaterUnit(rawValue: unitString) {
                waterData.unit = loadedUnit
            }
            
            if let lastDate = defaults.object(forKey: lastDateKey) as? Date {
                waterData.lastDate = lastDate
            }
            
            // Update published properties
            isEnabled = waterData.isEnabled
            dailyGoal = waterData.dailyGoal
            currentIntake = waterData.currentIntake
            unit = waterData.unit
            streak = waterData.streak
            
            // Save migrated data
            saveData()
            
            // Clean up UserDefaults
            defaults.removeObject(forKey: enabledKey)
            defaults.removeObject(forKey: goalKey)
            defaults.removeObject(forKey: intakeKey)
            defaults.removeObject(forKey: unitKey)
            defaults.removeObject(forKey: streakKey)
            defaults.removeObject(forKey: lastDateKey)
            defaults.removeObject(forKey: yesterdayIntakeKey)
        }
    }
}
