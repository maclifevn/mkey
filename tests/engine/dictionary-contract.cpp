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

    const Case prefixes[] = {
        {"ph", {KEY_P, KEY_H}, true},
        {"ch", {KEY_C, KEY_H}, true},
        {"gi", {KEY_G, KEY_I}, true},
        {"kh", {KEY_K, KEY_H}, true},
        {"ng", {KEY_N, KEY_G}, true},
        {"qu", {KEY_Q, KEY_U}, true},
        {"th", {KEY_T, KEY_H}, true},
        {"upper-ph", {KEY_P | CAPS_MASK, KEY_H | CAPS_MASK}, true},
        {"aph", {KEY_A, KEY_P, KEY_H}, false},
        {"haph", {KEY_H, KEY_A, KEY_P, KEY_H}, false},
        {"literal-pp", {KEY_P, KEY_P}, false},
        {"late-tone-bach", {KEY_B, KEY_A, KEY_C, KEY_H}, true},
        {"late-shape-chuong", {KEY_C, KEY_H, KEY_U, KEY_O, KEY_N, KEY_G}, true},
        {"tone-before-gi-coda", {KEY_G, KEY_I | MARK1_MASK, KEY_U, KEY_P}, true},
        {"dak", {KEY_D | TONE_MASK, KEY_A | TONEW_MASK | MARK1_MASK, KEY_K}, true},
        {"encoded-not-raw", {'a' | CHAR_CODE_MASK}, false},
        {"pure-not-raw", {'a' | PURE_CHARACTER_MASK}, false},
        {"unknown-flags", {KEY_P | 0x80000000u, KEY_H}, false},
        {"number", {KEY_1}, false},
        {"double-shape", {KEY_A | TONE_MASK | TONEW_MASK}, false},
        {"shape-on-consonant", {KEY_P | TONE_MASK, KEY_H}, false},
        {"double-tone", {KEY_A | MARK1_MASK | MARK2_MASK}, false},
        {"tone-on-consonant", {KEY_P | MARK1_MASK, KEY_H}, false},
        {"empty", {}, false},
        {"beyond-syllable", std::vector<Uint32>(8, KEY_A), false},
        {"long-window", std::vector<Uint32>(MAX_BUFF, KEY_A), false},
    };
    int prefixFailures = 0;
    for (const auto& test : prefixes) {
        if (vIsVietnamesePrefix(test.cells.data(), test.cells.size()) != test.known) {
            std::cerr << "FAIL dictionary prefix: " << test.name << '\n';
            ++prefixFailures;
        }
    }
    if (vIsVietnamesePrefix(nullptr, 2)) {
        std::cerr << "FAIL dictionary prefix: null\n";
        ++prefixFailures;
    }
    std::cout << sizeof(prefixes) / sizeof(prefixes[0]) + 1 << " dictionary prefix cases: " << prefixFailures << " FAIL\n";
    failures += prefixFailures;
    return failures ? 1 : 0;
}
