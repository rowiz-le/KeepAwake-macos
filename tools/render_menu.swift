import Cocoa

// Renders a static PNG that visually mirrors KeepAwake's status-bar menu.
// Run: swift tools/render_menu.swift <en|vi> <output.png> <off|on>
//   on = active state (BẬT / ON)  off = inactive
//
// This is a synthesized image (not a live screenshot) to avoid needing
// Screen Recording / Accessibility permissions.

guard CommandLine.arguments.count == 4 else {
    print("usage: render_menu.swift <en|vi> <output.png> <off|on>")
    exit(1)
}
let lang = CommandLine.arguments[1]
let outPath = CommandLine.arguments[2]
let state = CommandLine.arguments[3]

struct Row {
    enum Style { case header, item, itemChecked, itemBold, separator, toggle, dim }
    let text: String
    let style: Style
}

let isOn = (state == "on")

func rows(en: Bool) -> [Row] {
    let t: [String: String]
    if en {
        t = [
            "status":   isOn ? "● ON — Aggressive Mode 🔥" : "● Status: Off",
            "pmset":    isOn ? "   🔒 pmset: ON — Mac will NOT sleep on lid close"
                             : "   🔓 pmset: OFF — lid close will sleep",
            "toggle":   isOn ? "💤 TURN OFF — Allow sleep" : "☕ TURN ON — Keep awake",
            "modeH":    "⚡ Sleep prevention mode:",
            "std":      "   Standard (prevent display sleep)",
            "agg":      "   Aggressive (prevent lid-close sleep) ⭐",
            "durH":     "⏱ Duration:",
            "indef":    "   ♾ Indefinite",
            "d15":      "   15 minutes",
            "d30":      "   30 minutes",
            "d1h":      "   1 hour",
            "d2h":      "   2 hours",
            "d4h":      "   4 hours",
            "langH":    "🌐 Language:",
            "lEN":      "   English",
            "lVI":      "   Tiếng Việt",
            "refresh":  "🔄 Refresh pmset status",
            "version":  "KeepAwake v2.2",
            "quit":     "🚪 Quit",
        ]
    } else {
        t = [
            "status":   isOn ? "● BẬT — Chế độ Mạnh 🔥" : "● Trạng thái: Tắt",
            "pmset":    isOn ? "   🔒 pmset: BẬT — máy KHÔNG ngủ khi gập nắp"
                             : "   🔓 pmset: TẮT — gập nắp sẽ ngủ",
            "toggle":   isOn ? "💤 TẮT — Cho máy ngủ lại" : "☕ BẬT — Giữ máy thức",
            "modeH":    "⚡ Chế độ chống ngủ:",
            "std":      "   Cơ bản (ngăn tắt màn hình)",
            "agg":      "   Mạnh (ngăn ngủ khi gập nắp) ⭐",
            "durH":     "⏱ Thời gian:",
            "indef":    "   ♾ Không giới hạn",
            "d15":      "   15 phút",
            "d30":      "   30 phút",
            "d1h":      "   1 giờ",
            "d2h":      "   2 giờ",
            "d4h":      "   4 giờ",
            "langH":    "🌐 Ngôn ngữ:",
            "lEN":      "   English",
            "lVI":      "   Tiếng Việt",
            "refresh":  "🔄 Cập nhật trạng thái pmset",
            "version":  "KeepAwake v2.2",
            "quit":     "🚪 Thoát",
        ]
    }

    return [
        Row(text: t["status"]!,  style: .dim),
        Row(text: t["pmset"]!,   style: .dim),
        Row(text: "",            style: .separator),
        Row(text: t["toggle"]!,  style: .itemBold),
        Row(text: "",            style: .separator),
        Row(text: t["modeH"]!,   style: .header),
        Row(text: t["std"]!,     style: .item),
        Row(text: t["agg"]!,     style: isOn ? .itemChecked : .itemChecked),
        Row(text: "",            style: .separator),
        Row(text: t["durH"]!,    style: .header),
        Row(text: t["indef"]!,   style: .itemChecked),
        Row(text: t["d15"]!,     style: .item),
        Row(text: t["d30"]!,     style: .item),
        Row(text: t["d1h"]!,     style: .item),
        Row(text: t["d2h"]!,     style: .item),
        Row(text: t["d4h"]!,     style: .item),
        Row(text: "",            style: .separator),
        Row(text: t["langH"]!,   style: .header),
        Row(text: t["lEN"]!,     style: en ? .itemChecked : .item),
        Row(text: t["lVI"]!,     style: en ? .item : .itemChecked),
        Row(text: "",            style: .separator),
        Row(text: t["refresh"]!, style: .item),
        Row(text: t["version"]!, style: .dim),
        Row(text: "",            style: .separator),
        Row(text: t["quit"]!,    style: .item),
    ]
}

let menuRows = rows(en: lang == "en")

let width: CGFloat = 460
let rowH: CGFloat = 26
let sepH: CGFloat = 12
let padTop: CGFloat = 10
let padBot: CGFloat = 10
let padX: CGFloat = 16

var height: CGFloat = padTop + padBot
for r in menuRows {
    height += (r.style == .separator) ? sepH : rowH
}

let scale: CGFloat = 2.0  // retina
let img = NSImage(size: NSSize(width: width, height: height))
img.lockFocus()

// Background: macOS menu look (dark or light depending on system; we'll do light)
let bg = NSColor(calibratedRed: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
bg.setFill()
NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: width, height: height),
             xRadius: 10, yRadius: 10).fill()

// Subtle border
NSColor(calibratedWhite: 0, alpha: 0.12).setStroke()
let border = NSBezierPath(roundedRect: NSRect(x: 0.5, y: 0.5, width: width - 1, height: height - 1),
                          xRadius: 10, yRadius: 10)
border.lineWidth = 1
border.stroke()

// Draw rows from top down (flip y because lockFocus is bottom-up)
var y = height - padTop
let labelFont = NSFont.systemFont(ofSize: 13)
let boldFont = NSFont.boldSystemFont(ofSize: 13)
let headerFont = NSFont.systemFont(ofSize: 12, weight: .medium)
let labelColor = NSColor.black
let dimColor = NSColor(calibratedWhite: 0.45, alpha: 1.0)

for r in menuRows {
    if r.style == .separator {
        let mid = y - sepH / 2
        NSColor(calibratedWhite: 0, alpha: 0.10).setStroke()
        let line = NSBezierPath()
        line.move(to: NSPoint(x: padX, y: mid))
        line.line(to: NSPoint(x: width - padX, y: mid))
        line.lineWidth = 1
        line.stroke()
        y -= sepH
        continue
    }

    let rowY = y - rowH
    let textY = rowY + (rowH - 16) / 2  // vertical center for 13pt text

    // Checkmark prefix
    var textX = padX
    if r.style == .itemChecked {
        let check = "✓"
        let checkAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: labelColor,
        ]
        check.draw(at: NSPoint(x: padX - 6, y: textY), withAttributes: checkAttrs)
        textX = padX + 4  // shift text slightly
    }

    let font: NSFont
    let color: NSColor
    switch r.style {
    case .header:       font = headerFont; color = dimColor
    case .item:         font = labelFont;  color = labelColor
    case .itemChecked:  font = labelFont;  color = labelColor
    case .itemBold:     font = boldFont;   color = labelColor
    case .dim:          font = labelFont;  color = dimColor
    case .toggle:       font = boldFont;   color = labelColor
    case .separator:    font = labelFont;  color = labelColor  // not reached
    }

    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
    ]
    r.text.draw(at: NSPoint(x: textX, y: textY), withAttributes: attrs)
    y -= rowH
}

img.unlockFocus()

// Render at 2x for sharp text on high-DPI displays
guard let tiff = img.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff) else {
    print("Failed to convert to TIFF")
    exit(2)
}
rep.size = NSSize(width: width, height: height)

guard let pngData = rep.representation(using: .png, properties: [:]) else {
    print("Failed to encode PNG")
    exit(3)
}
do {
    try pngData.write(to: URL(fileURLWithPath: outPath))
    print("wrote \(outPath) (\(Int(width))x\(Int(height)))")
} catch {
    print("write failed: \(error)")
    exit(4)
}
