import 'package:gia_pha/features/articles/domain/entities/article.dart';

class ArticleModel extends Article {
  const ArticleModel({
    required super.id,
    required super.kind,
    required super.title,
    required super.body,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ArticleModel.fromEntity(Article a) => ArticleModel(
        id: a.id,
        kind: a.kind,
        title: a.title,
        body: a.body,
        createdAt: a.createdAt,
        updatedAt: a.updatedAt,
      );

  factory ArticleModel.fromMap(Map<String, Object?> m) => ArticleModel(
        id: m['id'] as String,
        kind: ArticleKind.values.byName(m['kind'] as String),
        title: m['title'] as String,
        body: m['body'] as String,
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'kind': kind.name,
        'title': title,
        'body': body,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
