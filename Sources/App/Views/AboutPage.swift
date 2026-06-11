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
        VStack(spacing: 0) {
            Spacer(minLength: 28)

            if let icon = NSApp.applicationIconImage {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 116, height: 116)
                    .shadow(color: .black.opacity(0.22), radius: 12, y: 6)
            }

            Text("MKey")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .padding(.top, 14)

            Text("Bộ gõ Tiếng Việt hiện đại cho macOS")
                .font(.title3)
                .foregroundStyle(.secondary)
                .padding(.top, 2)

            HStack(spacing: 8) {
                InfoPill(text: "Phiên bản \(versionShort)")
                InfoPill(text: "Build \(versionBuild)")
                InfoPill(text: "macOS 26")
            }
            .padding(.top, 12)

            HStack(spacing: 12) {
                FeatureCard(icon: "magnifyingglass",
                            title: "Mượt trong Spotlight",
                            caption: "Sửa chữ qua Accessibility API — gõ nhanh không nhảy chữ")
                FeatureCard(icon: "bolt.fill",
                            title: "Gõ tắt & chuyển mã",
                            caption: "Macro thông minh, 5 bảng mã, chuyển mã clipboard tức thì")
                FeatureCard(icon: "arrow.triangle.2.circlepath",
                            title: "Chuyển thông minh",
                            caption: "Tự nhớ Việt/Anh và bảng mã theo từng ứng dụng")
            }
            .padding(.top, 26)
            .padding(.horizontal, 28)

            Spacer(minLength: 20)

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
            .padding(.top, 10)
            .padding(.bottom, 22)
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
            .padding(.horizontal, 11)
            .padding(.vertical, 4)
            .background(.quaternary.opacity(0.5), in: Capsule())
    }
}

private struct FeatureCard: View {
    let icon: String
    let title: String
    let caption: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(
                    LinearGradient(colors: [Color(red: 0.16, green: 0.55, blue: 0.85),
                                            Color(red: 0.00, green: 0.40, blue: 0.67)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 11)
                )
            Text(title)
                .font(.callout.weight(.semibold))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text(caption)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .top)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 14))
    }
}
