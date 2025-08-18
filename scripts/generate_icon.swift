#!/usr/bin/env swift

import AppKit

// Create grass icon as NSImage
func createGrassIcon(size: CGFloat, isActive: Bool = false) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    
    // Background - rounded rect with subtle gradient
    let bgRect = NSRect(x: 0, y: 0, width: size, height: size)
    let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: size * 0.2, yRadius: size * 0.2)
    
    // White background
    NSColor.white.setFill()
    bgPath.fill()
    
    // Green gradient background
    let gradient = NSGradient(colors: [
        NSColor(red: 0.85, green: 0.95, blue: 0.85, alpha: 1.0),
        NSColor(red: 0.75, green: 0.90, blue: 0.75, alpha: 1.0)
    ])!
    gradient.draw(in: bgPath, angle: -90)
    
    // Draw grass blades
    let grassColor = NSColor(red: 0.2, green: 0.6, blue: 0.2, alpha: 1.0)
    grassColor.setFill()
    
    // Scale factors for icon
    let scale = size / 16.0  // Original icon was 16x16
    
    // 4 filled blades with pointed tops at different heights
    let blades: [(x: CGFloat, width: CGFloat, height: CGFloat)] = [
        (size * 0.2, size * 0.13, size * 0.45),   // Far left - medium-short
        (size * 0.4, size * 0.13, size * 0.65),   // Left - tall
        (size * 0.6, size * 0.13, size * 0.55),   // Right - medium
        (size * 0.8, size * 0.13, size * 0.4)     // Far right - short
    ]
    
    let bottomY = size * 0.15
    
    for blade in blades {
        let path = NSBezierPath()
        
        // Create filled blade with pointed top
        path.move(to: NSPoint(x: blade.x - blade.width / 2, y: bottomY))
        path.line(to: NSPoint(x: blade.x - blade.width / 2, y: bottomY + blade.height * 0.7))
        path.line(to: NSPoint(x: blade.x, y: bottomY + blade.height))
        path.line(to: NSPoint(x: blade.x + blade.width / 2, y: bottomY + blade.height * 0.7))
        path.line(to: NSPoint(x: blade.x + blade.width / 2, y: bottomY))
        path.close()
        
        // Fill with grass color
        path.fill()
    }
    
    image.unlockFocus()
    return image
}

// Create icon at different sizes
let sizes = [16, 32, 64, 128, 256, 512, 1024]

// Create iconset directory
let iconsetPath = "TouchGrass.iconset"
try? FileManager.default.removeItem(atPath: iconsetPath)
try! FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

for size in sizes {
    // Regular resolution
    let icon = createGrassIcon(size: CGFloat(size))
    let imageRep = NSBitmapImageRep(data: icon.tiffRepresentation!)!
    imageRep.size = NSSize(width: size, height: size)
    let pngData = imageRep.representation(using: .png, properties: [:])!
    let filename = "icon_\(size)x\(size).png"
    try! pngData.write(to: URL(fileURLWithPath: "\(iconsetPath)/\(filename)"))
    
    // Retina resolution (except for 512 and 1024)
    if size <= 256 {
        let retinaIcon = createGrassIcon(size: CGFloat(size * 2))
        let retinaImageRep = NSBitmapImageRep(data: retinaIcon.tiffRepresentation!)!
        retinaImageRep.size = NSSize(width: size * 2, height: size * 2)
        let retinaPngData = retinaImageRep.representation(using: .png, properties: [:])!
        let retinaFilename = "icon_\(size)x\(size)@2x.png"
        try! retinaPngData.write(to: URL(fileURLWithPath: "\(iconsetPath)/\(retinaFilename)"))
    }
}

print("Icon PNG files created in \(iconsetPath)")
print("Now run: iconutil -c icns TouchGrass.iconset")
