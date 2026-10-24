//
//  AboutPage.swift
//  mkey
//

import SwiftUI

struct AboutPage: View {
    @ObservedObject private var updater = UpdateChecker.shared
    private var versionShort: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
    private var versionBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 24)

                    if let icon = NSApp.applicationIconImage {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 104, height: 104)
                            .shadow(color: .black.opacity(0.18), radius: 10, y: 5)
                    }

                    Text("MKey")
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                        .padding(.top, 12)

                    Text("Bộ gõ Tiếng Việt hiện đại cho macOS")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)

                    HStack(spacing: 8) {
                        InfoPill(text: "Phiên bản \(versionShort)")
                        InfoPill(text: "Build \(versionBuild)")
                    }
                    .padding(.top, 10)

                    Button("Kiểm tra cập nhật") {
                        updater.checkForUpdates()
                    }
                    .buttonStyle(.bordered)
                    .disabled(!updater.canCheckForUpdates)
                    .controlSize(.small)
                    .padding(.top, 8)

                    VStack(spacing: 10) {
                        InfoRow(icon: "keyboard",
                                title: "Bộ gõ",
                                caption: "Telex, VNI, bảng mã phổ biến và các tuỳ chọn chính tả.")
                        InfoRow(icon: "app.badge",
                                title: "Tương thích ứng dụng",
                                caption: "Hỗ trợ Spotlight, Raycast, Alfred và cấu hình riêng từng ứng dụng.")
                        InfoRow(icon: "doc.on.clipboard",
                                title: "Tiện ích hằng ngày",
                                caption: "Chuyển mã nhanh, gõ tắt, lịch sử clipboard và đồng bộ iCloud Drive.")
                        InfoRow(icon: "speedometer",
                                title: "Hiệu năng",
                                caption: "Event hook và engine C++ được tối ưu cho độ trễ thấp khi gõ.")
                    }
                    .padding(.top, 18)
                    .padding(.horizontal, 34)
                    .frame(maxWidth: 620)

                    Spacer(minLength: 16)

                    Text("Phát triển bởi **Anh Tuấn** · © 2026")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    VStack(spacing: 5) {
                        Text("Sử dụng engine gõ tiếng Việt từ dự án mã nguồn mở OpenKey (© Tuyen Mai)")
                        HStack(spacing: 16) {
                            Link("Mã nguồn OpenKey", destination: URL(string: "https://github.com/tuyenvm/OpenKey")!)
                            Link("Giấy phép GPL v3", destination: URL(string: "https://www.gnu.org/licenses/gpl-3.0.html")!)
                        }
                    }
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 8)
                    .padding(.bottom, 18)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: proxy.size.height)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct InfoPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.quaternary.opacity(0.38), in: RoundedRectangle(cornerRadius: AppStyle.controlCornerRadius))
    }
}

private struct InfoRow: View {
    let icon: String
    let title: String
    let caption: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 32, height: 32)
                .background(.quaternary.opacity(0.36), in: RoundedRectangle(cornerRadius: AppStyle.controlCornerRadius))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout.weight(.semibold))
                Text(caption)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.18), in: RoundedRectangle(cornerRadius: AppStyle.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppStyle.cardCornerRadius)
                .stroke(.quaternary.opacity(0.38), lineWidth: 1)
        )
    }
}
