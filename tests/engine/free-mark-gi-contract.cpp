// Copyright (C) 2026 MKey contributors. SPDX-License-Identifier: GPL-3.0-or-later
#include "Engine.h"
#include <iostream>
#include <vector>

int checkFreeMarkGiContract() {
    vLanguage = 1;
    vCodeTable = 0;
    vFreeMark = 1;
    vUseModernOrthography = 1;
    vRestoreIfWrongSpelling = 0;
    vQuickTelex = vQuickStartConsonant = vQuickEndConsonant = 0;
    vUseMacro = 1;
    vAutoCapsMacro = vUpperCaseFirstChar = 0;
    addMacro("giúp", "help");
    addMacro("GIÚP", "help");
    int cases = 0, failures = 0;
    for (int input : {vTelex, vVNI}) {
        vInputType = input;
        const Uint16 toneKey = input == vTelex ? KEY_S : KEY_1;
        for (int spelling : {0, 1}) {
            vCheckSpelling = spelling;
            for (int caps : {0, 1}) {
                const Uint32 upper = caps ? CAPS_MASK : 0;
                auto* packet = static_cast<vKeyHookState*>(vKeyInit());
                const auto typeWord = [&]() {
                    startNewSession();
                    packet->macroKey.clear();
                    for (const auto key : {KEY_G, KEY_I, (int)toneKey, KEY_U, KEY_P})
                        vKeyHandleEvent(Keyboard, KeyDown, key,
                                        input == vVNI && key == toneKey ? 0 : caps, false);
                };
                const auto check = [&](bool valid, const char* name) {
                    ++cases;
                    if (!valid) {
                        std::cerr << "FAIL GI " << name << ": input=" << input
                                  << " spelling=" << spelling << " caps=" << caps << '\n';
                        ++failures;
                    }
                };
                typeWord();
                // The host has gíu/GÍU; P is suppressed and included exactly once.
                const std::vector<Uint32> macroKey = {KEY_G | upper, KEY_I | upper,
                                                      KEY_U | upper | MARK1_MASK, KEY_P | upper};
                check(packet->code == vWillProcess && packet->extCode == 4 &&
                      packet->backspaceCount == 2 && packet->newCharCount == 3 &&
                      packet->charData[0] == (KEY_P | upper) &&
                      packet->charData[1] == ((caps ? 0x00DAu : 0x00FAu) | CHAR_CODE_MASK) &&
                      packet->charData[2] == (KEY_I | upper) && packet->macroKey == macroKey,
                      "pending-coda packet/macro-key");

                vKeyHandleEvent(Keyboard, KeyDown, toneKey, input == vVNI ? 0 : caps, false);
                check(packet->code == vRestore && packet->backspaceCount == 2 &&
                      packet->newCharCount == 2 && packet->charData[0] == (KEY_P | upper) &&
                      packet->charData[1] == (KEY_U | upper), "canonical tone cancellation");

                typeWord();
                vKeyHandleEvent(Keyboard, KeyDown, KEY_SPACE, 0, false);
                const std::vector<Uint32> replacement = {KEY_H, KEY_E, KEY_L, KEY_P};
                check(packet->code == vReplaceMaro && packet->backspaceCount == 4 &&
                      packet->macroData == replacement, "corrected-word macro expansion");
            }
        }
    }
    deleteMacro("giúp");
    deleteMacro("GIÚP");
    std::cout << cases << " GI packet/macro/escape cases: " << failures << " FAIL\n";
    return failures ? 1 : 0;
}
