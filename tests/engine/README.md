# Engine regression harness

Run `./tests/engine/run.sh` from any directory. It compiles this repository's
`Sources/Engine/*.cpp` with clang++ in C++17 mode into a temporary directory;
Xcode is not needed. Each case uses a fresh process so the engine's static
history cannot leak between cases. `SANITIZE=1 ./tests/engine/run.sh` additionally
enables AddressSanitizer and UndefinedBehaviorSanitizer.

The CLI can inspect a sequence, including the engine's response per key:

```sh
./tests/engine/run.sh --probe 'telex,restore=1' 'tieengs vieetj ' --trace
```

`baseline.tsv` contains independently authored expected text. Its 404 cases
cover Telex, VNI, simple Telex, spelling on/off, both tone-placement styles,
quick Telex, free marks, uppercase/Shift/Caps Lock, English restoration, macros,
backspace, punctuation, Enter, Tab, cursor movement, mouse and session boundaries.
Settings omitted in a row use the values in `MKBridge.mm` (Unicode, spelling on,
modern orthography on, macros on, restoration/quick Telex/free marks off).
Fixtures are `btw`, `vn`, `dc`, and `longmacro`; production preferences are never
read or changed. Input is ASCII physical US ANSI keystrokes, output is UTF-8.
Special keys: `<BS>`, `<ENTER>`, `<KPENTER>`, `<TAB>`, `<LEFT>`, `<RIGHT>`, `<ESC>`,
`<CAPS>`, `<MOUSE>`, `<SESSION>`. JSON strings in `expected` preserve trailing
spaces, tabs and newlines. Normal quotes in TSV are CSV escaping.

The simulated text field follows `MKEngineHook.mm`'s Unicode delivery contract:

- `vKeyInit()` and `startNewSession()` initialize the engine.
- Each key goes through `vKeyHandleEvent()` (or `vEnglishMode()` for English
  macro cases). `vDoNothing` forwards the original key, including backspace.
- `vWillProcess` replaces `backspaceCount` characters with **reversed** `charData`.
  The hook's strict `< MAX_BUFF` deletion guard is retained.
- `vRestore` and `vRestoreAndStartNewSession` additionally forward the original
  trigger; the latter then clears the word. Control keys are forwarded too.
- `vReplaceMaro` inserts **forward** `macroData`, then the original trigger.
- `PURE_CHARACTER_MASK` / `CHAR_CODE_MASK` use the low 16 bits; other output
  entries are physical keycodes with `CAPS_MASK`. `extCode` only affects the
  hook's multicode-table bookkeeping, so Unicode has no extra action for it.

This is an engine test, not an event-tap/UI test. It does not model asynchronous
apps, inline selection, Accessibility replacement, injected event timing,
non-US layouts, simultaneous Shift+Caps Lock, other encodings, or emoji. The
empty-character browser workaround has no net text effect in this field;
its real-app behavior requires manual testing. Macro chunk boundaries likewise
need manual testing.

`baseline-results.json` is the immutable **pre-fix** observation at MKey HEAD
`e8fdc10` on 2026-10-23, with the user's pre-existing working-tree changes left
in place (none in `Sources/Engine`). Expected values were not replaced with
observed values. Five English restoration cases initially failed; the runner
accepts only their exact recorded output in `known-failures.json`. A changed
known failure is an error, including an unexpected pass, until reviewed.
When a targeted upstream fix resolves one, remove its known-failure exemption
and add focused coverage to `regressions.tsv`; retain the original observation.

To check an engine regression against the saved pre-fix MKey source, set
`MKEY_ENGINE_SOURCE` to that local snapshot. Do not point it at downloaded
upstream code: this investigation only reads upstream sources.
