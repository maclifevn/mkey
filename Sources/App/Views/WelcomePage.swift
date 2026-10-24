//
//  WelcomePage.swift
//  mkey
//

import SwiftUI

struct WelcomePage: View {
    @EnvironmentObject private var state: AppState
    @State private var isPulsing = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // App Icon with a soft shadow and glow
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 120, height: 120)
                    .blur(radius: 12)
                
                if let icon = NSApp.applicationIconImage {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 80, height: 80)
                        .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
                } else {
                    Image(systemName: "keyboard")
                        .font(.system(size: 52))
                        .foregroundStyle(Color.accentColor)
                }
            }

            // Welcome Text
            VStack(spacing: 6) {
                Text("Chào mừng đến với MKey")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text("Bộ gõ Tiếng Việt hiện đại, an toàn và siêu nhẹ cho macOS.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            // Permissions Instruction Card
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .font(.title3)
                        .foregroundStyle(Color.accentColor)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Yêu cầu quyền Trợ năng (Accessibility)")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text("Để MKey có thể nhận diện phím gõ và chuyển đổi thành chữ Tiếng Việt có dấu trực tiếp trên ứng dụng của bạn, macOS yêu cầu quyền Trợ năng.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineSpacing(2)
                    }
                }
            }
            .padding(18)
            .background(.quaternary.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.quaternary.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 32)

            // CTA and Status
            VStack(spacing: 14) {
                Button {
                    requestPermission()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "hand.tap.fill")
                        Text("Mở Cài đặt hệ thống")
                    }
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                // Pulsing Status Indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                        .opacity(isPulsing ? 0.3 : 1.0)
                        .scaleEffect(isPulsing ? 1.3 : 1.0)
                    
                    Text("Đang chờ bạn bật quyền trong Cài đặt hệ thống...")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        isPulsing = true
                    }
                }
            }

            Spacer()
        }
        .frame(width: 480)
        .frame(maxHeight: .infinity)
        .background(VisualEffectBlur(material: .sidebar))
        .ignoresSafeArea()
        .onAppear {
            DispatchQueue.main.async {
                if let window = NSApp.windows.first(where: { $0.identifier?.rawValue.hasPrefix("welcome") == true }) {
                    window.titlebarAppearsTransparent = true
                    window.titleVisibility = .hidden
                    window.isMovableByWindowBackground = true
                    window.isOpaque = false
                    window.backgroundColor = .clear
                }
            }
        }
        .onReceive(state.$accessibilityGranted) { granted in
            if granted {
                // close the welcome window
                if let welcomeWindow = NSApp.windows.first(where: { $0.identifier?.rawValue == "welcome" }) {
                    welcomeWindow.close()
                }
                // open settings window
                NotificationCenter.default.post(name: .mkOpenSettingsWindow, object: nil)
            }
        }
    }

    private func requestPermission() {
        NotificationCenter.default.post(name: .mkRequestAccessibility, object: nil)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
