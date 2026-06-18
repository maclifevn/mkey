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
import UniformTypeIdentifiers
import QuickLookThumbnailing

struct ClipItem: Identifiable, Codable, Equatable {
    let id: UUID
    let isImage: Bool
    let text: String        // text content, or a label like "Hình ảnh 1920×1080"
    let imageFile: String?   // PNG filename (in the clipboard dir) for image items
    let filePath: String?    // original file path of the copied image file
    let date: Date           // when it was captured
    let sourceApp: String?   // app that owned the clipboard at capture time

    init(text: String, source: String?) {
        id = UUID(); isImage = false; self.text = text; imageFile = nil; filePath = nil; date = Date(); sourceApp = source
    }
    init(imageFile: String, label: String, filePath: String? = nil, source: String?) {
        id = UUID(); isImage = true; text = label; self.imageFile = imageFile; self.filePath = filePath; date = Date(); sourceApp = source
    }

    // Custom decode keeps backward compatibility with items saved before
    // date/sourceApp/filePath existed.
    enum CodingKeys: String, CodingKey { case id, isImage, text, imageFile, filePath, date, sourceApp }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        isImage = try c.decode(Bool.self, forKey: .isImage)
        text = try c.decode(String.self, forKey: .text)
        imageFile = try c.decodeIfPresent(String.self, forKey: .imageFile)
        filePath = try c.decodeIfPresent(String.self, forKey: .filePath)
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

    @Published var pinOnTop: Bool {
        didSet {
            guard oldValue != pinOnTop else { return }
            defaults.set(pinOnTop, forKey: "clipboardPickerPinOnTop")
            picker.updatePinOnTop(pinOnTop)
        }
    }

    @Published var autoHide: Bool {
        didSet {
            guard oldValue != autoHide else { return }
            defaults.set(autoHide, forKey: "clipboardPickerAutoHide")
            picker.updateAutoHide(autoHide)
        }
    }

    @Published var hasCustomLayout: Bool = false

    @Published private(set) var items: [ClipItem] = [] {
        didSet {
            picker.updateItems(items)
        }
    }

    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?
    private let hotKeyMonitor = GlobalHotKey()
    private let picker = ClipboardPicker()
    private let imageDir: URL

    private init() {
        defaults.register(defaults: [
            "clipboardHistoryEnabled": true,
            "clipboardMaxItems": 30,
            "clipboardPickerPinOnTop": true,
            "clipboardPickerAutoHide": true,
        ])
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        imageDir = appSupport.appendingPathComponent("MKey/clipboard", isDirectory: true)
        try? FileManager.default.createDirectory(at: imageDir, withIntermediateDirectories: true)

        enabled = defaults.bool(forKey: "clipboardHistoryEnabled")
        maxItems = max(10, min(100, defaults.integer(forKey: "clipboardMaxItems")))
        pinOnTop = defaults.bool(forKey: "clipboardPickerPinOnTop")
        autoHide = defaults.bool(forKey: "clipboardPickerAutoHide")
        let savedHotKey = Int32(truncatingIfNeeded: defaults.integer(forKey: "clipboardHotKey"))
        hotKey = savedHotKey == 0 ? ClipboardManager.defaultHotKey : savedHotKey
        lastChangeCount = pasteboard.changeCount
        loadItems()

        hotKeyMonitor.onPressed = { [weak self] in
            Task { @MainActor in self?.togglePicker() }
        }
        updateCustomLayoutStatus()
    }

    func imageURL(for item: ClipItem) -> URL? {
        guard let file = item.imageFile else { return nil }
        return imageDir.appendingPathComponent(file)
    }

    nonisolated private func generateQuickLookThumbnail(for fileURL: URL, size: CGSize) async -> NSImage? {
        await withCheckedContinuation { continuation in
            let request = QLThumbnailGenerator.Request(
                fileAt: fileURL,
                size: size,
                scale: 2.0,
                representationTypes: .thumbnail
            )
            QLThumbnailGenerator.shared.generateRepresentations(for: request) { (thumbnail, type, error) in
                if let nsImage = thumbnail?.nsImage {
                    continuation.resume(returning: nsImage)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    // MARK: Lifecycle

    func startIfEnabled() { if enabled { start() } }

    private func start() {
        updateHotKeyRegistration()
        lastChangeCount = pasteboard.changeCount
        timer?.invalidate()
        let timer = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
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

    func suspendHotKey() {
        hotKeyMonitor.unregister()
    }

    func resumeHotKey() {
        updateHotKeyRegistration()
    }

    // MARK: Polling

    private func poll() {
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        if isSensitive() { return }

        let source = NSWorkspace.shared.frontmostApplication?.localizedName

        // Check for file URLs from Finder first
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], !urls.isEmpty {
            let fileURL = urls[0]
            let changeCountAtStart = pasteboard.changeCount
            Task.detached(priority: .background) {
                var pngData: Data? = nil
                
                // 1. Try generating a high-fidelity QuickLook thumbnail first
                if let qlImage = await ClipboardManager.shared.generateQuickLookThumbnail(for: fileURL, size: CGSize(width: 120, height: 120)) {
                    if let tiff = qlImage.tiffRepresentation,
                       let rep = NSBitmapImageRep(data: tiff) {
                        pngData = rep.representation(using: .png, properties: [:])
                    }
                }
                
                // 2. If QuickLook fails and it is a standard image, try reading the data directly
                if pngData == nil {
                    if let type = UTType(filenameExtension: fileURL.pathExtension), type.conforms(to: .image) {
                        if let data = try? Data(contentsOf: fileURL), data.count <= ClipboardManager.maxImageBytes {
                            if let rep = NSBitmapImageRep(data: data) {
                                pngData = rep.representation(using: .png, properties: [:])
                            } else {
                                pngData = data
                            }
                        }
                    }
                }
                
                // 3. Fallback to system file/folder icon
                if pngData == nil {
                    let icon = NSWorkspace.shared.icon(forFile: fileURL.path)
                    if let tiff = icon.tiffRepresentation,
                       let rep = NSBitmapImageRep(data: tiff) {
                        pngData = rep.representation(using: .png, properties: [:])
                    }
                }
                
                guard let png = pngData else { return }
                
                await MainActor.run {
                    guard ClipboardManager.shared.pasteboard.changeCount == changeCountAtStart else { return }
                    ClipboardManager.shared.addGeneralFile(png, originalURL: fileURL, source: source)
                }
            }
            return
        }

        if let text = pasteboard.string(forType: .string), !text.isEmpty {
            addText(text, source: source)
            return
        }

        guard let types = pasteboard.types else { return }
        let hasImage = types.contains(.png) || types.contains(.tiff)
        if hasImage {
            var imgData: Data? = nil
            var isPNG = false
            if types.contains(.png), let png = pasteboard.data(forType: .png) {
                imgData = png
                isPNG = true
            } else if types.contains(.tiff), let tiff = pasteboard.data(forType: .tiff) {
                imgData = tiff
                isPNG = false
            }

            guard let data = imgData, data.count <= ClipboardManager.maxImageBytes else { return }
            let changeCountAtStart = pasteboard.changeCount

            Task.detached(priority: .background) {
                let pngToWrite: Data?
                if isPNG {
                    pngToWrite = data
                } else {
                    if let rep = NSBitmapImageRep(data: data) {
                        pngToWrite = rep.representation(using: .png, properties: [:])
                    } else {
                        pngToWrite = nil
                    }
                }

                guard let png = pngToWrite, png.count <= ClipboardManager.maxImageBytes else { return }

                await MainActor.run {
                    guard ClipboardManager.shared.pasteboard.changeCount == changeCountAtStart else { return }
                    ClipboardManager.shared.addImage(png, source: source)
                }
            }
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

    // MARK: Mutations

    private func addText(_ text: String, source: String?) {
        var next = items.filter { $0.isImage || $0.text != text } // dedupe identical text
        next.insert(ClipItem(text: text, source: source), at: 0)
        applyTrimmed(next)
    }

    private func addImage(_ png: Data, source: String?) {
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

    private func addGeneralFile(_ png: Data, originalURL: URL, source: String?) {
        let filename = "\(UUID().uuidString).png"
        let url = imageDir.appendingPathComponent(filename)
        do { try png.write(to: url) } catch { return }

        let label: String
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: originalURL.path, isDirectory: &isDir), isDir.boolValue {
            label = "Thư mục: \(originalURL.lastPathComponent)"
        } else if let type = UTType(filenameExtension: originalURL.pathExtension) {
            if type.conforms(to: .image) {
                label = "File ảnh: \(originalURL.lastPathComponent)"
            } else if type.conforms(to: .pdf) {
                label = "File PDF: \(originalURL.lastPathComponent)"
            } else {
                label = "File: \(originalURL.lastPathComponent)"
            }
        } else {
            label = "File: \(originalURL.lastPathComponent)"
        }

        var next = items
        next = next.filter { $0.filePath != originalURL.path }
        next.insert(ClipItem(imageFile: filename, label: label, filePath: originalURL.path, source: source), at: 0)
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

    func resetPickerLayout() {
        defaults.removeObject(forKey: "clipboardPickerWidth")
        defaults.removeObject(forKey: "clipboardPickerHeight")
        defaults.removeObject(forKey: "clipboardPickerX")
        defaults.removeObject(forKey: "clipboardPickerY")
        updateCustomLayoutStatus()
        picker.resetLayout()
    }

    func updateCustomLayoutStatus() {
        let hasWidth = defaults.object(forKey: "clipboardPickerWidth") != nil
        let hasHeight = defaults.object(forKey: "clipboardPickerHeight") != nil
        let hasX = defaults.object(forKey: "clipboardPickerX") != nil
        let hasY = defaults.object(forKey: "clipboardPickerY") != nil
        hasCustomLayout = hasWidth || hasHeight || hasX || hasY
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
        pasteboard.clearContents()
        
        let pbItem = NSPasteboardItem()
        var hasData = false
        var activeFilePath: String? = nil
        
        if let filePath = item.filePath, FileManager.default.fileExists(atPath: filePath) {
            activeFilePath = filePath
        } else if item.isImage, let url = imageURL(for: item) {
            let tempDir = FileManager.default.temporaryDirectory
            let timestamp = Int(Date().timeIntervalSince1970)
            let tempFileURL = tempDir.appendingPathComponent("Anh_Clipboard_\(timestamp).png")
            if let data = try? Data(contentsOf: url), (try? data.write(to: tempFileURL)) != nil {
                activeFilePath = tempFileURL.path
            }
        }
        
        if let filePath = activeFilePath {
            let fileURL = URL(fileURLWithPath: filePath)
            pbItem.setString(fileURL.absoluteString, forType: .fileURL)
            pbItem.setPropertyList([filePath], forType: NSPasteboard.PasteboardType("NSFilenamesPboardType"))
            hasData = true
        }
        
        var isOriginalImage = false
        if let filePath = activeFilePath {
            let fileURL = URL(fileURLWithPath: filePath)
            if let type = UTType(filenameExtension: fileURL.pathExtension) {
                isOriginalImage = type.conforms(to: .image)
            }
        } else {
            isOriginalImage = item.isImage
        }
        
        if isOriginalImage, let url = imageURL(for: item), let data = try? Data(contentsOf: url) {
            pbItem.setData(data, forType: .png)
            if let image = NSImage(data: data), let tiffData = image.tiffRepresentation {
                pbItem.setData(tiffData, forType: .tiff)
            }
            hasData = true
        }
        
        if hasData {
            pasteboard.writeObjects([pbItem])
        } else {
            pasteboard.setString(item.text, forType: .string)
        }
        
        lastChangeCount = pasteboard.changeCount
        promote(item)

        previousApp?.activate(options: .activateIgnoringOtherApps)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
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
