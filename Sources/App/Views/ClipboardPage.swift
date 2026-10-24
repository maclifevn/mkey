//
//  ClipboardPage.swift
//  mkey
//
//  Settings for the clipboard history feature.
//

import SwiftUI

struct ClipboardPage: View {
    @ObservedObject var manager = ClipboardManager.shared

    var body: some View {
        Form {
            Section {
                Toggle("Bật lịch sử Clipboard", isOn: $manager.enabled)
                if manager.enabled {
                    Toggle("Ghim trên cùng", isOn: $manager.pinOnTop)
                    Toggle("Tự động ẩn", isOn: $manager.autoHide)
                    HStack {
                        Text("Kích thước và vị trí cửa sổ")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Đặt lại") {
                            manager.resetPickerLayout()
                        }
                        .disabled(!manager.hasCustomLayout)
                    }
                }
            }

            if manager.enabled {
                Section {
                    HotkeyEditor(status: $manager.hotKey, allowsModifierOnly: false)
                } header: {
                    Text("Phím tắt")
                } footer: {
                    Text("Mặc định: ⌃V. Cần ít nhất một phím chức năng kèm một phím chữ.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Số mục tối đa")
                            Spacer()
                            Text("\(manager.maxItems)")
                                .foregroundStyle(Color.accentColor)
                                .font(.body.weight(.semibold))
                                .monospacedDigit()
                        }
                        // Label + .labelsHidden() stops Form from reserving a
                        // left label column (which pushed the track to the
                        // right half). No value labels → avoids the render glitch.
                        Slider(
                            value: Binding(
                                get: { Double(manager.maxItems) },
                                set: { manager.maxItems = Int($0.rounded()) }
                            ),
                            in: 10...100
                        ) {
                            Text("Số mục tối đa")
                        }
                        .labelsHidden()
                        HStack {
                            Text("10")
                            Spacer()
                            Text("100")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                } footer: {
                    Text("Clipboard từ trình quản lý mật khẩu và ứng dụng nhạy cảm sẽ không được lưu vào lịch sử.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    HStack {
                        Text("Đang lưu \(manager.items.count) mục")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Xoá lịch sử", role: .destructive) {
                            manager.clear()
                        }
                        .disabled(manager.items.isEmpty)
                    }
                } footer: {
                    Text("Mục đã ghim (biểu tượng 📌 trong bảng lịch sử, phím tắt ⌘P) luôn nằm trên cùng, không bị trôi khi vượt số mục tối đa và được giữ lại khi xoá lịch sử. Di chuột lên mục hình ảnh để xem trước phóng to.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .settingsFormStyle()
    }
}
