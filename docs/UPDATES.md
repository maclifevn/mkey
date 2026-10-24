# Cập nhật MKey bằng Sparkle

MKey dùng Sparkle 2.9.6 giống MFinder: kiểm tra định kỳ, giao diện cập nhật trong
ứng dụng, tải gói, xác thực chữ ký, cài đặt và mở lại. Mặc định tự kiểm tra mỗi
24 giờ; tự tải/cài khi thoát là tuỳ chọn, mặc định tắt. Có nút kiểm tra thủ công
trong menu, trang Giới thiệu và Hệ thống. Lựa chọn `autoCheckUpdate` cũ được chuyển
sang Sparkle một lần, bao gồm trường hợp người dùng đã tắt kiểm tra tự động.

## Cấu hình

- Feed: `https://github.com/maclifevn/mkey/releases/latest/download/appcast.xml`.
- Kho phát hành: `maclifevn/mkey`, tag `v<CFBundleShortVersionString>`.
- Khóa Ed25519 riêng của MKey: tài khoản Keychain `vn.mkey.app`.
  Public key nằm trong `Sources/Support/Info.plist`; private key không nằm trong repo.
- Cả ZIP, appcast và ghi chú phát hành đều phải có chữ ký hợp lệ. Archive được
  xác thực trước khi giải nén. Không sửa các file sau khi đã ký.
- Release dùng Developer ID đội `CF5PGH3KGK`; Debug vẫn ký ad-hoc.
- Chỉ cập nhật app nằm trực tiếp trong `/Applications`, có quyền ghi, không chạy
  từ DMG hay App Translocation. Debug tắt updater trừ khi đặt `MKEY_ENABLE_UPDATES=1`;
  XCTest và SwiftUI previews luôn tắt. Không có feed override trong bản sản xuất.

Sparkle so sánh **CFBundleVersion**, không chỉ số phiên bản hiển thị. Mỗi bản phát
hành phải tăng build và có tag phiên bản mới. Không tái sử dụng phiên bản đã phát hành.

## Tạo bản phát hành

Yêu cầu Xcode, XcodeGen, Python 3, Developer ID và private key MKey trong Keychain.
Đổi phiên bản/build trong `Sources/Support/Info.plist`, viết release notes Markdown,
rồi build universal:

```bash
xcodegen generate
xcodebuild -project mkey.xcodeproj -scheme mkey -configuration Release \
  -derivedDataPath build/DerivedData ARCHS='arm64 x86_64' ONLY_ACTIVE_ARCH=NO build
```

Ký đầy đủ các helper Sparkle, notarize và staple một bản sao của app:

```bash
scripts/notarize.sh \
  build/DerivedData/Build/Products/Release/mkey.app \
  build/notarized-release \
  MFinderNotary
```

`MFinderNotary` là Keychain profile hiện có trên máy phát hành, dùng chung tài
khoản Developer ID với MFinder. Có thể truyền tên profile khác ở tham số cuối và
đổi chứng chỉ bằng `MKEY_SIGNING_IDENTITY`. Script giữ nguyên app nguồn, ký từ
helper bên trong ra app ngoài, yêu cầu Apple trả về `Accepted`, staple, kiểm tra
Gatekeeper và tạo ZIP chứa ticket. Chỉ ký app/framework ngoài cùng là chưa đủ:
các helper Sparkle từ Swift Package Manager có thể vẫn mang chữ ký ad-hoc.

Tạo gói và feed **sau khi staple**, vì staple làm thay đổi nội dung app. Chọn thư mục
output mới; công cụ từ chối ghi đè. Nó kiểm tra định danh app, public key, cấu hình
feed, chữ ký code, rồi ký và kiểm chứng gói, feed, notes; kiểm tra cả việc sửa một
byte phải bị từ chối.

```bash
scripts/build-update-feed.sh \
  build/notarized-release/mkey.app \
  /path/to/release-notes.md \
  build/update-release \
  build/DerivedData/SourcePackages/artifacts/sparkle/Sparkle/bin
```

Với bản tiếp theo, tải feed đang phát hành về file và truyền đường dẫn ở tham số
thứ năm. Công cụ xác thực feed cũ trước khi sử dụng, từ chối build không tăng và
lưu tối đa năm bản. Các release assets cũ phải còn tồn tại tại URL ban đầu.

Output gồm `appcast.xml`, `mkey-<version>.zip`, `mkey-<version>.md`. Đính kèm đủ ba
file vào cùng GitHub Release `v<version>`, sau đó mới công bố release là latest.
Công cụ chỉ tạo file cục bộ; **không tự push, upload hay công bố release**.
Không công bố appcast trỏ tới file chưa upload. Không đánh dấu prerelease là latest.

Feed bootstrap chỉ hoạt động sau khi các assets trên đã được công bố. Người dùng
bản MKey cũ chưa tích hợp Sparkle phải cài bản có Sparkle một lần; các lần sau mới
cập nhật trực tiếp trong ứng dụng. Khi chuyển từ chữ ký ad-hoc sang Developer ID,
macOS có thể yêu cầu cấp lại quyền Trợ năng một lần.

Không mất khóa Ed25519: giữ bản sao lưu Keychain an toàn. Không tạo khóa mới để ký
bản kế tiếp nếu không có kế hoạch xoay khóa; app đã cài sẽ từ chối chữ ký khác.

## Kiểm thử

```bash
xcrun swiftc Sources/App/UpdateRuntimePolicy.swift tests/UpdateRuntimePolicyTests.swift \
  -o /tmp/mkey-update-policy-tests
/tmp/mkey-update-policy-tests
python3 tests/run-update-smoke.py build/update-release/appcast.xml
```

Smoke test dùng controller thật và HTTP server loopback, tạo app thử có bundle ID
riêng trong `/Applications`, rồi tự dọn chúng. Kiểm tra: chuyển lựa chọn opt-out
cũ, đã mới nhất, có bản mới, feed bị sửa chữ ký và lỗi HTTP. Cửa sổ Sparkle có thể
xuất hiện trong lúc chạy; smoke test không cài gói và không thay thế MKey đang dùng.
Truyền feed được tạo từ chính Release build đang nằm trong `build/DerivedData`.

Trước khi phát hành công khai, kiểm tra thêm trên bản đã notarize: cài bản cũ,
cập nhật lên bản mới, xác nhận relaunch, gõ tiếng Việt và quyền Trợ năng. Đây là
kiểm tra khác với smoke test; không suy ra việc cài/relaunch từ việc đọc feed thành công.

Tài liệu upstream: https://sparkle-project.org/documentation/
