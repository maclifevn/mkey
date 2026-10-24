#!/bin/bash
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
engine_source="${MKEY_ENGINE_SOURCE:-$repo_root/Sources/Engine}"
test_build="$(mktemp -d "${TMPDIR:-/tmp}/mkey-engine.XXXXXX")"
trap 'rm -rf "$test_build"' EXIT
compiler_flags=(-std=c++17 -g -Wall -Wextra -Wno-sign-compare -Wno-unused-parameter)
python3 "$repo_root/scripts/generate-vietnamese-dictionary.py" --check
if [[ "${SANITIZE:-0}" == 1 ]]; then
    compiler_flags+=(-O1 -fsanitize=address,undefined -fno-sanitize-recover=all -fno-omit-frame-pointer)
else
    compiler_flags+=(-O0)
fi
clang++ "${compiler_flags[@]}" -I "$engine_source" \
    "$repo_root/tests/engine/harness.cpp" "$repo_root/tests/engine/hook-contract.cpp" \
    "$repo_root/tests/engine/dictionary-contract.cpp" "$repo_root/tests/engine/free-mark-gi-contract.cpp" \
    "$engine_source"/*.cpp \
    -o "$test_build/engine-harness"
if [[ "${1:-}" == --probe ]]; then
    shift
    "$test_build/engine-harness" "$@"
else
    "$test_build/engine-harness" --check-contract
    python3 "$repo_root/tests/engine/run.py" "$test_build/engine-harness" "$@"
fi
