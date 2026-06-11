//
//  HotkeyEditor.swift
//  mkey
//
//  Shared editor row for the hotkey bitfields (language switch & quick
//  convert): modifier toggle buttons + key recorder + live preview badge.
//

import SwiftUI

struct HotkeyEditor: View {
    @Binding var status: Int32

    private func modifierBinding(_ mask: Int32) -> Binding<Bool> {
        Binding {
            status & mask != 0
        } set: { on in
            if on { status |= mask } else { status &= ~mask }
        }
    }

    private var keyCode: Binding<UInt8> {
        Binding {
            UInt8(truncatingIfNeeded: status)
        } set: { code in
            status = (status & ~0xFF) | Int32(code)
        }
    }

    private var displayChar: Binding<UInt8> {
        Binding {
            UInt8(truncatingIfNeeded: status >> 24)
        } set: { char in
            status = (status & 0x00FF_FFFF) | (Int32(char) << 24)
        }
    }

    var body: some View {
        LabeledContent("Tổ hợp phím") {
            HStack(spacing: 6) {
                Toggle("⌃", isOn: modifierBinding(0x100)).help("Control")
                Toggle("⌥", isOn: modifierBinding(0x200)).help("Option")
                Toggle("⌘", isOn: modifierBinding(0x400)).help("Command")
                Toggle("⇧", isOn: modifierBinding(0x800)).help("Shift")
                KeyRecorderField(keyCode: keyCode, displayChar: displayChar)

                Text(AppState.hotkeyDescription(status))
                    .font(.callout.weight(.semibold).monospaced())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(.quaternary.opacity(0.6), in: Capsule())
                    .padding(.leading, 4)
            }
            .toggleStyle(.button)
            .buttonStyle(.bordered)
        }
    }
}
