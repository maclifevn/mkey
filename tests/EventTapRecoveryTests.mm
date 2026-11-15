#import <Carbon/Carbon.h>
#import "MKBridge.h"
#include <cassert>
#include <cstdio>

// Compile the real MKBridge with only the OS event-tap functions substituted.
// CF port/source lifetime is real; no keyboard is monitored or synthesized.
static bool secure = false, enabled = false, failCreate = false;
static int creates = 0, initializations = 0, resets = 0, frontChanges = 0, smartChanges = 0;
static CFMachPortRef lastPort = NULL;

extern "C" Boolean TestSecureInput(void) { return secure; }
extern "C" bool TestTapIsEnabled(CFMachPortRef tap) { return enabled; }
extern "C" void TestTapEnable(CFMachPortRef tap, bool value) { enabled = value; }
static void portCallback(CFMachPortRef, void *, CFIndex, void *) {}
extern "C" CFMachPortRef TestTapCreate(CGEventTapLocation, CGEventTapPlacement,
                                      CGEventTapOptions, CGEventMask,
                                      CGEventTapCallBack, void *) {
    ++creates;
    if (failCreate) return NULL;
    CFMachPortContext context = {0, NULL, NULL, NULL, NULL};
    lastPort = CFMachPortCreate(kCFAllocatorDefault, portCallback, &context, NULL);
    return lastPort;
}

extern "C" {
    void MKEngineInit(void) { ++initializations; }
    CGEventRef MKEngineCallback(CGEventTapProxy, CGEventType, CGEventRef event, void *) { return event; }
    void RequestNewSession(void) {}
    void MKResetAfterInputInterruption(void) { ++resets; }
    void OnActiveAppChanged(void) { ++smartChanges; }
    void MKFrontMostAppChanged(void) { ++frontChanges; }
    void MKReloadExcludedApps(void) {}
    void OnTableCodeChange(void) {}
    void OnInputMethodChanged(void) {}
    void OnSpellCheckingChanged(void) {}
    NSString *ConvertUtil(NSString *text) { return text; }
    void MKSetEngineSuspended(bool) {}
    void MKReEnableEventTap(void);
}

int main() {
    @autoreleasepool {
        int checks = 0;
        auto check = [&](bool condition) { assert(condition); ++checks; };
        secure = true;
        [MKBridge prepareEngine];
        check(![MKBridge startEventTap] && creates == 0 && initializations == 1);
        check(![MKBridge recoverEventTap] && resets == 0);

        secure = false;
        check([MKBridge startEventTap] && [MKBridge isEventTapRunning]);
        check(initializations == 1 && creates == 1 && resets == 1 && frontChanges == 1);
        enabled = false;
        check(![MKBridge isEventTapRunning]);
        check([MKBridge recoverEventTap] && creates == 1 && resets == 2);

        secure = true;
        enabled = false;
        MKReEnableEventTap();
        check(!enabled && ![MKBridge recoverEventTap] && resets == 2);
        secure = false;
        vUseSmartSwitchKey = 0;
        const int oldSmartChanges = smartChanges;
        check([MKBridge recoverEventTap] && smartChanges == oldSmartChanges);
        vUseSmartSwitchKey = 1;
        check([MKBridge recoverEventTap] && smartChanges == oldSmartChanges + 1);

        CFMachPortInvalidate(lastPort);
        check(![MKBridge isEventTapRunning]);
        check([MKBridge recoverEventTap] && creates == 2 && initializations == 1);
        check([MKBridge stopEventTap] && ![MKBridge isEventTapRunning]);
        check([MKBridge stopEventTap]);
        failCreate = true;
        check(![MKBridge recoverEventTap] && ![MKBridge isEventTapRunning]);
        failCreate = false;
        check([MKBridge recoverEventTap] && initializations == 1);
        [MKBridge stopEventTap];
        std::printf("PASS: %d event tap lifecycle checks\n", checks);
    }
}
