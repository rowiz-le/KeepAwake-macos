import Cocoa
import IOKit.pwr_mgt

// MARK: - KeepAwake v2.2
// Prevents Mac from sleeping even when lid is closed.
// Three layers of protection:
//   1. caffeinate subprocess with -dimsu flags
//   2. IOKit power assertions (multiple types)
//   3. pmset disablesleep (strongest, requires admin password)
//
// v2.2: Bilingual UI (English + Vietnamese), auto-detect locale, manual override.
// v2.1: Validated pmset apply, ioreg state indicator, crash recovery.

enum SleepMode: Int {
    case standard = 0
    case aggressive = 1
}

// MARK: - Localization

enum Language: String {
    case english = "en"
    case vietnamese = "vi"

    static let userDefaultsKey = "KeepAwakeLanguage"

    static var current: Language {
        if let saved = UserDefaults.standard.string(forKey: userDefaultsKey),
           let lang = Language(rawValue: saved) {
            return lang
        }
        let code = Locale.current.language.languageCode?.identifier ?? "en"
        return code == "vi" ? .vietnamese : .english
    }

    static func set(_ lang: Language) {
        UserDefaults.standard.set(lang.rawValue, forKey: userDefaultsKey)
    }
}

struct UIText {
    let statusOff: String
    let statusOnAggressive: String
    let statusOnStandard: String
    let pmsetReading: String
    let pmsetOn: String
    let pmsetOff: String
    let toggleOn: String
    let toggleOff: String

    let modeHeader: String
    let modeStandard: String
    let modeAggressive: String

    let durationHeader: String
    let durationIndefinite: String
    let duration15: String
    let duration30: String
    let duration1h: String
    let duration2h: String
    let duration4h: String

    let timerRemaining: String
    let timerElapsed: String

    let languageHeader: String
    let langEnglish: String
    let langVietnamese: String

    let refreshPmset: String
    let appVersion: String
    let quit: String

    let notifAggressiveTitle: String
    let notifAggressiveBody: String
    let notifStandardTitle: String
    let notifStandardBody: String
    let notifTimerEndTitle: String
    let notifTimerEndBody: String

    let alertPmsetFailTitle: String
    let alertPmsetFailBody: String
    let btnRetry: String
    let btnFallback: String
    let btnCancel: String

    let alertRecoverTitle: String
    let alertRecoverBody: String
    let btnRecoverDisable: String
    let btnRecoverLeave: String

    static let english = UIText(
        statusOff: "● Status: Off",
        statusOnAggressive: "● ON — Aggressive Mode 🔥",
        statusOnStandard: "● ON — Standard Mode",
        pmsetReading: "   🔓 pmset: reading…",
        pmsetOn: "   🔒 pmset: ON — Mac will NOT sleep on lid close",
        pmsetOff: "   🔓 pmset: OFF — lid close will sleep",
        toggleOn: "☕ TURN ON — Keep awake",
        toggleOff: "💤 TURN OFF — Allow sleep",
        modeHeader: "⚡ Sleep prevention mode:",
        modeStandard: "   Standard (prevent display sleep)",
        modeAggressive: "   Aggressive (prevent lid-close sleep) ⭐",
        durationHeader: "⏱ Duration:",
        durationIndefinite: "   ♾ Indefinite",
        duration15: "   15 minutes",
        duration30: "   30 minutes",
        duration1h: "   1 hour",
        duration2h: "   2 hours",
        duration4h: "   4 hours",
        timerRemaining: "   ⏰ Remaining: %@",
        timerElapsed: "   ⏰ Elapsed: %@",
        languageHeader: "🌐 Language:",
        langEnglish: "   English",
        langVietnamese: "   Tiếng Việt",
        refreshPmset: "🔄 Refresh pmset status",
        appVersion: "KeepAwake v2.2",
        quit: "🚪 Quit",
        notifAggressiveTitle: "☕ KeepAwake ON — Aggressive 🔥",
        notifAggressiveBody: "Mac will NOT sleep even with lid closed. (Plug in for best results.)",
        notifStandardTitle: "☕ KeepAwake ON — Standard",
        notifStandardBody: "Preventing display + idle sleep. Lid-close will still cause sleep.",
        notifTimerEndTitle: "💤 KeepAwake OFF",
        notifTimerEndBody: "Time's up. Mac will sleep normally.",
        alertPmsetFailTitle: "Could not enable Aggressive Mode",
        alertPmsetFailBody: "Admin password is required to run 'pmset disablesleep 1' — the only way to prevent Mac from sleeping on lid close.\n\nYou cancelled or entered the wrong password. What now?",
        btnRetry: "Try Again",
        btnFallback: "Use Standard Mode",
        btnCancel: "Cancel",
        alertRecoverTitle: "Orphaned pmset disablesleep detected",
        alertRecoverBody: "KeepAwake quit unexpectedly last time without restoring sleep settings.\nYour Mac is currently set to NEVER SLEEP — disable that?",
        btnRecoverDisable: "Disable pmset (recommended)",
        btnRecoverLeave: "Leave as is"
    )

    static let vietnamese = UIText(
        statusOff: "● Trạng thái: Tắt",
        statusOnAggressive: "● BẬT — Chế độ Mạnh 🔥",
        statusOnStandard: "● BẬT — Cơ bản",
        pmsetReading: "   🔓 pmset: đang đọc…",
        pmsetOn: "   🔒 pmset: BẬT — máy KHÔNG ngủ khi gập nắp",
        pmsetOff: "   🔓 pmset: TẮT — gập nắp sẽ ngủ",
        toggleOn: "☕ BẬT — Giữ máy thức",
        toggleOff: "💤 TẮT — Cho máy ngủ lại",
        modeHeader: "⚡ Chế độ chống ngủ:",
        modeStandard: "   Cơ bản (ngăn tắt màn hình)",
        modeAggressive: "   Mạnh (ngăn ngủ khi gập nắp) ⭐",
        durationHeader: "⏱ Thời gian:",
        durationIndefinite: "   ♾ Không giới hạn",
        duration15: "   15 phút",
        duration30: "   30 phút",
        duration1h: "   1 giờ",
        duration2h: "   2 giờ",
        duration4h: "   4 giờ",
        timerRemaining: "   ⏰ Còn lại: %@",
        timerElapsed: "   ⏰ Đã chạy: %@",
        languageHeader: "🌐 Ngôn ngữ:",
        langEnglish: "   English",
        langVietnamese: "   Tiếng Việt",
        refreshPmset: "🔄 Cập nhật trạng thái pmset",
        appVersion: "KeepAwake v2.2",
        quit: "🚪 Thoát",
        notifAggressiveTitle: "☕ KeepAwake BẬT — Chế độ Mạnh 🔥",
        notifAggressiveBody: "Mac sẽ KHÔNG ngủ kể cả khi gập nắp. (Khuyên cắm sạc để chắc chắn.)",
        notifStandardTitle: "☕ KeepAwake BẬT — Cơ bản",
        notifStandardBody: "Ngăn tắt màn hình + idle sleep. KHÔNG ngăn được sleep khi gập nắp.",
        notifTimerEndTitle: "💤 KeepAwake TẮT",
        notifTimerEndBody: "Hết giờ. Mac sẽ ngủ bình thường.",
        alertPmsetFailTitle: "Không thể bật chế độ Mạnh",
        alertPmsetFailBody: "Cần password admin để chạy 'pmset disablesleep 1' — đây là cách duy nhất ngăn Mac ngủ khi gập nắp.\n\nBạn đã Cancel hoặc nhập sai password. Bạn muốn làm gì?",
        btnRetry: "Thử lại",
        btnFallback: "Chuyển sang Cơ bản",
        btnCancel: "Huỷ",
        alertRecoverTitle: "Phát hiện pmset disablesleep còn sót lại",
        alertRecoverBody: "Lần trước KeepAwake thoát đột ngột mà chưa kịp khôi phục lại cài đặt ngủ.\nHiện máy đang ở trạng thái KHÔNG BAO GIỜ NGỦ — có muốn tắt không?",
        btnRecoverDisable: "Tắt pmset (khuyến nghị)",
        btnRecoverLeave: "Để nguyên"
    )

    static func current() -> UIText {
        switch Language.current {
        case .english: return .english
        case .vietnamese: return .vietnamese
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Properties
    private var statusItem: NSStatusItem!
    private var isActive = false
    private var currentMode: SleepMode = .aggressive

    private var caffeinateProcess: Process?
    private var assertionIDs: [IOPMAssertionID] = []
    private var pmsetDisabled = false

    private var timer: Timer?
    private var elapsedSeconds: Int = 0
    private var selectedDuration: Int = 0

    // Menu items (rebuilt on language switch)
    private var statusMenuItem: NSMenuItem!
    private var pmsetStateMenuItem: NSMenuItem!
    private var toggleMenuItem: NSMenuItem!
    private var timerMenuItem: NSMenuItem!
    private var modeHeaderItem: NSMenuItem!
    private var modeStandardItem: NSMenuItem!
    private var modeAggressiveItem: NSMenuItem!
    private var durationHeaderItem: NSMenuItem!
    private var indefiniteItem: NSMenuItem!
    private var duration15Item: NSMenuItem!
    private var duration30Item: NSMenuItem!
    private var duration1hItem: NSMenuItem!
    private var duration2hItem: NSMenuItem!
    private var duration4hItem: NSMenuItem!
    private var languageHeaderItem: NSMenuItem!
    private var langEnglishItem: NSMenuItem!
    private var langVietnameseItem: NSMenuItem!
    private var refreshItem: NSMenuItem!
    private var aboutItem: NSMenuItem!
    private var quitItem: NSMenuItem!

    private var pmsetStateFile: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("KeepAwake", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("pmset.flag")
    }

    // MARK: - App Lifecycle
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupMenu()
        applyLocalization()
        recoverFromPreviousCrash()
        refreshPmsetIndicator()
    }

    func applicationWillTerminate(_ notification: Notification) {
        if isActive { deactivate() }
    }

    // MARK: - Crash Recovery
    private func recoverFromPreviousCrash() {
        let flagExists = FileManager.default.fileExists(atPath: pmsetStateFile.path)
        let pmsetIsSet = checkPmsetDisableSleep()
        guard flagExists && pmsetIsSet else {
            try? FileManager.default.removeItem(at: pmsetStateFile)
            return
        }

        let t = UIText.current()
        NSLog("KeepAwake: Detected orphaned pmset=1 from previous crash, prompting user.")
        let alert = NSAlert()
        alert.messageText = t.alertRecoverTitle
        alert.informativeText = t.alertRecoverBody
        alert.alertStyle = .warning
        alert.addButton(withTitle: t.btnRecoverDisable)
        alert.addButton(withTitle: t.btnRecoverLeave)

        if alert.runModal() == .alertFirstButtonReturn {
            disablePmsetDisableSleep()
        }
        try? FileManager.default.removeItem(at: pmsetStateFile)
    }

    // MARK: - Status Bar
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = createIcon(active: false)
            button.imagePosition = .imageLeft
        }
    }

    private func createIcon(active: Bool) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let color: NSColor = active
                ? NSColor(calibratedRed: 0.35, green: 0.78, blue: 0.55, alpha: 1.0)
                : NSColor.secondaryLabelColor
            color.setStroke()
            color.setFill()

            let cup = NSBezierPath()
            cup.move(to: NSPoint(x: 3, y: 13))
            cup.line(to: NSPoint(x: 4, y: 3))
            cup.line(to: NSPoint(x: 11, y: 3))
            cup.line(to: NSPoint(x: 12, y: 13))
            cup.lineWidth = 1.5
            cup.stroke()

            let handle = NSBezierPath()
            handle.move(to: NSPoint(x: 12, y: 11))
            handle.curve(to: NSPoint(x: 12, y: 5),
                        controlPoint1: NSPoint(x: 16, y: 11),
                        controlPoint2: NSPoint(x: 16, y: 5))
            handle.lineWidth = 1.5
            handle.stroke()

            if active {
                let steam = NSColor(calibratedRed: 0.35, green: 0.78, blue: 0.55, alpha: 0.7)
                steam.setStroke()
                for i in 0..<3 {
                    let s = NSBezierPath()
                    let x = 5 + CGFloat(i) * 3
                    s.move(to: NSPoint(x: x, y: 14))
                    s.curve(to: NSPoint(x: x, y: 18),
                           controlPoint1: NSPoint(x: x - 1.5, y: 15),
                           controlPoint2: NSPoint(x: x + 1.5, y: 17))
                    s.lineWidth = 1.0
                    s.stroke()
                }
            }
            return true
        }
        image.isTemplate = !active
        return image
    }

    // MARK: - Menu (built once, titles updated by applyLocalization)
    private func setupMenu() {
        let menu = NSMenu()
        menu.autoenablesItems = false

        statusMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)

        pmsetStateMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        pmsetStateMenuItem.isEnabled = false
        menu.addItem(pmsetStateMenuItem)

        menu.addItem(NSMenuItem.separator())

        toggleMenuItem = NSMenuItem(title: "", action: #selector(toggle), keyEquivalent: "")
        toggleMenuItem.target = self
        menu.addItem(toggleMenuItem)

        timerMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        timerMenuItem.isHidden = true
        menu.addItem(timerMenuItem)

        menu.addItem(NSMenuItem.separator())

        modeHeaderItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        modeHeaderItem.isEnabled = false
        menu.addItem(modeHeaderItem)

        modeStandardItem = NSMenuItem(title: "", action: #selector(setStandard), keyEquivalent: "")
        modeStandardItem.target = self
        modeStandardItem.state = .off
        menu.addItem(modeStandardItem)

        modeAggressiveItem = NSMenuItem(title: "", action: #selector(setAggressive), keyEquivalent: "")
        modeAggressiveItem.target = self
        modeAggressiveItem.state = .on
        menu.addItem(modeAggressiveItem)

        menu.addItem(NSMenuItem.separator())

        durationHeaderItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        durationHeaderItem.isEnabled = false
        menu.addItem(durationHeaderItem)

        indefiniteItem = NSMenuItem(title: "", action: #selector(setIndefinite), keyEquivalent: "")
        indefiniteItem.target = self
        indefiniteItem.state = .on
        menu.addItem(indefiniteItem)

        duration15Item = NSMenuItem(title: "", action: #selector(set15), keyEquivalent: "")
        duration15Item.target = self
        menu.addItem(duration15Item)

        duration30Item = NSMenuItem(title: "", action: #selector(set30), keyEquivalent: "")
        duration30Item.target = self
        menu.addItem(duration30Item)

        duration1hItem = NSMenuItem(title: "", action: #selector(set1h), keyEquivalent: "")
        duration1hItem.target = self
        menu.addItem(duration1hItem)

        duration2hItem = NSMenuItem(title: "", action: #selector(set2h), keyEquivalent: "")
        duration2hItem.target = self
        menu.addItem(duration2hItem)

        duration4hItem = NSMenuItem(title: "", action: #selector(set4h), keyEquivalent: "")
        duration4hItem.target = self
        menu.addItem(duration4hItem)

        menu.addItem(NSMenuItem.separator())

        languageHeaderItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        languageHeaderItem.isEnabled = false
        menu.addItem(languageHeaderItem)

        langEnglishItem = NSMenuItem(title: "", action: #selector(setLangEnglish), keyEquivalent: "")
        langEnglishItem.target = self
        menu.addItem(langEnglishItem)

        langVietnameseItem = NSMenuItem(title: "", action: #selector(setLangVietnamese), keyEquivalent: "")
        langVietnameseItem.target = self
        menu.addItem(langVietnameseItem)

        menu.addItem(NSMenuItem.separator())

        refreshItem = NSMenuItem(title: "", action: #selector(refreshPmsetMenu), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)

        aboutItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        aboutItem.isEnabled = false
        menu.addItem(aboutItem)

        menu.addItem(NSMenuItem.separator())

        quitItem = NSMenuItem(title: "", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func applyLocalization() {
        let t = UIText.current()

        statusMenuItem.title = isActive
            ? (currentMode == .aggressive ? t.statusOnAggressive : t.statusOnStandard)
            : t.statusOff
        toggleMenuItem.title = isActive ? t.toggleOff : t.toggleOn
        modeHeaderItem.title = t.modeHeader
        modeStandardItem.title = t.modeStandard
        modeAggressiveItem.title = t.modeAggressive
        durationHeaderItem.title = t.durationHeader
        indefiniteItem.title = t.durationIndefinite
        duration15Item.title = t.duration15
        duration30Item.title = t.duration30
        duration1hItem.title = t.duration1h
        duration2hItem.title = t.duration2h
        duration4hItem.title = t.duration4h
        languageHeaderItem.title = t.languageHeader
        langEnglishItem.title = t.langEnglish
        langVietnameseItem.title = t.langVietnamese
        refreshItem.title = t.refreshPmset
        aboutItem.title = t.appVersion
        quitItem.title = t.quit

        // Language checkmarks
        switch Language.current {
        case .english:
            langEnglishItem.state = .on
            langVietnameseItem.state = .off
        case .vietnamese:
            langEnglishItem.state = .off
            langVietnameseItem.state = .on
        }

        refreshPmsetIndicator()
        updateTimerDisplay()
    }

    // MARK: - Toggle
    @objc private func toggle() {
        if isActive { deactivate() } else { activate() }
    }

    @objc private func refreshPmsetMenu() {
        refreshPmsetIndicator()
    }

    // MARK: - Language
    @objc private func setLangEnglish() {
        Language.set(.english)
        applyLocalization()
    }

    @objc private func setLangVietnamese() {
        Language.set(.vietnamese)
        applyLocalization()
    }

    // MARK: - Activate
    private func activate() {
        startCaffeinate()
        createIOKitAssertions()

        if currentMode == .aggressive {
            var aggressiveSucceeded = enablePmsetDisableSleep()
            if !aggressiveSucceeded {
                let choice = showPmsetFailureAlert()
                switch choice {
                case .retry:
                    aggressiveSucceeded = enablePmsetDisableSleep()
                    if !aggressiveSucceeded {
                        stopCaffeinate()
                        releaseIOKitAssertions()
                        refreshPmsetIndicator()
                        return
                    }
                case .fallback:
                    currentMode = .standard
                    modeStandardItem.state = .on
                    modeAggressiveItem.state = .off
                case .cancel:
                    stopCaffeinate()
                    releaseIOKitAssertions()
                    refreshPmsetIndicator()
                    return
                }
            }
        }

        isActive = true
        updateUI()
        refreshPmsetIndicator()
        startTimer()

        let t = UIText.current()
        if currentMode == .aggressive && pmsetDisabled {
            showNotification(title: t.notifAggressiveTitle, body: t.notifAggressiveBody)
        } else {
            showNotification(title: t.notifStandardTitle, body: t.notifStandardBody)
        }
    }

    private enum PmsetFailureChoice {
        case retry, fallback, cancel
    }

    private func showPmsetFailureAlert() -> PmsetFailureChoice {
        let t = UIText.current()
        let alert = NSAlert()
        alert.messageText = t.alertPmsetFailTitle
        alert.informativeText = t.alertPmsetFailBody
        alert.alertStyle = .warning
        alert.addButton(withTitle: t.btnRetry)
        alert.addButton(withTitle: t.btnFallback)
        alert.addButton(withTitle: t.btnCancel)

        switch alert.runModal() {
        case .alertFirstButtonReturn: return .retry
        case .alertSecondButtonReturn: return .fallback
        default: return .cancel
        }
    }

    // MARK: - Deactivate
    private func deactivate() {
        stopCaffeinate()
        releaseIOKitAssertions()

        if pmsetDisabled || checkPmsetDisableSleep() {
            disablePmsetDisableSleep()
        }

        isActive = false
        stopTimer()
        updateUI()
        refreshPmsetIndicator()
    }

    // MARK: - Layer 1: caffeinate
    private func startCaffeinate() {
        stopCaffeinate()

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        process.arguments = currentMode == .aggressive ? ["-dimsu"] : ["-di"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            caffeinateProcess = process
        } catch {
            NSLog("KeepAwake: Failed to start caffeinate: \(error)")
        }
    }

    private func stopCaffeinate() {
        if let proc = caffeinateProcess, proc.isRunning {
            proc.terminate()
            proc.waitUntilExit()
        }
        caffeinateProcess = nil
    }

    // MARK: - Layer 2: IOKit Power Assertions
    private func createIOKitAssertions() {
        releaseIOKitAssertions()

        let reason = "KeepAwake - User requested to prevent sleep" as CFString
        let assertionTypes: [String] = [
            kIOPMAssertPreventUserIdleSystemSleep as String,
            kIOPMAssertPreventUserIdleDisplaySleep as String,
            kIOPMAssertionTypePreventSystemSleep as String,
            kIOPMAssertionTypeNoIdleSleep as String,
            kIOPMAssertionTypeNoDisplaySleep as String,
        ]

        for type in assertionTypes {
            var assertionID: IOPMAssertionID = 0
            let result = IOPMAssertionCreateWithName(
                type as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                reason,
                &assertionID
            )
            if result == kIOReturnSuccess {
                assertionIDs.append(assertionID)
            }
        }
    }

    private func releaseIOKitAssertions() {
        for id in assertionIDs {
            IOPMAssertionRelease(id)
        }
        assertionIDs.removeAll()
    }

    // MARK: - Layer 3: pmset disablesleep
    private func enablePmsetDisableSleep() -> Bool {
        let script = """
        do shell script "pmset -a disablesleep 1" with administrator privileges
        """
        let appleScript = NSAppleScript(source: script)
        var error: NSDictionary?
        appleScript?.executeAndReturnError(&error)

        if let error = error {
            let errNum = (error[NSAppleScript.errorNumber] as? Int) ?? 0
            NSLog("KeepAwake: pmset enable failed (errno=\(errNum)): \(error)")
            pmsetDisabled = false
            return false
        }

        let verified = checkPmsetDisableSleep()
        pmsetDisabled = verified

        if verified {
            try? "1".write(to: pmsetStateFile, atomically: true, encoding: .utf8)
        } else {
            NSLog("KeepAwake: pmset succeeded but ioreg shows SleepDisabled=No")
        }
        return verified
    }

    private func disablePmsetDisableSleep() {
        let script = """
        do shell script "pmset -a disablesleep 0" with administrator privileges
        """
        let appleScript = NSAppleScript(source: script)
        var error: NSDictionary?
        appleScript?.executeAndReturnError(&error)

        pmsetDisabled = false
        try? FileManager.default.removeItem(at: pmsetStateFile)

        if let error = error {
            NSLog("KeepAwake: pmset restore failed: \(error)")
        }
    }

    private func checkPmsetDisableSleep() -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/ioreg")
        task.arguments = ["-c", "IOPMrootDomain", "-r", "-k", "SleepDisabled", "-d", "1"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return output.contains("\"SleepDisabled\" = Yes")
            }
        } catch {
            NSLog("KeepAwake: ioreg check failed: \(error)")
        }
        return false
    }

    private func refreshPmsetIndicator() {
        let t = UIText.current()
        pmsetStateMenuItem.title = checkPmsetDisableSleep() ? t.pmsetOn : t.pmsetOff
    }

    // MARK: - Mode Selection
    @objc private func setStandard() {
        currentMode = .standard
        modeStandardItem.state = .on
        modeAggressiveItem.state = .off
        if isActive { deactivate(); activate() }
    }

    @objc private func setAggressive() {
        currentMode = .aggressive
        modeStandardItem.state = .off
        modeAggressiveItem.state = .on
        if isActive { deactivate(); activate() }
    }

    // MARK: - Duration Selection
    private func clearDurationChecks() {
        indefiniteItem.state = .off
        duration15Item.state = .off
        duration30Item.state = .off
        duration1hItem.state = .off
        duration2hItem.state = .off
        duration4hItem.state = .off
    }

    private func setDuration(_ seconds: Int, item: NSMenuItem) {
        clearDurationChecks()
        item.state = .on
        selectedDuration = seconds
        if isActive { deactivate(); activate() }
    }

    @objc private func setIndefinite() { setDuration(0, item: indefiniteItem) }
    @objc private func set15() { setDuration(15 * 60, item: duration15Item) }
    @objc private func set30() { setDuration(30 * 60, item: duration30Item) }
    @objc private func set1h() { setDuration(60 * 60, item: duration1hItem) }
    @objc private func set2h() { setDuration(2 * 60 * 60, item: duration2hItem) }
    @objc private func set4h() { setDuration(4 * 60 * 60, item: duration4hItem) }

    // MARK: - Timer
    private func startTimer() {
        elapsedSeconds = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.elapsedSeconds += 1
            self.updateTimerDisplay()

            if self.selectedDuration > 0 && self.elapsedSeconds >= self.selectedDuration {
                self.deactivate()
                let t = UIText.current()
                self.showNotification(title: t.notifTimerEndTitle, body: t.notifTimerEndBody)
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        elapsedSeconds = 0
    }

    private func updateTimerDisplay() {
        guard isActive else { timerMenuItem.isHidden = true; return }
        let t = UIText.current()
        if selectedDuration > 0 {
            let remaining = max(0, selectedDuration - elapsedSeconds)
            timerMenuItem.title = String(format: t.timerRemaining, formatTime(remaining))
        } else {
            timerMenuItem.title = String(format: t.timerElapsed, formatTime(elapsedSeconds))
        }
        timerMenuItem.isHidden = false
    }

    // MARK: - UI Updates
    private func updateUI() {
        statusItem.button?.image = createIcon(active: isActive)

        let t = UIText.current()
        if isActive {
            statusMenuItem.title = currentMode == .aggressive ? t.statusOnAggressive : t.statusOnStandard
            toggleMenuItem.title = t.toggleOff
        } else {
            statusMenuItem.title = t.statusOff
            toggleMenuItem.title = t.toggleOn
            timerMenuItem.isHidden = true
        }
    }

    // MARK: - Helpers
    private func formatTime(_ total: Int) -> String {
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }

    private func showNotification(title: String, body: String) {
        let n = NSUserNotification()
        n.title = title
        n.informativeText = body
        NSUserNotificationCenter.default.deliver(n)
    }

    @objc private func quit() {
        if isActive { deactivate() }
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - Main
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
