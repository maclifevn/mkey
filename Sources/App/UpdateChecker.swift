//
//  UpdateChecker.swift
//  mkey
//
//  Checks GitHub Releases for a newer version. Self-contained (own UserDefaults,
//  independent of the engine). Because the app is ad-hoc signed, it cannot
//  auto-install; it surfaces the new version and opens the release page so the
//  user downloads and installs manually.
//

import AppKit
import Combine

struct ReleaseInfo: Equatable {
    let version: String   // e.g. "1.4.0"
    let notes: String     // release body
    let pageURL: URL      // html_url of the release
}

@MainActor
final class UpdateChecker: ObservableObject {
    static let shared = UpdateChecker()

    enum Status: Equatable {
        case idle
        case checking
        case upToDate
        case available(ReleaseInfo)
        case failed(String)
    }

    @Published private(set) var status: Status = .idle

    private let defaults = UserDefaults.standard
    private let autoKey = "autoCheckUpdate"
    private let lastCheckKey = "lastUpdateCheck"
    private let releaseAPI = URL(string: "https://api.github.com/repos/maclifevn/mkey/releases/latest")!
    private let minInterval: TimeInterval = 24 * 60 * 60

    var autoCheckEnabled: Bool {
        get { defaults.object(forKey: autoKey) as? Bool ?? true }
        set { defaults.set(newValue, forKey: autoKey); objectWillChange.send() }
    }

    var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    private init() {}

    // MARK: Public API

    /// Auto-check at launch: only if enabled and it's been > 24h since last check.
    func autoCheckIfDue() {
        guard autoCheckEnabled else { return }
        if let last = defaults.object(forKey: lastCheckKey) as? Date,
           Date().timeIntervalSince(last) < minInterval {
            return
        }
        Task { await check(manual: false) }
    }

    /// Query GitHub for the latest release. `manual` = triggered by the user.
    func check(manual: Bool) async {
        status = .checking
        do {
            let info = try await fetchLatest()
            defaults.set(Date(), forKey: lastCheckKey)
            if isNewer(info.version, than: currentVersion) {
                status = .available(info)
                if !manual {
                    // launch-time discovery: alert is shown by the app delegate
                    NotificationCenter.default.post(name: .mkUpdateAvailable, object: info)
                }
            } else {
                status = .upToDate
            }
        } catch {
            status = .failed("Không kiểm tra được cập nhật. Hãy thử lại sau.")
        }
    }

    func openReleasePage(_ info: ReleaseInfo) {
        NSWorkspace.shared.open(info.pageURL)
    }

    // MARK: Networking

    private func fetchLatest() async throws -> ReleaseInfo {
        var request = URLRequest(url: releaseAPI)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("MKey", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tag = json["tag_name"] as? String else {
            throw URLError(.cannotParseResponse)
        }
        let version = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
        let notes = (json["body"] as? String) ?? ""
        let pageString = (json["html_url"] as? String) ?? "https://github.com/maclifevn/mkey/releases/latest"
        let pageURL = URL(string: pageString) ?? releaseAPI
        return ReleaseInfo(version: version, notes: notes, pageURL: pageURL)
    }

    // MARK: Semver

    /// True when `remote` is a strictly newer version than `local`.
    /// Parses dot-separated numeric components; on any parse failure returns
    /// false so we never nag the user with a bogus "update available".
    private func isNewer(_ remote: String, than local: String) -> Bool {
        let r = numericComponents(remote)
        let l = numericComponents(local)
        guard !r.isEmpty, !l.isEmpty else { return false }
        for i in 0..<max(r.count, l.count) {
            let rv = i < r.count ? r[i] : 0
            let lv = i < l.count ? l[i] : 0
            if rv != lv { return rv > lv }
        }
        return false
    }

    private func numericComponents(_ version: String) -> [Int] {
        // keep only the leading "x.y.z" numeric part (drop any -beta suffix)
        let core = version.split(whereSeparator: { !"0123456789.".contains($0) }).first.map(String.init) ?? version
        return core.split(separator: ".").map { Int($0) ?? 0 }
    }
}

extension Notification.Name {
    static let mkUpdateAvailable = Notification.Name("MKUpdateAvailable")
}
