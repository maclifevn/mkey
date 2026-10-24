//
//  AppBundleListEditor.swift
//  mkey
//
//  Reusable editor for a list of application bundle identifiers: a card with
//  app rows (icon + name + bundle id + on/off switch), drag-and-drop from
//  Finder, and +/- buttons. Shared by the "Accessibility support" and the
//  "Excluded apps" settings.
//

import SwiftUI
import UniformTypeIdentifiers

struct AppBundleListEditor: View {
    @Binding var apps: [String]
    var emptyHint: String
    var panelMessage: String

    @State private var selected: String?
    @State private var isDropTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 0) {
                if apps.isEmpty {
                    Text(emptyHint)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ForEach(apps, id: \.self) { bundleID in
                        AppBundleRow(
                            app: AppBundleInfo(bundleID: bundleID),
                            isSelected: selected == bundleID,
                            onRemove: { remove(bundleID) }
                        )
                        .contentShape(Rectangle())
                        .onTapGesture { selected = bundleID }

                        if bundleID != apps.last {
                            Divider().padding(.leading, 52)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 116, alignment: .top)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: AppStyle.cardCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppStyle.cardCornerRadius)
                    .stroke(isDropTargeted ? Color.accentColor : Color(nsColor: .separatorColor), lineWidth: 1)
            )
            .onDrop(of: [UTType.fileURL], isTargeted: $isDropTargeted) { providers in
                addAppsFromDrop(providers)
            }

            HStack(spacing: 0) {
                Button {
                    addAppFromFinder()
                } label: {
                    Image(systemName: "plus").frame(width: 24, height: 22)
                }
                .buttonStyle(.borderless)
                .help("Thêm ứng dụng")

                Divider().frame(height: 18)

                Button {
                    if let selected { remove(selected) }
                } label: {
                    Image(systemName: "minus").frame(width: 24, height: 22)
                }
                .buttonStyle(.borderless)
                .disabled(selected == nil)
                .help("Xóa ứng dụng")
            }
            .padding(.top, 6)
        }
    }

    private func remove(_ bundleID: String) {
        apps.removeAll { $0 == bundleID }
        if selected == bundleID { selected = nil }
    }

    private func addAppFromFinder() {
        let panel = NSOpenPanel()
        panel.message = panelMessage
        panel.allowedContentTypes = [.application, .bundle]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        if panel.runModal() == .OK, let url = panel.url {
            addApp(at: url)
        }
    }

    private func addAppsFromDrop(_ providers: [NSItemProvider]) -> Bool {
        var handled = false
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            handled = true
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                guard let url = Self.fileURL(from: item) else { return }
                Task { @MainActor in addApp(at: url) }
            }
        }
        return handled
    }

    private func addApp(at url: URL) {
        guard let bundleID = Self.bundleID(for: url) else { return }
        if !apps.contains(bundleID) { apps.append(bundleID) }
        selected = bundleID
    }

    private static func bundleID(for url: URL) -> String? {
        if let bundleID = Bundle(url: url)?.bundleIdentifier { return bundleID }
        if let infoDict = NSDictionary(contentsOf: url.appendingPathComponent("Contents/Info.plist")),
           let bundleID = infoDict["CFBundleIdentifier"] as? String {
            return bundleID
        }
        return nil
    }

    private static func fileURL(from item: NSSecureCoding?) -> URL? {
        if let url = item as? URL { return url }
        if let data = item as? Data { return URL(dataRepresentation: data, relativeTo: nil) }
        if let string = item as? String { return URL(string: string) }
        return nil
    }
}

struct AppBundleInfo {
    let bundleID: String

    var appURL: URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
    }

    var name: String {
        if let appURL,
           let displayName = Bundle(url: appURL)?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
            return displayName
        }
        if let appURL,
           let bundleName = Bundle(url: appURL)?.object(forInfoDictionaryKey: "CFBundleName") as? String {
            return bundleName
        }
        return bundleID
    }

    var icon: NSImage {
        guard let appURL else { return NSWorkspace.shared.icon(for: .application) }
        return NSWorkspace.shared.icon(forFile: appURL.path)
    }
}

private struct AppBundleRow: View {
    let app: AppBundleInfo
    let isSelected: Bool
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: app.icon)
                .resizable()
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name).font(.footnote).lineLimit(1)
                Text(app.bundleID).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }

            Spacer()

            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Xóa khỏi danh sách")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor.opacity(0.16) : Color.clear)
    }
}
