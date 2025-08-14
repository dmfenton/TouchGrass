import SwiftUI
import AppKit

class ExerciseSelectionController: NSWindowController {
    init(reminderManager: ReminderManager) {
        let hostingController = NSHostingController(
            rootView: ExerciseSelectionView(reminderManager: reminderManager)
        )
        
        let window = NSPanel(
            contentViewController: hostingController
        )
        
        window.title = "Select Exercise Routine"
        window.styleMask = [.titled, .closable]
        window.level = .floating
        window.isReleasedWhenClosed = false
        window.center()
        
        super.init(window: window)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showSelection() {
        window?.makeKeyAndOrderFront(nil)
    }
}