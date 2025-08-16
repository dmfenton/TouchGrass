import Foundation
import Combine
import UserNotifications
import AppKit
import ServiceManagement

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
    @Published var activityTracker = ActivityTracker()
    @Published var adaptiveIntervalEnabled: Bool = true { didSet { saveSettings() } }
    @Published var hasActiveReminder = false  // New: indicates a reminder is waiting
    @Published var isTouchGrassModeActive = false  // Track if touch grass mode is open
    @Published var smartSchedulingEnabled: Bool = true { didSet { saveSettings() } }
    @Published var lastMeetingEndTime: Date? = nil
    
    // Water tracking
    @Published var waterTracker = WaterTracker()
    
    private var timerCancellable: AnyCancellable?
    private var countdownCancellable: AnyCancellable?
    private var meetingMonitorCancellable: AnyCancellable?
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
    
    // Use a shared UserDefaults suite that persists across bundle IDs
    private let defaults: UserDefaults = {
        // Use a consistent suite name that won't change with bundle ID
        if let suite = UserDefaults(suiteName: "com.touchgrass.shared") {
            return suite
        } else {
            // Fallback to standard if suite creation fails
            return UserDefaults.standard
        }
    }()
    
    // UserDefaults keys
    private let intervalKey = "TouchGrass.intervalMinutes"
    private let adaptiveKey = "TouchGrass.adaptiveEnabled"
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
    
    // MARK: - Activity tracking (delegates to ActivityTracker)
    func completeActivity(_ activity: String) {
        activityTracker.completeActivity(activity)
    }
    
    func completeBreak() {
        hasActiveReminder = false
        isTouchGrassModeActive = false
        activityTracker.completeBreak()
        scheduleNextTick()
    }
    
    // Computed properties for backward compatibility
    var currentStreak: Int {
        activityTracker.currentStreak
    }
    
    var bestStreak: Int {
        activityTracker.bestStreak
    }
    
    var completedActivities: [String] {
        activityTracker.completedActivities
    }
    
    func snoozeReminder() {
        hasActiveReminder = false
        isTouchGrassModeActive = false
        snooze(minutes: 5)
    }
    
    // MARK: - Water tracking (delegates to WaterTracker)
    func logWater(_ amount: Int = 1) {
        waterTracker.logWater(amount)
    }
    
    // Computed properties for backward compatibility
    var waterTrackingEnabled: Bool {
        get { waterTracker.isEnabled }
        set { waterTracker.isEnabled = newValue }
    }
    
    var dailyWaterGoal: Int {
        get { waterTracker.dailyGoal }
        set { waterTracker.dailyGoal = newValue }
    }
    
    var currentWaterIntake: Int {
        get { waterTracker.currentIntake }
        set { waterTracker.currentIntake = newValue }
    }
    
    var waterUnit: WaterUnit {
        get { waterTracker.unit }
        set { waterTracker.unit = newValue }
    }
    
    var waterStreak: Int {
        waterTracker.streak
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
        // Initialize trackers with same UserDefaults suite
        waterTracker = WaterTracker(userDefaults: defaults)
        activityTracker = ActivityTracker(userDefaults: defaults)
        
        loadSettings()
        checkLoginItemStatus()
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
        
        // Check immediately on startup
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.checkMeetingTransitions()
        }
        
        // Calculate delay to offset checks by 10 seconds past the 5-minute marks
        // This ensures meetings that end exactly on the hour/half-hour are detected
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.minute, .second], from: now)
        let currentSeconds = (components.minute ?? 0) % 5 * 60 + (components.second ?? 0)
        let delayToNext5Min = currentSeconds > 10 ? (300 - currentSeconds + 10) : (10 - currentSeconds)
        
        // Start checking 10 seconds after each 5-minute mark
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(delayToNext5Min)) { [weak self] in
            self?.checkMeetingTransitions()
            
            // Then continue every 5 minutes
            let publisher = Timer.publish(every: 300, on: .main, in: .common).autoconnect()
            self?.meetingMonitorCancellable = publisher.sink { _ in
                self?.checkMeetingTransitions()
            }
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
        
        // Also check for recently ended meetings we might have missed
        if !isCurrentlyInMeeting && !wasInMeeting {
            // Not currently in a meeting and wasn't tracking one
            // Check if a meeting ended in the last 5 minutes
            let meetings = calManager.getTodaysMeetings()
            if let lastEndedMeeting = meetings.last(where: { 
                ($0.endDate ?? Date.distantPast) <= now && 
                ($0.endDate ?? Date.distantPast) > now.addingTimeInterval(-300) 
            }) {
                // A meeting ended in the last 5 minutes
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
        intervalMinutes = defaults.double(forKey: intervalKey) > 0 ? defaults.double(forKey: intervalKey) : 45
        adaptiveIntervalEnabled = defaults.object(forKey: adaptiveKey) as? Bool ?? true
        smartSchedulingEnabled = defaults.object(forKey: smartSchedulingKey) as? Bool ?? true
        
        
        
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
        
        // Check activity tracker streak status
        activityTracker.resetDailyTracking()
    }
    
    private func saveSettings() {
        defaults.set(intervalMinutes, forKey: intervalKey)
        defaults.set(adaptiveIntervalEnabled, forKey: adaptiveKey)
        defaults.set(smartSchedulingEnabled, forKey: smartSchedulingKey)
        
        
        // Save work hours
        defaults.set(currentWorkStartHour, forKey: workStartHourKey)
        defaults.set(currentWorkEndHour, forKey: workEndHourKey)
        
        // Save login item preference
        defaults.set(startsAtLogin, forKey: startsAtLoginKey)
        
        // Force synchronization to disk
        defaults.synchronize()
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
    
    func scheduleNextTick() {
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
        // Update immediately
        if !self.isPaused {
            self.timeUntilNextReminder = max(0, self.nextFireDate.timeIntervalSinceNow)
        } else {
            self.timeUntilNextReminder = 0
        }
        
        // Then update every 60 seconds for minute-level precision
        let publisher = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
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
        
        // Just set the flag and play a sound - menu bar will show the touch grass view
        hasActiveReminder = true
        NSSound.beep()  // Gentle audio notification
        
        // Send a system notification as backup
        sendSystemNotification()
    }
    
    func openReminderWindow() {
        // This method is no longer needed - keeping empty for compatibility
        // The TouchGrassQuickView handles everything now
    }
    
    // MARK: - Notifications
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
    
    private func sendSystemNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Time to touch grass! 🌱"
        content.body = "Take a break - click the Touch Grass icon in the menu bar"
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        
        // Try to set app icon explicitly
        if let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns") {
            let attachment = try? UNNotificationAttachment(identifier: "appIcon", url: iconURL, options: nil)
            if let attachment = attachment {
                content.attachments = [attachment]
            }
        }
        
        let request = UNNotificationRequest(
            identifier: "touch-grass-\(UUID().uuidString)",
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
