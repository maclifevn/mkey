//
//  GlobalHotKey.swift
//  mkey
//
//  A self-contained Carbon global hotkey. Deliberately independent from the
//  engine's CGEventTap so the clipboard feature cannot affect the stable
//  typing/switch/convert hotkeys. Carbon hotkeys are consumed system-wide and
//  do not require Accessibility.
//

import AppKit
import Carbon.HIToolbox

final class GlobalHotKey {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    var onPressed: (() -> Void)?

    /// Map the shared hotkey bitfield (see Engine.h) to Carbon modifier flags.
    static func carbonModifiers(from status: Int32) -> UInt32 {
        let v = UInt32(bitPattern: status)
        var m: UInt32 = 0
        if v & 0x100 != 0 { m |= UInt32(controlKey) }
        if v & 0x200 != 0 { m |= UInt32(optionKey) }
        if v & 0x400 != 0 { m |= UInt32(cmdKey) }
        if v & 0x800 != 0 { m |= UInt32(shiftKey) }
        return m
    }

    static func keyCode(from status: Int32) -> UInt32 {
        UInt32(UInt8(truncatingIfNeeded: status))
    }

    /// (Re)register. Requires a real key (low byte != 0xFE) and at least one
    /// modifier — a bare key would hijack normal typing.
    func register(status: Int32) {
        unregister()
        let code = GlobalHotKey.keyCode(from: status)
        let mods = GlobalHotKey.carbonModifiers(from: status)
        guard code != 0xFE, mods != 0 else { return }

        let hotKeyID = EventHotKeyID(signature: OSType(0x4D4B4559), id: 1) // 'MKEY'
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { (_, _, userData) -> OSStatus in
            guard let userData else { return noErr }
            let me = Unmanaged<GlobalHotKey>.fromOpaque(userData).takeUnretainedValue()
            me.onPressed?()
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &eventHandler)

        RegisterEventHotKey(code, mods, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    func unregister() {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef); self.hotKeyRef = nil }
        if let eventHandler { RemoveEventHandler(eventHandler); self.eventHandler = nil }
    }

    deinit { unregister() }
}
