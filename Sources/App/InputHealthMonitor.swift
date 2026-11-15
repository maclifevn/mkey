import Foundation

enum InputMonitoringStatus: Equatable {
    case ready
    case secureInput
    case needsAccessibility
    case recovering

    var title: String {
        switch self {
        case .ready: return "Bộ gõ đã sẵn sàng"
        case .secureInput: return "Secure Input đang chặn bộ gõ"
        case .needsAccessibility: return "MKey cần quyền Trợ năng"
        case .recovering: return "Đang khôi phục bộ gõ"
        }
    }

    var detail: String {
        switch self {
        case .ready:
            return "MKey đang nhận phím bình thường."
        case .secureInput:
            return "macOS đang bảo vệ việc nhập mật khẩu nên MKey tạm thời không nhận được phím. Hãy rời ô mật khẩu. Nếu vẫn bị chặn sau khi đăng nhập, hãy đóng cửa sổ đăng nhập hoặc thoát rồi mở lại ứng dụng vừa dùng. MKey sẽ tự hoạt động lại khi Secure Input tắt."
        case .needsAccessibility:
            return "Bật quyền Trợ năng cho MKey trong Cài đặt hệ thống để tiếp tục gõ tiếng Việt."
        case .recovering:
            return "MKey đang thử kết nối lại để nhận phím. Nếu tình trạng kéo dài, hãy kiểm tra quyền Trợ năng trong Cài đặt hệ thống."
        }
    }

    var symbol: String {
        switch self {
        case .ready: return "checkmark.circle"
        case .secureInput: return "lock.fill"
        case .needsAccessibility: return "hand.raised.fill"
        case .recovering: return "arrow.triangle.2.circlepath"
        }
    }
}

/// Poll independently of keyboard delivery: Secure Input can stop tap callbacks.
/// Dependencies keep recovery sequencing testable without intercepting real keys.
@MainActor
final class InputHealthMonitor {
    struct Snapshot: Equatable {
        let accessibilityGranted: Bool
        let status: InputMonitoringStatus
    }

    private let secureInputEnabled: () -> Bool
    private let accessibilityGranted: () -> Bool
    private let eventTapRunning: () -> Bool
    private let recoverEventTap: () -> Bool
    private let publish: (Snapshot) -> Void
    private var timer: Timer?
    private var isSuspended = false
    private var needsSessionReset = false
    private var lastSnapshot: Snapshot?

    init(secureInputEnabled: @escaping () -> Bool,
         accessibilityGranted: @escaping () -> Bool,
         eventTapRunning: @escaping () -> Bool,
         recoverEventTap: @escaping () -> Bool,
         publish: @escaping (Snapshot) -> Void) {
        self.secureInputEnabled = secureInputEnabled
        self.accessibilityGranted = accessibilityGranted
        self.eventTapRunning = eventTapRunning
        self.recoverEventTap = recoverEventTap
        self.publish = publish
    }

    func start() {
        guard timer == nil else { return }
        isSuspended = false
        check()
        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.check() }
        }
        timer.tolerance = 0.1
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        isSuspended = true
        timer?.invalidate()
        timer = nil
    }

    func check() {
        guard !isSuspended else { return }
        let hasAccessibility = accessibilityGranted()
        let status: InputMonitoringStatus
        if secureInputEnabled() {
            // Keys may have been entered without reaching the engine. Reset its
            // composition on recovery even if the tap still reports enabled.
            needsSessionReset = true
            status = .secureInput
        } else if !hasAccessibility {
            status = .needsAccessibility
        } else if needsSessionReset || !eventTapRunning() {
            if recoverEventTap() {
                needsSessionReset = false
                status = .ready
            } else {
                status = .recovering
            }
        } else {
            status = .ready
        }

        let snapshot = Snapshot(accessibilityGranted: hasAccessibility, status: status)
        if snapshot != lastSnapshot {
            lastSnapshot = snapshot
            publish(snapshot)
        }
    }
}
