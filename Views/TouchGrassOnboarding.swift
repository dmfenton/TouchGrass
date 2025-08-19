import SwiftUI
import UserNotifications
import EventKit
import CoreLocation

struct TouchGrassOnboarding: View {
    @ObservedObject var reminderManager: ReminderManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var customizationWindow: CustomizationWindowController?
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var hasRequestedCalendarAccess = false
    @State private var hasRequestedLocationAccess = false
    @State private var locationStatus: CLAuthorizationStatus = .notDetermined
    @State private var selectedCalendars: Set<String> = []
    
    private let locationManager = CLLocationManager()
    
    var body: some View {
        VStack(spacing: 0) {
            OnboardingHeaderView()
            
            // Main message
            Text("Sitting all day is rough. We'll remind you to move, stretch, hydrate, and literally go touch some grass.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
            
            // Features list with nature theme
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(
                    icon: "figure.walk",
                    title: "Regular movement reminders",
                    subtitle: "Stand up and move every 45 minutes"
                )
                
                FeatureRow(
                    icon: "figure.flexibility",
                    title: "Guided exercise routines",
                    subtitle: "Stretches, posture resets, and breathing"
                )
                
                FeatureRow(
                    icon: "drop.fill",
                    title: "Water tracking",
                    subtitle: "Track daily hydration goals"
                )
                
                FeatureRow(
                    icon: "leaf.fill",
                    title: "Multiple break activities",
                    subtitle: "Touch grass, stretch, or meditate"
                )
                
                FeatureRow(
                    icon: "cloud.sun.fill",
                    title: "Weather-aware suggestions",
                    subtitle: "Smart recommendations based on conditions"
                )
                
                FeatureRow(
                    icon: "calendar",
                    title: "Calendar aware",
                    subtitle: "See your schedule at a glance"
                )
                
                FeatureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Build healthy habits",
                    subtitle: "Track streaks and progress"
                )
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.green.opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 30)
            
            // Calendar Selection Section
            if let calManager = reminderManager.calendarManager {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.green)
                        Text("Connect Your Calendar (Optional)")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                    }
                    
                    if !calManager.hasCalendarAccess && !hasRequestedCalendarAccess {
                        Button(action: requestCalendarAccess) {
                            HStack {
                                Image(systemName: "lock.shield")
                                    .font(.system(size: 12))
                                Text("Grant Calendar Access")
                                    .font(.system(size: 12))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.blue.opacity(0.1))
                            )
                            .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    } else if calManager.hasCalendarAccess {
                        VStack(alignment: .leading, spacing: 8) {
                            if calManager.availableCalendars.isEmpty {
                                Text("No calendars found")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Select calendars to monitor:")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                
                                ForEach(calManager.availableCalendars, id: \.calendarIdentifier) { calendar in
                                    HStack {
                                        Image(systemName: selectedCalendars.contains(calendar.calendarIdentifier) ? "checkmark.square.fill" : "square")
                                            .font(.system(size: 14))
                                            .foregroundColor(selectedCalendars.contains(calendar.calendarIdentifier) ? .green : .secondary)
                                        
                                        Circle()
                                            .fill(Color(calendar.color ?? .gray))
                                            .frame(width: 8, height: 8)
                                        
                                        Text(calendar.title)
                                            .font(.system(size: 12))
                                        
                                        Spacer()
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        toggleCalendar(calendar)
                                    }
                                }
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )
                    }
                    
                    Text("Touch Grass helps you maximize breaks between meetings")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.green.opacity(0.03))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.green.opacity(0.1), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 30)
                .padding(.top, 16)
            }
            
            // Location Permission Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                    Text("Enable Weather-Based Suggestions (Optional)")
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                }
                
                if locationStatus != .authorizedAlways && locationStatus != .authorizedWhenInUse && !hasRequestedLocationAccess {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Get smarter activity suggestions")
                                .font(.system(size: 11))
                            Text("We'll suggest outdoor breaks when it's nice outside")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: requestLocationAccess) {
                            HStack {
                                Image(systemName: "location.circle")
                                    .font(.system(size: 12))
                                Text("Enable Location")
                                    .font(.system(size: 12))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.blue.opacity(0.1))
                            )
                            .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                } else if locationStatus == .authorizedAlways || locationStatus == .authorizedWhenInUse {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 12))
                        Text("Location enabled - you'll get weather-aware suggestions")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                } else if locationStatus == .denied {
                    Text("Location access denied. You can enable it later in System Settings.")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.blue.opacity(0.1), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 30)
            .padding(.top, 8)
            
            Spacer()
            
            // Bottom section with two clear CTAs
            VStack(spacing: 16) {
                Text("🌱 Ready to feel better at work?")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 16) {
                    Button(action: openCustomization) {
                        HStack(spacing: 6) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 13))
                            Text("Customize")
                        }
                        .frame(width: 120)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.green, lineWidth: 1.5)
                        )
                        .foregroundColor(.green)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: quickStart) {
                        HStack(spacing: 6) {
                            Text("Let's Go")
                            Image(systemName: "arrow.right")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .frame(width: 140)
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
        .frame(width: 520, height: 780)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            checkNotificationStatus()
            checkLocationStatus()
            if let calManager = reminderManager.calendarManager {
                selectedCalendars = calManager.selectedCalendarIdentifiers
            }
        }
    }
    
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationStatus = settings.authorizationStatus
            }
        }
    }
    
    private func checkLocationStatus() {
        locationStatus = locationManager.authorizationStatus
    }
    
    private func requestLocationAccess() {
        hasRequestedLocationAccess = true
        locationManager.requestWhenInUseAuthorization()
        
        // Check status after a delay (authorization happens asynchronously)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            locationStatus = locationManager.authorizationStatus
        }
    }
    
    private func requestCalendarAccess() {
        hasRequestedCalendarAccess = true
        reminderManager.calendarManager?.requestCalendarAccess { granted in
            if granted {
                // Refresh the view
            }
        }
    }
    
    private func toggleCalendar(_ calendar: EKCalendar) {
        if selectedCalendars.contains(calendar.calendarIdentifier) {
            selectedCalendars.remove(calendar.calendarIdentifier)
        } else {
            selectedCalendars.insert(calendar.calendarIdentifier)
        }
        
        // Update the calendar manager
        reminderManager.calendarManager?.selectedCalendarIdentifiers = selectedCalendars
        reminderManager.calendarManager?.saveSelectedCalendars()
    }
    
    private func openCustomization() {
        // Close the onboarding window first
        dismiss()
        
        // Then open customization
        customizationWindow = CustomizationWindowController(
            reminderManager: reminderManager,
            onComplete: {
                // Mark onboarding as complete after customization
                UserDefaults.standard.set(true, forKey: "TouchGrass.hasCompletedOnboarding")
                
                // Request notifications if needed (note: can't capture self as it's a struct)
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
            }
        )
        customizationWindow?.showCustomization()
    }
    
    private func quickStart() {
        // Use default settings
        reminderManager.intervalMinutes = 45
        reminderManager.adaptiveIntervalEnabled = true
        reminderManager.startsAtLogin = false
        reminderManager.waterTrackingEnabled = true
        reminderManager.dailyWaterGoal = 8
        reminderManager.waterUnit = .glasses
        
        // Set standard work hours
        reminderManager.setWorkHours(
            start: (9, 0),
            end: (17, 0),
            days: [.monday, .tuesday, .wednesday, .thursday, .friday]
        )
        
        // Save calendar selections
        if let calManager = reminderManager.calendarManager {
            calManager.selectedCalendarIdentifiers = selectedCalendars
            calManager.saveSelectedCalendars()
        }
        
        completeOnboarding()
    }
    
    private func completeOnboarding() {
        // Mark onboarding complete
        UserDefaults.standard.set(true, forKey: "TouchGrass.hasCompletedOnboarding")
        
        // Request notifications if needed
        if notificationStatus == .notDetermined {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
        
        dismiss()
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.green)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}
