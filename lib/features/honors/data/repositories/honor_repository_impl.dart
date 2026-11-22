import 'package:gia_pha/core/database/app_database.dart';
import 'package:gia_pha/features/honors/data/models/honor_model.dart';
import 'package:gia_pha/features/honors/domain/entities/honor.dart';
import 'package:gia_pha/features/honors/domain/repositories/honor_repository.dart';

class HonorRepositoryImpl implements HonorRepository {
  HonorRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<List<Honor>> list() async {
    final db = await _db.database;
    final rows = await db.query('honors', orderBy: 'year IS NULL, year DESC, rowid');
    return rows.map(HonorModel.fromMap).toList();
  }

  @override
  Future<void> save(Honor honor) async {
    final db = await _db.database;
    final map = HonorModel.fromEntity(honor).toMap();
    final n = await db.update('honors', map, where: 'id = ?', whereArgs: [honor.id]);
    if (n == 0) await db.insert('honors', map);
  }

  @override
  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('honors', where: 'id = ?', whereArgs: [id]);
  }
}
