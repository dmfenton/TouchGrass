import Foundation
import Combine
import UserNotifications
import AppKit
import ServiceManagement

enum WaterUnit: String, CaseIterable {
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
}

final class ReminderManager: ObservableObject {
    @Published var isPaused = false
    @Published var calendarManager: CalendarManager?
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
    @Published var isTouchGrassModeActive = false  // Track if touch grass mode is open
    @Published var smartSchedulingEnabled: Bool = true { didSet { saveSettings() } }
    @Published var lastMeetingEndTime: Date? = nil
    
    // Water tracking
    @Published var waterTrackingEnabled: Bool = true { didSet { saveSettings() } }
    @Published var dailyWaterGoal: Int = 8 { didSet { saveSettings() } }
    @Published var currentWaterIntake: Int = 0 { didSet { saveSettings() } }
    @Published var dailyWaterOz: Int = 0  // Track water in ounces for display
    @Published var waterUnit: WaterUnit = .glasses { didSet { saveSettings() } }
    @Published var waterStreak: Int = 0
    
    // Activity tracking
    @Published var completedActivities: [String] = []
    
    private var timerCancellable: AnyCancellable?
    private var countdownCancellable: AnyCancellable?
    private var meetingMonitorCancellable: AnyCancellable?
    private let window = ReminderWindowController()
    private let exerciseWindow = ExerciseWindowController()
    private var nextFireDate = Date().addingTimeInterval(45 * 60)
    private var wasInMeeting = false
    
    // Work hours manager
    private let workHoursManager = WorkHoursManager()
    
    // Public getters for work hours (delegated to WorkHoursManager)
    var currentWorkStartHour: Int { workHoursManager.currentWorkStartHour }
    var currentWorkStartMinute: Int { workHoursManager.currentWorkStartMinute }
    var currentWorkEndHour: Int { workHoursManager.currentWorkEndHour }
    var currentWorkEndMinute: Int { workHoursManager.currentWorkEndMinute }
    var currentWorkDays: Set<WorkDay> { workHoursManager.currentWorkDays }
    
    // Tracking for adaptive timing
    private var recentCompletions: [Date] = []
    private var consecutiveSkips = 0
    private let maxInterval: Double = 45
    private let minInterval: Double = 30
    
    // UserDefaults keys
    private let streakKey = "TouchGrass.currentStreak"
    private let bestStreakKey = "TouchGrass.bestStreak"
    private let lastCheckDateKey = "TouchGrass.lastCheckDate"
    private let intervalKey = "TouchGrass.intervalMinutes"
    private let adaptiveKey = "TouchGrass.adaptiveEnabled"
    private let waterEnabledKey = "TouchGrass.waterEnabled"
    private let waterGoalKey = "TouchGrass.waterGoal"
    private let waterIntakeKey = "TouchGrass.waterIntake"
    private let waterUnitKey = "TouchGrass.waterUnit"
    private let waterStreakKey = "TouchGrass.waterStreak"
    private let lastWaterDateKey = "TouchGrass.lastWaterDate"
    private let workStartHourKey = "TouchGrass.workStartHour"
    private let workEndHourKey = "TouchGrass.workEndHour"
    private let startsAtLoginKey = "TouchGrass.startsAtLogin"
    private let smartSchedulingKey = "TouchGrass.smartSchedulingEnabled"

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
    
    func showTouchGrassMode() {
        let touchGrassController = TouchGrassModeController()
        touchGrassController.show(manager: self)
    }
    
    func showExercises() {
        exerciseWindow.showLastExercise()
    }
    
    func showExerciseSet(_ exerciseSet: ExerciseSet) {
        exerciseWindow.showExerciseWindow(with: exerciseSet)
    }
    
    func isExerciseWindowVisible() -> Bool {
        exerciseWindow.isWindowVisible()
    }
    
    // MARK: - Water tracking
    func logWater(_ amount: Int = 1) {
        currentWaterIntake += amount
        
        // Save immediately to persist the change
        UserDefaults.standard.set(currentWaterIntake, forKey: waterIntakeKey)
        
        // Check if daily goal is met
        if currentWaterIntake >= dailyWaterGoal {
            // Update water streak
            updateWaterStreak()
        }
        
        saveSettings()
    }
    
    func logWater(ounces: Int) {
        dailyWaterOz += ounces
        // Convert to current unit for storage
        switch waterUnit {
        case .glasses:
            currentWaterIntake = dailyWaterOz / 8
        case .ounces:
            currentWaterIntake = dailyWaterOz
        case .milliliters:
            currentWaterIntake = Int(Double(dailyWaterOz) * 29.5735)
        }
        
        // Check if daily goal is met
        if currentWaterIntake >= dailyWaterGoal {
            updateWaterStreak()
        }
        
        saveSettings()
    }
    
    // MARK: - Activity tracking
    func completeActivity(_ activity: String) {
        completedActivities.append(activity)
        // Could save to UserDefaults if we want persistence
    }
    
    func completeBreak() {
        hasActiveReminder = false
        isTouchGrassModeActive = false
        updateStreak(completed: true)
        scheduleNextTick()
    }
    
    func snoozeReminder() {
        hasActiveReminder = false
        isTouchGrassModeActive = false
        snooze(minutes: 5)
    }
    
    private func updateWaterStreak() {
        let defaults = UserDefaults.standard
        let calendar = Calendar.current
        let now = Date()
        
        // Save yesterday's intake before updating streak
        defaults.set(currentWaterIntake, forKey: "TouchGrass.yesterdayWaterIntake")
        
        if let lastWaterDate = defaults.object(forKey: lastWaterDateKey) as? Date {
            if calendar.isDateInToday(lastWaterDate) {
                // Already updated today
                return
            } else if calendar.isDateInYesterday(lastWaterDate) {
                // Continue streak
                waterStreak += 1
            } else {
                // Streak broken
                waterStreak = 1
            }
        } else {
            // First time
            waterStreak = 1
        }
        
        defaults.set(now, forKey: lastWaterDateKey)
        defaults.set(waterStreak, forKey: waterStreakKey)
        defaults.synchronize()
    }
    
    private func resetDailyWaterIntake() {
        let calendar = Calendar.current
        let defaults = UserDefaults.standard
        
        // Check if it's a new day
        if let lastWaterDate = defaults.object(forKey: lastWaterDateKey) as? Date {
            if !calendar.isDateInToday(lastWaterDate) {
                // Save yesterday's intake before resetting
                defaults.set(currentWaterIntake, forKey: "TouchGrass.yesterdayWaterIntake")
                
                // Reset water intake for new day
                currentWaterIntake = 0
                dailyWaterOz = 0
                defaults.set(0, forKey: waterIntakeKey)
                
                // Check water streak - if goal wasn't met yesterday, reset streak
                if let lastIntake = defaults.object(forKey: "TouchGrass.yesterdayWaterIntake") as? Int {
                    if lastIntake < dailyWaterGoal && !calendar.isDateInYesterday(lastWaterDate) {
                        waterStreak = 0
                        defaults.set(0, forKey: waterStreakKey)
                    }
                }
                
                // Update the last water date to today
                defaults.set(Date(), forKey: lastWaterDateKey)
            }
            // else: Same day - keep existing water intake values (already loaded from loadSettings)
        } else {
            // First run - initialize date but keep any existing water data
            defaults.set(Date(), forKey: lastWaterDateKey)
            // Don't reset water intake here - it was already loaded from loadSettings
        }
    }
    
    func setWorkHours(start: (hour: Int, minute: Int), end: (hour: Int, minute: Int), days: Set<WorkDay>) {
        workHoursManager.setWorkHours(start: start, end: end, days: days)
        
        // Update calendar manager with new work hours
        calendarManager?.workStartHour = start.hour
        calendarManager?.workStartMinute = start.minute
        calendarManager?.workEndHour = end.hour
        calendarManager?.workEndMinute = end.minute
        calendarManager?.updateCurrentAndNextEvents() // Refresh calendar data with new hours
        
        // Save the work hours
        saveSettings()
        
        // Reschedule if needed
        if !workHoursManager.isWithinWorkHours() && !isPaused {
            scheduleNextWorkHourReminder()
        }
    }
    
    private func scheduleNextWorkHourReminder() {
        if let nextWorkDate = workHoursManager.nextWorkHourDate() {
            schedule(at: nextWorkDate)
        }
    }

    // MARK: - Init
    init() {
        loadSettings()
        checkLoginItemStatus()
        resetDailyWaterIntake()
        scheduleAtFixedInterval()
        startCountdownTimer()
        requestNotificationPermissions()
        
        // Always initialize calendar manager to preserve settings
        self.calendarManager = CalendarManager()
        
        // Update calendar manager with work hours
        self.calendarManager?.workStartHour = workHoursManager.currentWorkStartHour
        self.calendarManager?.workStartMinute = workHoursManager.currentWorkStartMinute
        self.calendarManager?.workEndHour = workHoursManager.currentWorkEndHour
        self.calendarManager?.workEndMinute = workHoursManager.currentWorkEndMinute
        
        // Start monitoring meetings for smart scheduling
        startMeetingMonitoring()
    }
    
    // MARK: - Smart Meeting Monitoring
    private func startMeetingMonitoring() {
        guard smartSchedulingEnabled else { return }
        
        // Monitor calendar changes every 15 minutes (4 times per hour)
        let publisher = Timer.publish(every: 900, on: .main, in: .common).autoconnect()
        meetingMonitorCancellable = publisher.sink { [weak self] _ in
            self?.checkMeetingTransitions()
        }
    }
    
    private func checkMeetingTransitions() {
        guard let calManager = calendarManager,
              smartSchedulingEnabled,
              !isPaused else { return }
        
        // Update calendar state
        calManager.updateCurrentAndNextEvents()
        
        let isCurrentlyInMeeting = calManager.isInMeeting
        let now = Date()
        
        // Detect meeting end transition
        if wasInMeeting && !isCurrentlyInMeeting {
            // Meeting just ended!
            lastMeetingEndTime = now
            
            // Check if there's a meaningful gap before next meeting
            if let nextEvent = calManager.nextEvent,
               let nextStartTime = nextEvent.startDate {
                let gapDuration = nextStartTime.timeIntervalSince(now)
                
                // Only trigger if there's at least 10 minutes free
                if gapDuration >= 600 {
                    triggerSmartReminder(reason: "Meeting ended - perfect time to touch grass!")
                }
                // Don't trigger for short gaps - let the regular timer handle those
            } else {
                // No upcoming meetings - definitely time to touch grass!
                triggerSmartReminder(reason: "Meetings done - time to touch grass!")
            }
        }
        
        // Check for long meeting stretches ending (only if we're actually free now)
        if !isCurrentlyInMeeting && lastMeetingEndTime == nil {
            // Not in a meeting and haven't tracked an end time yet
            // Check if we just emerged from a long stretch of meetings
            let meetings = calManager.getTodaysMeetings()
            if let lastEndedMeeting = meetings.last(where: { 
                ($0.endDate ?? Date.distantPast) <= now && 
                ($0.endDate ?? Date.distantPast) > now.addingTimeInterval(-900) 
            }) {
                // A meeting ended in the last 15 minutes
                if let endDate = lastEndedMeeting.endDate {
                    lastMeetingEndTime = endDate
                    
                    // Only trigger if we have significant free time ahead
                    if let nextEvent = calManager.nextEvent,
                       let nextStartTime = nextEvent.startDate {
                        let gapDuration = nextStartTime.timeIntervalSince(now)
                        if gapDuration >= 600 {
                            // Count how many back-to-back meetings just ended
                            var consecutiveMeetings = 1
                            var checkTime = lastEndedMeeting.startDate ?? now
                            
                            for meeting in meetings.reversed() {
                                guard let meetingEnd = meeting.endDate,
                                      let meetingStart = meeting.startDate,
                                      meeting != lastEndedMeeting else { continue }
                                
                                // Check if this meeting was back-to-back with the previous one
                                if abs(meetingEnd.timeIntervalSince(checkTime)) < 300 {
                                    consecutiveMeetings += 1
                                    checkTime = meetingStart
                                } else {
                                    break
                                }
                            }
                            
                            if consecutiveMeetings >= 2 {
                                triggerSmartReminder(reason: "Back-to-back meetings ended - time for a break!")
                            }
                        }
                    } else {
                        // No more meetings today - trigger reminder
                        triggerSmartReminder(reason: "Meetings done for now - time to touch grass!")
                    }
                }
            }
        }
        
        // Update state for next check
        wasInMeeting = isCurrentlyInMeeting
    }
    
    private func triggerSmartReminder(reason: String) {
        // Don't trigger if we already have an active reminder or just showed one
        guard !hasActiveReminder else { return }
        
        // Check if enough time has passed since last reminder
        let timeSinceLastReminder = Date().timeIntervalSince(nextFireDate.addingTimeInterval(-intervalMinutes * 60))
        guard timeSinceLastReminder >= 900 else { return } // At least 15 minutes since last reminder
        
        // Set the active reminder flag and notify
        hasActiveReminder = true
        NSSound.beep()
        
        // Send a smart notification with the reason
        let content = UNMutableNotificationContent()
        content.title = "Time to touch grass!"
        content.body = reason
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "smart-reminder-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { _ in }
        
        // Reset the regular schedule
        scheduleNextTick()
    }

    // MARK: - Settings Persistence
    private func loadSettings() {
        let defaults = UserDefaults.standard
        currentStreak = defaults.integer(forKey: streakKey)
        bestStreak = defaults.integer(forKey: bestStreakKey)
        intervalMinutes = defaults.double(forKey: intervalKey) > 0 ? defaults.double(forKey: intervalKey) : 45
        adaptiveIntervalEnabled = defaults.object(forKey: adaptiveKey) as? Bool ?? true
        smartSchedulingEnabled = defaults.object(forKey: smartSchedulingKey) as? Bool ?? true
        
        // Load water settings
        waterTrackingEnabled = defaults.object(forKey: waterEnabledKey) as? Bool ?? true
        dailyWaterGoal = defaults.object(forKey: waterGoalKey) as? Int ?? 8
        currentWaterIntake = defaults.integer(forKey: waterIntakeKey)
        if let unitString = defaults.string(forKey: waterUnitKey),
           let unit = WaterUnit(rawValue: unitString) {
            waterUnit = unit
        }
        waterStreak = defaults.integer(forKey: waterStreakKey)
        
        // Sync dailyWaterOz based on loaded water intake and unit
        switch waterUnit {
        case .glasses:
            dailyWaterOz = currentWaterIntake * 8
        case .ounces:
            dailyWaterOz = currentWaterIntake
        case .milliliters:
            dailyWaterOz = Int(Double(currentWaterIntake) / 29.5735)
        }
        
        // Load work hours
        let startHour = defaults.object(forKey: workStartHourKey) as? Int ?? 9
        let endHour = defaults.object(forKey: workEndHourKey) as? Int ?? 17
        workHoursManager.setWorkHours(
            start: (startHour, 0),
            end: (endHour, 0),
            days: [.monday, .tuesday, .wednesday, .thursday, .friday]
        )
        
        // Load login item preference
        if let savedStartsAtLogin = defaults.object(forKey: startsAtLoginKey) as? Bool {
            startsAtLogin = savedStartsAtLogin
        }
        
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
        defaults.set(smartSchedulingEnabled, forKey: smartSchedulingKey)
        
        // Save water settings
        defaults.set(waterTrackingEnabled, forKey: waterEnabledKey)
        defaults.set(dailyWaterGoal, forKey: waterGoalKey)
        defaults.set(currentWaterIntake, forKey: waterIntakeKey)
        defaults.set(waterUnit.rawValue, forKey: waterUnitKey)
        defaults.set(waterStreak, forKey: waterStreakKey)
        
        // Save work hours
        defaults.set(currentWorkStartHour, forKey: workStartHourKey)
        defaults.set(currentWorkEndHour, forKey: workEndHourKey)
        
        // Save login item preference
        defaults.set(startsAtLogin, forKey: startsAtLoginKey)
        
        // Force synchronization to disk
        defaults.synchronize()
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
        // Check if we're within work hours
        guard workHoursManager.isWithinWorkHours() else {
            // Schedule for next work hour
            scheduleNextWorkHourReminder()
            return
        }
        
        // Update calendar info for awareness but don't pause
        if let calManager = calendarManager {
            calManager.updateCurrentAndNextEvents()
        }
        
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
            manager: self,
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
                startsAtLogin.toggle()
            }
        }
    }
}
