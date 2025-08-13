import SwiftUI

struct TouchGrassMode: View {
    @ObservedObject var reminderManager: ReminderManager
    @Environment(\.dismiss) var dismiss
    @State private var showingCompletion = false
    @State private var completedActivity: String? = nil
    
    // Simplified to 4 main options with minimal colors
    let activities: [(icon: String, name: String, color: Color, isGuided: Bool)] = [
        ("leaf.circle", "Touch Grass", Color.primary, false),
        ("arrow.up.and.person.rectangle.portrait", "30s Posture Reset", Color.primary, true),
        ("figure.flexibility", "Exercises", Color.primary, true),
        ("brain.head.profile", "Meditation", Color.primary, true)
    ]
    
    func handleActivityTap(_ activity: String, isGuided: Bool) {
        if isGuided {
            // Open the appropriate exercise window
            switch activity {
            case "30s Posture Reset":
                // Quick 30-second posture reset (chin tucks + scapular retraction)
                reminderManager.showExerciseSet(ExerciseData.quickReset)
            case "Exercises":
                // Rotate through different exercise sets for variety
                let exerciseSets = [
                    ExerciseData.twoMinuteRoutine,  // Stretches
                    ExerciseData.eyeBreak,           // Eye exercises
                    ExerciseData.fullRoutine,        // Full 3-minute routine
                    ExerciseData.oneMinuteBreak      // Quick posture break
                ]
                let randomSet = exerciseSets.randomElement() ?? ExerciseData.twoMinuteRoutine
                reminderManager.showExerciseSet(randomSet)
            case "Meditation":
                // Breathing and relaxation exercises
                reminderManager.showExerciseSet(ExerciseData.breathingExercise)
            default:
                break
            }
            // Close this window since exercise window is open
            dismiss()
        } else {
            // Instant completion for "Touch Grass" (go outside)
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
                Image(systemName: "leaf.circle")
                    .font(.title2)
                    .foregroundColor(.primary.opacity(0.8))
                Text("Time to Touch Grass")
                    .font(.title2)
                    .fontWeight(.medium)
            }
            
            // Calendar context
            if let calManager = reminderManager.calendarManager,
               calManager.hasCalendarAccess,
               !calManager.selectedCalendarIdentifiers.isEmpty {
                
                HStack(spacing: 12) {
                    // Current meeting status
                    if calManager.isInMeeting, let currentEvent = calManager.currentEvent {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.primary.opacity(0.4))
                                .frame(width: 8, height: 8)
                            Text("In meeting until \(calManager.formatEventTime(currentEvent.endDate))")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    } else if let nextEvent = calManager.nextEvent,
                              let timeUntil = calManager.timeUntilNextEvent {
                        HStack(spacing: 6) {
                            Image(systemName: "clock")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Text("Next meeting in \(calManager.formatTimeUntilEvent(timeUntil))")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.primary)
                            Text("•")
                                .foregroundColor(.secondary)
                            Text(nextEvent.title ?? "Event")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.controlBackgroundColor).opacity(0.8))
                        )
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Text("No upcoming meetings - enjoy your break!")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.controlBackgroundColor).opacity(0.8))
                        )
                    }
                }
                .frame(maxWidth: .infinity)
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
                    HStack {
                        Text("What would you like to do?")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Smart suggestion based on time available
                        if let calManager = reminderManager.calendarManager,
                           let timeUntil = calManager.timeUntilNextEvent {
                            if timeUntil >= 900 {  // 15+ minutes
                                Label("Perfect for a walk!", systemImage: "figure.walk")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            } else if timeUntil >= 300 {  // 5-15 minutes
                                Label("Quick stretch time", systemImage: "figure.flexibility")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            } else {  // Less than 5 minutes
                                Label("Try breathing", systemImage: "lungs")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Activity buttons in a 2x2 grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(activities, id: \.name) { activity in
                            Button(action: {
                                handleActivityTap(activity.name, isGuided: activity.isGuided)
                            }) {
                                VStack(spacing: 12) {
                                    Image(systemName: activity.icon)
                                        .font(.title2)
                                        .foregroundColor(.primary.opacity(0.7))
                                    
                                    Text(activity.name)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.primary)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 80)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(NSColor.controlBackgroundColor))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            
                Divider()
                
                // Water Tracking Section - consistent with main menu
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Quick water log:")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Daily total - show in current unit
                        HStack(spacing: 4) {
                            Image(systemName: "drop.fill")
                                .foregroundColor(.primary.opacity(0.6))
                            Text("\(reminderManager.currentWaterIntake)/\(reminderManager.dailyWaterGoal) \(reminderManager.waterUnit.rawValue)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )
                    }
                    
                    HStack(spacing: 12) {
                        // Use consistent amounts with main menu (+1, +2, +3 in current unit)
                        ForEach([1, 2, 3], id: \.self) { amount in
                            Button(action: {
                                reminderManager.logWater(amount)
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus.circle")
                                        .font(.system(size: 14))
                                    Text("+\(amount)")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(NSColor.controlBackgroundColor))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
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
                                .fill(Color.orange.opacity(0.08))
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
        .onAppear {
            // Refresh calendar data when window opens
            reminderManager.calendarManager?.updateCurrentAndNextEvents()
        }
    }
}