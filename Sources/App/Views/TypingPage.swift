//
//  TypingPage.swift
//  mkey
//
//  Core typing configuration: language, input type, code table,
//  switch hotkey and engine behaviour toggles.
//

import SwiftUI
import UniformTypeIdentifiers

struct TypingPage: View {
    @EnvironmentObject private var state: AppState
    @State private var selectedAXApp: String?
    @State private var isAXAppDropTargeted = false

    private var beepBinding: Binding<Bool> {
        Binding {
            state.switchKeyStatus & 0x8000 != 0
        } set: { on in
            if on { state.switchKeyStatus |= 0x8000 } else { state.switchKeyStatus &= ~0x8000 }
        }
    }

    var body: some View {
        Form {
            Section("Chế độ gõ") {
                Toggle("Bật Tiếng Việt", isOn: $state.isVietnamese)

                Picker("Kiểu gõ", selection: $state.inputType) {
                    ForEach(AppState.inputTypeNames.indices, id: \.self) { i in
                        Text(AppState.inputTypeNames[i]).tag(i)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Bảng mã", selection: $state.codeTable) {
                    ForEach(AppState.codeTableNames.indices, id: \.self) { i in
                        Text(AppState.codeTableNames[i]).tag(i)
                    }
                }
            }

            Section("Phím chuyển chế độ") {
                HotkeyEditor(status: $state.switchKeyStatus)
                Toggle("Kêu beep khi chuyển chế độ", isOn: beepBinding)
            }

            Section("Chính tả") {
                Toggle("Kiểm tra chính tả", isOn: $state.checkSpelling)
                Toggle("Khôi phục phím nếu từ sai chính tả", isOn: $state.restoreIfWrongSpelling)
                    .disabled(!state.checkSpelling)
                Toggle("Tạm tắt kiểm tra chính tả bằng phím ⌃", isOn: $state.tempOffSpelling)
                    .disabled(!state.checkSpelling)
                Toggle("Cho phép phụ âm Z, F, W, J đầu từ", isOn: $state.allowZFWJ)
                    .disabled(!state.checkSpelling)
                Toggle("Dấu thanh kiểu mới (oà, uý)", isOn: $state.modernOrthography)
                Toggle("Bỏ dấu tự do", isOn: $state.freeMark)
            }

            Section("Gõ nhanh") {
                Toggle("Gõ nhanh Telex (cc→ch, gg→gi, …)", isOn: $state.quickTelex)
                Toggle("Phụ âm đầu nhanh (f→ph, j→gi, w→qu)", isOn: $state.quickStartConsonant)
                Toggle("Phụ âm cuối nhanh (g→ng, h→nh, k→ch)", isOn: $state.quickEndConsonant)
                Toggle("Tự viết hoa chữ đầu câu", isOn: $state.upperCaseFirstChar)
            }

            Section("Tương thích") {
                Toggle("Sửa lỗi gợi ý của trình duyệt và Excel", isOn: $state.fixRecommendBrowser)
                Toggle("Sửa lỗi nhân Chromium (thử nghiệm)", isOn: $state.fixChromiumBrowser)
                    .disabled(!state.fixRecommendBrowser)
                Toggle("Tạm tắt mkey bằng phím ⌘", isOn: $state.tempOffByCommand)
                Toggle("Tắt Tiếng Việt khi dùng bàn phím ngôn ngữ khác", isOn: $state.otherLanguage)
            }

            Section("Hỗ trợ Trợ năng") {
                Toggle("Bật Trợ năng cho Spotlight, Raycast, Alfred", isOn: $state.fixSpotlight)

                VStack(alignment: .leading, spacing: 0) {
                    VStack(spacing: 0) {
                        if state.axIncludeApps.isEmpty {
                            Text("Chưa có ứng dụng nào, kéo thả ứng dụng vào đây hoặc nhấn nút + để thêm.")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            ForEach(state.axIncludeApps, id: \.self) { bundleID in
                                AXSupportAppRow(
                                    app: AXSupportApp(bundleID: bundleID),
                                    isSelected: selectedAXApp == bundleID,
                                    isEnabled: Binding {
                                        state.axIncludeApps.contains(bundleID)
                                    } set: { enabled in
                                        if !enabled {
                                            removeAXApp(bundleID)
                                        }
                                    }
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedAXApp = bundleID
                                }

                                if bundleID != state.axIncludeApps.last {
                                    Divider()
                                        .padding(.leading, 52)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 116, alignment: .top)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isAXAppDropTargeted ? Color.accentColor : Color(nsColor: .separatorColor), lineWidth: 1)
                    )
                    .onDrop(of: [UTType.fileURL], isTargeted: $isAXAppDropTargeted) { providers in
                        addAppsFromDrop(providers)
                    }

                    HStack(spacing: 0) {
                        Button {
                            addAppFromFinder()
                        } label: {
                            Image(systemName: "plus")
                                .frame(width: 24, height: 22)
                        }
                        .buttonStyle(.borderless)
                        .help("Thêm ứng dụng")

                        Divider()
                            .frame(height: 18)

                        Button {
                            if let selectedAXApp {
                                removeAXApp(selectedAXApp)
                            }
                        } label: {
                            Image(systemName: "minus")
                                .frame(width: 24, height: 22)
                        }
                        .buttonStyle(.borderless)
                        .disabled(selectedAXApp == nil)
                        .help("Xóa ứng dụng")
                    }
                    .padding(.top, 6)
                }
            }
        }
        .formStyle(.grouped)
    }

    private func removeAXApp(_ bundleID: String) {
        state.axIncludeApps.removeAll { $0 == bundleID }
        if selectedAXApp == bundleID {
            selectedAXApp = nil
        }
    }

    private func addAppFromFinder() {
        let panel = NSOpenPanel()
        panel.message = "Chọn ứng dụng để bật hỗ trợ Trợ năng (Accessibility)"
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
                guard let url = fileURL(from: item) else { return }
                Task { @MainActor in
                    addApp(at: url)
                }
            }
        }
        return handled
    }

    private func addApp(at url: URL) {
        guard let bundleID = bundleID(for: url) else { return }
        if !state.axIncludeApps.contains(bundleID) {
            state.axIncludeApps.append(bundleID)
        }
        selectedAXApp = bundleID
    }

    private func bundleID(for url: URL) -> String? {
        if let bundleID = Bundle(url: url)?.bundleIdentifier {
            return bundleID
        }
        if let infoDict = NSDictionary(contentsOf: url.appendingPathComponent("Contents/Info.plist")),
           let bundleID = infoDict["CFBundleIdentifier"] as? String {
            return bundleID
        }
        return nil
    }

    private func fileURL(from item: NSSecureCoding?) -> URL? {
        if let url = item as? URL {
            return url
        }
        if let data = item as? Data {
            return URL(dataRepresentation: data, relativeTo: nil)
        }
        if let string = item as? String {
            return URL(string: string)
        }
        return nil
    }
}

private struct AXSupportApp {
    let bundleID: String

    var appURL: URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
    }

    var name: String {
        if let appURL,
           let bundle = Bundle(url: appURL),
           let displayName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
            return displayName
        }
        if let appURL,
           let bundleName = Bundle(url: appURL)?.object(forInfoDictionaryKey: "CFBundleName") as? String {
            return bundleName
        }
        return bundleID
    }

    var icon: NSImage {
        guard let appURL else {
            return NSWorkspace.shared.icon(for: .application)
        }
        return NSWorkspace.shared.icon(forFile: appURL.path)
    }
}

private struct AXSupportAppRow: View {
    let app: AXSupportApp
    let isSelected: Bool
    @Binding var isEnabled: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: app.icon)
                .resizable()
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.system(size: 13))
                    .lineLimit(1)
                Text(app.bundleID)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Toggle("", isOn: $isEnabled)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor.opacity(0.16) : Color.clear)
    }
}
