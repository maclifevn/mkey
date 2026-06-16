//
//  ClipboardManager.swift
//  mkey
//
//  Clipboard history: polls NSPasteboard for new text, keeps a capped ring
//  buffer, persists it, and exposes a global hotkey to open the picker.
//  Entirely separate from the Vietnamese engine.
//

import AppKit
import Carbon.HIToolbox
import Combine

struct ClipItem: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    init(text: String) { self.id = UUID(); self.text = text }
}

@MainActor
final class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()

    // ⌃V default: keycode V (9), control bit (0x100), display char 'v' (0x76)
    static let defaultHotKey: Int32 = 0x7600_0109

    private let defaults = UserDefaults.standard
    private let itemsKey = "clipboardItems"

    @Published var enabled: Bool {
        didSet {
            guard oldValue != enabled else { return }
            defaults.set(enabled, forKey: "clipboardHistoryEnabled")
            enabled ? start() : stop()
        }
    }

    @Published var hotKey: Int32 {
        didSet {
            guard oldValue != hotKey else { return }
            defaults.set(Int(hotKey), forKey: "clipboardHotKey")
            updateHotKeyRegistration()
        }
    }

    @Published var maxItems: Int {
        didSet {
            guard oldValue != maxItems else { return }
            defaults.set(maxItems, forKey: "clipboardMaxItems")
            if items.count > maxItems {
                items = Array(items.prefix(maxItems))
                persistItems()
            }
        }
    }

    @Published private(set) var items: [ClipItem] = []

    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?
    private let hotKeyMonitor = GlobalHotKey()
    private let picker = ClipboardPicker()
    private var ignoreNextChange = false

    private init() {
        defaults.register(defaults: [
            "clipboardHistoryEnabled": true,
            "clipboardMaxItems": 30,
        ])
        enabled = defaults.bool(forKey: "clipboardHistoryEnabled")
        maxItems = max(10, min(100, defaults.integer(forKey: "clipboardMaxItems")))
        let savedHotKey = Int32(truncatingIfNeeded: defaults.integer(forKey: "clipboardHotKey"))
        hotKey = savedHotKey == 0 ? ClipboardManager.defaultHotKey : savedHotKey
        lastChangeCount = pasteboard.changeCount
        loadItems()

        hotKeyMonitor.onPressed = { [weak self] in
            Task { @MainActor in self?.togglePicker() }
        }
    }

    // MARK: Lifecycle

    func startIfEnabled() {
        if enabled { start() }
    }

    private func start() {
        updateHotKeyRegistration()
        lastChangeCount = pasteboard.changeCount
        timer?.invalidate()
        let timer = Timer(timeInterval: 0.4, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.poll() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func stop() {
        timer?.invalidate()
        timer = nil
        hotKeyMonitor.unregister()
        picker.close()
    }

    private func updateHotKeyRegistration() {
        guard enabled else { hotKeyMonitor.unregister(); return }
        hotKeyMonitor.register(status: hotKey)
    }

    // MARK: Polling

    private func poll() {
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        if ignoreNextChange { ignoreNextChange = false; return }
        if isSensitive() { return }
        guard let text = pasteboard.string(forType: .string), !text.isEmpty else { return }
        add(text)
    }

    /// Skip password managers and apps that mark content as concealed/transient.
    private func isSensitive() -> Bool {
        guard let types = pasteboard.types else { return false }
        let names = types.map { $0.rawValue }
        let blocked = ["org.nspasteboard.ConcealedType",
                       "org.nspasteboard.TransientType",
                       "com.agilebits.onepassword",
                       "com.apple.is-sensitive"]
        return names.contains { name in blocked.contains(name) }
    }

    private func add(_ text: String) {
        var next = items.filter { $0.text != text }
        next.insert(ClipItem(text: text), at: 0)
        if next.count > maxItems { next = Array(next.prefix(maxItems)) }
        items = next
        persistItems()
    }

    func clear() {
        items = []
        persistItems()
    }

    func remove(_ item: ClipItem) {
        items.removeAll { $0.id == item.id }
        persistItems()
    }

    // MARK: Picker

    func togglePicker() {
        guard enabled else { return }
        picker.toggle(manager: self)
    }

    /// Set clipboard to `text` and paste it into the previously focused app.
    func paste(_ item: ClipItem, into previousApp: NSRunningApplication?) {
        ignoreNextChange = true
        pasteboard.clearContents()
        pasteboard.setString(item.text, forType: .string)
        lastChangeCount = pasteboard.changeCount

        // move the chosen item to the top
        add(item.text)

        previousApp?.activate()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            let src = CGEventSource(stateID: .combinedSessionState)
            let down = CGEvent(keyboardEventSource: src, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true)
            down?.flags = .maskCommand
            let up = CGEvent(keyboardEventSource: src, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
            up?.flags = .maskCommand
            down?.post(tap: .cghidEventTap)
            up?.post(tap: .cghidEventTap)
        }
    }

    // MARK: Persistence

    private func loadItems() {
        guard let data = defaults.data(forKey: itemsKey),
              let decoded = try? JSONDecoder().decode([ClipItem].self, from: data) else { return }
        items = Array(decoded.prefix(maxItems))
    }

    private func persistItems() {
        if let data = try? JSONEncoder().encode(items) {
            defaults.set(data, forKey: itemsKey)
        }
    }
}
