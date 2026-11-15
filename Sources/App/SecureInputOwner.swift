import AppKit
import IOKit

struct SecureInputOwner: Equatable {
    let processIdentifier: pid_t
    let name: String
    let isApplication: Bool
    let isLoginWindow: Bool
}

@MainActor
enum SecureInputOwnerResolver {
    static func currentOwner() -> SecureInputOwner? {
        let root = IORegistryGetRootEntry(kIOMainPortDefault)
        guard root != 0 else { return nil }
        defer { IOObjectRelease(root) }
        let users = IORegistryEntryCreateCFProperty(root, "IOConsoleUsers" as CFString,
                                                   kCFAllocatorDefault, 0)?.takeRetainedValue()
        guard let pid = processIdentifier(in: users, currentUserID: getuid()) else { return nil }
        return owner(for: pid)
    }

    // These diagnostic registry keys may be absent or change between macOS
    // versions. Only accept one active console session belonging to this user;
    // never substitute the frontmost app or a different user's session.
    static func processIdentifier(in consoleUsers: Any?, currentUserID: uid_t) -> pid_t? {
        guard let users = consoleUsers as? [[String: Any]] else { return nil }
        let sessions = users.filter { session in
            guard integer(session["kCGSSessionUserIDKey"]) == Int64(currentUserID),
                  let onConsole = session["kCGSSessionOnConsoleKey"] as? NSNumber,
                  CFGetTypeID(onConsole) == CFBooleanGetTypeID() else { return false }
            return onConsole.boolValue
        }
        guard sessions.count == 1,
              let pid = integer(sessions[0]["kCGSSessionSecureInputPID"]),
              pid > 0, pid <= Int64(Int32.max) else { return nil }
        return pid_t(pid)
    }

    private static func integer(_ value: Any?) -> Int64? {
        guard let number = value as? NSNumber,
              CFGetTypeID(number) != CFBooleanGetTypeID(),
              number.doubleValue.isFinite,
              number.doubleValue == Double(number.int64Value) else { return nil }
        return number.int64Value
    }

    static func owner(for pid: pid_t) -> SecureInputOwner? {
        // MKey never requests Secure Input. Diagnostic state can attribute a
        // background request to the foreground process; do not blame MKey itself.
        guard pid > 0, pid != getpid() else { return nil }
        let app = NSRunningApplication(processIdentifier: pid)
        guard app?.isTerminated != true else { return nil }
        var buffer = [CChar](repeating: 0, count: 1024)
        let length = buffer.withUnsafeMutableBytes { bytes in
            proc_name(pid, bytes.baseAddress, UInt32(bytes.count))
        }
        let processName = length > 0 ? String(cString: buffer) : nil
        let isLoginWindow = app?.bundleIdentifier == "com.apple.loginwindow" || processName == "loginwindow"
        let name = (app?.localizedName ?? processName)?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let name, !name.isEmpty else { return nil }
        return SecureInputOwner(processIdentifier: pid,
                                name: isLoginWindow ? "Đăng nhập macOS (loginwindow)" : name,
                                isApplication: app != nil && app?.activationPolicy != .prohibited,
                                isLoginWindow: isLoginWindow)
    }
}
