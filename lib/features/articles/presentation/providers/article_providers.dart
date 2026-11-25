import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gia_pha/core/database/database_provider.dart';
import 'package:gia_pha/core/storage/image_store.dart';
import 'package:gia_pha/features/articles/data/repositories/article_repository_impl.dart';
import 'package:gia_pha/features/articles/domain/entities/article.dart';
import 'package:gia_pha/features/articles/domain/entities/article_content.dart';
import 'package:gia_pha/features/articles/domain/repositories/article_repository.dart';

final articleRepositoryProvider = Provider<ArticleRepository>(
  (ref) => ArticleRepositoryImpl(ref.watch(appDatabaseProvider)),
);

/// Nơi lưu ảnh chèn trong bài viết.
final articleImageStoreProvider =
    Provider<ImageStore>((ref) => const ImageStore(folder: 'articles'));

/// Đường dẫn thư mục ảnh bài viết (để ghép với tên file trong nội dung bài).
final articleImageDirProvider = FutureProvider<String>(
  (ref) => ref.watch(articleImageStoreProvider).directoryPath(),
);

final articlesProvider =
    AsyncNotifierProvider.family<ArticlesNotifier, List<Article>, ArticleKind>(
  ArticlesNotifier.new,
);

class ArticlesNotifier extends FamilyAsyncNotifier<List<Article>, ArticleKind> {
  ArticleRepository get _repo => ref.read(articleRepositoryProvider);

  @override
  Future<List<Article>> build(ArticleKind arg) => _repo.list(arg);

  Future<void> save(Article article) async {
    await _repo.save(article);
    state = AsyncData(await _repo.list(arg));
  }

  Future<void> remove(String id) async {
    Article? target;
    for (final a in state.valueOrNull ?? const <Article>[]) {
      if (a.id == id) target = a;
    }
    await _repo.delete(id);
    if (target != null) {
      final store = ref.read(articleImageStoreProvider);
      for (final name in articleImageNames(target.body)) {
        await store.deleteNamed(name);
      }
    }
    state = AsyncData(await _repo.list(arg));
  }
}
