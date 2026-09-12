import UserNotifications

@MainActor
protocol NotificationScheduling {
    func authorizationStatus() async -> UNAuthorizationStatus
    func requestAuthorization() async throws -> Bool
    func removeAllPending()
    func add(_ request: UNNotificationRequest) async throws
}

@MainActor
final class DeviceNotifications: NotificationScheduling {
    private let center = UNUserNotificationCenter.current()
    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }
    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound])
    }
    func removeAllPending() { center.removeAllPendingNotificationRequests() }
    func add(_ request: UNNotificationRequest) async throws { try await center.add(request) }
}
