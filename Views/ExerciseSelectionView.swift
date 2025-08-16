import SwiftUI

struct ExerciseSelectionView: View {
    @ObservedObject var reminderManager: ReminderManager
    @Environment(\.dismiss) var dismiss
    
    let exerciseOptions: [(set: ExerciseSet, icon: String)] = [
        (ExerciseData.oneMinuteBreak, "clock"),
        (ExerciseData.upperBodyRoutine, "figure.arms.open"),
        (ExerciseData.lowerBodyRoutine, "figure.walk")
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "figure.flexibility")
                    .font(.title2)
                    .foregroundColor(.primary.opacity(0.8))
                Text("Choose Exercise Routine")
                    .font(.title2)
                    .fontWeight(.medium)
            }
            .padding(.top)
            
            Divider()
            
            // Exercise options
            VStack(spacing: 12) {
                ForEach(exerciseOptions, id: \.set.id) { option in
                    Button(action: {
                        reminderManager.showExerciseSet(option.set)
                        dismiss()
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: option.icon)
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                                .frame(width: 40)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(option.set.name)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Text(option.set.description)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(option.set.duration / 60) min")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                Text("\(option.set.exercises.count) exercises")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Cancel button
            Button("Cancel") {
                dismiss()
            }
            .padding(.bottom)
        }
        .frame(width: 400, height: 350)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
