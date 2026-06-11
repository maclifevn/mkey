//
//  ConvertPage.swift
//  mkey
//
//  Clipboard encoding converter (Unicode ⇄ TCVN3 ⇄ VNI …).
//

import SwiftUI

struct ConvertPage: View {
    @EnvironmentObject private var state: AppState
    @State private var resultMessage: String?

    var body: some View {
        Form {
            Section("Bảng mã") {
                Picker("Từ bảng mã", selection: $state.convertFromCode) {
                    ForEach(AppState.codeTableNames.indices, id: \.self) { i in
                        Text(AppState.codeTableNames[i]).tag(i)
                    }
                }
                Picker("Sang bảng mã", selection: $state.convertToCode) {
                    ForEach(AppState.codeTableNames.indices, id: \.self) { i in
                        Text(AppState.codeTableNames[i]).tag(i)
                    }
                }
                LabeledContent("") {
                    Button {
                        let from = state.convertFromCode
                        state.convertFromCode = state.convertToCode
                        state.convertToCode = from
                    } label: {
                        Label("Đảo chiều", systemImage: "arrow.up.arrow.down")
                    }
                }
            }

            Section("Chữ hoa / chữ thường") {
                Picker("Chuyển đổi", selection: $state.convertCaseMode) {
                    Text("Giữ nguyên").tag(0)
                    Text("IN HOA TOÀN BỘ").tag(1)
                    Text("in thường toàn bộ").tag(2)
                    Text("Hoa chữ cái đầu câu").tag(3)
                    Text("Hoa Mỗi Đầu Từ").tag(4)
                }
                .pickerStyle(.radioGroup)
                Toggle("Loại bỏ dấu thanh (tiếng Việt → khong dau)", isOn: $state.convertRemoveMark)
            }

            Section("Phím tắt chuyển nhanh") {
                HotkeyEditor(status: $state.convertHotKey)
                Toggle("Thông báo khi chuyển mã xong", isOn: $state.convertAlert)
            }

            Section {
                HStack(alignment: .center) {
                    Text("Sao chép văn bản cần chuyển vào clipboard rồi bấm Chuyển mã.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Chuyển mã clipboard") {
                        let ok = MKBridge.quickConvertClipboard()
                        resultMessage = ok
                            ? "Chuyển mã thành công! Kết quả đã được lưu trong clipboard."
                            : "Không có dữ liệu trong clipboard. Hãy sao chép một đoạn văn bản trước."
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .formStyle(.grouped)
        .alert("Công cụ chuyển mã", isPresented: .init(get: { resultMessage != nil }, set: { if !$0 { resultMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(resultMessage ?? "")
        }
    }
}
