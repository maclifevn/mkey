#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import "MKBridge.h"
#include "Engine.h"
#include <cassert>
#include <cstdio>

extern "C" {
    extern CGEventFlags _flag, _lastFlag;
    extern bool _hasJustUsedHotKey, _mkEngineSuspended;
    extern CFAbsoluteTime _lastKeystrokeTime;
    void MKResetAfterInputInterruption(void);
}

int main() {
    @autoreleasepool {
        // Loads the real engine/hook, but does not install an event tap or post keys.
        [MKBridge prepareEngine];
        vLanguage = 1;
        vCodeTable = 0;
        vCheckSpelling = 0;
        vUseMacro = 0;
        vSetCheckSpelling();
        auto *packet = static_cast<vKeyHookState *>(vKeyInit());
        vKeyHandleEvent(vKeyEvent::Keyboard, vKeyEventState::KeyDown, KEY_A);
        vKeyHandleEvent(vKeyEvent::Keyboard, vKeyEventState::KeyDown, KEY_A);
        assert(packet->code == vWillProcess);
        _flag = _lastFlag = kCGEventFlagMaskControl | kCGEventFlagMaskShift;
        _hasJustUsedHotKey = true;
        _lastKeystrokeTime = 123;
        _mkEngineSuspended = true;
        MKResetAfterInputInterruption();
        assert(_flag == 0 && _lastFlag == 0 && !_hasJustUsedHotKey && _lastKeystrokeTime == 0);
        assert(_mkEngineSuspended && vLanguage == 1 && vCodeTable == 0);
        vKeyHandleEvent(vKeyEvent::Keyboard, vKeyEventState::KeyDown, KEY_A);
        assert(packet->code == vDoNothing);
        vKeyHandleEvent(vKeyEvent::Keyboard, vKeyEventState::KeyDown, KEY_A);
        assert(packet->code == vWillProcess && packet->backspaceCount == 1 && packet->newCharCount == 1);
        std::puts("PASS: real hook resets composition/modifiers and preserves suspension/settings");
    }
}
