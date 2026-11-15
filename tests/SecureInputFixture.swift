// Test-only app: simulate an application retaining Secure Input after login.
// Its own request expires after 30 seconds and is balanced on exit.
import AppKit
import Carbon

@MainActor
final class SecureInputFixture: NSObject, NSApplicationDelegate {
    private var window: NSWindow!
    private var ownsSecureInput = false
    private var expiry: Timer?
    private let status = NSTextField(labelWithString: "Secure Input: OFF")

    func applicationDidFinishLaunching(_ notification: Notification) {
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 420, height: 160),
                          styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = "MKey Secure Input Test"
        let enable = NSButton(title: "Enable for 30 seconds", target: self, action: #selector(enableInput))
        let disable = NSButton(title: "Release Secure Input", target: self, action: #selector(releaseInput))
        let stack = NSStackView(views: [status, enable, disable])
        stack.orientation = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        window.contentView!.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: window.contentView!.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: window.contentView!.centerYAnchor)
        ])
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    @objc private func enableInput() {
        guard !ownsSecureInput else { return }
        ownsSecureInput = EnableSecureEventInput() == noErr
        status.stringValue = ownsSecureInput ? "Secure Input: ON (auto release in 30s)" : "Enable failed"
        expiry = Timer.scheduledTimer(withTimeInterval: 30, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.releaseInput() }
        }
    }

    @objc private func releaseInput() {
        expiry?.invalidate()
        expiry = nil
        if ownsSecureInput {
            DisableSecureEventInput()
            ownsSecureInput = false
        }
        status.stringValue = "Secure Input: OFF"
    }

    func applicationWillTerminate(_ notification: Notification) { releaseInput() }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

@main
struct FixtureMain {
    @MainActor static func main() {
        let app = NSApplication.shared
        let delegate = SecureInputFixture()
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        app.run()
        withExtendedLifetime(delegate) {}
    }
}
