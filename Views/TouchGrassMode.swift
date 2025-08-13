import SwiftUI

struct TouchGrassMode: View {
    @ObservedObject var reminderManager: ReminderManager
    @Environment(\.dismiss) var dismiss
    @State private var showingCompletion = false
    @State private var completedActivity: String? = nil
    
    // Activities - some are instant, some open guided exercises
    let activities: [(icon: String, name: String, color: Color, isGuided: Bool)] = [
        ("figure.walk", "Take a Walk", Color.green, false),
        ("figure.flexibility", "Stretches", Color.blue, true),
        ("eye", "Eye Exercises", Color.purple, true),
        ("arrow.up.and.person.rectangle.portrait", "Posture Reset", Color.indigo, true),
        ("lungs", "Deep Breathing", Color.mint, true),
        ("sun.max", "Go Outside", Color.orange, false)
    ]
    
    let waterAmounts = [8, 16, 24] // oz
    
    func handleActivityTap(_ activity: String, isGuided: Bool) {
        if isGuided {
            // Open the appropriate exercise window
            switch activity {
            case "Stretches":
                reminderManager.showExerciseSet(ExerciseData.twoMinuteRoutine)
            case "Eye Exercises":
                reminderManager.showExerciseSet(ExerciseData.eyeBreak)
            case "Posture Reset":
                reminderManager.showExerciseSet(ExerciseData.quickReset)
            case "Deep Breathing":
                reminderManager.showExerciseSet(ExerciseData.breathingExercise)
            default:
                break
            }
            // Close this window since exercise window is open
            dismiss()
        } else {
            // Instant completion for non-guided activities
            completeActivity(activity)
        }
    }
    
    func completeActivity(_ activity: String) {
        reminderManager.completeActivity(activity)
        reminderManager.completeBreak()
        completedActivity = activity
        showingCompletion = true
        
        // Auto-close after showing completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "leaf.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                Text("Time to Touch Grass")
                    .font(.title2)
                    .fontWeight(.medium)
            }
            
            Divider()
            
            if showingCompletion {
                // Completion view
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                    Text("Great job!")
                        .font(.title3)
                        .fontWeight(.medium)
                    Text("You completed: \(completedActivity ?? "")")
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
            } else {
                // Activities Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("What would you like to do?")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    // Activity buttons in a grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(activities, id: \.name) { activity in
                            Button(action: {
                                handleActivityTap(activity.name, isGuided: activity.isGuided)
                            }) {
                                VStack(spacing: 12) {
                                    Image(systemName: activity.icon)
                                        .font(.title2)
                                        .foregroundColor(activity.color)
                                    
                                    Text(activity.name)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.primary)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 80)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(activity.color.opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(activity.color.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            
                Divider()
                
                // Water Tracking Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Quick water log:")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Daily total
                        HStack(spacing: 4) {
                            Image(systemName: "drop.fill")
                                .foregroundColor(.blue)
                            Text("\(reminderManager.dailyWaterOz)oz today")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.blue.opacity(0.1))
                        )
                    }
                    
                    HStack(spacing: 12) {
                        ForEach(waterAmounts, id: \.self) { amount in
                            Button(action: {
                                reminderManager.logWater(ounces: amount)
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 14))
                                    Text("\(amount)oz")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.blue.opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Spacer()
                
                // Bottom Actions
                HStack(spacing: 12) {
                    Button(action: {
                        reminderManager.snoozeReminder()
                        dismiss()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "clock")
                                .font(.system(size: 12))
                            Text("Snooze 5 min")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.orange.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Skip for now")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(24)
        .frame(width: 400)
        .background(Color(NSColor.windowBackgroundColor))
    }
}