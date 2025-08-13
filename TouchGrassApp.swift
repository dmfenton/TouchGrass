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
                TouchGrassMode(reminderManager: manager)
                    .frame(width: 400, height: 500)
            } else {
                MenuView(manager: manager)
            }
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
            .onAppear {
                // Refresh calendar data whenever menu is opened
                manager.calendarManager?.updateCurrentAndNextEvents()
            }
    }
    
    @ViewBuilder
    var mainMenuContent: some View {
        VStack(spacing: 8) {
            // Header with app name
            HStack {
                GrassIcon(isActive: false, size: 18)
                Text("Touch Grass")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            .padding(.top, 12)
            .padding(.bottom, 4)
                
            // Primary Status - Countdown Timer with integrated pause button
            HStack(spacing: 12) {
                VStack(spacing: 2) {
                    Text(manager.isPaused ? "Paused" : nextReminderText)
                        .font(.system(size: manager.isPaused ? 20 : 28, weight: .semibold, design: .monospaced))
                        .foregroundColor(manager.isPaused ? .orange : .primary)
                    Text(manager.isPaused ? "Reminders paused" : "until next reminder")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                // Integrated pause/resume button
                Button(action: { 
                    if manager.isPaused {
                        manager.resume()
                    } else {
                        manager.pause()
                    }
                }) {
                    Image(systemName: manager.isPaused ? "play.circle.fill" : "pause.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(manager.isPaused ? .green : .orange.opacity(0.8))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(manager.isPaused ? Color.orange.opacity(0.08) : Color.accentColor.opacity(0.08))
            )
            .padding(.horizontal, 12)
                
            // Calendar Context (Streamlined but informative)
            if let calManager = manager.calendarManager,
               calManager.hasCalendarAccess,
               !calManager.selectedCalendarIdentifiers.isEmpty {
                VStack(spacing: 6) {
                    // Current status
                    if let currentEvent = calManager.currentEvent {
                        // Currently in meeting
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 6, height: 6)
                            Text(currentEvent.title ?? "Meeting")
                                .font(.system(size: 12, weight: .medium))
                                .lineLimit(1)
                            Spacer()
                            Text("until \(calManager.formatEventTime(currentEvent.endDate))")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red.opacity(0.08))
                        )
                    } else if let freeSlot = calManager.nextFreeSlot(minimumDuration: 600),
                              freeSlot.start.timeIntervalSinceNow < 60 {
                        // Free right now - highlight opportunity
                        HStack(spacing: 8) {
                            Image(systemName: "leaf.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.green)
                            Text("Free now - perfect time to touch grass!")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.green.opacity(0.1))
                        )
                    }
                    
                    // Next event (always show if exists)
                    if let nextEvent = calManager.nextEvent,
                       let timeUntil = calManager.timeUntilNextEvent {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Text(nextEvent.title ?? "Meeting")
                                .font(.system(size: 11, weight: .medium))
                                .lineLimit(1)
                            Spacer()
                            Text("in \(calManager.formatTimeUntilEvent(timeUntil))")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )
                    }
                    
                    // Meeting load indicator (subtle)
                    let meetingLoad = calManager.getMeetingLoad()
                    if meetingLoad != .light {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(meetingLoad.color.opacity(0.8))
                                .frame(width: 5, height: 5)
                            Text(meetingLoad.suggestion)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                    }
                }
                .padding(.horizontal, 12)
            }
                
            // Stats Display (Streak + Water tracking)
            HStack(spacing: 16) {
                // Streak info
                if manager.currentStreak > 0 || manager.bestStreak > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                        Text("\(manager.currentStreak) day")
                            .font(.system(size: 12, weight: .medium))
                        if manager.bestStreak > manager.currentStreak {
                            Text("• best: \(manager.bestStreak)")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Water tracking display (no buttons here)
                if manager.waterTrackingEnabled {
                    HStack(spacing: 6) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                        Text("\(manager.currentWaterIntake)/\(manager.dailyWaterGoal) \(manager.waterUnit == .glasses ? "glasses" : manager.waterUnit.rawValue)")
                            .font(.system(size: 12, weight: .medium))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            
            // Water logging buttons (separate section)
            if manager.waterTrackingEnabled {
                HStack(spacing: 8) {
                    ForEach([1, 2, 4, 8], id: \.self) { amount in
                        Button(action: { manager.logWater(amount) }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 10))
                                Text("+\(amount)")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.blue.opacity(hoveredItem == "water-\(amount)" ? 0.15 : 0.08))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .onHover { hoveredItem = $0 ? "water-\(amount)" : nil }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 4)
            }
            
            Divider()
                .padding(.vertical, 4)
            
            // Primary Action - Touch Grass (larger, more prominent)
            Button(action: { manager.showTouchGrassMode() }) {
                HStack {
                    Image(systemName: "leaf.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.green)
                    Text("Touch Grass")
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                    Text("Now")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.green.opacity(hoveredItem == "touch-grass" ? 0.15 : 0.08))
                )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 12)
            .onHover { hoveredItem = $0 ? "touch-grass" : nil }
            
            // No secondary pause/resume button needed anymore since it's in the timer
            
            Spacer()
            
            // Footer Actions (smaller, less prominent)
            VStack(spacing: 0) {
                Divider()
                    .padding(.bottom, 4)
                
                HStack(spacing: 12) {
                    Button(action: { openSettings() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 11))
                            Text("Settings")
                                .font(.system(size: 11))
                        }
                        .foregroundColor(hoveredItem == "settings" ? .primary : .secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onHover { hoveredItem = $0 ? "settings" : nil }
                    
                    Spacer()
                    
                    Button(action: { NSApplication.shared.terminate(nil) }) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 11))
                            Text("Quit")
                                .font(.system(size: 11))
                        }
                        .foregroundColor(hoveredItem == "quit" ? .red : .secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onHover { hoveredItem = $0 ? "quit" : nil }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
        .frame(width: 260)
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

