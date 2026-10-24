#ifndef VietnameseDictionary_h
#define VietnameseDictionary_h

#include <cstddef>
#include "DataType.h"

// Raw TypingWord cells; case-insensitive, preserving letter shape and tone position.
bool vIsVietnameseWord(const Uint32* word, size_t count);

// Possible syllable prefix by base letters, allowing shape/tone keys entered later.
bool vIsVietnamesePrefix(const Uint32* word, size_t count);

#endif /* VietnameseDictionary_h */
