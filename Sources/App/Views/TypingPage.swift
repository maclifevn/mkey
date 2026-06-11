//
//  TypingPage.swift
//  mkey
//
//  Core typing configuration: language, input type, code table,
//  switch hotkey and engine behaviour toggles.
//

import SwiftUI

struct TypingPage: View {
    @EnvironmentObject private var state: AppState

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
                Toggle("Sửa lỗi nhảy chữ trên Spotlight, Raycast, Alfred", isOn: $state.fixSpotlight)
                Toggle("Sửa lỗi gợi ý của trình duyệt và Excel", isOn: $state.fixRecommendBrowser)
                Toggle("Sửa lỗi nhân Chromium (thử nghiệm)", isOn: $state.fixChromiumBrowser)
                    .disabled(!state.fixRecommendBrowser)
                Toggle("Tạm tắt mkey bằng phím ⌘", isOn: $state.tempOffByCommand)
                Toggle("Tắt Tiếng Việt khi dùng bàn phím ngôn ngữ khác", isOn: $state.otherLanguage)
            }
        }
        .formStyle(.grouped)
    }
}
