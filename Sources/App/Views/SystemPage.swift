//
//  SystemPage.swift
//  mkey
//
//  System integration: login item, dock/menu-bar icon, smart switching.
//

import SwiftUI

struct SystemPage: View {
    @EnvironmentObject private var state: AppState
    @ObservedObject private var updater = UpdateChecker.shared
    @State private var confirmReset = false

    var body: some View {
        Form {
            Section("Khởi động") {
                Toggle("Khởi động cùng macOS", isOn: $state.runOnStartup)
                Toggle("Hiện bảng điều khiển khi khởi động", isOn: $state.showUIOnStartup)
            }

            Section("Cập nhật") {
                Toggle("Tự động kiểm tra cập nhật",
                       isOn: Binding(get: { updater.autoCheckEnabled },
                                     set: { updater.autoCheckEnabled = $0 }))

                Toggle("Tự động tải và cài đặt khi thoát",
                       isOn: Binding(get: { updater.autoDownloadEnabled },
                                     set: { updater.autoDownloadEnabled = $0 }))
                    .disabled(!updater.autoCheckEnabled)

                HStack(spacing: 8) {
                    Image(systemName: updateIcon)
                        .foregroundStyle(updateIconColor)
                    Text(updateStatusText)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    Spacer()
                    if case .checking = updater.status {
                        ProgressView().controlSize(.small)
                    } else {
                        Button("Kiểm tra ngay") {
                            updater.checkForUpdates()
                        }
                        .disabled(!updater.canCheckForUpdates)
                    }
                }

                if case .available(let info) = updater.status {
                    HStack {
                        Text("Phiên bản \(info) đã sẵn sàng.")
                        Spacer()
                        Button("Cập nhật…") { updater.checkForUpdates() }
                            .disabled(!updater.canCheckForUpdates)
                            .buttonStyle(.borderedProminent)
                    }
                }
                if let lastCheck = updater.lastCheckDate {
                    Text("Kiểm tra lần cuối: \(lastCheck.formatted(date: .abbreviated, time: .shortened))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                if let notice = updater.availabilityNotice {
                    Text(notice).font(.footnote).foregroundStyle(.secondary)
                }
            }

            Section("Biểu tượng") {
                Toggle("Biểu tượng đơn sắc trên thanh menu", isOn: $state.grayIcon)
                Toggle("Hiện biểu tượng ở Dock", isOn: $state.showIconOnDock)
            }

            Section("Chuyển chế độ thông minh") {
                Toggle("Tự nhớ chế độ gõ theo từng ứng dụng", isOn: $state.useSmartSwitchKey)
                Toggle("Tự nhớ bảng mã theo từng ứng dụng", isOn: $state.rememberCode)
            }

            Section {
                AppBundleListEditor(
                    apps: $state.excludedApps,
                    emptyHint: "Chưa có ứng dụng nào. Kéo thả ứng dụng vào đây, nhấn +, hoặc dùng menu \u{201C}Tắt mkey cho…\u{201D} trên thanh menu.",
                    panelMessage: "Chọn ứng dụng để loại trừ (mkey sẽ không xử lý phím trong ứng dụng đó)"
                )
            } header: {
                Text("Ứng dụng loại trừ")
            } footer: {
                Text("Trong các ứng dụng này, mkey bỏ qua hoàn toàn — gõ như khi chưa cài (phù hợp terminal, IDE, game…). Khác với \u{201C}nhớ chế độ theo app\u{201D}: loại trừ là tắt cứng, luôn ưu tiên.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Tương thích nâng cao") {
                Toggle("Gửi phím từng bước (chậm nhưng tương thích cao)", isOn: $state.sendKeyStepByStep)
                Toggle("Tương thích bố cục bàn phím khác QWERTY", isOn: $state.performLayoutCompat)
            }

            Section {
                HStack {
                    Text("Khôi phục toàn bộ cài đặt về mặc định.")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Cài đặt mặc định", role: .destructive) {
                        confirmReset = true
                    }
                }
            }
        }
        .settingsFormStyle()
        .confirmationDialog("Bạn có chắc chắn muốn thiết lập lại cấu hình mặc định?",
                            isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Khôi phục mặc định", role: .destructive) {
                state.resetToDefaults()
            }
            Button("Huỷ", role: .cancel) {}
        }
    }

    private var updateStatusText: String {
        switch updater.status {
        case .idle:        return "Phiên bản hiện tại \(updater.currentVersion)."
        case .checking:    return "Đang kiểm tra cập nhật…"
        case .upToDate:    return "Bạn đang dùng bản mới nhất (\(updater.currentVersion))."
        case .available(let info): return "Đã có bản \(info)."
        case .failed(let msg):     return msg
        }
    }

    private var updateIcon: String {
        switch updater.status {
        case .available: return "arrow.down.circle.fill"
        case .failed:    return "exclamationmark.triangle"
        case .upToDate:  return "checkmark.circle"
        default:         return "arrow.triangle.2.circlepath"
        }
    }

    private var updateIconColor: Color {
        switch updater.status {
        case .available: return .accentColor
        case .failed:    return .orange
        default:         return .secondary
        }
    }
}
