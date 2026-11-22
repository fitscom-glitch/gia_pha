import 'package:gia_pha/features/heirlooms/domain/entities/heirloom.dart';

abstract interface class HeirloomRepository {
  /// Theo thứ tự thêm vào.
  Future<List<Heirloom>> list();
  Future<void> save(Heirloom item);
  Future<void> delete(String id);
}
