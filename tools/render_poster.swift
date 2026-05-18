import Cocoa

// Renders a Facebook-ready poster image.
// Usage:
//   swift tools/render_poster.swift landscape <out.png>   # 1200x630 (FB share / OG)
//   swift tools/render_poster.swift square <out.png>       # 1080x1080 (FB / IG square)

guard CommandLine.arguments.count == 3 else {
    print("usage: render_poster.swift <landscape|square> <output.png>")
    exit(1)
}
let mode = CommandLine.arguments[1]
let outPath = CommandLine.arguments[2]

let (width, height): (CGFloat, CGFloat) = (mode == "square") ? (1080, 1080) : (1200, 630)

let canvas = NSImage(size: NSSize(width: width, height: height))
canvas.lockFocus()

// ----- 1. Background: dark gradient -----
let bg = NSGradient(colorsAndLocations:
    (NSColor(calibratedRed: 0.06, green: 0.09, blue: 0.11, alpha: 1.0), 0.0),
    (NSColor(calibratedRed: 0.02, green: 0.04, blue: 0.05, alpha: 1.0), 1.0))
bg?.draw(in: NSRect(x: 0, y: 0, width: width, height: height), angle: -55)

// ----- 2. Soft green glow behind logo -----
let glowCenter: NSPoint
let glowRadius: CGFloat
if mode == "square" {
    glowCenter = NSPoint(x: width / 2, y: height * 0.62)
    glowRadius = 400
} else {
    glowCenter = NSPoint(x: 280, y: 320)
    glowRadius = 320
}
if let glow = NSGradient(colorsAndLocations:
    (NSColor(calibratedRed: 0.35, green: 0.78, blue: 0.55, alpha: 0.30), 0.0),
    (NSColor(calibratedRed: 0.35, green: 0.78, blue: 0.55, alpha: 0.00), 1.0)) {
    glow.draw(fromCenter: glowCenter, radius: 0,
              toCenter: glowCenter, radius: glowRadius, options: [])
}

// ----- 3. Logo -----
let scriptDir = (CommandLine.arguments[0] as NSString).deletingLastPathComponent
let repoRoot = (scriptDir as NSString).deletingLastPathComponent
let logoPath = "\(repoRoot)/docs/images/logo-1024.png"
let cwd = FileManager.default.currentDirectoryPath
let logoCandidates = [logoPath, "\(cwd)/docs/images/logo-1024.png", "docs/images/logo-1024.png"]
var logo: NSImage?
for p in logoCandidates {
    if FileManager.default.fileExists(atPath: p), let img = NSImage(contentsOfFile: p) {
        logo = img
        break
    }
}

let logoSize: CGFloat = (mode == "square") ? 360 : 380
let logoRect: NSRect
if mode == "square" {
    logoRect = NSRect(x: (width - logoSize) / 2, y: height * 0.50, width: logoSize, height: logoSize)
} else {
    logoRect = NSRect(x: 90, y: (height - logoSize) / 2, width: logoSize, height: logoSize)
}
logo?.draw(in: logoRect, from: .zero, operation: .sourceOver, fraction: 1.0)

// ----- 4. Text -----
let white = NSColor.white
let dim = NSColor(calibratedWhite: 1.0, alpha: 0.65)
let accent = NSColor(calibratedRed: 0.45, green: 0.92, blue: 0.65, alpha: 1.0)

func draw(_ text: String, at point: NSPoint, font: NSFont, color: NSColor, align: NSTextAlignment = .left, maxWidth: CGFloat = 0) {
    let style = NSMutableParagraphStyle()
    style.alignment = align
    style.lineBreakMode = .byTruncatingTail
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font, .foregroundColor: color, .paragraphStyle: style,
    ]
    if maxWidth > 0 {
        let rect = NSRect(x: point.x, y: point.y, width: maxWidth, height: font.pointSize * 1.4)
        (text as NSString).draw(in: rect, withAttributes: attrs)
    } else {
        text.draw(at: point, withAttributes: attrs)
    }
}

if mode == "square" {
    let titleFont = NSFont.systemFont(ofSize: 92, weight: .heavy)
    let subFont = NSFont.systemFont(ofSize: 30, weight: .medium)
    let bulletFont = NSFont.systemFont(ofSize: 26, weight: .regular)
    let urlFont = NSFont.monospacedSystemFont(ofSize: 22, weight: .medium)

    draw("KeepAwake", at: NSPoint(x: 0, y: height * 0.36), font: titleFont, color: white, align: .center, maxWidth: width)
    draw("Giữ Mac KHÔNG NGỦ — kể cả khi gập nắp", at: NSPoint(x: 0, y: height * 0.30),
         font: subFont, color: dim, align: .center, maxWidth: width)

    let bullets = ["☕ 3 lớp chống ngủ", "🇻🇳 / 🇬🇧 Song ngữ", "📦 Open source · MIT"]
    var by: CGFloat = height * 0.20
    for b in bullets {
        draw(b, at: NSPoint(x: 0, y: by), font: bulletFont, color: white, align: .center, maxWidth: width)
        by -= 42
    }

    draw("github.com/rowiz-le/KeepAwake-macos", at: NSPoint(x: 0, y: 50),
         font: urlFont, color: accent, align: .center, maxWidth: width)
} else {
    // landscape 1200x630
    let titleFont = NSFont.systemFont(ofSize: 88, weight: .heavy)
    let subFont = NSFont.systemFont(ofSize: 28, weight: .medium)
    let bulletFont = NSFont.systemFont(ofSize: 24, weight: .regular)
    let urlFont = NSFont.monospacedSystemFont(ofSize: 22, weight: .medium)

    let textX: CGFloat = 530
    draw("KeepAwake", at: NSPoint(x: textX, y: 430), font: titleFont, color: white)
    draw("Giữ Mac KHÔNG NGỦ", at: NSPoint(x: textX, y: 380), font: subFont, color: accent)
    draw("kể cả khi gập nắp", at: NSPoint(x: textX, y: 345), font: subFont, color: dim)

    let bullets = ["☕  3 lớp chống ngủ (caffeinate · IOKit · pmset)",
                   "🇻🇳  /  🇬🇧   Song ngữ Việt / Anh",
                   "📦  Open source · MIT · không phí"]
    var by: CGFloat = 270
    for b in bullets {
        draw(b, at: NSPoint(x: textX, y: by), font: bulletFont, color: white)
        by -= 38
    }

    draw("github.com/rowiz-le/KeepAwake-macos", at: NSPoint(x: textX, y: 110),
         font: urlFont, color: accent)
}

canvas.unlockFocus()

guard let tiff = canvas.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let pngData = rep.representation(using: .png, properties: [:]) else {
    print("encode failed")
    exit(2)
}
do {
    try pngData.write(to: URL(fileURLWithPath: outPath))
    print("wrote \(outPath) (\(Int(width))x\(Int(height)))")
} catch {
    print("write failed: \(error)")
    exit(3)
}
