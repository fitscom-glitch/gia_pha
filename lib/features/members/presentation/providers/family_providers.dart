import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gia_pha/core/database/app_database.dart';
import 'package:gia_pha/features/members/data/datasources/family_local_data_source.dart';
import 'package:gia_pha/features/members/data/repositories/family_repository_impl.dart';
import 'package:gia_pha/features/members/domain/entities/family_data.dart';
import 'package:gia_pha/features/members/domain/entities/person.dart';
import 'package:gia_pha/features/members/domain/entities/relationship.dart';
import 'package:gia_pha/features/members/domain/repositories/family_repository.dart';
import 'package:gia_pha/features/members/domain/usecases/delete_member.dart';
import 'package:gia_pha/features/members/domain/usecases/load_family.dart';
import 'package:gia_pha/features/members/domain/usecases/save_member.dart';

// --- Dependency injection (override các provider này khi test) ---

final appDatabaseProvider =
    Provider<AppDatabase>((ref) => AppDatabase.instance);

final familyRepositoryProvider = Provider<FamilyRepository>(
  (ref) => FamilyRepositoryImpl(
    FamilyLocalDataSource(ref.watch(appDatabaseProvider)),
  ),
);

final loadFamilyProvider =
    Provider<LoadFamily>((ref) => LoadFamily(ref.watch(familyRepositoryProvider)));

final saveMemberProvider =
    Provider<SaveMember>((ref) => SaveMember(ref.watch(familyRepositoryProvider)));

final deleteMemberProvider = Provider<DeleteMember>(
  (ref) => DeleteMember(ref.watch(familyRepositoryProvider)),
);

// --- State ---

final familyProvider =
    AsyncNotifierProvider<FamilyNotifier, FamilyData>(FamilyNotifier.new);

class FamilyNotifier extends AsyncNotifier<FamilyData> {
  @override
  Future<FamilyData> build() => ref.read(loadFamilyProvider)();

  Future<void> saveMember(
    Person person, {
    String? anchorId,
    AddAs? addAs,
  }) async {
    await ref.read(saveMemberProvider)(person, anchorId: anchorId, addAs: addAs);
    await _reload();
  }

  Future<void> deleteMember(String id) async {
    await ref.read(deleteMemberProvider)(id);
    await _reload();
  }

  Future<void> _reload() async {
    state = AsyncData(await ref.read(loadFamilyProvider)());
  }
}
