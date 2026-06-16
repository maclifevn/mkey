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
            }

            if manager.enabled {
                Section {
                    HotkeyEditor(status: $manager.hotKey)
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
                        // plain full-width slider (no value labels → no render glitch)
                        Slider(
                            value: Binding(
                                get: { Double(manager.maxItems) },
                                set: { manager.maxItems = Int($0.rounded()) }
                            ),
                            in: 10...100
                        )
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
                }
            }
        }
        .formStyle(.grouped)
    }
}
