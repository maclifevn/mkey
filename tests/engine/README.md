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
Fixtures are `btw`, `vn`, `dc`, `longmacro`, `ưds`, `test`, `r`, and `ko`,
plus three explicit long-vowel macro keys for redraw window/prefix checks;
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
  The hook and harness use the same bounded deletion policy in `DataType.h`.
  The legacy `< MAX_BUFF` guard remains; only a Unicode WillProcess packet
  explicitly marked `vUnicodeFullRedraw` may delete its full 31/32-character
  replacement span (plus the sentinel actually inserted by the hook).
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
still need manual testing. Untagged packets retain the MAX_BUFF boundary,
including the old guard when a count of 31 becomes 32. Macro
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
cases (230 failed before the casing fix). `redraw.tsv` adds 411 cases:
71 short-word cases, 280 boundary/edit/history cases, four guards outside the
active window, 36 macro cases and 20 tone/undo/prefix cases. 379 failed before
the redraw repair; all 411 pass after it. Expected text stays independent of
rendered engine output, including the correct nonduplicated text at 31/32.
`quick-start.tsv` adds 119 dictionary-backed quick-start cases: English F/J/W,
Vietnamese syllables, combined quick endings, case, macro/history, word breaks,
Telex escapes and 31/32/33-character unknown words. Before the guard, 45 text
cases failed and three oversized packets were rejected by the harness; all 119
pass afterwards. The user's chosen priority keeps fan→phan and fun→phun when
the complete expansion is in the Vietnamese dictionary.
`quick-telex.tsv` adds 721 cases for dictionary-backed double-consonant typing.
459 fail before this guard; all 721 pass afterwards. It checks App/Apple and
all seven quick pairs, valid Vietnamese onsets/codas, later tone/shape input,
case, spelling/free-mark/restore settings, combined quick-start/end options,
word breaks, macros/history, bypass, escapes and long-word boundaries.
The guard previews the complete candidate (including an enabled quick onset)
and checks its base-letter prefix against 1555 forms derived from the same
6678 syllables. This preserves pp before a later vowel and bach before a later
tone. It does not defer or replay input at the word boundary. A valid Vietnamese
prefix still takes priority in ambiguous English sequences. Non-Unicode output
keeps the previous Quick Telex path.
`free-mark.tsv` adds 622 cases for late circumflex/horn handling with free marks
enabled. Its independently written words cover 32 families and include Telex,
VNI, spelling/restoration, both tone styles, case, macros, word breaks, editing,
and tone/shape cancellation after correction. Before this fix, 509 failed and
113 passed; all 622 pass afterwards. The helper moves a single tone only when
exactly one whole syllable in the dictionary matches. It preserves every other
cell bit and skips already valid words, ordinary letter appends, Restore,
standalone characters, multiple tones, overflow and non-Unicode output.
The original shape-only change kept GI append behavior. The later GI fix below
updates ten explicit GISUP expectations after the user's canonical-escape
decision; their original values remain in Git at e3f343f.

`free-mark-gi.tsv` adds 539 cases for a GI word completed by an ordinary final
consonant. Before the fix, 256 failed and 283 passed; all 539 pass afterwards.
The dictionary moves the early tone on GI's I only when exactly one complete
syllable matches, retaining every letter/shape/case bit. Escape is compared with
the existing canonical input: gisups→giups like giupss, and gisupf→giùp like
giuspf. The ten changed GISUP expectations in `free-mark.tsv` are deliberate
corrections authorized by the user; baseline/known failures/72 escape guards
are unchanged. Intermediate gisu, unknown words, standalone W/brackets,
ordinary vowels, and invalid raw-history ownership stay outside the new path.
48 state guards cover engine bypass and edited prefixes; this prevents the
prototype's gisu<ENGINEOFF>q<ENGINEON>p redraw from corrupting the field.
Default runs total 4116 cases across nine tables (4111 pass, five exact known
baseline failures). They also execute `hook-contract.cpp`: 46 explicit packet
policy fixtures and 16 real-engine packet lifetime/non-Unicode checks.
Restore packets keep the legacy boundary; redraw expansion is WillProcess-only
to preserve Telex replay and avoid widening an unverified macro/history path.
Rejected candidates that failed separate research probes are documented in
`docs/upstream-fixes-report.md`; they are not silently accepted as new XFAILs.

`dictionary-contract.cpp` checks 22 independent raw-cell membership fixtures
and 27 prefix fixtures (including flags, late marks, null and length guards),
including both tone styles, letter shapes, uppercase, unsupported flags and
tone positions. `run.sh` also verifies the pinned dictionary input hashes and
reproduces the generated 6678-entry table; it does not fetch data or run any
upstream scripts. Data provenance and GPL notices are in
`third_party/hunspell-vi/` and `Sources/Engine/VietnameseDictionary-NOTICE.txt`.

`free-mark-gi-contract.cpp` adds 24 packet/macro/escape checks (all failed before
the GI fix). They verify Telex/VNI, case and spelling: the host's pending coda
needs BPC=2/NCC=3/ext4, macroKey must contain corrected giúp/GIÚP, repeated tone
uses Restore, and both explicit macro fixtures expand. Total contract checks:
108. No macro fixture is added to the normal text-case processes or the app.

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
Use the matching saved harness when the engine/hook header protocol differs;
the redraw pre-fix run uses its original harness with only the same test macro
fixtures added, not a compatibility shim that hides the old deletion guard.
