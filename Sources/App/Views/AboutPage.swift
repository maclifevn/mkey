//
//  AboutPage.swift
//  mkey
//

import SwiftUI

struct AboutPage: View {
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
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .padding(.top, 12)

                    Text("Bộ gõ Tiếng Việt hiện đại cho macOS")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)

                    HStack(spacing: 8) {
                        InfoPill(text: "Phiên bản \(versionShort)")
                        InfoPill(text: "Build \(versionBuild)")
                        InfoPill(text: "macOS 26")
                    }
                    .padding(.top, 10)

                    Button("Kiểm tra cập nhật") {
                        AppState.shared.selectedPage = .system
                        Task { await UpdateChecker.shared.check(manual: true) }
                    }
                    .buttonStyle(.bordered)
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
                        .font(.callout)

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
            .background(.quaternary.opacity(0.45), in: Capsule())
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
                .background(.quaternary.opacity(0.42), in: RoundedRectangle(cornerRadius: 7))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout.weight(.semibold))
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.24), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.quaternary.opacity(0.45), lineWidth: 1)
        )
    }
}
