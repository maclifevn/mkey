//
//  ClipboardPicker.swift
//  mkey
//
//  Floating panel that lists clipboard history and pastes the chosen entry
//  back into the app that was focused when the hotkey fired.
//
//  Keyboard navigation is driven by a local NSEvent monitor rather than
//  SwiftUI focus, which is unreliable inside a non-activating panel.
//

import AppKit
import SwiftUI

/// NSPanel that can become key so it receives key events.
private final class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

/// Display + selection state shared between the controller's key monitor and
/// the SwiftUI list.
@MainActor
final class ClipboardPickerModel: ObservableObject {
    @Published var items: [ClipItem] = []
    @Published var selection: Int = 0
}

@MainActor
final class ClipboardPicker {
    private var panel: KeyablePanel?
    private var previousApp: NSRunningApplication?
    private var keyMonitor: Any?
    private let model = ClipboardPickerModel()
    private weak var manager: ClipboardManager?

    var isOpen: Bool { panel != nil }

    func toggle(manager: ClipboardManager) {
        isOpen ? close() : show(manager: manager)
    }

    func show(manager: ClipboardManager) {
        guard !manager.items.isEmpty else { NSSound.beep(); return }
        self.manager = manager
        previousApp = NSWorkspace.shared.frontmostApplication

        model.items = manager.items
        model.selection = 0

        let root = ClipboardPickerView(model: model,
                                       onPick: { [weak self] item in self?.pick(item) })
        let hosting = NSHostingController(rootView: root)
        let panel = KeyablePanel(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 420),
            styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered, defer: false)
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.contentViewController = hosting
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        if let frame = (panel.screen ?? NSScreen.main)?.visibleFrame {
            panel.setFrameOrigin(NSPoint(x: frame.midX - 230, y: frame.midY - 40))
        }

        self.panel = panel
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)

        installKeyMonitor()
    }

    func close() {
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor); self.keyMonitor = nil }
        panel?.orderOut(nil)
        panel = nil
    }

    private func pick(_ item: ClipItem) {
        let prev = previousApp
        close()
        manager?.paste(item, into: prev)
    }

    private func installKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.isOpen else { return event }
            let count = self.model.items.count
            switch event.keyCode {
            case 125: // down
                if count > 0 { self.model.selection = min(count - 1, self.model.selection + 1) }
                return nil
            case 126: // up
                if count > 0 { self.model.selection = max(0, self.model.selection - 1) }
                return nil
            case 36, 76: // return / enter
                if self.model.items.indices.contains(self.model.selection) {
                    self.pick(self.model.items[self.model.selection])
                }
                return nil
            case 53: // escape
                self.close()
                return nil
            case 18...23, 25, 26, 28, 29: // number row 1-9 → quick pick
                if let n = Int(event.charactersIgnoringModifiers ?? ""), n >= 1, n <= count {
                    self.pick(self.model.items[n - 1])
                    return nil
                }
                return event
            default:
                return event
            }
        }
    }
}

private struct ClipboardPickerView: View {
    @ObservedObject var model: ClipboardPickerModel
    let onPick: (ClipItem) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "doc.on.clipboard")
                    .foregroundStyle(.secondary)
                Text("Lịch sử Clipboard")
                    .font(.headline)
                Spacer()
                Text("\(model.items.count) mục")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(Array(model.items.enumerated()), id: \.element.id) { index, item in
                            row(index: index, item: item).id(index)
                        }
                    }
                    .padding(8)
                }
                .onChange(of: model.selection) { _, newValue in
                    withAnimation(.easeOut(duration: 0.1)) { proxy.scrollTo(newValue, anchor: .center) }
                }
            }

            Divider()
            HStack(spacing: 14) {
                hint("↑↓", "Chọn")
                hint("↩", "Dán")
                hint("1–9", "Chọn nhanh")
                hint("esc", "Đóng")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
        }
        .frame(width: 460, height: 420)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func row(index: Int, item: ClipItem) -> some View {
        let isSelected = index == model.selection
        return HStack(alignment: .top, spacing: 10) {
            Text("\(index + 1)")
                .font(.caption.monospaced())
                .foregroundStyle(isSelected ? .white.opacity(0.85) : .secondary)
                .frame(width: 18, alignment: .trailing)
            Text(item.text.trimmingCharacters(in: .whitespacesAndNewlines))
                .lineLimit(2)
                .font(.body)
                .foregroundStyle(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(isSelected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.clear),
                    in: RoundedRectangle(cornerRadius: 7))
        .contentShape(Rectangle())
        .onTapGesture { onPick(item) }
    }

    private func hint(_ key: String, _ label: String) -> some View {
        HStack(spacing: 4) {
            Text(key)
                .font(.caption.monospaced())
                .padding(.horizontal, 5).padding(.vertical, 1)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }
}
