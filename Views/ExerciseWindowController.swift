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
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 750),
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

// Wrapper view for exercise window - uses ExerciseSetView which has overview
struct ExerciseWindowView: View {
    let exerciseSet: ExerciseSet
    let onClose: () -> Void
    
    init(exerciseSet: ExerciseSet, onClose: @escaping () -> Void) {
        self.exerciseSet = exerciseSet
        self.onClose = onClose
    }
    
    var body: some View {
        // Use ExerciseSetView directly with close button integrated
        ExerciseSetView(exerciseSet: exerciseSet, onClose: onClose)
    }
}