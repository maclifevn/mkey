//
//  HotkeyEditor.swift
//  mkey
//
//  Shared editor row for the hotkey bitfields (language switch & quick
//  convert): modifier toggle buttons + key recorder + live preview badge.
//

import SwiftUI
import AppKit

struct HotkeyEditor: View {
    @Binding var status: Int32
    /// Whether a modifier-only shortcut (e.g. ⌃⇧ with no letter) is valid.
    /// The language-switch & quick-convert hotkeys are matched by the engine's
    /// event tap and support this; the clipboard hotkey uses a Carbon hotkey
    /// that requires a real keycode, so it must pass `false`.
    var allowsModifierOnly: Bool = true
    @State private var isRecording = false
    @State private var activeModifiers: Int32 = 0

    private var hasHotkey: Bool {
        let value = UInt32(bitPattern: status)
        return (value & ~0x8000) != 0xFE0000FE
    }

    private var hotkeyParts: [String] {
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
        return parts
    }

    private var activeModifiersParts: [String] {
        var parts: [String] = []
        if activeModifiers & 0x100 != 0 { parts.append("⌃") }
        if activeModifiers & 0x200 != 0 { parts.append("⌥") }
        if activeModifiers & 0x400 != 0 { parts.append("⌘") }
        if activeModifiers & 0x800 != 0 { parts.append("⇧") }
        return parts
    }

    var body: some View {
        LabeledContent("Tổ hợp phím") {
            HStack(spacing: 8) {
                Button {
                    activeModifiers = 0
                    isRecording = true
                } label: {
                    HStack(spacing: 6) {
                        if isRecording {
                            let parts = activeModifiersParts
                            if parts.isEmpty {
                                Text("Nhấn tổ hợp phím...")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(parts, id: \.self) { part in
                                    KeycapView(text: part)
                                }
                                Text("...")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            let parts = hotkeyParts
                            if parts.isEmpty {
                                Text("Chưa đặt")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(parts, id: \.self) { part in
                                    KeycapView(text: part)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isRecording ? Color.accentColor.opacity(0.12) : Color(nsColor: .controlBackgroundColor).opacity(0.35))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isRecording ? Color.accentColor : Color(nsColor: .separatorColor), lineWidth: isRecording ? 1.5 : 0.8)
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .background(
                    HotkeyRecorderRepresentable(
                        isRecording: $isRecording,
                        status: $status,
                        activeModifiers: $activeModifiers,
                        allowsModifierOnly: allowsModifierOnly
                    )
                    .allowsHitTesting(false)
                )

                if !isRecording && hasHotkey {
                    Button {
                        let beep = status & 0x8000
                        status = beep | Int32(bitPattern: 0xFE0000FE)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .imageScale(.small)
                    }
                    .buttonStyle(.plain)
                    .help("Xóa phím tắt")
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .animation(.easeOut(duration: 0.12), value: isRecording)
        }
    }
}

struct KeycapView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color(nsColor: .controlColor))
                    .shadow(color: .black.opacity(0.12), radius: 1, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
            )
            .foregroundColor(.primary)
    }
}

private struct HotkeyRecorderRepresentable: NSViewRepresentable {
    @Binding var isRecording: Bool
    @Binding var status: Int32
    @Binding var activeModifiers: Int32
    let allowsModifierOnly: Bool

    func makeNSView(context: Context) -> NSView { NSView() }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.isRecording = isRecording
        context.coordinator.startOrStopMonitor()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator {
        var parent: HotkeyRecorderRepresentable
        var isRecording = false
        private var monitor: Any?
        // Highest modifier set seen while recording (union across the sequence
        // of flagsChanged events) and whether a shortcut has been committed —
        // used to capture modifier-only shortcuts on release without racing the
        // modifier+key path.
        private var peakModifiers: Int32 = 0
        private var committed = false

        init(parent: HotkeyRecorderRepresentable) {
            self.parent = parent
        }

        func startOrStopMonitor() {
            if isRecording, monitor == nil {
                peakModifiers = 0
                committed = false
                Task { @MainActor in
                    MKBridge.setEngineSuspended(true)
                    ClipboardManager.shared.suspendHotKey()
                }

                monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged, .leftMouseDown]) { [weak self] event in
                    guard let self, self.isRecording else { return event }

                    if event.type == .leftMouseDown {
                        Task { @MainActor in
                            self.parent.isRecording = false
                        }
                        return event
                    } else if event.type == .flagsChanged {
                        let flags = event.modifierFlags
                        var mods: Int32 = 0
                        if flags.contains(.control) { mods |= 0x100 }
                        if flags.contains(.option) { mods |= 0x200 }
                        if flags.contains(.command) { mods |= 0x400 }
                        if flags.contains(.shift) { mods |= 0x800 }

                        if mods != 0 {
                            self.peakModifiers |= mods
                            Task { @MainActor in self.parent.activeModifiers = mods }
                        } else {
                            // All modifiers released with no regular key pressed:
                            // capture a modifier-only shortcut (⌃⇧, ⌃⌥, …) when
                            // allowed and at least two modifiers were held. This
                            // matches how the engine detects a modifier-only
                            // switch key (on the flags-released event).
                            let peak = self.peakModifiers
                            if self.parent.allowsModifierOnly, !self.committed,
                               (peak & 0xF00).nonzeroBitCount >= 2 {
                                self.committed = true
                                Task { @MainActor in
                                    let beep = self.parent.status & 0x8000
                                    self.parent.status = beep | peak | Int32(bitPattern: 0xFE0000FE)
                                    self.parent.isRecording = false
                                }
                            } else {
                                Task { @MainActor in self.parent.activeModifiers = 0 }
                            }
                        }
                        return event
                    } else if event.type == .keyDown {
                        let code = event.keyCode

                        // Escape cancels
                        if code == 53 {
                            self.committed = true
                            Task { @MainActor in
                                self.parent.isRecording = false
                            }
                            return nil
                        }

                        // Delete/Backspace clears
                        if code == 51 || code == 117 {
                            self.committed = true
                            Task { @MainActor in
                                let beep = self.parent.status & 0x8000
                                self.parent.status = beep | Int32(bitPattern: 0xFE0000FE)
                                self.parent.isRecording = false
                            }
                            return nil
                        }

                        // Return/Enter confirms a modifier-only shortcut (where
                        // allowed); it is never recorded as a character key.
                        if code == 36 || code == 76 {
                            if self.parent.allowsModifierOnly, self.parent.activeModifiers != 0 {
                                self.committed = true
                                let mods = self.parent.activeModifiers
                                Task { @MainActor in
                                    let beep = self.parent.status & 0x8000
                                    self.parent.status = beep | mods | Int32(bitPattern: 0xFE0000FE)
                                    self.parent.isRecording = false
                                }
                            }
                            return nil
                        }

                        // Character keys
                        var displayChar: UInt8 = 0xFE
                        if code == 49 {
                            displayChar = 32
                        } else if let chars = event.characters, let first = chars.utf8.first, code < 0xFE {
                            displayChar = first
                        } else {
                            return event
                        }

                        self.committed = true
                        let finalModifiers = self.parent.activeModifiers
                        let finalKeyCode = UInt8(truncatingIfNeeded: code)

                        Task { @MainActor in
                            let beep = self.parent.status & 0x8000
                            self.parent.status = beep | finalModifiers | Int32(finalKeyCode) | (Int32(displayChar) << 24)
                            self.parent.isRecording = false
                        }
                        return nil
                    }
                    return event
                }
            } else if !isRecording, let monitor {
                NSEvent.removeMonitor(monitor)
                self.monitor = nil
                Task { @MainActor in
                    MKBridge.setEngineSuspended(false)
                    ClipboardManager.shared.resumeHotKey()
                }
            }
        }

        deinit {
            if let monitor {
                NSEvent.removeMonitor(monitor)
                Task { @MainActor in
                    MKBridge.setEngineSuspended(false)
                    ClipboardManager.shared.resumeHotKey()
                }
            }
        }
    }
}
