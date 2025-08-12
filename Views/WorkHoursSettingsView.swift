import SwiftUI

struct WorkHoursSettingsView: View {
    @ObservedObject var manager: ReminderManager
    @Environment(\.dismiss) private var dismiss
    @State private var workStartHour = 9
    @State private var workStartMinute = 0
    @State private var workEndHour = 17
    @State private var workEndMinute = 0
    @State private var workDays: Set<WorkDay> = [.monday, .tuesday, .wednesday, .thursday, .friday]
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "clock")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
                Text("Work Hours Settings")
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)
            
            VStack(alignment: .leading, spacing: 16) {
                // Work Days
                VStack(alignment: .leading, spacing: 8) {
                    Text("Work Days")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        ForEach(WorkDay.allCases, id: \.self) { day in
                            Toggle(isOn: Binding(
                                get: { workDays.contains(day) },
                                set: { isOn in
                                    if isOn {
                                        workDays.insert(day)
                                    } else {
                                        workDays.remove(day)
                                    }
                                }
                            )) {
                                Text(dayLabel(for: day))
                                    .font(.system(size: 11))
                            }
                            .toggleStyle(.button)
                            .controlSize(.small)
                        }
                    }
                }
                
                Divider()
                
                // Work Hours
                HStack(spacing: 40) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Start Time", systemImage: "sunrise")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Picker("Hour", selection: $workStartHour) {
                                ForEach(0..<24) { hour in
                                    Text(String(format: "%02d", hour)).tag(hour)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 60)
                            
                            Text(":")
                            
                            Picker("Minute", selection: $workStartMinute) {
                                ForEach([0, 15, 30, 45], id: \.self) { minute in
                                    Text(String(format: "%02d", minute)).tag(minute)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 60)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("End Time", systemImage: "sunset")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Picker("Hour", selection: $workEndHour) {
                                ForEach(0..<24) { hour in
                                    Text(String(format: "%02d", hour)).tag(hour)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 60)
                            
                            Text(":")
                            
                            Picker("Minute", selection: $workEndMinute) {
                                ForEach([0, 15, 30, 45], id: \.self) { minute in
                                    Text(String(format: "%02d", minute)).tag(minute)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 60)
                        }
                    }
                }
                
                // Summary
                Text("Reminders active \(formatScheduleSummary())")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
            .padding(.horizontal)
            
            Divider()
            
            // Buttons
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("Save") {
                    saveSettings()
                    dismiss()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 400, height: 320)
        .onAppear {
            loadCurrentSettings()
        }
    }
    
    private func dayLabel(for day: WorkDay) -> String {
        switch day {
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        case .sunday: return "Sun"
        }
    }
    
    private func formatScheduleSummary() -> String {
        let daysText = workDays.isEmpty ? "Never" : 
            workDays.count == 7 ? "Every day" :
            workDays.count == 5 && !workDays.contains(.saturday) && !workDays.contains(.sunday) ? "Weekdays" :
            workDays.count == 2 && workDays.contains(.saturday) && workDays.contains(.sunday) ? "Weekends" :
            "\(workDays.count) days/week"
        
        let timeText = String(
            format: "%02d:%02d - %02d:%02d",
            workStartHour,
            workStartMinute,
            workEndHour,
            workEndMinute
        )
        
        return "\(daysText), \(timeText)"
    }
    
    private func loadCurrentSettings() {
        workStartHour = manager.currentWorkStartHour
        workStartMinute = manager.currentWorkStartMinute
        workEndHour = manager.currentWorkEndHour
        workEndMinute = manager.currentWorkEndMinute
        workDays = manager.currentWorkDays
    }
    
    private func saveSettings() {
        manager.setWorkHours(
            start: (hour: workStartHour, minute: workStartMinute),
            end: (hour: workEndHour, minute: workEndMinute),
            days: workDays
        )
    }
}
