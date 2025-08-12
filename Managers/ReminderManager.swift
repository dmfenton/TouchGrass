import Foundation
import Combine
import UserNotifications
import AppKit
import ServiceManagement

final class ReminderManager: ObservableObject {
    @Published var isPaused = false
    @Published var intervalMinutes: Double = 45 { 
        didSet { 
            saveSettings()
            scheduleNextTick() 
        } 
    }
    @Published var startsAtLogin: Bool = false {
        didSet {
            if startsAtLogin != oldValue {
                updateLoginItemStatus()
            }
        }
    }
    @Published var timeUntilNextReminder: TimeInterval = 0
    @Published var currentStreak: Int = 0
    @Published var bestStreak: Int = 0
    @Published var adaptiveIntervalEnabled: Bool = true { didSet { saveSettings() } }
    @Published var hasActiveReminder = false  // New: indicates a reminder is waiting
    
    private var timerCancellable: AnyCancellable?
    private var countdownCancellable: AnyCancellable?
    private let window = ReminderWindowController()
    private let exerciseWindow = ExerciseWindowController()
    private var nextFireDate = Date().addingTimeInterval(45 * 60)
    
    // Tracking for adaptive timing
    private var recentCompletions: [Date] = []
    private var consecutiveSkips = 0
    private let maxInterval: Double = 45
    private let minInterval: Double = 30
    
    // UserDefaults keys
    private let streakKey = "PosturePal.currentStreak"
    private let bestStreakKey = "PosturePal.bestStreak"
    private let lastCheckDateKey = "PosturePal.lastCheckDate"
    private let intervalKey = "PosturePal.intervalMinutes"
    private let adaptiveKey = "PosturePal.adaptiveEnabled"

    // MARK: - Public actions
    func pause() { 
        isPaused = true
        timeUntilNextReminder = 0
    }
    
    func resume() { 
        isPaused = false
        scheduleNextTick()
    }
    
    func snooze(minutes: Int) { 
        isPaused = false
        schedule(at: Date().addingTimeInterval(Double(minutes) * 60))
    }
    
    func showReminder() { 
        openReminderWindow()
    }
    
    func showExercises() {
        exerciseWindow.showLastExercise()
    }
    
    func showExerciseSet(_ exerciseSet: ExerciseSet) {
        exerciseWindow.showExerciseWindow(with: exerciseSet)
    }
    
    func isExerciseWindowVisible() -> Bool {
        return exerciseWindow.isWindowVisible()
    }

    // MARK: - Init
    init() {
        loadSettings()
        checkLoginItemStatus()
        scheduleAtFixedInterval()
        startCountdownTimer()
        requestNotificationPermissions()
    }

    // MARK: - Settings Persistence
    private func loadSettings() {
        let defaults = UserDefaults.standard
        currentStreak = defaults.integer(forKey: streakKey)
        bestStreak = defaults.integer(forKey: bestStreakKey)
        intervalMinutes = defaults.double(forKey: intervalKey) > 0 ? defaults.double(forKey: intervalKey) : 45
        adaptiveIntervalEnabled = defaults.bool(forKey: adaptiveKey)
        
        // Check if streak should be reset (missed a day)
        if let lastCheck = defaults.object(forKey: lastCheckDateKey) as? Date {
            let calendar = Calendar.current
            if !calendar.isDateInToday(lastCheck) && !calendar.isDateInYesterday(lastCheck) {
                currentStreak = 0
                saveSettings()
            }
        }
    }
    
    private func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(currentStreak, forKey: streakKey)
        defaults.set(bestStreak, forKey: bestStreakKey)
        defaults.set(intervalMinutes, forKey: intervalKey)
        defaults.set(adaptiveIntervalEnabled, forKey: adaptiveKey)
    }
    
    private func updateStreak(completed: Bool) {
        let defaults = UserDefaults.standard
        let calendar = Calendar.current
        let now = Date()
        
        if completed {
            // Check if this is a new day
            if let lastCheck = defaults.object(forKey: lastCheckDateKey) as? Date {
                if !calendar.isDateInToday(lastCheck) {
                    // New day - increment streak
                    currentStreak += 1
                }
                // Same day - maintain streak
            } else {
                // First check ever
                currentStreak = 1
            }
            
            defaults.set(now, forKey: lastCheckDateKey)
            
            // Update best streak
            if currentStreak > bestStreak {
                bestStreak = currentStreak
            }
            
            // Track completion for adaptive timing
            recentCompletions.append(now)
            // Keep only last 10 completions
            if recentCompletions.count > 10 {
                recentCompletions.removeFirst()
            }
            
            consecutiveSkips = 0
            
            // Adaptive interval adjustment
            if adaptiveIntervalEnabled {
                adjustIntervalBasedOnBehavior()
            }
        } else {
            // Skipped
            consecutiveSkips += 1
            
            // If skipping too much, increase interval
            if adaptiveIntervalEnabled && consecutiveSkips >= 3 {
                intervalMinutes = min(maxInterval, intervalMinutes + 5)
                consecutiveSkips = 0
            }
        }
        
        saveSettings()
    }
    
    private func adjustIntervalBasedOnBehavior() {
        // If user is completing regularly, can slightly decrease interval
        // If user is skipping often, increase interval
        
        let recentCount = recentCompletions.filter { 
            $0.timeIntervalSinceNow > -3600 // Last hour
        }.count
        
        if recentCount >= 2 {
            // Very engaged - can decrease interval
            intervalMinutes = max(minInterval, intervalMinutes - 5)
        } else if recentCompletions.count >= 5 {
            // Good engagement - maintain current
            // No change
        }
    }

    // MARK: - Scheduling
    private func scheduleAtFixedInterval() {
        // Calculate next fire time based on fixed interval from start of hour
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.minute, .second], from: now)
        let minutesSinceHour = Double(components.minute ?? 0)
        let secondsSinceHour = Double(components.second ?? 0)
        let totalSecondsSinceHour = minutesSinceHour * 60 + secondsSinceHour
        
        let intervalSecs = intervalMinutes * 60
        let secondsUntilNext = intervalSecs - totalSecondsSinceHour.truncatingRemainder(dividingBy: intervalSecs)
        
        schedule(at: now.addingTimeInterval(secondsUntilNext))
    }
    
    private func scheduleNextTick() {
        scheduleAtFixedInterval()
    }

    private var intervalSeconds: TimeInterval { intervalMinutes * 60 }

    private func schedule(at date: Date) {
        nextFireDate = date
        timerCancellable?.cancel()

        let publisher = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        timerCancellable = publisher.sink { [weak self] _ in
            guard let self else { return }
            if !self.isPaused, Date() >= self.nextFireDate {
                self.presentReminder()
                self.scheduleAtFixedInterval()
            }
        }
    }
    
    private func startCountdownTimer() {
        let publisher = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        countdownCancellable = publisher.sink { [weak self] _ in
            guard let self else { return }
            if !self.isPaused {
                self.timeUntilNextReminder = max(0, self.nextFireDate.timeIntervalSinceNow)
            } else {
                self.timeUntilNextReminder = 0
            }
        }
    }

    // MARK: - Present
    private func presentReminder() {
        // Just set the flag and play a sound - don't show window automatically
        hasActiveReminder = true
        NSSound.beep()  // Gentle audio notification
        
        // Send a system notification as backup
        sendSystemNotification()
    }
    
    func openReminderWindow() {
        // This is called when user clicks from menu bar
        hasActiveReminder = false  // Clear the flag
        
        let message = Messages.composed()
        
        // Show window
        window.show(
            message: message,
            onOK: { [weak self] in 
                self?.updateStreak(completed: true)
                self?.scheduleNextTick()
                self?.sendCompletionNotification(action: "completed")
            },
            onSnooze5: { [weak self] in 
                self?.snooze(minutes: 5)
                self?.sendCompletionNotification(action: "snoozed for 5 minutes")
            },
            onSnooze10: { [weak self] in 
                self?.snooze(minutes: 10)
                self?.sendCompletionNotification(action: "snoozed for 10 minutes")
            },
            onSkip: { [weak self] in 
                self?.updateStreak(completed: false)
                self?.scheduleNextTick()
                self?.sendCompletionNotification(action: "skipped")
            }
        )
    }
    
    // MARK: - Notifications
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
    
    private func sendSystemNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Time to touch grass!"
        content.body = "Click Touch Grass in the menu bar when you're ready."
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "posture-reminder",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { _ in }
    }
    
    private func sendCompletionNotification(action: String) {
        let content = UNMutableNotificationContent()
        content.title = "Posture Check \(action)"
        content.body = "Next reminder in \(Int(intervalMinutes)) minutes"
        if currentStreak > 0 {
            content.body += " • \(currentStreak) day streak!"
        }
        content.sound = nil // Silent notification
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Login Item Management
    private func checkLoginItemStatus() {
        if #available(macOS 13.0, *) {
            // Use SMAppService for macOS 13+
            let appService = SMAppService.mainApp
            startsAtLogin = appService.status == .enabled
        } else {
            // For older macOS versions, use legacy SMLoginItemSetEnabled
            // This requires a helper app, so we'll just disable it
            startsAtLogin = false
        }
    }
    
    private func updateLoginItemStatus() {
        if #available(macOS 13.0, *) {
            let appService = SMAppService.mainApp
            
            do {
                if startsAtLogin {
                    if appService.status == .enabled {
                        // Already enabled
                        return
                    }
                    try appService.register()
                } else {
                    if appService.status != .enabled {
                        // Already disabled
                        return
                    }
                    try appService.unregister()
                }
            } catch {
                print("Failed to update login item status: \(error)")
                // Revert the toggle on failure
                startsAtLogin = !startsAtLogin
            }
        }
    }
}