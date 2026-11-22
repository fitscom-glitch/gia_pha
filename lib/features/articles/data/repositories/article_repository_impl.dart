import 'package:gia_pha/core/database/app_database.dart';
import 'package:gia_pha/features/articles/data/models/article_model.dart';
import 'package:gia_pha/features/articles/domain/entities/article.dart';
import 'package:gia_pha/features/articles/domain/repositories/article_repository.dart';

class ArticleRepositoryImpl implements ArticleRepository {
  ArticleRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<List<Article>> list(ArticleKind kind) async {
    final db = await _db.database;
    final rows = await db.query(
      'articles',
      where: 'kind = ?',
      whereArgs: [kind.name],
      orderBy: 'created_at, rowid',
    );
    return rows.map(ArticleModel.fromMap).toList();
  }

  @override
  Future<void> save(Article article) async {
    final db = await _db.database;
    final map = ArticleModel.fromEntity(article).toMap();
    final n = await db.update('articles', map, where: 'id = ?', whereArgs: [article.id]);
    if (n == 0) await db.insert('articles', map);
  }

  @override
  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('articles', where: 'id = ?', whereArgs: [id]);
  }
}
