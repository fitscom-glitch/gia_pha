import 'dart:convert';

import 'package:gia_pha/core/database/app_database.dart';
import 'package:gia_pha/features/settings/domain/entities/app_settings.dart';
import 'package:gia_pha/features/settings/domain/repositories/settings_repository.dart';
import 'package:sqflite/sqflite.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<AppSettings> load() async {
    final db = await _db.database;
    final rows = await db.query('settings');
    final m = {for (final r in rows) r['k'] as String: r['v'] as String};
    return AppSettings(
      clanName: m['clan_name'] ?? '',
      clanIntro: m['clan_intro'] ?? '',
    );
  }

  @override
  Future<void> save(AppSettings s) async {
    final db = await _db.database;
    final batch = db.batch();
    batch.insert(
      'settings',
      {'k': 'clan_name', 'v': s.clanName},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    batch.insert(
      'settings',
      {'k': 'clan_intro', 'v': s.clanIntro},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await batch.commit(noResult: true);
  }
}

class BackupRepositoryImpl implements BackupRepository {
  BackupRepositoryImpl(this._db);

  final AppDatabase _db;

  /// Thứ tự thêm (bảng cha trước). Khi xóa đi theo thứ tự ngược lại.
  static const _tables = [
    'persons',
    'relationships',
    'honors',
    'articles',
    'heirlooms',
    'settings',
  ];

  @override
  Future<String> exportJson() async {
    final db = await _db.database;
    final tables = <String, Object?>{};
    for (final t in _tables) {
      tables[t] = await db.query(t);
    }
    return const JsonEncoder.withIndent(' ').convert({
      'app': 'gia_pha',
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'tables': tables,
    });
  }

  static Object? _decode(String source) {
    try {
      return jsonDecode(source);
    } on FormatException {
      throw const FormatException('Nội dung không phải JSON hợp lệ');
    }
  }

  @override
  Future<void> importJson(String source) async {
    final decoded = _decode(source);
    if (decoded is! Map<String, dynamic> ||
        decoded['app'] != 'gia_pha' ||
        decoded['tables'] is! Map<String, dynamic>) {
      throw const FormatException('Không phải dữ liệu sao lưu của ứng dụng này');
    }
    final tables = decoded['tables'] as Map<String, dynamic>;
    final db = await _db.database;
    await db.transaction((txn) async {
      for (final t in _tables.reversed) {
        await txn.delete(t);
      }
      for (final t in _tables) {
        final rows = tables[t];
        if (rows is! List<dynamic>) continue;
        for (final row in rows) {
          await txn.insert(t, Map<String, Object?>.from(row as Map<dynamic, dynamic>));
        }
      }
    });
  }
}
