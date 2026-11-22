import 'package:gia_pha/features/settings/domain/entities/app_settings.dart';

abstract interface class SettingsRepository {
  Future<AppSettings> load();
  Future<void> save(AppSettings settings);
}

abstract interface class BackupRepository {
  /// Toàn bộ dữ liệu (không gồm file ảnh) dưới dạng JSON.
  Future<String> exportJson();

  /// Thay thế TOÀN BỘ dữ liệu hiện có bằng nội dung sao lưu.
  /// Ném [FormatException] nếu nội dung không hợp lệ.
  Future<void> importJson(String source);
}
