import Foundation
import Combine
import UserNotifications

final class ReminderManager: ObservableObject {
    @Published var isPaused = false
    @Published var intervalMinutes: Double = 45 { didSet { scheduleNextTick() } }
    @Published var fakeLoginToggle: Bool = false
    @Published var timeUntilNextReminder: TimeInterval = 0

    private var timerCancellable: AnyCancellable?
    private var countdownCancellable: AnyCancellable?
    private let window = ReminderWindowController()
    private var nextFireDate = Date().addingTimeInterval(45 * 60)

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
        presentReminder()
    }

    // MARK: - Init
    init() {
        scheduleAtFixedInterval()
        startCountdownTimer()
        requestNotificationPermissions()
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
        let message = Messages.composed()
        
        // Show window
        window.show(
            message: message,
            onOK: { [weak self] in 
                self?.scheduleNextTick()
                self?.sendCompletionNotification(action: "completed")
            },
            onSnooze10: { [weak self] in 
                self?.snooze(minutes: 10)
                self?.sendCompletionNotification(action: "snoozed for 10 minutes")
            },
            onSnooze20: { [weak self] in 
                self?.snooze(minutes: 20)
                self?.sendCompletionNotification(action: "snoozed for 20 minutes")
            },
            onSkip: { [weak self] in 
                self?.scheduleNextTick()
                self?.sendCompletionNotification(action: "skipped")
            }
        )
    }
    
    // MARK: - Notifications
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
    
    private func sendCompletionNotification(action: String) {
        let content = UNMutableNotificationContent()
        content.title = "Posture Check \(action)"
        content.body = "Next reminder in \(Int(intervalMinutes)) minutes"
        content.sound = nil // Silent notification
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}