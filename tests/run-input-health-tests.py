#!/usr/bin/env python3
"""Test the actual monitoring policy and bridge, without global input access."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]

def run(*args):
    subprocess.run(list(map(str, args)), check=True, cwd=root)

with tempfile.TemporaryDirectory(prefix='mkey-input-health-') as temporary:
    work = Path(temporary)
    run('xcrun', 'swiftc', 'Sources/App/InputHealthMonitor.swift',
        'tests/InputHealthMonitorTests.swift', '-o', work / 'monitor-tests')
    run(work / 'monitor-tests')
    common = ['-std=c++17', '-I', root / 'Sources/Engine', '-I', root / 'Sources/Platform']
    run('xcrun', 'clang++', *common, '-fobjc-arc',
        '-DCGEventTapCreate=TestTapCreate', '-DCGEventTapIsEnabled=TestTapIsEnabled',
        '-DCGEventTapEnable=TestTapEnable', '-DIsSecureEventInputEnabled=TestSecureInput',
        '-c', 'Sources/Platform/MKBridge.mm', '-o', work / 'bridge.o')
    run('xcrun', 'clang++', *common, '-fobjc-arc', '-c', 'tests/EventTapRecoveryTests.mm',
        '-o', work / 'lifecycle.o')
    run('xcrun', 'clang++', *common, work / 'bridge.o', work / 'lifecycle.o',
        *sorted((root / 'Sources/Engine').glob('*.cpp')),
        '-framework', 'Cocoa', '-framework', 'Carbon', '-o', work / 'lifecycle-tests')
    run(work / 'lifecycle-tests')
    run('xcrun', 'clang++', *common, '-fobjc-arc', '-c', 'Sources/Platform/MKBridge.mm',
        '-o', work / 'real-bridge.o')
    run('xcrun', 'clang++', *common, '-fobjc-arc', '-c', 'Sources/Platform/MKEngineHook.mm',
        '-o', work / 'real-hook.o')
    run('xcrun', 'clang++', *common, '-fobjc-arc', '-c', 'tests/InputInterruptionResetTests.mm',
        '-o', work / 'reset.o')
    run('xcrun', 'clang++', *common, work / 'real-bridge.o', work / 'real-hook.o', work / 'reset.o',
        *sorted((root / 'Sources/Engine').glob('*.cpp')),
        '-framework', 'Cocoa', '-framework', 'Carbon', '-o', work / 'reset-tests')
    run(work / 'reset-tests')
