import 'package:gia_pha/features/articles/domain/entities/article.dart';

abstract interface class ArticleRepository {
  /// Theo thứ tự viết (bài cũ trước), không sắp theo bảng chữ cái.
  Future<List<Article>> list(ArticleKind kind);
  Future<void> save(Article article);
  Future<void> delete(String id);
}
