// Copyright (C) 2026 MKey contributors. SPDX-License-Identifier: GPL-3.0-or-later
// A Unicode text-field model of MKEngineHook.mm's normal event delivery path.
#include "Engine.h"
#include <cctype>
#include <iostream>
#include <sstream>
#include <stdexcept>
#include <string>

int vLanguage = 1, vInputType = 0, vFreeMark = 0, vCodeTable = 0;
int vSwitchKeyStatus = 0, vCheckSpelling = 1, vUseModernOrthography = 1;
int vQuickTelex = 0, vRestoreIfWrongSpelling = 0, vFixRecommendBrowser = 1;
int vUseMacro = 1, vUseMacroInEnglishMode = 1, vAutoCapsMacro = 0;
int vUseSmartSwitchKey = 1, vUpperCaseFirstChar = 0, vTempOffSpelling = 0;
int vAllowConsonantZFWJ = 0, vQuickStartConsonant = 0, vQuickEndConsonant = 0;
int vRememberCode = 1, vOtherLanguage = 1, vTempOffOpenKey = 0;

struct Key {
    Uint16 code;
    Uint8 caps;
    char32_t text;
    bool otherControl = false;
};

static Key asciiKey(unsigned char ch, bool capsLock) {
    static const Uint16 letters[] = {
        KEY_A, KEY_B, KEY_C, KEY_D, KEY_E, KEY_F, KEY_G, KEY_H, KEY_I,
        KEY_J, KEY_K, KEY_L, KEY_M, KEY_N, KEY_O, KEY_P, KEY_Q, KEY_R,
        KEY_S, KEY_T, KEY_U, KEY_V, KEY_W, KEY_X, KEY_Y, KEY_Z
    };
    if (std::isalpha(ch)) {
        const bool shift = std::isupper(ch);
        return {letters[std::tolower(ch) - 'a'],
                static_cast<Uint8>(shift ? 1 : (capsLock ? 2 : 0)),
                static_cast<char32_t>(capsLock ? std::toupper(ch) : ch)};
    }
    // Explicit US ANSI physical keys, independent of the engine's character map.
    static const std::string unshifted = "1234567890[]`-=\\;',./ ";
    static const std::string shifted = "!@#$%^&*(){}~_+|:\"<>? ";
    static const Uint16 codes[] = {
        KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0,
        KEY_LEFT_BRACKET, KEY_RIGHT_BRACKET, KEY_BACKQUOTE, KEY_MINUS, KEY_EQUALS,
        KEY_BACK_SLASH, KEY_SEMICOLON, KEY_QUOTE, KEY_COMMA, KEY_DOT, KEY_SLASH, KEY_SPACE
    };
    auto pos = unshifted.find(ch);
    if (pos != std::string::npos) return {codes[pos], 0, ch};
    pos = shifted.find(ch);
    if (pos != std::string::npos) return {codes[pos], 1, ch};
    throw std::runtime_error("unsupported input byte (use ASCII keystrokes)");
}

static void configure(const std::string& options) {
    const std::map<std::string, int*> settings = {
        {"spell", &vCheckSpelling}, {"modern", &vUseModernOrthography},
        {"quick", &vQuickTelex}, {"free", &vFreeMark},
        {"restore", &vRestoreIfWrongSpelling}, {"macro", &vUseMacro},
        {"autocaps", &vAutoCapsMacro}, {"language", &vLanguage},
        {"macroEnglish", &vUseMacroInEnglishMode}, {"allowZFWJ", &vAllowConsonantZFWJ},
        {"quickStart", &vQuickStartConsonant}, {"quickEnd", &vQuickEndConsonant},
        {"upperFirst", &vUpperCaseFirstChar}, {"recommend", &vFixRecommendBrowser}
    };
    std::istringstream stream(options);
    for (std::string option; std::getline(stream, option, ',');) {
        if (option == "telex") vInputType = vTelex;
        else if (option == "vni") vInputType = vVNI;
        else if (option == "simple1") vInputType = vSimpleTelex1;
        else if (option == "simple2") vInputType = vSimpleTelex2;
        else {
            const auto eq = option.find('=');
            const auto it = settings.find(option.substr(0, eq));
            if (eq == std::string::npos || it == settings.end() ||
                (option.substr(eq + 1) != "0" && option.substr(eq + 1) != "1"))
                throw std::runtime_error("unknown setting: " + option);
            *it->second = option[eq + 1] - '0';
        }
    }
}

class TextField {
    std::u32string text;
    size_t caret = 0;
    bool trace;
    vKeyHookState* state;

    void insert(char32_t ch) {
        text.insert(text.begin() + caret++, ch);
    }

    void backspace() {
        if (caret > 0) text.erase(--caret, 1);
    }

    void originalKey(const Key& key) {
        // The fake field leaves Command/Control/Option shortcuts to its caller.
        if (key.otherControl) return;
        if (key.code == KEY_DELETE) backspace();
        else if (key.code == KEY_LEFT) { if (caret > 0) --caret; }
        else if (key.code == KEY_RIGHT) { if (caret < text.size()) ++caret; }
        else if (key.text) insert(key.text);
    }

    void generatedCharacter(Uint32 data) {
        // Same priority and 16-bit cast as SendNewCharString / TryAXProcessKey.
        if ((data & PURE_CHARACTER_MASK) || (data & CHAR_CODE_MASK))
            insert(static_cast<Uint16>(data));
        else {
            const auto ch = keyCodeToCharacter(data);
            if (!ch) throw std::runtime_error("unmapped generated keycode");
            insert(ch);
        }
    }

public:
    explicit TextField(bool trace) : trace(trace) {
        state = static_cast<vKeyHookState*>(vKeyInit());
        startNewSession();
        // Fixed, explicit fixtures. Each test runs in a fresh process.
        addMacro("btw", "by the way");
        addMacro("vn", "Việt Nam");
        addMacro("dc", "địa chỉ");
        addMacro("ưds", "windows");
        addMacro("test", "kiểm tra");
        addMacro("r", "rồi");
        addMacro("ko", "không");
        addMacro("longmacro", "một hai ba bốn năm sáu bảy tám chín mười");
    }

    void key(const Key& key) {
        if (vLanguage == 0) {
            if (!vUseMacro || !vUseMacroInEnglishMode) {
                originalKey(key);
                return;
            }
            vEnglishMode(KeyDown, key.code, key.caps != 0, key.otherControl);
        } else {
            vKeyHandleEvent(Keyboard, KeyDown, key.code, key.caps, key.otherControl);
        }
        if (trace) {
            std::cerr << "key=" << key.code << " caps=" << int(key.caps)
                      << " code=" << int(state->code) << " ext=" << int(state->extCode)
                      << " bs=" << int(state->backspaceCount)
                      << " new=" << int(state->newCharCount) << " data=";
            for (int i = 0; i < state->newCharCount; ++i)
                std::cerr << std::hex << state->charData[i] << ',' << std::dec;
            std::cerr << '\n';
        }
        switch (state->code) {
            case vDoNothing:
                // extCode 1/2/3 only changes the hook's multicode-table bookkeeping;
                // Unicode forwards the event unchanged for each of these values.
                originalKey(key);
                break;
            case vWillProcess:
            case vRestore:
            case vRestoreAndStartNewSession: {
                const auto action = state->code;
                // Normal (non-AX, non-Chromium-special) hook path. Keep the
                // Byte mutation too: at MAX_BUFF this is not a net-zero trick.
                if (vFixRecommendBrowser && state->extCode != 4) {
                    insert(U'\u202f');
                    ++state->backspaceCount;
                }
                // Keep the hook's exact < MAX_BUFF guard, including its boundary.
                if (state->backspaceCount < MAX_BUFF)
                    for (int i = 0; i < state->backspaceCount; ++i) backspace();
                if (state->newCharCount > MAX_BUFF)
                    throw std::runtime_error("engine character buffer overflow");
                for (int i = state->newCharCount - 1; i >= 0; --i)
                    generatedCharacter(state->charData[i]);
                if (action == vRestore || action == vRestoreAndStartNewSession)
                    originalKey(key);
                if (action == vRestoreAndStartNewSession) startNewSession();
                break;
            }
            case vReplaceMaro:
                if (vFixRecommendBrowser) {
                    insert(U'\u202f');
                    ++state->backspaceCount;
                }
                for (int i = 0; i < state->backspaceCount; ++i) backspace();
                // macroData is forward; charData above is reversed.
                for (const auto data : state->macroData) generatedCharacter(data);
                originalKey(key);
                break;
            case vBreakWord:
                // The current hook suppresses this unused action code.
                break;
            default:
                throw std::runtime_error("unknown hook action");
        }
    }

    void type(const std::string& keys) {
        bool capsLock = false;
        for (size_t i = 0; i < keys.size();) {
            if (keys.compare(i, 6, "<CAPS>") == 0) {
                capsLock = !capsLock;
                i += 6;
                continue;
            }
            if (keys.compare(i, 9, "<SESSION>") == 0) {
                startNewSession();
                i += 9;
                continue;
            }
            if (keys.compare(i, 11, "<ENGINEOFF>") == 0) {
                vTempOffEngine(true);
                i += 11;
                continue;
            }
            if (keys.compare(i, 10, "<ENGINEON>") == 0) {
                vTempOffEngine(false);
                i += 10;
                continue;
            }
            if (keys.compare(i, 7, "<MOUSE>") == 0) {
                // RequestNewSession in MKEngineHook.mm.
                if (vLanguage != 0) vKeyHandleEvent(Mouse, MouseDown, 0);
                i += 7;
                continue;
            }
            static const std::map<std::string, Key> controls = {
                {"<BS>", {KEY_DELETE, 0, 0}}, {"<ENTER>", {KEY_RETURN, 0, '\n'}},
                {"<KPENTER>", {KEY_ENTER, 0, '\n'}}, {"<TAB>", {KEY_TAB, 0, '\t'}},
                {"<LEFT>", {KEY_LEFT, 0, 0}}, {"<RIGHT>", {KEY_RIGHT, 0, 0}},
                {"<ESC>", {KEY_ESC, 0, 0}},
                {"<MOD+ENTER>", {KEY_RETURN, 0, '\n', true}},
                {"<MOD+SHIFT+ENTER>", {KEY_RETURN, 1, '\n', true}},
                {"<MOD+DOT>", {KEY_DOT, 0, '.', true}},
                {"<MOD+SHIFT+DOT>", {KEY_DOT, 1, '>', true}},
                {"<MOD+SHIFT+COMMA>", {KEY_COMMA, 1, '<', true}},
                {"<SHIFT+ENTER>", {KEY_RETURN, 1, '\n'}}
            };
            bool found = false;
            if (keys[i] == '<') {
                for (const auto& entry : controls) {
                    if (keys.compare(i, entry.first.size(), entry.first) == 0) {
                        key(entry.second);
                        i += entry.first.size();
                        found = true;
                        break;
                    }
                }
            }
            if (!found) key(asciiKey(keys[i++], capsLock));
        }
    }

    void print() const {
        for (const auto ch : text) {
            // Independent UTF-8 encoding; do not use the engine's conversion utility
            // as the test oracle for the engine's own output.
            if (ch < 0x80) std::cout.put(ch);
            else if (ch < 0x800) {
                std::cout.put(0xc0 | (ch >> 6));
                std::cout.put(0x80 | (ch & 0x3f));
            } else {
                std::cout.put(0xe0 | (ch >> 12));
                std::cout.put(0x80 | ((ch >> 6) & 0x3f));
                std::cout.put(0x80 | (ch & 0x3f));
            }
        }
    }
};

int main(int argc, char** argv) {
    try {
        if (argc < 3 || argc > 4) {
            std::cerr << "usage: engine-harness SETTINGS ASCII_KEYS [--trace]\n";
            return 2;
        }
        configure(argv[1]);
        TextField field(argc == 4 && std::string(argv[3]) == "--trace");
        field.type(argv[2]);
        field.print();
        return 0;
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 2;
    }
}
