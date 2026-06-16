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

    var body: some View {
        HStack(spacing: 0) {
            sidebar

            Divider()

            VStack(spacing: 0) {
                if !state.accessibilityGranted {
                    PermissionBanner()
                }

                HStack {
                    Text(state.selectedPage.title)
                        .font(.title3.weight(.semibold))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 6)

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
            }
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(minWidth: 720, minHeight: 500)
        // Accessory (menu-bar) apps don't activate properly when a window opens:
        // the window never becomes key, controls render gray and text fields
        // can't take focus. Promote to .regular while this window is visible.
        .onAppear {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            DispatchQueue.main.async {
                NSApp.windows.first { $0.identifier?.rawValue.hasPrefix("settings") == true }?
                    .makeKeyAndOrderFront(nil)
            }
        }
        .onDisappear {
            if !state.showIconOnDock {
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(SettingsPage.allCases) { page in
                SidebarRow(page: page, isSelected: state.selectedPage == page) {
                    state.selectedPage = page
                }
            }
            Spacer()
        }
        .padding(12)
        .frame(width: 188)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

private struct SidebarRow: View {
    let page: SettingsPage
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovering = false

    private var rowBackground: AnyShapeStyle {
        if isSelected { return AnyShapeStyle(Color.accentColor) }
        if isHovering { return AnyShapeStyle(.quaternary.opacity(0.5)) }
        return AnyShapeStyle(.clear)
    }

    var body: some View {
        Button(action: action) {
            Label {
                Text(page.title)
                    .font(.body)
            } icon: {
                Image(systemName: page.icon)
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 20)
                    .foregroundStyle(isSelected ? .white : Color.accentColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 7)
            .padding(.horizontal, 9)
            .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .background(rowBackground, in: RoundedRectangle(cornerRadius: 8))
        .foregroundStyle(isSelected ? .white : .primary)
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovering)
    }
}

/// Shown until the Accessibility permission is granted.
struct PermissionBanner: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.white)
            Text("MKey cần quyền Trợ năng (Accessibility) để gõ tiếng Việt.")
                .foregroundStyle(.white)
                .font(.callout.weight(.medium))
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
            .tint(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(.orange.gradient)
    }
}
