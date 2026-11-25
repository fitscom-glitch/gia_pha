import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:gia_pha/core/database/app_database.dart';
import 'package:gia_pha/core/storage/image_store.dart';
import 'package:gia_pha/features/settings/domain/entities/app_settings.dart';
import 'package:gia_pha/features/settings/domain/repositories/settings_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Dấu chèn ảnh trong bài viết, dạng [[img:tên-file]].
final _articleImage = RegExp(r'\[\[img:([^\]]+)\]\]');

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
      clanPlace: m['clan_place'] ?? '',
      generationGroups: m['generation_groups'] ?? '',
      phadoFrame: m['phado_frame'] != '0',
      phadoBanner: m['phado_banner'] != '0',
      phadoWatermark: m['phado_watermark'] != '0',
    );
  }

  @override
  Future<void> save(AppSettings s) async {
    final db = await _db.database;
    final batch = db.batch();
    for (final e in {
      'clan_name': s.clanName,
      'clan_intro': s.clanIntro,
      'clan_place': s.clanPlace,
      'generation_groups': s.generationGroups,
      'phado_frame': s.phadoFrame ? '1' : '0',
      'phado_banner': s.phadoBanner ? '1' : '0',
      'phado_watermark': s.phadoWatermark ? '1' : '0',
    }.entries) {
      batch.insert(
        'settings',
        {'k': e.key, 'v': e.value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
}

/// Sao lưu: một file .zip gồm `data.json` (mọi bảng) và thư mục `images/`
/// (ảnh đại diện + ảnh tư liệu).
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
    'events',
    'phado_layers',
    'settings',
  ];

  /// Bảng -> cột chứa đường dẫn ảnh.
  static const _imageColumn = {
    'persons': 'photo_path',
    'heirlooms': 'image_path',
    'phado_layers': 'path',
  };

  /// Bảng -> thư mục lưu ảnh trong ứng dụng.
  static const _imageFolder = {
    'persons': 'avatars',
    'heirlooms': 'heirlooms',
    'phado_layers': 'phado',
  };

  /// Bảng mà dòng không có ảnh thì bỏ qua (ảnh là bắt buộc).
  static const _requiredImage = {'phado_layers'};

  @override
  Future<Uint8List> exportArchive() async {
    final db = await _db.database;
    final archive = Archive();
    final tables = <String, Object?>{};
    var n = 0;
    for (final t in _tables) {
      final out = <Map<String, Object?>>[];
      for (final r in await db.query(t)) {
        final row = Map<String, Object?>.from(r);
        final col = _imageColumn[t];
        if (col != null) {
          final path = row[col] as String?;
          if (path != null && await File(path).exists()) {
            final bytes = await File(path).readAsBytes();
            final name = 'images/${t}_${n++}${ImageStore.extensionOf(path)}';
            archive.addFile(ArchiveFile(name, bytes.length, bytes));
            row[col] = name;
          } else {
            if (_requiredImage.contains(t)) continue;
            row[col] = null;
          }
        }
        out.add(row);
      }
      tables[t] = out;
    }
    // Ảnh chèn trong bài viết.
    final docs = await getApplicationDocumentsDirectory();
    final articleImages = <String>{};
    for (final a in tables['articles'] as List<Map<String, Object?>>) {
      for (final m in _articleImage.allMatches('${a['body'] ?? ''}')) {
        articleImages.add(m.group(1)!);
      }
    }
    for (final name in articleImages) {
      final f = File('${docs.path}/articles/$name');
      if (await f.exists()) {
        final b = await f.readAsBytes();
        archive.addFile(ArchiveFile('article_images/$name', b.length, b));
      }
    }
    final json = utf8.encode(jsonEncode({
      'app': 'gia_pha',
      'version': 3,
      'exportedAt': DateTime.now().toIso8601String(),
      'tables': tables,
    }));
    archive.addFile(ArchiveFile('data.json', json.length, json));
    final zip = ZipEncoder().encode(archive);
    if (zip == null) throw StateError('Không tạo được file nén');
    return Uint8List.fromList(zip);
  }

  static Object? _decode(String source) {
    try {
      return jsonDecode(source);
    } on FormatException {
      throw const FormatException('Nội dung sao lưu bị hỏng');
    }
  }

  @override
  Future<void> importArchive(Uint8List bytes) async {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw const FormatException('Đây không phải file sao lưu hợp lệ');
    }
    ArchiveFile? dataFile;
    final images = <String, ArchiveFile>{};
    final articleImageFiles = <ArchiveFile>[];
    for (final f in archive.files) {
      if (!f.isFile) continue;
      if (f.name == 'data.json') {
        dataFile = f;
      } else if (f.name.startsWith('images/')) {
        images[f.name] = f;
      } else if (f.name.startsWith('article_images/')) {
        articleImageFiles.add(f);
      }
    }
    if (dataFile == null) {
      throw const FormatException('File sao lưu thiếu dữ liệu (data.json)');
    }
    final decoded = _decode(utf8.decode(dataFile.content as List<int>));
    if (decoded is! Map<String, dynamic> ||
        decoded['app'] != 'gia_pha' ||
        decoded['tables'] is! Map<String, dynamic>) {
      throw const FormatException('Không phải dữ liệu sao lưu của ứng dụng này');
    }
    final tables = decoded['tables'] as Map<String, dynamic>;
    final db = await _db.database;

    // Ảnh cũ sẽ được xóa sau khi khôi phục thành công.
    final oldPaths = <String>[];
    for (final e in _imageColumn.entries) {
      for (final r in await db.query(e.key, columns: [e.value])) {
        final p = r[e.value] as String?;
        if (p != null) oldPaths.add(p);
      }
    }

    // Ghi ảnh vào bộ nhớ ứng dụng và đổi đường dẫn trong từng dòng.
    final prepared = <String, List<Map<String, Object?>>>{};
    for (final t in _tables) {
      final rows = <Map<String, Object?>>[];
      final raw = tables[t];
      if (raw is List<dynamic>) {
        for (final item in raw) {
          final row = Map<String, Object?>.from(item as Map<dynamic, dynamic>);
          final col = _imageColumn[t];
          if (col != null) {
            final name = row[col] as String?;
            final img = name == null ? null : images[name];
            row[col] = (img == null || name == null)
                ? null
                : await ImageStore(folder: _imageFolder[t]!).saveBytes(
                    img.content as List<int>,
                    '${row['id']}',
                    ext: ImageStore.extensionOf(name),
                  );
          }
          final imgCol = _imageColumn[t];
          if (imgCol != null && row[imgCol] == null && _requiredImage.contains(t)) continue;
          rows.add(row);
        }
      }
      prepared[t] = rows;
    }

    await db.transaction((txn) async {
      for (final t in _tables.reversed) {
        await txn.delete(t);
      }
      for (final t in _tables) {
        for (final row in prepared[t]!) {
          await txn.insert(t, row);
        }
      }
    });

    // Khôi phục ảnh trong bài viết.
    const articleStore = ImageStore(folder: 'articles');
    for (final f in articleImageFiles) {
      await articleStore.saveNamed(f.content as List<int>, f.name.split('/').last);
    }

    for (final p in oldPaths) {
      try {
        final f = File(p);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
  }
}
