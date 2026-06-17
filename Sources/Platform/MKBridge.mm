//
//  MKBridge.mm
//  mkey
//
//  Owns the engine configuration globals, the CGEventTap lifecycle and the
//  Objective-C++ wrappers around the C++ engine APIs (macros, convert tool).
//

#import "MKBridge.h"
#include "Engine.h"

NSNotificationName const MKStateDidChangeNotification = @"MKStateDidChangeNotification";
NSNotificationName const MKQuickConvertDidRunNotification = @"MKQuickConvertDidRunNotification";

//engine configuration globals (declared extern in Engine.h / MKGlobals.h)
int vLanguage = 1;
int vInputType = 0;
int vFreeMark = 0;
int vCodeTable = 0;
int vCheckSpelling = 1;
int vUseModernOrthography = 1;
int vQuickTelex = 0;
int vSwitchKeyStatus = MKEY_DEFAULT_SWITCH_STATUS;
int vRestoreIfWrongSpelling = 0;
int vFixRecommendBrowser = 1;
int vUseMacro = 1;
int vUseMacroInEnglishMode = 1;
int vAutoCapsMacro = 0;
int vSendKeyStepByStep = 0;
int vUseSmartSwitchKey = 1;
int vUpperCaseFirstChar = 0;
int vTempOffSpelling = 0;
int vAllowConsonantZFWJ = 0;
int vQuickStartConsonant = 0;
int vQuickEndConsonant = 0;
int vRememberCode = 1;
int vOtherLanguage = 1;
int vTempOffOpenKey = 0;
int vFixChromiumBrowser = 0;
int vPerformLayoutCompat = 0;
int vFixSpotlight = 1;
int vUseAXReplacement = 1;

//implemented in MKEngineHook.mm
extern "C" {
    void MKEngineInit(void);
    CGEventRef MKEngineCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon);
    void RequestNewSession(void);
    void OnActiveAppChanged(void);
    void OnTableCodeChange(void);
    void OnInputMethodChanged(void);
    void OnSpellCheckingChanged(void);
    NSString* ConvertUtil(NSString* str);
    void MKSetEngineSuspended(bool suspended);
}

static CFMachPortRef      _eventTap = NULL;
static CFRunLoopSourceRef _runLoopSource = NULL;
static BOOL               _tapRunning = NO;

extern "C" void MKReEnableEventTap(void) {
    if (_eventTap) {
        CGEventTapEnable(_eventTap, true);
    }
}

static NSUserDefaults* prefs(void) {
    return [NSUserDefaults standardUserDefaults];
}

static void postStateChanged(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:MKStateDidChangeNotification object:nil];
    });
}

@implementation MKMacroItem
@end

@implementation MKBridge

#pragma mark - Engine lifecycle

+ (BOOL)startEventTap {
    if (_tapRunning)
        return YES;

    MKEngineInit();

    CGEventMask eventMask = ((1 << kCGEventKeyDown) |
                             (1 << kCGEventKeyUp) |
                             (1 << kCGEventFlagsChanged) |
                             (1 << kCGEventLeftMouseDown) |
                             (1 << kCGEventRightMouseDown) |
                             (1 << kCGEventLeftMouseDragged) |
                             (1 << kCGEventRightMouseDragged));

    _eventTap = CGEventTapCreate(kCGSessionEventTap,
                                 kCGHeadInsertEventTap,
                                 kCGEventTapOptionDefault,
                                 eventMask,
                                 MKEngineCallback,
                                 NULL);
    if (!_eventTap) {
        return NO;
    }

    _runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, _eventTap, 0);
    CFRunLoopAddSource(CFRunLoopGetMain(), _runLoopSource, kCFRunLoopCommonModes);
    CGEventTapEnable(_eventTap, true);

    _tapRunning = YES;
    return YES;
}

+ (BOOL)stopEventTap {
    if (_tapRunning) {
        CFRunLoopRemoveSource(CFRunLoopGetMain(), _runLoopSource, kCFRunLoopCommonModes);
        CFRelease(_runLoopSource);
        _runLoopSource = NULL;

        CFMachPortInvalidate(_eventTap);
        CFRelease(_eventTap);
        _eventTap = NULL;

        _tapRunning = NO;
    }
    return YES;
}

+ (BOOL)isEventTapRunning {
    return _tapRunning;
}

#pragma mark - State changes driven by the UI

+ (void)toggleLanguage {
    [self setLanguage:(vLanguage == 0 ? 1 : 0)];
}

+ (void)setLanguage:(int)language {
    vLanguage = language;
    [prefs() setInteger:language forKey:@"InputMethod"];
    if (HAS_BEEP(vSwitchKeyStatus)) {
        NSBeep();
    }
    startNewSession();
    OnInputMethodChanged(); //persist for smart switch
    postStateChanged();
}

+ (void)setInputType:(int)inputType {
    vInputType = inputType;
    [prefs() setInteger:inputType forKey:@"InputType"];
    postStateChanged();
}

+ (void)setCodeTable:(int)codeTable {
    vCodeTable = codeTable;
    [prefs() setInteger:codeTable forKey:@"CodeTable"];
    OnTableCodeChange(); //reload macro content + persist for remember-code
    postStateChanged();
}

+ (void)spellCheckingChanged {
    OnSpellCheckingChanged();
}

+ (void)requestNewSession {
    RequestNewSession();
}

+ (void)activeAppChanged {
    OnActiveAppChanged();
}

+ (void)persistSwitchKeyStatus {
    [prefs() setInteger:vSwitchKeyStatus forKey:@"SwitchKeyStatus"];
}

+ (void)setEngineSuspended:(BOOL)suspended {
    MKSetEngineSuspended(suspended);
}

#pragma mark - State changes driven by the engine

+ (void)engineDidSwitchLanguage {
    [prefs() setInteger:vLanguage forKey:@"InputMethod"];
    OnInputMethodChanged();
    postStateChanged();
}

+ (void)engineDidChangeLanguage:(int)language {
    vLanguage = language;
    [prefs() setInteger:language forKey:@"InputMethod"];
    postStateChanged();
}

+ (void)engineDidChangeCodeTable:(int)codeTable {
    vCodeTable = codeTable;
    [prefs() setInteger:codeTable forKey:@"CodeTable"];
    OnTableCodeChange();
    postStateChanged();
}

+ (void)engineRequestsQuickConvert {
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL ok = [self quickConvertClipboard];
        [[NSNotificationCenter defaultCenter] postNotificationName:MKQuickConvertDidRunNotification
                                                            object:@(ok)];
    });
}

#pragma mark - Macros

+ (NSArray<MKMacroItem *> *)allMacros {
    vector<vector<Uint32>> keys;
    vector<string> texts;
    vector<string> contents;
    getAllMacro(keys, texts, contents);

    NSMutableArray<MKMacroItem *> *result = [NSMutableArray arrayWithCapacity:texts.size()];
    for (size_t i = 0; i < texts.size(); i++) {
        MKMacroItem *item = [[MKMacroItem alloc] init];
        item.text = [NSString stringWithUTF8String:texts[i].c_str()] ?: @"";
        item.content = [NSString stringWithUTF8String:contents[i].c_str()] ?: @"";
        [result addObject:item];
    }
    return result;
}

+ (BOOL)hasMacro:(NSString *)text {
    return hasMacro(string([text UTF8String]));
}

+ (void)addMacro:(NSString *)text content:(NSString *)content {
    addMacro(string([text UTF8String]), string([content UTF8String]));
    [self persistMacroData];
}

+ (BOOL)deleteMacro:(NSString *)text {
    BOOL ok = deleteMacro(string([text UTF8String]));
    if (ok)
        [self persistMacroData];
    return ok;
}

+ (void)importMacrosFromFile:(NSString *)path append:(BOOL)append {
    readFromFile(string([path UTF8String]), append);
    [self persistMacroData];
}

+ (void)exportMacrosToFile:(NSString *)path {
    saveToFile(string([path UTF8String]));
}

+ (void)persistMacroData {
    vector<Byte> macroData;
    getMacroSaveData(macroData);
    NSData* data = [NSData dataWithBytes:macroData.data() length:macroData.size()];
    [prefs() setObject:data forKey:@"macroData"];
}

#pragma mark - Convert tool

+ (BOOL)convertAlertWhenCompleted { return !convertToolDontAlertWhenCompleted; }
+ (void)setConvertAlertWhenCompleted:(BOOL)value {
    convertToolDontAlertWhenCompleted = !value;
    [prefs() setBool:value forKey:@"convertToolAlertWhenCompleted"];
}

+ (BOOL)convertToAllCaps { return convertToolToAllCaps; }
+ (void)setConvertToAllCaps:(BOOL)value {
    convertToolToAllCaps = value;
    [prefs() setBool:value forKey:@"convertToolToAllCaps"];
}

+ (BOOL)convertToAllNonCaps { return convertToolToAllNonCaps; }
+ (void)setConvertToAllNonCaps:(BOOL)value {
    convertToolToAllNonCaps = value;
    [prefs() setBool:value forKey:@"convertToolToAllNonCaps"];
}

+ (BOOL)convertToCapsFirstLetter { return convertToolToCapsFirstLetter; }
+ (void)setConvertToCapsFirstLetter:(BOOL)value {
    convertToolToCapsFirstLetter = value;
    [prefs() setBool:value forKey:@"convertToolToCapsFirstLetter"];
}

+ (BOOL)convertToCapsEachWord { return convertToolToCapsEachWord; }
+ (void)setConvertToCapsEachWord:(BOOL)value {
    convertToolToCapsEachWord = value;
    [prefs() setBool:value forKey:@"convertToolToCapsEachWord"];
}

+ (BOOL)convertRemoveMark { return convertToolRemoveMark; }
+ (void)setConvertRemoveMark:(BOOL)value {
    convertToolRemoveMark = value;
    [prefs() setBool:value forKey:@"convertToolRemoveMark"];
}

+ (int)convertFromCode { return convertToolFromCode; }
+ (void)setConvertFromCode:(int)value {
    convertToolFromCode = value;
    [prefs() setInteger:value forKey:@"convertToolFromCode"];
}

+ (int)convertToCode { return convertToolToCode; }
+ (void)setConvertToCode:(int)value {
    convertToolToCode = value;
    [prefs() setInteger:value forKey:@"convertToolToCode"];
}

+ (int)convertHotKey { return convertToolHotKey; }
+ (void)setConvertHotKey:(int)value {
    convertToolHotKey = value;
    [prefs() setInteger:value forKey:@"convertToolHotKey"];
}

+ (BOOL)quickConvertClipboard {
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSString *htmlString = [pasteboard stringForType:NSPasteboardTypeHTML];
    NSString *rawString = [pasteboard stringForType:NSPasteboardTypeString];
    BOOL converted = NO;
    if (htmlString != nil) {
        htmlString = ConvertUtil(htmlString);
        converted = YES;
    }
    if (rawString != nil) {
        rawString = ConvertUtil(rawString);
        converted = YES;
    }
    if (converted) {
        [pasteboard clearContents];
        if (htmlString != nil)
            [pasteboard setString:htmlString forType:NSPasteboardTypeHTML];
        if (rawString != nil)
            [pasteboard setString:rawString forType:NSPasteboardTypeString];
        return YES;
    }
    return NO;
}

@end
