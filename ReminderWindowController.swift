import SwiftUI
import AppKit

final class ReminderWindowController {
    private var panel: NSPanel?
    private var visualEffectView: NSVisualEffectView?

    func show(message: String,
              onOK: @escaping () -> Void,
              onSnooze10: @escaping () -> Void,
              onSnooze20: @escaping () -> Void,
              onSkip: @escaping () -> Void) {
        dismiss()

        let content = ReminderView(
            message: message,
            ok: { [weak self] in 
                self?.animateDismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self?.dismiss()
                    onOK()
                }
            },
            snooze10: { [weak self] in
                self?.animateDismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self?.dismiss()
                    onSnooze10()
                }
            },
            snooze20: { [weak self] in
                self?.animateDismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self?.dismiss()
                    onSnooze20()
                }
            },
            skip: { [weak self] in
                self?.animateDismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self?.dismiss()
                    onSkip()
                }
            }
        )

        let hosting = NSHostingController(rootView: content)
        let styleMask: NSWindow.StyleMask = [.borderless, .nonactivatingPanel]

        let panel = NSPanel(contentViewController: hosting)
        panel.styleMask = styleMask
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.isMovable = true
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.animationBehavior = .utilityWindow
        
        // Center the window on screen for better visibility
        panel.center()
        
        self.panel = panel
        
        // Make sure it's visible
        panel.alphaValue = 1.0
        panel.makeKeyAndOrderFront(nil)
        
        // Activate the app to bring window to front
        NSApp.activate(ignoringOtherApps: true)
        
        // Play subtle sound
        NSSound.beep()
    }
    
    private func animateDismiss() {
        guard let panel = panel else { return }
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0.0
        })
    }

    func dismiss() {
        panel?.orderOut(nil)
        panel = nil
        visualEffectView = nil
    }
}