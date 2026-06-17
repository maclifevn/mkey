//
//  MKGlobals.h
//  mkey
//
//  Pure-C declarations of the engine configuration globals so Swift can
//  read/write them directly through the bridging header.
//  Definitions live in MKBridge.mm (app-side) and the C++ engine.
//

#ifndef MKGlobals_h
#define MKGlobals_h

// Default language-switch hotkey: ⌥Z, display char 'z' in the top byte.
#define MKEY_DEFAULT_SWITCH_STATUS 0x7A000206
// Marker for "no key assigned" in hotkey bitfields.
#define MKEY_EMPTY_HOTKEY 0xFE0000FE

// NOTE: no extern "C" here on purpose — Engine.h declares the same globals
// with C++ linkage; plain int globals share the same symbol either way.

// See Engine.h for the meaning of each variable.
extern int vLanguage;               // 0: English, 1: Vietnamese
extern int vInputType;              // 0: Telex, 1: VNI, 2: Simple Telex 1, 3: Simple Telex 2
extern int vFreeMark;
extern int vCodeTable;              // 0: Unicode, 1: TCVN3, 2: VNI-Windows, 3: Unicode compound, 4: CP1258
extern int vCheckSpelling;
extern int vUseModernOrthography;
extern int vQuickTelex;
extern int vSwitchKeyStatus;        // hotkey bitfield (keycode | modifiers | beep | display char)
extern int vRestoreIfWrongSpelling;
extern int vFixRecommendBrowser;
extern int vUseMacro;
extern int vUseMacroInEnglishMode;
extern int vAutoCapsMacro;
extern int vSendKeyStepByStep;
extern int vUseSmartSwitchKey;
extern int vUpperCaseFirstChar;
extern int vTempOffSpelling;
extern int vAllowConsonantZFWJ;
extern int vQuickStartConsonant;
extern int vQuickEndConsonant;
extern int vRememberCode;
extern int vOtherLanguage;
extern int vTempOffOpenKey;
extern int vFixChromiumBrowser;
extern int vPerformLayoutCompat;
// mkey addition: pace synthesized events & skip the empty-char hack in
// Spotlight-like overlay search fields (they process input asynchronously,
// which scrambles fast typing).
extern int vFixSpotlight;
extern int vUseAXReplacement;

#endif /* MKGlobals_h */
