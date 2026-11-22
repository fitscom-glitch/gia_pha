import 'dart:io';

import 'package:gia_pha/core/database/app_database.dart';
import 'package:gia_pha/features/heirlooms/data/models/heirloom_model.dart';
import 'package:gia_pha/features/heirlooms/domain/entities/heirloom.dart';
import 'package:gia_pha/features/heirlooms/domain/repositories/heirloom_repository.dart';
import 'package:path_provider/path_provider.dart';

class HeirloomRepositoryImpl implements HeirloomRepository {
  HeirloomRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<List<Heirloom>> list() async {
    final db = await _db.database;
    final rows = await db.query('heirlooms', orderBy: 'created_at, rowid');
    return rows.map(HeirloomModel.fromMap).toList();
  }

  @override
  Future<void> save(Heirloom item) async {
    final db = await _db.database;
    final map = HeirloomModel.fromEntity(item).toMap();
    final n = await db.update('heirlooms', map, where: 'id = ?', whereArgs: [item.id]);
    if (n == 0) await db.insert('heirlooms', map);
  }

  @override
  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('heirlooms', where: 'id = ?', whereArgs: [id]);
  }
}

/// Chép ảnh người dùng chọn vào bộ nhớ riêng của ứng dụng (để không mất khi ảnh gốc bị xóa).
class HeirloomImageStore {
  const HeirloomImageStore();

  Future<String> saveCopy(String sourcePath, String id) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/heirlooms');
    if (!await dir.exists()) await dir.create(recursive: true);
    final dot = sourcePath.lastIndexOf('.');
    final ext = dot >= 0 && sourcePath.length - dot <= 6 ? sourcePath.substring(dot) : '.jpg';
    final target = '${dir.path}/${id}_${DateTime.now().millisecondsSinceEpoch}$ext';
    await File(sourcePath).copy(target);
    return target;
  }

  Future<void> delete(String? path) async {
    if (path == null) return;
    final f = File(path);
    if (await f.exists()) await f.delete();
  }
}
