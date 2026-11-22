import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gia_pha/core/database/database_provider.dart';
import 'package:gia_pha/features/articles/data/repositories/article_repository_impl.dart';
import 'package:gia_pha/features/articles/domain/entities/article.dart';
import 'package:gia_pha/features/articles/domain/repositories/article_repository.dart';

final articleRepositoryProvider = Provider<ArticleRepository>(
  (ref) => ArticleRepositoryImpl(ref.watch(appDatabaseProvider)),
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
    await _repo.delete(id);
    state = AsyncData(await _repo.list(arg));
  }
}
