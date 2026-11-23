import 'package:gia_pha/features/events/domain/entities/custom_event.dart';

abstract interface class EventRepository {
  /// Theo thứ tự thêm vào.
  Future<List<CustomEvent>> list();
  Future<void> save(CustomEvent event);
  Future<void> delete(String id);
}
