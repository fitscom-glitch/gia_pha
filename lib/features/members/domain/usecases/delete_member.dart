import 'package:gia_pha/features/members/domain/repositories/family_repository.dart';

class DeleteMember {
  const DeleteMember(this._repository);

  final FamilyRepository _repository;

  Future<void> call(String id) => _repository.deletePerson(id);
}
