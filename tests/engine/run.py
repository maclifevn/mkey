#!/usr/bin/env python3
"""Run independent engine cases; pre-existing failures must match recorded output."""
import argparse
import csv
import json
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent
parser = argparse.ArgumentParser()
parser.add_argument('binary')
parser.add_argument('--suite', type=pathlib.Path, action='append')
parser.add_argument('--record', type=pathlib.Path)
args = parser.parse_args()
suites = args.suite or [ROOT/'baseline.tsv', ROOT/'regressions.tsv', ROOT/'screened.tsv']
known_path = ROOT/'known-failures.json'
known = json.loads(known_path.read_text()) if known_path.exists() else {}
results = []
passed = xfailed = failed = 0
ids = set()
for suite in suites:
    if not suite.exists():
        sys.exit(f'Missing suite: {suite}')
    with suite.open(newline='') as stream:
        for case in csv.DictReader(stream, delimiter='\t'):
            case_id = case['id']
            if case_id in ids:
                sys.exit(f'Duplicate case id: {case_id}')
            ids.add(case_id)
            p = subprocess.run([args.binary, case['settings'], case['keys']],
                               capture_output=True, text=True, timeout=10)
            # TSV escapes keep TAB/ENTER and trailing spaces reviewable.
            expected = json.loads(case['expected'])
            actual = p.stdout
            result = dict(case, expected=expected, actual=actual, exit_code=p.returncode)
            if p.returncode:
                result['status'] = 'ERROR'
                failed += 1
                print(f"ERROR {case_id}: {p.stderr}", file=sys.stderr)
            elif case_id in known:
                if actual == known[case_id]['actual'] and actual != expected:
                    result['status'] = 'XFAIL'
                    xfailed += 1
                else:
                    result['status'] = 'CHANGED_BASELINE'
                    failed += 1
                    print(f"CHANGED_BASELINE {case_id}: expected original {known[case_id]['actual']!r}; got {actual!r}")
            elif actual == expected:
                result['status'] = 'PASS'
                passed += 1
            else:
                result['status'] = 'FAIL'
                failed += 1
                print(f"FAIL {case_id} | {case['settings']} | {case['keys']!r} -> {actual!r}; expected {expected!r}")
            results.append(result)
if args.record:
    if args.record.exists():
        sys.exit(f'Refusing to replace existing baseline: {args.record}')
    args.record.write_text(json.dumps(results, ensure_ascii=False, indent=2)+'\n')
print(f'{passed} PASS, {xfailed} known baseline failures, {failed} FAIL/ERROR ({len(results)} cases)')
sys.exit(bool(failed))
