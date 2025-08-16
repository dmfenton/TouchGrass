import SwiftUI
import AppKit

class ExerciseWindowController: NSObject {
    private var window: NSPanel?
    private var currentExerciseSet: ExerciseSet?
    
    func showExerciseWindow(with exerciseSet: ExerciseSet) {
        currentExerciseSet = exerciseSet
        
        if window == nil {
            window = WindowHelper.createFloatingPanel(
                title: "Touch Grass Exercises",
                size: NSSize(width: 520, height: 750),
                resizable: true
            )
        }
        
        // Update content and show
        if let panel = window {
            let exerciseView = ExerciseWindowView(
                exerciseSet: exerciseSet,
                onClose: { [weak self] in
                    self?.hideWindow()
                }
            )
            WindowHelper.setPanelContent(exerciseView, on: panel)
            WindowHelper.showWindow(panel)
        }
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
