// Copyright (C) 2026 MKey contributors. SPDX-License-Identifier: GPL-3.0-or-later
#include "Engine.h"
#include <iostream>
#include <vector>

// These are packet fixtures, independent of the engine's text-rendering oracle.
struct DeletionCase {
    const char* name;
    int codeTable;
    Byte extCode, action, before, newCount, after;
    bool insertedEmpty, allowed;
};

int checkHookContract() {
    const DeletionCase cases[] = {
        {"valid31-dummy-action1", 0, vUnicodeFullRedraw, vWillProcess, 31, 31, 32, true, true},
        {"valid32-no-dummy-action1", 0, vUnicodeFullRedraw, vWillProcess, 32, 32, 32, false, true},
        {"valid32-dummy-action1", 0, vUnicodeFullRedraw, vWillProcess, 32, 32, 33, true, true},
        // Restore keeps its existing delivery path and Telex replay rules.
        {"restore31-dummy-not-opened", 0, vUnicodeFullRedraw, vRestore, 31, 31, 32, true, false},
        {"restore32-no-dummy-not-opened", 0, vUnicodeFullRedraw, vRestore, 32, 32, 32, false, false},
        {"restore32-dummy-not-opened", 0, vUnicodeFullRedraw, vRestore, 32, 32, 33, true, false},
        {"wrong-action0", 0, vUnicodeFullRedraw, vDoNothing, 32, 32, 32, false, false},
        {"wrong-action2", 0, vUnicodeFullRedraw, vBreakWord, 32, 32, 32, false, false},
        {"wrong-action4", 0, vUnicodeFullRedraw, vReplaceMaro, 32, 32, 32, false, false},
        {"wrong-action5", 0, vUnicodeFullRedraw, vRestoreAndStartNewSession, 32, 32, 32, false, false},
        {"wrong-action99", 0, vUnicodeFullRedraw, 99, 32, 32, 32, false, false},
        {"wrong-action255", 0, vUnicodeFullRedraw, 255, 32, 32, 32, false, false},
        {"wrong-table1", 1, vUnicodeFullRedraw, vWillProcess, 32, 32, 32, false, false},
        {"wrong-table2", 2, vUnicodeFullRedraw, vWillProcess, 32, 32, 32, false, false},
        {"wrong-table3", 3, vUnicodeFullRedraw, vWillProcess, 32, 32, 32, false, false},
        {"wrong-table4", 4, vUnicodeFullRedraw, vWillProcess, 32, 32, 32, false, false},
        {"wrong-table99", 99, vUnicodeFullRedraw, vWillProcess, 32, 32, 32, false, false},
        {"wrong-tag0", 0, 0, vWillProcess, 32, 32, 32, false, false},
        {"wrong-tag1", 0, 1, vWillProcess, 32, 32, 32, false, false},
        {"wrong-tag2", 0, 2, vWillProcess, 32, 32, 32, false, false},
        {"wrong-tag3", 0, 3, vWillProcess, 32, 32, 32, false, false},
        {"wrong-tag4", 0, 4, vWillProcess, 32, 32, 32, false, false},
        {"wrong-tag6", 0, 6, vWillProcess, 32, 32, 32, false, false},
        {"wrong-tag99", 0, 99, vWillProcess, 32, 32, 32, false, false},
        {"wrong-tag255", 0, 255, vWillProcess, 32, 32, 32, false, false},
        {"orig30", 0, vUnicodeFullRedraw, vWillProcess, 30, 30, 32, true, false},
        {"orig33", 0, vUnicodeFullRedraw, vWillProcess, 33, 33, 33, false, false},
        {"orig0", 0, vUnicodeFullRedraw, vWillProcess, 0, 0, 32, false, false},
        {"orig255", 0, vUnicodeFullRedraw, vWillProcess, 255, 255, 255, false, false},
        {"byte-wrap255", 0, vUnicodeFullRedraw, vWillProcess, 255, 255, 0, true, false},
        {"NCC31-vs32", 0, vUnicodeFullRedraw, vWillProcess, 32, 31, 32, false, false},
        {"NCC33-vs32", 0, vUnicodeFullRedraw, vWillProcess, 32, 33, 32, false, false},
        {"NCC0-vs32", 0, vUnicodeFullRedraw, vWillProcess, 32, 0, 32, false, false},
        {"post-too-large", 0, vUnicodeFullRedraw, vWillProcess, 32, 32, 34, true, false},
        {"dummy-not-reflected", 0, vUnicodeFullRedraw, vWillProcess, 32, 32, 32, true, false},
        {"false-dummy-extra", 0, vUnicodeFullRedraw, vWillProcess, 32, 32, 33, false, false},
        {"31-no-dummy-extra", 0, vUnicodeFullRedraw, vWillProcess, 31, 31, 32, false, false},
        {"31-dummy-double", 0, vUnicodeFullRedraw, vWillProcess, 31, 31, 33, true, false},
        {"legacy-bound0", 0, 3, vWillProcess, 0, 0, 0, false, false},
        {"legacy-bound1", 0, 3, vWillProcess, 1, 1, 1, false, true},
        {"legacy-bound30", 0, 3, vWillProcess, 30, 30, 30, false, true},
        {"legacy-bound31", 0, 3, vWillProcess, 31, 31, 31, false, true},
        {"legacy-bound32", 0, 3, vWillProcess, 32, 32, 32, false, false},
        {"legacy-bound33", 0, 3, vWillProcess, 33, 33, 33, false, false},
        {"legacy-bound255", 0, 3, vWillProcess, 255, 255, 255, false, false},
        {"31-no-dummy-legacy", 0, vUnicodeFullRedraw, vWillProcess, 31, 31, 31, false, true},
    };
    int failures = 0;
    for (const auto& test : cases) {
        vKeyHookState packet = {};
        packet.extCode = test.extCode;
        packet.code = test.action;
        packet.backspaceCount = test.after;
        packet.newCharCount = test.newCount;
        if (vCanSendBackspace(packet, test.before, test.insertedEmpty, test.codeTable) != test.allowed) {
            std::cerr << "FAIL deletion policy: " << test.name << '\n';
            ++failures;
        }
    }

    vInputType = vTelex;
    vCodeTable = 0;
    vCheckSpelling = 0;
    vFreeMark = 1;
    vUseMacro = 0;
    vRestoreIfWrongSpelling = 0;
    int packetCases = 0;
    for (int span : {31, 32}) {
        std::vector<Uint16> keys = {KEY_U, KEY_W};
        for (int n = 0; n < (span == 31 ? 14 : 15); ++n) {
            keys.push_back(KEY_I);
            keys.push_back(KEY_E);
        }
        if (span == 31) keys.push_back(KEY_A);
        keys.push_back(KEY_O);
        keys.push_back(KEY_O);
        const auto makePacket = [&]() {
            auto* packet = static_cast<vKeyHookState*>(vKeyInit());
            startNewSession();
            for (const auto key : keys) vKeyHandleEvent(Keyboard, KeyDown, key, 0, false);
            return packet;
        };
        struct NextKey { Uint16 key; Byte extCode; };
        for (const auto next : {NextKey{KEY_SPACE, 3}, NextKey{KEY_DELETE, 2},
                                NextKey{KEY_RETURN, 1}, NextKey{KEY_A, 3}}) {
            auto* packet = makePacket();
            bool valid = packet->code == vWillProcess && packet->extCode == vUnicodeFullRedraw &&
                packet->backspaceCount == span && packet->newCharCount == span;
            ++packet->backspaceCount; // the real hook inserted its autocomplete sentinel
            vKeyHandleEvent(Keyboard, KeyDown, next.key, 0, false);
            valid = valid && packet->extCode == next.extCode;
            if (!valid) {
                std::cerr << "FAIL redraw marker lifetime: span=" << span << " next=" << next.key << '\n';
                ++failures;
            }
            ++packetCases;
        }
        for (int table : {1, 2, 3, 4}) {
            vCodeTable = table;
            const auto* packet = makePacket();
            if (packet->code != vWillProcess || packet->extCode != 3 ||
                packet->backspaceCount != 1 || packet->newCharCount != 1) {
                std::cerr << "FAIL non-Unicode packet changed: table=" << table << " span=" << span << '\n';
                ++failures;
            }
            ++packetCases;
        }
        vCodeTable = 0;
    }
    std::cout << sizeof(cases) / sizeof(cases[0]) << " deletion-policy cases, "
              << packetCases << " engine-packet cases: " << failures << " FAIL\n";
    return failures ? 1 : 0;
}
