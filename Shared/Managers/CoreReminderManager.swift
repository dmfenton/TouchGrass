import Foundation
import Combine

// Shared core logic for both macOS and iOS
class CoreReminderManager: ObservableObject {
    // Core properties shared between platforms
    @Published var isPaused = false
    @Published var intervalMinutes: Double = 45
    @Published var timeUntilNextReminder: TimeInterval = 0
    @Published var currentStreak: Int = 0
    @Published var bestStreak: Int = 0
    @Published var hasActiveReminder = false
    
    // Water tracking
    @Published var waterTrackingEnabled: Bool = true
    @Published var dailyWaterGoal: Int = 8
    @Published var currentWaterIntake: Int = 0
    @Published var waterUnit: WaterUnit = .glasses
    @Published var waterStreak: Int = 0
    
    // Completed activities
    @Published var completedActivities: [String] = []
    
    // Timers
    private var reminderTimer: Timer?
    private var countdownTimer: Timer?
    
    init() {
        loadSettings()
        scheduleNextReminder()
    }
    
    // MARK: - Shared Logic
    
    func pause() {
        isPaused = true
        reminderTimer?.invalidate()
        countdownTimer?.invalidate()
        saveSettings()
    }
    
    func resume() {
        isPaused = false
        scheduleNextReminder()
        saveSettings()
    }
    
    func snoozeReminder() {
        hasActiveReminder = false
        scheduleSnooze(minutes: 5)
    }
    
    func logWater(_ amount: Int = 1) {
        currentWaterIntake += amount
        updateWaterStreak()
        saveSettings()
    }
    
    func completeActivity(_ activity: String) {
        completedActivities.append(activity)
        let today = Calendar.current.startOfDay(for: Date())
        UserDefaults.standard.set(completedActivities, forKey: "TouchGrass.completedActivities.\(today)")
    }
    
    func completeBreak() {
        hasActiveReminder = false
        updateStreak(completed: true)
        scheduleNextReminder()
    }
    
    // MARK: - Private Methods
    
    private func scheduleNextReminder() {
        guard !isPaused else { return }
        
        reminderTimer?.invalidate()
        let interval = TimeInterval(intervalMinutes * 60)
        
        reminderTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            self.triggerReminder()
        }
        
        startCountdownTimer()
    }
    
    private func scheduleSnooze(minutes: Int) {
        reminderTimer?.invalidate()
        let interval = TimeInterval(minutes * 60)
        
        reminderTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            self.triggerReminder()
        }
        
        startCountdownTimer()
    }
    
    private func startCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.updateCountdown()
        }
    }
    
    private func updateCountdown() {
        guard let fireDate = reminderTimer?.fireDate else { return }
        timeUntilNextReminder = fireDate.timeIntervalSinceNow
        if timeUntilNextReminder <= 0 {
            countdownTimer?.invalidate()
        }
    }
    
    private func triggerReminder() {
        hasActiveReminder = true
        // Platform-specific notification will be handled by subclasses
        notifyUser()
    }
    
    // To be overridden by platform-specific implementations
    func notifyUser() {
        // Override in platform-specific classes
    }
    
    private func updateStreak(completed: Bool) {
        if completed {
            currentStreak += 1
            if currentStreak > bestStreak {
                bestStreak = currentStreak
            }
        } else {
            currentStreak = 0
        }
        saveSettings()
    }
    
    private func updateWaterStreak() {
        if currentWaterIntake >= dailyWaterGoal {
            waterStreak += 1
        }
    }
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        intervalMinutes = defaults.double(forKey: "TouchGrass.intervalMinutes")
        if intervalMinutes == 0 { intervalMinutes = 45 }
        
        isPaused = defaults.bool(forKey: "TouchGrass.isPaused")
        currentStreak = defaults.integer(forKey: "TouchGrass.currentStreak")
        bestStreak = defaults.integer(forKey: "TouchGrass.bestStreak")
        
        waterTrackingEnabled = defaults.bool(forKey: "TouchGrass.waterTrackingEnabled")
        if !defaults.bool(forKey: "TouchGrass.hasSetDefaults") {
            waterTrackingEnabled = true
        }
        
        dailyWaterGoal = defaults.integer(forKey: "TouchGrass.dailyWaterGoal")
        if dailyWaterGoal == 0 { dailyWaterGoal = 8 }
        
        currentWaterIntake = defaults.integer(forKey: "TouchGrass.currentWaterIntake")
        
        if let unitString = defaults.string(forKey: "TouchGrass.waterUnit"),
           let unit = WaterUnit(rawValue: unitString) {
            waterUnit = unit
        }
    }
    
    private func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(intervalMinutes, forKey: "TouchGrass.intervalMinutes")
        defaults.set(isPaused, forKey: "TouchGrass.isPaused")
        defaults.set(currentStreak, forKey: "TouchGrass.currentStreak")
        defaults.set(bestStreak, forKey: "TouchGrass.bestStreak")
        defaults.set(waterTrackingEnabled, forKey: "TouchGrass.waterTrackingEnabled")
        defaults.set(dailyWaterGoal, forKey: "TouchGrass.dailyWaterGoal")
        defaults.set(currentWaterIntake, forKey: "TouchGrass.currentWaterIntake")
        defaults.set(waterUnit.rawValue, forKey: "TouchGrass.waterUnit")
        defaults.set(true, forKey: "TouchGrass.hasSetDefaults")
    }
}

enum WaterUnit: String, CaseIterable {
    case glasses = "glasses"
    case oz = "oz"
    case ml = "ml"
}