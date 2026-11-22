/// Ba mục dạng bài viết: lịch sử, tộc ước & hương lễ, chuyện cổ kim.
enum ArticleKind { history, rules, stories }

class Article {
  const Article({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final ArticleKind kind;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;
}
