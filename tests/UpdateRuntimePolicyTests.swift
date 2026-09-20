import Foundation

@main
struct UpdateRuntimePolicyTests {
    static func main() {
        var count = 0
        func check(_ condition: Bool, _ name: String) {
            precondition(condition, name)
            count += 1
        }
        check(UpdateRuntimePolicy(isDebugBuild: false, environment: [:]).enabled, "Release enables updates")
        check(!UpdateRuntimePolicy(isDebugBuild: true, environment: [:]).enabled, "Debug disables updates")
        check(UpdateRuntimePolicy(isDebugBuild: true, environment: ["MKEY_ENABLE_UPDATES": "1"]).enabled, "Debug explicit opt-in")
        for environment in [
            ["XCTestConfigurationFilePath": "/tmp/tests.xctestconfiguration"],
            ["XCTestBundlePath": "/tmp/tests.xctest"],
            ["XCODE_RUNNING_FOR_PREVIEWS": "1"]
        ] {
            check(!UpdateRuntimePolicy(isDebugBuild: false, environment: environment).enabled, "Test and preview isolation")
        }
        let paths: [(String, Bool, Bool)] = [
            ("/Applications/mkey.app", true, true),
            ("/Applications/mkey.app", false, false),
            ("/Applications/mkey.zip", true, false),
            ("/Applications/Nested/mkey.app", true, false),
            ("/Users/test/Downloads/mkey.app", true, false),
            ("/Volumes/MKey/mkey.app", true, false),
            ("/private/var/folders/AppTranslocation/random/d/mkey.app", true, false),
            ("/Applications/../tmp/mkey.app", true, false)
        ]
        for (path, writable, expected) in paths {
            check(UpdateRuntimePolicy.installationIsEligible(bundleURL: URL(fileURLWithPath: path), isWritable: writable) == expected, path)
        }
        print("PASS: \(count) update runtime policy checks")
    }
}
