import AppKit
import SwiftUI

final class CustomizationWindowController: NSWindowController {
    private var hostingController: NSHostingController<CustomizationView>?
    
    convenience init(reminderManager: ReminderManager, onComplete: @escaping () -> Void) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 580),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Customize Touch Grass"
        window.titlebarAppearsTransparent = false
        window.isMovableByWindowBackground = true
        window.center()
        window.level = .floating
        window.backgroundColor = NSColor.windowBackgroundColor
        
        // Prevent window from being resizable
        window.styleMask.remove(.resizable)
        
        self.init(window: window)
        
        let customizationView = CustomizationView(
            reminderManager: reminderManager,
            onComplete: { [weak self] in
                onComplete()
                self?.close()
            }
        )
        let hostingController = NSHostingController(rootView: customizationView)
        self.hostingController = hostingController
        
        window.contentViewController = hostingController
    }
    
    func showCustomization() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}