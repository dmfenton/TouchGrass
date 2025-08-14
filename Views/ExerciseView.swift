//
//  ExerciseView.swift
//  TouchGrass
//
//  View for displaying and performing posture exercises
//

import SwiftUI
import Combine

struct ExerciseView: View {
    let exercise: Exercise
    @State private var timeRemaining: Int
    @State private var isCountingDown = false
    @State private var timerSubscription: AnyCancellable?
    var onCompletion: (() -> Void)?
    
    init(exercise: Exercise, onCompletion: (() -> Void)? = nil) {
        self.exercise = exercise
        self._timeRemaining = State(initialValue: exercise.duration)
        self.onCompletion = onCompletion
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
                                .foregroundColor(.secondary)
                                .frame(width: 20, alignment: .trailing)
                            
                            Text(instruction)
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 2)
                        .padding(.horizontal, 8)
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
                } else {
                    stopTimer()
                    // Play completion sound
                    NSSound.beep()
                    // Reset for next use
                    timeRemaining = exercise.duration
                    // Call completion handler if provided
                    onCompletion?()
                }
            }
    }
    
    private func stopTimer() {
        isCountingDown = false
        timerSubscription?.cancel()
        timerSubscription = nil
    }
}

struct ExerciseSetView: View {
    let exerciseSet: ExerciseSet
    var onClose: (() -> Void)? = nil
    @State private var currentExerciseIndex = 0
    @State private var showingExercise = false
    @State private var autoAdvance = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with close button inline
            HStack(alignment: .top) {
                Spacer(minLength: 30) // Balance for close button
                
                VStack(spacing: 6) {
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
                
                Spacer(minLength: 30)
                
                if let onClose = onClose {
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 2)
                }
            }
            .padding(.top, 8)
            
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
                        
                        // Auto-advance toggle for quick reset
                        if exerciseSet.id == "quick-reset" {
                            Toggle("Auto-advance", isOn: $autoAdvance)
                                .toggleStyle(.switch)
                                .scaleEffect(0.8)
                        }
                        
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
                    
                    ExerciseView(
                        exercise: exerciseSet.exercises[currentExerciseIndex],
                        onCompletion: {
                            // Auto-advance for quick posture reset
                            if exerciseSet.id == "quick-reset" && autoAdvance {
                                if currentExerciseIndex < exerciseSet.exercises.count - 1 {
                                    currentExerciseIndex += 1
                                } else {
                                    // All exercises completed
                                    dismiss()
                                }
                            }
                        }
                    )
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            if currentExerciseIndex > 0 {
                                currentExerciseIndex -= 1
                            } else {
                                // Go back to overview
                                showingExercise = false
                            }
                        }) {
                            Label(currentExerciseIndex > 0 ? "Previous" : "Overview", 
                                  systemImage: "chevron.left")
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
                // Exercise overview list
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Exercise Overview")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        ForEach(Array(exerciseSet.exercises.enumerated()), id: \.offset) { index, exercise in
                            Button(action: {
                                // Jump directly to this exercise
                                currentExerciseIndex = index
                                showingExercise = true
                            }) {
                                HStack(alignment: .top, spacing: 12) {
                                    // Exercise number
                                    ZStack {
                                        Circle()
                                            .fill(Color.blue.opacity(0.1))
                                            .frame(width: 30, height: 30)
                                        Text("\(index + 1)")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.blue)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(exercise.name)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.primary)
                                            
                                            Spacer()
                                            
                                            Label("\(exercise.duration)s", systemImage: "clock")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        // Show first instruction as preview
                                        if let firstInstruction = exercise.instructions.first {
                                            Text(firstInstruction)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .lineLimit(2)
                                        }
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.blue.opacity(0.02))
                                    .opacity(0)
                            )
                            .onHover { isHovered in
                                // Add hover effect if desired
                            }
                            
                            if index < exerciseSet.exercises.count - 1 {
                                Divider()
                                    .padding(.leading, 42)
                            }
                        }
                        
                        // Total time summary
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.blue)
                            Text("Total time: \(exerciseSet.duration / 60) min \(exerciseSet.duration % 60) sec")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: 500)
                
                VStack(spacing: 12) {
                    Button(action: {
                        showingExercise = true
                        currentExerciseIndex = 0
                    }, label: {
                        Label("Start Exercises", systemImage: "play.fill")
                            .frame(width: 160)
                    })
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Text("You can return to this overview at any time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .frame(width: 500, height: 600)
    }
}
