import SwiftUI

struct UpdateProgressView: View {
    @ObservedObject var updateManager = UpdateManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text("Downloading Update")
                        .font(.headline)
                    Text("Touch Grass \(updateManager.latestVersion ?? "")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Progress bar
            VStack(alignment: .leading, spacing: 8) {
                ProgressView(value: updateManager.downloadProgress)
                    .progressViewStyle(.linear)
                
                HStack {
                    Text("\(Int(updateManager.downloadProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if updateManager.downloadProgress > 0 {
                        Text("\(formatBytes(updateManager.downloadProgress * 10_000_000))") // Approximate
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Cancel button
            HStack {
                Spacer()
                
                Button("Cancel") {
                    updateManager.cancelDownload()
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(20)
        .frame(width: 400, height: 180)
    }
    
    private func formatBytes(_ bytes: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// Window controller for the update progress
class UpdateProgressWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 180),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Updating Touch Grass"
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .floating
        
        self.init(window: window)
        
        let contentView = UpdateProgressView()
        window.contentView = NSHostingView(rootView: contentView)
    }
    
    func show() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
