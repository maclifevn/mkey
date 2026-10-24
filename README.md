# mkey — Bộ gõ Tiếng Việt cho macOS 26

**mkey** là bộ gõ tiếng Việt cho macOS, xây dựng lại từ engine của dự án mã nguồn mở
[OpenKey](https://github.com/tuyenvm/OpenKey) (© Tuyen Mai, GPL v3) với giao diện
hoàn toàn mới bằng SwiftUI, tối ưu cho macOS 26 (Tahoe trở lên, yêu cầu tối thiểu macOS 14).

## Có gì mới so với OpenKey

- **Giao diện SwiftUI hiện đại** kiểu System Settings: sidebar + form nhóm,
  hỗ trợ Dark Mode tự nhiên, thay cho storyboard/Objective-C cũ.
- **MenuBarExtra** thuần SwiftUI với icon VI/EN vẽ runtime (template image,
  tự đổi màu theo menu bar sáng/tối).
- **Cập nhật trong ứng dụng bằng Sparkle**: tự kiểm tra, tải bản mới, xác thực chữ ký,
  cài đặt và mở lại MKey; có tùy chọn tự tải/cài khi thoát.
- **SMAppService** cho "Khởi động cùng macOS" — bỏ hẳn helper app
  `OpenKeyHelper` và API `SMLoginItemSetEnabled` đã deprecated.
- **Event tap tự hồi phục**: xử lý `kCGEventTapDisabledByTimeout` /
  `ByUserInput` — trên macOS mới, tap hay bị hệ thống tắt ngầm khiến bộ gõ
  "chết lặng"; mkey tự bật lại.
- **Luồng xin quyền Trợ năng mới**: banner trong cửa sổ cài đặt + tự phát hiện
  khi được cấp quyền (không cần khởi động lại app).
- Engine C++ gốc được giữ **nguyên vẹn 100%** — mọi tính năng gõ (Telex/VNI,
  5 bảng mã, gõ tắt, chuyển mã, smart switch…) hoạt động như OpenKey.

## Cấu trúc

```
mkey/
├── project.yml              # đặc tả XcodeGen
├── scripts/make_icon.swift  # sinh app icon bằng CoreGraphics
└── Sources/
    ├── Engine/              # engine C++ nguyên gốc từ OpenKey (GPL v3)
    ├── Platform/            # glue ObjC++: event tap, bridge engine ↔ Swift
    │   ├── MKGlobals.h      # khai báo biến cấu hình cho Swift
    │   ├── MKBridge.h/.mm   # facade: tap lifecycle, macro, chuyển mã
    │   └── MKEngineHook.mm  # CGEventTap callback + key synthesis
    ├── App/                 # SwiftUI: MenuBarExtra, Settings, AppState
    └── Support/             # Info.plist, entitlements, bridging header, assets
```

## Build

Yêu cầu: macOS 14+, Xcode 16+ (đã kiểm thử với Xcode 26.5 trên macOS 26.5), [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen
cd mkey
swift scripts/make_icon.swift Sources/Support/Assets.xcassets/AppIcon.appiconset  # nếu muốn sinh lại icon
xcodegen generate
xcodebuild -project mkey.xcodeproj -scheme mkey -configuration Release -derivedDataPath build
open build/Build/Products/Release/   # chứa mkey.app
```

## Cài đặt & cấp quyền

1. Kéo `mkey.app` vào thư mục **Applications**.
2. Mở app — macOS sẽ hỏi quyền **Trợ năng (Accessibility)**:
   System Settings → Privacy & Security → Accessibility → bật **mkey**.
3. mkey tự phát hiện khi được cấp quyền và bắt đầu hoạt động (không cần mở lại).
4. Phím chuyển Việt/Anh mặc định: **⌥Z** (đổi được trong Bảng điều khiển → Bộ gõ).

> **Chữ ký ứng dụng**: Debug ký ad-hoc; Release dùng Developer ID của nhóm phát hành.
> Nếu tự build mà không có chứng chỉ này, dùng Debug hoặc cấu hình chứng chỉ của bạn
> trong `project.yml`. Khi thay đổi định danh ký, macOS có thể yêu cầu cấp lại quyền Trợ năng.

## Auto update và phát hành

Xem [hướng dẫn cập nhật](docs/UPDATES.md) để tạo gói và feed Sparkle đã ký,
notarize, kiểm thử và phát hành. Bản cũ chưa có Sparkle cần cài bản hỗ trợ lần đầu.

## Giấy phép

Engine và phần glue kế thừa từ OpenKey, phát hành theo **GPL v3**.
Toàn bộ mã mkey (UI SwiftUI, bridge) cũng theo GPL v3.
