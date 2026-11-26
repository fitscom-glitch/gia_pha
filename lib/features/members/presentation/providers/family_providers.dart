import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gia_pha/core/database/database_provider.dart';
import 'package:gia_pha/core/storage/image_store.dart';
import 'package:gia_pha/features/members/data/datasources/family_local_data_source.dart';
import 'package:gia_pha/features/members/data/repositories/family_repository_impl.dart';
import 'package:gia_pha/features/members/domain/entities/family_data.dart';
import 'package:gia_pha/features/members/domain/entities/person.dart';
import 'package:gia_pha/features/members/domain/entities/relationship.dart';
import 'package:gia_pha/features/members/domain/repositories/family_repository.dart';
import 'package:gia_pha/features/members/domain/usecases/delete_member.dart';
import 'package:gia_pha/features/members/domain/usecases/load_family.dart';
import 'package:gia_pha/features/members/domain/usecases/reorder_siblings.dart';
import 'package:gia_pha/features/members/domain/usecases/save_member.dart';
import 'package:gia_pha/features/members/domain/usecases/set_parents.dart';

// --- Dependency injection (override các provider này khi test) ---

final familyRepositoryProvider = Provider<FamilyRepository>(
  (ref) => FamilyRepositoryImpl(
    FamilyLocalDataSource(ref.watch(appDatabaseProvider)),
  ),
);

final loadFamilyProvider = Provider<LoadFamily>(
  (ref) => LoadFamily(ref.watch(familyRepositoryProvider)),
);

final saveMemberProvider = Provider<SaveMember>(
  (ref) => SaveMember(ref.watch(familyRepositoryProvider)),
);

final setParentsProvider = Provider<SetParents>(
  (ref) => SetParents(ref.watch(familyRepositoryProvider)),
);

final deleteMemberProvider = Provider<DeleteMember>(
  (ref) => DeleteMember(ref.watch(familyRepositoryProvider)),
);

final reorderSiblingsProvider = Provider<ReorderSiblings>(
  (ref) => ReorderSiblings(ref.watch(familyRepositoryProvider)),
);

/// Nơi lưu ảnh đại diện.
final avatarStoreProvider =
    Provider<ImageStore>((ref) => const ImageStore(folder: 'avatars'));

// --- State ---

final familyProvider =
    AsyncNotifierProvider<FamilyDataNotifier, FamilyData>(FamilyDataNotifier.new);

class FamilyDataNotifier extends AsyncNotifier<FamilyData> {
  @override
  Future<FamilyData> build() => ref.read(loadFamilyProvider)();

  /// [newPhotoSourcePath]: ảnh vừa chọn từ thư viện; được chép vào bộ nhớ ứng dụng.
  Future<void> saveMember(
    Person person, {
    String? anchorId,
    AddAs? addAs,
    String? newPhotoSourcePath,
    bool removePhoto = false,
  }) async {
    var toSave = person;
    if (newPhotoSourcePath != null) {
      final store = ref.read(avatarStoreProvider);
      final stored = await store.saveCopy(newPhotoSourcePath, person.id);
      await store.delete(person.photoPath);
      toSave = person.withPhoto(stored);
    } else if (removePhoto) {
      await ref.read(avatarStoreProvider).delete(state.valueOrNull?.byId(person.id)?.photoPath);
      toSave = person.withPhoto(null);
    }
    await ref.read(saveMemberProvider)(toSave, anchorId: anchorId, addAs: addAs);
    await _reload();
  }

  /// Đặt lại cha/mẹ của [childId] (thay toàn bộ các quan hệ cha/mẹ cũ).
  Future<void> setParents(String childId, List<String> parentIds) async {
    await ref.read(setParentsProvider)(childId, parentIds);
    await _reload();
  }

  Future<void> deleteMember(String id) async {
    final photo = state.valueOrNull?.byId(id)?.photoPath;
    await ref.read(deleteMemberProvider)(id);
    await ref.read(avatarStoreProvider).delete(photo);
    await _reload();
  }

  /// [orderedIds]: phần tử đầu là con trưởng.
  Future<void> reorderSiblings(List<String> orderedIds) async {
    await ref.read(reorderSiblingsProvider)(orderedIds);
    await _reload();
  }

  Future<void> _reload() async {
    state = AsyncData(await ref.read(loadFamilyProvider)());
  }
}
