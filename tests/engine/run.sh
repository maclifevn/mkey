#!/bin/bash
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
engine_source="${MKEY_ENGINE_SOURCE:-$repo_root/Sources/Engine}"
test_build="$(mktemp -d "${TMPDIR:-/tmp}/mkey-engine.XXXXXX")"
trap 'rm -rf "$test_build"' EXIT
compiler_flags=(-std=c++17 -g -Wall -Wextra -Wno-sign-compare -Wno-unused-parameter)
if [[ "${SANITIZE:-0}" == 1 ]]; then
    compiler_flags+=(-O1 -fsanitize=address,undefined -fno-omit-frame-pointer)
else
    compiler_flags+=(-O0)
fi
clang++ "${compiler_flags[@]}" -I "$engine_source" \
    "$repo_root/tests/engine/harness.cpp" "$engine_source"/*.cpp \
    -o "$test_build/engine-harness"
if [[ "${1:-}" == --probe ]]; then
    shift
    "$test_build/engine-harness" "$@"
else
    python3 "$repo_root/tests/engine/run.py" "$test_build/engine-harness" "$@"
fi
