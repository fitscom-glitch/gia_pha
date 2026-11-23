import 'dart:typed_data';

import 'package:gia_pha/features/settings/domain/entities/app_settings.dart';

abstract interface class SettingsRepository {
  Future<AppSettings> load();
  Future<void> save(AppSettings settings);
}

abstract interface class BackupRepository {
  /// Gói toàn bộ dữ liệu và hình ảnh thành một file .zip.
  Future<Uint8List> exportArchive();

  /// Thay thế TOÀN BỘ dữ liệu hiện có bằng nội dung file sao lưu .zip.
  /// Ném [FormatException] nếu file không hợp lệ.
  Future<void> importArchive(Uint8List bytes);
}
