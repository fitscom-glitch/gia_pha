# Gia phả

Ứng dụng Flutter quản lý gia phả, dữ liệu lưu trên máy (SQLite).

**Tính năng**: thành viên và quan hệ (cha mẹ, vợ/chồng, con), sơ đồ cây, thứ tự anh em (theo thứ tự nhập hoặc tự kéo thả),
lịch dương/âm, ngày giỗ và sinh nhật, lịch sử dòng họ, tộc ước & hương lễ, chuyện cổ kim, bảng vinh danh,
di sản & kỷ vật (ảnh), danh bạ, sao lưu/khôi phục.

**Phả đồ**: dạng tranh treo (khung bao họa tiết hồi văn cam, hai rồng nét chầu hai bên cuốn thư, chữ tên dòng họ uốn cong theo cuốn thư; băng rôn, rồng và rồng chìm tự co dãn theo kích thước phả đồ; hình rồng/phụng/cuốn thư/khung nằm trong `assets/images/`; rồng + phụng ở các trang khác là hình nét đen, tô màu bằng `DragonArt`/`PhoenixArt`). Nét nối đi từ thẻ người cha (người huyết thống) tới thẻ người con, mỗi đời một hàng có nhãn "ĐỜI THỨ N",
có thể gộp nhiều đời vào một hàng (Cài đặt > Gộp nhiều đời, vd `2-5; 8-9`); màu thẻ lệch nhẹ theo từng đời.

**Xem phả đồ**: màn hình dọc thì phả đồ tự xoay dọc cho to (nút xoay ở góc dưới phải để đổi lại), phóng to/thu nhỏ không giới hạn bằng hai ngón, nút "vừa khung nhìn" để về vị trí ban đầu.

**Thống kê** (nút biểu đồ ở trang Gia phả): tổng số đời, số người, nam/nữ, còn sống/đã mất, con cháu trực hệ (không tính dâu, rể) chia trai/gái. Nút "Chèn ảnh" trong soạn bài luôn nằm cố định ở trên cùng.

**Khác**: ảnh đại diện thành viên, ghi chú quan hệ dưới tên, danh sách mở rộng xem vợ/chồng và con,
ngày kỷ niệm tự nhập (dương/âm lịch), bảng lịch âm dương, sao lưu ra file .zip kèm hình ảnh.

**Mới (0.3.0)**: phả đồ có thể gộp nhiều đời vào một hàng và chọn một đời đại diện (cú pháp `2-5:3`),
trang trí phả đồ bằng hình ngoài (PNG nền trong suốt, JPG, WebP, SVG), xuất phả đồ ra PNG/PDF độ phân giải cao,
xuất danh sách thành viên ra Excel (.xlsx) và PDF, bài viết có thể chèn ảnh, lịch đánh dấu ngày lễ (viền đỏ) và
ngày kỷ niệm (viền vàng đậm), xóa được ảnh đại diện. Tác giả dự án: Trung Nguyễn.

**Thứ tự anh em**: các con luôn xếp theo "con thứ mấy" nếu đã đặt (ô trong form thành viên hoặc nút ⇅ ở mục Con
của trang chi tiết), nếu chưa đặt thì theo thứ tự nhập vào. Không bao giờ xếp theo bảng chữ cái.

## Kiến trúc

Feature-first + Clean Architecture. Mỗi feature có 3 tầng:

```
features/<tên>/
├── domain/        # Dart thuần: entities, repositories (interface), usecases, services
├── data/          # models, datasources, repositories (cài đặt)
└── presentation/  # providers (Riverpod), pages, widgets
```

Quy tắc:
- Phụ thuộc một chiều: `presentation → domain ← data`.
- `domain` không import Flutter, sqflite.
- `members` là feature lõi; các feature khác (vd. `family_tree`) được phụ thuộc vào `domain`/providers của nó, không phụ thuộc vòng.
- `core/` chỉ chứa thứ dùng chung, không phụ thuộc feature nào.
- Feature có logic nghiệp vụ (members) dùng usecase; feature CRUD đơn giản (articles, honors, heirlooms, settings) để repository truy cập SQLite trực tiếp.

## Công nghệ

Riverpod (state/DI), go_router (điều hướng, 4 tab), sqflite (lưu local), uuid, image_picker + path_provider (ảnh tư liệu).

## Chạy

```
flutter pub get
flutter run
```

## Kiểm tra trước khi commit

```
dart format .
flutter analyze
flutter test
```

Workflow `.github/workflows/build.yaml` tự sinh thư mục `android/` (nếu chưa có), chạy analyze + test rồi build APK release; file APK nằm ở mục Artifacts của lần chạy workflow.

## Thêm migration DB

Tăng `_version` trong `core/database/app_database.dart` và thêm hàm vào `_migrations`.
