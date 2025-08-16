import Foundation
import Combine

protocol TimerServiceDelegate: AnyObject {
    func timerDidFire()
    func shouldScheduleWithinWorkHours() -> Bool
    func getNextWorkHourDate() -> Date?
}

final class TimerService: ObservableObject {
    @Published var timeUntilNextReminder: TimeInterval = 0
    @Published var intervalMinutes: Double = 45 {
        didSet {
            scheduleNextTick()
        }
    }
    
    weak var delegate: TimerServiceDelegate?
    
    private var timerCancellable: AnyCancellable?
    private var countdownCancellable: AnyCancellable?
    private var nextFireDate = Date().addingTimeInterval(45 * 60)
    private var isPaused = false
    
    // MARK: - Public Interface
    
    init(intervalMinutes: Double = 45) {
        self.intervalMinutes = intervalMinutes
        scheduleAtFixedInterval()
        startCountdownTimer()
    }
    
    func pause() {
        isPaused = true
        timeUntilNextReminder = 0
        timerCancellable?.cancel()
    }
    
    func resume() {
        isPaused = false
        scheduleNextTick()
    }
    
    func snooze(minutes: Int) {
        isPaused = false
        schedule(at: Date().addingTimeInterval(Double(minutes) * 60))
    }
    
    func scheduleNextTick() {
        scheduleAtFixedInterval()
    }
    
    func getNextFireDate() -> Date {
        return nextFireDate
    }
    
    func updateInterval(_ newInterval: Double) {
        intervalMinutes = newInterval
    }
    
    // MARK: - Internal Scheduling Logic
    
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
    
    private func schedule(at date: Date) {
        nextFireDate = date
        timerCancellable?.cancel()
        
        guard !isPaused else { return }
        
        let publisher = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        timerCancellable = publisher.sink { [weak self] _ in
            guard let self else { return }
            if !self.isPaused, Date() >= self.nextFireDate {
                self.handleTimerFire()
            }
        }
    }
    
    private func handleTimerFire() {
        // Check with delegate if we should fire within work hours
        guard delegate?.shouldScheduleWithinWorkHours() != false else {
            // Schedule for next work hour if outside work hours
            if let nextWorkDate = delegate?.getNextWorkHourDate() {
                schedule(at: nextWorkDate)
            }
            return
        }
        
        // Notify delegate that timer fired
        delegate?.timerDidFire()
        
        // Schedule next tick
        scheduleAtFixedInterval()
    }
    
    private func startCountdownTimer() {
        // Update immediately
        updateCountdown()
        
        // Then update every 60 seconds for minute-level precision
        let publisher = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
        countdownCancellable = publisher.sink { [weak self] _ in
            self?.updateCountdown()
        }
    }
    
    private func updateCountdown() {
        if !isPaused {
            timeUntilNextReminder = max(0, nextFireDate.timeIntervalSinceNow)
        } else {
            timeUntilNextReminder = 0
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        timerCancellable?.cancel()
        countdownCancellable?.cancel()
    }
}
