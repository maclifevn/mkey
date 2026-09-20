#!/usr/bin/env python3
"""Exercise the real updater in disposable app bundles; no update is installed."""
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import os
import plistlib
import shutil
import subprocess
import sys
import tempfile
import threading
import uuid

root = Path(__file__).resolve().parents[1]
products = root / 'build/DerivedData/Build/Products/Release'
feed = Path(sys.argv[1]).resolve()

with tempfile.TemporaryDirectory(prefix='mkey-update-smoke-') as temporary:
    work = Path(temporary)
    shutil.copy(feed, work / 'valid.xml')
    # Keep valid XML; alter signed content so rejection is about the signature.
    contents = feed.read_bytes()
    index = contents.index(b'<title>') + len(b'<title>')
    (work / 'tampered.xml').write_bytes(contents[:index] + bytes([contents[index] ^ 1]) + contents[index + 1:])
    server = ThreadingHTTPServer(('127.0.0.1', 0), partial(SimpleHTTPRequestHandler, directory=str(work)))
    threading.Thread(target=server.serve_forever, daemon=True).start()
    executable = work / 'Smoke'
    subprocess.run(['xcrun', 'swiftc', '-D', 'DEBUG', '-parse-as-library',
                    str(root / 'Sources/App/UpdateRuntimePolicy.swift'),
                    str(root / 'Sources/App/UpdateChecker.swift'),
                    str(root / 'tests/UpdateControllerSmoke.swift'),
                    '-F', str(products), '-framework', 'Sparkle',
                    '-Xlinker', '-rpath', '-Xlinker', '@executable_path/../Frameworks',
                    '-o', str(executable)], check=True)
    with (products / 'mkey.app/Contents/Info.plist').open('rb') as f:
        shipping_info = plistlib.load(f)
    current_build = shipping_info['CFBundleVersion']
    previous_build = str(int(current_build) - 1)
    try:
        for scenario, build, endpoint in [('upToDate', current_build, 'valid.xml'),
                                           ('available', previous_build, 'valid.xml'),
                                           ('failed', previous_build, 'tampered.xml'),
                                           ('failed', previous_build, 'missing.xml')]:
            identity = 'vn.mkey.updater-smoke.' + uuid.uuid4().hex
            app = Path('/Applications') / ('MKey-Updater-Smoke-' + uuid.uuid4().hex + '.app')
            try:
                (app / 'Contents/MacOS').mkdir(parents=True)
                (app / 'Contents/Frameworks').mkdir()
                shutil.copy(executable, app / 'Contents/MacOS/Smoke')
                subprocess.run(['ditto', str(products / 'Sparkle.framework'), str(app / 'Contents/Frameworks/Sparkle.framework')], check=True)
                info = dict(shipping_info)
                info.update(CFBundleIdentifier=identity, CFBundleExecutable='Smoke', CFBundleName='MKey Update Test',
                            CFBundleVersion=build, SUEnableAutomaticChecks=False,
                            SUFeedURL=f'http://127.0.0.1:{server.server_port}/{endpoint}',
                            NSAppTransportSecurity={'NSAllowsLocalNetworking': True})
                with (app / 'Contents/Info.plist').open('wb') as f:
                    plistlib.dump(info, f)
                subprocess.run(['codesign', '--force', '--sign', '-', str(app)], check=True, capture_output=True)
                result = work / (identity + '.txt')
                environment = dict(os.environ, MKEY_ENABLE_UPDATES='1', MKEY_SMOKE_EXPECTED=scenario, MKEY_SMOKE_RESULT=str(result))
                subprocess.run([str(app / 'Contents/MacOS/Smoke')], env=environment, timeout=35, check=True)
                message = result.read_text()
                print(f'{endpoint}: {message}', flush=True)
                if not message.startswith('PASS:'):
                    raise RuntimeError(message)
            finally:
                shutil.rmtree(app)
                subprocess.run(['defaults', 'delete', identity], capture_output=True)
    finally:
        server.shutdown()
