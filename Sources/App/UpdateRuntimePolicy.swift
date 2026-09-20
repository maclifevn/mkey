import Foundation

struct UpdateRuntimePolicy {
    let isDebugBuild: Bool
    let environment: [String: String]

    var enabled: Bool {
        guard environment["XCTestConfigurationFilePath"] == nil,
              environment["XCTestBundlePath"] == nil,
              environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else { return false }
        return !isDebugBuild || environment["MKEY_ENABLE_UPDATES"] == "1"
    }

    static func installationIsEligible(bundleURL: URL, isWritable: Bool) -> Bool {
        let url = bundleURL.standardizedFileURL.resolvingSymlinksInPath()
        return url.pathExtension.lowercased() == "app"
            && url.deletingLastPathComponent().path == "/Applications"
            && !url.path.contains("/AppTranslocation/")
            && isWritable
    }

    static var live: Self {
        #if DEBUG
        let debug = true
        #else
        let debug = false
        #endif
        return Self(isDebugBuild: debug, environment: ProcessInfo.processInfo.environment)
    }
}
