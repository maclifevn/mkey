#!/bin/bash
# Prepare local release assets. This script never uploads or publishes anything.
set -euo pipefail
APP="${1:?usage: build-update-feed.sh APP RELEASE_NOTES OUTPUT_DIR SPARKLE_BIN [PREVIOUS_FEED]}"
NOTES="${2:?missing release notes Markdown file}"
OUTPUT="${3:?missing output directory (must not exist)}"
SPARKLE_BIN="${4:?missing Sparkle bin directory}"
PREVIOUS_FEED="${5:-}"
ACCOUNT="${MKEY_SPARKLE_ACCOUNT:-vn.mkey.app}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLIST="$APP/Contents/Info.plist"

[ -f "$PLIST" ] && [ -f "$NOTES" ] || { echo 'Missing app or release notes' >&2; exit 1; }
[ ! -e "$OUTPUT" ] || { echo 'Output directory already exists; use a new directory' >&2; exit 1; }
for tool in generate_keys generate_appcast sign_update; do
    [ -x "$SPARKLE_BIN/$tool" ] || { echo "Missing Sparkle tool: $tool" >&2; exit 1; }
done
/usr/bin/codesign --verify --deep --strict "$APP"
PUBLIC_KEY="$("$SPARKLE_BIN/generate_keys" --account "$ACCOUNT" -p)"
# Validate the app's actual shipping configuration before signing a feed for it.
python3 - "$PLIST" "$PUBLIC_KEY" <<'PY'
import plistlib, re, sys
with open(sys.argv[1], 'rb') as f:
    p = plistlib.load(f)
checks = {
    'bundle identifier': p.get('CFBundleIdentifier') == 'vn.mkey.app',
    'public signing key': p.get('SUPublicEDKey') == sys.argv[2],
    'signed feed': p.get('SURequireSignedFeed') is True,
    'archive verification': p.get('SUVerifyUpdateBeforeExtraction') is True,
    'feed URL': p.get('SUFeedURL') == 'https://github.com/maclifevn/mkey/releases/latest/download/appcast.xml',
    'version': re.fullmatch(r'[0-9]+(?:\.[0-9]+){1,2}', p.get('CFBundleShortVersionString', '')),
    'build': re.fullmatch(r'[1-9][0-9]*', p.get('CFBundleVersion', '')),
}
for name, valid in checks.items():
    if not valid:
        raise SystemExit('Invalid release configuration: ' + name)
PY
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PLIST")"
BUILD="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$PLIST")"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/mkey-release.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
ARCHIVES="$WORK/archives"
mkdir -p "$ARCHIVES"

if [ -n "$PREVIOUS_FEED" ]; then
    # Never re-sign an unverified old feed; reject build regressions as well.
    "$SPARKLE_BIN/sign_update" --verify --account "$ACCOUNT" "$PREVIOUS_FEED"
    python3 - "$PREVIOUS_FEED" "$BUILD" <<'PY'
import sys, xml.etree.ElementTree as ET
ns = '{http://www.andymatuschak.org/xml-namespaces/sparkle}'
for item in ET.parse(sys.argv[1]).findall('./channel/item'):
    version = item.findtext(ns + 'version')
    enclosure = item.find('enclosure')
    if version is None and enclosure is not None:
        version = enclosure.get(ns + 'version')
    if version is None or not version.isdecimal() or int(version) >= int(sys.argv[2]):
        raise SystemExit('New build must be greater than every previous build')
PY
    cp "$PREVIOUS_FEED" "$ARCHIVES/appcast.xml"
fi

NAME="mkey-${VERSION}"
PREFIX="https://github.com/maclifevn/mkey/releases/download/v${VERSION}/"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$APP" "$ARCHIVES/$NAME.zip"
cp "$NOTES" "$ARCHIVES/$NAME.md"
"$SPARKLE_BIN/generate_appcast" --account "$ACCOUNT" \
    --download-url-prefix "$PREFIX" --release-notes-url-prefix "$PREFIX" \
    --link 'https://github.com/maclifevn/mkey' \
    --maximum-versions 5 --maximum-deltas 0 --disable-signing-warning "$ARCHIVES"
"$SCRIPT_DIR/verify-update-feed.py" "$ARCHIVES/appcast.xml" "$ARCHIVES/$NAME.zip" \
    "$ARCHIVES/$NAME.md" "$SPARKLE_BIN/sign_update" --account "$ACCOUNT"
mkdir -p "$OUTPUT"
cp "$ARCHIVES/appcast.xml" "$ARCHIVES/$NAME.zip" "$ARCHIVES/$NAME.md" "$OUTPUT/"
echo "Verified release assets: $OUTPUT (version $VERSION, build $BUILD)"
