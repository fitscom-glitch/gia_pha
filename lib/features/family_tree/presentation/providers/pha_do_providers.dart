import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gia_pha/core/database/database_provider.dart';
import 'package:gia_pha/core/storage/image_store.dart';
import 'package:gia_pha/features/family_tree/data/image_aspect.dart';
import 'package:gia_pha/features/family_tree/data/repositories/pha_do_layer_repository_impl.dart';
import 'package:gia_pha/features/family_tree/domain/entities/pha_do_layer.dart';
import 'package:gia_pha/features/family_tree/domain/repositories/pha_do_layer_repository.dart';
import 'package:uuid/uuid.dart';

final phaDoLayerRepositoryProvider = Provider<PhaDoLayerRepository>(
  (ref) => PhaDoLayerRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final phaDoImageStoreProvider =
    Provider<ImageStore>((ref) => const ImageStore(folder: 'phado'));

final phaDoLayersProvider =
    AsyncNotifierProvider<PhaDoLayersNotifier, List<PhaDoLayer>>(PhaDoLayersNotifier.new);

class PhaDoLayersNotifier extends AsyncNotifier<List<PhaDoLayer>> {
  PhaDoLayerRepository get _repo => ref.read(phaDoLayerRepositoryProvider);
  ImageStore get _store => ref.read(phaDoImageStoreProvider);

  @override
  Future<List<PhaDoLayer>> build() => _repo.list();

  /// Chép hình vào bộ nhớ ứng dụng và thêm thành một lớp mới. Trả về id lớp.
  Future<String> add({required String sourcePath, required PhaDoLayerKind kind}) async {
    final id = const Uuid().v4();
    final stored = await _store.saveCopy(sourcePath, id);
    final aspect = await imageAspect(stored);
    final isBg = kind == PhaDoLayerKind.background;
    final current = state.valueOrNull ?? const <PhaDoLayer>[];
    final top = current.isEmpty ? 0 : current.map((l) => l.z).reduce(math.max) + 1;
    await _repo.save(PhaDoLayer(
      id: id,
      path: stored,
      kind: kind,
      cy: isBg ? 0.5 : 0.2,
      w: isBg ? 1 : 0.3,
      aspect: aspect,
      z: isBg ? (current.isEmpty ? 0 : current.map((l) => l.z).reduce(math.min) - 1) : top,
    ));
    state = AsyncData(await _repo.list());
    return id;
  }

  /// Cập nhật tạm trong bộ nhớ (khi đang kéo/trượt), chưa ghi cơ sở dữ liệu.
  void updateLocal(PhaDoLayer layer) {
    final list = state.valueOrNull;
    if (list == null) return;
    state = AsyncData([for (final l in list) l.id == layer.id ? layer : l]);
  }

  Future<void> persist(PhaDoLayer layer) async {
    await _repo.save(layer);
    state = AsyncData(await _repo.list());
  }

  Future<void> remove(PhaDoLayer layer) async {
    await _repo.delete(layer.id);
    await _store.delete(layer.path);
    state = AsyncData(await _repo.list());
  }
}
