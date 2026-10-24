# Khảo sát và vá lỗi upstream cho MKey

Ngày khảo sát: **2026-10-23**, cập nhật đến **2026-10-24** (redraw và bộ từ điển), múi giờ Asia/Ho_Chi_Minh. Nhánh: **`fix/upstream-issues`**, tạo từ **`e8fdc10`**.

## Kết quả và phạm vi

Trong các đợt khảo sát engine, áp dụng **17 lỗi**, mỗi lỗi một commit: 13 lỗi từ các đợt trước, phụ âm đầu theo từ điển ở mục 11, dấu mũ/móc nhập muộn ở mục 12, GI có phụ âm cuối khi bật Free Mark ở mục 13 và Quick Telex theo từ điển ở mục 15. Thay đổi sản phẩm ở engine C++ và một hunk giới hạn xoá của `MKEngineHook.mm`; các bản vá engine không sửa UI, giá trị mặc định hoặc metadata phiên bản. Việc đồng bộ 1.6.1 và chuẩn bị phát hành theo yêu cầu sau đó được ghi riêng ở mục 14. Bốn bản vá từ điển không sửa hook. **Cả 5 sai lệch English vẫn giữ nguyên**; người dùng chọn giữ luật Telex và chốt thêm **`gisups`→`giups` như từ gõ chuẩn**, thay cho hai dấu cũ.

Working tree ban đầu có 18 file sửa và 9 mục untracked. Người dùng đã cho phép bỏ điều kiện dừng. Các thay đổi đó được giữ nguyên, không đưa vào commit của đợt này. Riêng hook đã có sửa của người dùng: chỉ stage hunk redraw tự viết trên nội dung HEAD, giữ các hunk khác ở working tree. Build được thực hiện trên checkout đang có các thay đổi của người dùng; không nên hiểu kết quả này là một lần build clean checkout chỉ chứa các commit mới. Hash các file có sẵn được đối chiếu lại khi kết thúc, sau khi loại đúng hunk redraw khỏi hook để kiểm nội dung ban đầu.

- Baseline trước mọi fix: **404 ca**, **399 PASS + 5 lỗi có sẵn**. Kỳ vọng độc lập với kết quả engine, không đổi kỳ vọng để khớp lỗi.
- Sau đợt đầu: 506 ca, 501 PASS + 5 lỗi có sẵn; sau bản vá lịch sử: 528 ca, 523 PASS + 5 known. Hiện tại: **4.116 ca, 4.111 PASS + đúng 5 sai lệch có sẵn, 0 lỗi mới**; gồm 404 baseline, 580 regression, 94 ca đối chiếu/giao thức/escape, 626 ca ConvertTool, 411 ca redraw, 119 ca phụ âm đầu, 622 ca Free Mark, 539 ca GI và 721 ca Quick Telex. Thêm 46 ca kiểm chính sách xoá, 16 ca packet trực tiếp, 22 ca tra từ điển, 27 ca prefix và 24 ca GI packet/macro/escape, đều PASS.
- Cả 17 bản vá đều có test tái hiện FAIL trước sửa, PASS sau sửa. Đợt trước: **54 ca caps, 46 ca undo tone, 220 ca đ muộn, 230 ca ConvertTool FAIL → PASS**; redraw có **379 FAIL → PASS**; phụ âm đầu có **48 FAIL/ERROR → PASS**; Free Mark có **509 FAIL → PASS**; GI thêm **256 FAIL → PASS**, cùng 24 contract FAIL → PASS; Quick Telex có **459 FAIL → PASS**. Không có trường hợp chỉ suy đoán rồi sửa. Build từng commit được ghi trong log kiểm tra sau commit.
- **72 guard** kiểm chính sách Telex đã chốt (trong đó `tesst`→`test`, `ass`→`as`, cả restore on/off) đều PASS trước/sau các bản vá. Không đổi baseline hoặc thêm known failure.
- Sanitizer: **ASan + UBSan PASS cho cả suite 4.116 ca và 135 kiểm tra packet/policy/dictionary/GI** (4.111 PASS, 5 known text failures; **0 sanitizer error**), với `-fno-sanitize-recover=all`.
- Review độc lập đã kiểm tra giao thức harness và các đoạn chuyển thể; kết quả review cuối: không có finding còn mở trong các bản vá đã nhận; đề xuất có regression được hoãn hoặc thu hẹp như mục 8. Finding shortcut của fix English macro đã được sửa, có test trước/sau; guard bounds cũng được review riêng.
- Mọi checklist ứng dụng thật bên dưới **chưa được test tay trong đợt này**.

Dữ liệu thô, bare clone, JSON issue/comment/timeline, diff và log build nằm **ngoài repo** tại `/Users/maclife/mkey-research/2026-10-23-upstream-6jsso5qt/`. `mkey-before/Sources/Engine/` là snapshot **MKey**, dùng cho probe trước sửa. Chỉ compile MKey hiện tại hoặc snapshot này; không chạy/build mã của repo khác.

Điều tra bổ sung nằm trong `baseline-followup/`; snapshot MKey trước bản vá thứ 8 là `baseline-followup/mkey-before/Sources/Engine/` tại `17a6dec`. Đã đối chiếu lại SHA-256: **29 file có sẵn của người dùng không đổi**.

Đợt điều tra tiếp theo nằm trong `pending-followup/`; snapshot trước bốn bản vá mới là `pending-followup/mkey-before/Sources/Engine/` tại `c4bbdb4`. Các bản thử gây regression chỉ sửa **bản sao MKey ngoài repo**, không phải checkout upstream; source upstream vẫn chỉ được đọc. Kết quả và giới hạn của cả bảy nhóm ở mục 8.

Đợt redraw bắt đầu từ `058ecb6`, lưu riêng tại `/Users/maclife/mkey-research/2026-10-24-redraw-et6cjaka/`. Snapshot `before/` giữ MKey và harness trước sửa; `naive/` là bản sao MKey thử hunk mở rộng đơn thuần để tái hiện ba lỗi duplicate. Kết quả cuối ở mục 9.

Điều tra Free Mark bắt đầu từ `05d6c43`, lưu tại `/Users/maclife/mkey-research/2026-10-24-free-mark-and5ucp9/`. **Đợt đó không nhận thêm bản vá engine**; mục 10 lưu các khác biệt mode và regression của bản thử. Theo yêu cầu mới từ ảnh, người dùng cho phép giải pháp tự viết dựa trên từ điển cho phụ âm đầu và bỏ dấu tự do; vẫn bắt buộc giữ escape Telex. Dữ liệu, snapshot `ec8d155` và log đợt mới ở `/Users/maclife/mkey-research/2026-10-24-dictionary-fixes-46r7lgt3/`.

Đợt GI tiếp theo bắt đầu tại `e3f343f`, lưu snapshot MKey, oracle trước sửa và bản thử tại `/Users/maclife/mkey-research/2026-10-24-gisup-j22xbmph/`. Người dùng đã chọn rõ luật hủy dấu theo từ gõ chuẩn; 10 kỳ vọng GI cũ được đối chiếu và cập nhật có chủ ý như bảng mục 13. Baseline gốc và known failures không đổi.

## 1. Repo và độ sâu khảo sát

“Tải/sàng lọc” dưới đây là lấy toàn bộ issue body, duyệt danh sách tiêu đề/trạng thái để phân loại; **không có nghĩa là đã đọc kỹ mọi thảo luận**. Đọc sâu nghĩa là đối chiếu body, comment/timeline liên quan và source/fix. Các issue `not_planned` không dùng làm bằng chứng lỗi đã sửa. Issue trùng được gộp ở bảng ứng viên.

| Repo | Engine thực tế | Giấy phép đã thấy | Issue lấy/sàng lọc; đọc sâu |
|---|---|---|---|
| [tuyenvm/OpenKey](https://github.com/tuyenvm/OpenKey) | C++ gốc `Engine.cpp`/`Vietnamese.cpp`, hook `OpenKey.mm` | GPL v3 | 288 issue, 148 completed, 1 not_planned; đọc sâu 11 issue engine và PR #306/#323/#297, sàng lọc 20 PR merged |
| [xmannv/xkey](https://github.com/xmannv/xkey) | Port Swift giữ mask/state, `insertW`, `insertAOE`, `checkGrammar`; thêm dictionary/IMKit riêng | LICENSE khai MIT; source ghi lineage OpenKey. Không chép code Swift vào MKey trong đợt này | 306 issue, 305 completed, 1 not_planned; đọc sâu 23 issue; 14 PR merged |
| [PhamHungTien/PHTV](https://github.com/PhamHungTien/PHTV) | C++ phái sinh OpenKey trước đây; HEAD là port Swift `PHTVEngineCore.swift` | **AGPL v3 ở HEAD**; riêng commit C++ dùng cho fix #30 có **GPL v3-or-later** tại đúng revision | 192 issue, 190 completed, 2 not_planned; đọc sâu 13 issue; 4 PR merged |
| [nghialuong/84Key](https://github.com/nghialuong/84Key) | OpenKey C++, thêm English heuristics/raw history | GPL v3 | 1 issue mở, 0 completed; sàng lọc 24 PR merged; đọc sâu PR #23 và bốn commit bảo vệ raw history ở đợt bổ sung |
| [viethoavnm/LibreKey](https://github.com/viethoavnm/LibreKey) | OpenKey C++ nguyên cấu trúc, có fix engine/hook | GPL v3, đọc LICENSE | 0 issue/PR; đọc các fix engine, parent/preimage, HEAD và follow-up. Số # trong commit là **issue OpenKey gốc** |
| [coderunknow/KieeKey](https://github.com/coderunknow/KieeKey) | C++20 `TextEngine.cpp` chuyển OpenKey 2.0.5 sang per-instance; product vẫn dùng engine này; OpenKey reference trong tests là bản đối chiếu riêng | GPL v3-or-later | 0 issue; 34 PR merged, lướt lịch sử sửa engine; không chuyển kiến trúc C++20 vào MKey; chỉ dịch guard bounds nhỏ được kiểm độc lập |
| [ToThangGTVT/OpenKeySwift](https://github.com/ToThangGTVT/OpenKeySwift) | **C++** `engine/Engine.cpp`, UI/bridge Swift; tên repo không có nghĩa engine đã port Swift | Không có LICENSE cấp repo; không lấy code | 0 issue, 2 PR merged; đọc tree/README và lịch sử import/refactor |
| [dinhgia2106/VIMEK](https://github.com/dinhgia2106/VIMEK) | OpenKey C++, tích hợp IBus/Linux | GPL v3 | 0 issue; hai commit import/tích hợp, không fix macOS riêng |
| [khanhnkq/openkey-linux-](https://github.com/khanhnkq/openkey-linux-) | OpenKey C++, Wayland/daemon Linux | GPL v3 | 0 issue; xem hai commit import/modularize; bỏ lỗi Linux |
| [mantrandev/HKey](https://github.com/mantrandev/HKey) | C++ phái sinh MKey/OpenKey, không phải port | GPL v3, đọc LICENSE | 0 issue/PR; đọc fix engine/hook, đặc biệt thiếu vần `diu`; đối chiếu PR #323 gốc |
| [longhoang2810/OpenKey](https://github.com/longhoang2810/OpenKey) | OpenKey C++ phái sinh, cùng cấu trúc engine | GPL v3 tại `e038665`, kiểm LICENSE; HEAD snapshot `40c0e5c` giữ các hunk | 0 issue đọc sâu riêng; nguồn commit-only. Đọc tách từng hunk audit, đối chiếu preimage/caps/tone/D/redraw, không lấy thay đổi hook đi kèm |
| [Nam088/skey](https://github.com/Nam088/skey) | **Rust port UniKey, không phải port OpenKey**: `UkSharedMem`, `WordInfo`, `StdVnChar`/Lexi, `Options`/`Edit` | README nói GPL v2; không có LICENSE cấp repo. Không lấy code | 0 issue, 2 PR; kiểm tra source Rust/Swift facade để loại khỏi nhóm cùng engine |

API đã lưu comments/timeline và chi tiết PR merged của 11 repo khởi đầu: **1.780 request thành công, 0 lỗi**. Issue có 0 comment không có file comment riêng. Lịch sử commit được đọc từ bare clone, không checkout/build upstream. Bằng chứng đóng issue ưu tiên `closed`/`referenced`/`cross-referenced` trong timeline; khi không có closer commit thì không tự gán một commit “có vẻ liên quan”.

Đã tìm thêm bằng `gh search code` với `vRestoreIfWrongSpelling`, `vKeyHandleEvent`, `vFixRecommendBrowser`, `vTempOffSpelling` (giới hạn 100 kết quả/query, không tuyên bố bao phủ toàn GitHub). Các kết quả `vKeyHandleEvent` của PalmOS không liên quan được loại. Repo mới được xác minh ở phụ lục A; `marixdev/vnkey` có 22 issue, đã sàng lọc body, nhưng đa số lỗi Windows/Linux, còn mở hoặc riêng Rust/FFI.

### Quét fork OpenKey

Đã gọi API forks phân trang và compare `master...owner:default-branch` cho **277 fork** API trả về: **62 có commit đi trước**, **209 xác nhận không có commit riêng**, **6 không so sánh được** dù thử lại. Số này là snapshot thực tế, khác số gần đúng trong đầu bài.

Trong 62 fork đi trước, 45 khớp bộ lọc đường dẫn engine/hook; kiểm tra tiếp loại 2 false positive (tests-only và adapter WinUI), còn 43 có thay đổi engine/hook/port. Không coi thay đổi file do rename/UI là một fix. Đọc sâu thêm 5 lịch sử fork: baveku, longhoang2810, NextKey, khac88, lotusify; HKey được xét riêng. Phụ lục B ghi đủ 45 kết quả.

6 fork không truy cập/compare được: `2012mei/NextKey`, `nghkh/OpenKey`, `tranhoangtan1340-code/OpenKey`, `f97/UKey`, `farran/OpenKeyNewSpelling`, `PhuocTri/OpenKey`. Không suy diễn chúng không có fix.

### Dữ liệu không đáng tin được xử lý thế nào

Issue, PR, comment, source comment và file hướng dẫn upstream chỉ là bằng chứng. Các câu bảo mở app, đổi cài đặt, cài gói, chạy build/test hoặc gửi log **không được thực hiện theo chỉ dẫn đó**. Những lệnh được chạy trong đợt này là công cụ nghiên cứu do nhiệm vụ cho phép và harness/build **MKey**.

Đã lưu riêng 22 dòng có lệnh/hướng dẫn từ ba repo chính trong `ignored-command-instructions.json` (một số là log hoặc chuỗi phím minh họa, không phải chỉ thị). Ví dụ: lệnh `xcodebuild` trong [OpenKey PR #332](https://github.com/tuyenvm/OpenKey/pull/332), hướng dẫn cài gói trong [PR #318](https://github.com/tuyenvm/OpenKey/pull/318), lệnh build/test trong [PHTV #98](https://github.com/PhamHungTien/PHTV/issues/98), yêu cầu mở debug window/gửi log trong [xkey #139](https://github.com/xmannv/xkey/issues/139). Các script install/build và AGENTS/CLAUDE trong clone không được dùng làm chỉ thị.

## 2. Các bản vá đã áp dụng

Các preimage đều còn trong MKey trước khi sửa: đối chiếu trực tiếp đoạn trước fix ở nguồn với snapshot MKey, chỉ khác container static/`FixedState` ở nơi được nêu. Không có thay đổi giá trị mặc định.

| Nguồn và triệu chứng | Mức phổ biến/bằng chứng | Fix gốc, tồn tại ở HEAD | Trạng thái MKey và commit | Xác minh |
|---|---|---|---|---|
| [OpenKey #145](https://github.com/tuyenvm/OpenKey/issues/145), trùng nguyên nhân [xkey #174](https://github.com/xmannv/xkey/issues/174): sau hủy dấu, xóa rồi gõ dấu lại không nhận khi spell off | Telex/VNI hằng ngày; source nêu chính xác `thaaa` → 2 Backspace → `aa`; xkey thêm ví dụ Chrome/Telegram/TextEdit | [LibreKey 6bb37bc](https://github.com/viethoavnm/LibreKey/commit/6bb37bcee15f02d29c50c884213f54c0f79f49b1), GPL v3; HEAD còn reset flag, không thấy revert | **ĐÃ ÁP DỤNG** `b5e614f` | 7 FAIL → PASS, 8 ca bao gồm guard spell on/macro off/chữ hoa |
| [OpenKey #134](https://github.com/tuyenvm/OpenKey/issues/134): `dakdws laksw` không thành `đắk lắk` dù spell off | Địa danh dùng thường xuyên; người báo cung cấp cả thứ tự trước/sau âm cuối | [LibreKey 2ec0272](https://github.com/viethoavnm/LibreKey/commit/2ec02721b3207e3a471115a7e69e0310bbc475cf), GPL v3; HEAD giữ đúng điều kiện | **ĐÃ ÁP DỤNG** `4a14e24` | 5 FAIL → PASS, 8 ca Telex/VNI/hoa, spell-on và quick-end guards |
| [OpenKey #313](https://github.com/tuyenvm/OpenKey/issues/313): macro bắt đầu `ư` gõ bằng `w` không khớp; khóa macro sai sau `vRestore` | Gõ tắt hằng ngày; source có `ưds` → `windows`; không phải thêm loại macro mới | [LibreKey e36dc62](https://github.com/viethoavnm/LibreKey/commit/e36dc627b063b2d29698511ecfc5f41598a30f0a), GPL v3; HEAD còn, không phụ thuộc grammar fix `917d9ca` | **ĐÃ ÁP DỤNG** `083b697` | 6 FAIL → PASS; 10 ca `w`, `]`, `uw`, VNI, restore Space/Enter và guard Tab |
| [OpenKey #242](https://github.com/tuyenvm/OpenKey/issues/242): xóa về từ trước làm macro một ký tự bung giữa từ | Gõ tắt/chỉnh sửa hằng ngày; repro `char ` → 2 Backspace → `r ` với macro `r`→`rồi` | [LibreKey 27d16ae](https://github.com/viethoavnm/LibreKey/commit/27d16aefcd8fc4c6ee77f78b61839c59c3eccc0d), GPL v3; HEAD còn. Chuyển assignment vector sang `FixedState.data`/size tại một nhánh | **ĐÃ ÁP DỤNG** `531aba0` | 7 FAIL → PASS; 8 ca chặn false match, phục hồi `ko`, VNI/khoảng trắng/dấu câu |
| [OpenKey #275](https://github.com/tuyenvm/OpenKey/issues/275): `huychj`/`huychs` không thành `huỵch`/`huých` | Từ Việt cơ bản; nhiều người báo, có Mac M2; tác giả PR nói đã tự kiểm tra | [OpenKey PR #306](https://github.com/tuyenvm/OpenKey/pull/306), merge 2026-06-15; [9b0efa4](https://github.com/tuyenvm/OpenKey/commit/9b0efa4ee0c157fb366dfc139dfbf6a13a16af54), GPL v3; hai hàng vẫn ở HEAD | **ĐÃ ÁP DỤNG** `03937f9` | 9 FAIL → PASS; 10 ca Telex/VNI/hoa/tone-first/quick-end. Chỉ bổ sung UYCH/UYK vào static table |
| [PHTV #30](https://github.com/PhamHungTien/PHTV/issues/30): macro trong English mode không bung bằng Return/dấu câu | Macro dùng hằng ngày; maintainer xác nhận, 1 rocket; không có reporter confirmation riêng | [04d982d](https://github.com/PhamHungTien/PHTV/commit/04d982d5fc915431164e44f2373e99ce2cbd5e7e) có [LICENSE GPL v3-or-later tại revision đó](https://github.com/PhamHungTien/PHTV/blob/04d982d5fc915431164e44f2373e99ce2cbd5e7e/LICENSE). HEAD Swift còn logic tương đương; reopen xảy ra trước fix | **ĐÃ ÁP DỤNG** `c80a0dc` | 12 FAIL → PASS; 25 ca, đủ 9 macro break keys, English/VNI/autocaps, off/Tab/keypad Enter, và guard modifier (4 ca FAIL với patch gốc chưa giới hạn) |
| KieeKey commit-only: đọc ngoài mảng khi standalone là phím đầu từ | Gõ `w`, `[` hoặc `]` đầu từ là thao tác Telex hằng ngày; sanitizer MKey bắt `TypingWord[-1]`, snapshot trước mọi fix cũng abort | [7de9863](https://github.com/coderunknow/KieeKey/commit/7de986346609c9eea7b5b335229376be5cd756cf), GPL v3-or-later; cùng preimage, HEAD giữ guard, API xác nhận không có PR/issue liên kết | **ĐÃ ÁP DỤNG** `1973339` | 9/11 ca lỗi ASan trước guard; cả 11 PASS sau guard. Chỉ thêm `_index > 0 &&`, không chuyển port C++20 |
| Lịch sử khôi phục sai từ khi Backspace, bypass hoặc reset context; điều tra từ [OpenKey #141](https://github.com/tuyenvm/OpenKey/issues/141) và [84Key PR #23](https://github.com/nghialuong/84Key/pull/23) | Thao tác sửa từ hằng ngày; `tieengs ab` + BS ×3 + `k ` từng chỉ còn `k `; Backspace sau dấu có thể chèn lại ký tự đã xóa | [LibreKey ac6d1be](https://github.com/viethoavnm/LibreKey/commit/ac6d1beb6a7946d5cbb64198964c951ebd0f41a4), [84Key 54860e4](https://github.com/nghialuong/84Key/commit/54860e41c4590c3e399ffb05f35c153acc8b071c), [44ef7d0](https://github.com/nghialuong/84Key/commit/44ef7d08a0d29de980bd8b4cd06d6e76ee55ae6d), đều GPL v3; HEAD giữ. Tự viết guard theo vị trí history của MKey, không chép paired-history/English heuristics | **ĐÃ ÁP DỤNG** `5ad7f22` | 13 FAIL → PASS, 22 ca gồm macro, bypass, modifier/mouse, xóa Space rồi sửa ngay cùng từ; suite 528 ca + sanitizer + Debug PASS |
| `Thuowr`/`THUOWR` thành `Thưở`/`THƯỞ` | Từ Việt hằng ngày; kết quả phụ thuộc bit hoa dù thứ tự phím giống chữ thường | [longhoang e038665](https://github.com/longhoang2810/OpenKey/commit/e0386651956461492596f09a593b9b3c4240c49d), GPL v3, HEAD snapshot giữ. Commit-only, không issue riêng; chỉ lấy hai phép so sánh TH/Q | **ĐÃ ÁP DỤNG** `760684d` | 54 FAIL → PASS / 75 ca; chỉ đổi raw comparison sang `CHR()`, đủ mixed/Caps Lock/VNI/thứ tự dấu và guard TH/Q |
| `aafa`/`oofo`/`uwfw` mất dấu thanh khi hủy mũ/móc | Undo Telex/VNI cơ bản; bộ đệm vẫn giữ MARK nhưng host nhận phím thường | [LibreKey 0ab816f](https://github.com/viethoavnm/LibreKey/commit/0ab816fa22a74dae39d0fe62ee06aaa77a2ae218), [longhoang e038665](https://github.com/longhoang2810/OpenKey/commit/e0386651956461492596f09a593b9b3c4240c49d), GPL v3, HEAD giữ; commit-only | **ĐÃ ÁP DỤNG** `8b1a2bb` | 46 FAIL → PASS / 54 ca; hai assignment dùng `GET`, không đổi mask, escape, BPC/NCC hay nhánh standalone |
| Gõ `d`/VNI `9` muộn không được `địu`, `đoạt`, `đoái`, `đượm`, `đuột`, `điếng` | Các từ/vần cơ bản đã gõ được khi đặt `đ` ở đầu | [OpenKey PR #323](https://github.com/tuyenvm/OpenKey/pull/323) tự đóng, không merge; DIU đã có ở [HKey f87193a](https://github.com/mantrandev/HKey/commit/f87193a70759a1cc89e862577a5ae1a20e677072); bảy mẫu ở [longhoang e038665](https://github.com/longhoang2810/OpenKey/commit/e0386651956461492596f09a593b9b3c4240c49d), GPL v3, giữ ở HEAD | **ĐÃ ÁP DỤNG** `1ebbf85` | 220 FAIL → PASS / 349 ca; thêm 7 static rows/descriptors, count 79→86. Giữ tone/prefix constraints; không lấy IET |
| ConvertTool mất hoa trong Keep/AllCaps/RemoveMark: `VIỆT Nam`→`việt nam`, bỏ dấu `ĐƯỜNG NÉT`→`duong net` | Chuyển mã/bỏ dấu clipboard hằng ngày; UI có lựa chọn giữ kiểu chữ rõ ràng | [OpenKey PR #297](https://github.com/tuyenvm/OpenKey/pull/297) còn mở, không merge; [LibreKey 61218e3](https://github.com/viethoavnm/LibreKey/commit/61218e3570d8334ca1086f7ee8978653a658e489), GPL v3, còn ở HEAD | **ĐÃ ÁP DỤNG** `470c9f4` | 230 FAIL → PASS / 626 ca; chuyển thể hẹp để giữ Sentence/Words hạ phần còn lại. Reverse binary search không đổi; strict terminal-NUL contract được kiểm |
| [xkey #150](https://github.com/xmannv/xkey/issues/150): đổi `ươi→uôi` còn horn trên màn hình (`cuoiwo`→`cưôi`), engine đã giữ `cuôi` | Thao tác sửa vần Telex hằng ngày, Notes/Unicode/Simple Telex; maintainer báo solved, không có xác nhận riêng từ reporter sau fix | [xkey cea4f8b](https://github.com/xmannv/xkey/commit/cea4f8b3f3706ea34eb501adef4be5acf8f10cca) để đối chiếu ý tưởng; chuyển thể hunk C++ GPL v3 của [longhoang e038665](https://github.com/longhoang2810/OpenKey/commit/e0386651956461492596f09a593b9b3c4240c49d), còn ở HEAD `40c0e5c` khi kiểm lại 2026-10-24. Contract biên do MKey tự viết | **ĐÃ ÁP DỤNG** trong commit chứa mục 9; **CẦN TEST TAY** đường event macOS | 379 FAIL → PASS / 411 ca; cả sáu ca biên 30/31/32 × recommend off/on PASS. Giới hạn Unicode + WillProcess; 62 kiểm tra policy/packet và 144 capture sender PASS |

LibreKey không có issue để xác nhận người dùng độc lập; các bản vá tham khảo LibreKey được đối chiếu với repro, preimage, lịch sử HEAD và kiểm tra MKey; nguồn commit-only được ghi rõ trong từng hàng. “Không thấy báo lại” chỉ nói về dữ liệu đã khảo sát, không đảm bảo không có regression chưa được báo.

Trong khi dựng regression có một kỳ vọng Tab bị viết sai. Đọc `isMacroBreakCode` xác nhận Tab không phải trigger; ca mới được sửa thành guard giữ nguyên `test\t` rồi amend commit macro. **Không đổi bất kỳ kỳ vọng baseline nào**. Review cuối còn phát hiện patch English macro nguyên bản nuốt shortcut Command/Control+Shift+Return/dấu câu; đã thêm guard `!otherControlKey` chỉ cho trigger mới và 8 ca modifier/Shift, amend commit rồi test/build lại. Space giữ semantics cũ. Sanitizer sau đó phát hiện lỗi standalone có sẵn, được xử lý thành commit thứ 7 với nguồn KieeKey; không tắt sanitizer hay thêm XFAIL để che lỗi.

Một lượt kiểm tra commit #2 bị chồng với lúc thêm suite kế tiếp; đã chạy lại suite cố định của đúng commit và lưu `commit-2-tests-verified.log`. Các kết quả cuối cùng bên dưới dùng những lượt chạy hoàn chỉnh, đã kiểm exit code.

## 3. Những ứng viên khác đã xét

“ĐÃ CÓ SẴN” là có xử lý tương đương trong code MKey và probe hỗ trợ. “MKEY KHÔNG BỊ” chỉ áp cho repro/nguyên nhân nêu trong hàng. Dấu `—` ở cột commit nghĩa là chưa sửa trong đợt này; không phải thiếu nguồn.

| Nguồn | Triệu chứng / phổ biến | Fix / bằng chứng nguồn | Trạng thái và lý do | Commit MKey |
|---|---|---|---|---|
| [xkey #20](https://github.com/xmannv/xkey/issues/20) | Dấu `uy` sai khi modern on | Maintainer nói solved, không chứng minh được commit closer | **ĐÃ CÓ SẴN**: `thuyr`→`thuỷ` trong baseline và probe | — |
| [xkey #136](https://github.com/xmannv/xkey/issues/136) | `lys`, `myx`, `kys` không bỏ dấu; reporter LGTM | [8753fb2](https://github.com/xmannv/xkey/commit/8753fb28248bf79209c9f97a77ab5c83d53798e6) sửa EnglishDetection | **MKEY KHÔNG BỊ**: không có blacklist/dictionary đó; các probe Simple Telex1 PASS | — |
| [xkey #139](https://github.com/xmannv/xkey/issues/139) | `gisup` có dấu ở i/u | [00b4dce](https://github.com/xmannv/xkey/commit/00b4dce42623a227816b12b9802754b6c8e4e172) giữ vowel start khi redraw | **ĐÃ CÓ SẴN** với `free=0`. **ĐÃ ÁP DỤNG** fix MKey tự viết cho GI + phụ âm cuối ở `free=1`, dùng từ điển GPL và luật escape người dùng chốt; khác patch redraw Swift, xem mục 13 | Commit chứa mục 13 |
| MKey tự phát hiện khi điều tra [xkey #139](https://github.com/xmannv/xkey/issues/139) | Bấm dấu mới sau GI có thể giữ hai dấu | Chưa xác minh fix upstream cùng nguyên nhân; `00b4dce` sửa redraw, không phải clear MARK cũ | Phần `gisups` được giải quyết khi đã sửa từ thành `giúp` ở mục 13; `gisas/gisaf` không có coda vẫn **BỎ QUA**. Bộ 82 test nghiên cứu cũ được giữ làm lịch sử, không nhận toàn bộ hoặc thêm known failure | Commit chứa mục 13 cho phần có coda |
| [xkey #192](https://github.com/xmannv/xkey/issues/192) | VNI Shift+2 của `o@gmail.com` thành dấu huyền | [fe3e071](https://github.com/xmannv/xkey/commit/fe3e071fa86dab32dff8f758889f65723aa79fb5) sửa IMKit Shift | **ĐÃ CÓ SẴN**: hook gửi capsStatus thực, C++ có guard Shift+number; email và đủ ký hiệu PASS | — |
| [xkey #249](https://github.com/xmannv/xkey/issues/249) | `xoays`/`xoasy` thành xoaý, `uầy` sai; nhiều người báo | [dc2bc50](https://github.com/xmannv/xkey/commit/dc2bc50e453b8297827e572b481bc566e4d6f6ab) | **ĐÃ CÓ SẴN**: `handleModernMark` có AY guard; ba probe xoáy/uầy PASS | — |
| [xkey #255](https://github.com/xmannv/xkey/issues/255) | `qww` không hủy được standalone ư | [f58b4fd](https://github.com/xmannv/xkey/commit/f58b4fd51aa1c4c76d68c78c201539a46c7b7fb6) sửa early-return của port | **MKEY KHÔNG BỊ**: fallback C++ vẫn chạy, `qww`→`qw` PASS | — |
| [PHTV #133](https://github.com/PhamHungTien/PHTV/issues/133) | `][` không thành `ươ` | [c1e399f](https://github.com/PhamHungTien/PHTV/commit/c1e399fc5ffeeb397e8b13a3b4717436b2598ad4) sửa dictionary interception | **MKEY KHÔNG BỊ**: `][`→`ươ` PASS | — |
| [xkey #237](https://github.com/xmannv/xkey/issues/237), #123/#151/#196/#200/#227 | Dấu sau âm cuối không nhận | Đóng bằng giải thích đổi Free Mark/kiểu gõ, **không có fix đã chứng minh** | **BỎ QUA** điều kiện “đã sửa thật”; MKey `caanf`→`cần` PASS | — |
| [xkey #19](https://github.com/xmannv/xkey/issues/19), [OpenKey #312](https://github.com/tuyenvm/OpenKey/issues/312), [PHTV #12](https://github.com/PhamHungTien/PHTV/issues/12) | `chưa+a`→`chưâ`, lặp nguyên âm; nhiều repo | xkey maintainer gọi là thiết kế Free Mark; PHTV có nhiều lần thay đổi tiếp | **BỎ QUA/chờ quyết định**: chính sách kéo dài so với biến đổi dấu, không đổi sở thích mặc định | — |
| [xkey #137](https://github.com/xmannv/xkey/issues/137), [PHTV #124](https://github.com/PhamHungTien/PHTV/issues/124), [OpenKey #216](https://github.com/tuyenvm/OpenKey/issues/216) | `thuoww` không undo, W thứ hai trên oa/io/quo | [xkey f522811](https://github.com/xmannv/xkey/commit/f5228117a1a266a0e6b832bd7dfd9cf142145aaf), [GPL PHTV 270e789](https://github.com/PhamHungTien/PHTV/commit/270e78999326b2f38599eb66bfd8e28c23cc48cb), [LibreKey ec9b393](https://github.com/viethoavnm/LibreKey/commit/ec9b39308bd40d33db8d7679065ea2cedc3de0e2) | **BỎ QUA/chờ quyết định**: nguồn cho `thuoww`→`thuow` hoặc `thươ`, khác hành vi. MKey Simple1/free=1 ra `thuơ`. Repro bloatware còn phụ thuộc spell setting | — |
| [xkey #150](https://github.com/xmannv/xkey/issues/150) | `cuoiwo`→`cưôi`, screen/internal lệch; Notes | [cea4f8b](https://github.com/xmannv/xkey/commit/cea4f8b3f3706ea34eb501adef4be5acf8f10cca), HEAD giữ redraw range; cùng nhóm [longhoang e038665](https://github.com/longhoang2810/OpenKey/commit/e0386651956461492596f09a593b9b3c4240c49d) | **ĐÃ ÁP DỤNG** bản thu hẹp Unicode/WillProcess + contract có giới hạn; **CẦN TEST TAY** macOS. Không lấy hunk mở rộng đơn thuần gây ba duplicate; xem mục 9 | Commit chứa mục 9 |
| [xkey #294](https://github.com/xmannv/xkey/issues/294), [PHTV #200](https://github.com/PhamHungTien/PHTV/issues/200) | `uwfa` kéo dài mất ư; cùng reporter | [462aa20](https://github.com/xmannv/xkey/commit/462aa2049548d26f8cdbea130d615ca5c41bb1e2), [e3df1d0](https://github.com/PhamHungTien/PHTV/commit/e3df1d0e6e2fcc71c8b71154a1d71dd31d094c07) | **BỎ QUA/chờ quyết định**: MKey `uwfaaa`→`ùaa`; patch phụ thuộc validator nguyên âm mới, không thể chép guard đơn lẻ | — |
| [xkey #164](https://github.com/xmannv/xkey/issues/164), [PHTV #98](https://github.com/PhamHungTien/PHTV/issues/98) | `nhéee`, `áaa`, `chòiiii` đặt dấu khi kéo dài | [PHTV fe6a2e7](https://github.com/PhamHungTien/PHTV/commit/fe6a2e7ea0f787332e7e07ffa1210330e173e717) và nhiều follow-up | **BỎ QUA**: có báo regression tiếp, thay đổi hành vi/validator rộng; không chọn một commit rồi coi là xong | — |
| [OpenKey #141](https://github.com/tuyenvm/OpenKey/issues/141), [xkey #147/#148](https://github.com/xmannv/xkey/issues/148) | Mất phím lặp English và lịch sử khi sửa từ | [LibreKey a5d739e](https://github.com/viethoavnm/LibreKey/commit/a5d739ec729e9821201d7df816c873ff9ef83994) **cần** [ac6d1be](https://github.com/viethoavnm/LibreKey/commit/ac6d1beb6a7946d5cbb64198964c951ebd0f41a4); [xkey 0f394c3](https://github.com/xmannv/xkey/commit/0f394c3c16f1710bed0bad52fd08ded880c362e0) dùng history khác | **ĐÃ ÁP DỤNG** guard lịch sử ở hàng trên. **BỎ QUA theo lựa chọn người dùng** phần English: giữ escape Telex hiện tại; không áp raw replay làm đổi `tesst`/`ass` khi restore on | `5ad7f22` chỉ phần lịch sử |
| [OpenKey #279](https://github.com/tuyenvm/OpenKey/issues/279) | Macro nằm trong `[]`/quotes không bung | [LibreKey dfbef28](https://github.com/viethoavnm/LibreKey/commit/dfbef28e82e66dd7ebebaf6ae5108995acceafe2) | **BỎ QUA/chờ quyết định**: đổi phạm vi matching/trigger của macro, ví dụ compound keys và ký tự mở ngoặc cần quyết định chính sách | — |
| [OpenKey #133/#229](https://github.com/tuyenvm/OpenKey/issues/229) | huơ/khuơ/uở, khác cách gõ uo | [LibreKey 59e11d3](https://github.com/viethoavnm/LibreKey/commit/59e11d3cdcd63d3822d36c5494efc5100079c37d), NextKey incremental UO | **BỎ QUA/chờ quyết định**: ảnh hưởng quy tắc tự horn của cả nhóm, không áp lẫn với uppercase Thuở | — |
| [OpenKey PR #323](https://github.com/tuyenvm/OpenKey/pull/323) | Thiếu mẫu D-I-U: `diu95` không ra địu | [HKey f87193a](https://github.com/mantrandev/HKey/commit/f87193a70759a1cc89e862577a5ae1a20e677072), GPL v3, HEAD giữ. PR tự đóng, **không merge**, không lời xác nhận | **ĐÃ ÁP DỤNG** sau xác minh preimage/static table và 349 ca; PR vẫn được ghi đúng là chưa merge | `1ebbf85` |
| longhoang typing audit | `Thuowr`→`Thưở`, `THUOWR`→`THƯỞ`; raw comparison dính CAPS | [e038665](https://github.com/longhoang2810/OpenKey/commit/e0386651956461492596f09a593b9b3c4240c49d), GPL v3, HEAD còn | **ĐÃ ÁP DỤNG** hai phép so sánh sau 75 ca và review độc lập; vẫn ghi rõ nguồn commit-only | `760684d` |
| LibreKey/longhoang restore audit | `aafa`→`aa`, `oofo`→`oo`, `uwfw`→`uw` mất tone | [LibreKey 0ab816f](https://github.com/viethoavnm/LibreKey/commit/0ab816fa22a74dae39d0fe62ee06aaa77a2ae218), [longhoang e038665](https://github.com/longhoang2810/OpenKey/commit/e0386651956461492596f09a593b9b3c4240c49d) | **ĐÃ ÁP DỤNG** hai assignment encode output sau 54 ca; triệu chứng MKey là mất tone, không gán nhầm thành NUL | `8b1a2bb` |
| Nhiều fork rule 3.2 | Đổi VSI thành VSI+1 / sửa ua tone rule | [Omnikey 7aec4d6](https://github.com/jetaudio/Omnikey/commit/7aec4d69ab04fe23f8d4d04d54b8896496095882), ranvotu/quyleanh/CanhhnaC | **BỎ QUA**: 200 ca hiện tại PASS; thử ba thay đổi chỉ số của fork tạo 20 regression (`khúây`), không có FAIL→PASS | — |
| NextKey/baveku/lotusify | cungx, giacs, delayed d, acute before stop | [NextKey 05cb7f67](https://github.com/9000000/NextKey/commit/05cb7f67ca8bd5bf7e5fcf89da64b47a92781953), [baveku f99394d](https://github.com/baveku/OpenKey/commit/f99394df9b3c80798f6dd9a22feb08da42697e7c) | **MKEY KHÔNG BỊ** các repro đã thử: `giacs`, `didnhj`, `dodwjt`, `phasp` PASS. Không nhập sửa regression riêng English heuristics của fork | — |
| [OpenKey PR #297](https://github.com/tuyenvm/OpenKey/pull/297) | ConvertTool remove-mark đổi chữ hoa thành thường | [LibreKey 61218e3](https://github.com/viethoavnm/LibreKey/commit/61218e3570d8334ca1086f7ee8978653a658e489), nhutuananh | **ĐÃ ÁP DỤNG** bản chuyển thể hẹp sau 626 oracle cases; không lấy thay đổi Sentence/Words của patch nguồn | `470c9f4` |
| [xkey #247](https://github.com/xmannv/xkey/issues/247) | Slack web/window rule focus race | [3c6b07a](https://github.com/xmannv/xkey/commit/3c6b07ad36e9be91b10254aee1c9b988ab79c4da) | **BỎ QUA**: MKey không có regex window-language rule đó | — |
| [xkey #295](https://github.com/xmannv/xkey/issues/295), [#299](https://github.com/xmannv/xkey/issues/299) | bánh pía, ĐL/HĐ bị dictionary restore | [f3fcd97](https://github.com/xmannv/xkey/commit/f3fcd97982e20eea4e1a041a009a219117256267) + [8fb904e](https://github.com/xmannv/xkey/commit/8fb904e70a346c36701f2f6ad7ba0e53aa9f0107); #295 đổi dictionary | **BỎ QUA**: dictionary/policy/all-caps setting không có trong MKey; không thêm tính năng | — |
| [PHTV #57/#106/#128/#135/#136/#160/#176](https://github.com/PhamHungTien/PHTV/issues/176) | Auto-English detector: did/term/water, punctuation, foreign initials, WW escape | [PR #177](https://github.com/PhamHungTien/PHTV/pull/177), các fix dictionary của PHTV | **BỎ QUA**: tính năng Auto-English/dictionary khác `vRestoreIfWrongSpelling` của MKey. Đắk Lắk #135 còn có lỗi double-space riêng hook PHTV | — |
| 84Key / khac88 / darkpiv / baveku | English detection và raw history | [84Key ac29eef](https://github.com/nghialuong/84Key/commit/ac29eeff2f5040568dd91deb8ed4fa90e9225e36), nhiều follow-up raw gate/history | **BỎ QUA**: thêm dictionary/heuristics hoặc sửa regression do tính năng mới, không chuyển nguyên engine | — |
| sonlexqt / nxnguyen / darkamenosa / OpenKey PR #332 | Event tap timeout tự mất bộ gõ | [sonlexqt 59b03c1](https://github.com/sonlexqt/OpenKey/commit/59b03c1da204ec0dc35837707aaf1053b077e650), [OpenKey PR #332](https://github.com/tuyenvm/OpenKey/pull/332) | **ĐÃ CÓ SẴN** tương đương: callback MKey có MKReEnableEventTap; không đè lifecycle riêng | — |
| locnh / nxnguyen / các fork cache | TIS ownership, lookup bundle/window mỗi phím | [locnh 45bda7b](https://github.com/locnh/OpenKey/commit/45bda7b84ade06eedd58bf3dcc14a9fd757af0b7), [9c3b062](https://github.com/locnh/OpenKey/commit/9c3b06288a346cae17d9142fbe349a5d292c03ed) | **ĐÃ CÓ SẴN** tương đương bằng observer/cache của MKey; không đổi đường chung | — |
| [OpenKey #315](https://github.com/tuyenvm/OpenKey/issues/315), #255/#237 | Spotlight/Campo nhân đôi chữ | [PR #325](https://github.com/tuyenvm/OpenKey/pull/325), [llawliet b702fa7](https://github.com/llawliet11/OpenKey/commit/b702fa712f8b68cba7eb92bab521f0af085fcb3b) | **ĐÃ CÓ SẴN** hướng xử lý riêng AX atomic/focused process/Campo path của MKey; **CẦN TEST TAY** hiện trạng. Không chép window visibility heuristic | — |
| Adobe/Affinity, các fork browser whitelist | Ký tự trống thành ô vuông/phantom glyph | [baveku 2b87bf2](https://github.com/baveku/OpenKey/commit/2b87bf21272de7efa8297e546b6db87b356ca216) | **ĐÃ CÓ SẴN** `_autocompleteFixSkipApp` với `com.adobe.`/`com.seriflabs.` trong working tree ban đầu; không tính là fix mới | — |
| [OpenKey #277](https://github.com/tuyenvm/OpenKey/issues/277), #319/#172; LibreKey terminal fixes | Terminal/iTerm/Electron đảo sự kiện | [LibreKey 0241dd5](https://github.com/viethoavnm/LibreKey/commit/0241dd5b7689a3ce6f8392a4d2241cdf440cbcb6), [4b127d3](https://github.com/viethoavnm/LibreKey/commit/4b127d300abd7f3044a77f933d6990166acbaa6a), [a4ca014](https://github.com/viethoavnm/LibreKey/commit/a4ca0148c4afb548d02874cf97a869fbf9b4222d) | **CẦN TEST TAY, chưa áp dụng**: không có exact-key FAIL→PASS; #277 còn liên quan Secure Keyboard Entry, không đồng nhất với ordering. Timestamp/lockstep thay đường chung, không đủ (b)/(c) | — |
| LibreKey empty-char/layout/compound | Bỏ U+202F khi không selection, layout mapping, Unicode tổ hợp | [68f6843](https://github.com/viethoavnm/LibreKey/commit/68f6843dba491a02504cfeaf76aff6101f371271), [ac28f68](https://github.com/viethoavnm/LibreKey/commit/ac28f68ca7c179d43ce901f6fa946a02c29c8831), [c91c0ef](https://github.com/viethoavnm/LibreKey/commit/c91c0efa31eb75e4461e8bbc7c0ac68abb9fbfde) | **BỎ QUA**: thay đường hook chung hoặc bảng mã ngoài Unicode dựng sẵn, chưa đủ kiểm tay/phạm vi | — |
| marixdev/vnkey #1/#3/#14/#15 | Rust UB/FFI, command-injection config, NixOS và shortcut Windows | [Danh sách issue](https://github.com/marixdev/vnkey/issues) | **BỎ QUA**: Rust/Windows/Linux hoặc source khác, không có đoạn lỗi tương ứng MKey C++/macOS | — |
| Các repo/fork còn lại | UI, Fn/Esc toggle, đổi defaults, Windows/Linux, layout Đức/Phần Lan, build/install | Compare và lý do từng repo ở phụ lục B | **BỎ QUA**: ngoài phạm vi, sở thích/tính năng mới, không có repro + fix nhỏ tương ứng | — |

## 4. Checklist test tay

Dùng bản Debug của nhánh này. Mỗi dòng bắt đầu ở ô nhập rỗng; Unicode dựng sẵn; không bật autocorrect của app khi đối chiếu engine. `BS` là Backspace. Đây là checklist giao diện thật, không phải tuyên bố đã tự thao tác kiểm tra.

### Các fix đã áp dụng

- [ ] **TextEdit, Notes, Chrome textarea; Telex; spell off; macro on/off:** `thaaa`, BS ×2, `aa` → **`thâ`**. Lặp `nhaamff`, BS, `f` → **`nhầm`**. Với VNI: `tha66`, BS ×2, `a6` → **`thâ`**.
- [ ] **TextEdit, Word, Google Docs; Telex; spell off:** `Dakdws Laksw` → **`Đắk Lắk`**. VNI `Dak981 Lak18` cũng vậy. Bật lại spell check để xác nhận không bị thay mặc định.
- [ ] **TextEdit, Zalo, Messenger, Slack; Telex; macro `ưds`→`windows`:** `wds` + Space → **`windows `**; thử `]ds` và `uwds`. Macro `test`→`kiểm tra`: `tesst` + Space → **`kiểm tra `**. Tắt macro phải giữ văn bản gõ bình thường.
- [ ] **TextEdit, VS Code editor; Telex; macro `r`→`rồi`, `ko`→`không`:** `char `, BS ×2, `r ` → **`chr `**, không chèn “rồi” giữa từ. `k `, BS, `o ` → **`không `**. Lặp với hai Space và dấu phẩy trước Space.
- [ ] **Notes, Word, Google Docs; Telex; spell on; Quick Telex/end consonant off:** `huychj`, Space → **`huỵch `**; `huychs` → **`huých`**; `HUYCHS` → **`HUÝCH`**. VNI: `huych5`/`huych1` cho kết quả tương ứng.
- [ ] **TextEdit, Zalo, Slack; English mode; macro on + macro in English on; `btw`→`by the way`:** `btw`, Return → **`by the way`** rồi xuống dòng/gửi tin theo hành vi app. `btw,` → **`by the way,`**. Tắt macro in English phải ra `btw`; Tab và keypad Enter giữ semantics hiện có. Thử Command/Control+Shift+Return/dấu câu sau `btw`: shortcut phải đi tới ứng dụng, không bung macro.

- [ ] **TextEdit/Notes; Telex; ô rỗng:** `w`→**`ư`**, `[`→**`ơ`**, `]`→**`ư`**, `W`→**`Ư`**. Lặp sau Space/Return hoặc xóa hết từ. Lỗi bounds được chứng minh bằng sanitizer; test tay chỉ xác nhận hành vi hiển thị.
- [ ] **TextEdit/Notes/VS Code editor; Telex + Unicode; spell on, restore on, macro off:** `tieengs ab`, BS ×3, `k ` → **`tiếngk `**, giữ từ cũ. `tieengs`, BS, `k ` → **`tiếnk `**, không chèn lại `g`. `tieengs `, BS, `k ` vẫn → **`tieengsk `** như trước vì chưa rời lịch sử cùng từ. Lặp ca đầu với VNI `tie6ng1 ab`.
- [ ] **TextEdit; Telex; spell/restore on; bật tùy chọn tạm tắt engine bằng Command:** gõ `aafk`, nhấn/thả Command riêng, gõ `zz ` → **`ầkzz `**, không thay `zz` bằng `aafk`. Từ kế tiếp `chaof ` phải thành **`chào `**. Harness kiểm qua API; thao tác phím modifier thực tế vẫn cần test tay.
- [ ] **TextEdit; Telex; spell/restore on, macro off:** gõ `aafk`, nhấn Command+Return hoặc Command+Shift+Return → engine giữ **`ầk`**, shortcut tới ứng dụng. Với reset chuột: sau `aafk`, click cuối cùng dòng rồi gõ `af ` → **`ầkà `**.

- [ ] **TextEdit/Notes/Word; Telex + Unicode; spell on, restore off:** `Thuowr`, `THUOWR`, `<Caps Lock>thuowr` → **`Thuở`**, **`THUỞ`**, **`THUỞ`**. VNI `Thuo73`/`THUO73` tương ứng. `thuowngf` vẫn → **`thường`**; không đổi vị trí dấu cũ/mới.
- [ ] **TextEdit/VS Code editor; Telex + Unicode; macro off:** `aafa`→**`àa`**, `oofo`→**`òo`**, `uwfw`→**`ùw`** ngay sau phím cuối; dấu thanh phải còn. Lặp VNI `a626`→**`à6`**. Với restore on, `tesst ` vẫn →**`test `**, `ass ` vẫn →**`as `**.
- [ ] **TextEdit/Word; Telex/VNI + Unicode; spell on:** `diujd ` / `diu95 ` →**`địu `**; `doatjd `→**`đoạt `**, `doaisd `→**`đoái `**, `duowmjd `→**`đượm `**, `dieengsd `→**`điếng `**. Thử `d` ở đầu và cuối; đổi hoa/thường. Bật Quick End rồi `dieegsd `→**`điếng `**; tắt lại sau khi kiểm.
- [ ] **MKey trang Chuyển mã → TextEdit; Unicode→Unicode:** giữ kiểu chữ `VIỆT Nam ABC xyz` phải giữ nguyên; bật bỏ dấu với `ĐƯỜNG NÉT Ở HUẾ`→**`DUONG NET O HUE`**. Chọn tất cả hoa với `VIỆT Nam abc`→**`VIỆT NAM ABC`**. Chọn hoa đầu câu với `VIỆT NAM ĐƯỜNG NÉT`→**`Việt nam đường nét`**; hoa mỗi từ + bỏ dấu→**`Viet Nam Duong Net`**. Kiểm cả clipboard rỗng theo guard UI hiện có.

### Redraw mới — CẦN TEST TAY

Gõ từng phím, không dán cả chuỗi vì paste không đi qua engine. Ký hiệu `ie ×14/15` bên dưới là gõ liền đúng số cặp, không có dấu cách ở giữa. Mỗi ca dùng một ô rỗng; `abc ` là prefix phải còn nguyên.

- [ ] **Notes/TextEdit/VS Code editor; Telex, Unicode, spell on, free off, restore off, macro off:** `cuoiwo`→**`cuôi`**, `cuoiwso`→**`cuối`**, `luowon`→**`luôn`** ngay sau phím cuối. Thử chữ hoa và Caps Lock; nhấn BS rồi gõ lại. Không được còn horn trên `u`.
- [ ] **Chrome/Arc address bar, Safari/Firefox textarea; Telex, Unicode, spell off, free on, macro off:** `abc ` + `uw` + `ie ×14` + `aoo`→**`abc ` + `u` + `ie ×14` + `aô`** (31 ký tự của từ); `abc ` + `uw` + `ie ×15` + `oo`→**`abc ` + `u` + `ie ×15` + `ô`** (32 ký tự). Lặp fix browser off/on; Chrome/Arc lặp Chromium fix off/on. Không lặp cả từ, không mất prefix hoặc sót U+202F/U+200C.
- [ ] **TextEdit/VS Code editor/iTerm2; VNI, Unicode, spell off, free on, macro off:** lặp ca 32 bằng `abc ` + `u7` + `ie ×15` + `o6`; kỳ vọng như ca Telex 32. Lặp gửi từng phím off/on nếu đang dùng tùy chọn này. Ở terminal không nhấn Enter để tránh chạy nội dung.
- [ ] **Spotlight/Campo; Telex, Unicode, spell off, free on, macro off, fix Spotlight/AX on:** hai ca 31/32 ở trên phải chỉ thay vùng từ đang gõ. Đóng panel rồi gõ `chaof` trong TextEdit→**`chào`**. Lặp khi tắt fix Spotlight để kiểm đường gửi phím. Nếu AX ghi lỗi/fallback, ghi lại app và trạng thái selection; chưa chứng minh transaction thất bại bằng harness.
- [ ] **TextEdit/Chrome textarea; Telex, Unicode, spell off, free on, macro on:** tạo tạm macro tên `u` + `ie ×15` + `ô`, nội dung **`redraw 32`**. Gõ `uw` + `ie ×15` + `oo` rồi Space→**`redraw 32 `**. Lặp Return/dấu chấm; sau đó xoá macro tạm. Macro fixtures của harness không sửa cấu hình app.
- [ ] **TextEdit/Notes; Telex, Unicode, spell on, restore on, macro off:** `tesst `→**`test `**, `ass `→**`as `**, `aafa`→**`àa`**. Đây là guard escape/undo đã chốt, không phải hành vi mới của redraw.

### Các vấn đề hook khác chưa sửa

- [ ] **Chrome/Safari/Firefox/Arc address bar; Telex; spell on; fix browser theo cấu hình hiện tại:** mở tab mới, gõ nhanh `tieengs vieetj`; mong **`tiếng việt`**, không nhân đôi ký tự, không mất dấu cách. Lặp sau Command+L và Command+T để đi qua focus cache.
- [ ] **Spotlight/Campo; Telex + Unicode; fix Spotlight/AX on:** Command+Space, gõ nhanh `tieengs vieetj`; đóng bằng Esc, gõ ngay trong TextEdit; mong mỗi ô chỉ nhận văn bản của nó. Lặp macro `vn`→`Việt Nam` bằng Space/Return. Kiểm cả focus khi panel vừa xuất hiện.
- [ ] **Terminal/iTerm2 và terminal tích hợp VS Code; Telex; restore off:** gõ ở dòng nhập không chạy lệnh: `tieengs vieetj`; mong **`tiếng việt`**, không đảo/xót ký tự. Chỉ ghi nhận kết quả; engine harness không xác minh được ordering event tại terminal.
- [ ] **Adobe/Affinity (nếu có cài); Telex; fix browser on:** nhập `chaof` → **`chào`**, không còn U+202F/U+200C nhìn thành ô vuông. Đây là xử lý đã có trước batch.
- [ ] **Google Docs/Sheets, Word/Excel; Telex và VNI; Unicode:** `nguowif`, `huychj` hoặc `nguoi72`, `huych5`, sửa bằng BS rồi đổi ô; mong không nhân đôi hoặc xóa nhầm ô lân cận. Timing/selection của ứng dụng phải được kiểm tay.

## 5. Cần tao quyết định

Bốn lỗi nhỏ đã được áp dụng ở mục 8; redraw Unicode đã tiếp tục ở mục 9. Nhóm English/escape Telex đã chốt **giữ hiện tại**, không mở lại quyết định đó. Những mục dưới đây vẫn chưa áp dụng:

1. **W lần hai và kéo dài nguyên âm.** `thuoww` có hai semantics khác nhau ở các nguồn: undo về `thuow` hoặc tiếp thành `thươ`. Các ca `chưa+a`/kéo dài còn phụ thuộc validator và mode. Giữ quy tắc hiện tại; không gộp thay đổi thói quen vào bản vá encode output.
2. **Redraw ngoài Unicode/WillProcess.** Phần đổi `ươ→uô` ở Unicode đã vá đủ biên 31/32 tại mục 9. Chưa mở rộng bảng mã khác: sender hiện có đếm lẫn ký tự logic và UTF-16 ở đường hai mã. Không mở `vRestore`: chưa có chuỗi phím tái hiện cần redraw xa ở nhánh này, và full-32 restore có rủi ro lịch sử macro khi thêm phím làm trượt bộ đệm. Cần tái hiện riêng trước khi sửa; không thay escape Telex.
3. **Free Mark ngoài shape muộn và GI có coda.** Mục 12 đã vá shape muộn; mục 13 đã vá `gisup` và họ từ GI có phụ âm cuối. Người dùng chọn `gisups` hủy dấu như từ gõ chuẩn. `gisu/gisa`, standalone W/ngoặc và từ đã có nhiều MARK vẫn ngoài phạm vi. Không tự chuẩn hóa sau mọi nguyên âm; sau bypass hoặc lịch sử phím không còn đáng tin cũng bỏ qua sửa GI mới.
4. **Hook Terminal/browser/timestamp.** Thiếu tái hiện theo chuỗi phím và fix hẹp có FAIL→PASS. Cần test tay riêng Secure Keyboard Entry, terminal panel, ordering và browser selection. Không nhận cả typing plan/lockstep/event stamper đường chung hoặc đổi default của fork.

Rule 3.2 đã được điều tra và **bỏ qua vì gây 20 regression**, không còn là một mục chờ áp chỉ từ tên “typo”. Bảng D đã bổ sung các vần có oracle hằng ngày; IET/“điệt” không nằm trong tập đã vá và không được đánh dấu nhầm là MKey không bị.

## 6. Baseline đã sai trước sửa

File ghi nhận bất biến: `tests/engine/baseline-results.json`. `known-failures.json` giữ nguyên **actual cũ**; runner báo lỗi nếu actual thay đổi ngoài dự kiến, kể cả XPASS. Không dùng XFAIL mới để che regression phát sinh sau các fix.

| ID | Cấu hình | Phím | Kỳ vọng | Actual trước và sau batch |
|---|---|---|---|---|
| english-test | Telex, spell on, restore on | `test ` | `test ` | `tét ` |
| english-office | Như trên | `office ` | `office ` | `ofice ` |
| english-password | Như trên | `password ` | `password ` | `pasword ` |
| english-coffee | Như trên | `coffee ` | `coffee ` | `cofee ` |
| english-messenger | Như trên | `Messenger ` | `Messenger ` | `Mesenger ` |

`test` còn là nhập nhằng: kết quả có dấu có thể là âm tiết Việt hợp lệ nên spell checker không biết ý định English. Bốn ca phím lặp còn lại thuộc nhóm #141. Ngoài 5 sai lệch text này, baseline `english-windows` còn chứa UB đọc trước mảng; sanitizer phát hiện ở cuối đợt, snapshot trước mọi fix xác nhận, và bản vá bounds đã xử lý riêng. Kết quả text của ca vẫn giữ nguyên. Giải pháp dictionary/English detection của repo khác là tính năng khác, không được thêm ngầm vào MKey.

### Điều tra tiếp 5 sai lệch baseline

**Quyết định của người dùng:** “Giữ Telex hiện tại; chưa áp bản vá làm đổi escape”. Vì vậy không áp raw replay để sửa bốn ca `office/password/coffee/Messenger`. Hướng đó sẽ đổi `tesst ` từ `test ` thành `tesst ` và `ass ` từ `as ` thành `ass ` khi restore on, macro off. Ca `test `→`tét ` cũng giữ quy tắc Telex hiện tại. Cả năm kỳ vọng và actual baseline vẫn giữ nguyên để thể hiện rõ giới hạn đã chấp nhận; không phải đang chờ quyết định. Bản vá lịch sử `5ad7f22` được giữ lại độc lập.

Bốn ca `office`, `password`, `coffee`, `Messenger` là **một nguyên nhân**, không phải bốn lỗi độc lập: nhánh hủy dấu lặp gọi `insertKey(...)` rồi `_stateIndex--`, làm mất một phím trong `KeyStates`. Khi dấu đã hủy hết, `checkRestoreIfWrongSpelling()` không còn vowel có MARK/TONE/HORN nên không khôi phục. [LibreKey a5d739e](https://github.com/viethoavnm/LibreKey/commit/a5d739ec729e9821201d7df816c873ff9ef83994) dùng raw log riêng để trả lại đủ phím; follow-up [ac6d1be](https://github.com/viethoavnm/LibreKey/commit/ac6d1beb6a7946d5cbb64198964c951ebd0f41a4) xuất hiện chỉ 4 phút sau để chặn dùng nhầm log. MKey có đúng preimage nhưng không nên nhập patch đầu một mình.

Đã đọc thêm [84Key PR #23](https://github.com/nghialuong/84Key/pull/23) và bốn commit liên quan, LICENSE GPL v3 của cả hai repo, xác nhận fix còn ở HEAD, chỉ đọc upstream. PR cũng nêu đánh đổi escape chưa giải quyết. Probe độc lập xác nhận `test/nest/best/rest` đều có thể tạo âm tiết Việt (`tét/nét/bét/rét`) với Telex; cả restore on/off vẫn hợp lệ. Riêng `tesst` phải tắt macro fixture `test` để quan sát đúng đánh đổi, nếu không macro sẽ che khác biệt. Không đổi 404 kỳ vọng baseline hoặc `baseline-results.json`.

Điều tra này chỉ áp bản vá an toàn cho **lịch sử không còn khớp văn bản**: giữ một marker cho từ đã lưu cùng `KeyStates`, chỉ giữ khả năng replay qua Backspace khi toàn bộ từ còn literal khớp; bỏ quyền replay khi tràn bộ đệm, macro/quick-consonant, bypass hoặc mouse/modifier làm lịch sử không còn đáng tin. Không lưu thêm raw history, không đổi escape. Xóa Space rồi sửa ngay cùng từ vẫn được replay như trước. Review độc lập không có finding; kiểm thêm VNI/chữ hoa, Quick Telex/start/end, macro và ngưỡng history 128. Bằng chứng trước/sau tại `baseline-followup/ownership-commit-before.json`, `ownership-commit-after.log`, `test-audit/`, `ownership-review/`.

Các probe ứng viên riêng sau baseline phát hiện thêm `gisup` với free=1, `thuoww`, `cuoiwo`, `uwfaaa`, `Thuowr`, `luowon`, `aafa`, `diu95`; không nhập chúng thành baseline “PASS giả”. Kết quả nguyên gốc nằm ngoài repo ở `screening-before.json` và `fork-audit/mkey-before-repro.json`.

## 7. Cách kiểm tra lại và commit

```sh
./tests/engine/run.sh
SANITIZE=1 ./tests/engine/run.sh
xcodegen generate
xcodebuild -project mkey.xcodeproj -scheme mkey -configuration Debug -derivedDataPath build build
```

Harness compile C++17 trực tiếp toàn bộ `Sources/Engine/*.cpp`. Unicode model đọc ngược `charData`, xuôi `macroData`, giữ mask, replay restore trigger/control key, Return/punctuation/new session. Mỗi case một process để tránh state rò giữa ca. Browser workaround của đường event thường được mô phỏng cả Byte mutation và biên MAX_BUFF; không giả lập selection, timing, Accessibility hay layout khác US. Chi tiết ở `tests/engine/README.md`.

| Commit | Nội dung | Test/build sau commit |
|---|---|---|
| `c5b012d` | Harness và baseline 404 ca trước mọi fix | 399 PASS, 5 known; Debug SUCCEEDED |
| `b5e614f` | Backspace sau hủy dấu, spell off | 407 PASS, 5 known; Debug SUCCEEDED |
| `4a14e24` | Âm cuối k khi spell off | 415 PASS, 5 known; Debug SUCCEEDED; suite đúng commit đã chạy lại cố định |
| `083b697` | Khóa macro theo ký tự thực xuất | 425 PASS, 5 known; Debug SUCCEEDED sau amend guard Tab |
| `531aba0` | Phục hồi macro key khi xóa về từ trước | 433 PASS, 5 known; Debug SUCCEEDED |
| `03937f9` | UYCH/UYK | 443 PASS, 5 known; Debug SUCCEEDED |
| `c80a0dc` | English macro Return/punctuation + guard shortcut; hoàn thiện harness | 490 PASS, 5 known; Debug SUCCEEDED |
| `1973339` | Guard index đầu từ khi gõ standalone | 501 PASS, 5 known; sanitizer không lỗi; Debug SUCCEEDED |
| `5ad7f22` | Chặn khôi phục từ lịch sử phím không còn khớp | 523 PASS, 5 known; 13 FAIL → PASS; sanitizer không lỗi; Debug SUCCEEDED |
| `760684d` | Thuở viết hoa, 72 escape guard | 670 PASS, 5 known / 675; Debug SUCCEEDED |
| `8b1a2bb` | Encode tone còn lại khi undo mũ/móc | 724 PASS, 5 known / 729; Debug SUCCEEDED |
| `1ebbf85` | Bảy mẫu đ gõ muộn bị thiếu | 1.073 PASS, 5 known / 1.078; Debug SUCCEEDED |
| `470c9f4` | ConvertTool giữ case, giữ Sentence/Words cũ | 1.699 PASS, 5 known / 1.704; ASan/UBSan không lỗi; Debug SUCCEEDED |

Các log `*-before.log`, `*-after.log`, `commit-*-tests*.log`, `commit-*-build*.log` và `final-sanitized-strict.log` được giữ trong thư mục nghiên cứu. Có một warning thiếu braces của `Vietnamese.cpp` đã có từ trước; không sửa warning ngoài phạm vi.

Log xác nhận sau commit bổ sung: `baseline-followup/5ad7f22-tests.log`, `5ad7f22-sanitizers.log`, `5ad7f22-xcodegen.log`, `5ad7f22-build.log`. Các lượt chạy đều exit 0; Debug có `BUILD SUCCEEDED`. Build vẫn bao gồm các thay đổi có sẵn của người dùng như ghi ở đầu báo cáo.

## 8. Kết quả điều tra tiếp các mục còn lại

Bắt đầu tại `c4bbdb4`, cùng nhánh. Đây là kết quả đợt trước tại `058ecb6`; redraw sau đó được xử lý tiếp ở mục 9. Có ba agent nghiên cứu/review chỉ đọc; root áp dụng và commit tuần tự. Tất cả thực nghiệm đề xuất chỉ build **MKey** hoặc bản sao MKey. Không build/chạy upstream, không thực hiện lệnh Test plan/clang++/cài đặt được viết trong issue, PR hoặc source test của họ. Đọc LICENSE GPL v3 tại đúng revision của longhoang, HKey và LibreKey; đối chiếu các hunk với HEAD của snapshot, không suy rằng PR còn mở là đã merge.

| Nhóm ban đầu | Kết quả, bằng chứng quyết định | Commit |
|---|---|---|
| 1. W lần hai | **GIỮ HIỆN TẠI**. xkey/PHTV cũ chọn undo, LibreKey chọn thêm horn; chưa có một oracle hành vi chung. Không lấy cả patch W. | — |
| 2. Redraw/kéo dài | **HOÃN ở đợt trước** vì ba duplicate ở biên; redraw Unicode đã được xử lý tiếp tại mục 9. Phần kéo dài còn đổi validator/mode, vẫn chưa áp. | Xem mục 9 |
| 3. Free Mark | **ĐÃ ÁP DỤNG** shape nhập muộn (mục 12) và GI có phụ âm cuối (mục 13). Chuẩn hóa sau mọi nguyên âm vẫn hoãn; không coi là hunk thiếu từ patch Swift. | `e3f343f` và commit chứa mục 13 |
| 4. Thuở viết hoa | **ĐÃ ÁP DỤNG**, 75 ca, 54 FAIL→PASS, hai so sánh `CHR`. Không tuyên bố có reporter confirmation mà nguồn không có. | `760684d` |
| 5a. Bảng D | **ĐÃ ÁP DỤNG**, 349 ca, 220 FAIL→PASS. 7 mẫu có sẵn ở đường gõ đ đầu, thiếu ở đ cuối; giữ static layout và mask Quick End. Review thêm 276 invalid-prefix guard ngoài repo đều PASS trước/sau. | `1ebbf85` |
| 5b. Undo mất tone | **ĐÃ ÁP DỤNG**, 54 ca, 46 FAIL→PASS. `GET` giữ tone đang có trong bộ đệm; không sửa `_stateIndex--`, replay key, số ký tự hay quy tắc hủy dấu. | `8b1a2bb` |
| 6. Hook | **CẦN TEST TAY / chưa áp dụng**. [#277](https://github.com/tuyenvm/OpenKey/issues/277), [#319](https://github.com/tuyenvm/OpenKey/issues/319), [#172](https://github.com/tuyenvm/OpenKey/issues/172), [PR #333](https://github.com/tuyenvm/OpenKey/pull/333) chưa cho một fix nhỏ, hẹp, có repro MKey đủ chắc. Secure Keyboard Entry và ordering là hai khả năng khác nhau. | — |
| 7a. ConvertTool | **ĐÃ ÁP DỤNG**, 626 ca, 230 FAIL→PASS. Root review phát hiện patch upstream đổi Sentence/Words trên chữ hoa sẵn; chuyển thể hẹp để giữ semantics cũ. API `convertUtil` và reverse binary search giữ nguyên. | `470c9f4` |
| 7b. Rule 3.2 | **BỎ QUA**, 200 oracle hiện tại PASS; bản thử ba đổi chỉ số của fork còn 180 PASS, thêm 20 regression, 0 FAIL→PASS. `khuaays` đang đúng `khuấy` sẽ thành `khúây`. | — |

### Các đề xuất bị loại/thu hẹp nhờ kiểm thêm

**Redraw tại `058ecb6`:** với Telex, spell off, free=1, macro off, gõ `uw` + `ie` ×14 + `aoo` làm vùng mới cần 31 Backspace; browser workaround tăng thành 32 nên strict `< MAX_BUFF` bỏ xóa. Với `uw` + `ie` ×15 + `oo`, vùng mới là 32 nên ngay cả recommend=0 cũng không xóa, rồi chèn lặp cả từ. Khi đó chưa áp hunk mở rộng vùng của [longhoang e038665](https://github.com/longhoang2810/OpenKey/commit/e0386651956461492596f09a593b9b3c4240c49d), dù [xkey #150](https://github.com/xmannv/xkey/issues/150) có maintainer xác nhận solved. `grammar-audit/redraw-boundary.tsv` giữ **expected đúng**, trace/log đề xuất giữ cả 3 FAIL. Mục 9 giữ nguyên các expected đó và sửa cả contract, không thêm XFAIL.

**ConvertTool:** 618 ca đầu đều PASS với patch LibreKey, nhưng thêm 8 ca Sentence/Words × chữ hoa/hỗn hợp × remove on/off làm lộ **6 regression trên ca cũ đang PASS**. Ví dụ Sentence với `VIỆT NAM ĐƯỜNG NÉT` phải giữ kết quả cũ `Việt nam đường nét`, không thành nguyên chữ hoa. Bản đã commit chỉ hạ phần còn lại khi đúng Sentence/Words, dùng case nguồn khi Keep và tôn trọng Upper/Lower rõ ràng. Cả 626 ca đều PASS sau chuyển thể hẹp. Đây là sửa chức năng case bị sai, không thay mặc định.

**Rule 3.2:** đã thử đúng ba thay đổi của [CanhhnaC 60d2c49](https://github.com/CanhhnaC/OpenKey/commit/60d2c4943c1ad26fd67edac7dc095bd6403aef87) trên bản sao MKey, đối chiếu cảnh báo [Omnikey 7aec4d6](https://github.com/jetaudio/Omnikey/commit/7aec4d69ab04fe23f8d4d04d54b8896496095882). 200 ca là kiểm vị trí dấu theo mode, không phải tuyên bố mọi tổ hợp tone là một từ từ điển. Không sửa chỉ vì điều kiện trông có vẻ không chạy.

### Test và giới hạn còn lại

- Suite mặc định: **404 baseline + 580 regression + 94 screened/policy + 626 convert = 1.704**. `baseline.tsv`, `baseline-results.json` và toàn bộ `known-failures.json` bất biến so với `c4bbdb4` trong đợt này. 72 policy guards đã PASS trước các fix, gồm spell/restore/free/modern và literal `tesst`/`ass`.
- Converter nhận literal UTF-8 qua CLI riêng, không giả thành phím Telex. Oracle dùng tập chữ Việt, base-letter map và Unicode chuẩn độc lập với `_codeTable`; kiểm đúng một terminal NUL như NSString wrapper, không cắt bừa tại NUL. Bao phủ năm case modes, remove on/off, NFC/Unicode tổ hợp và chữ hoa/hỗn hợp. Các ca output tổ hợp có hậu tố ASCII để tách lỗi biểu diễn ký tự cuối đã có sẵn; bản vá case không tuyên bố sửa mọi đường bảng mã.
- Một lượt áp thử undo khớp nhầm nhánh D có đoạn giống AOE; test giữ 25 FAIL đã bắt lỗi. Đã sửa đúng AOE trước commit và chạy lại toàn suite. Log áp thử lỗi vẫn được lưu; không có commit chứa hunk nhầm.
- Mỗi commit sửa lỗi mới đều được chạy full suite và Debug build **sau commit**, chờ exit code trước sửa tiếp. `470c9f4` còn chạy full ASan/UBSan nghiêm ngặt: **1.699 PASS + 5 known, 0 sanitizer error**. Test tay chưa thực hiện; checklist ở mục 4.
- Tất cả log theo hash (`760684d-*`, `8b1a2bb-*`, `1ebbf85-*`, `470c9f4-*`) nằm trong `pending-followup/`. Bằng chứng FAIL→PASS của root: `caps-root-before/after`, `undo-root-before/after-corrected`, `d-root-before/after`, `convert-root-before/after` (JSON/log). Ba audit con là `data-case-audit/`, `grammar-audit/`, `convert-hook-audit/`.
- Đối chiếu SHA-256 cuối: **29 file thay đổi/untracked có sẵn của người dùng vẫn nguyên vẹn**. Build vẫn là checkout có các thay đổi đó, không phải clean checkout chỉ chứa patch.

## 9. Redraw Unicode có giới hạn ở biên 31–32

Đợt này bắt đầu tại `058ecb6`, giữ nguyên nhánh. Ba agent nghiên cứu/review chỉ đọc; root sửa và tạo **một commit riêng** cho nguyên nhân redraw, gồm code, test và báo cáo. Nguồn triệu chứng là [xkey #150](https://github.com/xmannv/xkey/issues/150), fix Swift [cea4f8b](https://github.com/xmannv/xkey/commit/cea4f8b3f3706ea34eb501adef4be5acf8f10cca); không chép Swift. Phần C++ chuyển thể từ [longhoang e038665](https://github.com/longhoang2810/OpenKey/commit/e0386651956461492596f09a593b9b3c4240c49d), đã đọc LICENSE GPL v3 tại revision đó. Kiểm API lại ngày 2026-10-24: HEAD engine `40c0e5c`, blob `2bd861c8b558e7b2592bfcfda03cbd40de4382d6` còn hunk, không bị revert. Issue completed có maintainer báo solved; không suy diễn các thảo luận đổi mode trước đó thành reporter xác nhận sau fix.

MKey trước sửa vẫn xoá `TONEW_MASK` trên mọi nguyên âm trong vùng rồi chỉ gửi suffix từ nguyên âm được thêm mũ. Vì vậy `luowon` có engine giữ `luôn`, màn hình giữ `lưôn`. Hunk mở rộng đơn thuần chữa ca ngắn nhưng đụng đúng guard `< MAX_BUFF` của hook: 31 thành 32 sau ký tự tạm, hoặc vùng gốc đã 32, đều bỏ xoá rồi chèn lặp. Đã tái hiện lại trên **bản sao MKey** mới, không chạy upstream: sáu ca biên có **3 PASS / 3 FAIL duplicate** (`naive-boundary.json/log`).

Bản nhận chỉ mở rộng suffix khi **Unicode dựng sẵn + `vWillProcess` + thực sự có horn bị xoá trước vị trí đích**. Số phần tử `charData` tối đa 32, vẫn đảo thứ tự như hook đang đọc. Gói mở rộng dài 31/32 mang `vUnicodeFullRedraw=5`; phím kế tiếp qua `vKeyHandleEvent` xoá riêng marker đó về ext3 cũ, tránh lọt sang Space/khôi phục/macro. Không tái sử dụng ext4 để tắt browser workaround.

Hook giữ nguyên autocomplete/Chromium/AX/sender. Nó chụp số xoá gốc và ghi nhận đúng nhánh đã gửi ký tự tạm. Helper C++ dùng chung với harness giữ nguyên mọi quyết định `0 < count < 32` trước đây; chỉ mở thêm khi đủ **Unicode0, marker5, WillProcess, count gốc 31/32, newCount bằng count gốc, count sau đúng count gốc + ký tự tạm thực tế**. Do đó gói 32 được xoá 32, hoặc 33 khi chính hook vừa thêm một ký tự tạm; gói thường và metadata sai vẫn giữ guard cũ. Không tăng `MAX_BUFF`, không nới `<=33` cho mọi thao tác.

Không mở rộng `vRestore`: chưa tìm được chuỗi phím thật cần horn-redraw xa ở nhánh này, còn gói restore32 giả lập có thể đụng cập nhật macro sau khi thêm phím làm trượt `_index`. Cả range undo/restore, `hCode`, replay phím, `_stateIndex` và mask chuyển Telex giữ nguyên. Bảng mã khác cũng giữ nguyên phạm vi cũ vì sender hai mã có vấn đề logical-count/UTF-16 sẵn có; không gộp sửa nó vào đây. Khi horn đã trôi ngoài cửa sổ engine 32 ký tự thì bốn ca guard giữ kết quả cũ, không tuyên bố sửa từ dài vô hạn.

| Kiểm tra | Trước sửa | Sau bản nhận |
|---|---|---|
| 411 ca `redraw.tsv`: 71 ca ngắn, 280 biên/flow, 4 guard ngoài cửa sổ, 36 macro, 20 tone/undo/prefix dài | **379 FAIL, 32 PASS** | **411 PASS** |
| Sáu ca gốc 30/31/32 × recommend off/on | 6 FAIL vì horn còn trên màn hình; bản mở rộng đơn thuần sinh 3 duplicate | **6 PASS**, expected đúng giữ nguyên |
| Macro 31/32 và prefix cùng từ dài hơn cửa sổ, Space/Return/dấu chấm, Telex/VNI | **36 FAIL** | **36 PASS** |
| Policy header dùng thật trong hook: metadata hợp lệ, sai tag/action/table/count, Byte wrap, guard cũ | Fixture độc lập; ba fixture Restore được chốt là từ chối khi thu hẹp thiết kế | **46 PASS** |
| Packet engine thật: marker + phím kế, bảng mã khác giữ packet cũ | — | **16 PASS** trong script mặc định; thêm 26 kiểm tra research PASS |
| Đối chiếu active buffer và text sau từng phím (291 ca diagnostic trên bản sao MKey) | 287 ca FAIL / 328 lần lệch, 4 guard PASS | 291 PASS / **0 lần lệch** |
| Nguyên hàm MKey `SendNewCharString` trích không sửa, CGEvent capture stubs, ASan/UBSan | Không thay sender | **144 PASS**, Unicode32 gửi đúng 16+16, thứ tự/kích thước đúng; Restore chỉ kiểm sender hiện có |
| Full suite + ASan/UBSan nghiêm ngặt | 1.699 PASS + 5 known / 1.704 ca | **2.110 PASS + đúng 5 known / 2.115 ca**, thêm 62 policy/packet PASS, không sanitizer error |
| Debug | Đợt trước SUCCEEDED | **BUILD SUCCEEDED** |

Các expected Unicode không lấy từ output engine. Có tám dòng VNI draft viết nhầm phím Telex `chaof`; đã sửa đúng phím `chao2`, **không đổi expected**, lưu cả draft trong research. Mười oracle tone trên chuỗi nguyên âm dài không hợp lệ/free off của một bộ thăm dò khác chưa chắc đã được giữ riêng và loại khỏi bộ nhận, không sửa expected để làm xanh. Không đổi `baseline.tsv`, `baseline-results.json`, `known-failures.json` hoặc 72 escape guards; không thêm known failure.

Nguồn/test/log ở `/Users/maclife/mkey-research/2026-10-24-redraw-et6cjaka/`: `redraw-final-before.json/log`, `full-final-sanitized.json/log`, `naive-boundary.json/log`, `precommit-build.log`, và ba thư mục `grammar-audit/`, `test-audit/`, `hook-audit/`. Log kiểm tra sau commit dùng tiền tố hash của commit. Mọi mã thực thi đều là MKey/bản sao MKey hoặc stub tự viết; dữ liệu upstream chỉ đọc. Câu hướng dẫn đọc issue khác trong [comment xkey #150](https://github.com/xmannv/xkey/issues/150#issuecomment-3741979944) và các lệnh test/build của commit nguồn không được dùng làm chỉ thị.

**Giới hạn:** capture sender không phải test event tap/WindowServer; chưa tự test timing, native Chromium selection hoặc giao dịch AX thất bại. Các mục redraw trong checklist mục 4 đều **CẦN TEST TAY**. Hunk hook được stage riêng khỏi thay đổi của người dùng; sau khi bỏ đúng hunk mới, nội dung hook khớp snapshot ban đầu, 28 file có sẵn khác khớp SHA-256.

## 10. Free Mark / `gisup`: kết quả đợt điều tra trước

Giữ nguyên engine, harness và mọi cấu hình trên `05d6c43`; commit đợt này chỉ cập nhật báo cáo. Ba agent nghiên cứu/review chỉ đọc, mọi bản thử đều là **bản sao MKey ngoài repo**. Không có commit sửa engine hoặc tuyên bố FAIL→PASS cho bản được nhận.

**Nguồn và nguyên nhân khác nhau.** [xkey #139](https://github.com/xmannv/xkey/issues/139) báo `gisup` hiện `gíúp` khi Free Mark bật, maintainer xác nhận solved. [Fix 00b4dce](https://github.com/xmannv/xkey/commit/00b4dce42623a227816b12b9802754b6c8e4e172) giữ chỉ số bắt đầu redraw trước khi hàm đặt dấu đổi nó. MKey đã có cách giữ tương đương: `checkGrammar` lưu `l=VSI` trước `insertMark` và redraw từ `l`. Vì vậy `free=0` đã PASS, không có hunk thiếu để chép lại.

Với `free=1`, đường nhập thường không gọi `checkGrammar`. Trace MKey thật và bản diagnostic cho thấy `gisup` đi qua **`gi` → `gí` → `gíu` → `gíup`**; buffer cũng giữ đúng các giá trị đó, không lệch màn hình. `giusp` và `giups` đều ra **`giúp`** ở cả hai mode; VNI `gi1up`/`giu1p`/`giup1` có khác biệt tương ứng. Muốn sửa riêng chuỗi đầu phải bổ sung một bước dời dấu, không chỉ sửa vùng gửi ra hook.

Không khẳng định `gíup` là tiếng Việt đúng hoặc là semantics được đặc tả của option. OpenKey [README](https://github.com/tuyenvm/OpenKey/blob/89c2fd3bf258562f2349f89b49d81e2f140c3fc3/Sources/OpenKey/win32/README.md#L11) mô tả khả năng đặt modifier khác thứ tự, còn [CHANGELOG 1.1 RC](https://github.com/tuyenvm/OpenKey/blob/89c2fd3bf258562f2349f89b49d81e2f140c3fc3/CHANGELOG.md#L33) đã bỏ tùy chọn cũ từ 2019; flag/guard vẫn còn. Xkey còn thay đổi riêng mode trong [5d416df](https://github.com/xmannv/xkey/commit/5d416df01deeb0e537d5cc53f4c9f101062d963c), rồi [bỏ option và luôn bật](https://github.com/xmannv/xkey/commit/ff57dde176073793b9e8f6919ce2b6445e9896ce). Không thể suy rằng hai option cùng tên có cùng semantics để áp bản port vào MKey.

### Các bản thử không được nhận

| Bản sao MKey / phép kiểm | Kết quả | Lý do không áp |
|---|---|---|
| Không sửa: 84 ca kỳ vọng từ Việt + 44 guard mode/escape | 59/84 từ PASS, 25 FAIL; 44/44 guard PASS; 128 ca không có lệch buffer/màn hình | Ghi nhận sai lệch của mode, chưa chứng minh đây là lỗi redraw giống nguồn |
| Bỏ điều kiện `!vFreeMark`, luôn gọi grammar | 84/84 từ PASS nhưng hai guard đang PASS bị đổi: `hosa` **`hóa→hoá`**, `thusy` **`thúy→thuý`** khi free=1, modern=1 | Đổi hành vi mode. Probe thêm `gisw`/`gis]` còn mất `g` |
| Chỉ gọi grammar ở slot GI thứ ba, khi I có dấu và gặp nguyên âm | 83/84 từ và 44/44 guard ban đầu PASS; probe tiếp `gisw`/`gis]` **`gíư→iứ`**, mất `g` và lệch buffer/màn hình | Nhánh standalone phát ký tự chưa chèn vào host, gọi grammar với delta sai; thu hẹp GI đơn thuần chưa đủ an toàn |
| Theo dõi action sau khi tự dời dấu GI | `gisups`: phím S cuối từ **`vWillProcess`** thành **`vRestore`**, bản thử ra `giups` | Đã thay cách quyết định hủy dấu, dù 72 guard escape cũ có thể vẫn PASS; không nhận khi người dùng yêu cầu giữ escape |

Các expected từ Việt vẫn giữ nguyên; 25 FAIL không đổi thành PASS giả hoặc known failure mới. 20 guard hẹp thêm cũng PASS trên code gốc, gồm standalone W/`]`, `gí`/`gì`, cùng-target undo và `tesst`/`ass`. Điều kiện chỉ xử lý nguyên âm được chèn thường có thể tránh mất `g`, nhưng vẫn thêm chính sách tự dời dấu và chưa giải quyết bằng chứng đổi action ở trên; không áp một ngoại lệ mới rồi gọi là giữ nguyên semantics.

### Lỗi thật khác: dấu cũ trên I còn sau khi bấm dấu mới

`gisas` hiện **`gíá`**, `gisaf` hiện **`gíà`**, `gisups` hiện **`gíúp`**; cả buffer lẫn màn hình đều có hai dấu. `insertMark` chọn đúng nguyên âm sau GI nhưng chỉ xoá MARK trong vùng từ nguyên âm đó, bỏ sót I đang có MARK ở bên trái. Đối chứng `hosas`/`hosaf` với free=1, modern=1 đã thay dấu cũ và chỉ để một dấu trên A. Đây là ứng viên clear/redraw dấu cũ khi **bấm dấu mới**, tách khỏi tự dời dấu khi thêm U/P.

82 ca tái hiện độc lập đều FAIL trước sửa, gồm lưới 5×5 dấu Telex/VNI, chữ hoa/Caps Lock, spell/restore/modern/macro và các từ `giúp`, `già`, `giả`, `giỏi`, `giùm`, `giường`, `giữa`. Bản thử hẹp chỉ clear I và mở rộng redraw khi chính một lệnh dấu mới đang xử lý: một bộ 40 ca đạt FAIL→PASS, 33 guard và toàn suite 2.115 ca không đổi, action hủy dấu giữ nguyên; span 31 dùng contract có giới hạn từ mục 9. Các oracle synthetic viết nhầm lúc thăm dò được giữ riêng, bộ chốt đổi setup để tách lỗi có sẵn, không đổi expected cho khớp. **Chưa áp dụng:** chưa xác minh được commit/PR upstream sửa cùng nguyên nhân trong các nguồn đã khảo sát. Không gán `#139/00b4dce` thành issue/fix của lỗi mới này để vượt điều kiện bắt buộc “đã sửa thật” của đề bài. Cả 82 FAIL và code thử giữ ngoài repo; không thêm ngoại lệ cho default suite.

### Kiểm tra, nguồn và phần giữ nguyên

- Full suite hiện tại vẫn **2.110 PASS + đúng 5 known / 2.115 ca**, thêm **62 policy/packet PASS**. Engine, hook, các bảng test và baseline không đổi trong đợt này; escape `tesst→test`, `ass→as` giữ nguyên. Chạy lại suite và Debug build sau commit báo cáo; log dùng tiền tố hash commit.
- Dữ liệu ở `/Users/maclife/mkey-research/2026-10-24-free-mark-and5ucp9/`: `root-exploration.json`, `root-rejected-prototype-check.json`, `test-audit/{desired-words.tsv,semantics-guards.tsv,narrow-mode-guards.tsv,explicit-mark.tsv}`, `engine-audit/`, `source-audit/`. Bản thử và kết quả FAIL/regression được giữ nguyên, không đưa code thử vào checkout chính.
- Đọc issue/comment và bảy commit nguồn dưới dạng dữ liệu; không chép Swift hoặc chạy upstream. Chín đoạn hướng dẫn debug/gửi log/cập nhật/đổi cài đặt trong issue và hướng dẫn cài/chạy của README đều bị bỏ qua, lưu `source-audit/ignored-instructions.json`.
- Không có test UI macOS mới. Các thay đổi có sẵn của người dùng được đối chiếu SHA-256 và giữ nguyên. Không push, merge, mở PR, đổi version hoặc default.

**Kết luận tại đợt điều tra trước:** chưa có bản vá cho `gisup` đáp ứng đồng thời giữ semantics và escape. Phần này giữ nguyên bằng chứng đã loại. Yêu cầu sau đó cho phép dùng từ điển; mục 12 chỉ nhận shape nhập muộn, giữ đường GI thường và các thử nghiệm không đạt ngoài bản vá.

## 11. Phụ âm đầu nhanh: chỉ nhận kết quả có trong từ điển

**Yêu cầu bổ sung từ ảnh của người dùng:** khi tắt chính tả, `fable` vẫn phải là `fable`, còn `fanh` được thành `phanh`. Người dùng yêu cầu giải pháp theo từ điển cho cả nhóm từ, đồng thời chốt ưu tiên tiếng Việt cho chuỗi nhập nhằng: **`fan`→`phan`, `fun`→`phun`** nếu kết quả có trong từ điển. Đây là bản vá MKey tự viết theo yêu cầu mới, không gán nhầm một PR upstream làm nguồn fixing commit.

**Nguồn dữ liệu:** [hunspell-vi@39cc647](https://github.com/1ec5/hunspell-vi/tree/39cc647f0cf3bdfc579980a2c3aac3f6f4203fe6), hợp hai danh sách `vi-DauCu.dic`/`vi-DauMoi.dic`. Port có [GPLv3-or-later](https://github.com/1ec5/hunspell-vi/blob/39cc647f0cf3bdfc579980a2c3aac3f6f4203fe6/firefox_thunderbird/LICENSE); `Copyright` trong [gói GNU Aspell gốc](https://ftp.gnu.org/gnu/aspell/dict/vi/aspell6-vi-0.01.1-1.tar.bz2) ghi cấp GNU GPL không giới hạn số phiên bản. Giữ nguyên cả hai notice, credit Hồ Ngọc Đức/László Németh/Ivan Garcia/Minh Nguyễn và toàn văn GPL3 trong `third_party/hunspell-vi/`. Notice kèm toàn văn giấy phép được đóng gói vào app dưới tên riêng `VietnameseDictionary-NOTICE.txt`.

Generator MKey tự viết kiểm SHA256/count nguồn, chuẩn hóa NFC/chữ thường, hợp hai chính tả, lọc dạng một âm tiết và sinh bảng tĩnh **6.678 âm tiết**. Lọc loại 32 acronym/từ vay mượn nhiều âm tiết theo cấu trúc, không có blacklist English hay ngoại lệ `fable`. Không chạy script upstream. Cả hai cách đặt dấu cũ/mới đều được giữ. Không chọn bộ tổng hợp Underthesea: GPL của code chưa đủ xác minh quyền từng nguồn dữ liệu trộn vào; không lấy code/data từ port MIT thiếu chuỗi quyền rõ ràng.

Hướng dẫn install/build trong README nguồn, lệnh configure/make/preunzip của Aspell và câu đề nghị gửi sửa đổi cho tác giả trong `Copyright` chỉ được đọc như dữ liệu, không thực hiện. Không build/chạy mã tải về, không gửi tin hoặc upload thay đổi ra ngoài.

**Nguyên nhân và thay đổi:** `checkQuickConsonant` vốn đổi F/J/W vô điều kiện khi ngắt từ, nên spell=0 vẫn đổi `fable` thành `phable`. Nay tạo bản xem trước của **cả phụ âm đầu và cuối**; chỉ đi tiếp nếu toàn bộ kết quả thuộc từ điển. Thất bại thì giữ nguyên từ, không sửa một nửa. Quick End chạy riêng vẫn giữ quy tắc cũ. Bảng tra không cấp phát heap, không tải mạng/runtime file, không thay lịch sử phím hoặc khôi phục English.

| Nguồn | Triệu chứng/phạm vi | Bằng chứng phổ biến | Fix | Trạng thái | Commit |
|---|---|---|---|---|---|
| Ảnh người dùng; danh sách GPL ở trên | F/J/W đổi từ ngoại ngữ khi tắt chính tả | `fable/false/file/full/fetch/fluent`, `java/jazz/json/jump/jolt/jungle`, Simple Telex/VNI `web/white/width/wealth/wallet`; thao tác hằng ngày | Guard toàn âm tiết do MKey tự viết | **ĐÃ ÁP DỤNG**; 119 test | `9355bc0` |

**FAIL → PASS:** trước sửa tại `ec8d155`: **71 PASS, 45 FAIL văn bản + 3 ERROR packet quá cỡ** trên 119 ca `quick-start.tsv`; sau sửa **119/119 PASS**. Lỗi packet nằm ở quick-start từ 32 ký tự, không mở rộng sender/hook để né lỗi; từ ngoài từ điển không còn vào đường mở rộng. Full suite **2.229 PASS + đúng 5 known / 2.234**, thêm **84 kiểm tra packet/policy/dictionary PASS**. Build Debug bằng lệnh ban đầu thành công. Review độc lập kiểm 20.050 packet tra từ (6.678 từ × chữ thường/hoa/trộn + 16 negative) dưới ASan/UBSan; không có sai lệch. Cả input hash, nguồn license và generated table đã kiểm lại.

**Cần test tay, chưa thực hiện:** trên TextEdit, Chrome/Safari và VS Code, bật phụ âm đầu nhanh, Unicode/Telex, tắt chính tả, tắt macro: gõ `fable fanh fan fun ` → `fable phanh phan phun `; thử dấu phẩy và Enter. Với Simple Telex 1/VNI: `web wanh ` → `web quanh `. Bật cả phụ âm cuối nhanh: `fag jag ` → `phang giang `, `fbleg ` giữ `fbleg `. Bật lại chính tả và khôi phục, kiểm `tesst `→`test `, `ass `→`as ` (macro tắt).

**Giới hạn đã chốt:** đây là từ điển âm tiết Việt, không phải bộ phát hiện ý định tiếng Anh. Từ mới/tên riêng không có trong dữ liệu không được tự mở rộng; `fan/fun` ưu tiên Việt theo lựa chọn người dùng. Không đổi default, version, UI hoặc đường event tap.

## 12. Bỏ dấu tự do: nhận dấu mũ/móc nhập muộn bằng từ điển

**Yêu cầu từ ảnh:** Unicode/Telex, Bỏ dấu tự do bật, `vijece` và `viejce` phải thành **`việc`**. Trước sửa, engine giữ MARK trên I khi E nhận mũ muộn, dẫn tới `vịêc`; đây là trạng thái thật trong buffer, khác lỗi redraw Swift ở [xkey #139](https://github.com/xmannv/xkey/issues/139)/[00b4dce](https://github.com/xmannv/xkey/commit/00b4dce42623a227816b12b9802754b6c8e4e172). Không chuyển thể patch đó hoặc code port. Bản này tự viết cho MKey, dùng chung dữ liệu GPL đã kiểm ở mục 11.

**Cách sửa tổng quát:** sau phím A/E/O/W (VNI 6/7/8) thực sự thay shape, chỉ nhận packet `vWillProcess` có số xoá và số chèn bằng nhau. Nếu từ hiện tại đã nằm trong từ điển thì giữ nguyên. Với đúng một dấu thanh, thử các vị trí của **chính dấu đó**, giữ nguyên mọi bit chữ, hoa/thường và mũ/móc. Chỉ sửa khi có **duy nhất một âm tiết hợp lệ**; không có hoặc nhiều đáp án thì bỏ qua. Không có nhánh so chuỗi `việc`, `vijece` hay `viejce` trong engine.

Không gọi thử `checkGrammar` rồi khôi phục state: mọi ứng viên chỉ ở buffer cục bộ, word/packet chỉ thay sau khi đã chọn duy nhất. Vùng redraw bắt đầu từ vị trí sớm nhất trong dấu cũ, dấu mới và vùng shape của packet hiện tại. Nhờ vậy không bỏ mất shape chưa gửi ra app. Packet dùng ext4; âm tiết được nhận dài tối đa 7 ký tự, không cần ext5 hoặc sửa giới hạn hook. Macro cập nhật sau chuẩn hóa; raw `KeyStates`, stateIndex và lịch sử undo giữ nguyên.

| Nguồn | Triệu chứng/phạm vi | Bằng chứng phổ biến | Fix | Trạng thái | Commit |
|---|---|---|---|---|---|
| Ảnh người dùng, bộ từ GPL ở mục 11 | Dấu thanh đặt trước rồi thêm mũ/móc muộn: `vijece/viejce`→`việc` | Cùng nguyên nhân ở tiếng/tiền/biển/chiếc/hiện/nghiệm/quyền/thuế/người/dưới/tuổi/chuẩn/khuấy; thao tác Telex/VNI hằng ngày | Enum vị trí dấu trên cả âm tiết, chỉ nhận kết quả từ điển duy nhất; code MKey tự viết | **ĐÃ ÁP DỤNG**, 622 ca, **509 FAIL → PASS** tại đợt shape | `e3f343f` |
| GI nhập chữ thường sau dấu, nhiều dấu hoặc standalone W/ngoặc | Khác biệt mode/hủy dấu đã ghi ở mục 10 | Có issue liên quan nhưng khác nguyên nhân và đường state | GI + coda được tiếp tục ở mục 13; `gisu/gisa`, nhiều dấu, standalone vẫn bỏ qua | **ĐÃ ÁP DỤNG** phần có coda; các phần còn lại giữ guard | Commit chứa mục 13 |

**Test trước/sau:** `free-mark.tsv` gồm 128 ca sàng lọc/undo, 64 ca thuộc 32 họ từ × hai chính tả và 430 ca cài đặt/VNI/case/history. Kỳ vọng được viết độc lập trước khi chạy, không sửa theo output. Trước bản này (engine `9355bc0`): **113 PASS + 509 FAIL / 622**; sau sửa **622/622 PASS**. Full suite **2.851 PASS + đúng 5 known / 2.856**, thêm **84 kiểm tra packet/policy/dictionary PASS**; ASan/UBSan strict toàn suite sạch. Debug `xcodegen generate` + `xcodebuild ... clean build` thành công; sau commit chạy lại test và build bằng lệnh ban đầu.

Review trên snapshot đúng source hiện tại xác nhận 472 probe packet/biên/history và 168 probe focus khớp text/trace đã audit, không có finding. Cả prefix redraw 31/32, ordinary GI, `tesst/ass`, Restore, raw restoration sau thêm chữ sai, macro và Backspace đều giữ guard. Các prototype có regression trước đây vẫn bị loại; 38 oracle ordinary-append ngoài phạm vi được giữ nguyên trong research, không đổi thành known failure hoặc kỳ vọng giả.

**Escape:** `tesst `→`test `, `ass `→`as ` giữ cả restore on/off. Từ đã sửa nay dùng chính quy tắc hủy dấu như từ gõ chuẩn: `vijecej` và `vieecjj` cùng ra `viêcj`; `vijecee` và `vieecje` cùng ra `viẹce`. Đây là phím hủy trên chữ đã được sửa đúng, không replay tất cả raw keys. Chuỗi GI nhập thường và trường hợp nhiều MARK không bị helper can thiệp.

**CẦN TEST TAY**, chưa chạy app thật trong đợt này:

| App | Kiểu gõ/cài đặt | Chuỗi phím | Mong đợi |
|---|---|---|---|
| TextEdit, Chrome/Safari, VS Code | Unicode/Telex, Bỏ dấu tự do bật, macro tắt; lặp chính tả và khôi phục on/off | `vijece viejce tisenge quyfene ngufoiw ` | `việc việc tiếng quyền người ` |
| Cùng các app trên | Unicode/VNI, Bỏ dấu tự do bật, macro tắt | `vi5ec6 vie5c6 ` | `việc việc ` |
| Chrome/Safari và VS Code | Telex/free=1, macro tắt | `vijece,` rồi Enter; gõ `vijece` rồi Backspace và `c` | `việc,` rồi xuống dòng; từ sau vẫn là `việc`, không mất/lặp chữ |
| TextEdit, Chrome | Telex/free=1, macro tắt, restore on/off | `vijecej `, `vijecee `, `tesst ass ` | `viêcj `, `viẹce `, `test as ` như gõ chuẩn và quy tắc escape đã chốt |
| TextEdit | free=1, macro tắt, cả chính tả cũ/mới | `hosa thusy` | Giữ hành vi cũ `hóa thúy`, không ép theo một chuẩn khác |

**Giới hạn:** Unicode dựng sẵn, chỉ khi shape nhập muộn, không tự chuẩn hóa sau mọi chữ hoặc dò từ gần giống. Từ ngoài dữ liệu, nhiều dấu, standalone chưa chèn ra host, overflow và bảng mã khác được bỏ qua. Không đổi default của Free Mark, chính tả hay khôi phục. SHA256 của 29 file có sẵn của người dùng được đối chiếu với snapshot đầu đợt mới; engine/harness/report thay đổi trong hai commit này không chứa hunk của người dùng.

## 13. GI có phụ âm cuối: `gisup` → `giúp`, giữ escape theo từ gõ chuẩn

**Quyết định trực tiếp của người dùng:** sau khi sửa `gisup` thành `giúp`, thêm S phải hủy dấu thành **`giups`**, giống `giupss`; không giữ kết quả cũ `gíúp` có hai dấu. Đây là luật escape hiện có áp lên từ đã sửa đúng, tương tự `vijecej` sau mục 12. Không đổi `insertMark`, điều kiện duplicate tone, `vRestore`, raw replay hay default nào.

**Nguồn:** báo cáo liên quan [xkey #139](https://github.com/xmannv/xkey/issues/139) và [00b4dce](https://github.com/xmannv/xkey/commit/00b4dce42623a227816b12b9802754b6c8e4e172). Patch Swift đó sửa vùng redraw; MKey C++ thiếu bước dời dấu khi thêm coda với free=1, nên bản này **tự viết**, không chép code port hoặc gán nhầm fixing commit. Dùng lại bộ dữ liệu GPL [hunspell-vi@39cc647](https://github.com/1ec5/hunspell-vi/tree/39cc647f0cf3bdfc579980a2c3aac3f6f4203fe6) và notice ở mục 11. Không tải/chạy/build thêm code upstream.

**Nguyên nhân và điều kiện hẹp:** `findAndCalculateVowel(false)` bỏ I trong phụ âm đầu GI; MARK đặt sớm trên I không được dời khi thêm U rồi P, bởi free=1 không chạy grammar ở đường nhập thường. Nay tái dùng phép tra vị trí dấu duy nhất: chỉ khi phụ âm thường vừa chèn, code gốc là DoNothing, prefix GI, đúng một dấu trên I, từ hiện tại chưa hợp lệ và có duy nhất một kết quả trong từ điển. Từ, shape, chữ hoa, dấu đã chọn giữ nguyên. `gisu` vẫn là `gíu`; helper chỉ nhận khi phụ âm cuối tạo được âm tiết như giúp/gián/giàn/giản/giãn/giọt/giận/giếng, không có nhánh đặc biệt theo chuỗi `gisup`.

**Packet:** phụ âm mới chưa tới text field, nên suffix phải có **NCC=BPC+1**. Với `gisup`, packet là **WillProcess/ext4, BPC=2, NCC=3**, data đảo `[p, ú, i]`: thay `íu` bằng `iúp`, suppress P gốc. Macro updater sẵn có pop BPC/append NCC nên đồng bộ với từ đã sửa; KeyStates/stateIndex/owner history không đổi. Từ điển dài tối đa 7 chữ, tone cũ bắt buộc ở index1 nên NCC≤6, BPC≤5; không mở giới hạn 31/32, không sửa sender/hook.

**Regression phát hiện trước commit và đã chặn:** bản thử đầu sửa cả `gisu<ENGINEOFF>q<ENGINEON>p` thành `gíiúp`, vì Q tới host trong lúc engine không theo dõi. Thêm điều kiện **raw history còn hợp lệ** riêng nhánh coda mới; từ đã bypass hoặc edit làm mất ownership được giữ như trước. Không thêm điểm invalidate/reset, không siết lại nhánh shape cũ. 48 guard Telex/VNI × spelling/macro/restore xác minh bypass có/không chèn chữ và prefix đã Backspace. Review độc lập thêm 640 so sánh control/bypass dưới ASan/UBSan đều giữ output cũ. Vì thế `gisu<BS>up` vẫn giữ `gíup`; đây là giới hạn thận trọng, không quảng cáo sửa mọi thứ tự chỉnh sửa GI.

| Nguồn | Triệu chứng và bằng chứng phổ biến | Fix | Trạng thái | Commit |
|---|---|---|---|---|
| Người dùng yêu cầu trực tiếp; xkey #139 liên quan | `gisup/gi1up` sai dấu; cùng họ GI có coda, Telex/VNI, năm dấu, chữ hoa và ứng dụng gõ hằng ngày | Từ điển xác nhận vị trí MARK duy nhất, packet tính cả phụ âm đang chờ gửi | **ĐÃ ÁP DỤNG**, 256 ca mới FAIL → PASS, 24 contract FAIL → PASS | Commit chứa mục 13 (`engine: sửa dấu GI khi thêm phụ âm cuối`) |
| Bản thử thiếu guard raw ownership | Bypass giữa từ làm redraw sai `gíuqp`→`gíiúp` | Bỏ qua coda normalization khi KeyStates không còn đáng tin | **ĐÃ CHẶN TRƯỚC COMMIT**, không đưa bản thử lỗi vào commit | Cùng commit |
| GI mở, nhiều MARK sẵn có, standalone hoặc từ không có trong từ điển | `gisu/gisa/gisas`, W/ngoặc và các từ không có coda hợp lệ | Giữ nguyên ngoài điều kiện hẹp | **BỎ QUA**; có guard | — |

### Mười kỳ vọng GI cũ được đổi có chủ ý

Giữ ID để đối chiếu lịch sử. Trước yêu cầu mới, các dòng này là guard ngoài phạm vi ở `e3f343f`; nay người dùng chấp thuận sửa GI theo canonical. Không cập nhật expected hàng loạt theo output mới: mỗi giá trị được đối chiếu với chuỗi gõ chuẩn trên **engine trước sửa** và ghi trong `reviewed-existing-gi-expectation-changes.json` ngoài repo.

| Ca | Trước | Sau | Chuỗi chuẩn đối chứng trên engine trước sửa |
|---|---|---|---|
| `gisup` (3 dòng gồm guard và restore0/1) | `gíup` | `giúp` | `giusp` |
| `gisups` (2 dòng restore0/1) | `gíúp` | `giups` | `giusps` |
| `gisups ` (1 dòng) | `gíúp ` | `giups ` | `giusps ` |
| `gisups<BS>s` (2 dòng restore0/1) | `gius` | `giúp` | `giusps<BS>s` |
| `gisupf` (2 dòng restore0/1) | `gíùp` | `giùp` | `giuspf` |

**Xác minh:** baseline đầu đợt `e3f343f` là **2.851 PASS + 5 known / 2.856**, 84 contract PASS. `free-mark-gi.tsv` mới có **539 ca: 283 PASS + 256 FAIL trước sửa → 539 PASS sau sửa**; thêm 24 packet/macro/escape check đều FAIL trước và PASS sau. Toàn suite hiện tại **3.390 PASS + đúng 5 known / 3.395**, **108 contract PASS**, ASan/UBSan strict sạch. Build Debug bằng `xcodegen generate` và lệnh xcodebuild ban đầu thành công; sau commit chạy lại cả suite và build. Baseline404, baseline-results, known-failures, screened/72 escape guard không thay đổi hoặc thêm exemption.

Các oracle gồm từ Việt độc lập, cặp source/canonical để hủy/thay dấu, VNI, case, lịch sử, raw restore, unknown/intermediate và trạng thái bypass. Một bản draft escape đã giả định sai F/R/X luôn thay dấu trên âm cuối T; nhánh `checkCorrectVowel` hiện có chèn literal ở các trường hợp đó, và canonical được kiểm lại trước khi chốt. Draft/log sai giữ ngoài repo. Packet fixture đầu cũng đã sửa đúng cách nhả Shift khi gõ số VNI và đăng ký rõ macro chữ hoa khi AutoCaps tắt; không sửa code sản phẩm để làm test xanh. Không nhận 23 oracle GI mở ngoài phạm vi thành XFAIL mới.

Review độc lập kiểm rule/canonical và packet ở nhánh fresh-word; phát hiện bypass của root được thêm guard rồi review lại trên source đúng. Các lần so canonical xét **cả text lẫn packet**: riêng packet có thể giống nhưng vẫn bỏ sót dấu trên I ở bên trái, nên không dùng packet-only để kết luận. Macro `giúp/GIÚP`→`help` nằm trong process contract riêng, không thêm fixture đó vào app hoặc các ca văn bản thông thường.

**CẦN TEST TAY**, chưa thực hiện trên app thật:

| App | Cài đặt | Chuỗi phím | Mong đợi |
|---|---|---|---|
| TextEdit, Chrome/Safari/Firefox, VS Code | Unicode/Telex, Bỏ dấu tự do bật, macro tắt; lặp spelling/restore on/off | `gisup` rồi dừng, không cần Space | `giúp` ngay khi bấm P |
| Cùng các app trên | Như trên | `gisups `; `gisupf`; `gisups<BS>s` | `giups `; `giùp`; `giúp`, giống từ gõ chuẩn |
| TextEdit, Chrome | Unicode/VNI, Bỏ dấu tự do bật, macro tắt | `gi1up`; `gi1up1 ` | `giúp`; `giup1 ` |
| TextEdit, VS Code | Telex/free=1, macro tắt | `gisan gifan giran gixan gijot `; `GISUP` | `gián giàn giản giãn giọt `; `GIÚP` |
| TextEdit | Telex/free=1, spell=1, restore=1, macro tắt | `gisupq `; `tesst ass `; `gisu` | Khôi phục đúng `gisupq `; `test as `; giữ phần đang nhập `gíu` |
| TextEdit, Chrome | Thêm macro thử `giúp`→`help`, bật macro | `gisup ` | `help `, không còn chữ/dấu cũ hoặc lặp P |

**Giới hạn:** chỉ Unicode dựng sẵn và GI có coda trong composition còn đáng tin; không mở normalization sau mọi nguyên âm, nhiều dấu hoặc từ không xác định. Sau macro/quick rewrite ở dấu câu/Enter, raw validity có thể vẫn false ở từ mới cho tới Space/session reset, nên nhánh GI mới cũng thận trọng bỏ qua; không nới ownership trong bản vá này. Kiểm raw validity chỉ bảo đảm các transition engine quan sát được; chưa xác minh toàn bộ focus/suspend/layout, timing, AX hoặc lựa chọn tự động trong browser. Bản vá không đổi hook, UI, version/default, nguồn dữ liệu hay giấy phép. 29 file có sẵn của người dùng được kiểm SHA256 so với đầu đợt; build vẫn trên checkout có các thay đổi của người dùng.

## 14. Đồng bộ bản phát hành và chuẩn bị 1.6.2

Theo yêu cầu tiếp theo của người dùng, commit `bc85c3f` đồng bộ đầy đủ tag `v1.6.1` (`b3c6f61`) vào nhánh `fix/upstream-issues`, giữ cả lịch sử của 16 bản vá engine. Mọi file engine và hook giữ nguyên byte so với checkout trước đồng bộ. Các thay đổi chưa commit đã trùng với tag được ghi nhận từ lịch sử phát hành; chỉ bổ sung metadata 1.6.1/build 13, ghi chú phát hành và mục loại trừ `dist/`.

Bản Release universal 1.6.1/build 13 có Sparkle 2.9.6 đã được notarize, staple và cài tại `/Applications/mkey.app`. Toàn bộ 3.395 ca văn bản có 3.390 PASS và đúng 5 sai lệch English đã biết; 108 contract, ASan/UBSan, 14 kiểm tra chính sách updater và 4 tình huống Sparkle đều PASS. Debug và Release build thành công. Giao diện xác nhận đúng version/build, nút kiểm tra cập nhật được bật và trạng thái Trợ năng là “Đã sẵn sàng”.

Người dùng sau đó báo đã thử gõ và thấy “khá ok”. Đây là xác nhận sử dụng chung; chưa có kết quả riêng cho toàn bộ app và từng mục của checklist test tay nên không đánh dấu chúng đã hoàn tất.

Yêu cầu mới cho phép commit và push mã nguồn. Chuẩn bị phiên bản kế tiếp **1.6.2/build 14**, giữ các commit sửa lỗi riêng, với release note tại `docs/releases/1.6.2.md`. Gói Release và feed ký chỉ được chuẩn bị cục bộ; nhánh nguồn được push riêng. **Chỉ xuất bản GitHub Release và cập nhật kênh Sparkle sau khi người dùng duyệt release note.**

## 15. Quick Telex: kiểm tra tiền tố bằng từ điển

Người dùng báo bật Gõ nhanh Telex làm `App` thành `Aph`, rồi yêu cầu sửa tổng quát bằng từ điển nhưng giữ `ppoor`→`phổ` và escape Telex. Quy tắc cũ đổi cả bảy cặp `cc/gg/kk/nn/qq/pp/tt` ở mọi vị trí. Đối chiếu bản MKey 1.6.1 và bản đang chuẩn bị phát hành tái hiện giống nhau; đây là xử lý có sẵn, không phải regression của ba bản vá từ điển trước. Chưa có issue/PR upstream được xác minh cùng bản vá này; không gán một fix nguồn giả. Preimage MKey: [Engine.cpp tại v1.6.1](https://github.com/maclifevn/mkey/blob/v1.6.1/Sources/Engine/Engine.cpp).

Bản vá tự viết tái sử dụng danh sách GPL đã pin ở mục 11: [hunspell-vi 39cc647](https://github.com/1ec5/hunspell-vi/commit/39cc647f0cf3bdfc579980a2c3aac3f6f4203fe6). Generator giữ nguyên 6.678 âm tiết và bảng membership, sinh thêm **1.555 dạng chữ cái cơ sở** đã sắp xếp, tương ứng 1.720 tiền tố không rỗng. Prefix lookup không cấp phát heap, không tải dữ liệu lúc chạy; bỏ dấu thanh và hình dạng nguyên âm khi so khớp để còn gõ dấu muộn (`baccs`→`bách`). Cờ lạ, chữ đã mã hoá, dấu mâu thuẫn, từ quá dài và cửa sổ đã trượt bị từ chối.

Chỉ trước khi đổi một cặp Quick Telex ở **Unicode dựng sẵn**, engine xem trước toàn bộ từ cùng phụ âm mới. Khi bật Phụ âm đầu nhanh, preview cả F/J/W để giữ các tổ hợp `fann`→`phang`, `jann`→`giang`, VNI/Simple Telex `wann`→`quang`. `ph` là tiền tố hợp lệ nên `ppoor` vẫn thành `phổ`; `aph` không có trong từ điển nên phím P thứ hai đi qua đường nhập thường. Hàm gửi packet và early return cũ của các cặp được nhận giữ nguyên; không đổi hook, escape, replay lịch sử, cài đặt mặc định hoặc version/build.

| Xác minh | Trước sửa | Sau sửa |
|---|---|---|
| 721 ca `quick-telex.tsv`, gồm App/Apple, bảy cặp, phụ âm cuối CC/NN, cấu hình, chữ hoa, macro/history/bypass và biên 31–32 | 262 PASS, **459 FAIL**; App hiện Aph | **721 PASS**, giữ nguyên toàn bộ expected |
| 27 contract prefix từ điển | API mới | **27 PASS**, cùng 22 membership cũ |
| Đối chiếu độc lập từ nguồn `.dic` bằng NFD: membership prefix, mask/case, 65.536 keycode, giới hạn | Oracle độc lập | **593.281/593.281 PASS**, ASan/UBSan sạch |
| 2.714 cặp gõ chuẩn / Quick Telex thuộc đúng 6.678 âm tiết | Đã tương đương | Giữ nguyên cả văn bản lẫn toàn bộ packet từng phím |
| Full suite | 3.390 PASS + 5 known ở bộ cũ | **4.111 PASS + đúng 5 known**, 135 contract PASS |

Một bản thăm dò rộng ban đầu dùng cả dữ liệu thô ngoài 6.678 âm tiết (GIF, palăng, PNG); oracle và kết quả này được giữ riêng, không đổi expected để đưa vào bộ nhận. Những ca Hanna/Hannah/Accept/Accent đòi khôi phục sau một prefix vốn hợp lệ cũng được giữ ngoài bộ nhận, không thêm XFAIL. Bản vá này kiểm prefix lúc gõ, không nhận diện toàn bộ từ tiếng Anh: ví dụ `Ann` vẫn có thể thành `Ang`, `account` vẫn có thể thành `achount` theo quy tắc ưu tiên tiếng Việt. Không sửa riêng lỗi viết hoa hỗn hợp ở Quick Telex hoặc Free Mark trên từ khác.

**Cần test tay:** TextEdit, VS Code và ô soạn thảo trình duyệt; Telex + Unicode dựng sẵn, Quick Telex bật, macro/restore tắt. Gõ `App Apple ppoor baccs `→`App Apple phổ bách `; kiểm ngay sau P thứ hai của App. Bật/tắt chính tả, Free Mark; thử Enter/dấu phẩy. Bật thêm Phụ âm đầu nhanh: `fann jann `→`phang giang `. `tesst `→`test `, `ass `→`as ` và Free Mark `gisups`→`giups` vẫn giữ nguyên. Không dán chuỗi để thay cho gõ từng phím.

Snapshot, oracle trước/sau, full suite, review packet và sanitizer nằm ngoài repo tại `/Users/maclife/mkey-research/2026-10-24-quick-telex-dictionary-5psqulrf/`. Gói 1.6.2 cũ từ `36f6026` đã được đánh dấu superseded; chỉ được tạo lại từ commit chứa bản vá này. Việc xuất bản lên Sparkle vẫn chờ người dùng duyệt release note mới.

## Phụ lục A — Repo tìm thêm qua code search

| Repository / snapshot | Classification | Active-code evidence | License evidence | Issue coverage |
|---|---|---|---|---|
| [binhsonnguyen/Everkey](https://github.com/binhsonnguyen/Everkey/tree/05b9375e7c2c68945ab1c00266ce24ed81917ee2) `05b9375e` | Swift port OpenKey qua XKey, dùng thật | `EverkeyEngine/Sources/EverkeyEngine/XKeyEngine/VNEngine.swift:5-13` tự nhận direct OpenKey C++ port; `KeyboardEventHandler.swift:4,30` giữ/tạo VNEngine; Package.swift:12 bao gồm target engine. `THIRD_PARTY_NOTICES.md:7-11` chỉ rõ lấy từ XKey v1.2.22-20260602.1. | `LICENSE:1` MIT thật, dù API NOASSERTION do cuối file thêm third-party note. NOTICE ghi MIT XKey; giữ lưu ý lineage OpenKey, không suy diễn lại quyền relicensing. | 0 bug issues;1PR |
| [datnm555/dkey](https://github.com/datnm555/dkey/tree/8eac80141d4e0370f56279e96f1be0f82f5fd2b6) `8eac8014` | Swift port trực tiếp logic OpenKey, dùng thật | `Sources/Engine/TelexEngine.swift:492,546,740,855,1139` đối chiếu rõ từng hàm/dòng Engine.cpp gốc; dùng TypingWord cell/mask, chuyển getCharacterCode. `project.yml:23` đưa Sources/Engine vào app. | Root LICENSE GPLv3. | 0 bug issues;8PR |
| [lotus-key/lotus-key](https://github.com/lotus-key/lotus-key/tree/1d8b9ff982b83da77d8f3d19f8ca4c5587e85f8a) `1d8b9ff9` | Swift rewrite tham khảo hành vi OpenKey, dùng thật; không port giữ nguyên kiến trúc | `Sources/LotusKey/Core/Engine/VietnameseEngine.swift:51` DefaultVietnameseEngine dùng `TypingBuffer`/`TypedCharacter` và enum replacement; :568 ghi triển khai checkGrammar behavior từ OpenKey; :628 backspace; :73-80 history/spaceCount mô phỏng OpenKey. `Package.swift:22` build Sources/LotusKey. README:3 chỉ nói lấy cảm hứng. Xem như partial logic port, không coi code before/after là preimage MKey. | Root LICENSE GPLv3. | 0issue/PR |
| [hoquangthaiholy/vnkey](https://github.com/hoquangthaiholy/vnkey/tree/e2fdc6daf3eef7b3b242728644f6e8841693ad22) `e2fdc6da` | C++ OpenKey active, Rust/Tauri shell; có thêm Rust engine module | `Sources/src-tauri/src/lib.rs:2-3` alias `legacy_engine as engine_sys`; caller dùng engine_sys::startNewSession (e.g.617). `build.rs:29,36,51` compile Engine.cpp/Vietnamese.cpp vào vnkey_engine. `Sources/src-tauri/engine/Engine.cpp` vẫn TypingWord, checkGrammar và hook protocol. Rust `src/engine/key_engine.rs` tồn tại nhưng không thay alias active này. | Root LICENSE GPLv3. | 0bug issues;5PR |
| [marixdev/vnkey](https://github.com/marixdev/vnkey/tree/b75cdc0f5cbee954364212cfceb85f788d84809a) `b75cdc0f` | Rust UniKey-style lexical engine; không phải port cấu trúc OpenKey | README:256 lấy cảm hứng UniKey. `vnkey-engine/src/engine.rs:82-105` WordInfo lưu form,c1_offset,v_offset,c2_offset,VowelSeq,ConSeq,VnLexiName; :131 Engine; `src/vnlexi.rs:9` lexical enums. Không phải TypingWord/CHAR_CODE_MASK/vKeyHookState protocol OpenKey. `vnkey-macos/CMakeLists.txt:7-9` dùng Rust staticlib thật. Gọi UniKey-style/rewrite, không khẳng định bản port nguyên xi khi chưa chứng minh lịch sử. | Root LICENSE GPLv3; fcitx5/ibus có LICENSE riêng nhưng không thay lineage engine. | 22bug issues+7PR đãcó data; parent đãđọc sơbộ, passnày khôngđọc lại bodies |
| [lamtran8401/GoviKey](https://github.com/lamtran8401/GoviKey/tree/92406a39fe2bac1c9cea55ddb954b518c7c17c61) `92406a39` | Swift port PHTV → OpenKey, dùng thật | `Sources/Engine/VietnameseEngine.swift:5-6` ghi port từ PHTVEngineCore.swift; :33 typingWord,[UInt32], :96 vKeyHandleEvent, :301 startNewSession; các extension EngineComposition/EngineHandler/EngineMark giữ cấu trúc. `Package.swift:16` build Sources/Engine. | Không có LICENSE/COPYING trong root hoặc subdir engine theo toàn tree. README:7 chỉ badge MIT, không đủ coi là grant license. Chỉ học ý tưởng, không chép. | 0issue/PR |
| [nguyenduyhung1989/mindful-keyboard](https://github.com/nguyenduyhung1989/mindful-keyboard/tree/0b0c8c56b654b3b95667136c261d7ccae6af117a) `0b0c8c56` | Bundled C++ OpenKey làm nền prototype, không chỉ test reference | README:13-14 định nghĩa OpenKey/ làm nền fork; :33,:57-59 thêm vOnWordCommitted callback. `prototype/test_engine.cpp:11,81,115` gọi trực tiếp Engine.h/vKeyHandleEvent/vKeyInit. Bundled macOS project vẫn đưa Engine.cpp vào Sources(:43,407). App cảm xúc Windows còn roadmap chưa hoàn tất nên không coi là nguồn fix macOS đã shipping. | Root không LICENSE nhưng `OpenKey/LICENSE:1-2` là GPLv3 áp phần engine. README:62 cũng ghi chấp nhận GPLv3 cho sản phẩm phái sinh; không suy ra license riêng cho mọi file ngoài OpenKey/. | 0issue/PR |
| [thamdavies/TnKey](https://github.com/thamdavies/TnKey/tree/7cff98156cc8bbdf08f68c3479a072985a4fea80) `7cff9815` | C++ OpenKey modified, nằm product build | `engine/Engine.cpp:2-6` giữ tác giả Tuyen/OpenKey; :477 startNewSession, :1857 vKeyHandleEvent cùng masks/state. `macOS/OpenKey.xcodeproj/project.pbxproj:48,416` thêm Engine.cpp vào Sources. Không phải thư mục archive/reference. | Không có LICENSE/COPYING tại root lẫn engine hoặc chỗ khác trong tree. Header attribution không thay grant license; chỉ học ý tưởng. | 0issue/PR |
| [JimmyVNC/AZS-TOOL](https://github.com/JimmyVNC/AZS-TOOL/tree/227e67cf181cb9cdb3f0aa0af62fb5554775bdf0) `227e67cf` | C++ OpenKey qua MKey, dùng thật trong AZSTools | README:3,67,76-77 gọi rõ engine OpenKey và phần glue/UI kếthừa mkey. `project.yml:55-58` đưa Sources/Engine+Platform vào application AZSTools. Source `Sources/Engine/Engine.cpp` và `Sources/Platform/MKEngineHook.mm` giữ bố cục MKey. | Root LICENSE GPLv3; README:76-77 khẳng định cả engine/glue/mkey GPLv3. Các phần chuột riêng có thirdparty license khác, không dùng cho enginefix. | 0issue/PR |
| [coderunknow/KieeKey](https://github.com/coderunknow/KieeKey/tree/842eea2e8ca6062acf56b8b9a78071c24aaa024a) `842eea2e` | ACTIVE C++ port OpenKey2.0.5 sang class/stateperinstance; KHÔNG phải chỉreference | `src/core/TextEngine.cpp:35-44` ghi Algorithm=OpenKey2.0.5 Engine.cpp, giữ thuật toán và một master iterationfix; :61,:75,:184 constructor/session/process. `CMakeLists.txt:172,184-185` build TextEngine.cpp vào product ok_core, :288 link app với ok_core. `tests/reference/openkey-2.0.5/` chỉ oracle để đối chiếu. ChaosEngine.cpp là case/glyph transform & gamification, không thay bộ gõ Telex/VNI. Đối chiếu fix phải dịch class/ASCIIidentity về MKey C++cũ. | Root LICENSE GPLv3; TextEngine.cpp:28 SPDX GPL-3.0-or-later và :5-7 copyright upstream. | 0bug issues;36PR; passnày chỉsourceinventory |

## Phụ lục B — Toàn bộ 45 fork khớp bộ lọc

Giấy phép trong bảng fork là metadata GPL v3 của repo; chỉ các source được lấy code mới được kiểm LICENSE cụ thể như đã nêu phía trên. Bảng này là triage fork, không biến một compare có thay đổi thành bằng chứng fix đã xác nhận.

| Repo | Engine | License | Disposition | Rationale |
|---|---|---|---|---|
| [chickengamer33-real/OpenKey](https://github.com/tuyenvm/OpenKey/compare/master...chickengamer33-real:master) | OpenKey C++ | GPL-3.0 | HÀNH VI/ UI | Fn hotkey support + HUD/Tahoe UI; không có engine regression nhỏ cần áp. |
| [zeldrisho/OpenKey](https://github.com/tuyenvm/OpenKey/compare/master...zeldrisho:master) | OpenKey C++ | GPL-3.0 | REFACTOR | Tổ chức lại engine/src cross-platform, review autofixes; không tìm thấy issue tái hiện macOS cụ thể. |
| [truongvpv/OpenKey](https://github.com/tuyenvm/OpenKey/compare/master...truongvpv:master) | OpenKey C++ | GPL-3.0 | RỦI RO | Load word from caret + change mark/redraw generally; new context-recovery feature beyond scope; typo tone code chưa có repro. |
| [ntanvinh/OpenKey](https://github.com/tuyenvm/OpenKey/compare/master...ntanvinh:master) | OpenKey C++ | GPL-3.0 | TÍNH NĂNG | Suggestion/snippets/restore mouse word/AI; đụng rộng engine, chưa có ứng viên nhỏ độc lập đủ bằng chứng. |
| [llawliet11/OpenKey](https://github.com/tuyenvm/OpenKey/compare/master...llawliet11:master) | OpenKey C++ | GPL-3.0 | ĐÃ CÓ SẴN / RỦI RO | Event tap recovery/TIS lifetime/cache equivalent đã có ở MKey; Spotlight stale-window fix không tương ứng AX route hiện tại. Fresh-backspace thay đường chung, defer. |
| [vanbui0196/OpenKey](https://github.com/tuyenvm/OpenKey/compare/master...vanbui0196:master) | OpenKey C++ | GPL-3.0 | TÍNH NĂNG | Thêm gõ tiếng Đức, ngoài phạm vi tiếng Việt. |
| [nxnguyen/OpenKey](https://github.com/tuyenvm/OpenKey/compare/master...nxnguyen:master) | OpenKey C++ | GPL-3.0 | ĐÃ CÓ SẴN | Event tap recovery + cached input source/Spotlight work; MKey dùng observer/cache và AX focused process riêng. |
| [jetaudio/Omnikey](https://github.com/tuyenvm/OpenKey/compare/master...jetaudio:master) | OpenKey C++ | GPL-3.0 | RỦI RO / NGOÀI PHẠM VI | ConvertTool casing và SmartSwitch defaults, engine perf, tone dead code cleanup; không đổi default. Tone rule cảnh báo ua fix ngây thơ gây khúây. |
| [longhoang2810/OpenKey](https://github.com/tuyenvm/OpenKey/compare/master...longhoang2810:fix/typing-group1) | OpenKey C++ | GPL-3.0 | ĐÃ ÁP DỤNG MỘT PHẦN / RỦI RO | Caps, GET encode và bảy mẫu D đã áp tại 760684d/8b1a2bb/1ebbf85. Redraw đã chuyển thể hẹp ở mục 9, bổ sung contract biên riêng; hook/hotkey upstream không lấy. |
| [gioigioi124/OpenKey](https://github.com/tuyenvm/OpenKey/compare/master...gioigioi124:master) | OpenKey C++ | GPL-3.0 | WINDOWS / TÍNH NĂNG | Userform TextBox macro + lazy macro conversion; nhiều logic reset hook riêng Windows; không có macOS repro nhỏ. |
| [jooservices/OpenKey](https://github.com/tuyenvm/OpenKey/compare/master...jooservices:master) | OpenKey C++ | GPL-3.0 | TEST-ONLY | Chỉ thêm tests/harness; false positive bộ lọc đường dẫn engine; không thay Sources engine/hook. |
| [tuyennq1001/gox](https://github.com/tuyenvm/OpenKey/compare/master...tuyennq1001:master) | OpenKey C++ | GPL-3.0 | ĐÃ CÓ SẴN / TÍNH NĂNG | C++ engine rename không đổi logic; event tap/cache tương đương; JIS/CJK layout thay hành vi cần test riêng, không áp. |
| [hungmtuci/OpenKey](https://github.com/tuyenvm/OpenKey/compare/master...hungmtuci:master) | OpenKey C++ | GPL-3.0 | ĐÃ CÓ SẴN / RỦI RO | Recovery/cache + Spotlight/Raycast/Alfred selection replacement. MKey đã AX atomic route; browser-only workaround đổi rộng, thiếu repro từng bundle. |
| [linhnd3/OpenKeyFi](https://github.com/tuyenvm/OpenKey/compare/master...linhnd3:master) | OpenKey C++ | GPL-3.0 | TÍNH NĂNG | Finnish keyboard support, ngoài phạm vi minimal Vietnamese bugs. |
| [baveku/OpenKey](https://github.com/tuyenvm/OpenKey/compare/master...baveku:master) | OpenKey C++ | GPL-3.0 | MKEY KHÔNG BỊ / RỦI RO | phasp, didnhj, dodwjt PASS MKey; delayed-d/tone fixes sửa regressions của fork English heuristics. Hook recovery/cache đã có; thay toàn browser workaround/backspace generic không áp. |
| [hungdoansy/OhMyKey](https://github.com/tuyenvm/OpenKey/compare/master...hungdoansy:master) | OpenKey C++ | GPL-3.0 | REBRAND / UI | C++ code gần như rename; header/hotkey Swift UI và macro store tests, không bug logic mới. |
| [VoAnKhoi2005/OpenKey](https://github.com/tuyenvm/OpenKey/compare/master...VoAnKhoi2005:master) | OpenKey C++ | GPL-3.0 | LINUX / TÍNH NĂNG | IBus terminal replacement + custom typing; không macOS hook candidate. |
| [hieu8123/h-openkey](https://github.com/tuyenvm/OpenKey/compare/master...hieu8123:master) | OpenKey C++ | GPL-3.0 | LINUX | Direct input/Wayland/IBus fixes; ConvertTool include only. |
| [sonlexqt/OpenKey](https://github.com/tuyenvm/OpenKey/compare/master...sonlexqt:master) | OpenKey C++ | GPL-3.0 | ĐÃ CÓ SẴN | 59b03c: CGEventTap disabled timeout/user input re-enable; MKey đã có MKReEnableEventTap. |
| [locnh/OpenKey](https://github.com/tuyenvm/OpenKey/compare/master...locnh:master) | OpenKey C++ | GPL-3.0 | ĐÃ CÓ SẴN / RỦI RO | TIS ownership MKey đã tránh retain/release bug. Spotlight running process detection không chứng minh panel hiện và không dùng AX route; không áp. |
| [minhtuan9922/OpenKey](https://github.com/tuyenvm/OpenKey/compare/master...minhtuan9922:master) | OpenKey C++ | GPL-3.0 | REFACTOR / RỦI RO | Signedness and duplicate conditions; rule3.2 source change không có failing case rõ; Windows/UI/perf mostly. |
| [anhkhoakz/OpenKey](https://github.com/tuyenvm/OpenKey/compare/master...anhkhoakz:main) | OpenKey C++ | GPL-3.0 | REFACTOR | Format/UTF conversion/analyze issues diện rộng; không isolated issue reproduction. |
| [TrungThachDau/OpenKey](https://github.com/tuyenvm/OpenKey/compare/master...TrungThachDau:master) | OpenKey C++ | GPL-3.0 | FALSE POSITIVE / WINDOWS | Match OriginalEngineProcessService.cs trong WinUI adapter, không Sources C++/macOS hook change. |
| [minhtoantm/VieKey](https://github.com/tuyenvm/OpenKey/compare/master...minhtoantm:master) | OpenKey C++ | GPL-3.0 | TÍNH NĂNG | Globe/Fn toggle + branding/UI. Không sửa default shortcut. |
| [luatnd/OpenKey](https://github.com/tuyenvm/OpenKey/compare/master...luatnd:master) | OpenKey C++ | GPL-3.0 | TÍNH NĂNG | HAS_FN/SET_FN_KEY + checkHotKey Fn modifier, engine không đổi. |
| [teppyboy/OpenKey](https://github.com/tuyenvm/OpenKey/compare/master...teppyboy:master) | OpenKey C++ | GPL-3.0 | WINDOWS | TSF TIP / EngineOutput adapter; không macOS typing route. |
| [tldkhoa/OpenKey](https://github.com/tuyenvm/OpenKey/compare/master...tldkhoa:master) | OpenKey C++ | GPL-3.0 | HÀNH VI / RỦI RO | Fn-alone & Esc toggle + rule3.2 typo fix. syncKey/TIS guards MKey có tương đương; generic no new hook. |
| [ntdgo/OpenKey](https://github.com/tuyenvm/OpenKey/compare/master...ntdgo:master) | OpenKey C++ | GPL-3.0 | SỞ THÍCH | Bỏ standalone [ ] mapping, đổi hành vi người dùng, không áp. |
| [codezi/OpenKey](https://github.com/tuyenvm/OpenKey/compare/master...codezi:master) | OpenKey C++ | GPL-3.0 | CÓ REPRO / RỦI RO | UYCH giống upstream PR306; bounds macro, UTF rewrite, tone rule3.2. Chọn source upstream UYCH; phần còn lại thiếu issue/repro hoặc quá rộng. |
| [lotusify/OpenKey](https://github.com/tuyenvm/OpenKey/compare/master...lotusify:master) | OpenKey C++ | GPL-3.0 | CÓ REPRO / RỦI RO | Cherry-pick NextKey, UYCH giống PR306, rule3.2 và gi- old mark; giacs PASS MKey. uow incremental đổi hành vi, English/restore changes broad. |
| [darkamenosa/OpenKey](https://github.com/tuyenvm/OpenKey/compare/master...darkamenosa:master) | OpenKey C++ | GPL-3.0 | ĐÃ CÓ SẴN | 2eb749: event tap disabled recovery; MKey đã có. |
| [9000000/NextKey](https://github.com/tuyenvm/OpenKey/compare/master...9000000:feat/UI-Next) | OpenKey C++ | GPL-3.0 | CÓ REPRO / RỦI RO | 0967bec UYCH rõ và duplicate PR306; cungx PASS. de257 sets _stateIndex=_index phân biệt raw/logical bị mất, không chép. uow đổi uơ/ươ là hành vi khác. macro restore cần thêm tests. |
| [ranvotu/OpenKey](https://github.com/tuyenvm/OpenKey/compare/master...ranvotu:latest-stable-1) | OpenKey C++ | GPL-3.0 | RỦI RO / NGOÀI PHẠM VI | Rule3.2 typo; ConvertTool preserve-case, Windows restore hooks. Typo chưa có failing daily MKey case; không áp. |
| [Nam0101/OpenKeyFork](https://github.com/tuyenvm/OpenKey/compare/master...Nam0101:master) | Kotlin port + original C++ | GPL-3.0 | PORT / NGOÀI PHẠM VI | Port Kotlin Engine.kt/Vietnamese.kt giữ cấu trúc; không Swift/Rust. Không chạy/build port, không evidence bug macOS. |
| [nltoan/OpenKey](https://github.com/tuyenvm/OpenKey/compare/master...nltoan:master) | OpenKey C++ | GPL-3.0 | ĐÃ CÓ SẴN | Event tap ensure enabled; MKey đã có. |
| [CanhhnaC/OpenKey](https://github.com/tuyenvm/OpenKey/compare/master...CanhhnaC:master) | OpenKey C++ | GPL-3.0 | RỦI RO | Chỉ rule3.2 VSI+1 typo correction, không repro; khuaays PASS MKey; Omnikey cảnh báo broader ua change. |
| [nhutuananh/OpenKey](https://github.com/tuyenvm/OpenKey/compare/master...nhutuananh:master) | OpenKey C++ | GPL-3.0 | NGOÀI PHẠM VI | ConvertTool mark-removal casing, không keyboard engine/hook issue trong đợt này. |
| [darkpiv/OpenKey](https://github.com/tuyenvm/OpenKey/compare/master...darkpiv:master) | OpenKey C++ | GPL-3.0 | TÍNH NĂNG / RỦI RO | English dictionaries detection + restore escape changes; recovery already. Requires new feature and settings. |
| [vothaianh/OpenKey](https://github.com/tuyenvm/OpenKey/compare/master...vothaianh:master) | OpenKey C++ | GPL-3.0 | TÍNH NĂNG | Per-app exclusion UI+hook; MKey đã có excluded apps riêng, không thêm tính năng. |
| [dandehoon/OpenKey](https://github.com/tuyenvm/OpenKey/compare/master...dandehoon:master) | OpenKey C++ | GPL-3.0 | HÀNH VI / RỦI RO | English macro on all break keys instead of space, not confirmed isolated bug; Windows GetTempPath compatibility irrelevant. |
| [khac88/OpenKey](https://github.com/tuyenvm/OpenKey/compare/master...khac88:master) | OpenKey C++ | GPL-3.0 | TÍNH NĂNG / REGRESSION | AutoRestoreEnglish new feature; subsequent roww/themee/uxx/docss fixes are regressions of own feature. ForceEnglishSpotlight default ON forbidden default change; MKey AX route already. |
| [quyleanh/OpenKey](https://github.com/tuyenvm/OpenKey/compare/master...quyleanh:master) | OpenKey C++ | GPL-3.0 | HÀNH VI / RỦI RO | Esc VietnameseOff setting plus rule3.2 typo; none isolated failing MKey reproduction. |
| [dtk9289/OpenKey](https://github.com/tuyenvm/OpenKey/compare/master...dtk9289:master) | OpenKey C++ | GPL-3.0 | TÍNH NĂNG | Esc turns Vietnamese off, internal formatting/static data changes. Preferences feature, not bug. |
| [vungoctrung93/OpenKey](https://github.com/tuyenvm/OpenKey/compare/master...vungoctrung93:master) | OpenKey C++ | GPL-3.0 | UI | Sort macro names in C++ getAllMacro instead of keyboard-code map ordering; UI behavior, not typing bug. |
| [doanhxd/OpenKey](https://github.com/tuyenvm/OpenKey/compare/master...doanhxd:master) | OpenKey C++ | GPL-3.0 | REBRAND | Only copyright/author replacement in engine/hook, no behavior change. |
