import AppKit
import SwiftUI

final class TouchGrassOnboardingController: NSWindowController {
    private var hostingController: NSHostingController<TouchGrassOnboarding>?
    
    convenience init(reminderManager: ReminderManager) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 780),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.title = ""
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.center()
        window.level = .floating
        window.backgroundColor = NSColor.windowBackgroundColor
        
        // Prevent window from being resizable
        window.styleMask.remove(.resizable)
        
        self.init(window: window)
        
        let onboardingView = TouchGrassOnboarding(reminderManager: reminderManager)
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
