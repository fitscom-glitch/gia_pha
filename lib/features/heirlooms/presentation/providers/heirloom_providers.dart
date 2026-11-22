import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gia_pha/core/database/database_provider.dart';
import 'package:gia_pha/features/heirlooms/data/repositories/heirloom_repository_impl.dart';
import 'package:gia_pha/features/heirlooms/domain/entities/heirloom.dart';
import 'package:gia_pha/features/heirlooms/domain/repositories/heirloom_repository.dart';

final heirloomRepositoryProvider = Provider<HeirloomRepository>(
  (ref) => HeirloomRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final heirloomImageStoreProvider =
    Provider<HeirloomImageStore>((ref) => const HeirloomImageStore());

final heirloomsProvider =
    AsyncNotifierProvider<HeirloomsNotifier, List<Heirloom>>(HeirloomsNotifier.new);

class HeirloomsNotifier extends AsyncNotifier<List<Heirloom>> {
  HeirloomRepository get _repo => ref.read(heirloomRepositoryProvider);
  HeirloomImageStore get _store => ref.read(heirloomImageStoreProvider);

  @override
  Future<List<Heirloom>> build() => _repo.list();

  /// [newImageSourcePath]: ảnh vừa chọn từ thư viện; sẽ được chép vào bộ nhớ ứng dụng.
  Future<void> save(Heirloom item, {String? newImageSourcePath}) async {
    var toSave = item;
    if (newImageSourcePath != null) {
      final stored = await _store.saveCopy(newImageSourcePath, item.id);
      await _store.delete(item.imagePath);
      toSave = item.withImage(stored);
    }
    await _repo.save(toSave);
    state = AsyncData(await _repo.list());
  }

  Future<void> remove(Heirloom item) async {
    await _repo.delete(item.id);
    await _store.delete(item.imagePath);
    state = AsyncData(await _repo.list());
  }
}
