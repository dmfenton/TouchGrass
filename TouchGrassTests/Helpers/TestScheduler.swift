import Foundation
import Combine

final class TestScheduler {
    private var currentTime = Date()
    private var scheduledActions: [(date: Date, action: () -> Void)] = []
    
    var now: Date {
        return currentTime
    }
    
    func advance(by interval: TimeInterval) {
        let targetTime = currentTime.addingTimeInterval(interval)
        
        let actionsToRun = scheduledActions
            .filter { $0.date <= targetTime }
            .sorted { $0.date < $1.date }
        
        scheduledActions.removeAll { action in
            actionsToRun.contains { $0.date == action.date }
        }
        
        for action in actionsToRun {
            currentTime = action.date
            action.action()
        }
        
        currentTime = targetTime
    }
    
    func schedule(at date: Date, action: @escaping () -> Void) {
        scheduledActions.append((date: date, action: action))
        scheduledActions.sort { $0.date < $1.date }
    }
    
    func scheduleAfter(_ interval: TimeInterval, action: @escaping () -> Void) {
        let date = currentTime.addingTimeInterval(interval)
        schedule(at: date, action: action)
    }
    
    func reset() {
        currentTime = Date()
        scheduledActions.removeAll()
    }
    
    func setCurrentTime(_ date: Date) {
        currentTime = date
    }
    
    func advanceToNextScheduledAction() -> Bool {
        guard let nextAction = scheduledActions.first else {
            return false
        }
        
        currentTime = nextAction.date
        nextAction.action()
        scheduledActions.removeFirst()
        return true
    }
}
