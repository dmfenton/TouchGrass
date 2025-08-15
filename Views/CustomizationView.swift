import SwiftUI
import EventKit

struct CustomizationView: View {
    @ObservedObject var reminderManager: ReminderManager
    let onComplete: () -> Void
    
    @State private var workStartHour: Int = 9
    @State private var workEndHour: Int = 17
    @State private var reminderInterval: Double = 45
    @State private var enableSmartTiming = true
    @State private var startAtLogin = false
    @State private var calendarPermissionRequested = false
    @State private var waterTrackingEnabled = true
    @State private var dailyWaterGoal = 8
    @State private var waterUnit: WaterUnit = .glasses
    
    private var calendarManager: CalendarManager? {
        reminderManager.calendarManager
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 24))
                    .foregroundColor(.green)
                
                Text("Customize Your Experience")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 15)
            
            Divider()
                .padding(.horizontal, 20)
            
            // Settings in ScrollView
            ScrollView {
                VStack(spacing: 24) {
                // Interval slider
                VStack(alignment: .leading, spacing: 10) {
                    Label("Break Frequency", systemImage: "timer")
                        .font(.system(size: 14, weight: .semibold))
                    
                    VStack(spacing: 6) {
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
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                // Work hours
                VStack(alignment: .leading, spacing: 10) {
                    Label("Work Hours", systemImage: "sun.and.horizon")
                        .font(.system(size: 14, weight: .semibold))
                    
                    HStack(spacing: 40) {
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
                        
                        Spacer()
                    }
                }
                
                // Calendar
                VStack(alignment: .leading, spacing: 10) {
                    Label("Calendar Awareness", systemImage: "calendar.badge.clock")
                        .font(.system(size: 14, weight: .semibold))
                    
                    Text("See upcoming meetings to find best times")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if calendarManager?.hasCalendarAccess == true {
                        VStack(alignment: .leading, spacing: 8) {
                            // Show selected calendars count
                            if !(calendarManager?.selectedCalendarIdentifiers.isEmpty ?? true) {
                                Text("\(calendarManager?.selectedCalendarIdentifiers.count ?? 0) calendar(s) selected")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            
                            // Simple button that opens multi-select menu
                            Menu("Select Calendars") {
                                ForEach(calendarManager?.availableCalendars ?? [], id: \.calendarIdentifier) { calendar in
                                    Button(action: {
                                        calendarManager?.toggleCalendar(calendar)
                                    }) {
                                        HStack {
                                            if calendarManager?.selectedCalendarIdentifiers.contains(calendar.calendarIdentifier) == true {
                                                Image(systemName: "checkmark")
                                            }
                                            Text(calendar.title)
                                        }
                                    }
                                }
                            }
                            .menuStyle(.borderedButton)
                        }
                    } else {
                        Button(action: {
                            calendarPermissionRequested = true
                            if reminderManager.calendarManager == nil {
                                reminderManager.calendarManager = CalendarManager()
                            }
                            reminderManager.calendarManager?.requestCalendarAccess { _ in }
                        }) {
                            HStack {
                                Image(systemName: "calendar.badge.plus")
                                Text("Connect Calendar")
                            }
                            .font(.system(size: 13))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.green.opacity(0.1))
                            .foregroundColor(.green)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Water Tracking Section
                VStack(alignment: .leading, spacing: 10) {
                    Label("Water Tracking", systemImage: "drop.fill")
                        .font(.system(size: 14, weight: .semibold))
                    
                    Toggle(isOn: $waterTrackingEnabled) {
                        Text("Track water intake with reminders")
                            .font(.system(size: 13))
                    }
                    .toggleStyle(.checkbox)
                    
                    if waterTrackingEnabled {
                        VStack(spacing: 10) {
                            HStack {
                                Text("Daily Goal:")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Stepper(value: $dailyWaterGoal, in: 4...16) {
                                    Text("\(dailyWaterGoal) glasses")
                                        .font(.system(size: 12, weight: .medium))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(4)
                                }
                                Spacer()
                            }
                            
                            HStack {
                                Text("Units:")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Picker("", selection: $waterUnit) {
                                    ForEach(WaterUnit.allCases, id: \.self) { unit in
                                        Text(unit.displayName).tag(unit)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 200)
                                Spacer()
                            }
                        }
                        .padding(.leading, 20)
                        .transition(.opacity)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 12)
                .background(Color.blue.opacity(0.03))
                .cornerRadius(8)
                
                // Toggles
                VStack(spacing: 12) {
                    Toggle(isOn: $enableSmartTiming) {
                        Label("Adaptive timing", systemImage: "wand.and.stars")
                            .font(.system(size: 13))
                    }
                    .toggleStyle(.checkbox)
                    
                    Toggle(isOn: $startAtLogin) {
                        Label("Launch at startup", systemImage: "power")
                            .font(.system(size: 13))
                    }
                    .toggleStyle(.checkbox)
                    
                    Toggle(isOn: .init(
                        get: { UpdateManager.shared.autoUpdateEnabled },
                        set: { UpdateManager.shared.autoUpdateEnabled = $0 }
                    )) {
                        Label("Check for updates automatically", systemImage: "arrow.triangle.2.circlepath")
                            .font(.system(size: 13))
                    }
                    .toggleStyle(.checkbox)
                }
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 20)
            }
            
            Spacer(minLength: 10)
            
            Divider()
            
            // Action buttons
            HStack {
                Button("Cancel") {
                    NSApp.keyWindow?.close()
                }
                .controlSize(.large)
                
                Spacer()
                
                Button(action: saveAndClose) {
                    Text("Save Settings")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                colors: [Color.green, Color.green.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.return, modifiers: [])
            }
            .padding(20)
        }
        .frame(width: 480, height: 720)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            loadCurrentSettings()
        }
    }
    
    private func loadCurrentSettings() {
        reminderInterval = reminderManager.intervalMinutes
        enableSmartTiming = reminderManager.adaptiveIntervalEnabled
        startAtLogin = reminderManager.startsAtLogin
        workStartHour = reminderManager.currentWorkStartHour
        workEndHour = reminderManager.currentWorkEndHour
        waterTrackingEnabled = reminderManager.waterTrackingEnabled
        dailyWaterGoal = reminderManager.dailyWaterGoal
        waterUnit = reminderManager.waterUnit
    }
    
    private func saveAndClose() {
        // Apply settings
        reminderManager.intervalMinutes = reminderInterval
        reminderManager.adaptiveIntervalEnabled = enableSmartTiming
        reminderManager.startsAtLogin = startAtLogin
        reminderManager.waterTrackingEnabled = waterTrackingEnabled
        reminderManager.dailyWaterGoal = dailyWaterGoal
        reminderManager.waterUnit = waterUnit
        
        // Set work hours
        reminderManager.setWorkHours(
            start: (workStartHour, 0),
            end: (workEndHour, 0),
            days: [.monday, .tuesday, .wednesday, .thursday, .friday]
        )
        
        // Save calendar settings
        reminderManager.calendarManager?.saveSelectedCalendars()
        
        // Close window
        NSApp.keyWindow?.close()
        onComplete()
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