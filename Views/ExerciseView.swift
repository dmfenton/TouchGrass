//
//  ExerciseView.swift
//  PosturePal
//
//  View for displaying and performing posture exercises
//

import SwiftUI

struct ExerciseView: View {
    let exercise: Exercise
    @State private var currentInstructionIndex = 0
    @State private var timeRemaining: Int
    @State private var isCountingDown = false
    @State private var timer: Timer?
    
    init(exercise: Exercise) {
        self.exercise = exercise
        self._timeRemaining = State(initialValue: exercise.duration)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Exercise name and category
            VStack(spacing: 4) {
                Text(exercise.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                HStack(spacing: 8) {
                    Label(exercise.category.rawValue, systemImage: categoryIcon)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Label("\(exercise.duration)s", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Target area and benefits
            VStack(alignment: .leading, spacing: 8) {
                Label(exercise.targetArea, systemImage: "figure.stand")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                
                Text(exercise.benefits)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            
            // Instructions
            VStack(alignment: .leading, spacing: 4) {
                Text("Instructions:")
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(exercise.instructions.enumerated()), id: \.offset) { index, instruction in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(index + 1).")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 20, alignment: .leading)
                                
                                Text(instruction)
                                    .font(.caption)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .foregroundColor(currentInstructionIndex == index ? .primary : .secondary)
                            }
                        }
                    }
                }
                .frame(maxHeight: 150)
            }
            .padding(.horizontal)
            
            // Timer and control
            VStack(spacing: 12) {
                // Timer display
                Text(timeString)
                    .font(.system(size: 28, weight: .medium, design: .monospaced))
                    .foregroundColor(isCountingDown ? .blue : .primary)
                
                // Start/Stop button
                Button(action: toggleTimer) {
                    Label(
                        isCountingDown ? "Pause" : "Start Exercise",
                        systemImage: isCountingDown ? "pause.fill" : "play.fill"
                    )
                    .frame(width: 140)
                }
                .controlSize(.regular)
            }
        }
        .padding()
        .frame(width: 350)
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private var categoryIcon: String {
        switch exercise.category {
        case .stretch:
            return "arrow.up.and.down.and.arrow.left.and.right"
        case .strengthen:
            return "dumbbell.fill"
        case .mobilize:
            return "arrow.trianglehead.2.clockwise.rotate.90"
        case .quickReset:
            return "arrow.clockwise"
        }
    }
    
    private var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func toggleTimer() {
        if isCountingDown {
            timer?.invalidate()
            timer = nil
            isCountingDown = false
        } else {
            isCountingDown = true
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                    updateInstructionIndex()
                } else {
                    timer?.invalidate()
                    timer = nil
                    isCountingDown = false
                    // Play completion sound
                    NSSound.beep()
                }
            }
        }
    }
    
    private func updateInstructionIndex() {
        // Update which instruction to highlight based on time
        let timeElapsed = exercise.duration - timeRemaining
        let timePerInstruction = exercise.duration / exercise.instructions.count
        currentInstructionIndex = min(timeElapsed / timePerInstruction, exercise.instructions.count - 1)
    }
}

struct ExerciseSetView: View {
    let exerciseSet: ExerciseSet
    @State private var currentExerciseIndex = 0
    @State private var showingExercise = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Text(exerciseSet.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(exerciseSet.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Label("\(exerciseSet.duration / 60) min \(exerciseSet.duration % 60) sec total", 
                      systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Exercise list or current exercise
            if showingExercise && currentExerciseIndex < exerciseSet.exercises.count {
                VStack(spacing: 12) {
                    // Progress indicator
                    HStack {
                        Text("Exercise \(currentExerciseIndex + 1) of \(exerciseSet.exercises.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Progress dots
                        HStack(spacing: 6) {
                            ForEach(0..<exerciseSet.exercises.count, id: \.self) { index in
                                Circle()
                                    .fill(index <= currentExerciseIndex ? Color.blue : Color.gray.opacity(0.3))
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    ExerciseView(exercise: exerciseSet.exercises[currentExerciseIndex])
                    
                    HStack(spacing: 16) {
                        if currentExerciseIndex > 0 {
                            Button("Previous") {
                                currentExerciseIndex -= 1
                            }
                        }
                        
                        Spacer()
                        
                        if currentExerciseIndex < exerciseSet.exercises.count - 1 {
                            Button("Next Exercise") {
                                currentExerciseIndex += 1
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            Button("Complete") {
                                dismiss()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(.horizontal)
                }
            } else {
                // Exercise preview list
                VStack(alignment: .leading, spacing: 12) {
                    Text("Exercises included:")
                        .font(.footnote)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    ForEach(exerciseSet.exercises) { exercise in
                        HStack {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(exercise.name)
                                .font(.body)
                            
                            Spacer()
                            
                            Text("\(exercise.duration)s")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button(action: {
                    showingExercise = true
                    currentExerciseIndex = 0
                }) {
                    Label("Start Exercises", systemImage: "play.fill")
                        .frame(width: 140)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding()
        .frame(width: 400, height: 500)
    }
}