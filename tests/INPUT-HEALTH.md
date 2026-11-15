# Input health checks

Run `python3 tests/run-input-health-tests.py` on macOS. It compiles the production
monitor and bridge in a temporary directory. The bridge tests substitute only
CoreGraphics tap operations and the Secure Input query; CoreFoundation port and
run-loop source validity/lifetime remain real. They do not monitor or synthesize
keyboard input or change the system Secure Input state.

Coverage includes blocked startup, an enabled tap during Secure Input, recovery
after release, delayed Accessibility permission, failed recovery/retry, invalid
ports, sleep/wake, repeated registration and preservation of the smart-switch
setting. Ready-state polling must never clear an in-progress composition.
The real hook reset is also checked against a partially composed word and held
modifier flags; it must preserve clipboard suspension and typing settings.

Owner checks cover missing/malformed PID data, other users, background sessions,
ambiguous sessions, owner changes while blocked, and clearing stale names on
release or lookup failure. The owner query runs only while Secure Input is on.
MKey never requests Secure Input, so a registry entry pointing to MKey itself is
treated as unknown. AX button presses can invoke the fixture while backgrounded;
the fixture now waits for activation before enabling Secure Input so the OS can
attribute the request to the intended process.

For UI QA, compile `tests/SecureInputFixture.swift` as a separate AppKit test app:

```sh
xcrun swiftc -parse-as-library tests/SecureInputFixture.swift \
  -o /path/to/Fixture.app/Contents/MacOS/Fixture
```

Give the fixture its own bundle identifier and executable entry in Info.plist.
It deliberately retains **its own** Secure Input request while backgrounded to
reproduce a stuck login window; it releases the request after 30 seconds or on
exit. The fixture is excluded from the shipping app.

1. Run MKey and the fixture. Click **Enable for 30 seconds**.
2. Confirm MKey shows a lock in the menu bar, a Secure Input message in its menu
   and settings naming **MKey Secure Input Test**, and guidance for closing its
   password/login window. If the diagnostic registry does not expose an owner,
   MKey must show the generic guidance rather than guess the foreground app.
3. Click **Release Secure Input**. Confirm MKey returns to **Bộ gõ đã sẵn sàng**
   without relaunching and the lock/banner disappear.
4. Repeat with the fixture active before starting MKey. Saved macros and typing
   settings must still load; releasing the fixture must start the tap.
5. Use physical keys in TextEdit/browser to check `tieengs vieetj` → `tiếng việt`
   after release, plus a saved macro. Do not count pasted or automated synthetic
   text as verification of the physical keyboard event tap.

The production app only queries `IsSecureEventInputEnabled`; it does not call
`EnableSecureEventInput` or `DisableSecureEventInput`.
