import SwiftUI
import UserNotifications

struct OnboardingWindow: View {
    @StateObject private var onboardingManager = OnboardingManager()
    @ObservedObject var reminderManager: ReminderManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            ProgressBar(currentStep: onboardingManager.currentStep)
                .padding(.horizontal, 20)
                .padding(.top, 20)
            
            // Content
            TabView(selection: $onboardingManager.currentStep) {
                WelcomeView()
                    .tag(OnboardingManager.OnboardingStep.welcome)
                
                WorkHoursView(manager: onboardingManager)
                    .tag(OnboardingManager.OnboardingStep.workHours)
                
                ReminderSettingsView(manager: onboardingManager)
                    .tag(OnboardingManager.OnboardingStep.reminderSettings)
                
                PermissionsView()
                    .tag(OnboardingManager.OnboardingStep.permissions)
                
                CompleteView()
                    .tag(OnboardingManager.OnboardingStep.complete)
            }
            .tabViewStyle(.automatic)
            .frame(height: 400)
            
            // Navigation buttons
            HStack(spacing: 12) {
                if onboardingManager.currentStep != .welcome {
                    Button("Back") {
                        onboardingManager.previousStep()
                    }
                    .controlSize(.large)
                    .keyboardShortcut(.leftArrow)
                }
                
                Spacer()
                
                if onboardingManager.currentStep == .complete {
                    Button("Get Started") {
                        completeOnboarding()
                    }
                    .controlSize(.large)
                    .keyboardShortcut(.return, modifiers: [])
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(onboardingManager.currentStep == .permissions ? "Continue" : "Next") {
                        if onboardingManager.currentStep == .permissions {
                            requestNotificationPermission()
                        }
                        onboardingManager.nextStep()
                    }
                    .controlSize(.large)
                    .keyboardShortcut(.rightArrow)
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(20)
        }
        .frame(width: 600, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in
            // Permission handled
        }
    }
    
    private func completeOnboarding() {
        // Apply settings to ReminderManager
        reminderManager.intervalMinutes = onboardingManager.reminderInterval
        reminderManager.adaptiveIntervalEnabled = onboardingManager.enableSmartTiming
        reminderManager.startsAtLogin = onboardingManager.startAtLogin
        
        // Save onboarding completion
        onboardingManager.completeOnboarding()
        
        // Apply work hours to reminder manager if it supports it
        let workDays = Set(onboardingManager.workDays.map { day -> WorkDay in
            switch day {
            case .sunday: return .sunday
            case .monday: return .monday
            case .tuesday: return .tuesday
            case .wednesday: return .wednesday
            case .thursday: return .thursday
            case .friday: return .friday
            case .saturday: return .saturday
            }
        })
        reminderManager.setWorkHours(
            start: (onboardingManager.workStartHour, onboardingManager.workStartMinute),
            end: (onboardingManager.workEndHour, onboardingManager.workEndMinute),
            days: workDays
        )
        
        dismiss()
    }
}

struct ProgressBar: View {
    let currentStep: OnboardingManager.OnboardingStep
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(OnboardingManager.OnboardingStep.allCases, id: \.self) { step in
                Circle()
                    .fill(step.rawValue <= currentStep.rawValue ? Color.accentColor : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut, value: currentStep)
            }
        }
    }
}

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "figure.walk")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
                .symbolRenderingMode(.hierarchical)
            
            Text("Welcome to Touch Grass")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Your personal posture and wellness companion")
                .font(.title3)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 16) {
                OldFeatureRow(
                    icon: "bell.badge",
                    title: "Smart Reminders",
                    description: "Get gentle nudges to check your posture"
                )
                OldFeatureRow(
                    icon: "figure.strengthtraining.traditional",
                    title: "Quick Exercises",
                    description: "Simple stretches to keep you healthy"
                )
                OldFeatureRow(
                    icon: "flame.fill",
                    title: "Build Streaks",
                    description: "Track your progress and stay motivated"
                )
            }
            .padding(.top, 20)
        }
        .padding(40)
    }
}

struct OldFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct WorkHoursView: View {
    @ObservedObject var manager: OnboardingManager
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
                
                Text("When do you work?")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Text("We'll only send reminders during your work hours")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 20) {
                // Work days selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("Work Days")
                        .font(.headline)
                    
                    HStack(spacing: 8) {
                        ForEach(OnboardingManager.WorkDay.allCases, id: \.self) { day in
                            DayToggle(day: day, isSelected: manager.workDays.contains(day)) {
                                if manager.workDays.contains(day) {
                                    manager.workDays.remove(day)
                                } else {
                                    manager.workDays.insert(day)
                                }
                            }
                        }
                    }
                }
                
                // Time pickers
                HStack(spacing: 40) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Start Time")
                            .font(.headline)
                        TimePicker(hour: $manager.workStartHour, minute: $manager.workStartMinute)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("End Time")
                            .font(.headline)
                        TimePicker(hour: $manager.workEndHour, minute: $manager.workEndMinute)
                    }
                }
                
                // Preview text
                Text(workHoursDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(40)
    }
    
    private var workHoursDescription: String {
        let startTime = String(format: "%d:%02d %@",
                               manager.workStartHour > 12 ? manager.workStartHour - 12 : manager.workStartHour,
                               manager.workStartMinute,
                               manager.workStartHour >= 12 ? "PM" : "AM")
        let endTime = String(format: "%d:%02d %@",
                             manager.workEndHour > 12 ? manager.workEndHour - 12 : manager.workEndHour,
                             manager.workEndMinute,
                             manager.workEndHour >= 12 ? "PM" : "AM")
        
        let daysList = OnboardingManager.WorkDay.allCases
            .filter { manager.workDays.contains($0) }
            .map { $0.displayName }
            .joined(separator: ", ")
        
        return "Reminders active \(daysList) from \(startTime) to \(endTime)"
    }
}

struct DayToggle: View {
    let day: OnboardingManager.WorkDay
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(day.displayName)
                .font(.system(size: 12, weight: .medium))
                .frame(width: 44, height: 32)
                .background(isSelected ? Color.accentColor : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

struct TimePicker: View {
    @Binding var hour: Int
    @Binding var minute: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Picker("", selection: $hour) {
                ForEach(0..<24, id: \.self) { hour in
                    Text(String(format: "%02d", hour)).tag(hour)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 60)
            
            Text(":")
                .font(.headline)
            
            Picker("", selection: $minute) {
                ForEach([0, 15, 30, 45], id: \.self) { minute in
                    Text(String(format: "%02d", minute)).tag(minute)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 60)
        }
    }
}

struct ReminderSettingsView: View {
    @ObservedObject var manager: OnboardingManager
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "bell")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
                
                Text("How often should we remind you?")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Text("You can always adjust this later")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 24) {
                // Interval slider
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Reminder Interval")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(manager.reminderInterval)) minutes")
                            .font(.system(.body, design: .monospaced))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.2))
                            .cornerRadius(6)
                    }
                    
                    Slider(value: $manager.reminderInterval, in: 15...90, step: 5)
                    
                    HStack {
                        Text("More frequent")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Less frequent")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                
                // Smart timing toggle
                Toggle(isOn: $manager.enableSmartTiming) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Smart Timing", systemImage: "wand.and.stars")
                            .font(.headline)
                        Text("Automatically adjust reminders based on your activity")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(.switch)
                .padding(.horizontal, 20)
                
                // Start at login toggle
                Toggle(isOn: $manager.startAtLogin) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Start at Login", systemImage: "power")
                            .font(.headline)
                        Text("Launch Touch Grass when you log in to your Mac")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(.switch)
                .padding(.horizontal, 20)
            }
        }
        .padding(40)
    }
}

struct PermissionsView: View {
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "checkmark.shield")
                    .font(.system(size: 48))
                    .foregroundColor(.green)
                
                Text("Enable Notifications")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Text("We'll send you gentle reminders when it's time to check your posture")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                Image(systemName: notificationStatus == .authorized ? "checkmark.circle.fill" : "bell.badge")
                    .font(.system(size: 64))
                    .foregroundColor(notificationStatus == .authorized ? .green : .accentColor)
                    .symbolRenderingMode(.hierarchical)
                
                if notificationStatus == .authorized {
                    Text("Notifications are enabled")
                        .font(.headline)
                        .foregroundColor(.green)
                } else {
                    Text("Click 'Continue' to enable notifications")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text("You can always change this in System Settings")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 20)
        }
        .padding(40)
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
}

struct CompleteView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
                .symbolRenderingMode(.hierarchical)
            
            Text("You're all set!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Touch Grass will help you maintain good posture throughout your workday")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Work hours configured")
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Reminder schedule set")
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Notifications enabled")
                }
            }
            .font(.body)
            .padding(.top, 20)
            
            Text("Click 'Get Started' to begin using Touch Grass")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 10)
        }
        .padding(40)
    }
}
