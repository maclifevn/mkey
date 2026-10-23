//
//  Vietnamese.cpp
//  OpenKey
//
//  Created by Tuyen on 1/19/19.
//  Copyright © 2019 Tuyen Mai. All rights reserved.
//

#include "Vietnamese.h"
#include <algorithm>

using namespace std;

// unicode
Uint16 douKey[][2] = {
    {KEY_A, 0xE2}, // a -> â
    {KEY_E, 0xEA}  // e -> ê
};

// --- _vowel static definitions ---
static const Uint16 vow_A_0[] = {KEY_A, KEY_N, KEY_G};
static const Uint16 vow_A_1[] = {KEY_A, KEY_G | END_CONSONANT_MASK};
static const Uint16 vow_A_2[] = {KEY_A, KEY_N};
static const Uint16 vow_A_3[] = {KEY_A, KEY_M};
static const Uint16 vow_A_4[] = {KEY_A, KEY_U};
static const Uint16 vow_A_5[] = {KEY_A, KEY_Y};
static const Uint16 vow_A_6[] = {KEY_A, KEY_T};
static const Uint16 vow_A_7[] = {KEY_A, KEY_P};
static const Uint16 vow_A_8[] = {KEY_A};
static const Uint16 vow_A_9[] = {KEY_A, KEY_C};

static const Array16 vow_A_seqs[] = {
    {vow_A_0, 3}, {vow_A_1, 2}, {vow_A_2, 2}, {vow_A_3, 2}, {vow_A_4, 2},
    {vow_A_5, 2}, {vow_A_6, 2}, {vow_A_7, 2}, {vow_A_8, 1}, {vow_A_9, 2}
};

static const Uint16 vow_O_0[] = {KEY_O, KEY_N, KEY_G};
static const Uint16 vow_O_1[] = {KEY_O, KEY_G | END_CONSONANT_MASK};
static const Uint16 vow_O_2[] = {KEY_O, KEY_N};
static const Uint16 vow_O_3[] = {KEY_O, KEY_M};
static const Uint16 vow_O_4[] = {KEY_O, KEY_I};
static const Uint16 vow_O_5[] = {KEY_O, KEY_C};
static const Uint16 vow_O_6[] = {KEY_O, KEY_T};
static const Uint16 vow_O_7[] = {KEY_O, KEY_P};
static const Uint16 vow_O_8[] = {KEY_O};

static const Array16 vow_O_seqs[] = {
    {vow_O_0, 3}, {vow_O_1, 2}, {vow_O_2, 2}, {vow_O_3, 2}, {vow_O_4, 2},
    {vow_O_5, 2}, {vow_O_6, 2}, {vow_O_7, 2}, {vow_O_8, 1}
};

static const Uint16 vow_E_0[] = {KEY_E, KEY_N, KEY_H};
static const Uint16 vow_E_1[] = {KEY_E, KEY_H | END_CONSONANT_MASK};
static const Uint16 vow_E_2[] = {KEY_E, KEY_N, KEY_G};
static const Uint16 vow_E_3[] = {KEY_E, KEY_G | END_CONSONANT_MASK};
static const Uint16 vow_E_4[] = {KEY_E, KEY_C, KEY_H};
static const Uint16 vow_E_5[] = {KEY_E, KEY_K | END_CONSONANT_MASK};
static const Uint16 vow_E_6[] = {KEY_E, KEY_C};
static const Uint16 vow_E_7[] = {KEY_E, KEY_T};
static const Uint16 vow_E_8[] = {KEY_E, KEY_Y};
static const Uint16 vow_E_9[] = {KEY_E, KEY_U};
static const Uint16 vow_E_10[] = {KEY_E, KEY_P};
static const Uint16 vow_E_11[] = {KEY_E, KEY_C};
static const Uint16 vow_E_12[] = {KEY_E, KEY_N};
static const Uint16 vow_E_13[] = {KEY_E, KEY_M};
static const Uint16 vow_E_14[] = {KEY_E};

static const Array16 vow_E_seqs[] = {
    {vow_E_0, 3}, {vow_E_1, 2}, {vow_E_2, 3}, {vow_E_3, 2}, {vow_E_4, 3},
    {vow_E_5, 2}, {vow_E_6, 2}, {vow_E_7, 2}, {vow_E_8, 2}, {vow_E_9, 2},
    {vow_E_10, 2}, {vow_E_11, 2}, {vow_E_12, 2}, {vow_E_13, 2}, {vow_E_14, 1}
};

static const Uint16 vow_W_0[] = {KEY_O, KEY_N};
static const Uint16 vow_W_1[] = {KEY_U, KEY_O, KEY_N, KEY_G};
static const Uint16 vow_W_2[] = {KEY_U, KEY_O, KEY_G | END_CONSONANT_MASK};
static const Uint16 vow_W_3[] = {KEY_U, KEY_O, KEY_N};
static const Uint16 vow_W_4[] = {KEY_U, KEY_O, KEY_I};
static const Uint16 vow_W_5[] = {KEY_U, KEY_O, KEY_C};
static const Uint16 vow_W_6[] = {KEY_O, KEY_I};
static const Uint16 vow_W_7[] = {KEY_O, KEY_P};
static const Uint16 vow_W_8[] = {KEY_O, KEY_M};
static const Uint16 vow_W_9[] = {KEY_O, KEY_A};
static const Uint16 vow_W_10[] = {KEY_O, KEY_T};
static const Uint16 vow_W_11[] = {KEY_U, KEY_N, KEY_G};
static const Uint16 vow_W_12[] = {KEY_U, KEY_G | END_CONSONANT_MASK};
static const Uint16 vow_W_13[] = {KEY_A, KEY_N, KEY_G};
static const Uint16 vow_W_14[] = {KEY_A, KEY_G | END_CONSONANT_MASK};
static const Uint16 vow_W_15[] = {KEY_U, KEY_N};
static const Uint16 vow_W_16[] = {KEY_U, KEY_M};
static const Uint16 vow_W_17[] = {KEY_U, KEY_C};
static const Uint16 vow_W_18[] = {KEY_U, KEY_A};
static const Uint16 vow_W_19[] = {KEY_U, KEY_I};
static const Uint16 vow_W_20[] = {KEY_U, KEY_T};
static const Uint16 vow_W_21[] = {KEY_U};
static const Uint16 vow_W_22[] = {KEY_A, KEY_P};
static const Uint16 vow_W_23[] = {KEY_A, KEY_T};
static const Uint16 vow_W_24[] = {KEY_A, KEY_M};
static const Uint16 vow_W_25[] = {KEY_A, KEY_N};
static const Uint16 vow_W_26[] = {KEY_A};
static const Uint16 vow_W_27[] = {KEY_A, KEY_C};
static const Uint16 vow_W_28[] = {KEY_A, KEY_C, KEY_H};
static const Uint16 vow_W_29[] = {KEY_A, KEY_K | END_CONSONANT_MASK};
static const Uint16 vow_W_30[] = {KEY_O};
static const Uint16 vow_W_31[] = {KEY_U, KEY_U};

static const Array16 vow_W_seqs[] = {
    {vow_W_0, 2}, {vow_W_1, 4}, {vow_W_2, 3}, {vow_W_3, 3}, {vow_W_4, 3},
    {vow_W_5, 3}, {vow_W_6, 2}, {vow_W_7, 2}, {vow_W_8, 2}, {vow_W_9, 2},
    {vow_W_10, 2}, {vow_W_11, 3}, {vow_W_12, 2}, {vow_W_13, 3}, {vow_W_14, 2},
    {vow_W_15, 2}, {vow_W_16, 2}, {vow_W_17, 2}, {vow_W_18, 2}, {vow_W_19, 2},
    {vow_W_20, 2}, {vow_W_21, 1}, {vow_W_22, 2}, {vow_W_23, 2}, {vow_W_24, 2},
    {vow_W_25, 2}, {vow_W_26, 1}, {vow_W_27, 2}, {vow_W_28, 3}, {vow_W_29, 2},
    {vow_W_30, 1}, {vow_W_31, 2}
};

static const VowelMapEntry vowel_entries[] = {
    { KEY_A, {vow_A_seqs, 10} },
    { KEY_O, {vow_O_seqs, 9} },
    { KEY_E, {vow_E_seqs, 15} },
    { KEY_W, {vow_W_seqs, 32} }
};

const VowelMap _vowel = {vowel_entries, 4};

// --- _vowelCombine static definitions ---
static const Uint32 vc_A_0[] = {0, KEY_A, KEY_I};
static const Uint32 vc_A_1[] = {0, KEY_A, KEY_O};
static const Uint32 vc_A_2[] = {0, KEY_A, KEY_U};
static const Uint32 vc_A_3[] = {0, KEY_A | TONE_MASK, KEY_U};
static const Uint32 vc_A_4[] = {0, KEY_A, KEY_Y};
static const Uint32 vc_A_5[] = {0, KEY_A | TONE_MASK, KEY_Y};

static const Array32 vc_A_seqs[] = {
    {vc_A_0, 3}, {vc_A_1, 3}, {vc_A_2, 3}, {vc_A_3, 3}, {vc_A_4, 3}, {vc_A_5, 3}
};

static const Uint32 vc_E_0[] = {0, KEY_E, KEY_O};
static const Uint32 vc_E_1[] = {0, KEY_E | TONE_MASK, KEY_U};

static const Array32 vc_E_seqs[] = {
    {vc_E_0, 3}, {vc_E_1, 3}
};

static const Uint32 vc_I_0[] = {1, KEY_I, KEY_E | TONE_MASK, KEY_U};
static const Uint32 vc_I_1[] = {0, KEY_I, KEY_A};
static const Uint32 vc_I_2[] = {1, KEY_I, KEY_E | TONE_MASK};
static const Uint32 vc_I_3[] = {0, KEY_I, KEY_U};

static const Array32 vc_I_seqs[] = {
    {vc_I_0, 4}, {vc_I_1, 3}, {vc_I_2, 3}, {vc_I_3, 3}
};

static const Uint32 vc_O_0[] = {0, KEY_O, KEY_A, KEY_I};
static const Uint32 vc_O_1[] = {0, KEY_O, KEY_A, KEY_O};
static const Uint32 vc_O_2[] = {0, KEY_O, KEY_A, KEY_Y};
static const Uint32 vc_O_3[] = {0, KEY_O, KEY_E, KEY_O};
static const Uint32 vc_O_4[] = {1, KEY_O, KEY_A};
static const Uint32 vc_O_5[] = {1, KEY_O, KEY_A | TONEW_MASK};
static const Uint32 vc_O_6[] = {1, KEY_O, KEY_E};
static const Uint32 vc_O_7[] = {0, KEY_O, KEY_I};
static const Uint32 vc_O_8[] = {0, KEY_O | TONE_MASK, KEY_I};
static const Uint32 vc_O_9[] = {0, KEY_O | TONEW_MASK, KEY_I};
static const Uint32 vc_O_10[] = {1, KEY_O, KEY_O};
static const Uint32 vc_O_11[] = {1, KEY_O | TONE_MASK, KEY_O | TONE_MASK};

static const Array32 vc_O_seqs[] = {
    {vc_O_0, 4}, {vc_O_1, 4}, {vc_O_2, 4}, {vc_O_3, 4}, {vc_O_4, 3}, {vc_O_5, 3},
    {vc_O_6, 3}, {vc_O_7, 3}, {vc_O_8, 3}, {vc_O_9, 3}, {vc_O_10, 3}, {vc_O_11, 3}
};

static const Uint32 vc_U_0[] = {0, KEY_U, KEY_Y, KEY_U};
static const Uint32 vc_U_1[] = {1, KEY_U, KEY_Y, KEY_E | TONE_MASK};
static const Uint32 vc_U_2[] = {0, KEY_U, KEY_Y, KEY_A};
static const Uint32 vc_U_3[] = {0, KEY_U | TONEW_MASK, KEY_O | TONEW_MASK, KEY_U};
static const Uint32 vc_U_4[] = {0, KEY_U | TONEW_MASK, KEY_O | TONEW_MASK, KEY_I};
static const Uint32 vc_U_5[] = {0, KEY_U, KEY_O | TONE_MASK, KEY_I};
static const Uint32 vc_U_6[] = {0, KEY_U, KEY_A | TONE_MASK, KEY_Y};
static const Uint32 vc_U_7[] = {1, KEY_U, KEY_A, KEY_O};
static const Uint32 vc_U_8[] = {1, KEY_U, KEY_A};
static const Uint32 vc_U_9[] = {1, KEY_U, KEY_A | TONEW_MASK};
static const Uint32 vc_U_10[] = {1, KEY_U, KEY_A | TONE_MASK};
static const Uint32 vc_U_11[] = {0, KEY_U | TONEW_MASK, KEY_A};
static const Uint32 vc_U_12[] = {1, KEY_U, KEY_E | TONE_MASK};
static const Uint32 vc_U_13[] = {0, KEY_U, KEY_I};
static const Uint32 vc_U_14[] = {0, KEY_U | TONEW_MASK, KEY_I};
static const Uint32 vc_U_15[] = {1, KEY_U, KEY_O};
static const Uint32 vc_U_16[] = {1, KEY_U, KEY_O | TONE_MASK};
static const Uint32 vc_U_17[] = {0, KEY_U, KEY_O | TONEW_MASK};
static const Uint32 vc_U_18[] = {1, KEY_U | TONEW_MASK, KEY_O | TONEW_MASK};
static const Uint32 vc_U_19[] = {0, KEY_U | TONEW_MASK, KEY_U};
static const Uint32 vc_U_20[] = {1, KEY_U, KEY_Y};

static const Array32 vc_U_seqs[] = {
    {vc_U_0, 4}, {vc_U_1, 4}, {vc_U_2, 4}, {vc_U_3, 4}, {vc_U_4, 4}, {vc_U_5, 4},
    {vc_U_6, 4}, {vc_U_7, 4}, {vc_U_8, 3}, {vc_U_9, 3}, {vc_U_10, 3}, {vc_U_11, 3},
    {vc_U_12, 3}, {vc_U_13, 3}, {vc_U_14, 3}, {vc_U_15, 3}, {vc_U_16, 3}, {vc_U_17, 3},
    {vc_U_18, 3}, {vc_U_19, 3}, {vc_U_20, 3}
};

static const Uint32 vc_Y_0[] = {0, KEY_Y, KEY_E | TONE_MASK, KEY_U};
static const Uint32 vc_Y_1[] = {1, KEY_Y, KEY_E | TONE_MASK};

static const Array32 vc_Y_seqs[] = {
    {vc_Y_0, 4}, {vc_Y_1, 3}
};

static const VowelCombineEntry vowel_combine_entries[] = {
    { KEY_A, {vc_A_seqs, 6} },
    { KEY_E, {vc_E_seqs, 2} },
    { KEY_I, {vc_I_seqs, 4} },
    { KEY_O, {vc_O_seqs, 12} },
    { KEY_U, {vc_U_seqs, 21} },
    { KEY_Y, {vc_Y_seqs, 2} }
};

const VowelCombineMap _vowelCombine = {vowel_combine_entries, 6};

// --- _consonantD static definitions ---
static const Uint16 cd_0[] = {KEY_D, KEY_E, KEY_N, KEY_H};
static const Uint16 cd_1[] = {KEY_D, KEY_E, KEY_H | END_CONSONANT_MASK};
static const Uint16 cd_2[] = {KEY_D, KEY_E, KEY_N, KEY_G};
static const Uint16 cd_3[] = {KEY_D, KEY_E, KEY_G | END_CONSONANT_MASK};
static const Uint16 cd_4[] = {KEY_D, KEY_E, KEY_C, KEY_H};
static const Uint16 cd_5[] = {KEY_D, KEY_E, KEY_K | END_CONSONANT_MASK};
static const Uint16 cd_6[] = {KEY_D, KEY_E, KEY_N};
static const Uint16 cd_7[] = {KEY_D, KEY_E, KEY_C};
static const Uint16 cd_8[] = {KEY_D, KEY_E, KEY_M};
static const Uint16 cd_9[] = {KEY_D, KEY_E};
static const Uint16 cd_10[] = {KEY_D, KEY_E, KEY_T};
static const Uint16 cd_11[] = {KEY_D, KEY_E, KEY_U};
static const Uint16 cd_12[] = {KEY_D, KEY_E, KEY_O};
static const Uint16 cd_13[] = {KEY_D, KEY_E, KEY_P};
static const Uint16 cd_14[] = {KEY_D, KEY_U, KEY_N, KEY_G};
static const Uint16 cd_15[] = {KEY_D, KEY_U, KEY_G | END_CONSONANT_MASK};
static const Uint16 cd_16[] = {KEY_D, KEY_U, KEY_N};
static const Uint16 cd_17[] = {KEY_D, KEY_U, KEY_M};
static const Uint16 cd_18[] = {KEY_D, KEY_U, KEY_C};
static const Uint16 cd_19[] = {KEY_D, KEY_U, KEY_O};
static const Uint16 cd_20[] = {KEY_D, KEY_U, KEY_A};
static const Uint16 cd_21[] = {KEY_D, KEY_U, KEY_O, KEY_I};
static const Uint16 cd_22[] = {KEY_D, KEY_U, KEY_O, KEY_C};
static const Uint16 cd_23[] = {KEY_D, KEY_U, KEY_O, KEY_N};
static const Uint16 cd_24[] = {KEY_D, KEY_U, KEY_O, KEY_N, KEY_G};
static const Uint16 cd_25[] = {KEY_D, KEY_U, KEY_O, KEY_G | END_CONSONANT_MASK};
static const Uint16 cd_26[] = {KEY_D, KEY_U};
static const Uint16 cd_27[] = {KEY_D, KEY_U, KEY_P};
static const Uint16 cd_28[] = {KEY_D, KEY_U, KEY_T};
static const Uint16 cd_29[] = {KEY_D, KEY_U, KEY_I};
static const Uint16 cd_30[] = {KEY_D, KEY_I, KEY_C, KEY_H};
static const Uint16 cd_31[] = {KEY_D, KEY_I, KEY_K | END_CONSONANT_MASK};
static const Uint16 cd_32[] = {KEY_D, KEY_I, KEY_C};
static const Uint16 cd_33[] = {KEY_D, KEY_I, KEY_N, KEY_H};
static const Uint16 cd_34[] = {KEY_D, KEY_I, KEY_H | END_CONSONANT_MASK};
static const Uint16 cd_35[] = {KEY_D, KEY_I, KEY_N};
static const Uint16 cd_36[] = {KEY_D, KEY_I};
static const Uint16 cd_37[] = {KEY_D, KEY_I, KEY_A};
static const Uint16 cd_38[] = {KEY_D, KEY_I, KEY_E};
static const Uint16 cd_39[] = {KEY_D, KEY_I, KEY_E, KEY_C};
static const Uint16 cd_40[] = {KEY_D, KEY_I, KEY_E, KEY_U};
static const Uint16 cd_41[] = {KEY_D, KEY_I, KEY_E, KEY_N};
static const Uint16 cd_42[] = {KEY_D, KEY_I, KEY_E, KEY_M};
static const Uint16 cd_43[] = {KEY_D, KEY_I, KEY_E, KEY_P};
static const Uint16 cd_44[] = {KEY_D, KEY_I, KEY_T};
static const Uint16 cd_45[] = {KEY_D, KEY_O};
static const Uint16 cd_46[] = {KEY_D, KEY_O, KEY_A};
static const Uint16 cd_47[] = {KEY_D, KEY_O, KEY_A, KEY_N};
static const Uint16 cd_48[] = {KEY_D, KEY_O, KEY_A, KEY_N, KEY_G};
static const Uint16 cd_49[] = {KEY_D, KEY_O, KEY_A, KEY_G | END_CONSONANT_MASK};
static const Uint16 cd_50[] = {KEY_D, KEY_O, KEY_A, KEY_N, KEY_H};
static const Uint16 cd_51[] = {KEY_D, KEY_O, KEY_A, KEY_H | END_CONSONANT_MASK};
static const Uint16 cd_52[] = {KEY_D, KEY_O, KEY_A, KEY_M};
static const Uint16 cd_53[] = {KEY_D, KEY_O, KEY_E};
static const Uint16 cd_54[] = {KEY_D, KEY_O, KEY_I};
static const Uint16 cd_55[] = {KEY_D, KEY_O, KEY_P};
static const Uint16 cd_56[] = {KEY_D, KEY_O, KEY_C};
static const Uint16 cd_57[] = {KEY_D, KEY_O, KEY_N};
static const Uint16 cd_58[] = {KEY_D, KEY_O, KEY_N, KEY_G};
static const Uint16 cd_59[] = {KEY_D, KEY_O, KEY_G | END_CONSONANT_MASK};
static const Uint16 cd_60[] = {KEY_D, KEY_O, KEY_M};
static const Uint16 cd_61[] = {KEY_D, KEY_O, KEY_T};
static const Uint16 cd_62[] = {KEY_D, KEY_A};
static const Uint16 cd_63[] = {KEY_D, KEY_A, KEY_T};
static const Uint16 cd_64[] = {KEY_D, KEY_A, KEY_Y};
static const Uint16 cd_65[] = {KEY_D, KEY_A, KEY_U};
static const Uint16 cd_66[] = {KEY_D, KEY_A, KEY_I};
static const Uint16 cd_67[] = {KEY_D, KEY_A, KEY_O};
static const Uint16 cd_68[] = {KEY_D, KEY_A, KEY_P};
static const Uint16 cd_69[] = {KEY_D, KEY_A, KEY_C};
static const Uint16 cd_70[] = {KEY_D, KEY_A, KEY_C, KEY_H};
static const Uint16 cd_71[] = {KEY_D, KEY_A, KEY_K | END_CONSONANT_MASK};
static const Uint16 cd_72[] = {KEY_D, KEY_A, KEY_N};
static const Uint16 cd_73[] = {KEY_D, KEY_A, KEY_N, KEY_H};
static const Uint16 cd_74[] = {KEY_D, KEY_A, KEY_H | END_CONSONANT_MASK};
static const Uint16 cd_75[] = {KEY_D, KEY_A, KEY_N, KEY_G};
static const Uint16 cd_76[] = {KEY_D, KEY_A, KEY_G | END_CONSONANT_MASK};
static const Uint16 cd_77[] = {KEY_D, KEY_A, KEY_M};
static const Uint16 cd_78[] = {KEY_D};

static const Array16 cd_rows[] = {
    {cd_0, 4}, {cd_1, 3}, {cd_2, 4}, {cd_3, 3}, {cd_4, 4}, {cd_5, 3}, {cd_6, 3},
    {cd_7, 3}, {cd_8, 3}, {cd_9, 2}, {cd_10, 3}, {cd_11, 3}, {cd_12, 3}, {cd_13, 3},
    {cd_14, 4}, {cd_15, 3}, {cd_16, 3}, {cd_17, 3}, {cd_18, 3}, {cd_19, 3}, {cd_20, 3},
    {cd_21, 4}, {cd_22, 4}, {cd_23, 4}, {cd_24, 5}, {cd_25, 4}, {cd_26, 2}, {cd_27, 3},
    {cd_28, 3}, {cd_29, 3}, {cd_30, 4}, {cd_31, 3}, {cd_32, 3}, {cd_33, 4}, {cd_34, 3},
    {cd_35, 3}, {cd_36, 2}, {cd_37, 3}, {cd_38, 3}, {cd_39, 4}, {cd_40, 4}, {cd_41, 4},
    {cd_42, 4}, {cd_43, 4}, {cd_44, 3}, {cd_45, 2}, {cd_46, 3}, {cd_47, 4}, {cd_48, 5},
    {cd_49, 4}, {cd_50, 5}, {cd_51, 4}, {cd_52, 4}, {cd_53, 3}, {cd_54, 3}, {cd_55, 3},
    {cd_56, 3}, {cd_57, 3}, {cd_58, 4}, {cd_59, 3}, {cd_60, 3}, {cd_61, 3}, {cd_62, 2},
    {cd_63, 3}, {cd_64, 3}, {cd_65, 3}, {cd_66, 3}, {cd_67, 3}, {cd_68, 3}, {cd_69, 3},
    {cd_70, 4}, {cd_71, 3}, {cd_72, 3}, {cd_73, 4}, {cd_74, 3}, {cd_75, 4}, {cd_76, 3},
    {cd_77, 3}, {cd_78, 1}
};

const Array2D16 _consonantD = {cd_rows, 79};

// --- _vowelForMark static definitions ---
static const Uint16 vfm_A_0[] = {KEY_A, KEY_N, KEY_G};
static const Uint16 vfm_A_1[] = {KEY_A, KEY_G | END_CONSONANT_MASK};
static const Uint16 vfm_A_2[] = {KEY_A, KEY_N};
static const Uint16 vfm_A_3[] = {KEY_A, KEY_N, KEY_H};
static const Uint16 vfm_A_4[] = {KEY_A, KEY_H | END_CONSONANT_MASK};
static const Uint16 vfm_A_5[] = {KEY_A, KEY_M};
static const Uint16 vfm_A_6[] = {KEY_A, KEY_U};
static const Uint16 vfm_A_7[] = {KEY_A, KEY_Y};
static const Uint16 vfm_A_8[] = {KEY_A, KEY_T};
static const Uint16 vfm_A_9[] = {KEY_A, KEY_P};
static const Uint16 vfm_A_10[] = {KEY_A};
static const Uint16 vfm_A_11[] = {KEY_A, KEY_C};
static const Uint16 vfm_A_12[] = {KEY_A, KEY_I};
static const Uint16 vfm_A_13[] = {KEY_A, KEY_O};
static const Uint16 vfm_A_14[] = {KEY_A, KEY_C, KEY_H};
static const Uint16 vfm_A_15[] = {KEY_A, KEY_K | END_CONSONANT_MASK};

static const Array16 vfm_A_seqs[] = {
    {vfm_A_0, 3}, {vfm_A_1, 2}, {vfm_A_2, 2}, {vfm_A_3, 3}, {vfm_A_4, 2},
    {vfm_A_5, 2}, {vfm_A_6, 2}, {vfm_A_7, 2}, {vfm_A_8, 2}, {vfm_A_9, 2},
    {vfm_A_10, 1}, {vfm_A_11, 2}, {vfm_A_12, 2}, {vfm_A_13, 2}, {vfm_A_14, 3},
    {vfm_A_15, 2}
};

static const Uint16 vfm_O_0[] = {KEY_O, KEY_O, KEY_N, KEY_G};
static const Uint16 vfm_O_1[] = {KEY_O, KEY_O, KEY_G | END_CONSONANT_MASK};
static const Uint16 vfm_O_2[] = {KEY_O, KEY_N, KEY_G};
static const Uint16 vfm_O_3[] = {KEY_O, KEY_G | END_CONSONANT_MASK};
static const Uint16 vfm_O_4[] = {KEY_O, KEY_O, KEY_N};
static const Uint16 vfm_O_5[] = {KEY_O, KEY_O, KEY_C};
static const Uint16 vfm_O_6[] = {KEY_O, KEY_O};
static const Uint16 vfm_O_7[] = {KEY_O, KEY_N};
static const Uint16 vfm_O_8[] = {KEY_O, KEY_M};
static const Uint16 vfm_O_9[] = {KEY_O, KEY_I};
static const Uint16 vfm_O_10[] = {KEY_O, KEY_C};
static const Uint16 vfm_O_11[] = {KEY_O, KEY_T};
static const Uint16 vfm_O_12[] = {KEY_O, KEY_P};
static const Uint16 vfm_O_13[] = {KEY_O};

static const Array16 vfm_O_seqs[] = {
    {vfm_O_0, 4}, {vfm_O_1, 3}, {vfm_O_2, 3}, {vfm_O_3, 2}, {vfm_O_4, 3},
    {vfm_O_5, 3}, {vfm_O_6, 2}, {vfm_O_7, 2}, {vfm_O_8, 2}, {vfm_O_9, 2},
    {vfm_O_10, 2}, {vfm_O_11, 2}, {vfm_O_12, 2}, {vfm_O_13, 1}
};

static const Uint16 vfm_E_0[] = {KEY_E, KEY_N, KEY_H};
static const Uint16 vfm_E_1[] = {KEY_E, KEY_H | END_CONSONANT_MASK};
static const Uint16 vfm_E_2[] = {KEY_E, KEY_N, KEY_G};
static const Uint16 vfm_E_3[] = {KEY_E, KEY_G | END_CONSONANT_MASK};
static const Uint16 vfm_E_4[] = {KEY_E, KEY_C, KEY_H};
static const Uint16 vfm_E_5[] = {KEY_E, KEY_K | END_CONSONANT_MASK};
static const Uint16 vfm_E_6[] = {KEY_E, KEY_C};
static const Uint16 vfm_E_7[] = {KEY_E, KEY_T};
static const Uint16 vfm_E_8[] = {KEY_E, KEY_Y};
static const Uint16 vfm_E_9[] = {KEY_E, KEY_U};
static const Uint16 vfm_E_10[] = {KEY_E, KEY_P};
static const Uint16 vfm_E_11[] = {KEY_E, KEY_C};
static const Uint16 vfm_E_12[] = {KEY_E, KEY_N};
static const Uint16 vfm_E_13[] = {KEY_E, KEY_M};
static const Uint16 vfm_E_14[] = {KEY_E};

static const Array16 vfm_E_seqs[] = {
    {vfm_E_0, 3}, {vfm_E_1, 2}, {vfm_E_2, 3}, {vfm_E_3, 2}, {vfm_E_4, 3},
    {vfm_E_5, 2}, {vfm_E_6, 2}, {vfm_E_7, 2}, {vfm_E_8, 2}, {vfm_E_9, 2},
    {vfm_E_10, 2}, {vfm_E_11, 2}, {vfm_E_12, 2}, {vfm_E_13, 2}, {vfm_E_14, 1}
};

static const Uint16 vfm_I_0[] = {KEY_I, KEY_N, KEY_H};
static const Uint16 vfm_I_1[] = {KEY_I, KEY_H | END_CONSONANT_MASK};
static const Uint16 vfm_I_2[] = {KEY_I, KEY_C, KEY_H};
static const Uint16 vfm_I_3[] = {KEY_I, KEY_K | END_CONSONANT_MASK};
static const Uint16 vfm_I_4[] = {KEY_I, KEY_N};
static const Uint16 vfm_I_5[] = {KEY_I, KEY_T};
static const Uint16 vfm_I_6[] = {KEY_I, KEY_U};
static const Uint16 vfm_I_7[] = {KEY_I, KEY_U, KEY_P};
static const Uint16 vfm_I_8[] = {KEY_I, KEY_N};
static const Uint16 vfm_I_9[] = {KEY_I, KEY_M};
static const Uint16 vfm_I_10[] = {KEY_I, KEY_P};
static const Uint16 vfm_I_11[] = {KEY_I, KEY_A};
static const Uint16 vfm_I_12[] = {KEY_I, KEY_C};
static const Uint16 vfm_I_13[] = {KEY_I};

static const Array16 vfm_I_seqs[] = {
    {vfm_I_0, 3}, {vfm_I_1, 2}, {vfm_I_2, 3}, {vfm_I_3, 2}, {vfm_I_4, 2},
    {vfm_I_5, 2}, {vfm_I_6, 2}, {vfm_I_7, 3}, {vfm_I_8, 2}, {vfm_I_9, 2},
    {vfm_I_10, 2}, {vfm_I_11, 2}, {vfm_I_12, 2}, {vfm_I_13, 1}
};

static const Uint16 vfm_U_0[] = {KEY_U, KEY_N, KEY_G};
static const Uint16 vfm_U_1[] = {KEY_U, KEY_G | END_CONSONANT_MASK};
static const Uint16 vfm_U_2[] = {KEY_U, KEY_I};
static const Uint16 vfm_U_3[] = {KEY_U, KEY_O};
static const Uint16 vfm_U_4[] = {KEY_U, KEY_Y};
static const Uint16 vfm_U_5[] = {KEY_U, KEY_Y, KEY_N};
static const Uint16 vfm_U_6[] = {KEY_U, KEY_Y, KEY_T};
static const Uint16 vfm_U_7[] = {KEY_U, KEY_Y, KEY_P};
static const Uint16 vfm_U_8[] = {KEY_U, KEY_Y, KEY_N, KEY_H};
static const Uint16 vfm_U_9[] = {KEY_U, KEY_Y, KEY_H | END_CONSONANT_MASK};
static const Uint16 vfm_U_10[] = {KEY_U, KEY_T};
static const Uint16 vfm_U_11[] = {KEY_U, KEY_U};
static const Uint16 vfm_U_12[] = {KEY_U, KEY_A};
static const Uint16 vfm_U_13[] = {KEY_U, KEY_I};
static const Uint16 vfm_U_14[] = {KEY_U, KEY_C};
static const Uint16 vfm_U_15[] = {KEY_U, KEY_N};
static const Uint16 vfm_U_16[] = {KEY_U, KEY_M};
static const Uint16 vfm_U_17[] = {KEY_U, KEY_P};
static const Uint16 vfm_U_18[] = {KEY_U};
static const Uint16 vfm_U_19[] = {KEY_U, KEY_Y, KEY_C, KEY_H};
static const Uint16 vfm_U_20[] = {KEY_U, KEY_Y, KEY_K | END_CONSONANT_MASK};

static const Array16 vfm_U_seqs[] = {
    {vfm_U_0, 3}, {vfm_U_1, 2}, {vfm_U_2, 2}, {vfm_U_3, 2}, {vfm_U_4, 2},
    {vfm_U_5, 3}, {vfm_U_6, 3}, {vfm_U_7, 3}, {vfm_U_19, 4}, {vfm_U_20, 3},
    {vfm_U_8, 4}, {vfm_U_9, 3},
    {vfm_U_10, 2}, {vfm_U_11, 2}, {vfm_U_12, 2}, {vfm_U_13, 2}, {vfm_U_14, 2},
    {vfm_U_15, 2}, {vfm_U_16, 2}, {vfm_U_17, 2}, {vfm_U_18, 1}
};

static const Uint16 vfm_Y_0[] = {KEY_Y};

static const Array16 vfm_Y_seqs[] = {
    {vfm_Y_0, 1}
};

const VowelMapEntry _vowelForMarkStatic[6] = {
    { KEY_A, {vfm_A_seqs, 16} },
    { KEY_O, {vfm_O_seqs, 14} },
    { KEY_E, {vfm_E_seqs, 15} },
    { KEY_I, {vfm_I_seqs, 14} },
    { KEY_U, {vfm_U_seqs, 21} },
    { KEY_Y, {vfm_Y_seqs, 1} }
};

// --- _consonantTable static definitions ---
static const Uint16 ct_0[] = {KEY_N, KEY_G, KEY_H};
static const Uint16 ct_1[] = {KEY_P, KEY_H};
static const Uint16 ct_2[] = {KEY_T, KEY_H};
static const Uint16 ct_3[] = {KEY_T, KEY_R};
static const Uint16 ct_4[] = {KEY_G, KEY_I};
static const Uint16 ct_5[] = {KEY_C, KEY_H};
static const Uint16 ct_6[] = {KEY_N, KEY_H};
static const Uint16 ct_7[] = {KEY_N, KEY_G};
static const Uint16 ct_8[] = {KEY_K, KEY_H};
static const Uint16 ct_9[] = {KEY_G, KEY_H};
static const Uint16 ct_10[] = {KEY_G};
static const Uint16 ct_11[] = {KEY_C};
static const Uint16 ct_12[] = {KEY_Q};
static const Uint16 ct_13[] = {KEY_K};
static const Uint16 ct_14[] = {KEY_T};
static const Uint16 ct_15[] = {KEY_R};
static const Uint16 ct_16[] = {KEY_H};
static const Uint16 ct_17[] = {KEY_B};
static const Uint16 ct_18[] = {KEY_M};
static const Uint16 ct_19[] = {KEY_V};
static const Uint16 ct_20[] = {KEY_N};
static const Uint16 ct_21[] = {KEY_L};
static const Uint16 ct_22[] = {KEY_X};
static const Uint16 ct_23[] = {KEY_P};
static const Uint16 ct_24[] = {KEY_S};
static const Uint16 ct_25[] = {KEY_D};
static const Uint16 ct_26[] = {KEY_F | CONSONANT_ALLOW_MASK};
static const Uint16 ct_27[] = {KEY_W | CONSONANT_ALLOW_MASK};
static const Uint16 ct_28[] = {KEY_Z | CONSONANT_ALLOW_MASK};
static const Uint16 ct_29[] = {KEY_J | CONSONANT_ALLOW_MASK};
static const Uint16 ct_30[] = {KEY_F | END_CONSONANT_MASK};
static const Uint16 ct_31[] = {KEY_W | END_CONSONANT_MASK};
static const Uint16 ct_32[] = {KEY_J | END_CONSONANT_MASK};

static const Array16 ct_rows[] = {
    {ct_0, 3}, {ct_1, 2}, {ct_2, 2}, {ct_3, 2}, {ct_4, 2}, {ct_5, 2}, {ct_6, 2},
    {ct_7, 2}, {ct_8, 2}, {ct_9, 2}, {ct_10, 1}, {ct_11, 1}, {ct_12, 1}, {ct_13, 1},
    {ct_14, 1}, {ct_15, 1}, {ct_16, 1}, {ct_17, 1}, {ct_18, 1}, {ct_19, 1}, {ct_20, 1},
    {ct_21, 1}, {ct_22, 1}, {ct_23, 1}, {ct_24, 1}, {ct_25, 1}, {ct_26, 1}, {ct_27, 1},
    {ct_28, 1}, {ct_29, 1}, {ct_30, 1}, {ct_31, 1}, {ct_32, 1}
};

const Array2D16 _consonantTable = {ct_rows, 33};

// --- _endConsonantTable static definitions ---
static const Uint16 ect_0[] = {KEY_T};
static const Uint16 ect_1[] = {KEY_P};
static const Uint16 ect_2[] = {KEY_C};
static const Uint16 ect_3[] = {KEY_N};
static const Uint16 ect_4[] = {KEY_M};
static const Uint16 ect_5[] = {KEY_G | END_CONSONANT_MASK};
static const Uint16 ect_6[] = {KEY_K | END_CONSONANT_MASK};
static const Uint16 ect_7[] = {KEY_H | END_CONSONANT_MASK};
static const Uint16 ect_8[] = {KEY_C, KEY_H};
static const Uint16 ect_9[] = {KEY_N, KEY_H};
static const Uint16 ect_10[] = {KEY_N, KEY_G};

static const Array16 ect_rows[] = {
    {ect_0, 1}, {ect_1, 1}, {ect_2, 1}, {ect_3, 1}, {ect_4, 1},
    {ect_5, 1}, {ect_6, 1}, {ect_7, 1}, {ect_8, 2}, {ect_9, 2}, {ect_10, 2}
};

const Array2D16 _endConsonantTable = {ect_rows, 11};

// --- _standaloneWbad static definitions ---
static const Uint16 swb_data[] = {
    KEY_W, KEY_E, KEY_Y, KEY_F, KEY_J, KEY_K, KEY_Z
};
const Array16 _standaloneWbad = {swb_data, 7};

// --- _doubleWAllowed static definitions ---
static const Uint16 dwa_0[] = {KEY_T, KEY_R};
static const Uint16 dwa_1[] = {KEY_T, KEY_H};
static const Uint16 dwa_2[] = {KEY_C, KEY_H};
static const Uint16 dwa_3[] = {KEY_N, KEY_H};
static const Uint16 dwa_4[] = {KEY_N, KEY_G};
static const Uint16 dwa_5[] = {KEY_K, KEY_H};
static const Uint16 dwa_6[] = {KEY_G, KEY_I};
static const Uint16 dwa_7[] = {KEY_P, KEY_H};
static const Uint16 dwa_8[] = {KEY_G, KEY_H};

static const Array16 dwa_rows[] = {
    {dwa_0, 2}, {dwa_1, 2}, {dwa_2, 2}, {dwa_3, 2}, {dwa_4, 2},
    {dwa_5, 2}, {dwa_6, 2}, {dwa_7, 2}, {dwa_8, 2}
};
const Array2D16 _doubleWAllowed = {dwa_rows, 9};

// --- _quickStartConsonant static definitions ---
static const QuickConsonantEntry qsc_entries[] = {
    { KEY_F, {KEY_P, KEY_H} },
    { KEY_J, {KEY_G, KEY_I} },
    { KEY_W, {KEY_Q, KEY_U} }
};
const QuickConsonantMap _quickStartConsonant = {qsc_entries, 3};

// --- _quickEndConsonant static definitions ---
static const QuickConsonantEntry qec_entries[] = {
    { KEY_G, {KEY_N, KEY_G} },
    { KEY_H, {KEY_N, KEY_H} },
    { KEY_K, {KEY_C, KEY_H} }
};
const QuickConsonantMap _quickEndConsonant = {qec_entries, 3};

// --- _quickTelex static definitions ---
static const QuickTelexEntry qt_entries[] = {
    { KEY_C, {KEY_C, KEY_H} },
    { KEY_G, {KEY_G, KEY_I} },
    { KEY_K, {KEY_K, KEY_H} },
    { KEY_N, {KEY_N, KEY_G} },
    { KEY_Q, {KEY_Q, KEY_U} },
    { KEY_P, {KEY_P, KEY_H} },
    { KEY_T, {KEY_T, KEY_H} },
    { KEY_U, {KEY_U, KEY_U} }
};
const QuickTelexMap _quickTelex = {qt_entries, 8};

// --- _characterMap static definitions ---
static const CharacterMap::Entry staticCharMapEntries[95] = {
    {'a', KEY_A}, {'A', KEY_A|CAPS_MASK},
    {'b', KEY_B}, {'B', KEY_B|CAPS_MASK},
    {'c', KEY_C}, {'C', KEY_C|CAPS_MASK},
    {'d', KEY_D}, {'D', KEY_D|CAPS_MASK},
    {'e', KEY_E}, {'E', KEY_E|CAPS_MASK},
    {'f', KEY_F}, {'F', KEY_F|CAPS_MASK},
    {'g', KEY_G}, {'G', KEY_G|CAPS_MASK},
    {'h', KEY_H}, {'H', KEY_H|CAPS_MASK},
    {'i', KEY_I}, {'I', KEY_I|CAPS_MASK},
    {'j', KEY_J}, {'J', KEY_J|CAPS_MASK},
    {'k', KEY_K}, {'K', KEY_K|CAPS_MASK},
    {'l', KEY_L}, {'L', KEY_L|CAPS_MASK},
    {'m', KEY_M}, {'M', KEY_M|CAPS_MASK},
    {'n', KEY_N}, {'N', KEY_N|CAPS_MASK},
    {'o', KEY_O}, {'O', KEY_O|CAPS_MASK},
    {'p', KEY_P}, {'P', KEY_P|CAPS_MASK},
    {'q', KEY_Q}, {'Q', KEY_Q|CAPS_MASK},
    {'r', KEY_R}, {'R', KEY_R|CAPS_MASK},
    {'s', KEY_S}, {'S', KEY_S|CAPS_MASK},
    {'t', KEY_T}, {'T', KEY_T|CAPS_MASK},
    {'u', KEY_U}, {'U', KEY_U|CAPS_MASK},
    {'v', KEY_V}, {'V', KEY_V|CAPS_MASK},
    {'w', KEY_W}, {'W', KEY_W|CAPS_MASK},
    {'x', KEY_X}, {'X', KEY_X|CAPS_MASK},
    {'y', KEY_Y}, {'Y', KEY_Y|CAPS_MASK},
    {'z', KEY_Z}, {'Z', KEY_Z|CAPS_MASK},
    {'1', KEY_1}, {'!', KEY_1|CAPS_MASK},
    {'2', KEY_2}, {'@', KEY_2|CAPS_MASK},
    {'3', KEY_3}, {'#', KEY_3|CAPS_MASK},
    {'4', KEY_4}, {'$', KEY_4|CAPS_MASK},
    {'5', KEY_5}, {'%', KEY_5|CAPS_MASK},
    {'6', KEY_6}, {'^', KEY_6|CAPS_MASK},
    {'7', KEY_7}, {'&', KEY_7|CAPS_MASK},
    {'8', KEY_8}, {'*', KEY_8|CAPS_MASK},
    {'9', KEY_9}, {'(', KEY_9|CAPS_MASK},
    {'0', KEY_0}, {')', KEY_0|CAPS_MASK},
    {'`', KEY_BACKQUOTE}, {'~', KEY_BACKQUOTE|CAPS_MASK},
    {'-', KEY_MINUS}, {'_', KEY_MINUS|CAPS_MASK},
    {'=', KEY_EQUALS}, {'+', KEY_EQUALS|CAPS_MASK},
    {'[', KEY_LEFT_BRACKET}, {'{', KEY_LEFT_BRACKET|CAPS_MASK},
    {']', KEY_RIGHT_BRACKET}, {'}', KEY_RIGHT_BRACKET|CAPS_MASK},
    {'\\', KEY_BACK_SLASH}, {'|', KEY_BACK_SLASH|CAPS_MASK},
    {';', KEY_SEMICOLON}, {':', KEY_SEMICOLON|CAPS_MASK},
    {'\'', KEY_QUOTE}, {'"', KEY_QUOTE|CAPS_MASK},
    {',', KEY_COMMA}, {'<', KEY_COMMA|CAPS_MASK},
    {'.', KEY_DOT}, {'>', KEY_DOT|CAPS_MASK},
    {'/', KEY_SLASH}, {'?', KEY_SLASH|CAPS_MASK},
    {' ', KEY_SPACE}
};

CharacterMap::const_iterator CharacterMap::begin() const {
    return const_iterator{staticCharMapEntries};
}

CharacterMap::const_iterator CharacterMap::end() const {
    return const_iterator{staticCharMapEntries + 95};
}

CharacterMap::const_iterator CharacterMap::find(Uint32 key) const {
    for (size_t i = 0; i < 95; ++i) {
        if (staticCharMapEntries[i].first == key) {
            return const_iterator{staticCharMapEntries + i};
        }
    }
    return end();
}

Uint32 CharacterMap::operator[](Uint32 key) const {
    auto it = find(key);
    if (it != end()) {
        return it->second;
    }
    return 0;
}

const CharacterMap _characterMap = {};

// --- _codeTable static definitions ---
// --- Table 0 ---
static const Uint16 ct0_A[] = {0x00C2, 0x00E2, 0x0102, 0x0103, 0x00C1, 0x00E1, 0x00C0, 0x00E0, 0x1EA2, 0x1EA3, 0x00C3, 0x00E3, 0x1EA0, 0x1EA1};
static const Uint16 ct0_O[] = {0x00D4, 0x00F4, 0x01A0, 0x01A1, 0x00D3, 0x00F3, 0x00D2, 0x00F2, 0x1ECE, 0x1ECF, 0x00D5, 0x00F5, 0x1ECC, 0x1ECD};
static const Uint16 ct0_U[] = {0x0000, 0x0000, 0x01AF, 0x01B0, 0x00DA, 0x00FA, 0x00D9, 0x00F9, 0x1EE6, 0x1EE7, 0x0168, 0x0169, 0x1EE4, 0x1EE5};
static const Uint16 ct0_E[] = {0x00CA, 0x00EA, 0x0000, 0x0000, 0x00C9, 0x00E9, 0x00C8, 0x00E8, 0x1EBA, 0x1EBB, 0x1EBC, 0x1EBD, 0x1EB8, 0x1EB9};
static const Uint16 ct0_D[] = {0x0110, 0x0111};
static const Uint16 ct0_A_T[] = {0x1EA4, 0x1EA5, 0x1EA6, 0x1EA7, 0x1EA8, 0x1EA9, 0x1EAA, 0x1EAB, 0x1EAC, 0x1EAD};
static const Uint16 ct0_A_TW[] = {0x1EAE, 0x1EAF, 0x1EB0, 0x1EB1, 0x1EB2, 0x1EB3, 0x1EB4, 0x1EB5, 0x1EB6, 0x1EB7};
static const Uint16 ct0_O_T[] = {0x1ED0, 0x1ED1, 0x1ED2, 0x1ED3, 0x1ED4, 0x1ED5, 0x1ED6, 0x1ED7, 0x1ED8, 0x1ED9};
static const Uint16 ct0_O_TW[] = {0x1EDA, 0x1EDB, 0x1EDC, 0x1EDD, 0x1EDE, 0x1EDF, 0x1EE0, 0x1EE1, 0x1EE2, 0x1EE3};
static const Uint16 ct0_U_TW[] = {0x1EE8, 0x1EE9, 0x1EEA, 0x1EEB, 0x1EEC, 0x1EED, 0x1EEE, 0x1EEF, 0x1EF0, 0x1EF1};
static const Uint16 ct0_E_T[] = {0x1EBE, 0x1EBF, 0x1EC0, 0x1EC1, 0x1EC2, 0x1EC3, 0x1EC4, 0x1EC5, 0x1EC6, 0x1EC7};
static const Uint16 ct0_I[] = {0x00CD, 0x00ED, 0x00CC, 0x00EC, 0x1EC8, 0x1EC9, 0x0128, 0x0129, 0x1ECA, 0x1ECB};
static const Uint16 ct0_Y[] = {0x00DD, 0x00FD, 0x1EF2, 0x1EF3, 0x1EF6, 0x1EF7, 0x1EF8, 0x1EF9, 0x1EF4, 0x1EF5};

static const CodeTableEntry ct0_entries[] = {
    { KEY_A, {ct0_A, 14} },
    { KEY_O, {ct0_O, 14} },
    { KEY_U, {ct0_U, 14} },
    { KEY_E, {ct0_E, 14} },
    { KEY_D, {ct0_D, 2} },
    { KEY_A | TONE_MASK, {ct0_A_T, 10} },
    { KEY_A | TONEW_MASK, {ct0_A_TW, 10} },
    { KEY_O | TONE_MASK, {ct0_O_T, 10} },
    { KEY_O | TONEW_MASK, {ct0_O_TW, 10} },
    { KEY_U | TONEW_MASK, {ct0_U_TW, 10} },
    { KEY_E | TONE_MASK, {ct0_E_T, 10} },
    { KEY_I, {ct0_I, 10} },
    { KEY_Y, {ct0_Y, 10} }
};

// --- Table 1 ---
static const Uint16 ct1_A[] = {0xA2, 0xA9, 0xA1, 0xA8, 0xB8, 0xB8, 0xB5, 0xB5, 0xB6, 0xB6, 0xB7, 0xB7, 0xB9, 0xB9};
static const Uint16 ct1_O[] = {0xA4, 0xAB, 0xA5, 0xAC, 0xE3, 0xE3, 0xDF, 0xDF, 0xE1, 0xE1, 0xE2, 0xE2, 0xE4, 0xE4};
static const Uint16 ct1_U[] = {0x00, 0x00, 0xA6, 0xAD, 0xF3, 0xF3, 0xEF, 0xEF, 0xF1, 0xF1, 0xF2, 0xF2, 0xF4, 0xF4};
static const Uint16 ct1_E[] = {0xA3, 0xAA, 0x00, 0x00, 0xD0, 0xD0, 0xCC, 0xCC, 0xCE, 0xCE, 0xCF, 0xCF, 0xD1, 0xD1};
static const Uint16 ct1_D[] = {0xA7, 0xAE};
static const Uint16 ct1_A_T[] = {0xCA, 0xCA, 0xC7, 0xC7, 0xC8, 0xC8, 0xC9, 0xC9, 0xCB, 0xCB};
static const Uint16 ct1_A_TW[] = {0xBE, 0xBE, 0xBB, 0xBB, 0xBC, 0xBC, 0xBD, 0xBD, 0xC6, 0xC6};
static const Uint16 ct1_O_T[] = {0xE8, 0xE8, 0xE5, 0xE5, 0xE6, 0xE6, 0xE7, 0xE7, 0xE9, 0xE9};
static const Uint16 ct1_O_TW[] = {0xED, 0xED, 0xEA, 0xEA, 0xEB, 0xEB, 0xEC, 0xEC, 0xEE, 0xEE};
static const Uint16 ct1_U_TW[] = {0xF8, 0xF8, 0xF5, 0xF5, 0xF6, 0xF6, 0xF7, 0xF7, 0xF9, 0xF9};
static const Uint16 ct1_E_T[] = {0xD5, 0xD5, 0xD2, 0xD2, 0xD3, 0xD3, 0xD4, 0xD4, 0xD6, 0xD6};
static const Uint16 ct1_I[] = {0xDD, 0xDD, 0xD7, 0xD7, 0xD8, 0xD8, 0xDC, 0xDC, 0xDE, 0xDE};
static const Uint16 ct1_Y[] = {0xFD, 0xFD, 0xFA, 0xFA, 0xFB, 0xFB, 0xFC, 0xFC, 0xFE, 0xFE};

static const CodeTableEntry ct1_entries[] = {
    { KEY_A, {ct1_A, 14} },
    { KEY_O, {ct1_O, 14} },
    { KEY_U, {ct1_U, 14} },
    { KEY_E, {ct1_E, 14} },
    { KEY_D, {ct1_D, 2} },
    { KEY_A | TONE_MASK, {ct1_A_T, 10} },
    { KEY_A | TONEW_MASK, {ct1_A_TW, 10} },
    { KEY_O | TONE_MASK, {ct1_O_T, 10} },
    { KEY_O | TONEW_MASK, {ct1_O_TW, 10} },
    { KEY_U | TONEW_MASK, {ct1_U_TW, 10} },
    { KEY_E | TONE_MASK, {ct1_E_T, 10} },
    { KEY_I, {ct1_I, 10} },
    { KEY_Y, {ct1_Y, 10} }
};

// --- Table 2 ---
static const Uint16 ct2_A[] = {0xC241, 0xE261, 0xCA41, 0xEA61, 0xD941, 0xF961, 0xD841, 0xF861, 0xDB41, 0xFB61, 0xD541, 0xF561, 0xCF41, 0xEF61};
static const Uint16 ct2_O[] = {0xC24F, 0xE26F, 0x00D4, 0x00F4, 0xD94F, 0xF96F, 0xD84F, 0xF86F, 0xDB4F, 0xFB6F, 0xD54F, 0xF56F, 0xCF4F, 0xEF6F};
static const Uint16 ct2_U[] = {0x0000, 0x0000, 0x00D6, 0x00F6, 0xD955, 0xF975, 0xD855, 0xF875, 0xDB55, 0xFB75, 0xD555, 0xF575, 0xCF55, 0xEF75};
static const Uint16 ct2_E[] = {0xC245, 0xE265, 0x0000, 0x0000, 0xD945, 0xF965, 0xD845, 0xF865, 0xDB45, 0xFB65, 0xD545, 0xF565, 0xCF45, 0xEF65};
static const Uint16 ct2_D[] = {0x00D1, 0x00F1};
static const Uint16 ct2_A_T[] = {0xC141, 0xE161, 0xC041, 0xE061, 0xC541, 0xE561, 0xC341, 0xE361, 0xC441, 0xE461};
static const Uint16 ct2_A_TW[] = {0xC941, 0xE961, 0xC841, 0xE861, 0xDA41, 0xFA61, 0xDC41, 0xFC61, 0xCB41, 0xEB61};
static const Uint16 ct2_O_T[] = {0xC14F, 0xE16F, 0xC04F, 0xE06F, 0xC54F, 0xE56F, 0xC34F, 0xE36F, 0xC44F, 0xE46F};
static const Uint16 ct2_O_TW[] = {0xD9D4, 0xF9F4, 0xD8D4, 0xF8F4, 0xDBD4, 0xFBF4, 0xD5D4, 0xF5F4, 0xCFD4, 0xEFF4};
static const Uint16 ct2_U_TW[] = {0xD9D6, 0xF9F6, 0xD8D6, 0xF8F6, 0xDBD6, 0xFBF6, 0xD5D6, 0xF5F6, 0xCFD6, 0xEFF6};
static const Uint16 ct2_E_T[] = {0xC145, 0xE165, 0xC045, 0xE065, 0xC545, 0xE565, 0xC345, 0xE365, 0xC445, 0xE465};
static const Uint16 ct2_I[] = {0x00CD, 0x00ED, 0x00CC, 0x00EC, 0x00C6, 0x00E6, 0x00D3, 0x00F3, 0x00D2, 0x00F2};
static const Uint16 ct2_Y[] = {0xD959, 0xF979, 0xD859, 0xF879, 0xDB59, 0xFB79, 0xD559, 0xF579, 0x00CE, 0x00EE};

static const CodeTableEntry ct2_entries[] = {
    { KEY_A, {ct2_A, 14} },
    { KEY_O, {ct2_O, 14} },
    { KEY_U, {ct2_U, 14} },
    { KEY_E, {ct2_E, 14} },
    { KEY_D, {ct2_D, 2} },
    { KEY_A | TONE_MASK, {ct2_A_T, 10} },
    { KEY_A | TONEW_MASK, {ct2_A_TW, 10} },
    { KEY_O | TONE_MASK, {ct2_O_T, 10} },
    { KEY_O | TONEW_MASK, {ct2_O_TW, 10} },
    { KEY_U | TONEW_MASK, {ct2_U_TW, 10} },
    { KEY_E | TONE_MASK, {ct2_E_T, 10} },
    { KEY_I, {ct2_I, 10} },
    { KEY_Y, {ct2_Y, 10} }
};

// --- Table 3 ---
static const Uint16 ct3_A[] = {0x00C2, 0x00E2, 0x0102, 0x0103, 0x2041, 0x2061, 0x4041, 0x4061, 0x6041, 0x6061, 0x8041, 0x8061, 0xA041, 0xA061};
static const Uint16 ct3_O[] = {0x00D4, 0x00F4, 0x01A0, 0x01A1, 0x204F, 0x206F, 0x404F, 0x406F, 0x604F, 0x606F, 0x804F, 0x806F, 0xA04F, 0xA06F};
static const Uint16 ct3_U[] = {0x0000, 0x0000, 0x01AF, 0x01B0, 0x2055, 0x2075, 0x4055, 0x4075, 0x6055, 0x6075, 0x8055, 0x8075, 0xA055, 0xA075};
static const Uint16 ct3_E[] = {0x00CA, 0x00EA, 0x0000, 0x0000, 0x2045, 0x2065, 0x4045, 0x4065, 0x6045, 0x6065, 0x8045, 0x8065, 0xA045, 0xA065};
static const Uint16 ct3_D[] = {0x0110, 0x0111};
static const Uint16 ct3_A_T[] = {0x20C2, 0x20E2, 0x40C2, 0x40E2, 0x60C2, 0x60E2, 0x80C2, 0x80E2, 0xA0C2, 0xA0E2};
static const Uint16 ct3_A_TW[] = {0x2102, 0x2103, 0x4102, 0x4103, 0x6102, 0x6103, 0x8102, 0x8103, 0xA102, 0xA103};
static const Uint16 ct3_O_T[] = {0x20D4, 0x20F4, 0x40D4, 0x40F4, 0x60D4, 0x60F4, 0x80D4, 0x80F4, 0xA0D4, 0xA0F4};
static const Uint16 ct3_O_TW[] = {0x21A0, 0x21A1, 0x41A0, 0x41A1, 0x61A0, 0x61A1, 0x81A0, 0x81A1, 0xA1A0, 0xA1A1};
static const Uint16 ct3_U_TW[] = {0x21AF, 0x21B0, 0x41AF, 0x41B0, 0x61AF, 0x61B0, 0x81AF, 0x81B0, 0xA1AF, 0xA1B0};
static const Uint16 ct3_E_T[] = {0x20CA, 0x20EA, 0x40CA, 0x40EA, 0x60CA, 0x60EA, 0x80CA, 0x80EA, 0xA0CA, 0xA0EA};
static const Uint16 ct3_I[] = {0x2049, 0x2069, 0x4049, 0x4069, 0x6049, 0x6069, 0x8049, 0x8069, 0xA049, 0xA069};
static const Uint16 ct3_Y[] = {0x2059, 0x2079, 0x4059, 0x4079, 0x6059, 0x6079, 0x8059, 0x8079, 0xA059, 0xA079};

static const CodeTableEntry ct3_entries[] = {
    { KEY_A, {ct3_A, 14} },
    { KEY_O, {ct3_O, 14} },
    { KEY_U, {ct3_U, 14} },
    { KEY_E, {ct3_E, 14} },
    { KEY_D, {ct3_D, 2} },
    { KEY_A | TONE_MASK, {ct3_A_T, 10} },
    { KEY_A | TONEW_MASK, {ct3_A_TW, 10} },
    { KEY_O | TONE_MASK, {ct3_O_T, 10} },
    { KEY_O | TONEW_MASK, {ct3_O_TW, 10} },
    { KEY_U | TONEW_MASK, {ct3_U_TW, 10} },
    { KEY_E | TONE_MASK, {ct3_E_T, 10} },
    { KEY_I, {ct3_I, 10} },
    { KEY_Y, {ct3_Y, 10} }
};

// --- Table 4 ---
static const Uint16 ct4_A[] = {0x00C2, 0x00E2, 0x00C3, 0x00E3, 0xEC41, 0xEC61, 0xCC41, 0xCC61, 0xD241, 0xD261, 0xDE41, 0xDE61, 0xF241, 0xF261};
static const Uint16 ct4_O[] = {0x00D4, 0x00F4, 0x00D5, 0x00F5, 0xEC4F, 0xEC6F, 0xCC4F, 0xCC6F, 0xD24F, 0xD26F, 0xDE4F, 0xDE6F, 0xF24F, 0xF26F};
static const Uint16 ct4_U[] = {0x0000, 0x0000, 0x00DD, 0x00FD, 0xEC55, 0xEC75, 0xCC55, 0xCC75, 0xD255, 0xD275, 0xDE55, 0xDE75, 0xF255, 0xF275};
static const Uint16 ct4_E[] = {0x00CA, 0x00EA, 0x0000, 0x0000, 0xEC45, 0xEC65, 0xCC45, 0xCC65, 0xD245, 0xD265, 0xDE45, 0xDE65, 0xF245, 0xF265};
static const Uint16 ct4_D[] = {0x00D0, 0x00F0};
static const Uint16 ct4_A_T[] = {0xECC2, 0xECE2, 0xCCC2, 0xCCE2, 0xD2C2, 0xD2E2, 0xDEC2, 0xDEE2, 0xF2C2, 0xF2E2};
static const Uint16 ct4_A_TW[] = {0xECC3, 0xECE3, 0xCCC3, 0xCCE3, 0xD2C3, 0xD2E3, 0xDEC3, 0xDEE3, 0xF2C3, 0xF2E3};
static const Uint16 ct4_O_T[] = {0xECD4, 0xECF4, 0xCCD4, 0xCCF4, 0xD2D4, 0xD2F4, 0xDED4, 0xDEF4, 0xF2D4, 0xF2D4};
static const Uint16 ct4_O_TW[] = {0xECD5, 0xECF5, 0xCCD5, 0xCCF5, 0xD2D5, 0xD2F5, 0xDED5, 0xDEF5, 0xF2D5, 0xF2D5};
static const Uint16 ct4_U_TW[] = {0xECDD, 0xECFD, 0xCCDD, 0xCCFD, 0xD2DD, 0xD2FD, 0xDEDD, 0xDEFD, 0xF2DD, 0xF2FD};
static const Uint16 ct4_E_T[] = {0xECCA, 0xECEA, 0xCCCA, 0xCCEA, 0xD2CA, 0xD2EA, 0xDECA, 0xDEEA, 0xF2CA, 0xF2EA};
static const Uint16 ct4_I[] = {0xEC49, 0xEC69, 0xCC49, 0xCC69, 0xD249, 0xD269, 0xDE49, 0xDE69, 0xF249, 0xF269};
static const Uint16 ct4_Y[] = {0xEC59, 0xEC79, 0xCC59, 0xCC79, 0xD259, 0xD279, 0xDE59, 0xDE59, 0xF259, 0xF259};

static const CodeTableEntry ct4_entries[] = {
    { KEY_A, {ct4_A, 14} },
    { KEY_O, {ct4_O, 14} },
    { KEY_U, {ct4_U, 14} },
    { KEY_E, {ct4_E, 14} },
    { KEY_D, {ct4_D, 2} },
    { KEY_A | TONE_MASK, {ct4_A_T, 10} },
    { KEY_A | TONEW_MASK, {ct4_A_TW, 10} },
    { KEY_O | TONE_MASK, {ct4_O_T, 10} },
    { KEY_O | TONEW_MASK, {ct4_O_TW, 10} },
    { KEY_U | TONEW_MASK, {ct4_U_TW, 10} },
    { KEY_E | TONE_MASK, {ct4_E_T, 10} },
    { KEY_I, {ct4_I, 10} },
    { KEY_Y, {ct4_Y, 10} }
};

const CodeTable _codeTable[] = {
    { ct0_entries, 13 },
    { ct1_entries, 13 },
    { ct2_entries, 13 },
    { ct3_entries, 13 },
    { ct4_entries, 13 }
};

// sắc, huyền, hỏi, ngã, nặng - for Unicode Compound
Uint16 _unicodeCompoundMark[] = {0x0301, 0x0300, 0x0309, 0x0303, 0x0323};

static Uint16 _keyCodeToCharTable[128][2] = {0};
static bool _keyCodeToCharTableInitialized = false;

void initKeyCodeToCharTable() {
    if (_keyCodeToCharTableInitialized) return;
    for (auto it = _characterMap.begin(); it != _characterMap.end(); ++it) {
        Uint32 val = it->second;
        unsigned int key = val & CHAR_MASK;
        unsigned int caps = (val & CAPS_MASK) ? 1 : 0;
        if (key < 128) {
            _keyCodeToCharTable[key][caps] = it->first;
        }
    }
    _keyCodeToCharTableInitialized = true;
}

Uint16 keyCodeToCharacter(const Uint32& keyCode) {
    if (!_keyCodeToCharTableInitialized) {
        initKeyCodeToCharTable();
    }
    unsigned int key = keyCode & CHAR_MASK;
    unsigned int caps = (keyCode & CAPS_MASK) ? 1 : 0;
    if (key < 128) {
        Uint16 ch = _keyCodeToCharTable[key][caps];
        if (ch != 0) return ch;
    }
    return 0;
}
