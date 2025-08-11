import SwiftUI
import AppKit

class ExerciseWindowController: NSObject {
    private var window: NSPanel?
    private var currentExerciseSet: ExerciseSet?
    
    func showExerciseWindow(with exerciseSet: ExerciseSet) {
        currentExerciseSet = exerciseSet
        
        if window == nil {
            createWindow()
        }
        
        updateWindowContent(exerciseSet)
        window?.makeKeyAndOrderFront(nil)
        window?.center()
    }
    
    func showLastExercise() {
        guard let exerciseSet = currentExerciseSet else {
            // Show default exercise if none selected yet
            showExerciseWindow(with: ExerciseData.oneMinuteBreak)
            return
        }
        showExerciseWindow(with: exerciseSet)
    }
    
    func hideWindow() {
        window?.orderOut(nil)
    }
    
    func isWindowVisible() -> Bool {
        return window?.isVisible ?? false
    }
    
    private func createWindow() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 700),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.title = "PosturePal Exercises"
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = false
        
        self.window = panel
    }
    
    private func updateWindowContent(_ exerciseSet: ExerciseSet) {
        guard let window = window else { return }
        
        let exerciseView = ExerciseWindowView(
            exerciseSet: exerciseSet,
            onClose: { [weak self] in
                self?.hideWindow()
            }
        )
        
        window.contentView = NSHostingView(rootView: exerciseView)
    }
}

// Wrapper view for exercise window
struct ExerciseWindowView: View {
    let exerciseSet: ExerciseSet
    let onClose: () -> Void
    @State private var selectedExercise: Exercise?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Guided Exercises")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            if let exercise = selectedExercise {
                // Show individual exercise with full controls
                VStack(spacing: 0) {
                    HStack {
                        Button(action: {
                            selectedExercise = nil
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Back to exercises")
                            }
                            .foregroundColor(.secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding()
                        
                        Spacer()
                    }
                    
                    ExerciseView(exercise: exercise)
                        .padding(.top, -20) // Adjust spacing since ExerciseView has its own padding
                }
            } else {
                // Show exercise list
                ScrollView {
                    VStack(spacing: 16) {
                        // Quick exercise sets
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Exercise Sets")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(ExerciseData.allExerciseSets) { set in
                                Button(action: {
                                    if set.exercises.count == 1 {
                                        selectedExercise = set.exercises.first
                                    } else {
                                        // For multi-exercise sets, show the first one
                                        // You could enhance this to show a set view
                                        selectedExercise = set.exercises.first
                                    }
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(set.name)
                                                .font(.body)
                                                .fontWeight(.medium)
                                            Text(set.description)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Label("\(set.duration / 60):\(String(format: "%02d", set.duration % 60))", 
                                              systemImage: "clock")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color(NSColor.controlBackgroundColor))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal)
                            }
                        }
                        
                        Divider()
                            .padding(.vertical)
                        
                        // Individual exercises
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Individual Exercises")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(ExerciseData.coreExercises) { exercise in
                                Button(action: {
                                    selectedExercise = exercise
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(exercise.name)
                                                .font(.body)
                                                .fontWeight(.medium)
                                            Text(exercise.targetArea)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Label(exercise.category.rawValue, 
                                              systemImage: categoryIcon(for: exercise.category))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color(NSColor.controlBackgroundColor))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .frame(width: 520, height: 700)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private func categoryIcon(for category: Exercise.ExerciseCategory) -> String {
        switch category {
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
}