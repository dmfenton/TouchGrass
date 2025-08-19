import SwiftUI

struct TouchGrassMode: View {
    @ObservedObject var reminderManager: ReminderManager
    @Environment(\.dismiss) var dismiss
    @State private var showingCompletion = false
    @State private var completedActivity: String? = nil
    @State private var showExerciseMenu = false
    @State private var selectedExerciseSet: ExerciseSet? = nil
    
    private func closeMenuBar() {
        NSApplication.shared.keyWindow?.close()
    }
    
    // Simplified to 4 main options with minimal colors
    let activities: [(icon: String, name: String, color: Color, isGuided: Bool)] = [
        ("clock", "1 Min Reset", Color.primary, true),
        ("figure.flexibility", "Exercises", Color.primary, true),
        ("brain.head.profile", "Meditation", Color.primary, true),
        ("leaf.circle", "Touch Grass", Color.primary, false)
    ]
    
    func handleActivityTap(_ activity: String, isGuided: Bool) {
        if isGuided {
            // Open the appropriate exercise window
            switch activity {
            case "1 Min Reset":
                // Quick 1-minute posture reset
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedExerciseSet = ExerciseData.oneMinuteBreak
                }
            case "Exercises":
                // Show exercise menu state
                withAnimation(.easeInOut(duration: 0.2)) {
                    showExerciseMenu = true
                }
            case "Meditation":
                // Breathing and relaxation exercises
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedExerciseSet = ExerciseData.breathingExercise
                }
            default:
                break
            }
        } else {
            // Touch Grass - go outside
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
            closeMenuBar()
            dismiss()
        }
    }
    
    var body: some View {
        if let exerciseSet = selectedExerciseSet {
            // Show exercise view directly
            ExerciseSetView(
                exerciseSet: exerciseSet,
                reminderManager: reminderManager,
                onClose: {
                    // Go back to main menu
                    selectedExerciseSet = nil
                    showExerciseMenu = false
                }
            )
        } else {
            // Show normal Touch Grass mode
            VStack(spacing: 20) {
            // Header
            HStack {
                GrassIcon(isActive: false, size: 24)
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
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
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
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
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
            } else if showExerciseMenu {
                // Exercise menu
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Button(action: { showExerciseMenu = false }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14))
                        }
                        .buttonStyle(.plain)
                        
                        Text("Choose Exercise Routine")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    // Exercise options
                    VStack(spacing: 8) {
                        // Upper Body Routine
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedExerciseSet = ExerciseData.upperBodyRoutine
                            }
                        }) {
                            HStack {
                                Image(systemName: "figure.arms.open")
                                    .frame(width: 30)
                                VStack(alignment: .leading) {
                                    Text("Upper Body & Posture")
                                        .font(.system(size: 14, weight: .medium))
                                    Text("3 min • Neck, shoulders, upper back")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                    .fill(Color.secondary.opacity(0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        .onHover { hovering in
                            if hovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                        
                        // Lower Body Routine
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedExerciseSet = ExerciseData.lowerBodyRoutine
                            }
                        }) {
                            HStack {
                                Image(systemName: "figure.walk")
                                    .frame(width: 30)
                                VStack(alignment: .leading) {
                                    Text("Hips, Glutes & Knees")
                                        .font(.system(size: 14, weight: .medium))
                                    Text("5 min • Lower body tension relief")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                    .fill(Color.secondary.opacity(0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        .onHover { hovering in
                            if hovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                        
                        // Ankle & Foot Routine
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedExerciseSet = ExerciseData.ankleFootRoutine
                            }
                        }) {
                            HStack {
                                Image(systemName: "shoeprints.fill")
                                    .frame(width: 30)
                                VStack(alignment: .leading) {
                                    Text("Ankle & Foot Mobility")
                                        .font(.system(size: 14, weight: .medium))
                                    Text("4.5 min • Ankle flexibility & foot health")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                    .fill(Color.secondary.opacity(0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        .onHover { hovering in
                            if hovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                        
                        // Eye Break
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedExerciseSet = ExerciseData.eyeBreak
                            }
                        }) {
                            HStack {
                                Image(systemName: "eye")
                                    .frame(width: 30)
                                VStack(alignment: .leading) {
                                    Text("Eye Relief")
                                        .font(.system(size: 14, weight: .medium))
                                    Text("1 min • Reduce eye strain")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                    .fill(Color.secondary.opacity(0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        .onHover { hovering in
                            if hovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                    }
                }
            } else {
                // Main activities Section
                VStack(alignment: .leading, spacing: 12) {
                    // Suggested activity from the engine
                    if let suggestion = reminderManager.suggestionEngine?.getSuggestion() {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 14))
                                    .foregroundColor(.orange)
                                Text("Suggested for you")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            
                            Button(action: {
                                // Handle the suggested activity
                                switch suggestion.type {
                                case .touchGrass:
                                    handleActivityTap("Touch Grass", isGuided: false)
                                case .posture:
                                    handleActivityTap("1 Min Reset", isGuided: true)
                                case .exercise:
                                    handleActivityTap("Exercises", isGuided: true)
                                case .meditation:
                                    handleActivityTap("Meditation", isGuided: true)
                                case .hydration:
                                    // Log water and show completion
                                    reminderManager.waterTracker.logWater(1)
                                    completeActivity("Hydration Break")
                                }
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(suggestion.title)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.primary)
                                        if let reason = suggestion.reason {
                                            Text(reason)
                                                .font(.system(size: 12))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.orange)
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                        .fill(Color.orange.opacity(0.08))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.bottom, 8)
                    }
                    
                    HStack {
                        Text("Or choose an activity:")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
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
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                                        .fill(Color.secondary.opacity(0.05))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .contentShape(Rectangle())
                            .onHover { hovering in
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                        }
                    }
                }
            
                Divider()
                
                // Water Tracking Section - consistent with main menu
                HStack {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.0, green: 0.5, blue: 1.0))
                    
                    Text("\(reminderManager.currentWaterIntake * 8) / 64 oz")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: { reminderManager.logWater(1) }) {
                        Text("+8oz")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                                    .fill(Color(red: 0.0, green: 0.5, blue: 1.0))
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                
                Spacer()
                
                // Bottom Actions
                HStack(spacing: 12) {
                    Button(action: {
                        reminderManager.snoozeReminder()
                        closeMenuBar()
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
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Button(action: {
                        reminderManager.hasActiveReminder = false
                        reminderManager.scheduleNextTick()
                        closeMenuBar()
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
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .padding(.top, 32)
        .frame(width: 400)
        .background(Color(NSColor.controlBackgroundColor))
        .onAppear {
            // Refresh calendar data when window opens
            reminderManager.calendarManager?.updateCurrentAndNextEvents()
            
            // Reset active reminder state when Touch Grass window opens
            if reminderManager.hasActiveReminder {
                reminderManager.hasActiveReminder = false
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showExerciseMenu)
        .animation(.easeInOut(duration: 0.2), value: selectedExerciseSet?.id)
        } // End else
    }
}
