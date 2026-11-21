# Gia phả

Ứng dụng Flutter quản lý gia phả: thành viên, quan hệ (cha mẹ, vợ/chồng, con) và sơ đồ cây.

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

## Công nghệ

Riverpod (state/DI), go_router (điều hướng), sqflite (lưu local), uuid.

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
