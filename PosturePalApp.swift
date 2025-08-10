import SwiftUI

@main
struct PosturePalApp: App {
    @StateObject private var manager = ReminderManager()

    var body: some Scene {
        MenuBarExtra {
            MenuView(manager: manager)
        } label: {
            Image(systemName: manager.isPaused ? "figure.seated.side.air.distribution" : "figure.seated.side")
                .symbolRenderingMode(.hierarchical)
        }
        .menuBarExtraStyle(.window)
    }
}

struct MenuView: View {
    @ObservedObject var manager: ReminderManager
    @State private var hoveredItem: String? = nil
    
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
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.accentColor)
                    Text("Posture Pal")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .padding(.top, 12)
                
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
                    icon: "bell.badge",
                    title: "Check Posture Now",
                    action: { manager.showReminder() },
                    isHovered: hoveredItem == "now",
                    onHover: { hoveredItem = $0 ? "now" : nil }
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
            
            // Settings
            VStack(spacing: 8) {
                Text("SETTINGS")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                
                // Interval Slider
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "timer")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text("Reminder Interval")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                        Spacer()
                        Text("\(Int(manager.intervalMinutes)) min")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(NSColor.controlBackgroundColor))
                            )
                    }
                    
                    Slider(value: $manager.intervalMinutes, in: 15...120, step: 5)
                        .controlSize(.small)
                }
                .padding(.horizontal, 16)
                
                // Login Item Toggle
                Toggle(isOn: $manager.fakeLoginToggle) {
                    HStack(spacing: 6) {
                        Image(systemName: "power")
                            .font(.system(size: 12))
                        Text("Start at Login")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                    }
                }
                .toggleStyle(.checkbox)
                .controlSize(.small)
                .padding(.horizontal, 16)
                .help("Add PosturePal to System Settings > Login Items manually")
                .padding(.bottom, 8)
            }
            
            Divider()
            
            // Footer
            MenuButton(
                icon: "xmark.circle",
                title: "Quit Posture Pal",
                action: { NSApplication.shared.terminate(nil) },
                isHovered: hoveredItem == "quit",
                onHover: { hoveredItem = $0 ? "quit" : nil },
                tintColor: .red
            )
            .padding(.vertical, 4)
        }
        .frame(width: 280)
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

