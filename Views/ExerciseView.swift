//
//  ExerciseView.swift
//  TouchGrass
//
//  View for displaying and performing posture exercises
//

import SwiftUI
import Combine
import AVFoundation

// Audio controller using pre-generated audio files
class AudioController: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    @Published var currentUtteranceIndex = 0
    
    private var audioPlayer: AVAudioPlayer?
    private var completionHandler: (() -> Void)?
    private var isPaused = false
    
    override init() {
        super.init()
    }
    
    func playAudioFile(_ fileName: String, completion: @escaping () -> Void) {
        completionHandler = completion
        
        // Construct the file path
        guard let audioURL = Bundle.main.url(forResource: fileName, withExtension: "mp3") else {
            print("Audio file not found: \(fileName).mp3")
            // Fallback: call completion immediately
            DispatchQueue.main.async {
                completion()
            }
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.delegate = self
            audioPlayer?.volume = 0.9
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
            isPaused = false
        } catch {
            print("Error playing audio file: \(error)")
            // Fallback: call completion immediately
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    func playExerciseAudio(exerciseKey: String, audioType: String, stepNumber: Int? = nil, completion: @escaping () -> Void) {
        // Convert exercise key to snake_case for file path
        let snakeKey = exerciseKey
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")
            .lowercased()
        
        // Build file path
        var fileName: String
        if let step = stepNumber {
            fileName = "Assets/Audio/Exercises/\(snakeKey)/step_\(step)"
        } else {
            fileName = "Assets/Audio/Exercises/\(snakeKey)/\(audioType)"
        }
        
        playAudioFile(fileName, completion: completion)
    }
    
    func stop() {
        audioPlayer?.stop()
        isPlaying = false
        isPaused = false
        completionHandler = nil
    }
    
    func pause() {
        if isPlaying && !isPaused {
            audioPlayer?.pause()
            isPaused = true
        }
    }
    
    func resume() {
        if isPaused {
            audioPlayer?.play()
            isPaused = false
        }
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        isPaused = false
        if let completion = completionHandler {
            completionHandler = nil
            DispatchQueue.main.async {
                completion()
            }
        }
    }
}

// Separate view for audio indicator to prevent title re-renders
struct AudioIndicator: View {
    let isPlaying: Bool
    @State private var animating = false
    
    var body: some View {
        Image(systemName: "dot.radiowaves.left.and.right")
            .foregroundColor(.blue)
            .opacity(isPlaying ? 1 : 0)
            .scaleEffect(animating ? 1.1 : 0.9)
            .animation(isPlaying ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true) : .default, value: animating)
            .onAppear {
                animating = true
            }
    }
}

// Separate view for instruction rows to prevent full re-renders
struct InstructionRow: View {
    let index: Int
    let instruction: String
    let isHighlighted: Bool
    
    var body: some View {
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
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isHighlighted ? Color.blue.opacity(0.1) : Color.clear)
                .animation(.easeInOut(duration: 0.2), value: isHighlighted)
        )
    }
}

struct ExerciseView: View {
    let exercise: Exercise
    @State private var timeRemaining: Int
    @State private var isCountingDown = false
    @State private var timerSubscription: AnyCancellable?
    @StateObject private var audioController = AudioController()
    @State private var currentInstructionIndex = 0
    @State private var hasFinishedReadingInstructions = false
    var onCompletion: (() -> Void)?
    var withCoaching: Bool = false
    var startImmediately: Bool = true
    
    init(exercise: Exercise, withCoaching: Bool = false, startImmediately: Bool = true, onCompletion: (() -> Void)? = nil) {
        self.exercise = exercise
        self.withCoaching = withCoaching
        self.startImmediately = startImmediately
        self._timeRemaining = State(initialValue: exercise.duration)
        self.onCompletion = onCompletion
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with name and timer - more compact
            VStack(spacing: 8) {
                ZStack {
                    // Static title that never changes
                    Text(exercise.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                    
                    // Audio indicator overlaid on the right
                    HStack {
                        Spacer()
                        if withCoaching {
                            AudioIndicator(isPlaying: audioController.isPlaying)
                        }
                    }
                }
                
                // Timer display with category info
                HStack(spacing: 20) {
                    Text(timeString)
                        .font(.system(size: 32, weight: .medium, design: .monospaced))
                        .foregroundColor(isCountingDown ? .blue : .primary)
                        .id("timer-\(timeRemaining)") // Force update only this text
                    
                    VStack(alignment: .leading, spacing: 2) {
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
            
            // All instructions visible at once - reduced spacing
            VStack(alignment: .leading, spacing: 8) {
                Text("Instructions")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(exercise.instructions.enumerated()), id: \.offset) { index, instruction in
                        InstructionRow(
                            index: index,
                            instruction: instruction,
                            isHighlighted: withCoaching && audioController.isPlaying && index == currentInstructionIndex
                        )
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer(minLength: 10)
            
            // Benefits section (compact)
            VStack(spacing: 4) {
                Text("Benefits")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(exercise.benefits)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .padding(.horizontal)
            
            // Control buttons
            HStack(spacing: 16) {
                Button(action: toggleTimer) {
                    Label(
                        isCountingDown ? "Pause" : (startImmediately ? "Resume" : "Start Exercise"),
                        systemImage: isCountingDown ? "pause.fill" : "play.fill"
                    )
                    .frame(width: 140)
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                
                if withCoaching {
                    Button(action: toggleAudio) {
                        Image(systemName: audioController.isPlaying ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 18))
                    }
                    .buttonStyle(.bordered)
                    .help(audioController.isPlaying ? "Stop coaching" : "Resume coaching")
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 16)
        .frame(width: 500, height: 520)
        .onDisappear {
            stopTimer()
            audioController.stop()
        }
        .onAppear {
            if withCoaching {
                // In coaching mode, read instructions first, then start timer
                startCoaching()
            } else if startImmediately {
                // Without coaching, start timer immediately
                startTimer()
            }
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
        // Play start sound
        NSSound.beep()
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
    
    // MARK: - Audio Methods
    
    private func startCoaching() {
        guard withCoaching && !exercise.instructions.isEmpty else { return }
        
        // Reset instruction index
        currentInstructionIndex = 0
        
        // Get exercise key from ID (e.g., "chin-tuck" -> "chin_tuck")
        let exerciseKey = exercise.id.replacingOccurrences(of: "-", with: "_")
        
        // Play intro audio
        audioController.playExerciseAudio(exerciseKey: exerciseKey, audioType: "intro") {
            // After intro, play the instructions
            self.playInstructions()
        }
    }
    
    private func playInstructions() {
        guard currentInstructionIndex < exercise.instructions.count else {
            // All instructions played - play complete message then start timer
            hasFinishedReadingInstructions = true
            
            let exerciseKey = exercise.id.replacingOccurrences(of: "-", with: "_")
            audioController.playExerciseAudio(exerciseKey: exerciseKey, audioType: "complete") {
                // Small delay before starting timer
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.startTimer()
                }
            }
            return
        }
        
        let exerciseKey = exercise.id.replacingOccurrences(of: "-", with: "_")
        
        // Play this instruction audio, then move to next
        audioController.playExerciseAudio(exerciseKey: exerciseKey, audioType: "step", stepNumber: currentInstructionIndex + 1) {
            // Move to next instruction
            self.currentInstructionIndex += 1
            // Immediately play next instruction (no artificial delay)
            self.playInstructions()
        }
    }
    
    private func toggleAudio() {
        if audioController.isPlaying {
            audioController.pause()
        } else {
            audioController.resume()
        }
    }
}

struct ExerciseSetView: View {
    let exerciseSet: ExerciseSet
    var onClose: (() -> Void)? = nil
    @State private var currentExerciseIndex = 0
    @State private var showingExercise = false
    @State private var autoAdvance = true
    @State private var withCoaching = false
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
                        
                        // Auto-advance toggle for quick reset or when not coaching
                        if !withCoaching && exerciseSet.id == "quick-reset" {
                            Toggle("Auto-advance", isOn: $autoAdvance)
                                .toggleStyle(.switch)
                                .scaleEffect(0.8)
                        } else if withCoaching {
                            Text("Auto-advance")
                                .font(.caption)
                                .foregroundColor(.secondary)
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
                        withCoaching: withCoaching,
                        startImmediately: true,
                        onCompletion: {
                            // Auto-advance when coaching or for quick reset
                            if withCoaching || (exerciseSet.id == "quick-reset" && autoAdvance) {
                                if currentExerciseIndex < exerciseSet.exercises.count - 1 {
                                    currentExerciseIndex += 1
                                } else {
                                    // All exercises completed
                                    dismiss()
                                }
                            }
                        }
                    )
                    .id("exercise-\(currentExerciseIndex)") // Force re-creation when index changes
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            if currentExerciseIndex > 0 {
                                currentExerciseIndex -= 1
                            } else {
                                // Go back to overview
                                showingExercise = false
                                withCoaching = false
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
                    HStack(spacing: 16) {
                        Button(action: {
                            withCoaching = false
                            showingExercise = true
                            currentExerciseIndex = 0
                        }, label: {
                            Label("Start Exercises", systemImage: "play.fill")
                                .frame(width: 140)
                        })
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        
                        Button(action: {
                            withCoaching = true
                            showingExercise = true
                            currentExerciseIndex = 0
                        }, label: {
                            Label("Start with Coaching", systemImage: "speaker.wave.2.fill")
                                .frame(width: 160)
                        })
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                    
                    Text("Coaching will read instructions aloud as you exercise")
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
