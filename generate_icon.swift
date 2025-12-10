import Cocoa

let size = CGSize(width: 1024, height: 1024)
let image = NSImage(size: size)

image.lockFocus()

// 1. Background (Dark Gradient)
let context = NSGraphicsContext.current!.cgContext
let colors = [
    NSColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1.0).cgColor,
    NSColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0).cgColor
] as CFArray
let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0.0, 1.0])!
context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 1024), end: CGPoint(x: 0, y: 0), options: [])

// 2. Circle (Focus Ring)
let circlePath = NSBezierPath(ovalIn: NSRect(x: 112, y: 112, width: 800, height: 800))
NSColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0).setStroke() // Blue
circlePath.lineWidth = 60
circlePath.stroke()

// 3. Inner Circle (Progress/Activity)
let innerPath = NSBezierPath(ovalIn: NSRect(x: 250, y: 250, width: 524, height: 524))
NSColor(red: 0.6, green: 0.3, blue: 0.8, alpha: 1.0).setFill() // Purple
innerPath.fill()

// 4. Checkmark or Symbol
let symbolPath = NSBezierPath()
symbolPath.move(to: CGPoint(x: 360, y: 512))
symbolPath.line(to: CGPoint(x: 480, y: 380))
symbolPath.line(to: CGPoint(x: 700, y: 650))
NSColor.white.setStroke()
symbolPath.lineWidth = 50
symbolPath.lineCapStyle = .round
symbolPath.lineJoinStyle = .round
symbolPath.stroke()

image.unlockFocus()

// Save to PNG
if let tiffData = image.tiffRepresentation,
   let bitmap = NSBitmapImageRep(data: tiffData),
   let pngData = bitmap.representation(using: .png, properties: [:]) {
    try pngData.write(to: URL(fileURLWithPath: "icon.png"))
    print("Icon generated successfully: icon.png")
}
