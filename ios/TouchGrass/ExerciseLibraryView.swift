import AVFoundation
import FentonDesignSystem
import SwiftUI

struct ExerciseLibraryView: View {
    var body: some View {
        NavigationStack {
            List(ExerciseData.allExerciseSets) { routine in
                NavigationLink {
                    RoutineView(routine: routine)
                } label: {
                    VStack(alignment: .leading, spacing: FentonSpacing.small) {
                        Text(routine.name).font(.headline)
                        Text(routine.description).font(.subheadline).foregroundStyle(.secondary)
                        FentonTag("\(routine.duration) seconds")
                    }.padding(.vertical, FentonSpacing.small)
                }
            }.navigationTitle("A little movement")
        }
    }
}

@MainActor
final class ExerciseCoach: ObservableObject {
    private let speech = AVSpeechSynthesizer()
    func speak(_ text: String) {
        speech.stopSpeaking(at: .immediate)
        speech.speak(AVSpeechUtterance(string: text))
    }
    func stop() { speech.stopSpeaking(at: .immediate) }
}

struct RoutineView: View {
    let routine: ExerciseSet
    @EnvironmentObject private var store: WellnessStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var coach = ExerciseCoach()
    @State private var started: Date?
    @State private var exerciseIndex = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FentonSpacing.large) {
                Text(routine.description).font(.title3)
                if let started { Text(started, style: .timer).font(.largeTitle.monospacedDigit()) }
                if started == nil {
                    Button("Start routine") { started = Date() }.buttonStyle(.borderedProminent)
                } else {
                    Text("Exercise \(exerciseIndex + 1) of \(routine.exercises.count)").font(.headline)
                }
                ForEach(started == nil ? routine.exercises : Array(routine.exercises.dropFirst(exerciseIndex).prefix(1))) { exercise in
                    FentonCard {
                        VStack(alignment: .leading, spacing: FentonSpacing.medium) {
                            Text(exercise.name).font(.headline)
                            Text("\(exercise.duration) seconds").foregroundStyle(.secondary)
                            ForEach(Array(exercise.instructions.enumerated()), id: \.offset) { index, instruction in
                                Text("\(index + 1). \(instruction)")
                            }
                            Button("Read instructions", systemImage: "speaker.wave.2") {
                                coach.speak(exercise.instructions.joined(separator: ". "))
                            }
                        }
                    }
                }
                if started != nil {
                    if exerciseIndex + 1 < routine.exercises.count {
                        Button("Next exercise") {
                            coach.stop()
                            exerciseIndex += 1
                            started = Date()
                        }.buttonStyle(.borderedProminent)
                    }
                    Button("Complete break") {
                        store.record(breaks: 1)
                        dismiss()
                    }.buttonStyle(.borderedProminent)
                }
            }.padding(FentonSpacing.large)
        }.navigationTitle(routine.name)
            .onDisappear { coach.stop() }
    }
}
