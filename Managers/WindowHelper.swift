import AppKit
import SwiftUI

/// Utility class to reduce window configuration boilerplate
final class WindowHelper {
    
    /// Create a standard floating window
    static func createFloatingWindow(
        title: String,
        size: NSSize,
        transparentTitlebar: Bool = false
    ) -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.title = title
        window.titlebarAppearsTransparent = transparentTitlebar
        window.titleVisibility = transparentTitlebar ? .hidden : .visible
        window.isMovableByWindowBackground = true
        window.center()
        window.level = .floating
        window.backgroundColor = NSColor.windowBackgroundColor
        window.styleMask.remove(.resizable)
        
        return window
    }
    
    /// Create a floating panel that joins all spaces
    static func createFloatingPanel(
        title: String,
        size: NSSize,
        resizable: Bool = true
    ) -> NSPanel {
        var styleMask: NSWindow.StyleMask = [.titled, .closable, .nonactivatingPanel]
        if resizable {
            styleMask.insert(.resizable)
        }
        
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        
        panel.title = title
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = NSColor.windowBackgroundColor
        panel.titlebarAppearsTransparent = false
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = false
        
        return panel
    }
    
    /// Show a window with activation
    static func showWindow(_ window: NSWindow) {
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    /// Set SwiftUI content on a window
    static func setContent<Content: View>(_ content: Content, on window: NSWindow) {
        let hostingController = NSHostingController(rootView: content)
        window.contentViewController = hostingController
    }
    
    /// Set SwiftUI content on a panel
    static func setPanelContent<Content: View>(_ content: Content, on panel: NSPanel) {
        panel.contentView = NSHostingView(rootView: content)
    }
}
