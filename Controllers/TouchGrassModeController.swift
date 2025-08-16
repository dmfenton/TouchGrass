import AppKit
import SwiftUI

final class TouchGrassModeController: NSObject {
    private var window: NSPanel?
    
    func show(manager: ReminderManager) {
        // Create window if needed
        if window == nil {
            window = WindowHelper.createFloatingPanel(
                title: "Touch Grass",
                size: NSSize(width: 500, height: 600),
                resizable: true
            )
        }
        
        // Set content and show
        if let panel = window {
            WindowHelper.setPanelContent(
                TouchGrassMode(reminderManager: manager),
                on: panel
            )
            WindowHelper.showWindow(panel)
        }
        
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
