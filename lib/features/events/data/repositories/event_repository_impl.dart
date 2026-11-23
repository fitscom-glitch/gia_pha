import 'package:gia_pha/core/database/app_database.dart';
import 'package:gia_pha/features/events/data/models/event_model.dart';
import 'package:gia_pha/features/events/domain/entities/custom_event.dart';
import 'package:gia_pha/features/events/domain/repositories/event_repository.dart';

class EventRepositoryImpl implements EventRepository {
  EventRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<List<CustomEvent>> list() async {
    final db = await _db.database;
    final rows = await db.query('events', orderBy: 'created_at, rowid');
    return rows.map(EventModel.fromMap).toList();
  }

  @override
  Future<void> save(CustomEvent event) async {
    final db = await _db.database;
    final map = EventModel.fromEntity(event).toMap();
    final n = await db.update('events', map, where: 'id = ?', whereArgs: [event.id]);
    if (n == 0) await db.insert('events', map);
  }

  @override
  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }
}
