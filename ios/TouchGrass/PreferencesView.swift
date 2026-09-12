import EventKit
import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject private var store: WellnessStore
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            Form {
                Section("Break reminders") {
                    Toggle("Reminders enabled", isOn: $store.preferences.remindersEnabled)
                    Picker("Every", selection: $store.preferences.intervalMinutes) {
                        ForEach([15, 30, 45, 60, 90], id: \.self) { Text("\($0) minutes").tag($0) }
                    }
                    Button("Allow notifications") { Task { await store.enableNotifications() } }
                    if store.notificationStatus == .denied {
                        Button("Open notification settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                        }
                    }
                }
                Section("Work hours") {
                    Picker("Start", selection: $store.preferences.startHour) {
                        ForEach(0..<store.preferences.endHour, id: \.self) { Text(hour($0)).tag($0) }
                    }
                    Picker("End", selection: $store.preferences.endHour) {
                        ForEach((store.preferences.startHour + 1)..<24, id: \.self) { Text(hour($0)).tag($0) }
                    }
                    ForEach(1...7, id: \.self) { day in
                        Toggle(Calendar.current.weekdaySymbols[day - 1], isOn: Binding(
                            get: { store.preferences.weekdays.contains(day) },
                            set: { enabled in
                                if enabled { store.preferences.weekdays.insert(day) } else { store.preferences.weekdays.remove(day) }
                            }
                        ))
                    }
                }
                Section("Hydration") {
                    Stepper("\(store.preferences.waterGoal) glasses per day", value: $store.preferences.waterGoal, in: 1...24)
                }
                Section {
                    Button("Connect calendars") { Task { await store.enableCalendar() } }
                    ForEach(store.calendars, id: \.calendarIdentifier) { calendar in
                        Toggle(calendar.title, isOn: Binding(
                            get: { store.preferences.calendarIDs.contains(calendar.calendarIdentifier) },
                            set: { enabled in
                                if enabled {
                                    store.preferences.calendarIDs.insert(calendar.calendarIdentifier)
                                } else {
                                    store.preferences.calendarIDs.remove(calendar.calendarIdentifier)
                                }
                            }
                        ))
                    }
                } header: { Text("Meeting awareness") } footer: {
                    Text("""
                    Reminders avoid meetings in your selected calendars.
                    Open Touch Grass after schedule changes to refresh upcoming reminders.
                    iOS limits the number of reminders that can be queued.
                    """)
                }
                Section("Privacy") {
                    Text("Progress and preferences stay on this device. Calendar details are only used here to plan breaks.")
                    Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")")
                }
            }.navigationTitle("Settings")
                .onChange(of: store.preferences) { _, _ in store.scheduleRefresh() }
        }
    }

    private func hour(_ value: Int) -> String {
        let date = Calendar.current.date(bySettingHour: value, minute: 0, second: 0, of: Date()) ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }
}
