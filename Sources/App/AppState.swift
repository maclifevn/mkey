//
//  AppState.swift
//  mkey
//
//  Single source of truth for the UI. Mirrors the engine's C globals and
//  UserDefaults, and reacts to engine-driven changes (hotkey switch,
//  smart switch) through MKStateDidChangeNotification.
//

import AppKit
import Combine
import ServiceManagement
import SwiftUI

enum SettingsPage: String, CaseIterable, Identifiable {
    case typing, macro, convert, system, about
    var id: String { rawValue }

    var title: String {
        switch self {
        case .typing: return "Bộ gõ"
        case .macro: return "Gõ tắt"
        case .convert: return "Chuyển mã"
        case .system: return "Hệ thống"
        case .about: return "Giới thiệu"
        }
    }

    var icon: String {
        switch self {
        case .typing: return "keyboard"
        case .macro: return "text.badge.plus"
        case .convert: return "arrow.left.arrow.right"
        case .system: return "gearshape"
        case .about: return "info.circle"
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    static let inputTypeNames = ["Telex", "VNI", "Simple Telex 1", "Simple Telex 2"]
    static let codeTableNames = ["Unicode dựng sẵn", "TCVN3 (ABC)", "VNI Windows", "Unicode tổ hợp", "Vietnamese Locale CP 1258"]

    private let defaults = UserDefaults.standard
    private var suppressCallbacks = false

    @Published var selectedPage: SettingsPage = .typing
    @Published var accessibilityGranted = true

    // MARK: Core state

    @Published var isVietnamese: Bool {
        didSet {
            guard !suppressCallbacks, isVietnamese != (vLanguage == 1) else { return }
            MKBridge.setLanguage(isVietnamese ? 1 : 0)
        }
    }

    @Published var inputType: Int {
        didSet {
            guard !suppressCallbacks, inputType != Int(vInputType) else { return }
            MKBridge.setInputType(Int32(inputType))
        }
    }

    @Published var codeTable: Int {
        didSet {
            guard !suppressCallbacks, codeTable != Int(vCodeTable) else { return }
            MKBridge.setCodeTable(Int32(codeTable))
        }
    }

    // MARK: Switch hotkey (bitfield, see Engine.h)

    @Published var switchKeyStatus: Int32 {
        didSet {
            guard !suppressCallbacks else { return }
            vSwitchKeyStatus = switchKeyStatus
            MKBridge.persistSwitchKeyStatus()
        }
    }

    // MARK: Typing options

    @Published var checkSpelling: Bool { didSet { set("Spelling", &vCheckSpelling, checkSpelling); MKBridge.spellCheckingChanged() } }
    @Published var modernOrthography: Bool { didSet { set("ModernOrthography", &vUseModernOrthography, modernOrthography) } }
    @Published var freeMark: Bool { didSet { set("FreeMark", &vFreeMark, freeMark) } }
    @Published var quickTelex: Bool { didSet { set("QuickTelex", &vQuickTelex, quickTelex) } }
    @Published var restoreIfWrongSpelling: Bool { didSet { set("RestoreIfInvalidWord", &vRestoreIfWrongSpelling, restoreIfWrongSpelling) } }
    @Published var fixRecommendBrowser: Bool { didSet { set("FixRecommendBrowser", &vFixRecommendBrowser, fixRecommendBrowser) } }
    @Published var fixChromiumBrowser: Bool { didSet { set("vFixChromiumBrowser", &vFixChromiumBrowser, fixChromiumBrowser) } }
    @Published var upperCaseFirstChar: Bool { didSet { set("UpperCaseFirstChar", &vUpperCaseFirstChar, upperCaseFirstChar) } }
    @Published var tempOffSpelling: Bool { didSet { set("vTempOffSpelling", &vTempOffSpelling, tempOffSpelling) } }
    @Published var allowZFWJ: Bool { didSet { set("vAllowConsonantZFWJ", &vAllowConsonantZFWJ, allowZFWJ) } }
    @Published var quickStartConsonant: Bool { didSet { set("vQuickStartConsonant", &vQuickStartConsonant, quickStartConsonant) } }
    @Published var quickEndConsonant: Bool { didSet { set("vQuickEndConsonant", &vQuickEndConsonant, quickEndConsonant) } }
    @Published var tempOffByCommand: Bool { didSet { set("vTempOffOpenKey", &vTempOffOpenKey, tempOffByCommand) } }
    @Published var otherLanguage: Bool { didSet { set("vOtherLanguage", &vOtherLanguage, otherLanguage) } }
    @Published var fixSpotlight: Bool { didSet { set("vFixSpotlight", &vFixSpotlight, fixSpotlight) } }

    // MARK: Macro options

    @Published var useMacro: Bool { didSet { set("UseMacro", &vUseMacro, useMacro) } }
    @Published var useMacroInEnglishMode: Bool { didSet { set("UseMacroInEnglishMode", &vUseMacroInEnglishMode, useMacroInEnglishMode) } }
    @Published var autoCapsMacro: Bool { didSet { set("vAutoCapsMacro", &vAutoCapsMacro, autoCapsMacro) } }

    // MARK: System options

    @Published var useSmartSwitchKey: Bool { didSet { set("UseSmartSwitchKey", &vUseSmartSwitchKey, useSmartSwitchKey) } }
    @Published var rememberCode: Bool { didSet { set("vRememberCode", &vRememberCode, rememberCode) } }
    @Published var sendKeyStepByStep: Bool { didSet { set("SendKeyStepByStep", &vSendKeyStepByStep, sendKeyStepByStep) } }
    @Published var performLayoutCompat: Bool { didSet { set("vPerformLayoutCompat", &vPerformLayoutCompat, performLayoutCompat) } }

    @Published var grayIcon: Bool {
        didSet { if !suppressCallbacks { defaults.set(grayIcon, forKey: "GrayIcon") } }
    }

    @Published var showIconOnDock: Bool {
        didSet {
            guard !suppressCallbacks else { return }
            defaults.set(showIconOnDock, forKey: "vShowIconOnDock")
            NSApp.setActivationPolicy(showIconOnDock ? .regular : .accessory)
        }
    }

    @Published var showUIOnStartup: Bool {
        didSet { if !suppressCallbacks { defaults.set(showUIOnStartup, forKey: "ShowUIOnStartup") } }
    }

    @Published var runOnStartup: Bool {
        didSet {
            guard !suppressCallbacks else { return }
            do {
                if runOnStartup {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                NSLog("mkey: SMAppService error: \(error)")
                suppressCallbacks = true
                runOnStartup = SMAppService.mainApp.status == .enabled
                suppressCallbacks = false
            }
        }
    }

    // MARK: Convert tool (backed by MKBridge)

    @Published var convertFromCode: Int { didSet { if !suppressCallbacks { MKBridge.convertFromCode = Int32(convertFromCode) } } }
    @Published var convertToCode: Int { didSet { if !suppressCallbacks { MKBridge.convertToCode = Int32(convertToCode) } } }
    @Published var convertAlert: Bool { didSet { if !suppressCallbacks { MKBridge.convertAlertWhenCompleted = convertAlert } } }
    @Published var convertRemoveMark: Bool { didSet { if !suppressCallbacks { MKBridge.convertRemoveMark = convertRemoveMark } } }
    @Published var convertCaseMode: Int { // 0 none, 1 ALL CAPS, 2 all lower, 3 Cap first letter, 4 Cap Each Word
        didSet {
            guard !suppressCallbacks else { return }
            MKBridge.convertToAllCaps = convertCaseMode == 1
            MKBridge.convertToAllNonCaps = convertCaseMode == 2
            MKBridge.convertToCapsFirstLetter = convertCaseMode == 3
            MKBridge.convertToCapsEachWord = convertCaseMode == 4
        }
    }
    @Published var convertHotKey: Int32 { didSet { if !suppressCallbacks { MKBridge.convertHotKey = convertHotKey } } }

    // MARK: Init

    private init() {
        AppState.registerDefaultSettings()

        isVietnamese = defaults.integer(forKey: "InputMethod") == 1
        inputType = defaults.integer(forKey: "InputType")
        codeTable = defaults.integer(forKey: "CodeTable")
        var status = Int32(truncatingIfNeeded: defaults.integer(forKey: "SwitchKeyStatus"))
        if status == 0 { status = Int32(MKEY_DEFAULT_SWITCH_STATUS) }
        switchKeyStatus = status

        checkSpelling = defaults.integer(forKey: "Spelling") != 0
        modernOrthography = defaults.integer(forKey: "ModernOrthography") != 0
        freeMark = defaults.integer(forKey: "FreeMark") != 0
        quickTelex = defaults.integer(forKey: "QuickTelex") != 0
        restoreIfWrongSpelling = defaults.integer(forKey: "RestoreIfInvalidWord") != 0
        fixRecommendBrowser = defaults.integer(forKey: "FixRecommendBrowser") != 0
        fixChromiumBrowser = defaults.integer(forKey: "vFixChromiumBrowser") != 0
        upperCaseFirstChar = defaults.integer(forKey: "UpperCaseFirstChar") != 0
        tempOffSpelling = defaults.integer(forKey: "vTempOffSpelling") != 0
        allowZFWJ = defaults.integer(forKey: "vAllowConsonantZFWJ") != 0
        quickStartConsonant = defaults.integer(forKey: "vQuickStartConsonant") != 0
        quickEndConsonant = defaults.integer(forKey: "vQuickEndConsonant") != 0
        tempOffByCommand = defaults.integer(forKey: "vTempOffOpenKey") != 0
        otherLanguage = defaults.integer(forKey: "vOtherLanguage") != 0
        fixSpotlight = defaults.integer(forKey: "vFixSpotlight") != 0

        useMacro = defaults.integer(forKey: "UseMacro") != 0
        useMacroInEnglishMode = defaults.integer(forKey: "UseMacroInEnglishMode") != 0
        autoCapsMacro = defaults.integer(forKey: "vAutoCapsMacro") != 0

        useSmartSwitchKey = defaults.integer(forKey: "UseSmartSwitchKey") != 0
        rememberCode = defaults.integer(forKey: "vRememberCode") != 0
        sendKeyStepByStep = defaults.integer(forKey: "SendKeyStepByStep") != 0
        performLayoutCompat = defaults.integer(forKey: "vPerformLayoutCompat") != 0
        grayIcon = defaults.integer(forKey: "GrayIcon") != 0
        showIconOnDock = defaults.integer(forKey: "vShowIconOnDock") != 0
        showUIOnStartup = defaults.integer(forKey: "ShowUIOnStartup") != 0
        runOnStartup = SMAppService.mainApp.status == .enabled

        convertFromCode = defaults.integer(forKey: "convertToolFromCode")
        convertToCode = defaults.integer(forKey: "convertToolToCode")
        convertAlert = defaults.bool(forKey: "convertToolAlertWhenCompleted")
        convertRemoveMark = defaults.bool(forKey: "convertToolRemoveMark")
        if defaults.bool(forKey: "convertToolToAllCaps") { convertCaseMode = 1 }
        else if defaults.bool(forKey: "convertToolToAllNonCaps") { convertCaseMode = 2 }
        else if defaults.bool(forKey: "convertToolToCapsFirstLetter") { convertCaseMode = 3 }
        else if defaults.bool(forKey: "convertToolToCapsEachWord") { convertCaseMode = 4 }
        else { convertCaseMode = 0 }
        var hotkey = Int32(truncatingIfNeeded: defaults.integer(forKey: "convertToolHotKey"))
        if hotkey == 0 { hotkey = Int32(bitPattern: UInt32(MKEY_EMPTY_HOTKEY)) }
        convertHotKey = hotkey

        NotificationCenter.default.addObserver(forName: .MKStateDidChange,
                                               object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.reloadFromEngine()
            }
        }
    }

    /// Defaults for a fresh install — mirrors OpenKey's loadDefaultConfig.
    static func registerDefaultSettings() {
        UserDefaults.standard.register(defaults: [
            "InputMethod": 1,
            "InputType": 0,
            "CodeTable": 0,
            "Spelling": 1,
            "ModernOrthography": 0,
            "FixRecommendBrowser": 1,
            "UseMacro": 1,
            "UseSmartSwitchKey": 1,
            "vRememberCode": 1,
            "vOtherLanguage": 1,
            "GrayIcon": 1,
            "SwitchKeyStatus": Int(MKEY_DEFAULT_SWITCH_STATUS),
            "vFixSpotlight": 1,
            "convertToolAlertWhenCompleted": true,
        ])
    }

    /// Engine changed state behind our back (hotkey switch, smart switch, …).
    private func reloadFromEngine() {
        suppressCallbacks = true
        if isVietnamese != (vLanguage == 1) { isVietnamese = vLanguage == 1 }
        if inputType != Int(vInputType) { inputType = Int(vInputType) }
        if codeTable != Int(vCodeTable) { codeTable = Int(vCodeTable) }
        suppressCallbacks = false
    }

    private func set(_ key: String, _ global: inout Int32, _ value: Bool) {
        guard !suppressCallbacks else { return }
        global = value ? 1 : 0
        defaults.set(value ? 1 : 0, forKey: key)
    }

    /// Reset everything to factory defaults.
    func resetToDefaults() {
        let keys = ["InputMethod", "InputType", "CodeTable", "Spelling", "ModernOrthography",
                    "FreeMark", "QuickTelex", "RestoreIfInvalidWord", "FixRecommendBrowser",
                    "vFixChromiumBrowser", "UpperCaseFirstChar", "vTempOffSpelling",
                    "vAllowConsonantZFWJ", "vQuickStartConsonant", "vQuickEndConsonant",
                    "vTempOffOpenKey", "vOtherLanguage", "vFixSpotlight", "UseMacro", "UseMacroInEnglishMode",
                    "vAutoCapsMacro", "UseSmartSwitchKey", "vRememberCode", "SendKeyStepByStep",
                    "vPerformLayoutCompat", "GrayIcon", "vShowIconOnDock", "ShowUIOnStartup",
                    "SwitchKeyStatus"]
        keys.forEach { defaults.removeObject(forKey: $0) }

        suppressCallbacks = true
        isVietnamese = true
        inputType = 0
        codeTable = 0
        switchKeyStatus = Int32(MKEY_DEFAULT_SWITCH_STATUS)
        checkSpelling = true
        modernOrthography = false
        freeMark = false
        quickTelex = false
        restoreIfWrongSpelling = false
        fixRecommendBrowser = true
        fixChromiumBrowser = false
        upperCaseFirstChar = false
        tempOffSpelling = false
        allowZFWJ = false
        quickStartConsonant = false
        quickEndConsonant = false
        tempOffByCommand = false
        otherLanguage = true
        fixSpotlight = true
        useMacro = true
        useMacroInEnglishMode = false
        autoCapsMacro = false
        useSmartSwitchKey = true
        rememberCode = true
        sendKeyStepByStep = false
        performLayoutCompat = false
        grayIcon = true
        showIconOnDock = false
        showUIOnStartup = false
        suppressCallbacks = false

        // push everything into the engine globals in one go
        vLanguage = 1; vInputType = 0; vCodeTable = 0
        vSwitchKeyStatus = Int32(MKEY_DEFAULT_SWITCH_STATUS)
        vCheckSpelling = 1; vUseModernOrthography = 0; vFreeMark = 0; vQuickTelex = 0
        vRestoreIfWrongSpelling = 0; vFixRecommendBrowser = 1; vFixChromiumBrowser = 0
        vUpperCaseFirstChar = 0; vTempOffSpelling = 0; vAllowConsonantZFWJ = 0
        vQuickStartConsonant = 0; vQuickEndConsonant = 0; vTempOffOpenKey = 0
        vOtherLanguage = 1; vFixSpotlight = 1; vUseMacro = 1; vUseMacroInEnglishMode = 0; vAutoCapsMacro = 0
        vUseSmartSwitchKey = 1; vRememberCode = 1; vSendKeyStepByStep = 0; vPerformLayoutCompat = 0
        MKBridge.spellCheckingChanged()
        NSApp.setActivationPolicy(.accessory)
    }

    // MARK: Hotkey helpers

    static func hotkeyDescription(_ status: Int32) -> String {
        let value = UInt32(bitPattern: status)
        var parts: [String] = []
        if value & 0x100 != 0 { parts.append("⌃") }
        if value & 0x200 != 0 { parts.append("⌥") }
        if value & 0x400 != 0 { parts.append("⌘") }
        if value & 0x800 != 0 { parts.append("⇧") }
        let char = UInt8((value >> 24) & 0xFF)
        if char != 0xFE {
            if char == 49 || Character(UnicodeScalar(char)) == " " {
                parts.append("Space")
            } else {
                parts.append(String(UnicodeScalar(char)).uppercased())
            }
        }
        return parts.isEmpty ? "—" : parts.joined()
    }
}
