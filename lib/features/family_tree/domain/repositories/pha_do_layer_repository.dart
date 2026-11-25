import 'package:gia_pha/features/family_tree/domain/entities/pha_do_layer.dart';

abstract interface class PhaDoLayerRepository {
  /// Theo thứ tự lớp (dưới lên trên).
  Future<List<PhaDoLayer>> list();
  Future<void> save(PhaDoLayer layer);
  Future<void> delete(String id);
}
