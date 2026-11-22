import 'package:gia_pha/features/honors/domain/entities/honor.dart';

abstract interface class HonorRepository {
  /// Năm mới nhất trước; chưa có năm xếp sau; cùng năm theo thứ tự nhập.
  Future<List<Honor>> list();
  Future<void> save(Honor honor);
  Future<void> delete(String id);
}
