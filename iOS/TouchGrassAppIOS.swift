import SwiftUI

@main
struct TouchGrassAppIOS: App {
    @StateObject private var manager = iOSReminderManager()
    @Environment(\.scenePhase) var scenePhase
    
    init() {
        // Request notification permissions on first launch
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(manager: manager)
                .onChange(of: scenePhase) { newPhase in
                    switch newPhase {
                    case .active:
                        // Refresh when app becomes active
                        manager.refreshState()
                    case .background:
                        // Schedule local notifications when going to background
                        manager.scheduleBackgroundNotifications()
                    default:
                        break
                    }
                }
        }
    }
}

// iOS-specific reminder manager
class iOSReminderManager: CoreReminderManager {
    override func notifyUser() {
        super.notifyUser()
        
        // Create iOS notification
        let content = UNMutableNotificationContent()
        content.title = "Time to Touch Grass"
        content.body = "Take a break and move around! Your body will thank you."
        content.sound = .default
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleBackgroundNotifications() {
        // Schedule next few reminders as local notifications
        guard !isPaused else { return }
        
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Schedule up to 5 reminders
        for i in 1...5 {
            let content = UNMutableNotificationContent()
            content.title = "Time to Touch Grass"
            content.body = "Take a break and move around!"
            content.sound = .default
            
            let timeInterval = TimeInterval(intervalMinutes * 60 * Double(i))
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
            let request = UNNotificationRequest(
                identifier: "reminder-\(i)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    func refreshState() {
        // Refresh any state when app becomes active
        loadSettings()
    }
    
    func clearNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
}