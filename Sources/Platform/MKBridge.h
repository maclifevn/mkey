//
//  MKBridge.h
//  mkey
//
//  Objective-C facade between the SwiftUI app and the C++ engine / event hook.
//  This header is pure Objective-C so it can be imported into Swift.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "MKGlobals.h"

NS_ASSUME_NONNULL_BEGIN

/// Posted (on the main queue) whenever the engine changes state behind the
/// UI's back: language switched by hotkey, smart-switch on app change, …
extern NSNotificationName const MKStateDidChangeNotification;

/// Posted (on the main queue) when the quick-convert hotkey is pressed.
/// Object is an NSNumber (BOOL) indicating whether the conversion succeeded.
extern NSNotificationName const MKQuickConvertDidRunNotification;

/// One shortcut entry shown in the macro table.
@interface MKMacroItem : NSObject
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSString *content;
@end

@interface MKBridge : NSObject

#pragma mark - Engine lifecycle

/// Create the event tap and initialise the engine. Returns NO when the
/// Accessibility permission is missing.
+ (BOOL)startEventTap;
+ (BOOL)stopEventTap;
+ (BOOL)isEventTapRunning;

#pragma mark - State changes driven by the UI

/// Toggle Vietnamese/English, persist and inform the smart-switch store.
+ (void)toggleLanguage;
+ (void)setLanguage:(int)language;
+ (void)setInputType:(int)inputType;
+ (void)setCodeTable:(int)codeTable;
+ (void)spellCheckingChanged;
/// Tell the engine a new typing session begins (space switch, …).
+ (void)requestNewSession;
/// Smart switch: the frontmost application changed.
+ (void)activeAppChanged;
/// Reload vSwitchKeyStatus & friends after the UI edited them.
+ (void)persistSwitchKeyStatus;

/// Suspend/resume Vietnamese processing — used while MKey's own text UI (the
/// clipboard search field) is up so typed keys arrive raw.
+ (void)setEngineSuspended:(BOOL)suspended;

#pragma mark - State changes driven by the engine (do not call from UI)

+ (void)engineDidSwitchLanguage;
+ (void)engineDidChangeLanguage:(int)language;
+ (void)engineDidChangeCodeTable:(int)codeTable;
+ (void)engineRequestsQuickConvert;

#pragma mark - Macros

+ (NSArray<MKMacroItem *> *)allMacros;
+ (BOOL)hasMacro:(NSString *)text;
+ (void)addMacro:(NSString *)text content:(NSString *)content;
+ (BOOL)deleteMacro:(NSString *)text;
+ (void)importMacrosFromFile:(NSString *)path append:(BOOL)append;
+ (void)exportMacrosToFile:(NSString *)path;

#pragma mark - Convert tool

@property (class, nonatomic) BOOL convertAlertWhenCompleted;
@property (class, nonatomic) BOOL convertToAllCaps;
@property (class, nonatomic) BOOL convertToAllNonCaps;
@property (class, nonatomic) BOOL convertToCapsFirstLetter;
@property (class, nonatomic) BOOL convertToCapsEachWord;
@property (class, nonatomic) BOOL convertRemoveMark;
@property (class, nonatomic) int convertFromCode;
@property (class, nonatomic) int convertToCode;
@property (class, nonatomic) int convertHotKey;

/// Convert the current clipboard content. Returns NO when the clipboard is empty.
+ (BOOL)quickConvertClipboard;

@end

NS_ASSUME_NONNULL_END
