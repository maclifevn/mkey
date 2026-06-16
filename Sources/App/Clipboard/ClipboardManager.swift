//
//  ClipboardManager.swift
//  mkey
//
//  Clipboard history: polls NSPasteboard for new text *and images*, keeps a
//  capped ring buffer, persists it, and exposes a global hotkey to open the
//  picker. Images are stored as PNG files in Application Support; text and
//  metadata live in UserDefaults. Entirely separate from the engine.
//

import AppKit
import Carbon.HIToolbox
import Combine

struct ClipItem: Identifiable, Codable, Equatable {
    let id: UUID
    let isImage: Bool
    let text: String        // text content, or a label like "Hình ảnh 1920×1080"
    let imageFile: String?   // PNG filename (in the clipboard dir) for image items
    let date: Date           // when it was captured
    let sourceApp: String?   // app that owned the clipboard at capture time

    init(text: String, source: String?) {
        id = UUID(); isImage = false; self.text = text; imageFile = nil; date = Date(); sourceApp = source
    }
    init(imageFile: String, label: String, source: String?) {
        id = UUID(); isImage = true; text = label; self.imageFile = imageFile; date = Date(); sourceApp = source
    }

    // Custom decode keeps backward compatibility with items saved before
    // date/sourceApp existed.
    enum CodingKeys: String, CodingKey { case id, isImage, text, imageFile, date, sourceApp }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        isImage = try c.decode(Bool.self, forKey: .isImage)
        text = try c.decode(String.self, forKey: .text)
        imageFile = try c.decodeIfPresent(String.self, forKey: .imageFile)
        date = try c.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        sourceApp = try c.decodeIfPresent(String.self, forKey: .sourceApp)
    }
}

@MainActor
final class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()

    // ⌃V default: keycode V (9), control bit (0x100), display char 'v' (0x76)
    static let defaultHotKey: Int32 = 0x7600_0109
    private static let maxImageBytes = 12 * 1024 * 1024

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
            trim()
        }
    }

    @Published private(set) var items: [ClipItem] = []

    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?
    private let hotKeyMonitor = GlobalHotKey()
    private let picker = ClipboardPicker()
    private var ignoreNextChange = false
    private let imageDir: URL

    private init() {
        defaults.register(defaults: [
            "clipboardHistoryEnabled": true,
            "clipboardMaxItems": 30,
        ])
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        imageDir = appSupport.appendingPathComponent("MKey/clipboard", isDirectory: true)
        try? FileManager.default.createDirectory(at: imageDir, withIntermediateDirectories: true)

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

    func imageURL(for item: ClipItem) -> URL? {
        guard let file = item.imageFile else { return nil }
        return imageDir.appendingPathComponent(file)
    }

    // MARK: Lifecycle

    func startIfEnabled() { if enabled { start() } }

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

        let source = NSWorkspace.shared.frontmostApplication?.localizedName
        if let text = pasteboard.string(forType: .string), !text.isEmpty {
            addText(text, source: source)
        } else if let png = currentImagePNG() {
            addImage(png, source: source)
        }
    }

    /// Skip password managers and apps that mark content as concealed/transient.
    private func isSensitive() -> Bool {
        guard let types = pasteboard.types else { return false }
        let names = types.map { $0.rawValue }
        let blocked = ["org.nspasteboard.ConcealedType",
                       "org.nspasteboard.TransientType",
                       "com.agilebits.onepassword",
                       "com.apple.is-sensitive"]
        return names.contains { blocked.contains($0) }
    }

    private func currentImagePNG() -> Data? {
        if let png = pasteboard.data(forType: .png) { return png }
        if let tiff = pasteboard.data(forType: .tiff),
           let rep = NSBitmapImageRep(data: tiff) {
            return rep.representation(using: .png, properties: [:])
        }
        return nil
    }

    // MARK: Mutations

    private func addText(_ text: String, source: String?) {
        var next = items.filter { $0.isImage || $0.text != text } // dedupe identical text
        next.insert(ClipItem(text: text, source: source), at: 0)
        applyTrimmed(next)
    }

    private func addImage(_ png: Data, source: String?) {
        guard png.count <= ClipboardManager.maxImageBytes else { return }
        let filename = "\(UUID().uuidString).png"
        let url = imageDir.appendingPathComponent(filename)
        do { try png.write(to: url) } catch { return }

        let label: String
        if let rep = NSBitmapImageRep(data: png) {
            label = "Hình ảnh \(rep.pixelsWide)×\(rep.pixelsHigh)"
        } else {
            label = "Hình ảnh"
        }
        var next = items
        next.insert(ClipItem(imageFile: filename, label: label, source: source), at: 0)
        applyTrimmed(next)
    }

    /// Re-add an existing item to the top (after the user pastes it).
    private func promote(_ item: ClipItem) {
        var next = items.filter { $0.id != item.id }
        next.insert(item, at: 0)
        items = next
        persistItems()
    }

    private func applyTrimmed(_ newItems: [ClipItem]) {
        var next = newItems
        if next.count > maxItems {
            let dropped = next.suffix(next.count - maxItems)
            deleteImageFiles(of: dropped)
            next = Array(next.prefix(maxItems))
        }
        items = next
        persistItems()
    }

    private func trim() {
        guard items.count > maxItems else { return }
        deleteImageFiles(of: items.suffix(items.count - maxItems))
        items = Array(items.prefix(maxItems))
        persistItems()
    }

    func clear() {
        deleteImageFiles(of: items)
        items = []
        persistItems()
    }

    func remove(_ item: ClipItem) {
        deleteImageFiles(of: [item])
        items.removeAll { $0.id == item.id }
        persistItems()
    }

    private func deleteImageFiles<S: Sequence>(of seq: S) where S.Element == ClipItem {
        for item in seq {
            if let url = imageURL(for: item) { try? FileManager.default.removeItem(at: url) }
        }
    }

    // MARK: Picker

    func togglePicker() {
        guard enabled else { return }
        picker.toggle(manager: self)
    }

    /// Put `item` on the clipboard and paste it into the previously focused app.
    func paste(_ item: ClipItem, into previousApp: NSRunningApplication?) {
        ignoreNextChange = true
        pasteboard.clearContents()
        if item.isImage, let url = imageURL(for: item), let image = NSImage(contentsOf: url) {
            pasteboard.writeObjects([image])
        } else {
            pasteboard.setString(item.text, forType: .string)
        }
        lastChangeCount = pasteboard.changeCount
        promote(item)

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
        // keep only items whose backing image file still exists
        items = decoded.prefix(maxItems).filter { item in
            guard item.isImage else { return true }
            guard let url = imageURL(for: item) else { return false }
            return FileManager.default.fileExists(atPath: url.path)
        }
    }

    private func persistItems() {
        if let data = try? JSONEncoder().encode(items) {
            defaults.set(data, forKey: itemsKey)
        }
    }
}
