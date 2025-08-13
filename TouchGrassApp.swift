import SwiftUI

@main
struct TouchGrassApp: App {
    @StateObject private var manager = ReminderManager()
    private var onboardingWindow: TouchGrassOnboardingController?
    @State private var touchGrassController = TouchGrassModeController()

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
            if manager.hasActiveReminder {
                TouchGrassQuickView(manager: manager)
            } else {
                MenuView(manager: manager)
            }
        } label: {
            GrassIcon(isActive: manager.hasActiveReminder, size: 20)
        }
        .menuBarExtraStyle(.window)
    }
}

struct TouchGrassQuickView: View {
    @ObservedObject var manager: ReminderManager
    @State private var touchGrassController = TouchGrassModeController()
    
    var body: some View {
        VStack(spacing: 0) {
            // Touch Grass Mode
            VStack(spacing: 16) {
                // Header with icon
                HStack {
                    GrassIcon(isActive: true, size: 24)
                    Text("Time to Touch Grass!")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                }
                .padding(.top, 16)
                
                // Message
                Text(Messages.composed())
                    .font(.system(size: 14))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                
                // Action buttons
                VStack(spacing: 8) {
                    Button(action: {
                        manager.completeBreak()
                        NSApplication.shared.keyWindow?.close()
                    }) {
                        Label("I touched grass!", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.green)
                            )
                            .foregroundColor(.white)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    HStack(spacing: 8) {
                        Button(action: {
                            manager.snoozeReminder()
                            NSApplication.shared.keyWindow?.close()
                        }) {
                            Text("5 min")
                                .font(.system(size: 13, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.orange.opacity(0.15))
                                )
                                .foregroundColor(.orange)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            manager.snooze(minutes: 10)
                            manager.hasActiveReminder = false
                            NSApplication.shared.keyWindow?.close()
                        }) {
                            Text("10 min")
                                .font(.system(size: 13, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.orange.opacity(0.15))
                                )
                                .foregroundColor(.orange)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Button(action: {
                        touchGrassController.show(manager: manager)
                        NSApplication.shared.keyWindow?.close()
                    }) {
                        Label("Open Touch Grass Mode", systemImage: "leaf.circle")
                            .font(.system(size: 13, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.green, lineWidth: 1)
                            )
                            .foregroundColor(.green)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            
            Divider()
            
            // Quick access to regular menu
            Button(action: {
                manager.hasActiveReminder = false
                // This will cause the menu to refresh and show the regular menu
            }) {
                HStack {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11))
                    Text("Back to Menu")
                        .font(.system(size: 12))
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        }
        .frame(width: 280)
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
            .onAppear {
                // Refresh calendar data whenever menu is opened
                manager.calendarManager?.updateCurrentAndNextEvents()
            }
    }
    
    @ViewBuilder
    var mainMenuContent: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                HStack {
                    GrassIcon(isActive: false, size: 18)
                    Text("Touch Grass")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .padding(.top, 12)
                
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
                
                // Water Tracking Display
                if manager.waterTrackingEnabled {
                    HStack(spacing: 12) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Text("\(manager.currentWaterIntake)/\(manager.dailyWaterGoal)")
                                    .font(.system(size: 13, weight: .semibold))
                                Text(manager.waterUnit == .glasses ? "glasses" : manager.waterUnit.rawValue)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            
                            // Progress bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.blue.opacity(0.2))
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.blue)
                                        .frame(width: geometry.size.width * 
                                            min(1.0, Double(manager.currentWaterIntake) / Double(manager.dailyWaterGoal)))
                                }
                            }
                            .frame(height: 4)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Button(action: { manager.logWater(1) }) {
                                Text("+1")
                                    .font(.system(size: 11, weight: .medium))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.blue.opacity(0.15))
                                    .foregroundColor(.blue)
                                    .cornerRadius(4)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: { manager.logWater(2) }) {
                                Text("+2")
                                    .font(.system(size: 11, weight: .medium))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.blue.opacity(0.15))
                                    .foregroundColor(.blue)
                                    .cornerRadius(4)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.05))
                    )
                    .padding(.horizontal, 12)
                }
                
                // Calendar Events Display with Smart Insights (only if connected)
                if let calManager = manager.calendarManager,
                   calManager.hasCalendarAccess,
                   !calManager.selectedCalendarIdentifiers.isEmpty {
                    VStack(spacing: 8) {
                        // Meeting Load Indicator
                        let meetingLoad = calManager.getMeetingLoad()
                        HStack(spacing: 8) {
                            Circle()
                                .fill(meetingLoad.color)
                                .frame(width: 8, height: 8)
                            Text(meetingLoad.suggestion)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        
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
                        
                        // Only show free slot if we have calendar data
                        if calManager.getTodaysMeetings().count > 0 {
                            if let freeSlot = calManager.nextFreeSlot(minimumDuration: 900) {
                                let isNow = freeSlot.start.timeIntervalSinceNow < 60
                                
                                HStack(spacing: 8) {
                                    Image(systemName: "leaf.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.green)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(isNow ? "Free now!" : "Free at \(calManager.formatEventTime(freeSlot.start))")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(isNow ? .green : .primary)
                                        Text(freeSlot.duration >= 1800 ? "Perfect for a real outdoor break 🌳" : "Quick fresh air opportunity")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.green.opacity(0.08))
                                )
                            }
                        }
                        
                        // Total meeting time remaining
                        let totalMeetingTime = calManager.totalMeetingTimeToday()
                        if totalMeetingTime > 0 {
                            HStack(spacing: 8) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                Text("\(Int(totalMeetingTime / 3600))h \(Int((totalMeetingTime.truncatingRemainder(dividingBy: 3600)) / 60))m in meetings today")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 12)
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
                if !manager.isPaused {
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
                MenuButton(
                    icon: "leaf.circle",
                    title: "Take a Break",
                    action: { 
                        manager.showTouchGrassMode()
                    },
                    isHovered: hoveredItem == "break",
                    onHover: { hoveredItem = $0 ? "break" : nil },
                    tintColor: .green
                )
                
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

