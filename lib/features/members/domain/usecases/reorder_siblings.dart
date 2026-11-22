import 'package:gia_pha/features/members/domain/repositories/family_repository.dart';

/// Lưu thứ tự anh em do người dùng sắp xếp (phần tử đầu = con trưởng).
class ReorderSiblings {
  const ReorderSiblings(this._repository);

  final FamilyRepository _repository;

  Future<void> call(List<String> orderedIds) =>
      _repository.setBirthOrders(orderedIds);
}
