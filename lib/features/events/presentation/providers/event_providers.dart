import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gia_pha/core/database/database_provider.dart';
import 'package:gia_pha/features/events/data/repositories/event_repository_impl.dart';
import 'package:gia_pha/features/events/domain/entities/custom_event.dart';
import 'package:gia_pha/features/events/domain/repositories/event_repository.dart';

final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => EventRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final eventsProvider =
    AsyncNotifierProvider<EventsNotifier, List<CustomEvent>>(EventsNotifier.new);

class EventsNotifier extends AsyncNotifier<List<CustomEvent>> {
  EventRepository get _repo => ref.read(eventRepositoryProvider);

  @override
  Future<List<CustomEvent>> build() => _repo.list();

  Future<void> save(CustomEvent event) async {
    await _repo.save(event);
    state = AsyncData(await _repo.list());
  }

  Future<void> remove(String id) async {
    await _repo.delete(id);
    state = AsyncData(await _repo.list());
  }
}
