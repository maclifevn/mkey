//
//  SystemPage.swift
//  mkey
//
//  System integration: login item, dock/menu-bar icon, smart switching.
//

import SwiftUI

struct SystemPage: View {
    @EnvironmentObject private var state: AppState
    @State private var confirmReset = false

    var body: some View {
        Form {
            Section("Khởi động") {
                Toggle("Khởi động cùng macOS", isOn: $state.runOnStartup)
                Toggle("Hiện bảng điều khiển khi khởi động", isOn: $state.showUIOnStartup)
            }

            Section("Biểu tượng") {
                Toggle("Biểu tượng đơn sắc trên thanh menu", isOn: $state.grayIcon)
                Toggle("Hiện biểu tượng ở Dock", isOn: $state.showIconOnDock)
            }

            Section("Chuyển chế độ thông minh") {
                Toggle("Tự nhớ chế độ gõ theo từng ứng dụng", isOn: $state.useSmartSwitchKey)
                Toggle("Tự nhớ bảng mã theo từng ứng dụng", isOn: $state.rememberCode)
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
        .formStyle(.grouped)
        .confirmationDialog("Bạn có chắc chắn muốn thiết lập lại cấu hình mặc định?",
                            isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Khôi phục mặc định", role: .destructive) {
                state.resetToDefaults()
            }
            Button("Huỷ", role: .cancel) {}
        }
    }
}
