import AppKit
import SwiftUI

final class CustomizationWindowController: NSWindowController {
    private var hostingController: NSHostingController<CustomizationView>?
    
    convenience init(reminderManager: ReminderManager, onComplete: @escaping () -> Void) {
        let window = WindowHelper.createFloatingWindow(
            title: "Customize Touch Grass",
            size: NSSize(width: 480, height: 720),
            transparentTitlebar: false
        )
        
        self.init(window: window)
        
        let customizationView = CustomizationView(
            reminderManager: reminderManager,
            onComplete: { [weak self] in
                onComplete()
                self?.close()
            }
        )
        
        WindowHelper.setContent(customizationView, on: window)
    }
    
    func showCustomization() {
        if let window = window {
            WindowHelper.showWindow(window)
        }
    }
}
