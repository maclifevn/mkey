//
//  MKEngineHook.mm
//  mkey
//
//  CGEventTap hook + key synthesis. Adapted from OpenKey's macOS glue
//  (OpenKey.mm, GPLv3, © Tuyen Mai) with the UI dependencies replaced by
//  MKBridge so the SwiftUI layer stays decoupled.
//
#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import <Foundation/Foundation.h>
#include "Engine.h"
#import "MKBridge.h"

#define FRONT_APP [[NSWorkspace sharedWorkspace] frontmostApplication].bundleIdentifier
#define OTHER_CONTROL_KEY (_flag & kCGEventFlagMaskCommand) || (_flag & kCGEventFlagMaskControl) || \
                            (_flag & kCGEventFlagMaskAlternate) || (_flag & kCGEventFlagMaskSecondaryFn) || \
                            (_flag & kCGEventFlagMaskNumericPad) || (_flag & kCGEventFlagMaskHelp)

#define DYNA_DATA(macro, pos) (macro ? pData->macroData[pos] : pData->charData[pos])
#define MAX_UNICODE_STRING  20
#define EMPTY_HOTKEY 0xFE0000FE
#define LOAD_DATA(VAR, KEY) VAR = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@#KEY]

extern "C" void MKReEnableEventTap(void); //implemented in MKBridge.mm

//set by MKBridge while MKey's own text UI (clipboard search) needs raw keys
bool _mkEngineSuspended = false;
extern "C" void MKSetEngineSuspended(bool suspended) { _mkEngineSuspended = suspended; }

extern "C" {
    //app which must sent special empty character
    NSArray* _niceSpaceApp = @[@"com.sublimetext.3",
                               @"com.sublimetext.2",
                             ];

    //app which error with unicode Compound
    NSArray* _unicodeCompoundApp = @[@"com.apple.",
                                     @"com.google.Chrome", @"com.brave.Browser",
                                     @"com.microsoft.edgemac.Dev", @"com.microsoft.edgemac.Beta", @"com.microsoft.Edge.Dev", @"com.microsoft.Edge"];

    //overlay search fields that process input asynchronously: synthesized
    //backspaces race with the live inline completion (the first backspace
    //only clears the selected suggestion), scrambling fast typing. For these
    //apps we bypass key synthesis entirely and edit the focused text field
    //atomically through the Accessibility API.
    //IMPORTANT: Spotlight is a non-activating overlay panel - it is usually
    //NOT the frontmostApplication while its window is up. Detection must go
    //through the AX focused element's owning process instead.
    NSArray* _slowPathApp = @[@"com.apple.Spotlight",
                              @"com.apple.launchpad.launcher",
                              @"com.raycast.macos",
                              @"com.runningwithcrayons.Alfred"];

    AXUIElementRef _axSystemWide = NULL;
    AXUIElementRef _axCachedFocused = NULL;
    bool _axCachedIsSlow = false;
    bool _axCachedIsIncluded = false;
    CFAbsoluteTime _axCacheTime = 0;
    pid_t _axLoggedPid = 0;
    CFAbsoluteTime _lastKeystrokeTime = 0;
    bool _cachedIsEnglishLayout = true;

    void MKUpdateInputSourceCache() {
        TISInputSourceRef isource = TISCopyCurrentKeyboardInputSource();
        if (isource != NULL) {
            CFArrayRef languages = (CFArrayRef)TISGetInputSourceProperty(isource, kTISPropertyInputSourceLanguages);
            if (languages != NULL && CFArrayGetCount(languages) > 0) {
                CFStringRef langRef = (CFStringRef)CFArrayGetValueAtIndex(languages, 0);
                if (langRef != NULL) {
                    NSString *currentLanguage = (__bridge NSString *)langRef;
                    _cachedIsEnglishLayout = [currentLanguage isLike:@"en"];
                }
            }
            CFRelease(isource);
        }
    }

    void MKInputSourceChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
        MKUpdateInputSourceCache();
    }

    void AXInvalidateFocusCache() {
        if (_axCachedFocused) { CFRelease(_axCachedFocused); _axCachedFocused = NULL; }
        _axCachedIsSlow = false;
        _axCachedIsIncluded = false;
        _axCacheTime = 0;
    }

    bool AXAppIsIncluded(NSString* bid) {
        if (bid == nil)
            return false;
        NSArray* includedApps = [[NSUserDefaults standardUserDefaults] stringArrayForKey:@"axIncludeApps"];
        for (NSString* included in includedApps) {
            if ([bid isEqualToString:included] || [bid hasPrefix:included]) {
                return true;
            }
        }
        return false;
    }

    //look up the AX-focused element and whether it belongs to a slow-path app;
    //cached so fast typing costs only one IPC lookup per burst.
    //We skip updating the cache if the user is currently typing continuously
    //(keystrokes less than 0.5s apart) or if the cache is less than 2.0s old.
    void AXRefreshFocusCache() {
        CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
        if (_axCacheTime != 0 && ((now - _axCacheTime) < 2.0 || (now - _lastKeystrokeTime) < 0.5))
            return;
        AXInvalidateFocusCache();
        _axCacheTime = now;
        if (_axSystemWide == NULL)
            _axSystemWide = AXUIElementCreateSystemWide();
        AXUIElementRef focused = NULL;
        if (AXUIElementCopyAttributeValue(_axSystemWide, kAXFocusedUIElementAttribute, (CFTypeRef*)&focused) != kAXErrorSuccess || focused == NULL)
            return;
        _axCachedFocused = focused;
        pid_t pid = 0;
        if (AXUIElementGetPid(focused, &pid) == kAXErrorSuccess) {
            NSString* bid = [NSRunningApplication runningApplicationWithProcessIdentifier:pid].bundleIdentifier;
            _axCachedIsSlow = (bid != nil) && [_slowPathApp containsObject:bid];
            _axCachedIsIncluded = AXAppIsIncluded(bid);
            
            if (_axCachedIsSlow && _axLoggedPid != pid) {
                NSLog(@"mkey: AX direct-edit path active for %@ (pid %d)", bid, pid);
                _axLoggedPid = pid;
            }
        }
    }

    bool AXSlowPathActive() {
        if (vCodeTable != 0)
            return false;
        AXRefreshFocusCache();
        if (!vUseAXReplacement)
            return false;
        if (_axCachedIsIncluded)
            return _axCachedFocused != NULL;
        if (!vFixSpotlight)
            return false;
        return _axCachedIsSlow;
    }

    CGEventSourceRef myEventSource = NULL;
    vKeyHookState* pData;
    CGEventRef eventBackSpaceDown;
    CGEventRef eventBackSpaceUp;
    UniChar _newChar, _newCharHi;
    CGEventRef _newEventDown, _newEventUp;
    CGKeyCode _keycode;
    CGEventFlags _flag, _lastFlag = 0, _privateFlag;
    CGEventTapProxy _proxy;

    Uint16 _newCharString[MAX_UNICODE_STRING];
    Uint16 _newCharSize;
    bool _willContinuteSending = false;
    bool _willSendControlKey = false;

    vector<Uint16> _syncKey;

    Uint16 _uniChar[2];
    int _i, _j, _k;
    Uint32 _tempChar;
    bool _hasJustUsedHotKey = false;

    int _languageTemp = 0; //use for smart switch key
    vector<Byte> savedSmartSwitchKeyData; //use for smart switch key

    NSString* _frontMostApp = @"UnknownApp";

    /**
     * Atomically replace `deleteCount` characters before the caret (plus any
     * selected inline-completion text) with `insert`, by driving the cached
     * AX-focused element directly. Two strategies:
     *   1. set AXSelectedTextRange then AXSelectedText (clean, most fields)
     *   2. rewrite the whole AXValue and restore the caret (stubborn fields)
     * Returns false when neither works — caller falls back to key events.
     */
    bool AXReplaceTextDirect(long deleteCount, NSString* insert) {
        AXUIElementRef focused = _axCachedFocused;
        if (focused == NULL)
            return false;

        AXValueRef rangeVal = NULL;
        AXError err = AXUIElementCopyAttributeValue(focused, kAXSelectedTextRangeAttribute, (CFTypeRef*)&rangeVal);
        if (err != kAXErrorSuccess || rangeVal == NULL) {
            NSLog(@"mkey: AX get selected range failed (%d)", err);
            AXInvalidateFocusCache();
            return false;
        }
        CFRange sel = CFRangeMake(0, 0);
        bool gotRange = AXValueGetValue(rangeVal, (AXValueType)kAXValueCFRangeType, &sel);
        CFRelease(rangeVal);
        if (!gotRange || sel.location < deleteCount) {
            NSLog(@"mkey: AX range unusable (loc=%ld len=%ld del=%ld)", sel.location, sel.length, deleteCount);
            return false;
        }
        //extend over the selected inline completion (sel.length) so it is
        //wiped together with the characters being recomposed
        CFRange replaceRange = CFRangeMake(sel.location - deleteCount, deleteCount + sel.length);

        //strategy 1: selection-based replacement
        AXValueRef newRangeVal = AXValueCreate((AXValueType)kAXValueCFRangeType, &replaceRange);
        err = AXUIElementSetAttributeValue(focused, kAXSelectedTextRangeAttribute, newRangeVal);
        CFRelease(newRangeVal);
        if (err == kAXErrorSuccess) {
            err = AXUIElementSetAttributeValue(focused, kAXSelectedTextAttribute, (__bridge CFTypeRef)insert);
            if (err == kAXErrorSuccess)
                return true;
        }
        NSLog(@"mkey: AX selection replace failed (%d), trying full-value replace", err);

        //strategy 2: rewrite the whole value
        CFTypeRef valueRef = NULL;
        err = AXUIElementCopyAttributeValue(focused, kAXValueAttribute, &valueRef);
        if (err != kAXErrorSuccess || valueRef == NULL) {
            NSLog(@"mkey: AX get value failed (%d)", err);
            AXInvalidateFocusCache();
            return false;
        }
        if (CFGetTypeID(valueRef) != CFStringGetTypeID()) {
            CFRelease(valueRef);
            NSLog(@"mkey: AX value is not a string");
            return false;
        }
        NSString* value = (__bridge_transfer NSString*)valueRef;
        if ((NSUInteger)(replaceRange.location + replaceRange.length) > value.length) {
            NSLog(@"mkey: AX replace range out of bounds (%ld+%ld > %lu)",
                  replaceRange.location, replaceRange.length, (unsigned long)value.length);
            return false;
        }
        NSString* newValue = [value stringByReplacingCharactersInRange:NSMakeRange(replaceRange.location, replaceRange.length)
                                                            withString:insert];
        err = AXUIElementSetAttributeValue(focused, kAXValueAttribute, (__bridge CFTypeRef)newValue);
        if (err != kAXErrorSuccess) {
            NSLog(@"mkey: AX set value failed (%d)", err);
            AXInvalidateFocusCache();
            return false;
        }
        CFRange caret = CFRangeMake(replaceRange.location + (long)insert.length, 0);
        AXValueRef caretVal = AXValueCreate((AXValueType)kAXValueCFRangeType, &caret);
        AXUIElementSetAttributeValue(focused, kAXSelectedTextRangeAttribute, caretVal);
        CFRelease(caretVal);
        return true;
    }

    /**
     * AX-based replacement for SendBackspace+SendNewCharString, Unicode code
     * table only. Returns false when the event path must be used instead.
     */
    bool TryAXProcessKey() {
        Uint16 buf[MAX_BUFF * 2];
        int n = 0;
        for (int k = pData->newCharCount - 1; k >= 0; k--) {
            Uint32 t = pData->charData[k];
            Uint16 ch;
            if (t & PURE_CHARACTER_MASK) {
                ch = (Uint16)t;
            } else if (!(t & CHAR_CODE_MASK)) {
                ch = keyCodeToCharacter(t);
                if (ch == 0) return false;
            } else {
                ch = (Uint16)t;
            }
            buf[n++] = ch;
        }
        if (pData->code == vRestore || pData->code == vRestoreAndStartNewSession) {
            Uint16 keyChar = keyCodeToCharacter(_keycode | ((_flag & kCGEventFlagMaskAlphaShift) || (_flag & kCGEventFlagMaskShift) ? CAPS_MASK : 0));
            if (keyChar == 0)
                return false; //restore ends with a control key (TAB, arrows…) — event path handles that
            buf[n++] = keyChar;
        }
        NSString* replacement = [NSString stringWithCharacters:buf length:n];
        if (!AXReplaceTextDirect(pData->backspaceCount, replacement))
            return false;
        if (pData->code == vRestoreAndStartNewSession)
            startNewSession();
        return true;
    }

    /**
     * AX-based macro expansion (Unicode code table only).
     */
    bool TryAXProcessMacro() {
        Uint16 buf[MAX_BUFF * 4];
        int n = 0;
        for (size_t k = 0; k < pData->macroData.size() && n < MAX_BUFF * 4; k++) {
            Uint32 t = pData->macroData[k];
            Uint16 ch;
            if (t & PURE_CHARACTER_MASK) {
                ch = (Uint16)t;
            } else if (!(t & CHAR_CODE_MASK)) {
                ch = keyCodeToCharacter(t);
                if (ch == 0) return false;
            } else {
                ch = (Uint16)t;
            }
            buf[n++] = ch;
        }
        return AXReplaceTextDirect(pData->backspaceCount, [NSString stringWithCharacters:buf length:n]);
    }


    void MKEngineInit() {
        //load saved data
        vFreeMark = 0;
        LOAD_DATA(vLanguage, InputMethod);
        LOAD_DATA(vInputType, InputType);
        LOAD_DATA(vCodeTable, CodeTable); if (vCodeTable < 0) vCodeTable = 0;
        LOAD_DATA(vCheckSpelling, Spelling);
        LOAD_DATA(vQuickTelex, QuickTelex);
        LOAD_DATA(vUseModernOrthography, ModernOrthography);
        LOAD_DATA(vRestoreIfWrongSpelling, RestoreIfInvalidWord);
        LOAD_DATA(vFixRecommendBrowser, FixRecommendBrowser);
        LOAD_DATA(vUseMacro, UseMacro);
        LOAD_DATA(vUseMacroInEnglishMode, UseMacroInEnglishMode);
        LOAD_DATA(vAutoCapsMacro, vAutoCapsMacro);
        LOAD_DATA(vSendKeyStepByStep, SendKeyStepByStep);
        LOAD_DATA(vUseSmartSwitchKey, UseSmartSwitchKey);
        LOAD_DATA(vUpperCaseFirstChar, UpperCaseFirstChar);

        LOAD_DATA(vTempOffSpelling, vTempOffSpelling);
        LOAD_DATA(vAllowConsonantZFWJ, vAllowConsonantZFWJ);
        LOAD_DATA(vQuickEndConsonant, vQuickEndConsonant);
        LOAD_DATA(vQuickStartConsonant, vQuickStartConsonant);
        LOAD_DATA(vRememberCode, vRememberCode);
        LOAD_DATA(vOtherLanguage, vOtherLanguage);
        LOAD_DATA(vTempOffOpenKey, vTempOffOpenKey);

        LOAD_DATA(vFixChromiumBrowser, vFixChromiumBrowser);
        LOAD_DATA(vPerformLayoutCompat, vPerformLayoutCompat);
        LOAD_DATA(vFixSpotlight, vFixSpotlight);
        LOAD_DATA(vUseAXReplacement, vUseAXReplacement);

        LOAD_DATA(vSwitchKeyStatus, SwitchKeyStatus);
        if (vSwitchKeyStatus == 0)
            vSwitchKeyStatus = MKEY_DEFAULT_SWITCH_STATUS;

        if (myEventSource == NULL) {
            myEventSource = CGEventSourceCreate(kCGEventSourceStatePrivate);
            eventBackSpaceDown = CGEventCreateKeyboardEvent (myEventSource, 51, true);
            eventBackSpaceUp = CGEventCreateKeyboardEvent (myEventSource, 51, false);
        }
        pData = (vKeyHookState*)vKeyInit();

        //init and load macro data
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSData *data = [prefs objectForKey:@"macroData"];
        initMacroMap((Byte*)data.bytes, (int)data.length);

        //init and load smart switch key data
        data = [prefs objectForKey:@"smartSwitchKey"];
        initSmartSwitchKey((Byte*)data.bytes, (int)data.length);

        //init convert tool
        convertToolDontAlertWhenCompleted = ![prefs boolForKey:@"convertToolAlertWhenCompleted"];
        convertToolToAllCaps = [prefs boolForKey:@"convertToolToAllCaps"];
        convertToolToAllNonCaps = [prefs boolForKey:@"convertToolToAllNonCaps"];
        convertToolToCapsFirstLetter = [prefs boolForKey:@"convertToolToCapsFirstLetter"];
        convertToolToCapsEachWord = [prefs boolForKey:@"convertToolToCapsEachWord"];
        convertToolRemoveMark = [prefs boolForKey:@"convertToolRemoveMark"];
        convertToolFromCode = [prefs integerForKey:@"convertToolFromCode"];
        convertToolToCode = [prefs integerForKey:@"convertToolToCode"];
        convertToolHotKey = (int)[prefs integerForKey:@"convertToolHotKey"];
        if (convertToolHotKey == 0) {
            convertToolHotKey = EMPTY_HOTKEY;
        }

        MKUpdateInputSourceCache();

        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            NULL,
            MKInputSourceChangedCallback,
            kTISNotifySelectedKeyboardInputSourceChanged,
            NULL,
            CFNotificationSuspensionBehaviorDeliverImmediately
        );
    }

    void RequestNewSession() {
        AXInvalidateFocusCache();
        //send event signal to Engine
        vKeyHandleEvent(vKeyEvent::Mouse, vKeyEventState::MouseDown, 0);

        if (IS_DOUBLE_CODE(vCodeTable)) { //VNI
            _syncKey.clear();
        }
    }

    void queryFrontMostApp() {
        if ([[[NSWorkspace sharedWorkspace] frontmostApplication].bundleIdentifier compare:[[NSBundle mainBundle] bundleIdentifier]] != 0) {
            _frontMostApp = [[NSWorkspace sharedWorkspace] frontmostApplication].bundleIdentifier;
            if (_frontMostApp == nil)
                _frontMostApp = [[NSWorkspace sharedWorkspace] frontmostApplication].localizedName != nil ?
                [[NSWorkspace sharedWorkspace] frontmostApplication].localizedName : @"UnknownApp";
        }
    }

    NSString* ConvertUtil(NSString* str) {
        return [NSString stringWithUTF8String:convertUtil([str UTF8String]).c_str()];
    }

    BOOL containUnicodeCompoundApp(NSString* topApp) {
        if (topApp == nil) return false;
        for (_j = 0; _j < [_unicodeCompoundApp count]; _j++) {
            if ([topApp hasPrefix:[_unicodeCompoundApp objectAtIndex:_j]] || [[_unicodeCompoundApp objectAtIndex:_j] isEqualToString:topApp])
                return true;
        }
        return false;
    }

    void saveSmartSwitchKeyData() {
        getSmartSwitchKeySaveData(savedSmartSwitchKeyData);
        NSData* _data = [NSData dataWithBytes:savedSmartSwitchKeyData.data() length:savedSmartSwitchKeyData.size()];
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        [prefs setObject:_data forKey:@"smartSwitchKey"];
    }

    void OnActiveAppChanged() { //use for smart switch key
        AXInvalidateFocusCache();
        MKUpdateInputSourceCache();
        queryFrontMostApp();
        _languageTemp = getAppInputMethodStatus(string(_frontMostApp.UTF8String), vLanguage | (vCodeTable << 1));
        if ((_languageTemp & 0x01) != vLanguage) { //for input method
            if (_languageTemp != -1) {
                vLanguage = _languageTemp & 0x01;
                [MKBridge engineDidChangeLanguage:vLanguage];
                startNewSession();
            } else {
                saveSmartSwitchKeyData();
            }
        }
        if (vRememberCode && (_languageTemp >> 1) != vCodeTable) { //for remember table code feature
            if (_languageTemp != -1) {
                [MKBridge engineDidChangeCodeTable:(_languageTemp >> 1)];
            } else {
                saveSmartSwitchKeyData();
            }
        }
    }

    void OnTableCodeChange() {
        onTableCodeChange();
        if (vRememberCode) {
            queryFrontMostApp();
            setAppInputMethodStatus(string(_frontMostApp.UTF8String), vLanguage | (vCodeTable << 1));
            saveSmartSwitchKeyData();
        }
    }

    void OnInputMethodChanged() {
        if (vUseSmartSwitchKey) {
            queryFrontMostApp();
            setAppInputMethodStatus(string(_frontMostApp.UTF8String), vLanguage | (vCodeTable << 1));
            saveSmartSwitchKeyData();
        }
    }

    void OnSpellCheckingChanged() {
        vSetCheckSpelling();
    }

    void InsertKeyLength(const Uint8& len) {
        _syncKey.push_back(len);
    }

    void SendPureCharacter(const Uint16& ch) {
        _newEventDown = CGEventCreateKeyboardEvent(myEventSource, 0, true);
        _newEventUp = CGEventCreateKeyboardEvent(myEventSource, 0, false);
        CGEventKeyboardSetUnicodeString(_newEventDown, 1, &ch);
        CGEventKeyboardSetUnicodeString(_newEventUp, 1, &ch);
        CGEventTapPostEvent(_proxy, _newEventDown);
        CGEventTapPostEvent(_proxy, _newEventUp);
        CFRelease(_newEventDown);
        CFRelease(_newEventUp);
        if (IS_DOUBLE_CODE(vCodeTable)) {
            InsertKeyLength(1);
        }
    }

    void SendKeyCode(Uint32 data) {
        _newChar = (Uint16)data;
        if (!(data & CHAR_CODE_MASK)) {
            if (IS_DOUBLE_CODE(vCodeTable)) //VNI
                InsertKeyLength(1);

            _newEventDown = CGEventCreateKeyboardEvent(myEventSource, _newChar, true);
            _newEventUp = CGEventCreateKeyboardEvent(myEventSource, _newChar, false);
            _privateFlag = CGEventGetFlags(_newEventDown);

            if (data & CAPS_MASK) {
                _privateFlag |= kCGEventFlagMaskShift;
            } else {
                _privateFlag &= ~kCGEventFlagMaskShift;
            }
            _privateFlag |= kCGEventFlagMaskNonCoalesced;

            CGEventSetFlags(_newEventDown, _privateFlag);
            CGEventSetFlags(_newEventUp, _privateFlag);
            CGEventTapPostEvent(_proxy, _newEventDown);
            CGEventTapPostEvent(_proxy, _newEventUp);
        } else {
            if (vCodeTable == 0) { //unicode 2 bytes code
                _newEventDown = CGEventCreateKeyboardEvent(myEventSource, 0, true);
                _newEventUp = CGEventCreateKeyboardEvent(myEventSource, 0, false);
                CGEventKeyboardSetUnicodeString(_newEventDown, 1, &_newChar);
                CGEventKeyboardSetUnicodeString(_newEventUp, 1, &_newChar);
                CGEventTapPostEvent(_proxy, _newEventDown);
                CGEventTapPostEvent(_proxy, _newEventUp);
            } else if (vCodeTable == 1 || vCodeTable == 2 || vCodeTable == 4) { //others such as VNI Windows, TCVN3: 1 byte code
                _newCharHi = HIBYTE(_newChar);
                _newChar = LOBYTE(_newChar);

                _newEventDown = CGEventCreateKeyboardEvent(myEventSource, 0, true);
                _newEventUp = CGEventCreateKeyboardEvent(myEventSource, 0, false);
                CGEventKeyboardSetUnicodeString(_newEventDown, 1, &_newChar);
                CGEventKeyboardSetUnicodeString(_newEventUp, 1, &_newChar);
                CGEventTapPostEvent(_proxy, _newEventDown);
                CGEventTapPostEvent(_proxy, _newEventUp);
                if (_newCharHi > 32) {
                    if (vCodeTable == 2) //VNI
                        InsertKeyLength(2);
                    CFRelease(_newEventDown);
                    CFRelease(_newEventUp);
                    _newEventDown = CGEventCreateKeyboardEvent(myEventSource, 0, true);
                    _newEventUp = CGEventCreateKeyboardEvent(myEventSource, 0, false);
                    CGEventKeyboardSetUnicodeString(_newEventDown, 1, &_newCharHi);
                    CGEventKeyboardSetUnicodeString(_newEventUp, 1, &_newCharHi);
                    CGEventTapPostEvent(_proxy, _newEventDown);
                    CGEventTapPostEvent(_proxy, _newEventUp);
                } else {
                    if (vCodeTable == 2) //VNI
                        InsertKeyLength(1);
                }
            } else if (vCodeTable == 3) { //Unicode Compound
                _newCharHi = (_newChar >> 13);
                _newChar &= 0x1FFF;
                _uniChar[0] = _newChar;
                _uniChar[1] = _newCharHi > 0 ? (_unicodeCompoundMark[_newCharHi - 1]) : 0;
                InsertKeyLength(_newCharHi > 0 ? 2 : 1);
                _newEventDown = CGEventCreateKeyboardEvent(myEventSource, 0, true);
                _newEventUp = CGEventCreateKeyboardEvent(myEventSource, 0, false);
                CGEventKeyboardSetUnicodeString(_newEventDown, (_newCharHi > 0 ? 2 : 1), _uniChar);
                CGEventKeyboardSetUnicodeString(_newEventUp, (_newCharHi > 0 ? 2 : 1), _uniChar);
                CGEventTapPostEvent(_proxy, _newEventDown);
                CGEventTapPostEvent(_proxy, _newEventUp);
            }
        }
        CFRelease(_newEventDown);
        CFRelease(_newEventUp);
    }

    void SendEmptyCharacter() {
        if (IS_DOUBLE_CODE(vCodeTable)) //VNI or Unicode Compound
            InsertKeyLength(1);

        _newChar = 0x202F; //empty char
        if ([_niceSpaceApp containsObject:FRONT_APP]) {
            _newChar = 0x200C; //Unicode character with empty space
        }

        _newEventDown = CGEventCreateKeyboardEvent(myEventSource, 0, true);
        _newEventUp = CGEventCreateKeyboardEvent(myEventSource, 0, false);
        CGEventKeyboardSetUnicodeString(_newEventDown, 1, &_newChar);
        CGEventKeyboardSetUnicodeString(_newEventUp, 1, &_newChar);
        CGEventTapPostEvent(_proxy, _newEventDown);
        CGEventTapPostEvent(_proxy, _newEventUp);
        CFRelease(_newEventDown);
        CFRelease(_newEventUp);
    }

    void SendBackspace() {
        CGEventTapPostEvent(_proxy, eventBackSpaceDown);
        CGEventTapPostEvent(_proxy, eventBackSpaceUp);

        if (IS_DOUBLE_CODE(vCodeTable)) { //VNI or Unicode Compound
            if (_syncKey.back() > 1) {
                if (!(vCodeTable == 3 && containUnicodeCompoundApp(FRONT_APP))) {
                    CGEventTapPostEvent(_proxy, eventBackSpaceDown);
                    CGEventTapPostEvent(_proxy, eventBackSpaceUp);
                }
            }
            _syncKey.pop_back();
        }
    }

    void SendShiftAndLeftArrow() {
        CGEventRef eventVkeyDown = CGEventCreateKeyboardEvent (myEventSource, KEY_LEFT, true);
        CGEventRef eventVkeyUp = CGEventCreateKeyboardEvent (myEventSource, KEY_LEFT, false);
        _privateFlag = CGEventGetFlags(eventVkeyDown);
        _privateFlag |= kCGEventFlagMaskShift;
        CGEventSetFlags(eventVkeyDown, _privateFlag);
        CGEventSetFlags(eventVkeyUp, _privateFlag);

        CGEventTapPostEvent(_proxy, eventVkeyDown);
        CGEventTapPostEvent(_proxy, eventVkeyUp);

        if (IS_DOUBLE_CODE(vCodeTable)) { //VNI or Unicode Compound
            if (_syncKey.back() > 1) {
                if (!(vCodeTable == 3 && containUnicodeCompoundApp(FRONT_APP))) {
                    CGEventTapPostEvent(_proxy, eventVkeyDown);
                    CGEventTapPostEvent(_proxy, eventVkeyUp);
                }
            }
            _syncKey.pop_back();
        }
        CFRelease(eventVkeyDown);
        CFRelease(eventVkeyUp);
    }

    void SendNewCharString(const bool& dataFromMacro=false, const Uint16& offset=0) {
        _j = 0;
        _newCharSize = dataFromMacro ? pData->macroData.size() : pData->newCharCount;
        _willContinuteSending = false;
        _willSendControlKey = false;

        if (_newCharSize > 0) {
            for (_k = dataFromMacro ? offset : pData->newCharCount - 1 - offset;
                 dataFromMacro ? _k < pData->macroData.size() : _k >= 0;
                 dataFromMacro ? _k++ : _k--) {

                if (_j >= 16) {
                    _willContinuteSending = true;
                    break;
                }

                _tempChar = DYNA_DATA(dataFromMacro, _k);
                if (_tempChar & PURE_CHARACTER_MASK) {
                    _newCharString[_j++] = _tempChar;
                    if (IS_DOUBLE_CODE(vCodeTable)) {
                        InsertKeyLength(1);
                    }
                } else if (!(_tempChar & CHAR_CODE_MASK)) {
                    if (IS_DOUBLE_CODE(vCodeTable)) //VNI
                        InsertKeyLength(1);
                    _newCharString[_j++] = keyCodeToCharacter(_tempChar);
                } else {
                    if (vCodeTable == 0) {  //unicode 2 bytes code
                        _newCharString[_j++] = _tempChar;
                    } else if (vCodeTable == 1 || vCodeTable == 2 || vCodeTable == 4) { //others such as VNI Windows, TCVN3: 1 byte code
                        _newChar = _tempChar;
                        _newCharHi = HIBYTE(_newChar);
                        _newChar = LOBYTE(_newChar);
                        _newCharString[_j++] = _newChar;

                        if (_newCharHi > 32) {
                            if (vCodeTable == 2) //VNI
                                InsertKeyLength(2);
                            _newCharString[_j++] = _newCharHi;
                            _newCharSize++;
                        } else {
                            if (vCodeTable == 2) //VNI
                                InsertKeyLength(1);
                        }
                    } else if (vCodeTable == 3) { //Unicode Compound
                        _newChar = _tempChar;
                        _newCharHi = (_newChar >> 13);
                        _newChar &= 0x1FFF;

                        InsertKeyLength(_newCharHi > 0 ? 2 : 1);
                        _newCharString[_j++] = _newChar;
                        if (_newCharHi > 0) {
                            _newCharSize++;
                            _newCharString[_j++] = _unicodeCompoundMark[_newCharHi - 1];
                        }

                    }
                }
            }//end for
        }

        if (!_willContinuteSending && (pData->code == vRestore || pData->code == vRestoreAndStartNewSession)) { //if is restore
            if (keyCodeToCharacter(_keycode) != 0) {
                _newCharSize++;
                _newCharString[_j++] = keyCodeToCharacter(_keycode | ((_flag & kCGEventFlagMaskAlphaShift) || (_flag & kCGEventFlagMaskShift) ? CAPS_MASK : 0));
            } else {
                _willSendControlKey = true;
            }
        }
        if (!_willContinuteSending && pData->code == vRestoreAndStartNewSession) {
            startNewSession();
        }

        _newEventDown = CGEventCreateKeyboardEvent(myEventSource, 0, true);
        _newEventUp = CGEventCreateKeyboardEvent(myEventSource, 0, false);
        CGEventKeyboardSetUnicodeString(_newEventDown, _willContinuteSending ? 16 : _newCharSize - offset, _newCharString);
        CGEventKeyboardSetUnicodeString(_newEventUp, _willContinuteSending ? 16 : _newCharSize - offset, _newCharString);
        CGEventTapPostEvent(_proxy, _newEventDown);
        CGEventTapPostEvent(_proxy, _newEventUp);
        CFRelease(_newEventDown);
        CFRelease(_newEventUp);

        if (_willContinuteSending) {
            SendNewCharString(dataFromMacro, dataFromMacro ? _k : 16);
        }

        //the case when hCode is vRestore or vRestoreAndStartNewSession, the word is invalid and last key is control key such as TAB, LEFT ARROW, RIGHT ARROW,...
        if (_willSendControlKey) {
            SendKeyCode(_keycode);
        }
    }

    bool checkHotKey(int hotKeyData, bool checkKeyCode=true) {
        if ((hotKeyData & (~0x8000)) == EMPTY_HOTKEY)
            return false;
        CGEventFlags flagsToUse = checkKeyCode ? _flag : _lastFlag;
        if (HAS_CONTROL(hotKeyData) ^ GET_BOOL(flagsToUse & kCGEventFlagMaskControl))
            return false;
        if (HAS_OPTION(hotKeyData) ^ GET_BOOL(flagsToUse & kCGEventFlagMaskAlternate))
            return false;
        if (HAS_COMMAND(hotKeyData) ^ GET_BOOL(flagsToUse & kCGEventFlagMaskCommand))
            return false;
        if (HAS_SHIFT(hotKeyData) ^ GET_BOOL(flagsToUse & kCGEventFlagMaskShift))
            return false;
        if (checkKeyCode) {
            if (GET_SWITCH_KEY(hotKeyData) != _keycode)
                return false;
        }
        return true;
    }

    void switchLanguage() {
        if (vLanguage == 0)
            vLanguage = 1;
        else
            vLanguage = 0;
        if (HAS_BEEP(vSwitchKeyStatus))
            NSBeep();
        [MKBridge engineDidSwitchLanguage];
        startNewSession();
    }

    void handleMacro() {
        //Spotlight-like fields: replace text atomically via Accessibility,
        //then deliver the trigger key (space/enter) as a normal event
        if (AXSlowPathActive() && TryAXProcessMacro()) {
            SendKeyCode(_keycode | (_flag & kCGEventFlagMaskShift ? CAPS_MASK : 0));
            return;
        }

        //fix autocomplete
        if (vFixRecommendBrowser) {
            SendEmptyCharacter();
            pData->backspaceCount++;
        }

        //send backspace
        if (pData->backspaceCount > 0) {
            for (int i = 0; i < pData->backspaceCount; i++) {
                SendBackspace();
            }
        }
        //send real data
        if (!vSendKeyStepByStep) {
            SendNewCharString(true);
        } else {
            for (int i = 0; i < pData->macroData.size(); i++) {
                if (pData->macroData[i] & PURE_CHARACTER_MASK) {
                    SendPureCharacter(pData->macroData[i]);
                } else {
                    SendKeyCode(pData->macroData[i]);
                }
            }
        }
        SendKeyCode(_keycode | (_flag & kCGEventFlagMaskShift ? CAPS_MASK : 0));
    }

    int ConvertKeyStringToKeyCode(NSString *keyString, CGKeyCode fallback) {
        if (keyString == nil || [keyString length] == 0) return fallback;
        unichar ch = [keyString characterAtIndex:0];
        if (ch < 128) {
            switch (ch) {
                case 'a': case 'A': return 0;
                case 'b': case 'B': return 11;
                case 'c': case 'C': return 8;
                case 'd': case 'D': return 2;
                case 'e': case 'E': return 14;
                case 'f': case 'F': return 3;
                case 'g': case 'G': return 5;
                case 'h': case 'H': return 4;
                case 'i': case 'I': return 34;
                case 'j': case 'J': return 38;
                case 'k': case 'K': return 40;
                case 'l': case 'L': return 37;
                case 'm': case 'M': return 46;
                case 'n': case 'N': return 45;
                case 'o': case 'O': return 31;
                case 'p': case 'P': return 35;
                case 'q': case 'Q': return 12;
                case 'r': case 'R': return 15;
                case 's': case 'S': return 1;
                case 't': case 'T': return 17;
                case 'u': case 'U': return 32;
                case 'v': case 'V': return 9;
                case 'w': case 'W': return 13;
                case 'x': case 'X': return 7;
                case 'y': case 'Y': return 16;
                case 'z': case 'Z': return 6;
                case '1': case '!': return 18;
                case '2': case '@': return 19;
                case '3': case '#': return 20;
                case '4': case '$': return 21;
                case '5': case '%': return 23;
                case '6': case '^': return 22;
                case '7': case '&': return 26;
                case '8': case '*': return 28;
                case '9': case '(': return 25;
                case '0': case ')': return 29;
                case '`': case '~': return 50;
                case '-': case '_': return 27;
                case '=': case '+': return 24;
                case '[': case '{': return 33;
                case ']': case '}': return 30;
                case '\\': case '|': return 42;
                case ';': case ':': return 41;
                case '\'': case '"': return 39;
                case ',': case '<': return 43;
                case '.': case '>': return 47;
                case '/': case '?': return 44;
                default: return fallback;
            }
        }
        return fallback;
    }

    // If conversion fails, return fallbackKeyCode
    CGKeyCode ConvertEventToKeyboadLayoutCompatKeyCode(CGEventRef keyEvent, CGKeyCode fallbackKeyCode) {
        NSEvent *kbLayoutCompatEvent = [NSEvent eventWithCGEvent:keyEvent];
        NSString *kbLayoutCompatKeyString = kbLayoutCompatEvent.charactersIgnoringModifiers;
        return ConvertKeyStringToKeyCode(kbLayoutCompatKeyString,
                                         fallbackKeyCode);
    }

    /**
     * MAIN HOOK entry, very important function.
     */
    CGEventRef MKEngineCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
        //macOS disables the tap when the callback is too slow or the user holds many keys;
        //re-enable instead of silently dying (frequent on modern macOS)
        if (type == kCGEventTapDisabledByTimeout || type == kCGEventTapDisabledByUserInput) {
            MKReEnableEventTap();
            return event;
        }

        //dont handle my event
        if (CGEventGetIntegerValueField(event, kCGEventSourceStateID) == CGEventSourceGetSourceStateID(myEventSource)) {
            return event;
        }

        //engine suspended (e.g. while the clipboard picker's search field is up)
        //-> let every keystroke through raw so Vietnamese processing doesn't
        //mangle what is typed into MKey's own UI.
        if (_mkEngineSuspended) {
            return event;
        }

        _flag = CGEventGetFlags(event);
        _keycode = (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);

        CFAbsoluteTime currentKeystrokeTime = 0;
        if (type == kCGEventKeyDown) {
            currentKeystrokeTime = CFAbsoluteTimeGetCurrent();
            if (OTHER_CONTROL_KEY) {
                AXInvalidateFocusCache();
            }
        }

        if (type == kCGEventKeyDown && vPerformLayoutCompat) {
            // If conversion fail, use current keycode
           _keycode = ConvertEventToKeyboadLayoutCompatKeyCode(event, _keycode);
        }

        //switch language shortcut; convert hotkey
        if (type == kCGEventKeyDown) {
            if (GET_SWITCH_KEY(vSwitchKeyStatus) != _keycode && GET_SWITCH_KEY(convertToolHotKey) != _keycode) {
                _lastFlag = 0;
            } else {
                if (GET_SWITCH_KEY(vSwitchKeyStatus) == _keycode && checkHotKey(vSwitchKeyStatus, GET_SWITCH_KEY(vSwitchKeyStatus) != 0xFE)){
                    switchLanguage();
                    _lastFlag = 0;
                    _hasJustUsedHotKey = true;
                    return NULL;
                }
                if (GET_SWITCH_KEY(convertToolHotKey) == _keycode && checkHotKey(convertToolHotKey, GET_SWITCH_KEY(convertToolHotKey) != 0xFE)){
                    [MKBridge engineRequestsQuickConvert];
                    _lastFlag = 0;
                    _hasJustUsedHotKey = true;
                    return NULL;
                }
            }
            _hasJustUsedHotKey = _lastFlag != 0;
        } else if (type == kCGEventFlagsChanged) {
            if (_lastFlag == 0 || _lastFlag < _flag) {
                _lastFlag = _flag;
            } else if (_lastFlag > _flag)  {
                //check switch
                if (checkHotKey(vSwitchKeyStatus, GET_SWITCH_KEY(vSwitchKeyStatus) != 0xFE)) {
                    _lastFlag = 0;
                    switchLanguage();
                    _hasJustUsedHotKey = true;
                    return NULL;
                }
                if (checkHotKey(convertToolHotKey, GET_SWITCH_KEY(convertToolHotKey) != 0xFE)) {
                    _lastFlag = 0;
                    [MKBridge engineRequestsQuickConvert];
                    _hasJustUsedHotKey = true;
                    return NULL;
                }
                //check temporarily turn off spell checking
                if (vTempOffSpelling && !_hasJustUsedHotKey && _lastFlag & kCGEventFlagMaskControl) {
                    vTempOffSpellChecking();
                }
                if (vTempOffOpenKey && !_hasJustUsedHotKey && _lastFlag & kCGEventFlagMaskCommand) {
                    vTempOffEngine();
                }
                _lastFlag = 0;
                _hasJustUsedHotKey = false;
            }
        }

        // Also check correct event hooked
        if ((type != kCGEventKeyDown) && (type != kCGEventKeyUp) &&
            (type != kCGEventLeftMouseDown) && (type != kCGEventRightMouseDown) &&
            (type != kCGEventLeftMouseDragged) && (type != kCGEventRightMouseDragged))
            return event;

        _proxy = proxy;

        //If is in english mode
        if (vLanguage == 0) {
            if (vUseMacro && vUseMacroInEnglishMode && type == kCGEventKeyDown) {
                vEnglishMode((type == kCGEventKeyDown ? vKeyEventState::KeyDown : vKeyEventState::MouseDown),
                             _keycode,
                             (_flag & kCGEventFlagMaskShift) || (_flag & kCGEventFlagMaskAlphaShift),
                             OTHER_CONTROL_KEY);

                if (pData->code == vReplaceMaro) { //handle macro in english mode
                    handleMacro();
                    _lastKeystrokeTime = currentKeystrokeTime;
                    return NULL;
                }
            }
            if (type == kCGEventKeyDown) {
                _lastKeystrokeTime = currentKeystrokeTime;
            }
            return event;
        }

        //handle mouse
        if (type == kCGEventLeftMouseDown || type == kCGEventRightMouseDown || type == kCGEventLeftMouseDragged || type == kCGEventRightMouseDragged) {
            RequestNewSession();
            return event;
        }

        //if "turn off Vietnamese when in other language" mode on
        if(vOtherLanguage){
            if (!_cachedIsEnglishLayout) {
                if (type == kCGEventKeyDown) {
                    _lastKeystrokeTime = currentKeystrokeTime;
                }
                return event;
            }
        }

        //handle keyboard
        if (type == kCGEventKeyDown) {
            //send event signal to Engine
            vKeyHandleEvent(vKeyEvent::Keyboard,
                            vKeyEventState::KeyDown,
                            _keycode,
                            _flag & kCGEventFlagMaskShift ? 1 : (_flag & kCGEventFlagMaskAlphaShift ? 2 : 0),
                            OTHER_CONTROL_KEY);
            if (pData->code == vDoNothing) { //do nothing
                if (IS_DOUBLE_CODE(vCodeTable)) { //VNI
                    if (pData->extCode == 1) { //break key
                        _syncKey.clear();
                    } else if (pData->extCode == 2) { //delete key
                        if (_syncKey.size() > 0) {
                            if (_syncKey.back() > 1 && (vCodeTable == 2 || !containUnicodeCompoundApp(FRONT_APP))) {
                                //send one more backspace
                                CGEventTapPostEvent(_proxy, eventBackSpaceDown);
                                CGEventTapPostEvent(_proxy, eventBackSpaceUp);
                            }
                            _syncKey.pop_back();
                        }

                    } else if (pData->extCode == 3) { //normal key
                        InsertKeyLength(1);
                    }
                }
                _lastKeystrokeTime = currentKeystrokeTime;
                return event;
            } else if (pData->code == vWillProcess || pData->code == vRestore || pData->code == vRestoreAndStartNewSession) { //handle result signal

                //Spotlight-like fields: atomic replacement via Accessibility
                //beats any event-timing game (no backspace can be swallowed
                //by the async inline completion). Falls through on failure.
                if (AXSlowPathActive() && TryAXProcessKey()) {
                    _lastKeystrokeTime = currentKeystrokeTime;
                    return NULL;
                }

                //fix autocomplete
                if (vFixRecommendBrowser && pData->extCode != 4) {
                    if (vFixChromiumBrowser && [_unicodeCompoundApp containsObject:FRONT_APP]) {
                        if (pData->backspaceCount > 0) {
                            SendShiftAndLeftArrow();
                            if (pData->backspaceCount == 1)
                                pData->backspaceCount--;
                        }
                    } else {
                        SendEmptyCharacter();
                        pData->backspaceCount++;

                    }
                }

                //send backspace
                if (pData->backspaceCount > 0 && pData->backspaceCount < MAX_BUFF) {
                    for (_i = 0; _i < pData->backspaceCount; _i++) {
                        SendBackspace();
                    }
                }

                //send new character
                if (!vSendKeyStepByStep) {
                    SendNewCharString();
                } else {
                    if (pData->newCharCount > 0 && pData->newCharCount <= MAX_BUFF) {
                        for (int i = pData->newCharCount - 1; i >= 0; i--) {
                            SendKeyCode(pData->charData[i]);
                        }
                    }
                    if (pData->code == vRestore || pData->code == vRestoreAndStartNewSession) {
                        SendKeyCode(_keycode | ((_flag & kCGEventFlagMaskAlphaShift) || (_flag & kCGEventFlagMaskShift) ? CAPS_MASK : 0));
                    }
                    if (pData->code == vRestoreAndStartNewSession) {
                        startNewSession();
                    }
                }
            } else if (pData->code == vReplaceMaro) { //MACRO
                handleMacro();
            }

            _lastKeystrokeTime = currentKeystrokeTime;
            return NULL;
        }

        return event;
    }
}
