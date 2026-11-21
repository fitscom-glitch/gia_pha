import 'package:gia_pha/features/members/data/datasources/family_local_data_source.dart';
import 'package:gia_pha/features/members/data/models/person_model.dart';
import 'package:gia_pha/features/members/data/models/relationship_model.dart';
import 'package:gia_pha/features/members/domain/entities/family_data.dart';
import 'package:gia_pha/features/members/domain/entities/person.dart';
import 'package:gia_pha/features/members/domain/entities/relationship.dart';
import 'package:gia_pha/features/members/domain/repositories/family_repository.dart';

class FamilyRepositoryImpl implements FamilyRepository {
  FamilyRepositoryImpl(this._local);

  final FamilyLocalDataSource _local;

  @override
  Future<FamilyData> loadFamily() async {
    final persons = await _local.getPersons();
    final relationships = await _local.getRelationships();
    return FamilyData(persons, relationships);
  }

  @override
  Future<void> savePerson(Person person, {Relationship? relationship}) {
    return _local.savePerson(
      PersonModel.fromEntity(person),
      relationship:
          relationship == null ? null : RelationshipModel.fromEntity(relationship),
    );
  }

  @override
  Future<void> deletePerson(String id) => _local.deletePerson(id);
}
