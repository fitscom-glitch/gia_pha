import 'package:gia_pha/core/database/app_database.dart';
import 'package:gia_pha/features/family_tree/data/models/pha_do_layer_model.dart';
import 'package:gia_pha/features/family_tree/domain/entities/pha_do_layer.dart';
import 'package:gia_pha/features/family_tree/domain/repositories/pha_do_layer_repository.dart';

class PhaDoLayerRepositoryImpl implements PhaDoLayerRepository {
  PhaDoLayerRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<List<PhaDoLayer>> list() async {
    final db = await _db.database;
    final rows = await db.query('phado_layers', orderBy: 'z, rowid');
    return rows.map(PhaDoLayerModel.fromMap).toList();
  }

  @override
  Future<void> save(PhaDoLayer layer) async {
    final db = await _db.database;
    final map = PhaDoLayerModel.fromEntity(layer).toMap();
    final n = await db.update('phado_layers', map, where: 'id = ?', whereArgs: [layer.id]);
    if (n == 0) await db.insert('phado_layers', map);
  }

  @override
  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('phado_layers', where: 'id = ?', whereArgs: [id]);
  }
}
