# Vietnamese syllable data

Pinned source: [1ec5/hunspell-vi@39cc647f0cf3bdfc579980a2c3aac3f6f4203fe6](https://github.com/1ec5/hunspell-vi/tree/39cc647f0cf3bdfc579980a2c3aac3f6f4203fe6).
The two `.dic` files here are unchanged upstream data. `LICENSE` is the port's
explicit GPLv3-or-later notice. `Copyright` is the original notice from
[GNU Aspell Vietnamese 0.01.1-1](https://ftp.gnu.org/gnu/aspell/dict/vi/aspell6-vi-0.01.1-1.tar.bz2).
That original grant specifies GNU GPL without a version; the port grants GPLv3
or later. Preserve both notices. `GPL-3.0.txt` contains the full license.

Data credits: Hồ Ngọc Đức (Free Vietnamese Dictionary Project), László Németh
(Aspell/Hunspell conversion), Ivan Garcia and Minh Nguyễn (corrections/packaging).

MKey modification, 2026-10-24: `scripts/generate-vietnamese-dictionary.py` verifies
the original hashes and entry counts, unions old/new tone styles, normalizes
NFC/lowercase, filters single-syllable shapes, and generates a sorted static
lookup table. No upstream programs are run. The filter removes 32 non-syllable
entries such as acronyms and multisyllabic loans; it contains no English-word
blacklist and does not synthesize words. The resulting 6,678 syllables have
SHA256 `c99eb94c7d0305bc40e4397f45649abbc83087de9666fa7de4b4f6d29351a49d`
when sorted by Unicode and written as UTF-8 lines with a final newline.

Input SHA256:

- `vi-DauCu.dic`: `50b23ff20ea83ad886e2ff166220d53b307784c9870fb447341e0f298f0e5588`
- `vi-DauMoi.dic`: `a075773a27729713a1f5853404c7aafbb78e9056a12ccd729c19622953723143`

Run the MKey generator to regenerate; use `--check` to verify reproducibility.
The engine validates proposed whole syllables against this data. It does not
infer English intent, choose a nearest word, or restore raw Telex key sequences.
Both tone styles are retained so an existing valid spelling is left alone.
