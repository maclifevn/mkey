import AppKit
import SwiftUI

/// Wait for menu tracking to finish, then focus the actual scene window.
/// Keep the activation policy chosen by the user throughout presentation.
@MainActor
final class AppWindowPresenter {
    static let shared = AppWindowPresenter()

    private let windows = NSMapTable<NSString, NSWindow>.strongToWeakObjects()
    private var pendingWindowID: String?

    func open(_ id: String, using openWindow: OpenWindowAction) {
        RunLoop.main.perform(inModes: [.default]) { [self] in
            MainActor.assumeIsolated {
                pendingWindowID = id
                // A new window can attach synchronously inside openWindow.
                // Let attach's deferred callback focus it after scene setup.
                let existingWindow = windows.object(forKey: id as NSString)
                openWindow(id: id)
                if let window = existingWindow {
                    present(window, id: id)
                }
            }
        }
    }

    func attach(_ window: NSWindow, id: String) {
        windows.setObject(window, forKey: id as NSString)
        // SwiftUI may still be installing the scene's window content.
        RunLoop.main.perform(inModes: [.default]) { [weak window, self] in
            MainActor.assumeIsolated {
                guard let window else { return }
                present(window, id: id)
            }
        }
    }

    private func present(_ window: NSWindow, id: String) {
        guard pendingWindowID == id else { return }
        pendingWindowID = nil
        if window.isMiniaturized { window.deminiaturize(nil) }
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}

/// Registers the real NSWindow instead of guessing when openWindow creates it.
struct WindowAttachment: NSViewRepresentable {
    let id: String

    func makeNSView(context: Context) -> AttachmentView {
        AttachmentView(id: id)
    }

    func updateNSView(_ nsView: AttachmentView, context: Context) {}

    final class AttachmentView: NSView {
        let id: String

        init(id: String) {
            self.id = id
            super.init(frame: .zero)
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if let window {
                AppWindowPresenter.shared.attach(window, id: id)
            }
        }
    }
}
