import Foundation

@main
@MainActor
struct SecureInputOwnerTests {
    static func main() {
        var checks = 0
        func check(_ condition: Bool, _ message: String) {
            precondition(condition, message)
            checks += 1
        }
        func session(uid: Any = 501, onConsole: Any = true, pid: Any? = 123) -> [String: Any] {
            var value: [String: Any] = ["kCGSSessionUserIDKey": uid, "kCGSSessionOnConsoleKey": onConsole]
            value["kCGSSessionSecureInputPID"] = pid
            return value
        }
        func pid(_ value: Any?) -> pid_t? {
            SecureInputOwnerResolver.processIdentifier(in: value, currentUserID: 501)
        }

        check(pid([session()]) == 123, "uses the active console session's owner PID")
        check(pid([session(uid: 502, pid: 456), session()]) == 123, "ignores other users")
        check(pid([session(onConsole: false, pid: 456), session()]) == 123, "ignores background sessions")
        check(pid([session(uid: 502)]) == nil, "never attributes another user's owner")
        check(pid([session(onConsole: false)]) == nil, "no owner while this user is off console")
        check(pid([session(), session(pid: 456)]) == nil, "ambiguous sessions stay unknown")
        check(pid(nil) == nil && pid([]) == nil && pid("invalid") == nil, "missing or malformed registry stays unknown")
        check(pid([session(pid: nil)]) == nil, "missing PID")
        for invalid: Any in [0, -1, Int64(Int32.max) + 1, "123", true, 1.5, Double.nan, Double.infinity] {
            check(pid([session(pid: invalid)]) == nil, "rejects malformed or out-of-range PID")
        }
        check(pid([session(pid: Int32.max)]) == Int32.max, "accepts a valid pid_t boundary")
        check(pid([session(uid: "501")]) == nil && pid([session(onConsole: "true")]) == nil,
              "does not coerce registry strings")
        check(SecureInputOwnerResolver.owner(for: 0) == nil && SecureInputOwnerResolver.owner(for: -1) == nil,
              "invalid process identifiers cannot resolve to a name")
        check(SecureInputOwnerResolver.owner(for: getpid()) == nil, "does not blame the querying process itself")

        let browser = SecureInputOwner(processIdentifier: 123, name: "Google Chrome", isApplication: true, isLoginWindow: false)
        let login = SecureInputOwner(processIdentifier: 124, name: "Đăng nhập macOS (loginwindow)", isApplication: false, isLoginWindow: true)
        let service = SecureInputOwner(processIdentifier: 125, name: "Test helper", isApplication: false, isLoginWindow: false)
        let blocked = InputMonitoringStatus.secureInput
        check(blocked.title(owner: browser).contains("Google Chrome"), "title names the application")
        check(blocked.detail(owner: browser).contains("PID 123"), "detailed message exposes the verified PID")
        check(blocked.bannerDetail(owner: browser).contains("Google Chrome"), "banner names the application to close")
        check(blocked.detail(owner: login).contains("đăng xuất") && !blocked.detail(owner: login).contains("thoát rồi mở lại"),
              "loginwindow gets login-session guidance rather than quit-app advice")
        check(blocked.detail(owner: service).contains("Test helper") && !blocked.detail(owner: service).contains("thoát rồi mở lại"),
              "background processes do not get quit-app advice")
        check(blocked.title(owner: nil) == blocked.title, "unknown owner keeps generic title")
        check(InputMonitoringStatus.ready.title(owner: browser) == InputMonitoringStatus.ready.title,
              "ready state cannot display a stale application name")
        print("PASS: \(checks) Secure Input owner checks")
    }
}
