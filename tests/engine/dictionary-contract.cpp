// Copyright (C) 2026 MKey contributors. SPDX-License-Identifier: GPL-3.0-or-later
#include "VietnameseDictionary.h"
#include <iostream>
#include <vector>

int checkDictionaryContract() {
    struct Case {
        const char* name;
        std::vector<Uint32> cells;
        bool known;
    };
    const Case cases[] = {
        {"phanh", {KEY_P, KEY_H, KEY_A, KEY_N, KEY_H}, true},
        {"phan", {KEY_P, KEY_H, KEY_A, KEY_N}, true},
        {"phun", {KEY_P, KEY_H, KEY_U, KEY_N}, true},
        {"phable", {KEY_P, KEY_H, KEY_A, KEY_B, KEY_L, KEY_E}, false},
        {"giup", {KEY_G, KEY_I, KEY_U | MARK1_MASK, KEY_P}, true},
        {"tone-on-gi-i", {KEY_G, KEY_I | MARK1_MASK, KEY_U, KEY_P}, false},
        {"viec", {KEY_V, KEY_I, KEY_E | TONE_MASK | MARK5_MASK, KEY_C}, true},
        {"tone-on-viec-i", {KEY_V, KEY_I | MARK5_MASK, KEY_E | TONE_MASK, KEY_C}, false},
        {"upper-viec", {KEY_V | CAPS_MASK, KEY_I | CAPS_MASK,
                         KEY_E | CAPS_MASK | TONE_MASK | MARK5_MASK, KEY_C | CAPS_MASK}, true},
        {"old-hoa", {KEY_H, KEY_O, KEY_A | MARK2_MASK}, true},
        {"new-hoa", {KEY_H, KEY_O | MARK2_MASK, KEY_A}, true},
        {"old-thuy", {KEY_T, KEY_H, KEY_U, KEY_Y | MARK3_MASK}, true},
        {"new-thuy", {KEY_T, KEY_H, KEY_U | MARK3_MASK, KEY_Y}, true},
        {"dak", {KEY_D | TONE_MASK, KEY_A | TONEW_MASK | MARK1_MASK, KEY_K}, true},
        {"nguoi", {KEY_N, KEY_G, KEY_U | TONEW_MASK, KEY_O | TONEW_MASK | MARK2_MASK, KEY_I}, true},
        {"standalone-horn", {KEY_G, KEY_I, KEY_U | TONEW_MASK | STANDALONE_MASK | MARK4_MASK}, true},
        {"encoded-not-raw", {'a' | CHAR_CODE_MASK}, false},
        {"pure-not-raw", {'a' | PURE_CHARACTER_MASK}, false},
        {"double-shape", {KEY_A | TONE_MASK | TONEW_MASK}, false},
        {"double-tone", {KEY_A | MARK1_MASK | MARK2_MASK}, false},
        {"empty", {}, false},
        {"long-window", std::vector<Uint32>(MAX_BUFF, KEY_A), false},
    };
    int failures = 0;
    for (const auto& test : cases) {
        if (vIsVietnameseWord(test.cells.data(), test.cells.size()) != test.known) {
            std::cerr << "FAIL dictionary membership: " << test.name << '\n';
            ++failures;
        }
    }
    std::cout << sizeof(cases) / sizeof(cases[0]) << " dictionary membership cases: " << failures << " FAIL\n";
    return failures ? 1 : 0;
}
