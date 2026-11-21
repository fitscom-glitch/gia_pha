import 'package:gia_pha/features/members/domain/entities/family_data.dart';
import 'package:gia_pha/features/members/domain/repositories/family_repository.dart';

class LoadFamily {
  const LoadFamily(this._repository);

  final FamilyRepository _repository;

  Future<FamilyData> call() => _repository.loadFamily();
}
