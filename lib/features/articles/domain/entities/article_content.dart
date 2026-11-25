/// Bài viết có thể chèn ảnh: ảnh được ghi trong nội dung bằng dấu `[[img:tên-file]]`.
final RegExp _imageToken = RegExp(r'\[\[img:([^\]]+)\]\]');

String articleImageToken(String fileName) => '[[img:$fileName]]';

/// Tên các file ảnh được chèn trong [body].
Set<String> articleImageNames(String body) => {
      for (final m in _imageToken.allMatches(body)) m.group(1)!,
    };

/// Nội dung không kèm các dấu chèn ảnh (dùng cho phần tóm tắt).
String stripArticleImageTokens(String body) => body.replaceAll(_imageToken, ' ');

/// Một đoạn của bài: hoặc là văn bản, hoặc là một ảnh.
class ArticleBlock {
  const ArticleBlock.text(this.text) : image = null;
  const ArticleBlock.image(this.image) : text = null;

  final String? text;
  final String? image;
}

List<ArticleBlock> parseArticleBody(String body) {
  final blocks = <ArticleBlock>[];
  var last = 0;
  for (final m in _imageToken.allMatches(body)) {
    final before = body.substring(last, m.start).trim();
    if (before.isNotEmpty) blocks.add(ArticleBlock.text(before));
    blocks.add(ArticleBlock.image(m.group(1)!));
    last = m.end;
  }
  final tail = body.substring(last).trim();
  if (tail.isNotEmpty) blocks.add(ArticleBlock.text(tail));
  return blocks;
}
