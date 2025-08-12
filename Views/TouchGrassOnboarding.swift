import SwiftUI
import UserNotifications
import EventKit

struct TouchGrassOnboarding: View {
    @ObservedObject var reminderManager: ReminderManager
    @StateObject private var calendarManager = CalendarManager()
    @Environment(\.dismiss) private var dismiss
    
    @State private var showCustomization = true  // Show by default for better discoverability
    @State private var workStartHour: Int
    @State private var workEndHour: Int  
    @State private var reminderInterval: Double
    @State private var enableSmartTiming = true
    @State private var startAtLogin = false
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var calendarPermissionRequested = false
    
    init(reminderManager: ReminderManager) {
        self.reminderManager = reminderManager
        
        // Set intelligent defaults based on timezone
        let timeZone = TimeZone.current
        let hoursFromUTC = timeZone.secondsFromGMT() / 3600
        
        if hoursFromUTC >= 5 && hoursFromUTC <= 10 {
            _workStartHour = State(initialValue: 8)
            _workEndHour = State(initialValue: 17)
        } else if hoursFromUTC >= -1 && hoursFromUTC <= 3 {
            _workStartHour = State(initialValue: 9)
            _workEndHour = State(initialValue: 18)
        } else {
            _workStartHour = State(initialValue: 9)
            _workEndHour = State(initialValue: 17)
        }
        
        _reminderInterval = State(initialValue: 45)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            OnboardingHeaderView()
            
            // Main message
            VStack(spacing: 16) {
                Text("Let's keep you human during work")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Sitting all day is rough. We'll remind you to move, stretch, and literally go touch some grass.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // Quick setup summary with nature theme
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 18))
                        .foregroundColor(.green)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Stand up every **\(Int(reminderInterval)) minutes**")
                            .font(.system(size: 13, weight: .medium))
                        Text("Your body will thank you")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "clock.badge.checkmark")
                        .font(.system(size: 18))
                        .foregroundColor(.green)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Active **\(formatHour(workStartHour)) - \(formatHour(workEndHour))**")
                            .font(.system(size: 13, weight: .medium))
                        Text("Only during work hours")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.green)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Build healthy habits")
                            .font(.system(size: 13, weight: .medium))
                        Text("Track streaks, feel better")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                
                if calendarManager.hasCalendarAccess && !calendarManager.selectedCalendarIdentifiers.isEmpty {
                    HStack(spacing: 12) {
                        Image(systemName: "calendar")
                            .font(.system(size: 18))
                            .foregroundColor(.green)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Meeting-aware reminders")
                                .font(.system(size: 13, weight: .medium))
                            Text("Pauses during your calls")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.green.opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 30)
            .padding(.vertical, 20)
            
            // Optional customization (collapsed by default)
            if showCustomization {
                OnboardingCustomizationView(
                    reminderInterval: $reminderInterval,
                    workStartHour: $workStartHour,
                    workEndHour: $workEndHour,
                    enableSmartTiming: $enableSmartTiming,
                    startAtLogin: $startAtLogin,
                    calendarManager: calendarManager,
                    calendarPermissionRequested: $calendarPermissionRequested
                )
            }
            
            // Customize button
            if !showCustomization {
                Button(action: { withAnimation(.spring(response: 0.3)) { showCustomization.toggle() } }, label: {
                    Label("Customize", systemImage: "slider.horizontal.3")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                })
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
            
            Spacer()
            
            // Bottom section
            VStack(spacing: 16) {
                // Motivational message
                Text("🌱 Ready to feel better at work?")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                // Action buttons
                HStack(spacing: 12) {
                    if showCustomization {
                        Button("Reset") {
                            reminderInterval = 45
                            workStartHour = 9
                            workEndHour = 17
                            enableSmartTiming = true
                            startAtLogin = false
                            withAnimation {
                                showCustomization = false
                            }
                        }
                        .controlSize(.large)
                    }
                    
                    Spacer()
                    
                    Button(action: completeOnboarding) {
                        HStack(spacing: 6) {
                            Text("Let's Go")
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [Color.green, Color.green.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.return, modifiers: [])
                }
            }
            .padding(30)
        }
        .frame(width: 520, height: showCustomization ? 780 : 580)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            checkNotificationStatus()
        }
    }
    
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationStatus = settings.authorizationStatus
            }
        }
    }
    
    private func completeOnboarding() {
        // Apply settings
        reminderManager.intervalMinutes = reminderInterval
        reminderManager.adaptiveIntervalEnabled = enableSmartTiming
        reminderManager.startsAtLogin = startAtLogin
        
        // Set work hours
        reminderManager.setWorkHours(
            start: (workStartHour, 0),
            end: (workEndHour, 0),
            days: [.monday, .tuesday, .wednesday, .thursday, .friday]
        )
        
        // Save calendar settings
        reminderManager.calendarManager = calendarManager
        
        // Mark onboarding complete
        UserDefaults.standard.set(true, forKey: "TouchGrass.hasCompletedOnboarding")
        
        // Request notifications (non-blocking)
        if notificationStatus == .notDetermined {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
        
        dismiss()
    }
    
    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        var components = DateComponents()
        components.hour = hour
        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date).lowercased()
    }
}
