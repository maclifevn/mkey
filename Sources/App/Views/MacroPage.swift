//
//  MacroPage.swift
//  mkey
//
//  Shortcut (macro) manager: table + add/edit/delete + import/export.
//

import SwiftUI
import UniformTypeIdentifiers

struct MacroRow: Identifiable, Hashable {
    let id: String
    let text: String
    let content: String
}

struct MacroPage: View {
    @EnvironmentObject private var state: AppState

    @State private var rows: [MacroRow] = []
    @State private var selection: MacroRow.ID?
    @State private var newText = ""
    @State private var newContent = ""
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    private enum Field { case text, content }

    private var isEditingExisting: Bool {
        rows.contains { $0.text == newText }
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Tuỳ chọn") {
                    Toggle("Bật gõ tắt", isOn: $state.useMacro)
                    Toggle("Dùng gõ tắt cả trong chế độ tiếng Anh", isOn: $state.useMacroInEnglishMode)
                        .disabled(!state.useMacro)
                    Toggle("Tự hoa theo từ gốc (btw→by the way, Btw→By the way)", isOn: $state.autoCapsMacro)
                        .disabled(!state.useMacro)
                }

                Section("Thêm / sửa gõ tắt") {
                    HStack(spacing: 8) {
                        TextField("Từ tắt", text: $newText, prompt: Text("Từ tắt"))
                            .labelsHidden()
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 130)
                            .focused($focusedField, equals: .text)
                            .onSubmit { focusedField = .content }
                        TextField("Nội dung thay thế", text: $newContent, prompt: Text("Nội dung thay thế"))
                            .labelsHidden()
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: .infinity)
                            .focused($focusedField, equals: .content)
                            .onSubmit { addOrEdit() }
                        Button(isEditingExisting ? "Sửa" : "Thêm") {
                            addOrEdit()
                        }
                        .buttonStyle(.borderedProminent)
                        Button("Xoá", role: .destructive) {
                            deleteSelected()
                        }
                        .disabled(!isEditingExisting)
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Table(rows, selection: $selection) {
                        TableColumn("Từ tắt") { row in
                            Text(row.text)
                        }
                        .width(min: 90, ideal: 130, max: 220)
                        TableColumn("Nội dung thay thế") { row in
                            Text(row.content)
                        }
                    }
                    .frame(minHeight: 220)
                    .alternatingRowBackgrounds()
                    .onChange(of: selection) { _, newValue in
                        if let id = newValue, let row = rows.first(where: { $0.id == id }) {
                            newText = row.text
                            newContent = row.content
                        }
                    }

                    HStack {
                        Button("Nhập từ file…") { importFromFile() }
                        Button("Xuất ra file…") { exportToFile() }
                        Spacer()
                        Text("\(rows.count) mục")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Danh sách gõ tắt")
                }
            }
            .formStyle(.grouped)
        }
        .onAppear {
            reload()
            focusedField = .text
        }
        .alert("Gõ tắt", isPresented: .init(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func reload() {
        rows = MKBridge.allMacros().map {
            MacroRow(id: $0.text, text: $0.text, content: $0.content)
        }
    }

    private func addOrEdit() {
        guard !newText.isEmpty, !newContent.isEmpty else {
            errorMessage = "Bạn hãy nhập cả từ tắt và nội dung thay thế!"
            return
        }
        MKBridge.addMacro(newText, content: newContent)
        newText = ""
        newContent = ""
        selection = nil
        reload()
        focusedField = .text
    }

    private func deleteSelected() {
        guard !newText.isEmpty else {
            errorMessage = "Bạn hãy chọn từ cần xoá trong danh sách!"
            return
        }
        guard MKBridge.deleteMacro(newText) else {
            errorMessage = "Không tìm thấy từ tắt \"\(newText)\" trong danh sách."
            return
        }
        newText = ""
        newContent = ""
        selection = nil
        reload()
    }

    private func importFromFile() {
        let panel = NSOpenPanel()
        panel.message = "Chọn file dữ liệu gõ tắt"
        panel.allowedContentTypes = [.plainText]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }

        let alert = NSAlert()
        alert.messageText = "Dữ liệu gõ tắt"
        alert.informativeText = "Bạn có muốn giữ lại các dữ liệu hiện tại không?"
        alert.addButton(withTitle: "Có")
        alert.addButton(withTitle: "Không")
        let keep = alert.runModal() == .alertFirstButtonReturn
        MKBridge.importMacros(fromFile: url.path, append: keep)
        reload()
    }

    private func exportToFile() {
        let panel = NSSavePanel()
        panel.message = "Chọn nơi lưu dữ liệu gõ tắt"
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "mkeyMacro"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        MKBridge.exportMacros(toFile: url.path)
    }
}
