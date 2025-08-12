import SwiftUI
import EventKit

struct OnboardingCustomizationView: View {
    @Binding var reminderInterval: Double
    @Binding var workStartHour: Int
    @Binding var workEndHour: Int
    @Binding var enableSmartTiming: Bool
    @Binding var startAtLogin: Bool
    @ObservedObject var calendarManager: CalendarManager
    @Binding var calendarPermissionRequested: Bool
    
    var body: some View {
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
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Smart Calendar Sync", systemImage: "calendar.badge.clock")
                            .font(.system(size: 13, weight: .semibold))
                        
                        Text("Skip reminders during meetings")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if calendarManager.hasCalendarAccess {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(calendarManager.availableCalendars, id: \.calendarIdentifier) { calendar in
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
                        } else {
                            Button(action: {
                                calendarPermissionRequested = true
                                calendarManager.requestCalendarAccess { _ in
                                    // Calendar list is automatically loaded on success
                                }
                            }, label: {
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
                            })
                            .buttonStyle(.plain)
                        }
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
    
    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        var components = DateComponents()
        components.hour = hour
        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date).lowercased()
    }
}
