import SwiftUI

struct ReminderView: View {
    let message: String
    let ok: () -> Void
    let snooze10: () -> Void
    let snooze20: () -> Void
    let skip: () -> Void
    
    @State private var hoveredButton: String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "figure.walk")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                Text("Posture Check")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                Spacer()
                Button(action: skip) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Content
            VStack(alignment: .leading, spacing: 16) {
                // Message steps
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(message.components(separatedBy: "\n").filter { !$0.isEmpty }, id: \.self) { line in
                        if line.contains("✨") {
                            // Extra tip
                            VStack(alignment: .leading, spacing: 8) {
                                Divider()
                                HStack(alignment: .top, spacing: 10) {
                                    Text("💡")
                                        .font(.system(size: 14))
                                    Text(line.replacingOccurrences(of: "✨ Extra: ", with: ""))
                                        .font(.system(size: 14, weight: .regular, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
                            }
                        } else {
                            // Regular step
                            HStack(alignment: .top, spacing: 10) {
                                Text(String(line.prefix(2)))
                                    .font(.system(size: 16))
                                    .frame(width: 24)
                                Text(line.dropFirst(2).trimmingCharacters(in: .whitespaces))
                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Buttons
                VStack(spacing: 10) {
                    // Primary action
                    Button(action: ok) {
                        HStack {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .medium))
                            Text("Done")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.accentColor)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .keyboardShortcut(.defaultAction)
                    
                    // Secondary actions
                    HStack(spacing: 8) {
                        Button(action: snooze10) {
                            Text("Snooze 10m")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(hoveredButton == "snooze10" ? .primary : .secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(hoveredButton == "snooze10" ? Color.secondary.opacity(0.08) : Color.clear)
                                        )
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .onHover { isHovered in
                            hoveredButton = isHovered ? "snooze10" : nil
                        }
                        
                        Button(action: snooze20) {
                            Text("Snooze 20m")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(hoveredButton == "snooze20" ? .primary : .secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(hoveredButton == "snooze20" ? Color.secondary.opacity(0.08) : Color.clear)
                                        )
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .onHover { isHovered in
                            hoveredButton = isHovered ? "snooze20" : nil
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 380)
        .background(Color(NSColor.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
}