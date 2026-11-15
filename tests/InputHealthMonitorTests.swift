import Foundation

@main
@MainActor
struct InputHealthMonitorTests {
    static func main() {
        var secure = false
        var permission = true
        var running = true
        var recoverySucceeds = true
        var recoveries = 0
        var checks = 0
        var snapshots: [InputHealthMonitor.Snapshot] = []
        let monitor = InputHealthMonitor(
            secureInputEnabled: { secure },
            accessibilityGranted: { permission },
            eventTapRunning: { running },
            recoverEventTap: {
                recoveries += 1
                running = recoverySucceeds
                return recoverySucceeds
            },
            publish: { snapshots.append($0) }
        )
        func check(_ condition: Bool, _ name: String) {
            precondition(condition, name)
            checks += 1
        }
        func status(_ expected: InputMonitoringStatus, _ name: String) {
            check(snapshots.last?.status == expected, name)
        }

        monitor.check()
        status(.ready, "healthy tap is ready")
        monitor.check()
        check(recoveries == 0 && snapshots.count == 1, "steady polling never resets composition or republishes")

        secure = true
        monitor.check()
        status(.secureInput, "reports Secure Input even if the tap is enabled")
        monitor.check()
        check(recoveries == 0 && snapshots.count == 2, "never recovers or repeats notifications while blocked")
        secure = false
        monitor.check()
        status(.ready, "recovers when Secure Input ends")
        check(recoveries == 1, "resets composition even when tap stayed enabled")
        monitor.check()
        check(recoveries == 1, "does not reset on every keystroke/poll after recovery")

        running = false
        monitor.check()
        check(recoveries == 2 && running, "recovers a disabled tap without a Secure Input transition")
        running = false
        recoverySucceeds = false
        monitor.check()
        status(.recovering, "failure is not presented as ready or missing permission")
        monitor.check()
        check(recoveries == 4, "failed recovery is retried")
        recoverySucceeds = true
        monitor.check()
        status(.ready, "successful retry becomes ready")

        permission = false
        running = false
        let beforePermission = recoveries
        monitor.check()
        status(.needsAccessibility, "permission revocation is visible")
        check(snapshots.last?.accessibilityGranted == false && recoveries == beforePermission,
              "does not recreate a tap while permission is missing")
        secure = true
        monitor.check()
        status(.secureInput, "Secure Input and missing permission can coexist")
        check(snapshots.last?.accessibilityGranted == false, "does not invent Accessibility permission")
        secure = false
        monitor.check()
        status(.needsAccessibility, "waits for permission after Secure Input ends")
        permission = true
        running = true
        monitor.check()
        check(recoveries == beforePermission + 1, "pending session reset survives the permission wait")

        monitor.stop()
        secure = true
        let beforeSleep = snapshots.count
        monitor.check()
        check(snapshots.count == beforeSleep, "queued checks cannot restart the engine during sleep")
        monitor.start()
        status(.secureInput, "wake checks Secure Input immediately")
        monitor.start()
        check(snapshots.count == beforeSleep + 1, "starting twice is idempotent")
        monitor.stop()

        var bootRecoveries = 0
        var bootStatus: InputMonitoringStatus?
        let boot = InputHealthMonitor(
            secureInputEnabled: { secure },
            accessibilityGranted: { true },
            eventTapRunning: { false },
            recoverEventTap: { bootRecoveries += 1; return true },
            publish: { bootStatus = $0.status }
        )
        boot.check()
        check(bootStatus == .secureInput && bootRecoveries == 0, "blocked startup does not attempt a tap")
        secure = false
        boot.check()
        check(bootStatus == .ready && bootRecoveries == 1, "blocked startup recovers without relaunch")

        var ownerSecure = false
        var ownerQueries = 0
        var ownerRecoveries = 0
        var owner: SecureInputOwner? = SecureInputOwner(processIdentifier: 123, name: "First app", isApplication: true, isLoginWindow: false)
        var ownerSnapshots: [InputHealthMonitor.Snapshot] = []
        let ownerMonitor = InputHealthMonitor(
            secureInputEnabled: { ownerSecure },
            accessibilityGranted: { true },
            eventTapRunning: { true },
            recoverEventTap: { ownerRecoveries += 1; return false },
            secureInputOwner: { ownerQueries += 1; return owner },
            publish: { ownerSnapshots.append($0) }
        )
        ownerMonitor.check()
        check(ownerQueries == 0 && ownerSnapshots.last?.secureInputOwner == nil, "never queries owner during normal typing")
        ownerSecure = true
        ownerMonitor.check()
        check(ownerSnapshots.last?.secureInputOwner == owner, "publishes detected owner")
        ownerMonitor.check()
        check(ownerSnapshots.count == 2, "unchanged owner does not redraw UI")
        owner = SecureInputOwner(processIdentifier: 456, name: "Second app", isApplication: true, isLoginWindow: false)
        ownerMonitor.check()
        check(ownerSnapshots.count == 3 && ownerSnapshots.last?.secureInputOwner == owner && ownerRecoveries == 0,
              "owner handoff updates the UI while input stays blocked")
        owner = nil
        ownerMonitor.check()
        check(ownerSnapshots.last?.status == .secureInput && ownerSnapshots.last?.secureInputOwner == nil,
              "lookup failure clears the old name without inventing recovery")
        owner = SecureInputOwner(processIdentifier: 789, name: "Third app", isApplication: true, isLoginWindow: false)
        ownerMonitor.check()
        ownerSecure = false
        let queriesBeforeRelease = ownerQueries
        ownerMonitor.check()
        check(ownerSnapshots.last?.status == .recovering && ownerSnapshots.last?.secureInputOwner == nil && ownerQueries == queriesBeforeRelease,
              "release clears the owner even when tap recovery fails")

        print("PASS: \(checks) input health checks")
    }
}
