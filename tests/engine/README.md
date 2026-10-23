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
Fixtures are `btw`, `vn`, `dc`, `longmacro`, `ưds`, `test`, `r`, and `ko`;
production preferences are never read or changed. Input is ASCII physical US
ANSI keystrokes, output is UTF-8.
Special keys: `<BS>`, `<ENTER>`, `<KPENTER>`, `<TAB>`, `<LEFT>`, `<RIGHT>`, `<ESC>`,
`<CAPS>`, `<MOUSE>`, `<SESSION>`. JSON strings in `expected` preserve trailing
spaces, tabs and newlines. Normal quotes in TSV are CSV escaping.
`<ENGINEOFF>` and `<ENGINEON>` call `vTempOffEngine(true/false)` without
inserting text, to verify that bypassed keys cannot reuse stale restoration data.
`<MOD+ENTER>`, `<MOD+SHIFT+ENTER>`, `<MOD+DOT>`, `<MOD+SHIFT+DOT>` and
`<MOD+SHIFT+COMMA>` set the engine's shared other-control flag (Command,
Control, Option, Fn, etc.). The fake field does not insert text for shortcuts;
it checks that they do not spuriously expand a macro. `<SHIFT+ENTER>` has Shift
alone and remains an ordinary Return trigger. Real shortcut actions need UI QA.

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
  entries are physical keycodes with `CAPS_MASK`. `extCode` 1/2/3 changes the
  hook's multicode-table bookkeeping, so Unicode has no extra action for these.
- The ordinary event path's autocomplete workaround inserts U+202F, increments
  the response's Byte backspace count, then applies the hook's deletion guard;
  `extCode == 4` skips this for character replacement. Macro replacement has no
  such guard. Set `recommend=0` to disable this modeled workaround. Trace shows
  the engine response before the hook adjusts it.

This is an engine test, not an event-tap/UI test. It does not model asynchronous
apps, inline selection, Accessibility replacement, injected event timing,
non-US layouts, simultaneous Shift+Caps Lock, other encodings, or emoji. Its
ordinary event path assumes a non-nice-space app, no autocomplete selection,
and Chromium's special fix off. Browser selection and the U+200C alternative
still need manual testing. The MAX_BUFF boundary is retained, including the
hook's failure to delete if the workaround raises a count of 31 to 32. Macro
chunk boundaries likewise need manual testing. English mode ignores mouse
notifications, as the hook returns before Vietnamese mouse handling.

`baseline-results.json` is the immutable **pre-fix** observation at MKey HEAD
`e8fdc10` on 2026-10-23, with the user's pre-existing working-tree changes left
in place (none in `Sources/Engine`). Expected values were not replaced with
observed values. Five English restoration cases initially failed; the runner
accepts only their exact recorded output in `known-failures.json`. A changed
known failure is an error, including an unexpected pass, until reviewed.
When a targeted upstream fix resolves one, remove its known-failure exemption
and add focused coverage to `regressions.tsv`; retain the original observation.

`regressions.tsv` holds 580 cases for the eleven typing fixes. These include
22 cases for restoration history (13 failed before its guard) and 75 cases for
case-insensitive TH/Q horn handling (54 failed before the fix). Another 54
verify tone encoding when undoing circumflex/horn (46 failed before the fix).
349 cases cover missing late-đ patterns, including invalid prefixes and blocked
tones; 220 failed before the pattern additions. The five English baseline observations
remain unchanged by the user's explicit choice to preserve current Telex
escapes; the report records that decision.
`screened.tsv` holds
19 pre-fix passing probes for upstream bugs MKey already avoids, 72 guards for
the chosen Telex escape policy, and three delivery-contract checks. Default
runs also include `convert.tsv`: 626 independently authored Unicode conversion
cases (230 failed before the casing fix), for 1704 cases across four tables.
Rejected candidates that failed separate research probes are documented in
`docs/upstream-fixes-report.md`; they are not silently accepted as new XFAILs.

The same CLI calls `convertUtil()` directly when settings start with `convert`:

```sh
./tests/engine/run.sh --probe 'convert,case=keep,remove=1,from=0,to=0' 'ĐƯỜNG NÉT'
```

Conversion input is literal UTF-8, bypassing physical-key replay. `case` accepts
`keep`, `upper`, `lower`, `sentence` or `words`; `remove` is 0/1 and code tables
are 0 through 4. Fixtures use Unicode precomposed/compound (0/3). The driver
requires exactly one terminal NUL from the API and rejects interior NULs before
printing user-visible text, matching the NSString wrapper. Expected strings
come from explicit Vietnamese letters and standard Unicode mappings, not engine
tables. Mixed-case guards preserve the existing Sentence/Words lower-rest rule.
Compound-output fixtures end in ASCII to isolate a pre-existing last-character
representation issue that this casing fix does not address.

To check an engine regression against the saved pre-fix MKey source, set
`MKEY_ENGINE_SOURCE` to that local snapshot. Do not point it at downloaded
upstream code: this investigation only reads upstream sources.
