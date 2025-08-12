import SwiftUI

struct TouchGrassMode: View {
    @ObservedObject var reminderManager: ReminderManager
    @State private var selectedActivity: String? = nil
    @Environment(\.dismiss) var dismiss
    
    let activities = [
        ("figure.walk", "Take a Walk"),
        ("figure.flexibility", "Stretch"),
        ("eye", "Eye Exercises"),
        ("leaf", "Deep Breathing"),
        ("sun.max", "Go Outside")
    ]
    
    let waterAmounts = [8, 16, 24] // oz
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("Time to Touch Grass")
                .font(.title2)
                .fontWeight(.medium)
            
            Divider()
            
            // Activities Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Choose an activity:")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 8) {
                    ForEach(activities, id: \.1) { icon, name in
                        Button(action: {
                            selectedActivity = name
                        }) {
                            HStack {
                                Image(systemName: icon)
                                    .frame(width: 20)
                                Text(name)
                                Spacer()
                                if selectedActivity == name {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(selectedActivity == name ? 
                                          Color.accentColor.opacity(0.1) : 
                                          Color.clear)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Divider()
            
            // Water Tracking Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Log water:")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    ForEach(waterAmounts, id: \.self) { amount in
                        Button(action: {
                            reminderManager.logWater(ounces: amount)
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "drop.fill")
                                    .font(.title3)
                                Text("\(amount)oz")
                                    .font(.caption)
                            }
                            .frame(width: 60, height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(NSColor.controlBackgroundColor))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                    
                    // Daily total
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(reminderManager.dailyWaterOz)oz")
                            .font(.headline)
                        Text("today")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Divider()
            
            // Action Buttons
            HStack(spacing: 12) {
                Button("Snooze 5 min") {
                    reminderManager.snoozeReminder()
                    dismiss()
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
                
                Spacer()
                
                Button("Complete") {
                    if let activity = selectedActivity {
                        reminderManager.completeActivity(activity)
                    }
                    reminderManager.completeBreak()
                    dismiss()
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.accentColor)
                )
                .foregroundColor(.white)
                .disabled(selectedActivity == nil)
                .opacity(selectedActivity == nil ? 0.6 : 1.0)
            }
        }
        .padding(24)
        .frame(width: 400)
        .background(Color(NSColor.windowBackgroundColor))
    }
}