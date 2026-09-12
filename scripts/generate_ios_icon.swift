import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let size = 1024
let context = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size * 4,
    space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
)!
context.setFillColor(CGColor(red: 0.94, green: 0.95, blue: 0.87, alpha: 1))
context.fill(CGRect(x: 0, y: 0, width: size, height: size))
context.setFillColor(CGColor(red: 0.24, green: 0.36, blue: 0.28, alpha: 1))
for (x, height) in [(260.0, 360.0), (425.0, 560.0), (590.0, 455.0), (755.0, 320.0)] {
    context.move(to: CGPoint(x: x - 45, y: 240))
    context.addCurve(to: CGPoint(x: x - 40, y: 240 + height),
                     control1: CGPoint(x: x - 80, y: 300 + height * 0.5),
                     control2: CGPoint(x: x - 100, y: 240 + height * 0.8))
    context.addCurve(to: CGPoint(x: x + 45, y: 240),
                     control1: CGPoint(x: x + 65, y: 200 + height * 0.7),
                     control2: CGPoint(x: x + 45, y: 200 + height * 0.3))
    context.closePath()
    context.fillPath()
}
let output = URL(fileURLWithPath: "ios/TouchGrass/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
let destination = CGImageDestinationCreateWithURL(output as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(destination, context.makeImage()!, nil)
guard CGImageDestinationFinalize(destination) else { fatalError("Could not write app icon") }
