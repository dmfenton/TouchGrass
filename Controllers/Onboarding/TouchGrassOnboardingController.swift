import AppKit
import SwiftUI

final class TouchGrassOnboardingController: NSWindowController {
    private var hostingController: NSHostingController<TouchGrassOnboarding>?
    
    convenience init(reminderManager: ReminderManager) {
        let window = WindowHelper.createFloatingWindow(
            title: "",
            size: NSSize(width: 520, height: 600),
            transparentTitlebar: true
        )
        
        self.init(window: window)
        
        let onboardingView = TouchGrassOnboarding(reminderManager: reminderManager)
        WindowHelper.setContent(onboardingView, on: window)
    }
    
    func showOnboarding() {
        if let window = window {
            WindowHelper.showWindow(window)
        }
    }
    
    static func shouldShowOnboarding() -> Bool {
        !UserDefaults.standard.bool(forKey: "TouchGrass.hasCompletedOnboarding")
    }
}
