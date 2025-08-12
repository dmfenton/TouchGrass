import SwiftUI
import UserNotifications
import EventKit

struct SimpleOnboardingWindow: View {
    @ObservedObject var reminderManager: ReminderManager
    @StateObject private var calendarManager = CalendarManager()
    @Environment(\.dismiss) private var dismiss
    
    @State private var showCustomization = false
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
            // Asian time zones
            _workStartHour = State(initialValue: 8)
            _workEndHour = State(initialValue: 17)
        } else if hoursFromUTC >= -1 && hoursFromUTC <= 3 {
            // European time zones  
            _workStartHour = State(initialValue: 9)
            _workEndHour = State(initialValue: 18)
        } else {
            // Americas and others
            _workStartHour = State(initialValue: 9)
            _workEndHour = State(initialValue: 17)
        }
        
        _reminderInterval = State(initialValue: 45)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 56))
                    .foregroundColor(.accentColor)
                    .symbolRenderingMode(.hierarchical)
                
                Text("Welcome to Touch Grass")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Your posture reminder that actually works")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            .padding(.bottom, 30)
            
            // Quick setup summary
            VStack(alignment: .leading, spacing: 12) {
                Label {
                    Text("Remind me every **\(Int(reminderInterval)) minutes**")
                        .font(.body)
                } icon: {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.accentColor)
                }
                
                Label {
                    Text("During work hours **\(formatHour(workStartHour)) - \(formatHour(workEndHour))**")
                        .font(.body)
                } icon: {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.accentColor)
                }
                
                Label {
                    Text("Smart timing that adapts to your habits")
                        .font(.body)
                } icon: {
                    Image(systemName: "wand.and.stars")
                        .foregroundColor(.accentColor)
                }
                
                if calendarManager.hasCalendarAccess && !calendarManager.selectedCalendarIdentifiers.isEmpty {
                    Label {
                        Text("Auto-pause during calendar events")
                            .font(.body)
                    } icon: {
                        Image(systemName: "calendar.badge.checkmark")
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 20)
            .background(Color.accentColor.opacity(0.08))
            .cornerRadius(12)
            .padding(.horizontal, 40)
            
            // Optional customization
            if showCustomization {
                VStack(spacing: 16) {
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Interval slider
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reminder Interval")
                            .font(.headline)
                        HStack {
                            Text("15m")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Slider(value: $reminderInterval, in: 15...90, step: 15)
                            Text("90m")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Work hours
                    HStack(spacing: 20) {
                        VStack(alignment: .leading) {
                            Text("Start")
                                .font(.headline)
                            Picker("", selection: $workStartHour) {
                                ForEach(6..<13, id: \.self) { hour in
                                    Text(formatHour(hour)).tag(hour)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 100)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("End")
                                .font(.headline)
                            Picker("", selection: $workEndHour) {
                                ForEach(15..<21, id: \.self) { hour in
                                    Text(formatHour(hour)).tag(hour)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 100)
                        }
                    }
                    
                    // Options
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Smart timing (adapts to your usage)", isOn: $enableSmartTiming)
                            .toggleStyle(.checkbox)
                        Toggle("Start Touch Grass at login", isOn: $startAtLogin)
                            .toggleStyle(.checkbox)
                    }
                    .font(.system(size: 13))
                    
                    // Calendar selection
                    if calendarManager.hasCalendarAccess {
                        Divider()
                            .padding(.vertical, 8)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Calendars to Monitor")
                                .font(.headline)
                            Text("Reminders will pause during events")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ScrollView {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(calendarManager.availableCalendars, id: \.calendarIdentifier) { calendar in
                                        CalendarToggleRow(calendar: calendar, calendarManager: calendarManager)
                                    }
                                }
                            }
                            .frame(maxHeight: 100)
                            .padding(8)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                        }
                    } else if !calendarPermissionRequested {
                        Button("Enable Calendar Integration") {
                            calendarPermissionRequested = true
                            calendarManager.requestCalendarAccess { _ in }
                        }
                        .buttonStyle(.link)
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 60)
                .padding(.vertical, 20)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Customize button
            if !showCustomization {
                Button(action: { withAnimation { showCustomization.toggle() } }, label: {
                    Text("Customize Settings")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
                .padding(.top, 12)
            }
            
            Spacer()
            
            // Permissions notice (non-blocking)
            HStack(spacing: 8) {
                Image(systemName: notificationStatus == .authorized ? "checkmark.circle.fill" : "info.circle")
                    .foregroundColor(notificationStatus == .authorized ? .green : .secondary)
                    .font(.system(size: 14))
                
                Text(notificationStatus == .authorized ? 
                     "Notifications enabled" : 
                     "We'll ask for notification permission after setup")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 12)
            
            // Action buttons
            HStack(spacing: 12) {
                if showCustomization {
                    Button("Use Defaults") {
                        // Reset to defaults
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
                
                Button("Start Using Touch Grass") {
                    completeOnboarding()
                }
                .controlSize(.large)
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(.borderedProminent)
            }
            .padding(30)
        }
        .frame(width: 500, height: showCustomization ? (calendarManager.hasCalendarAccess ? 780 : 680) : 520)
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
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in
                // Permission handled, but we don't block on it
            }
        }
        
        dismiss()
    }
    
    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        var components = DateComponents()
        components.hour = hour
        components.minute = 0
        
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        
        // Fallback to 24-hour format
        return String(format: "%02d:00", hour)
    }
}

struct CalendarToggleRow: View {
    let calendar: EKCalendar
    @ObservedObject var calendarManager: CalendarManager
    
    var body: some View {
        Toggle(isOn: Binding(
            get: { calendarManager.isCalendarSelected(calendar) },
            set: { _ in calendarManager.toggleCalendar(calendar) }
        )) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color(cgColor: calendar.cgColor))
                    .frame(width: 10, height: 10)
                Text(calendar.title)
                    .font(.system(size: 12))
                    .lineLimit(1)
            }
        }
        .toggleStyle(.checkbox)
        .controlSize(.small)
    }
}
