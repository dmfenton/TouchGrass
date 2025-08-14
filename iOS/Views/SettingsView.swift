import SwiftUI

struct SettingsView: View {
    @ObservedObject var manager: iOSReminderManager
    @State private var showingAbout = false
    
    var body: some View {
        NavigationView {
            Form {
                // Reminder Settings
                Section(header: Text("Reminders")) {
                    HStack {
                        Text("Interval")
                        Spacer()
                        Picker("", selection: $manager.intervalMinutes) {
                            Text("15 min").tag(15.0)
                            Text("30 min").tag(30.0)
                            Text("45 min").tag(45.0)
                            Text("60 min").tag(60.0)
                            Text("90 min").tag(90.0)
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    Toggle("Enable Reminders", isOn: Binding(
                        get: { !manager.isPaused },
                        set: { enabled in
                            if enabled {
                                manager.resume()
                            } else {
                                manager.pause()
                            }
                        }
                    ))
                }
                
                // Water Tracking Settings
                Section(header: Text("Water Tracking")) {
                    Toggle("Enable Water Tracking", isOn: $manager.waterTrackingEnabled)
                    
                    if manager.waterTrackingEnabled {
                        HStack {
                            Text("Daily Goal")
                            Spacer()
                            Stepper(
                                "\(manager.dailyWaterGoal) \(manager.waterUnit.rawValue)",
                                value: $manager.dailyWaterGoal,
                                in: 1...20
                            )
                        }
                        
                        Picker("Unit", selection: $manager.waterUnit) {
                            ForEach(WaterUnit.allCases, id: \.self) { unit in
                                Text(unit.rawValue).tag(unit)
                            }
                        }
                    }
                }
                
                // Notifications
                Section(header: Text("Notifications")) {
                    Button(action: {
                        openNotificationSettings()
                    }) {
                        HStack {
                            Text("Notification Settings")
                            Spacer()
                            Image(systemName: "arrow.up.forward.app")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: {
                        manager.clearNotifications()
                    }) {
                        Text("Clear All Notifications")
                            .foregroundColor(.red)
                    }
                }
                
                // Data
                Section(header: Text("Data")) {
                    HStack {
                        Text("Current Streak")
                        Spacer()
                        Text("\(manager.currentStreak) days")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Best Streak")
                        Spacer()
                        Text("\(manager.bestStreak) days")
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        resetData()
                    }) {
                        Text("Reset All Data")
                            .foregroundColor(.red)
                    }
                }
                
                // About
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        showingAbout = true
                    }) {
                        HStack {
                            Text("About Touch Grass")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://github.com/dmfenton/TouchGrass")!) {
                        HStack {
                            Text("View on GitHub")
                            Spacer()
                            Image(systemName: "arrow.up.forward.app")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
        }
    }
    
    private func openNotificationSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func resetData() {
        // Show confirmation alert
        manager.currentStreak = 0
        manager.bestStreak = 0
        manager.currentWaterIntake = 0
        manager.completedActivities = []
    }
}

struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.green)
                
                Text("Touch Grass")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Version 1.0.0")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 16) {
                    Text("Take regular breaks, move your body, and literally touch some grass.")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Text("Your body and mind will thank you.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    Text("Made with 💚")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("© 2024 Touch Grass")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 30)
            }
            .padding()
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}