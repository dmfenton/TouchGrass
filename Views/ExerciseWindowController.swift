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
        
        // For quick reset and other specific sets, ensure we start directly
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
        window?.isVisible ?? false
    }
    
    private func createWindow() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 700),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.title = "Touch Grass Exercises"
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

// Wrapper view for exercise window - now always shows the exercise set directly
struct ExerciseWindowView: View {
    let exerciseSet: ExerciseSet
    let onClose: () -> Void
    @State private var currentExerciseIndex: Int = 0
    
    init(exerciseSet: ExerciseSet, onClose: @escaping () -> Void) {
        self.exerciseSet = exerciseSet
        self.onClose = onClose
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(exerciseSet.name)
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
            
            // Always show the exercise set directly - no selection menu
            VStack(spacing: 0) {
                // Show progress if multiple exercises
                if exerciseSet.exercises.count > 1 {
                    HStack {
                        Text("Exercise \(currentExerciseIndex + 1) of \(exerciseSet.exercises.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Next button to move through exercises
                        if currentExerciseIndex < exerciseSet.exercises.count - 1 {
                            Button(action: {
                                currentExerciseIndex = min(currentExerciseIndex + 1, exerciseSet.exercises.count - 1)
                            }) {
                                HStack(spacing: 4) {
                                    Text("Next")
                                    Image(systemName: "chevron.right")
                                }
                                .foregroundColor(.blue)
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            Button(action: onClose) {
                                Text("Complete")
                                    .foregroundColor(.green)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
                
                // Show current exercise
                if currentExerciseIndex < exerciseSet.exercises.count {
                    ExerciseView(exercise: exerciseSet.exercises[currentExerciseIndex])
                        .padding(.top, exerciseSet.exercises.count == 1 ? 0 : -20)
                }
            }
        }
    }
}