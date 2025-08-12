import AppKit
import SwiftUI

final class OnboardingWindowController: NSWindowController {
    private var hostingController: NSHostingController<OnboardingWindow>?
    
    convenience init(reminderManager: ReminderManager) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Welcome to Touch Grass"
        window.titlebarAppearsTransparent = false
        window.isMovableByWindowBackground = true
        window.center()
        window.level = .floating
        
        self.init(window: window)
        
        let onboardingView = OnboardingWindow(reminderManager: reminderManager)
        let hostingController = NSHostingController(rootView: onboardingView)
        self.hostingController = hostingController
        
        window.contentViewController = hostingController
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func showOnboarding() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}