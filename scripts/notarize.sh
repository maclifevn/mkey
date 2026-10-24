#!/bin/bash
# Copy, sign nested Sparkle helpers, notarize, staple and package a local test app.
set -euo pipefail
SOURCE_APP="${1:?usage: notarize.sh APP NEW_OUTPUT_DIR [KEYCHAIN_PROFILE]}"
OUTPUT="${2:?missing output directory}"
PROFILE="${3:-MFinderNotary}"
IDENTITY="${MKEY_SIGNING_IDENTITY:-Developer ID Application: Anh Tuan Vu Nguyen (CF5PGH3KGK)}"
[ -d "$SOURCE_APP" ] || { echo 'App does not exist' >&2; exit 1; }
[ ! -e "$OUTPUT" ] || { echo 'Use a new output directory' >&2; exit 1; }
mkdir -p "$OUTPUT"
APP="$OUTPUT/mkey.app"
ditto "$SOURCE_APP" "$APP"
SPARKLE="$APP/Contents/Frameworks/Sparkle.framework"
# Signing only the enclosing framework does not replace its ad-hoc helper
# signatures. Sign inside out; preserve each helper's existing entitlements.
for component in \
    "$SPARKLE/Versions/B/XPCServices/Downloader.xpc" \
    "$SPARKLE/Versions/B/XPCServices/Installer.xpc" \
    "$SPARKLE/Versions/B/Autoupdate" \
    "$SPARKLE/Versions/B/Updater.app" \
    "$SPARKLE" \
    "$APP"; do
    codesign --force --sign "$IDENTITY" --options runtime --timestamp \
        --preserve-metadata=identifier,entitlements "$component"
done
codesign --verify --deep --strict "$APP"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$OUTPUT/submission.zip"
xcrun notarytool submit "$OUTPUT/submission.zip" --keychain-profile "$PROFILE" \
    --wait --output-format json > "$OUTPUT/notarization.json"
python3 - "$OUTPUT/notarization.json" <<'PY'
import json, sys
with open(sys.argv[1]) as f:
    result = json.load(f)
print('Notarization:', result.get('status'), 'ID:', result.get('id'))
if result.get('status') != 'Accepted':
    raise SystemExit('Notarization was not accepted; retrieve the submission log before retrying.')
PY
xcrun stapler staple "$APP"
xcrun stapler validate "$APP"
codesign --verify --deep --strict "$APP"
spctl --assess --type execute --verbose=2 "$APP"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist")"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$OUTPUT/mkey-$VERSION-notarized.zip"
echo "Notarized app ready: $APP"
