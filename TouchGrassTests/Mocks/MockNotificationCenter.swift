import Foundation
import UserNotifications

// Mock implementation of notification center for testing
class MockNotificationCenter {
    var pendingNotifications: [UNNotificationRequest] = []
    var deliveredNotifications: [MockNotification] = []
    var authorizationStatus: UNAuthorizationStatus = .authorized
    var authorizationOptions: UNAuthorizationOptions = []
    
    func requestAuthorization(options: UNAuthorizationOptions, completionHandler: @escaping (Bool, Error?) -> Void) {
        authorizationOptions = options
        completionHandler(authorizationStatus == .authorized, nil)
    }
    
    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> Void)? = nil) {
        pendingNotifications.append(request)
        completionHandler?(nil)
    }
    
    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        pendingNotifications.removeAll { identifiers.contains($0.identifier) }
    }
    
    func removeAllPendingNotificationRequests() {
        pendingNotifications.removeAll()
    }
    
    func getPendingNotificationRequests(completionHandler: @escaping ([UNNotificationRequest]) -> Void) {
        completionHandler(pendingNotifications)
    }
    
    func getDeliveredNotifications(completionHandler: @escaping ([MockNotification]) -> Void) {
        completionHandler(deliveredNotifications)
    }
    
    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        deliveredNotifications.removeAll { notification in
            identifiers.contains(notification.request.identifier)
        }
    }
    
    func removeAllDeliveredNotifications() {
        deliveredNotifications.removeAll()
    }
    
    func reset() {
        pendingNotifications.removeAll()
        deliveredNotifications.removeAll()
        authorizationStatus = .authorized
        authorizationOptions = []
    }
    
    func simulateNotificationDelivery(identifier: String) {
        if let request = pendingNotifications.first(where: { $0.identifier == identifier }) {
            let notification = MockNotification(request: request)
            deliveredNotifications.append(notification)
            pendingNotifications.removeAll { $0.identifier == identifier }
        }
    }
}

class MockNotification {
    let request: UNNotificationRequest
    let date: Date
    
    init(request: UNNotificationRequest, date: Date = Date()) {
        self.request = request
        self.date = date
    }
}
