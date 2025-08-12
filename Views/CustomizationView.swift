import SwiftUI
import EventKit

struct CustomizationView: View {
    @ObservedObject var reminderManager: ReminderManager
    @StateObject private var calendarManager = CalendarManager()
    let onComplete: () -> Void
    
    @State private var workStartHour: Int = 9
    @State private var workEndHour: Int = 17
    @State private var reminderInterval: Double = 45
    @State private var enableSmartTiming = true
    @State private var startAtLogin = false
    @State private var calendarPermissionRequested = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 32))
                    .foregroundColor(.green)
                
                Text("Customize Your Experience")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Set up Touch Grass to work best for you")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 25)
            .padding(.bottom, 20)
            
            Divider()
                .padding(.horizontal, 20)
            
            // Settings
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
                    Label("Calendar Integration", systemImage: "calendar.badge.clock")
                        .font(.system(size: 14, weight: .semibold))
                    
                    Text("Skip reminders during meetings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if calendarManager.hasCalendarAccess {
                        HStack {
                            if calendarManager.selectedCalendarIdentifiers.isEmpty {
                                Text("Select calendars to monitor")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            } else {
                                Text("\(calendarManager.selectedCalendarIdentifiers.count) calendar(s) selected")
                                    .font(.system(size: 12))
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            Menu {
                                ForEach(calendarManager.availableCalendars, id: \.calendarIdentifier) { calendar in
                                    Button(action: {
                                        calendarManager.toggleCalendar(calendar)
                                    }) {
                                        HStack {
                                            if calendarManager.selectedCalendarIdentifiers.contains(calendar.calendarIdentifier) {
                                                Image(systemName: "checkmark")
                                            }
                                            Circle()
                                                .fill(Color(calendar.cgColor))
                                                .frame(width: 8, height: 8)
                                            Text(calendar.title)
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text("Choose")
                                        .font(.system(size: 12))
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 10))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.1))
                                .foregroundColor(.green)
                                .cornerRadius(6)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                    } else {
                        Button(action: {
                            calendarPermissionRequested = true
                            calendarManager.requestCalendarAccess { _ in }
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
                }
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 25)
            
            Spacer()
            
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
        .frame(width: 480, height: 580)
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
        
        if let existingCalManager = reminderManager.calendarManager {
            // Use existing calendar manager if available
            calendarManager.selectedCalendarIdentifiers = existingCalManager.selectedCalendarIdentifiers
        }
    }
    
    private func saveAndClose() {
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