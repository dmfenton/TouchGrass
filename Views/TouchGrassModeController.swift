import AppKit
import SwiftUI

final class TouchGrassModeController: NSObject {
    private var window: NSPanel?
    
    func show(manager: ReminderManager) {
        // Create window if needed
        if window == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 500, height: 600),
                styleMask: [.titled, .closable, .nonactivatingPanel, .resizable],
                backing: .buffered,
                defer: false
            )
            
            panel.title = "Touch Grass"
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.isMovableByWindowBackground = true
            panel.backgroundColor = NSColor.windowBackgroundColor
            panel.titlebarAppearsTransparent = false
            
            window = panel
        }
        
        // Set content
        let contentView = TouchGrassMode(reminderManager: manager)
        window?.contentView = NSHostingView(rootView: contentView)
        
        // Center on screen
        window?.center()
        
        // Show window
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        manager.isTouchGrassModeActive = true
    }
    
    func close() {
        window?.close()
        window = nil
    }
    
    func isWindowVisible() -> Bool {
        return window?.isVisible ?? false
    }
}