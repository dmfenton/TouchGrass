import SwiftUI
import AppKit

struct GrassIcon: View {
    let isActive: Bool
    let size: CGFloat
    
    init(isActive: Bool = false, size: CGFloat = 16) {
        self.isActive = isActive
        self.size = size
    }
    
    var nsImage: NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        // Draw using NSBezierPath
        let grassColor = isActive ? NSColor.systemGreen : NSColor.labelColor
        grassColor.setStroke()
        
        let strokeWidth: CGFloat = 1.2  // Thin outline
        
        // 4 outlined blades with pointed tops at different heights
        let blades: [(x: CGFloat, width: CGFloat, height: CGFloat)] = [
            (size * 0.2, size * 0.13, size * 0.45),   // Far left - medium-short
            (size * 0.4, size * 0.13, size * 0.65),   // Left - tall
            (size * 0.6, size * 0.13, size * 0.55),   // Right - medium
            (size * 0.8, size * 0.13, size * 0.4)     // Far right - short
        ]
        
        let bottomY = size * 0.15
        
        for blade in blades {
            let path = NSBezierPath()
            path.lineWidth = strokeWidth
            
            // Create outlined rectangle with pointed top
            // Start at bottom left
            path.move(to: NSPoint(x: blade.x - blade.width / 2, y: bottomY))
            // Go up the left side (to about 70% of height)
            path.line(to: NSPoint(x: blade.x - blade.width / 2, y: bottomY + blade.height * 0.7))
            // Go to the pointed top
            path.line(to: NSPoint(x: blade.x, y: bottomY + blade.height))
            // Go down to the right side (at 70% height)
            path.line(to: NSPoint(x: blade.x + blade.width / 2, y: bottomY + blade.height * 0.7))
            // Go down the right side to bottom
            path.line(to: NSPoint(x: blade.x + blade.width / 2, y: bottomY))
            // Close back to start
            path.close()
            
            // Stroke only - leaves interior empty
            path.stroke()
        }
        
        // No ground line - keep it clean and simple
        
        image.unlockFocus()
        image.isTemplate = !isActive // Template for automatic color adaptation when not active
        return image
    }
    
    var body: some View {
        Image(nsImage: nsImage)
            .frame(width: size, height: size)
    }
}

// Keep the Canvas version for preview
struct GrassIconCanvas: View {
    let isActive: Bool
    let size: CGFloat
    
    var body: some View {
        Canvas { context, _ in
            let grassColor = isActive ? Color.green : Color(NSColor.labelColor)
            
            // Essential grass - upright blades with varied heights
            let baseY = size * 0.95
            let bladeWidth = size / 5  // Much wider base for visibility
            
            // More upright blades with significant height variation
            let blades: [(baseX: CGFloat, tipX: CGFloat, height: CGFloat)] = [
                // Left outer - short
                (size * 0.25, size * 0.23, size * 0.45),
                // Left inner - tall
                (size * 0.38, size * 0.37, size * 0.75),
                // Center - tallest
                (size * 0.5, size * 0.5, size * 0.85),
                // Right inner - medium
                (size * 0.62, size * 0.63, size * 0.65),
                // Right outer - short
                (size * 0.75, size * 0.77, size * 0.5)
            ]
            
            for blade in blades {
                var path = Path()
                
                // Create triangular blade shape
                // Base left point
                path.move(to: CGPoint(x: blade.baseX - bladeWidth / 2, y: baseY))
                // Base right point
                path.addLine(to: CGPoint(x: blade.baseX + bladeWidth / 2, y: baseY))
                // Top point (sharp tip)
                path.addLine(to: CGPoint(x: blade.tipX, y: baseY - blade.height))
                // Close the path
                path.closeSubpath()
                
                // Fill the triangular blade
                context.fill(
                    path,
                    with: .color(grassColor)
                )
            }
            
            // Optional: subtle ground line
            var groundPath = Path()
            groundPath.move(to: CGPoint(x: size * 0.1, y: baseY))
            groundPath.addLine(to: CGPoint(x: size * 0.9, y: baseY))
            
            context.stroke(
                groundPath,
                with: .color(grassColor.opacity(0.3)),
                lineWidth: size / 32
            )
        }
        .frame(width: size, height: size)
    }
}

// Preview for development
struct GrassIcon_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 20) {
            GrassIcon(isActive: false, size: 20)
            GrassIcon(isActive: true, size: 20)
        }
        .padding()
    }
}
