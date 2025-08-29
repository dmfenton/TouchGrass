import SwiftUI

struct TouchGrassModeWithSuggestion: View {
    @ObservedObject var reminderManager: ReminderManager
    @Environment(\.dismiss) var dismiss
    @State private var showingCompletion = false
    @State private var completedActivity: String? = nil
    @State private var showAllActivities = false
    @State private var selectedExerciseSet: ExerciseSet? = nil
    @State private var currentSuggestion: SuggestedActivity?
    @State private var isLoadingSuggestion = true
    
    private func closeMenuBar() {
        NSApplication.shared.keyWindow?.close()
    }
    
    var body: some View {
        if let exerciseSet = selectedExerciseSet {
            // Show exercise view directly
            ExerciseSetView(
                exerciseSet: exerciseSet,
                reminderManager: reminderManager,
                onClose: {
                    selectedExerciseSet = nil
                    showAllActivities = false
                    loadSuggestion()
                }
            )
        } else if showingCompletion {
            // Completion view
            CompletionAnimationView(
                activity: completedActivity ?? "Break",
                onDismiss: {
                    closeMenuBar()
                    dismiss()
                }
            )
        } else if showAllActivities {
            // Show all activity options
            AllActivitiesView(
                reminderManager: reminderManager,
                onSelectActivity: { activity, exerciseSet in
                    if let exercise = exerciseSet {
                        selectedExerciseSet = exercise
                    } else {
                        completeActivity(activity)
                    }
                },
                onBack: {
                    showAllActivities = false
                }
            )
        } else {
            // Main suggestion view
            VStack(spacing: 0) {
                // Header
                HStack {
                    GrassIcon(isActive: false, size: 20)
                        .foregroundColor(DesignSystem.Colors.primaryGreen)
                    Text("Time for a Break")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                
                Divider()
                
                // Calendar context (compact)
                if let calManager = reminderManager.calendarManager,
                   calManager.hasCalendarAccess,
                   !calManager.selectedCalendarIdentifiers.isEmpty {
                    CalendarContextBar(calendarManager: calManager)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    Divider()
                }
                
                // Main content
                if isLoadingSuggestion {
                    // Loading state
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Finding the perfect break for you...")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else if let suggestion = currentSuggestion {
                    // Suggestion content
                    VStack(spacing: 16) {
                        // Smart suggestion reason
                        HStack {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12))
                                .foregroundColor(.orange)
                            Text(suggestion.reason)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        
                        // Primary suggestion - prominent
                        Button(action: { handleSuggestion(suggestion) }) {
                            VStack(spacing: 12) {
                                // Icon and title
                                HStack(spacing: 12) {
                                    Image(systemName: suggestionIcon(for: suggestion))
                                        .font(.system(size: 28))
                                        .foregroundColor(suggestionColor(for: suggestion))
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(suggestion.title)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.primary)
                                        Text("\(suggestion.duration) minute\(suggestion.duration == 1 ? "" : "s")")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(suggestionColor(for: suggestion))
                                }
                                
                                // Urgency indicator (if high)
                                if suggestion.urgency > 0.7 {
                                    HStack {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(urgencyColor(suggestion.urgency))
                                            .frame(height: 4)
                                            .frame(maxWidth: 200)
                                            .overlay(alignment: .leading) {
                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(urgencyColor(suggestion.urgency).opacity(0.8))
                                                    .frame(width: 200 * suggestion.urgency, height: 4)
                                            }
                                        Text(urgencyText(suggestion.urgency))
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(urgencyColor(suggestion.urgency))
                                    }
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(suggestionColor(for: suggestion).opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(suggestionColor(for: suggestion).opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 16)
                        
                        // Alternative option
                        HStack(spacing: 16) {
                            Button(action: { showAllActivities = true }) {
                                HStack {
                                    Image(systemName: "square.grid.2x2")
                                        .font(.system(size: 13))
                                    Text("Choose Different Activity")
                                        .font(.system(size: 13))
                                }
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: snoozeAndClose) {
                                HStack {
                                    Image(systemName: "alarm.waves.left.and.right")
                                        .font(.system(size: 13))
                                    Text("Snooze 5 min")
                                        .font(.system(size: 13))
                                }
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                } else {
                    // Fallback if no suggestion
                    VStack(spacing: 12) {
                        Image(systemName: "leaf.circle")
                            .font(.system(size: 40))
                            .foregroundColor(.green)
                        Text("Time to take a break!")
                            .font(.system(size: 14, weight: .medium))
                        Button("Choose an Activity") {
                            showAllActivities = true
                        }
                        .buttonStyle(PlainButtonStyle())
                        .foregroundColor(.blue)
                    }
                    .padding(.vertical, 40)
                }
            }
            .frame(width: 360)
            .onAppear {
                loadSuggestion()
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func loadSuggestion() {
        isLoadingSuggestion = true
        currentSuggestion = nil
        
        Task {
            if let engine = reminderManager.suggestionEngine {
                let suggestion = await engine.getSuggestion()
                await MainActor.run {
                    currentSuggestion = suggestion
                    isLoadingSuggestion = false
                }
            } else {
                // Fallback suggestion
                await MainActor.run {
                    currentSuggestion = SuggestedActivity(
                        type: "touchGrass",
                        title: "Take a Walk",
                        reason: "Step away from your desk",
                        duration: 5,
                        category: .outdoor
                    )
                    isLoadingSuggestion = false
                }
            }
        }
    }
    
    private func handleSuggestion(_ suggestion: SuggestedActivity) {
        switch suggestion.type {
        case "exercise":
            if let exerciseSet = suggestion.exerciseSet {
                selectedExerciseSet = exerciseSet
            } else {
                // Fallback to default exercise
                selectedExerciseSet = ExerciseData.oneMinuteBreak
            }
        case "meditation", "breathing":
            selectedExerciseSet = ExerciseData.breathingExercise
        default:
            completeActivity(suggestion.title)
        }
    }
    
    private func completeActivity(_ activity: String) {
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
    
    private func snoozeAndClose() {
        reminderManager.snoozeReminder()
        closeMenuBar()
        dismiss()
    }
    
    private func suggestionIcon(for suggestion: SuggestedActivity) -> String {
        switch suggestion.type {
        case "touchGrass": return "leaf.circle.fill"
        case "exercise": return "figure.flexibility"
        case "water": return "drop.fill"
        case "meditation", "breathing": return "brain.head.profile"
        default: return "star.circle.fill"
        }
    }
    
    private func suggestionColor(for suggestion: SuggestedActivity) -> Color {
        switch suggestion.category {
        case .outdoor: return DesignSystem.Colors.primaryGreen
        case .physical, .posture: return .blue
        case .mental: return .purple
        // hydration category removed - now handled separately
        }
    }
    
    private func urgencyColor(_ urgency: Double) -> Color {
        if urgency > 0.8 { return .orange }
        if urgency > 0.6 { return .yellow }
        return .green
    }
    
    private func urgencyText(_ urgency: Double) -> String {
        if urgency > 0.8 { return "Recommended" }
        if urgency > 0.6 { return "Good timing" }
        return ""
    }
    
}

// MARK: - Supporting Views

struct CalendarContextBar: View {
    let calendarManager: CalendarManager
    
    var body: some View {
        HStack(spacing: 8) {
            if calendarManager.isInMeeting, let currentEvent = calendarManager.currentEvent {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 6, height: 6)
                    Text("In meeting until \(calendarManager.formatEventTime(currentEvent.endDate))")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            } else if let nextEvent = calendarManager.nextEvent,
                      let timeUntil = calendarManager.timeUntilNextEvent {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text("\(calendarManager.formatTimeUntilEvent(timeUntil)) until")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text(nextEvent.title ?? "next meeting")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
            } else {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text("No meetings - enjoy your break!")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
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

struct AllActivitiesView: View {
    let reminderManager: ReminderManager
    let onSelectActivity: (String, ExerciseSet?) -> Void
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with back button
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12))
                        Text("Back")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Text("All Activities")
                    .font(.system(size: 14, weight: .semibold))
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            Divider()
            
            // Activity grid
            VStack(spacing: 8) {
                SuggestionActivityButton(
                    icon: "leaf.circle",
                    title: "Touch Grass",
                    subtitle: "Go outside",
                    color: .green,
                    action: { onSelectActivity("Touch Grass", nil) }
                )
                
                SuggestionActivityButton(
                    icon: "figure.flexibility",
                    title: "Posture Reset",
                    subtitle: "5 min routine",
                    color: .blue,
                    action: { onSelectActivity("Exercise", ExerciseData.oneMinuteBreak) }
                )
                
                SuggestionActivityButton(
                    icon: "figure.walk",
                    title: "Quick Stretches",
                    subtitle: "3 min desk stretches",
                    color: .blue,
                    action: { onSelectActivity("Exercise", ExerciseData.quickReset) }
                )
                
                SuggestionActivityButton(
                    icon: "brain.head.profile",
                    title: "Meditation",
                    subtitle: "Breathing exercises",
                    color: .purple,
                    action: { onSelectActivity("Meditation", ExerciseData.breathingExercise) }
                )
                
                if reminderManager.waterTrackingEnabled {
                    SuggestionActivityButton(
                        icon: "drop.fill",
                        title: "Water Break",
                        subtitle: "Stay hydrated",
                        color: Color(red: 0.0, green: 0.5, blue: 1.0),
                        action: { 
                            reminderManager.logWater()
                            onSelectActivity("Water Break", nil)
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .frame(width: 360)
    }
}

struct SuggestionActivityButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CompletionAnimationView: View {
    let activity: String
    let onDismiss: () -> Void
    @State private var showCheckmark = false
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.green)
                    .scaleEffect(showCheckmark ? 1 : 0.5)
                    .opacity(showCheckmark ? 1 : 0)
            }
            
            Text("Great job!")
                .font(.system(size: 16, weight: .semibold))
            
            Text("Completed: \(activity)")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .frame(width: 360, height: 200)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showCheckmark = true
            }
        }
    }
}
