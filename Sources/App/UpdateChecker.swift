import AppKit
import Combine
import Sparkle

/// Sparkle is responsible for version comparison, signatures, downloads,
/// installation and relaunch. Keep one updater for the lifetime of the app.
@MainActor
final class UpdateChecker: NSObject, ObservableObject, SPUUpdaterDelegate {
    static let shared = UpdateChecker()

    enum Status: Equatable {
        case idle
        case checking
        case upToDate
        case available(String)
        case failed(String)
    }

    @Published private(set) var status: Status = .idle
    @Published private(set) var canCheckForUpdates = false
    @Published private(set) var lastCheckDate: Date?

    private let policy = UpdateRuntimePolicy.live
    private var started = false
    private var subscriptions = Set<AnyCancellable>()
    private lazy var controller = SPUStandardUpdaterController(
        startingUpdater: false, updaterDelegate: self, userDriverDelegate: nil
    )

    private override init() {
        super.init()
    }

    var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    var autoCheckEnabled: Bool {
        get { controller.updater.automaticallyChecksForUpdates }
        set {
            objectWillChange.send()
            controller.updater.automaticallyChecksForUpdates = newValue
        }
    }

    var autoDownloadEnabled: Bool {
        get { controller.updater.automaticallyDownloadsUpdates }
        set {
            objectWillChange.send()
            controller.updater.automaticallyDownloadsUpdates = newValue
        }
    }

    var availabilityNotice: String? {
        if !policy.enabled { return "Cập nhật tự động được tắt trong bản phát triển." }
        if !installationIsEligible { return "Để cập nhật, hãy chuyển MKey vào Applications và mở lại ứng dụng." }
        return nil
    }

    private var installationIsEligible: Bool {
        let url = Bundle.main.bundleURL
        return UpdateRuntimePolicy.installationIsEligible(
            bundleURL: url,
            isWritable: FileManager.default.isWritableFile(atPath: url.path)
                && FileManager.default.isWritableFile(atPath: url.deletingLastPathComponent().path)
        )
    }

    func start() {
        guard policy.enabled, !started else { return }
        let updater = controller.updater
        let defaults = UserDefaults.standard
        // Preserve the old checker's opt-out exactly once during migration.
        if !defaults.bool(forKey: "sparklePreferencesMigrated") {
            if let previous = defaults.object(forKey: "autoCheckUpdate") as? Bool {
                updater.automaticallyChecksForUpdates = previous
            }
            defaults.set(true, forKey: "sparklePreferencesMigrated")
        }
        updater.publisher(for: \.canCheckForUpdates)
            .receive(on: RunLoop.main)
            .sink { [weak self] value in self?.canCheckForUpdates = value }
            .store(in: &subscriptions)
        updater.publisher(for: \.lastUpdateCheckDate)
            .receive(on: RunLoop.main)
            .sink { [weak self] value in self?.lastCheckDate = value }
            .store(in: &subscriptions)
        updater.publisher(for: \.automaticallyChecksForUpdates)
            .combineLatest(updater.publisher(for: \.automaticallyDownloadsUpdates))
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &subscriptions)
        do {
            try updater.start()
            started = true
        } catch {
            subscriptions.removeAll()
            status = .failed(error.localizedDescription)
        }
    }

    func checkForUpdates() {
        guard canCheckForUpdates else { return }
        // A menu action must finish tracking before Sparkle presents its UI.
        RunLoop.main.perform(inModes: [.default]) { [weak self] in
            MainActor.assumeIsolated {
                guard let self, self.canCheckForUpdates,
                      self.controller.updater.canCheckForUpdates else { return }
                guard self.installationIsEligible else {
                    self.status = .failed(self.availabilityNotice ?? "Không thể cập nhật tại vị trí này.")
                    let alert = NSAlert()
                    alert.messageText = "Chuyển MKey vào Applications"
                    alert.informativeText = self.availabilityNotice ?? ""
                    alert.addButton(withTitle: "OK")
                    NSApp.activate(ignoringOtherApps: true)
                    alert.runModal()
                    return
                }
                self.status = .checking
                self.controller.checkForUpdates(nil)
            }
        }
    }

    func updater(_ updater: SPUUpdater, mayPerform updateCheck: SPUUpdateCheck) throws {
        guard policy.enabled, installationIsEligible else {
            throw NSError(domain: "vn.mkey.updates", code: 1, userInfo: [
                NSLocalizedDescriptionKey: availabilityNotice ?? "Không thể cập nhật tại vị trí này."
            ])
        }
    }

    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        status = .available(item.displayVersionString)
    }

    func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        status = .upToDate
    }

    func updater(_ updater: SPUUpdater, didFinishUpdateCycleFor updateCheck: SPUUpdateCheck, error: Error?) {
        if let error = error as NSError? {
            if error.domain == SUSparkleErrorDomain && error.code == SUError.noUpdateError.rawValue {
                status = .upToDate
            } else if error.domain == SUSparkleErrorDomain && error.code == SUError.installationCanceledError.rawValue {
                status = .idle
            } else {
                status = .failed(error.localizedDescription)
            }
        } else if status == .checking {
            status = .idle
        }
    }
}
