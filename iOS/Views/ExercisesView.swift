import SwiftUI

struct ExercisesView: View {
    @ObservedObject var manager: iOSReminderManager
    @State private var selectedExerciseSet: ExerciseSet?
    @State private var isShowingExercise = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Exercise Categories
                    ForEach(exerciseCategories, id: \.title) { category in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(category.title)
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(category.sets, id: \.name) { exerciseSet in
                                ExerciseCard(exerciseSet: exerciseSet) {
                                    selectedExerciseSet = exerciseSet
                                    isShowingExercise = true
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Exercises")
            .background(Color(.systemGroupedBackground))
            .sheet(isPresented: $isShowingExercise) {
                if let exerciseSet = selectedExerciseSet {
                    ExercisePlayerView(exerciseSet: exerciseSet, manager: manager)
                }
            }
        }
    }
}

struct ExerciseCategory {
    let title: String
    let sets: [ExerciseSet]
}

let exerciseCategories = [
    ExerciseCategory(
        title: "Quick Breaks",
        sets: [
            ExerciseData.quickReset,
            ExerciseData.oneMinuteBreak
        ]
    ),
    ExerciseCategory(
        title: "Stretching Routines",
        sets: [
            ExerciseData.twoMinuteRoutine,
            ExerciseData.fullRoutine
        ]
    ),
    ExerciseCategory(
        title: "Eye & Mind",
        sets: [
            ExerciseData.eyeBreak,
            ExerciseData.breathingExercise
        ]
    )
]

struct ExerciseCard: View {
    let exerciseSet: ExerciseSet
    let action: () -> Void
    
    var totalDuration: String {
        let total = exerciseSet.exercises.reduce(0) { $0 + $1.duration }
        let minutes = total / 60
        let seconds = total % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(exerciseSet.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("\(exerciseSet.exercises.count) exercises • \(totalDuration)")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.green)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 3)
            )
        }
    }
}

// Exercise Player View
struct ExercisePlayerView: View {
    let exerciseSet: ExerciseSet
    @ObservedObject var manager: iOSReminderManager
    @Environment(\.dismiss) var dismiss
    
    @State private var currentExerciseIndex = 0
    @State private var timeRemaining = 0
    @State private var timer: Timer?
    @State private var isCompleted = false
    
    var currentExercise: Exercise {
        exerciseSet.exercises[currentExerciseIndex]
    }
    
    var progress: Double {
        let totalExercises = exerciseSet.exercises.count
        return Double(currentExerciseIndex) / Double(totalExercises)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Progress bar
                ProgressView(value: progress)
                    .tint(.green)
                    .padding(.horizontal)
                
                if !isCompleted {
                    // Exercise content
                    VStack(spacing: 20) {
                        // Icon
                        Image(systemName: currentExercise.icon)
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                        
                        // Name
                        Text(currentExercise.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        // Instructions
                        Text(currentExercise.instructions)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        // Timer
                        Text("\(timeRemaining)s")
                            .font(.system(size: 60, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                        
                        // Control buttons
                        HStack(spacing: 40) {
                            Button(action: previousExercise) {
                                Image(systemName: "backward.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.secondary)
                            }
                            .disabled(currentExerciseIndex == 0)
                            
                            Button(action: nextExercise) {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.green)
                            }
                        }
                    }
                } else {
                    // Completion view
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 100))
                            .foregroundColor(.green)
                        
                        Text("Great job!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("You completed \(exerciseSet.name)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            manager.completeActivity(exerciseSet.name)
                            manager.completeBreak()
                            dismiss()
                        }) {
                            Text("Done")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(width: 200, height: 50)
                                .background(Color.green)
                                .cornerRadius(25)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle(exerciseSet.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        timer?.invalidate()
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            startExercise()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startExercise() {
        timeRemaining = currentExercise.duration
        startTimer()
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                nextExercise()
            }
        }
    }
    
    private func nextExercise() {
        if currentExerciseIndex < exerciseSet.exercises.count - 1 {
            currentExerciseIndex += 1
            startExercise()
        } else {
            timer?.invalidate()
            isCompleted = true
        }
    }
    
    private func previousExercise() {
        if currentExerciseIndex > 0 {
            currentExerciseIndex -= 1
            startExercise()
        }
    }
}