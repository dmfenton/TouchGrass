import SwiftUI
import AppKit

// Standalone preview app to show the grass icons
// @main  // Commented out - main app is TouchGrassApp
struct GrassIconPreviewApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(width: 400, height: 300)
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 30) {
            Text("Grass Icon Preview")
                .font(.title2)
                .fontWeight(.semibold)
            
            HStack(spacing: 50) {
                VStack(spacing: 15) {
                    Text("Normal State")
                        .font(.headline)
                    Text("(Default color)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Show in different sizes
                    HStack(spacing: 20) {
                        VStack {
                            GrassIcon(isActive: false, size: 16)
                            Text("16pt").font(.caption2)
                        }
                        VStack {
                            GrassIcon(isActive: false, size: 20)
                            Text("20pt").font(.caption2)
                        }
                        VStack {
                            GrassIcon(isActive: false, size: 32)
                            Text("32pt").font(.caption2)
                        }
                    }
                }
                
                Divider()
                    .frame(height: 100)
                
                VStack(spacing: 15) {
                    Text("Active State")
                        .font(.headline)
                    Text("(Green - Time to touch grass!)")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    // Show in different sizes
                    HStack(spacing: 20) {
                        VStack {
                            GrassIcon(isActive: true, size: 16)
                            Text("16pt").font(.caption2)
                        }
                        VStack {
                            GrassIcon(isActive: true, size: 20)
                            Text("20pt").font(.caption2)
                        }
                        VStack {
                            GrassIcon(isActive: true, size: 32)
                            Text("32pt").font(.caption2)
                        }
                    }
                }
            }
            
            Divider()
            
            // Simulated menu bar appearance
            VStack(spacing: 10) {
                Text("Menu Bar Simulation")
                    .font(.headline)
                
                HStack(spacing: 30) {
                    HStack(spacing: 4) {
                        GrassIcon(isActive: false, size: 16)
                        Text("45:00")
                            .font(.system(size: 12, design: .monospaced))
                    }
                    .padding(4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
                    
                    HStack(spacing: 4) {
                        GrassIcon(isActive: true, size: 16)
                        Text("!")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.green)
                    }
                    .padding(4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(4)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Include the GrassIcon view
struct GrassIcon: View {
    let isActive: Bool
    let size: CGFloat
    
    init(isActive: Bool = false, size: CGFloat = 16) {
        self.isActive = isActive
        self.size = size
    }
    
    var body: some View {
        Canvas { context, _ in
            let grassColor = isActive ? Color.green : Color(NSColor.labelColor)
            
            // Draw grass blades
            let bladeWidth = size / 8
            let baseY = size * 0.9
            
            // Blade positions and heights
            let blades: [(x: CGFloat, height: CGFloat, curve: CGFloat)] = [
                (size * 0.2, size * 0.6, -0.1),
                (size * 0.35, size * 0.75, 0.15),
                (size * 0.5, size * 0.65, -0.12),
                (size * 0.65, size * 0.7, 0.1),
                (size * 0.8, size * 0.55, -0.08)
            ]
            
            for blade in blades {
                var path = Path()
                
                // Start at base
                let startX = blade.x
                let startY = baseY
                path.move(to: CGPoint(x: startX, y: startY))
                
                // Create curved blade using quadratic curve
                let controlX = startX + (blade.curve * size)
                let controlY = baseY - (blade.height * 0.5)
                let endX = startX + (blade.curve * size * 0.5)
                let endY = baseY - blade.height
                
                path.addQuadCurve(
                    to: CGPoint(x: endX, y: endY),
                    control: CGPoint(x: controlX, y: controlY)
                )
                
                // Draw the blade
                context.stroke(
                    path,
                    with: .color(grassColor),
                    lineWidth: bladeWidth * 0.8
                )
            }
            
            // Draw ground line
            var groundPath = Path()
            groundPath.move(to: CGPoint(x: size * 0.1, y: baseY))
            groundPath.addLine(to: CGPoint(x: size * 0.9, y: baseY))
            
            context.stroke(
                groundPath,
                with: .color(grassColor.opacity(0.6)),
                lineWidth: 1
            )
        }
        .frame(width: size, height: size)
    }
}
