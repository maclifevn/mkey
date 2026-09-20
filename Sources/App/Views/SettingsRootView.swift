//
//  SettingsRootView.swift
//  mkey
//
//  Settings window: custom sidebar + detail pane. A hand-rolled sidebar is
//  used instead of NavigationSplitView, which mis-renders its selection row
//  into the titlebar area on macOS 26.
//

import SwiftUI

struct SettingsRootView: View {
    @EnvironmentObject private var state: AppState
    @State private var headerHeight: CGFloat = 80

    var body: some View {
        HStack(spacing: 0) {
            sidebar

            ZStack(alignment: .top) {
                Group {
                    switch state.selectedPage {
                    case .typing: TypingPage()
                    case .macro: MacroPage()
                    case .convert: ConvertPage()
                    case .clipboard: ClipboardPage()
                    case .system: SystemPage()
                    case .about: AboutPage()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaPadding(.top, headerHeight + 32)
                .mask(
                    VStack(spacing: 0) {
                        Color.black.opacity(0.35)
                            .frame(height: headerHeight)
                        LinearGradient(
                            colors: [Color.black.opacity(0.35), .black],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 32)
                        Color.black
                    }
                )

                VStack(spacing: 0) {
                    PageHeader(page: state.selectedPage)
                }
                .readSize { size in
                    self.headerHeight = size.height
                }
            }
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.55))
            .background(VisualEffectBlur(material: .sidebar))
        }
        .frame(minWidth: 820, maxWidth: 820, minHeight: 560, maxHeight: .infinity)
        .ignoresSafeArea(.container, edges: .top)
        .onAppear {
            DispatchQueue.main.async {
                if let window = NSApp.windows.first(where: { $0.identifier?.rawValue.hasPrefix("settings") == true }) {
                    window.titlebarAppearsTransparent = true
                    window.titleVisibility = .hidden
                    window.isMovableByWindowBackground = true
                    window.isOpaque = false
                    window.backgroundColor = .clear
                    window.minSize = NSSize(width: 820, height: 560)
                    window.maxSize = NSSize(width: 820, height: CGFloat.greatestFiniteMagnitude)
                }
            }
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Spacer(minLength: 0)

                if let icon = NSApp.applicationIconImage {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 64, height: 64)
                        .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.top, 38)
            .padding(.bottom, 8)

            VStack(alignment: .leading, spacing: 6) {
                Text("CÀI ĐẶT")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 1)

                ForEach(SettingsPage.allCases) { page in
                    SidebarRow(page: page, isSelected: state.selectedPage == page) {
                        state.selectedPage = page
                    }
                }
            }

            Spacer()

            StatusBadge(isReady: state.accessibilityGranted)
        }
        .padding(14)
        .frame(width: 192)
        .background(VisualEffectBlur(material: .sidebar))
        .overlay(alignment: .trailing) {
            Divider()
        }
    }
}

private struct PageHeader: View {
    let page: SettingsPage

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: page.icon)
                .font(.title2.weight(.bold))
            Text(page.title)
                .font(.title2.weight(.bold))
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
}

private struct StatusBadge: View {
    let isReady: Bool

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isReady ? Color.green : Color.orange)
                .frame(width: 7, height: 7)
            Text(isReady ? "Đã sẵn sàng" : "Cần quyền Trợ năng")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.quaternary.opacity(0.26), in: RoundedRectangle(cornerRadius: AppStyle.controlCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppStyle.controlCornerRadius)
                .stroke(.quaternary.opacity(0.48), lineWidth: 1)
        )
    }
}

private struct SidebarRow: View {
    let page: SettingsPage
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovering = false

    private var rowBackground: AnyShapeStyle {
        if isSelected { return AnyShapeStyle(Color.accentColor.opacity(0.13)) }
        if isHovering { return AnyShapeStyle(.quaternary.opacity(0.3)) }
        return AnyShapeStyle(.clear)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: page.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    .frame(width: 22, height: 22)

                Text(page.title)
                    .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                    .lineLimit(1)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 7)
            .padding(.horizontal, 10)
            .contentShape(RoundedRectangle(cornerRadius: AppStyle.controlCornerRadius))
        }
        .buttonStyle(.plain)
        .background(rowBackground, in: RoundedRectangle(cornerRadius: AppStyle.controlCornerRadius))
        .foregroundStyle(.primary)
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovering)
        .animation(.easeOut(duration: 0.12), value: isSelected)
    }
}

/// Shown until the Accessibility permission is granted.
struct PermissionBanner: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text("MKey cần quyền Trợ năng (Accessibility) để gõ tiếng Việt.")
                .font(.footnote.weight(.medium))
            Spacer()
            Button("Mở Cài đặt hệ thống") {
                // re-register MKey into the Accessibility list (macOS won't let an
                // app enable itself, but this adds it back so the user only needs
                // to flip the switch) and start polling so no relaunch is needed
                NotificationCenter.default.post(name: .mkRequestAccessibility, object: nil)
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal, 14)
        .padding(.top, 36)
        .padding(.bottom, 10)
        .background(Color.orange.opacity(0.12))
    }
}

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

extension View {
    fileprivate func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometry.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}

struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .sidebar
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
