//
//  ExerciseView.swift
//  PosturePal
//
//  View for displaying and performing posture exercises
//

import SwiftUI
import Combine

struct ExerciseView: View {
    let exercise: Exercise
    @State private var currentInstructionIndex = 0
    @State private var timeRemaining: Int
    @State private var isCountingDown = false
    @State private var timerSubscription: AnyCancellable?
    
    init(exercise: Exercise) {
        self.exercise = exercise
        self._timeRemaining = State(initialValue: exercise.duration)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with name and timer
            VStack(spacing: 12) {
                Text(exercise.name)
                    .font(.title)
                    .fontWeight(.semibold)
                
                // Timer display with category info
                HStack(spacing: 24) {
                    Text(timeString)
                        .font(.system(size: 36, weight: .medium, design: .monospaced))
                        .foregroundColor(isCountingDown ? .blue : .primary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Label(exercise.category.rawValue, systemImage: categoryIcon)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Label("\(exercise.duration)s", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Divider()
            
            // All instructions visible at once
            VStack(alignment: .leading, spacing: 12) {
                Text("Instructions")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(exercise.instructions.enumerated()), id: \.offset) { index, instruction in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1).")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(currentInstructionIndex == index ? .blue : .secondary)
                                .frame(width: 20, alignment: .trailing)
                            
                            Text(instruction)
                                .font(.system(size: 14))
                                .foregroundColor(currentInstructionIndex == index ? .primary : .secondary)
                                .fontWeight(currentInstructionIndex == index ? .medium : .regular)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 2)
                        .padding(.horizontal, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(currentInstructionIndex == index ? Color.blue.opacity(0.1) : Color.clear)
                        )
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Benefits section (compact)
            VStack(spacing: 6) {
                Text("Benefits")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(exercise.benefits)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal)
            
            // Control buttons
            Button(action: toggleTimer) {
                Label(
                    isCountingDown ? "Pause" : "Start Exercise",
                    systemImage: isCountingDown ? "pause.fill" : "play.fill"
                )
                .frame(width: 140)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(width: 500, height: 600)
        .onDisappear {
            stopTimer()
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
            stopTimer()
        } else {
            startTimer()
        }
    }
    
    private func startTimer() {
        isCountingDown = true
        timerSubscription = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                    updateInstructionIndex()
                } else {
                    stopTimer()
                    // Play completion sound
                    NSSound.beep()
                    // Reset for next use
                    timeRemaining = exercise.duration
                    currentInstructionIndex = 0
                }
            }
    }
    
    private func stopTimer() {
        isCountingDown = false
        timerSubscription?.cancel()
        timerSubscription = nil
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