import SwiftUI

@main
struct TouchGrassApp: App {
    @StateObject private var manager = ReminderManager()
    private var onboardingWindow: TouchGrassOnboardingController?

    init() {
        // Check for onboarding after a short delay to let the app fully initialize
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if TouchGrassOnboardingController.shouldShowOnboarding() {
                let window = TouchGrassOnboardingController(reminderManager: ReminderManager())
                window.showOnboarding()
            }
        }
    }

    var body: some Scene {
        MenuBarExtra {
            MenuView(manager: manager)
        } label: {
            GrassIcon(isActive: manager.hasActiveReminder, size: 20)
        }
        .menuBarExtraStyle(.window)
    }
}

struct MenuView: View {
    @ObservedObject var manager: ReminderManager
    @State private var hoveredItem: String? = nil
    @State private var customizationWindow: CustomizationWindowController?
    
    var nextReminderText: String {
        let totalSeconds = Int(manager.timeUntilNextReminder)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        
        if totalSeconds <= 0 {
            return "Any moment..."
        } else if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return "\(seconds)s"
        }
    }
    
    var body: some View {
        mainMenuContent
    }
    
    @ViewBuilder
    var mainMenuContent: some View {
        VStack(spacing: 0) {
            // Active reminder notification
            if manager.hasActiveReminder {
                Button(action: { manager.showReminder() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "figure.walk.motion")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        Text("Posture Check Ready!")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [Color.orange, Color.orange.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
            }
            
            // Header
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.accentColor)
                    Text("Touch Grass")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .padding(.top, manager.hasActiveReminder ? 8 : 12)
                
                // Streak Display
                if manager.currentStreak > 0 || manager.bestStreak > 0 {
                    HStack(spacing: 16) {
                        VStack(spacing: 2) {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.orange)
                                Text("\(manager.currentStreak)")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                            }
                            Text("day streak")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        
                        if manager.bestStreak > 0 {
                            Divider()
                                .frame(height: 20)
                            
                            VStack(spacing: 2) {
                                HStack(spacing: 4) {
                                    Image(systemName: "trophy.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.yellow)
                                    Text("\(manager.bestStreak)")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                }
                                Text("best")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.orange.opacity(0.08))
                    )
                }
                
                // Calendar Events Display
                if let calManager = manager.calendarManager {
                    VStack(spacing: 8) {
                        if let currentEvent = calManager.currentEvent {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("In Meeting")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(currentEvent.title ?? "Busy")
                                        .font(.system(size: 12, weight: .medium))
                                        .lineLimit(1)
                                    Text("Until \(calManager.formatEventTime(currentEvent.endDate))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.red.opacity(0.1))
                            )
                        }
                        
                        if let nextEvent = calManager.nextEvent,
                           let timeUntil = calManager.timeUntilNextEvent {
                            HStack(spacing: 8) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Next: \(nextEvent.title ?? "Event")")
                                        .font(.system(size: 11, weight: .medium))
                                        .lineLimit(1)
                                    Text("in \(calManager.formatTimeUntilEvent(timeUntil))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(NSColor.controlBackgroundColor))
                            )
                        }
                    }
                    .padding(.horizontal, 12)
                }
                
                // Countdown Display
                if !manager.isPaused && !(manager.calendarManager?.isInMeeting ?? false) {
                    VStack(spacing: 4) {
                        Text("Next reminder in")
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .foregroundColor(.secondary)
                        Text(nextReminderText)
                            .font(.system(size: 24, weight: .semibold, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.accentColor.opacity(0.08))
                    )
                    .padding(.horizontal, 12)
                } else {
                    Label("Paused", systemImage: "pause.circle.fill")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.orange)
                        .padding(.vertical, 8)
                }
            }
            
            Divider()
            
            // Quick Actions
            VStack(spacing: 1) {
                if !manager.hasActiveReminder {
                    MenuButton(
                        icon: "bell.badge",
                        title: "Check Posture Now",
                        action: { manager.showReminder() },
                        isHovered: hoveredItem == "now",
                        onHover: { hoveredItem = $0 ? "now" : nil }
                    )
                }
                
                if manager.isPaused {
                    MenuButton(
                        icon: "play.fill",
                        title: "Resume Reminders",
                        action: { manager.resume() },
                        isHovered: hoveredItem == "resume",
                        onHover: { hoveredItem = $0 ? "resume" : nil },
                        tintColor: .green
                    )
                } else {
                    MenuButton(
                        icon: "pause.fill",
                        title: "Pause Reminders",
                        action: { manager.pause() },
                        isHovered: hoveredItem == "pause",
                        onHover: { hoveredItem = $0 ? "pause" : nil },
                        tintColor: .orange
                    )
                }
            }
            .padding(.vertical, 4)
            
            Divider()
            
            // Exercises Section
            VStack(spacing: 4) {
                Text("EXERCISES")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                
                MenuButton(
                    icon: "figure.strengthtraining.traditional",
                    title: manager.isExerciseWindowVisible() ? "Exercise Window Open" : "Open Exercises",
                    action: { manager.showExercises() },
                    isHovered: hoveredItem == "exercises",
                    onHover: { hoveredItem = $0 ? "exercises" : nil },
                    tintColor: manager.isExerciseWindowVisible() ? .green : .accentColor
                )
                
                // Quick access to exercise sets
                HStack(spacing: 4) {
                    ForEach([
                        ("30s", ExerciseData.quickReset),
                        ("1m", ExerciseData.oneMinuteBreak),
                        ("2m", ExerciseData.twoMinuteRoutine)
                    ], id: \.0) { label, exerciseSet in
                        Button(action: {
                            manager.showExerciseSet(exerciseSet)
                        }) {
                            Text(label)
                                .font(.system(size: 11, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(NSColor.controlBackgroundColor))
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 4)
            }
            
            Divider()
            
            // Settings button
            MenuButton(
                icon: "slider.horizontal.3",
                title: "Settings",
                action: { openSettings() },
                isHovered: hoveredItem == "settings",
                onHover: { hoveredItem = $0 ? "settings" : nil }
            )
            .padding(.vertical, 4)
            
            Divider()
            
            // Footer
            MenuButton(
                icon: "xmark.circle",
                title: "Quit Touch Grass",
                action: { NSApplication.shared.terminate(nil) },
                isHovered: hoveredItem == "quit",
                onHover: { hoveredItem = $0 ? "quit" : nil },
                tintColor: .red
            )
            .padding(.vertical, 4)
        }
        .frame(width: 280)
    }
    
    private func openSettings() {
        customizationWindow = CustomizationWindowController(
            reminderManager: manager,
            onComplete: {
                // Settings saved
            }
        )
        customizationWindow?.showCustomization()
    }
}

struct MenuButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    let isHovered: Bool
    let onHover: (Bool) -> Void
    var tintColor: Color = .accentColor
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(isHovered ? tintColor : .secondary)
                    .frame(width: 20)
                Text(title)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(isHovered ? .primary : .primary.opacity(0.9))
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover(perform: onHover)
    }
}

