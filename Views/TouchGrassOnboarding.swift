import SwiftUI
import UserNotifications
import EventKit

struct TouchGrassOnboarding: View {
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
            // Header with grass animation
            VStack(spacing: 20) {
                ZStack {
                    // Grass blades background
                    HStack(spacing: 8) {
                        ForEach(0..<7, id: \.self) { index in
                            GrassBlade(delay: Double(index) * 0.1)
                        }
                    }
                    .frame(height: 60)
                    
                    // Sun/outdoor icon overlay
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.yellow.opacity(0.8))
                        .offset(x: -40, y: -15)
                }
                
                VStack(spacing: 8) {
                    Text("Touch Grass")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.green.opacity(0.9))
                    
                    Text("Your guide to surviving the workday")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 30)
            .padding(.bottom, 25)
            
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
                VStack(spacing: 16) {
                    Divider()
                        .padding(.horizontal, 30)
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // Interval slider
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Break Frequency", systemImage: "timer")
                                    .font(.system(size: 13, weight: .semibold))
                                
                                HStack {
                                    Text("15m")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Slider(value: $reminderInterval, in: 15...90, step: 15)
                                        .tint(.green)
                                    Text("90m")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text("\(Int(reminderInterval)) minutes between breaks")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(4)
                            }
                            
                            // Work hours
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Work Hours", systemImage: "sun.and.horizon")
                                    .font(.system(size: 13, weight: .semibold))
                                
                                HStack(spacing: 20) {
                                    VStack(alignment: .leading) {
                                        Text("Start")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Picker("", selection: $workStartHour) {
                                            ForEach(5..<13, id: \.self) { hour in
                                                Text(formatHour(hour)).tag(hour)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .frame(width: 100)
                                    }
                                    
                                    VStack(alignment: .leading) {
                                        Text("End")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Picker("", selection: $workEndHour) {
                                            ForEach(14..<22, id: \.self) { hour in
                                                Text(formatHour(hour)).tag(hour)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .frame(width: 100)
                                    }
                                }
                            }
                            
                            // Calendar selection
                            if calendarManager.hasCalendarAccess {
                                VStack(alignment: .leading, spacing: 8) {
                                    Label("Smart Calendar Sync", systemImage: "calendar.badge.clock")
                                        .font(.system(size: 13, weight: .semibold))
                                    
                                    Text("Skip reminders during meetings")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    ScrollView {
                                        VStack(alignment: .leading, spacing: 4) {
                                            ForEach(
                                                calendarManager.availableCalendars,
                                                id: \.calendarIdentifier
                                            ) { calendar in
                                                TouchGrassCalendarRow(
                                                    calendar: calendar,
                                                    calendarManager: calendarManager
                                                )
                                            }
                                        }
                                    }
                                    .frame(maxHeight: 80)
                                    .padding(8)
                                    .background(Color(NSColor.controlBackgroundColor))
                                    .cornerRadius(6)
                                }
                            } else if !calendarPermissionRequested {
                                Button(action: {
                                    calendarPermissionRequested = true
                                    calendarManager.requestCalendarAccess { _ in }
                                }, label: {
                                    Label("Connect Calendar", systemImage: "calendar.badge.plus")
                                        .font(.system(size: 12))
                                        .foregroundColor(.green)
                                }
                                .buttonStyle(.plain)
                            }
                            
                            // Options
                            VStack(alignment: .leading, spacing: 10) {
                                Toggle(isOn: $enableSmartTiming) {
                                    Label("Adaptive timing", systemImage: "wand.and.stars")
                                        .font(.system(size: 12))
                                }
                                .toggleStyle(.checkbox)
                                
                                Toggle(isOn: $startAtLogin) {
                                    Label("Launch at startup", systemImage: "power")
                                        .font(.system(size: 12))
                                }
                                .toggleStyle(.checkbox)
                            }
                        }
                        .padding(.horizontal, 40)
                    }
                    .frame(maxHeight: 200)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Customize button
            if !showCustomization {
                Button(action: { withAnimation(.spring(response: 0.3)) { showCustomization.toggle() } }, label: {
                    Label("Customize", systemImage: "slider.horizontal.3")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                }
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
        .frame(width: 520, height: showCustomization ? 740 : 580)
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
        formatter.timeStyle = .short
        
        var components = DateComponents()
        components.hour = hour
        components.minute = 0
        
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        
        return String(format: "%02d:00", hour)
    }
}

struct GrassBlade: View {
    let delay: Double
    @State private var isSwaying = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(
                LinearGradient(
                    colors: [Color.green.opacity(0.6), Color.green],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(width: 4, height: 40)
            .rotationEffect(.degrees(isSwaying ? -3 : 3), anchor: .bottom)
            .animation(
                Animation.easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true)
                    .delay(delay),
                value: isSwaying
            )
            .onAppear {
                isSwaying = true
            }
    }
}

struct TouchGrassCalendarRow: View {
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
