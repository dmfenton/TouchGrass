import SwiftUI
import UserNotifications
import CoreLocation

// MARK: - Location Permission Manager
class LocationPermissionManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationPermissionManager()
    
    private let locationManager = CLLocationManager()
    @Published var authorizationStatus: CLAuthorizationStatus
    
    override init() {
        self.authorizationStatus = locationManager.authorizationStatus
        super.init()
        locationManager.delegate = self
    }
    
    func requestAlwaysAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
        }
    }
}

@main
struct TouchGrassApp: App {
    static let sharedManager = ReminderManager()
    @StateObject private var manager = TouchGrassApp.sharedManager
    private var onboardingWindow: TouchGrassOnboardingController?
    @State private var touchGrassController = TouchGrassModeController()

    init() {
        // Set up notification delegate with the shared manager
        NotificationDelegate.shared.reminderManager = TouchGrassApp.sharedManager
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        
        // Check for onboarding after a short delay to let the app fully initialize
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if TouchGrassOnboardingController.shouldShowOnboarding() {
                let window = TouchGrassOnboardingController(reminderManager: ReminderManager())
                window.showOnboarding()
            }
        }
    }

    var body: some Scene {
        MenuBarExtra {
            MenuView(manager: manager)
        } label: {
            GrassIcon(isActive: manager.hasActiveReminder, size: 20)
        }
        .menuBarExtraStyle(.window)
        // No longer automatically open window when reminder triggers
        // User will click the icon when they see the notification
    }
}

struct MenuView: View {
    @ObservedObject var manager: ReminderManager
    @StateObject private var locationManager = LocationPermissionManager.shared
    @State private var hoveredItem: String? = nil
    @State private var customizationWindow: CustomizationWindowController?
    @State private var locationAlertDismissed = UserDefaults.standard.bool(forKey: "TouchGrass.locationAlertDismissed")
    
    var nextReminderText: String {
        let totalSeconds = Int(manager.timeUntilNextReminder)
        let minutes = (totalSeconds + 59) / 60  // Round up to next minute
        
        if totalSeconds <= 0 {
            return "now"
        } else if minutes == 1 {
            return "1 minute"
        } else {
            return "\(minutes) minutes"
        }
    }
    
    var body: some View {
        mainMenuContent
            .onAppear {
                // Refresh calendar data whenever menu is opened
                manager.calendarManager?.updateCurrentAndNextEvents()
                
                // Check if it's a new day for water tracking
                manager.waterTracker.checkForNewDay()
                
                // Reset active reminder state when menu is opened
                if manager.hasActiveReminder {
                    manager.hasActiveReminder = false
                }
            }
    }
    
    @ViewBuilder
    var mainMenuContent: some View {
        VStack(spacing: 0) {
            // Header Button - Combines title and action with streak
            Button(action: { 
                // Close the menu first
                NSApplication.shared.sendAction(#selector(NSMenu.cancelTracking), to: nil, from: nil)
                // Then show Touch Grass mode after a small delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    manager.showTouchGrassMode()
                }
            }) {
                HStack {
                    HStack(spacing: 8) {
                        GrassIcon(isActive: false, size: 16)
                            .foregroundColor(.white)
                        Text("Touch Grass")
                            .font(DesignSystem.Typography.bodyLarge)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    if manager.currentStreak > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(DesignSystem.Typography.caption)
                            Text("\(manager.currentStreak)")
                                .font(DesignSystem.Typography.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.2))
                        )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(DesignSystem.Colors.primaryGreen)
            }
            .buttonStyle(PlainButtonStyle())
            
            Divider()
            
            // Location Permission Alert - only show if permission is not determined
            if shouldShowLocationAlert() {
                Button(action: requestLocationPermission) {
                    HStack(spacing: 8) {
                        Image(systemName: "location.slash.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Enable weather suggestions")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.primary)
                            Text("Click to allow location access")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "location.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.orange)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.orange.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .overlay(alignment: .topTrailing) {
                    Button(action: dismissLocationAlert) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(6)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                
                Divider()
            }
                
            // Calendar Status (if connected) - Simplified
            if let calManager = manager.calendarManager,
               calManager.hasCalendarAccess,
               !calManager.selectedCalendarIdentifiers.isEmpty {
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("CALENDAR")
                        .font(DesignSystem.Typography.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                    
                    Group {
                        if let currentEvent = calManager.currentEvent {
                            // In meeting
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 5, height: 5)
                                Text("In meeting until \(calManager.formatEventTime(currentEvent.endDate))")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.bottom, 8)
                        } else if calManager.nextEvent != nil,
                                  let timeUntil = calManager.timeUntilNextEvent {
                            // Free time between meetings
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 5, height: 5)
                                Text("Free for \(calManager.formatTimeUntilEvent(timeUntil))")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.bottom, 8)
                        } else {
                            // Check if work day is over or just no meetings
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 5, height: 5)
                                Text(calendarStatusMessage(calManager: calManager))
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.bottom, 8)
                        }
                    }
                }
            }
            
            // Add divider between calendar and water sections
            if let calManager = manager.calendarManager,
               calManager.hasCalendarAccess,
               !calManager.selectedCalendarIdentifiers.isEmpty,
               manager.waterTrackingEnabled {
                Divider()
                    .padding(.vertical, 4)
            }
                
            // Water Section - clean single line
            if manager.waterTrackingEnabled {
                VStack(alignment: .leading, spacing: 6) {
                    Text("HYDRATION")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.7))
                        .padding(.horizontal, 12)
                        .padding(.top, 4)
                    
                    HStack {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 13))
                            .foregroundColor(Color(red: 0.0, green: 0.5, blue: 1.0))
                        
                        Text("\(manager.currentWaterIntake * 8) / 64 oz")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: { manager.logWater(1) }) {
                            Text("+8oz")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(red: 0.0, green: 0.5, blue: 1.0))
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                }
            }
            
            Divider()
            
            // Timer Section - Simplified
            VStack(alignment: .leading, spacing: 6) {
                Text("REMINDER")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                
                HStack {
                    Text(manager.isPaused ? "Paused" : "Next in \(nextReminderText)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: { 
                        if manager.isPaused {
                            manager.resume()
                        } else {
                            manager.pause()
                        }
                    }) {
                        Image(systemName: manager.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 16))
                            .foregroundColor(manager.isPaused ? Color(red: 0.0, green: 0.6, blue: 0.0) : .secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
            
            Spacer()
            
            Divider()
            
            // Check for Updates
            HStack {
                Button(action: { checkForUpdates() }) {
                    HStack {
                        Label("Check for Updates", systemImage: "arrow.triangle.2.circlepath")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if UpdateManager.shared.updateAvailable {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            
            Divider()
            
            // Footer - Clean and minimal
            HStack {
                Button(action: { openSettings() }) {
                    Label("Settings", systemImage: "gearshape")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Button(action: { NSApplication.shared.terminate(nil) }) {
                    Label("Quit", systemImage: "xmark.circle")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(width: 240)
    }
    
    private func calendarStatusMessage(calManager: CalendarManager) -> String {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let isWeekend = calendar.isDateInWeekend(now)
        
        if isWeekend {
            return "Weekend - enjoy your time off!"
        } else if hour >= calManager.workEndHour {
            return "Work day complete"
        } else if hour < calManager.workStartHour {
            return "Work day hasn't started"
        } else {
            return "No meetings scheduled"
        }
    }
    
    private func openSettings() {
        customizationWindow = CustomizationWindowController(
            reminderManager: manager,
            onComplete: {
                // Settings saved
            }
        )
        customizationWindow?.showCustomization()
    }
    
    private func checkForUpdates() {
        Task {
            await UpdateManager.shared.checkForUpdates(silent: false)
        }
    }
    
    private func shouldShowLocationAlert() -> Bool {
        // Don't show if user has dismissed it
        if locationAlertDismissed {
            return false
        }
        
        let status = locationManager.authorizationStatus
        #if DEBUG
        NSLog("Location permission status: \(status.rawValue)")
        #endif
        
        // Only show alert if permission hasn't been determined yet
        // Don't show for denied/restricted (user made their choice)
        // Don't show for authorized (already have permission)
        return status == .notDetermined
    }
    
    private func requestLocationPermission() {
        let status = locationManager.authorizationStatus
        
        if status == .notDetermined {
            // Request permission - this will show the system dialog
            locationManager.requestAlwaysAuthorization()
            // The LocationPermissionManager will automatically update authorizationStatus
            // which will trigger a re-render and hide the alert if permission is granted
        } else if status == .denied || status == .restricted {
            // If already denied, we have to send them to Settings
            openLocationSettings()
        }
    }
    
    private func openLocationSettings() {
        // Open System Settings to the Location Services pane
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func dismissLocationAlert() {
        locationAlertDismissed = true
        // Save dismissal preference
        UserDefaults.standard.set(true, forKey: "TouchGrass.locationAlertDismissed")
    }
}

struct MenuButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    let isHovered: Bool
    let onHover: (Bool) -> Void
    var tintColor: Color = .accentColor
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(isHovered ? tintColor : .secondary)
                    .frame(width: 20)
                Text(title)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(isHovered ? .primary : .primary.opacity(0.9))
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover(perform: onHover)
    }
}

// MARK: - Notification Delegate
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    weak var reminderManager: ReminderManager?
    
    // Present notifications even when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                                willPresent notification: UNNotification, 
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show banner and play sound even when app is active
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        // When user taps notification, open Touch Grass window
        DispatchQueue.main.async { [weak self] in
            self?.reminderManager?.showTouchGrassMode()
        }
        completionHandler()
    }
}
