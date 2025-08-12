import AppKit
import SwiftUI

final class SimpleOnboardingWindowController: NSWindowController {
    private var hostingController: NSHostingController<SimpleOnboardingWindow>?
    
    convenience init(reminderManager: ReminderManager) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 520),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Welcome"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.center()
        window.level = .floating
        
        self.init(window: window)
        
        let onboardingView = SimpleOnboardingWindow(reminderManager: reminderManager)
        let hostingController = NSHostingController(rootView: onboardingView)
        self.hostingController = hostingController
        
        window.contentViewController = hostingController
    }
    
    func showOnboarding() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    static func shouldShowOnboarding() -> Bool {
        !UserDefaults.standard.bool(forKey: "TouchGrass.hasCompletedOnboarding")
    }
}
