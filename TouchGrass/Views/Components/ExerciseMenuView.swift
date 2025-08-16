//
//  ExerciseMenuView.swift
//  TouchGrass
//
//  Exercise selection menu component
//

import SwiftUI

struct ExerciseMenuView: View {
    let onBack: () -> Void
    let onExerciseSelected: (ExerciseSet) -> Void
    @State private var hoveredExercise: String?
    
    private let exercises: [(id: String, name: String, duration: String, description: String, icon: String, set: ExerciseSet)] = [
        ("upper", "Upper Body & Posture", "3 min", "Neck, shoulders, upper back", "figure.arms.open", ExerciseData.upperBodyRoutine),
        ("lower", "Hips, Glutes & Knees", "5 min", "Lower body tension relief", "figure.walk", ExerciseData.lowerBodyRoutine),
        ("ankle", "Ankle & Foot Mobility", "4.5 min", "Ankle flexibility & foot health", "shoeprints.fill", ExerciseData.ankleFootRoutine),
        ("eye", "Eye Relief", "1 min", "Reduce eye strain", "eye", ExerciseData.eyeBreak)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            // Header with back button
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(DesignSystem.Typography.bodyRegular)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back to activities")
                
                Text("Choose Exercise Routine")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
            }
            
            // Exercise options
            VStack(spacing: DesignSystem.Spacing.small) {
                ForEach(exercises, id: \.id) { exercise in
                    ExerciseOptionButton(
                        name: exercise.name,
                        duration: exercise.duration,
                        description: exercise.description,
                        icon: exercise.icon,
                        isHovered: hoveredExercise == exercise.id,
                        action: {
                            withAnimation(DesignSystem.Animation.standard) {
                                onExerciseSelected(exercise.set)
                            }
                        },
                        onHover: { isHovered in
                            withAnimation(DesignSystem.Animation.micro) {
                                hoveredExercise = isHovered ? exercise.id : nil
                            }
                        }
                    )
                }
            }
        }
    }
}

struct ExerciseOptionButton: View {
    let name: String
    let duration: String
    let description: String
    let icon: String
    let isHovered: Bool
    let action: () -> Void
    let onHover: (Bool) -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 30)
                    .foregroundColor(isHovered ? DesignSystem.Colors.primaryGreen : DesignSystem.Colors.textPrimary.opacity(0.7))
                
                VStack(alignment: .leading) {
                    Text(name)
                        .font(DesignSystem.Typography.bodyRegular)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("\(duration) • \(description)")
                        .font(DesignSystem.Typography.labelSmall)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                if isHovered {
                    Image(systemName: "chevron.right")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.primaryGreen)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .padding(DesignSystem.Spacing.medium)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(isHovered ? 
                          DesignSystem.Colors.tertiaryGreen : 
                          DesignSystem.Colors.backgroundSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke(isHovered ? 
                           DesignSystem.Colors.primaryGreen.opacity(0.3) : 
                           DesignSystem.Colors.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .onHover(perform: onHover)
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(DesignSystem.Animation.micro, value: isHovered)
        .accessibilityLabel("\(name), \(duration), \(description)")
    }
}
