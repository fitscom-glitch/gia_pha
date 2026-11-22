import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gia_pha/core/database/database_provider.dart';
import 'package:gia_pha/features/honors/data/repositories/honor_repository_impl.dart';
import 'package:gia_pha/features/honors/domain/entities/honor.dart';
import 'package:gia_pha/features/honors/domain/repositories/honor_repository.dart';

final honorRepositoryProvider = Provider<HonorRepository>(
  (ref) => HonorRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final honorsProvider =
    AsyncNotifierProvider<HonorsNotifier, List<Honor>>(HonorsNotifier.new);

class HonorsNotifier extends AsyncNotifier<List<Honor>> {
  HonorRepository get _repo => ref.read(honorRepositoryProvider);

  @override
  Future<List<Honor>> build() => _repo.list();

  Future<void> save(Honor honor) async {
    await _repo.save(honor);
    state = AsyncData(await _repo.list());
  }

  Future<void> remove(String id) async {
    await _repo.delete(id);
    state = AsyncData(await _repo.list());
  }
}
