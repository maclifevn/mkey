#include "VietnameseDictionary.h"
#include "Vietnamese.h"
#include <algorithm>
#include <cstring>

namespace {
#include "VietnameseDictionaryData.h"
}

bool vIsVietnameseWord(const Uint32* word, size_t count) {
    if (!word || count == 0 || count > kMaxWordLength)
        return false;

    char encoded[kMaxWordLength * 2 + 1];
    for (size_t index = 0; index < count; index++) {
        const Uint32 cell = word[index];
        if (cell & ~(CHAR_MASK | CAPS_MASK | TONE_MASK | TONEW_MASK | MARK_MASK | STANDALONE_MASK))
            return false;
        const char base = (char)keyCodeToCharacter(cell & CHAR_MASK);
        if (base < 'a' || base > 'z')
            return false;

        int shape = 0;
        if (cell & TONE_MASK) {
            if ((cell & TONEW_MASK) || (base != 'a' && base != 'e' && base != 'o' && base != 'd'))
                return false;
            shape = 1;
        } else if (cell & TONEW_MASK) {
            if (base != 'a' && base != 'o' && base != 'u')
                return false;
            shape = 2;
        }
        int tone = 0;
        switch (cell & MARK_MASK) {
            case 0: break;
            case MARK1_MASK: tone = 1; break;
            case MARK2_MASK: tone = 2; break;
            case MARK3_MASK: tone = 3; break;
            case MARK4_MASK: tone = 4; break;
            case MARK5_MASK: tone = 5; break;
            default: return false;
        }
        if (tone && base != 'a' && base != 'e' && base != 'i' && base != 'o' && base != 'u' && base != 'y')
            return false;
        encoded[index * 2] = base;
        encoded[index * 2 + 1] = (char)('a' + shape * 6 + tone);
    }
    encoded[count * 2] = '\0';
    return std::binary_search(std::begin(kVietnameseWords), std::end(kVietnameseWords), encoded,
                              [](const char* left, const char* right) { return std::strcmp(left, right) < 0; });
}

bool vIsVietnamesePrefix(const Uint32* word, size_t count) {
    if (!word || count == 0 || count > kMaxWordLength)
        return false;

    char prefix[kMaxWordLength + 1];
    for (size_t index = 0; index < count; index++) {
        const Uint32 cell = word[index];
        if (cell & ~(CHAR_MASK | CAPS_MASK | TONE_MASK | TONEW_MASK | MARK_MASK | STANDALONE_MASK))
            return false;
        const char base = (char)keyCodeToCharacter(cell & CHAR_MASK);
        if (base < 'a' || base > 'z')
            return false;
        if ((cell & TONE_MASK) &&
            ((cell & TONEW_MASK) || (base != 'a' && base != 'e' && base != 'o' && base != 'd')))
            return false;
        if ((cell & TONEW_MASK) && base != 'a' && base != 'o' && base != 'u')
            return false;
        const Uint32 tone = cell & MARK_MASK;
        if (tone && ((tone & (tone - 1)) || !std::strchr("aeiouy", base)))
            return false;
        prefix[index] = base;
    }
    prefix[count] = '\0';
    const auto found = std::lower_bound(std::begin(kVietnameseWordBases), std::end(kVietnameseWordBases), prefix,
                                        [](const char* left, const char* right) { return std::strcmp(left, right) < 0; });
    return found != std::end(kVietnameseWordBases) && std::strncmp(*found, prefix, count) == 0;
}
