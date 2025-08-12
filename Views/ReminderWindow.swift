import SwiftUI

struct ReminderView: View {
    let message: String
    @ObservedObject var manager: ReminderManager
    let ok: () -> Void
    let snooze5: () -> Void
    let snooze10: () -> Void
    let skip: () -> Void
    
    @State private var hoveredButton: String?
    private let exerciseWindow = ExerciseWindowController()
    
    var body: some View {
        // Main reminder view
            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(manager.waterTrackingEnabled ? "Posture & Hydration Check" : "Posture Check")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                    Spacer()
                    Button(action: skip) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(NSColor.windowBackgroundColor))
                
                Divider()
                
                // Content
                VStack(alignment: .leading, spacing: 16) {
                    // Message steps
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(message.components(separatedBy: "\n").filter { !$0.isEmpty }, id: \.self) { line in
                            if line.contains("✨") {
                                // Extra tip
                                VStack(alignment: .leading, spacing: 8) {
                                    Divider()
                                    HStack(alignment: .top, spacing: 10) {
                                        Text("💡")
                                            .font(.system(size: 14))
                                        Text(line.replacingOccurrences(of: "✨ Extra: ", with: ""))
                                            .font(.system(size: 14, weight: .regular, design: .rounded))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            } else {
                                // Regular step
                                HStack(alignment: .top, spacing: 10) {
                                    Text(String(line.prefix(2)))
                                        .font(.system(size: 16))
                                        .frame(width: 24)
                                    Text(line.dropFirst(2).trimmingCharacters(in: .whitespaces))
                                        .font(.system(size: 14, weight: .regular, design: .rounded))
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // Water tracking section
                    if manager.waterTrackingEnabled {
                        VStack(spacing: 12) {
                            Divider()
                            
                            HStack {
                                Image(systemName: "drop.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                                Text("Hydration Check")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("\(manager.currentWaterIntake)/\(manager.dailyWaterGoal) glasses")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.blue)
                            }
                            
                            // Progress bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.blue.opacity(0.2))
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.blue)
                                        .frame(width: geometry.size.width * 
                                            min(1.0, Double(manager.currentWaterIntake) / Double(manager.dailyWaterGoal)))
                                }
                            }
                            .frame(height: 6)
                            
                            // Quick water log buttons
                            HStack(spacing: 8) {
                                Button(action: { 
                                    manager.logWater(1)
                                }) {
                                    Label("Log 1 glass", systemImage: "plus.circle")
                                        .font(.system(size: 12))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .fill(
                                                            hoveredButton == "water1"
                                                                ? Color.blue.opacity(0.08)
                                                                : Color.clear
                                                        )
                                                )
                                        )
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .onHover { isHovered in
                                    hoveredButton = isHovered ? "water1" : nil
                                }
                                
                                Button(action: { 
                                    manager.logWater(2)
                                }) {
                                    Label("Log 2 glasses", systemImage: "plus.circle.fill")
                                        .font(.system(size: 12))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .fill(
                                                            hoveredButton == "water2"
                                                                ? Color.blue.opacity(0.08)
                                                                : Color.clear
                                                        )
                                                )
                                        )
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .onHover { isHovered in
                                    hoveredButton = isHovered ? "water2" : nil
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Exercise options
                    VStack(spacing: 8) {
                        Divider()
                        
                        Text("Try a guided exercise:")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 8) {
                            ForEach(ExerciseData.allExerciseSets.prefix(2)) { exerciseSet in
                                Button(action: {
                                    exerciseWindow.showExerciseWindow(with: exerciseSet)
                                    skip()  // Close reminder window when opening exercises
                                }, label: {
                                    VStack(spacing: 4) {
                                        Text(exerciseSet.name)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.primary)
                                        let minutes = exerciseSet.duration / 60
                                        let seconds = exerciseSet.duration % 60
                                        Text("\(minutes):\(String(format: "%02d", seconds))")
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                            .background(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .fill(
                                                        hoveredButton == exerciseSet.id
                                                            ? Color.secondary.opacity(0.08)
                                                            : Color.clear
                                                    )
                                            )
                                    )
                                })
                                .buttonStyle(PlainButtonStyle())
                                .onHover { isHovered in
                                    hoveredButton = isHovered ? exerciseSet.id : nil
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Buttons
                    VStack(spacing: 10) {
                        // Primary action
                        Button(action: ok) {
                            HStack {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .medium))
                                Text(manager.waterTrackingEnabled ? "Done - Posture & Water Logged" : "Done - Posture Checked")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.accentColor)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .keyboardShortcut(.defaultAction)
                        
                        // Secondary actions
                        HStack(spacing: 8) {
                            Button(action: snooze5) {
                                Text("Snooze 5m")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(hoveredButton == "snooze5" ? .primary : .secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                            .background(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .fill(
                                                        hoveredButton == "snooze5"
                                                            ? Color.secondary.opacity(0.08)
                                                            : Color.clear
                                                    )
                                            )
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .onHover { isHovered in
                                hoveredButton = isHovered ? "snooze5" : nil
                            }
                            
                            Button(action: snooze10) {
                                Text("Snooze 10m")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(hoveredButton == "snooze10" ? .primary : .secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                            .background(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .fill(
                                                        hoveredButton == "snooze10"
                                                            ? Color.secondary.opacity(0.08)
                                                            : Color.clear
                                                    )
                                            )
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .onHover { isHovered in
                                hoveredButton = isHovered ? "snooze10" : nil
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .background(Color(NSColor.controlBackgroundColor))
            }
            .frame(width: 420)
            .background(Color(NSColor.windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
}
