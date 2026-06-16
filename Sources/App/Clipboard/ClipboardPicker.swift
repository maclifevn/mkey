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

/// Behind-window blur so the picker is genuinely translucent (samples the
/// desktop / windows underneath), unlike SwiftUI's in-app Material.
private struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .popover
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
    }
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
    private var pasting = false
    private let model = ClipboardPickerModel()
    private weak var manager: ClipboardManager?

    var isOpen: Bool { panel != nil }

    func toggle(manager: ClipboardManager) {
        isOpen ? close() : show(manager: manager)
    }

    func show(manager: ClipboardManager) {
        self.manager = manager
        previousApp = NSWorkspace.shared.frontmostApplication

        model.items = manager.items
        model.selection = 0

        let root = ClipboardPickerView(
            model: model,
            imageURL: { [weak manager] item in manager?.imageURL(for: item) },
            onPick: { [weak self] item in self?.pick(item) },
            onRemove: { [weak self] item in
                guard let self else { return }
                self.manager?.remove(item)
                self.model.items = self.manager?.items ?? []
                if self.model.selection >= self.model.items.count {
                    self.model.selection = max(0, self.model.items.count - 1)
                }
            },
            onClear: { [weak self] in
                self?.manager?.clear()
                self?.model.items = []
            },
            onClose: { [weak self] in self?.close() })
        let hosting = NSHostingController(rootView: root)

        // Borderless (no empty title strip), Spotlight-style. The rounded
        // material lives in the SwiftUI content, so the window is transparent.
        // NOT a non-activating panel: the app must become active so SwiftUI
        // renders controls in their active (coloured) state, not greyed out.
        let panel = KeyablePanel(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 420),
            styleMask: [.borderless],
            backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.contentViewController = hosting
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
        let wasOpen = panel != nil
        panel?.orderOut(nil)
        panel = nil
        // we activated MKey to show the panel; hand focus back so the user
        // returns to whatever they were doing (unless a paste will do it)
        if wasOpen, !pasting { previousApp?.activate() }
    }

    private func pick(_ item: ClipItem) {
        let prev = previousApp
        pasting = true
        close()
        pasting = false
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
            case 48, 36, 76: // tab (primary) / return / enter → paste
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
    let imageURL: (ClipItem) -> URL?
    let onPick: (ClipItem) -> Void
    let onRemove: (ClipItem) -> Void
    let onClear: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "doc.on.clipboard")
                    .foregroundStyle(.secondary)
                Text("Lịch sử Clipboard")
                    .font(.headline)
                Spacer()
                if !model.items.isEmpty {
                    Text("\(model.items.count) mục")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button(role: .destructive) {
                        onClear()
                    } label: {
                        Text("Xoá tất cả")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .help("Xoá toàn bộ lịch sử")
                }
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.borderless)
                .help("Đóng (Esc)")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)

            Divider()

            if model.items.isEmpty {
                Spacer()
                VStack(spacing: 10) {
                    Image(systemName: "clipboard")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(.tertiary)
                    Text("Chưa có gì trong Clipboard")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text("Sao chép văn bản hoặc hình ảnh để bắt đầu lưu lịch sử.")
                        .font(.callout)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 30)
                Spacer()
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(Array(model.items.enumerated()), id: \.element.id) { index, item in
                                PickerRow(index: index, item: item,
                                          isSelected: index == model.selection,
                                          imageURL: imageURL,
                                          onPick: { onPick(item) },
                                          onRemove: { onRemove(item) })
                                    .id(index)
                            }
                        }
                        .padding(8)
                    }
                    .onChange(of: model.selection) { _, newValue in
                        withAnimation(.easeOut(duration: 0.1)) { proxy.scrollTo(newValue, anchor: .center) }
                    }
                }
            }

            Divider()
            HStack(spacing: 14) {
                hint("↑↓", "Chọn")
                hint("⇥", "Dán")
                hint("1–9", "Chọn nhanh")
                hint("esc", "Đóng")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
        }
        .frame(width: 460, height: 420)
        // Light behind-window blur softens the content underneath (so it isn't
        // a busy, sharp see-through) while a low tint keeps text readable.
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.45))
        .background(VisualEffectBlur(material: .popover))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.separator, lineWidth: 0.5))
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

private struct PickerRow: View {
    let index: Int
    let item: ClipItem
    let isSelected: Bool
    let imageURL: (ClipItem) -> URL?
    let onPick: () -> Void
    let onRemove: () -> Void
    @State private var hovering = false

    private var subtitle: String {
        let app = item.sourceApp ?? "Khác"
        return "\(app) • \(PickerRow.relativeTime(item.date))"
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Text("\(index + 1)")
                .font(.caption.monospaced())
                .foregroundStyle(isSelected ? .white.opacity(0.85) : .secondary)
                .frame(width: 18, alignment: .trailing)

            if item.isImage, let url = imageURL(item), let nsImage = NSImage(contentsOf: url) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 52, height: 38, alignment: .leading)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(.quaternary))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.isImage ? item.text : item.text.trimmingCharacters(in: .whitespacesAndNewlines))
                    .lineLimit(2)
                    .font(.body)
                    .foregroundStyle(isSelected ? .white : .primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if hovering {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(isSelected ? .white.opacity(0.9) : .secondary)
                }
                .buttonStyle(.plain)
                .help("Xoá mục này")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(isSelected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(hovering ? AnyShapeStyle(.quaternary.opacity(0.4)) : AnyShapeStyle(.clear)),
                    in: RoundedRectangle(cornerRadius: 7))
        .contentShape(Rectangle())
        .onTapGesture { onPick() }
        .onHover { hovering = $0 }
    }

    /// Vietnamese relative time: "Vừa xong", "5 phút trước", "2 giờ trước", …
    static func relativeTime(_ date: Date) -> String {
        let s = Int(Date().timeIntervalSince(date))
        if s < 5 { return "Vừa xong" }
        if s < 60 { return "\(s) giây trước" }
        let m = s / 60
        if m < 60 { return "\(m) phút trước" }
        let h = m / 60
        if h < 24 { return "\(h) giờ trước" }
        let d = h / 24
        if d < 7 { return "\(d) ngày trước" }
        let w = d / 7
        return "\(w) tuần trước"
    }
}
